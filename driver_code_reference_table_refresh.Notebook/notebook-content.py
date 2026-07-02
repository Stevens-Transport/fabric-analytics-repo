# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "6347e061-2f76-4e4a-93c6-8834bf7afa76",
# META       "default_lakehouse_name": "data_central_lh",
# META       "default_lakehouse_workspace_id": "aec56c7f-8ffa-4f7a-b3e6-599f1a16ef27",
# META       "known_lakehouses": [
# META         {
# META           "id": "6347e061-2f76-4e4a-93c6-8834bf7afa76"
# META         }
# META       ]
# META     },
# META     "warehouse": {
# META       "known_warehouses": [
# META         {
# META           "id": "6d0007d9-0647-4acb-9add-13d26a7f0b54",
# META           "type": "Lakewarehouse"
# META         },
# META         {
# META           "id": "f8578495-391e-4e7e-b791-4949397ba86f",
# META           "type": "Datawarehouse"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

import pandas as pd
import pyodbc
import struct
import re
import notebookutils
from datetime import datetime

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ---------------------- CONFIG ------------------------------
SERVER   = "lofzv5bdxbxepf3ufbs6kug4du-p5wmllx2r55e7m7glgprufxpe4.datawarehouse.fabric.microsoft.com"
DATABASE = "data_central_wh"
SOURCE_VIEW      = "gold.vw_ibmi_driver"
REFERENCE_TABLE  = "driver_code_reference_table"   # main output (default lakehouse)
REVIEW_TABLE     = "driver_code_review"            # manual-review output
# ------------------------------------------------------------

def log(msg):
    print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}")
 
 
log("=== Driver code reference table refresh START ===")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 1: Connect to Warehouse and load driver data
# ============================================================
token = notebookutils.credentials.getToken("https://database.windows.net/")
token_bytes = token.encode("UTF-16-LE")
token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
 
conn = pyodbc.connect(
    f"Driver={{ODBC Driver 18 for SQL Server}};"
    f"Server={SERVER};"
    f"Database={DATABASE};",
    attrs_before={1256: token_struct}
)
 
# Lean frame used by the main pipeline.
df = pd.read_sql(f"""
    SELECT
        drv_code,
        drv_full_name,
        drv_social_security,
        drv_address_line_1,
        drv_create_date,
        drv_status_code,
        drv_type
    FROM {SOURCE_VIEW}
""", conn)
 
# Full-detail copy (all columns) used only to build the review table.
df_full = pd.read_sql(f"SELECT * FROM {SOURCE_VIEW}", conn)
df_full['drv_code'] = df_full['drv_code'].astype(str).str.strip().str.upper()
 
log(f"Step 1: loaded {len(df)} rows ({df.shape[1]} cols) + full-detail copy ({df_full.shape[1]} cols)")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 1b: Attribute dedup + conflict isolation
#  1. Same person, duplicate physical records -> collapse to one row (keep valid SSN).
#  2. Two people sharing one code (e.g. PRIS) -> recorded as conflict, kept in
#     df_conflicts, re-introduced in Step 4 with is_conflict = True.
# ============================================================

INVALID_SSN = {None, '', '000000000'}
 
def valid_ssn(s):
    """Return True only for a real SSN (not null, blank, or the 000000000 placeholder)."""
    return pd.notna(s) and str(s).strip() not in INVALID_SSN
 
 
df['drv_code'] = df['drv_code'].astype(str).str.strip().str.upper()
df['_ssn_valid'] = df['drv_social_security'].apply(valid_ssn).astype(int)
 
# A code with >= 2 DISTINCT valid SSNs means two real people share one code.
multi = df[df['_ssn_valid'] == 1].groupby('drv_code')['drv_social_security'].nunique()
conflict_codes = set(multi[multi >= 2].index)
 
df_attr = (df[~df['drv_code'].isin(conflict_codes)]
           .sort_values('_ssn_valid', ascending=False)
           .drop_duplicates(subset=['drv_code'], keep='first')
           .drop(columns='_ssn_valid'))
 
df_conflicts = df[df['drv_code'].isin(conflict_codes)].drop(columns='_ssn_valid').copy()
df = df.drop(columns='_ssn_valid')
 
log(f"Step 1b: raw physical rows={len(df)}, unique codes={df['drv_code'].nunique()}, "
    f"conflict codes={len(conflict_codes)} {sorted(conflict_codes)}, df_attr={len(df_attr)}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 2: Extract the code referenced in the address line
#  - strips quotes so CODE "POWRO" works; asterisks/other symbols are ignored
#  - STOP_WORDS reject connector/error words (IN, BY, ERROR, ...) that follow CODE
#  - self-pointing edges are dropped (they only loop back to a self-mapping)
# ============================================================
STOP_WORDS = {'IN', 'BY', 'ERROR', 'ERRO', 'ERR', 'TO', 'THE',
              'A', 'AN', 'IS', 'NO', 'NOT'}
 
 
def extract_code_from_address(address):
    if pd.isna(address):
        return None
 
    address = str(address).strip()
 
    # Strip quotes only (CODE "POWRO" -> CODE POWRO). Asterisks are left alone;
    # [A-Z0-9]+ already stops at them, so starred rows are unaffected.
    address = address.replace('"', '').replace("'", '')
 
    if 'CODE' not in address.upper():
        return None
 
    # 'CHANGED TO xxx' pattern -> take the code after 'TO'.
    changed_match = re.search(r'CHANGED\s+TO\s+([A-Z0-9]+)', address)
    if changed_match:
        candidate = changed_match.group(1)
        if candidate.upper() not in STOP_WORDS:
            return candidate
 
    # Otherwise take the code after the last occurrence of 'CODE'.
    all_matches = re.findall(r'CODE\s+([A-Z0-9]+)', address)
    if all_matches:
        candidate = all_matches[-1]
        if ' ' in candidate or candidate == '':
            return None
        if candidate.upper() in STOP_WORDS:
            return None
        return candidate
 
    return None
 
 
df['extracted_code'] = df['drv_address_line_1'].apply(extract_code_from_address)
 
history_codes = df[df['extracted_code'].notna()][['drv_code', 'extracted_code']].copy()
history_codes.columns = ['history_code', 'current_code']
 
# Remove duplicate edges, then drop self-pointing edges.
history_codes = history_codes.drop_duplicates(subset=['history_code'], keep='first')
history_codes = history_codes[history_codes['history_code'] != history_codes['current_code']]
 
log(f"Step 2: raw edges={len(history_codes)}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 3: Recursively follow the chain to the final current code
# ============================================================
edge_map = dict(zip(history_codes['history_code'], history_codes['current_code']))
 
 
def find_final_current(code, visited=None):
    """Follow the chain until reaching a code with no further reference."""
    if visited is None:
        visited = set()
    if code in visited:
        return code  # circular reference guard
    visited.add(code)
    if code not in edge_map:
        return code  # end of chain
    return find_final_current(edge_map[code], visited)
 
 
history_codes['current_code'] = history_codes['history_code'].apply(find_final_current)
log(f"Step 3: resolved {len(history_codes)} mappings")
 

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 3b: SSN cross-validation gate
# Both ends have a valid but different SSN -> suspicious pointer; break back to
# self and record in df_ssn_conflict_review (keeps original_target + names).
# Policy: prefer under-merge over mis-merge.
# ============================================================
ssn_lookup  = df_attr.set_index('drv_code')['drv_social_security'].to_dict()
name_lookup = df_attr.set_index('drv_code')['drv_full_name'].to_dict()
 
hc = history_codes.copy()
hc['_hist_ssn'] = hc['history_code'].map(ssn_lookup)
hc['_curr_ssn'] = hc['current_code'].map(ssn_lookup)
 
suspect = (
    hc['_hist_ssn'].apply(valid_ssn) &
    hc['_curr_ssn'].apply(valid_ssn) &
    (hc['_hist_ssn'].astype(str).str.strip() != hc['_curr_ssn'].astype(str).str.strip()) &
    (hc['history_code'] != hc['current_code'])
)
 
df_ssn_conflict_review = (
    hc[suspect][['history_code', 'current_code', '_hist_ssn', '_curr_ssn']]
    .rename(columns={'current_code': 'original_target',
                     '_hist_ssn': 'history_ssn',
                     '_curr_ssn': 'current_ssn'})
    .copy()
)
df_ssn_conflict_review['history_full_name'] = df_ssn_conflict_review['history_code'].map(name_lookup)
 
hc.loc[suspect, 'current_code'] = hc.loc[suspect, 'history_code']
history_codes = hc.drop(columns=['_hist_ssn', '_curr_ssn'])
 
log(f"Step 3b: broke {int(suspect.sum())} suspicious SSN-mismatch mapping(s)")
if suspect.sum() > 0:
    for _, r in df_ssn_conflict_review.iterrows():
        log(f"  - {r['history_code']} ({r['history_full_name']}, ssn {r['history_ssn']}) "
            f"was -> {r['original_target']} (ssn {r['current_ssn']}); broken to self")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 4: Build the final reference table
#  - Non-conflict part: clean codes mapped to current code, is_conflict = False.
#  - Conflict part: shared-code conflicts kept as self-mappings, is_conflict = True.
# ============================================================
hist_map = history_codes[
    ~history_codes['history_code'].isin(conflict_codes) &
    ~history_codes['current_code'].isin(conflict_codes)
][['history_code', 'current_code']].copy()

all_history_codes = set(hist_map['history_code'])
current_only = df_attr[~df_attr['drv_code'].isin(all_history_codes)][['drv_code']].copy()
current_only['current_code'] = current_only['drv_code']
current_only = current_only.rename(columns={'drv_code': 'history_code'})

non_conflict = pd.concat([
    hist_map[['history_code', 'current_code']],
    current_only[['history_code', 'current_code']]
], ignore_index=True).drop_duplicates()

# Enrich: current side keeps SSN (renamed to 'ssn'); history side keeps create date only.
driver_info = df_attr[['drv_code', 'drv_social_security', 'drv_create_date']]

non_conflict = non_conflict.merge(
    driver_info[['drv_code', 'drv_create_date']].rename(columns={
        'drv_code': 'history_code', 'drv_create_date': 'history_create_date'}),
    on='history_code', how='left')
non_conflict = non_conflict.merge(
    driver_info.rename(columns={
        'drv_code': 'current_code',
        'drv_social_security': 'ssn', 'drv_create_date': 'current_create_date'}),
    on='current_code', how='left')
non_conflict['is_conflict'] = False

conflict_people = (
    df_conflicts[df_conflicts['drv_social_security'].apply(valid_ssn)]
    .drop_duplicates(subset=['drv_code', 'drv_social_security'])
    [['drv_code', 'drv_social_security', 'drv_create_date']]
    .copy())

conflict_part = pd.DataFrame({
    'history_code':        conflict_people['drv_code'].values,
    'current_code':        conflict_people['drv_code'].values,
    'history_create_date': conflict_people['drv_create_date'].values,
    'ssn':                 conflict_people['drv_social_security'].values,
    'current_create_date': conflict_people['drv_create_date'].values,
})
conflict_part['is_conflict'] = True

reference_table = pd.concat([non_conflict, conflict_part], ignore_index=True)

# Sanity check (name-independent): current codes that don't resolve to a known code.
known_codes = set(df_attr['drv_code']) | conflict_codes
nan_current = int((~reference_table['current_code'].isin(known_codes)).sum())
log(f"Step 4: reference rows={len(reference_table)} (non_conflict={len(non_conflict)}, conflict={len(conflict_part)}), current-side unresolved={nan_current}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 5: Write the reference table to Delta (with validation fuse)
# The pre-write assert stops a bad load from overwriting the live table.
# If it fails the job errors out - make sure the scheduler alerts on failure.
# ============================================================
out = reference_table.copy()
for c in ['history_create_date', 'current_create_date']:
    if c in out.columns:
        out[c] = out[c].astype(str).replace({'NaT': None, 'nan': None, 'None': None})
out = out.where(pd.notna(out), None)
 
expected = df_attr['drv_code'].nunique() + int(out['is_conflict'].sum())
actual = len(out)
log(f"Step 5: pre-write check actual={actual} expected={expected}")
assert actual == expected, f"Row count mismatch ({actual} != {expected}); aborting before overwrite."
 
spark.createDataFrame(out).write \
    .mode("overwrite").option("overwriteSchema", "true") \
    .saveAsTable(REFERENCE_TABLE)
 
cnt = spark.sql(f"SELECT COUNT(*) AS n FROM {REFERENCE_TABLE}").collect()[0]['n']
assert cnt == expected, f"Post-write count mismatch ({cnt} != {expected})."
log(f"Step 5: wrote {REFERENCE_TABLE}, persisted rows={cnt}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 5b: Write the review table (full gold detail for every flagged code)
# One row per original gold record, tagged by conflict_type. Always overwritten
# so downstream always finds the current set of cases (may be empty).
# ============================================================
from pyspark.sql.types import StructType, StructField, StringType
 
shared_code_set = set(df_conflicts['drv_code'])
ssn_break_set   = set(df_ssn_conflict_review['history_code'])
review_codes    = shared_code_set | ssn_break_set
 
df_review = df_full[df_full['drv_code'].isin(review_codes)].copy()
 
 
def classify(code):
    tags = []
    if code in shared_code_set:
        tags.append('shared_code')
    if code in ssn_break_set:
        tags.append('ssn_mismatch')
    return '+'.join(tags)
 
 
df_review.insert(0, 'conflict_type', df_review['drv_code'].apply(classify))
df_review = df_review.sort_values(['conflict_type', 'drv_code']).reset_index(drop=True)
 
# Everything to string for a stable review-table schema, empty-safe.
df_review_str = df_review.astype(str)
if len(df_review_str) > 0:
    review_sdf = spark.createDataFrame(df_review_str)
else:
    schema = StructType([StructField(c, StringType(), True) for c in df_review_str.columns])
    review_sdf = spark.createDataFrame([], schema)
 
review_sdf.write \
    .mode("overwrite").option("overwriteSchema", "true") \
    .saveAsTable(REVIEW_TABLE)
 
log(f"Step 5b: wrote {REVIEW_TABLE}, rows={len(df_review)}, "
    f"shared_code={len(shared_code_set)}, ssn_mismatch={len(ssn_break_set)}, codes={sorted(review_codes)}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
