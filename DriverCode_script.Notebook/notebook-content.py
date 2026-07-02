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

# ============================================================
# Step 1: Connect to Warehouse and load driver data
# ============================================================
import pandas as pd
import pyodbc
import struct
import notebookutils
 
# Use Fabric's built-in notebookutils to obtain a token.
token = notebookutils.credentials.getToken("https://database.windows.net/")
token_bytes = token.encode("UTF-16-LE")
token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
 
server = "lofzv5bdxbxepf3ufbs6kug4du-p5wmllx2r55e7m7glgprufxpe4.datawarehouse.fabric.microsoft.com"
database = "data_central_wh"
 
conn = pyodbc.connect(
    f"Driver={{ODBC Driver 18 for SQL Server}};"
    f"Server={server};"
    f"Database={database};",
    attrs_before={1256: token_struct}
)
 
# Load the FULL driver master WITHOUT dedup on purpose - Step 2 needs every physical
# row so that no address-line pointer is missed.
df = pd.read_sql("""
    SELECT
        drv_code,
        drv_full_name,
        drv_social_security,
        drv_address_line_1,
        drv_create_date,
        drv_status_code,
        drv_type
    FROM gold.vw_ibmi_driver
""", conn)
 
print(df.shape)
print(df.head())

# Full-detail copy for review tables (keep the main df lean).
df_full = pd.read_sql("SELECT * FROM gold.vw_ibmi_driver", conn)
df_full['drv_code'] = df_full['drv_code'].astype(str).str.strip().str.upper()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 1b: Attribute dedup + conflict isolation
# (does NOT touch df; Step 2 still extracts pointers on the full df)
#
# Two kinds of "duplicate" rows are handled differently:
#  1. Same person, duplicate physical records (e.g. DREY, KEMW, MIDOU):
#     one valid-SSN row + one NULL/000000000 row -> collapse to one row in df_attr.
#  2. Two different people sharing one code (e.g. PRIS): same drv_code carries
#     two DIFFERENT valid SSNs -> recorded in conflict_codes / df_conflicts,
#     re-introduced into the reference table in Step 4 with is_conflict = True.
# ============================================================
 
# Shared SSN helper - reused in Step 3b as well.
INVALID_SSN = {None, '', '000000000'}
 
 
def valid_ssn(s):
    """Return True only for a real SSN (not null, '', or the 000000000 placeholder)."""
    return pd.notna(s) and str(s).strip() not in INVALID_SSN
 
 
# Normalize the join key.
df['drv_code'] = df['drv_code'].astype(str).str.strip().str.upper()
 
# Flag rows that carry a valid SSN.
df['_ssn_valid'] = df['drv_social_security'].apply(valid_ssn).astype(int)
 
# A code with >= 2 DISTINCT valid SSNs means two real people share one code (e.g. PRIS).
multi = df[df['_ssn_valid'] == 1].groupby('drv_code')['drv_social_security'].nunique()
conflict_codes = set(multi[multi >= 2].index)
 
# Attribute table: one row per code, preferring the valid-SSN record; conflicts excluded.
df_attr = (df[~df['drv_code'].isin(conflict_codes)]
           .sort_values('_ssn_valid', ascending=False)
           .drop_duplicates(subset=['drv_code'], keep='first')
           .drop(columns='_ssn_valid'))
 
# Keep full physical detail of conflict codes for the separate review table.
df_conflicts = df[df['drv_code'].isin(conflict_codes)].drop(columns='_ssn_valid').copy()
 
# Restore df (Step 2 extracts pointers from the full, un-deduplicated dataset).
df = df.drop(columns='_ssn_valid')
 
print(f"Raw physical rows : {len(df)}")    # number of rows in original gold table
print(f"Unique codes      : {df['drv_code'].nunique()}")       # number of unique codes in original gold table
print(f"Conflict codes   : {len(conflict_codes)} -> {sorted(conflict_codes)}")  # number of conflict codes
print(f"df_attr rows      : {len(df_attr)}")
 

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# duplicate codes in the raw gold view
all_dup = df['drv_code'].value_counts()
all_dup = set(all_dup[all_dup > 1].index)
print(f"Codes with duplicate physical records: {len(all_dup)} -> {sorted(all_dup)}")
print(df[df['drv_code'].isin(all_dup)]
      .sort_values(['drv_code', 'drv_create_date'])
      .to_string(index=False))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 2: Extract the code referenced in the address line
# (NULL means the address line is a normal address -> this is
#  a current code; a value means this record points to another
#  code -> this is a history/process code)
#
# Runs on the FULL df so every pointer is captured. Duplicate edges are
# removed at the end so a code duplicated in gold does not yield two identical edges.
# ============================================================
import re

# Connector / error words that follow 'CODE' but are not real codes
# (e.g. "THIS CODE IN ERROR" -> IN, "SEE TUDA NEW CODE BY ERRO" -> BY).
STOP_WORDS = {'IN', 'BY', 'ERROR', 'ERRO', 'ERR', 'TO', 'THE',
              'A', 'AN', 'IS', 'NO', 'NOT'}


def extract_code_from_address(address):
    if pd.isna(address):
        return None

    address = str(address).strip()

    # Strip quotes only, so CODE "POWRO" -> CODE POWRO. Asterisks and other symbols
    # are left alone; the [A-Z0-9]+ pattern already stops at them, so starred rows
    # (e.g. "**SEE NEW CODE GATAN1", "**CORRECT CODE MCANM**") are unaffected.
    address = address.replace('"', '').replace("'", '')

    # If the address line doesn't contain 'CODE', it's a normal address.
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
        # Contains a space or is empty -> noise, not a valid code.
        if ' ' in candidate or candidate == '':
            return None
        # Reject connector/error words that are not real codes.
        if candidate.upper() in STOP_WORDS:
            return None
        return candidate

    return None


df['extracted_code'] = df['drv_address_line_1'].apply(extract_code_from_address)

# History codes: address line points to another code.
history_codes = df[df['extracted_code'].notna()][['drv_code', 'extracted_code']].copy()
history_codes.columns = ['history_code', 'current_code']

# Remove duplicate edges (a code duplicated in gold must not yield identical edges twice).
history_codes = history_codes.drop_duplicates(subset=['history_code'], keep='first')

# Drop self-pointing edges (e.g. MIDOU's "SEE CORRECT CODE MIDOU") - meaningless,
# and they would otherwise loop through the Step 3 guard back to a self-mapping.
history_codes = history_codes[history_codes['history_code'] != history_codes['current_code']]

print(f"History codes (raw edges): {len(history_codes)}")
print(history_codes.head(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 3: Recursively follow the chain to the final current code
# (handles multi-hop chains, e.g. AANDR1 -> AANDR -> AAND1)
# ============================================================
edge_map = dict(zip(history_codes['history_code'], history_codes['current_code']))
 
 
def find_final_current(code, visited=None):
    """Follow the chain until reaching a code with no further reference."""
    if visited is None:
        visited = set()
    if code in visited:
        # Circular reference guard.
        return code
    visited.add(code)
    if code not in edge_map:
        return code  # end of chain - this is the final current code
    return find_final_current(edge_map[code], visited)
 
 
history_codes['current_code'] = history_codes['history_code'].apply(find_final_current)
 
print(f"Total mappings: {len(history_codes)}")
print(history_codes.tail(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 3b: SSN cross-validation gate
# (after the chain is resolved, if both ends have a valid SSN but they
#  differ, the mapping is suspicious - likely a wrong address-line pointer
#  linking two different people, e.g. DUAND -> DURANA. Break it back to
#  self and route to df_ssn_conflict_review for manual decision.)
#
# Policy: prefer to UNDER-merge (split one person temporarily) over
# MIS-merge (collapse two people). original_target keeps the pre-break target.
# ============================================================
 
# Look up each code's SSN from df_attr (one row per code -> no fan-out).
ssn_lookup = df_attr.set_index('drv_code')['drv_social_security'].to_dict()
 
hc = history_codes.copy()
hc['_hist_ssn'] = hc['history_code'].map(ssn_lookup)
hc['_curr_ssn'] = hc['current_code'].map(ssn_lookup)
 
# Suspicious: both ends have a valid SSN, they differ, and it is not a self-mapping.
suspect = (
    hc['_hist_ssn'].apply(valid_ssn) &
    hc['_curr_ssn'].apply(valid_ssn) &
    (hc['_hist_ssn'].astype(str).str.strip() != hc['_curr_ssn'].astype(str).str.strip()) &
    (hc['history_code'] != hc['current_code'])
)
 
# Review table: keep the original target before breaking the link.
df_ssn_conflict_review = (
    hc[suspect][['history_code', 'current_code', '_hist_ssn', '_curr_ssn']]
    .rename(columns={'current_code': 'original_target',
                     '_hist_ssn': 'history_ssn',
                     '_curr_ssn': 'current_ssn'})
    .copy()
)

# add the driver name for the broken code
name_lookup = df_attr.set_index('drv_code')['drv_full_name'].to_dict()
df_ssn_conflict_review['history_full_name'] = df_ssn_conflict_review['history_code'].map(name_lookup)
 
# Break the suspicious links: point the code back to itself.
hc.loc[suspect, 'current_code'] = hc.loc[suspect, 'history_code']
 
history_codes = hc.drop(columns=['_hist_ssn', '_curr_ssn'])
 
print(f"SSN cross-validation: broke {int(suspect.sum())} suspicious mapping(s)")
if suspect.sum() > 0:
    print(df_ssn_conflict_review.to_string(index=False))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Step 3c: Validation cases
# (spot-check that each address-line pointer format resolves correctly)

# SEE NEW CODE
adams = history_codes[history_codes['history_code'].isin(['AANDR', 'AAND1', 'AANDR1'])]
print("\n SEE NEW CODE 1:")
print(adams)
 
rojob = history_codes[history_codes['history_code'].isin(['ROJOB1', 'ROJO1', 'ROJOB'])]
print("\n SEE NEW CODE 2:")
print(rojob)
 
# SEE OLD CODE
yatt = history_codes[history_codes['history_code'].isin(['YATT', 'YATTO'])]
print("\n SEE OLD CODE:")
print(yatt)
 
# SEE CORRECT CODE
wince = history_codes[history_codes['history_code'].isin(['WINCE', 'WINJON'])]
print("\n SEE CORRECT CODE:")
print(wince)
 
# CODE CHANGED TO
rohec = history_codes[history_codes['history_code'].isin(['ROHECT', 'ROHEC1', 'ROHE1'])]
print("\n CODE CHANGED TO:")
print(rohec)
 
# SEE ORIGINAL CODE
coscha = history_codes[history_codes['history_code'].isin(['COSCHA', 'COCHAR'])]
print("\n SEE ORIGINAL CODE:")
print(coscha)
 

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 4: Build the final reference table
# (every driver code mapped to its current code, plus SSN / name /
#  create date from the driver master)
#
# Two parts:
#  - Non-conflict part: clean codes mapped to their current code, enriched
#    from df_attr, is_conflict = False. Built from df_attr so it is never
#    inflated by duplicate physical records or fanned-out merges.
#  - Conflict part: shared-code conflicts (e.g. PRIS) are KEPT in the table.
#    Each real person (distinct code + valid SSN) becomes a self-mapping row
#    flagged is_conflict = True.
# ============================================================
 
# ---- Non-conflict part ----
# Drop edges where either end is a conflict code (conflicts handled below).
hist_map = history_codes[
    ~history_codes['history_code'].isin(conflict_codes) &
    ~history_codes['current_code'].isin(conflict_codes)
][['history_code', 'current_code']].copy()
 
# Codes that never appear as a history_code are themselves current codes.
# Build the skeleton from df_attr (clean, one row per code), not df.
all_history_codes = set(hist_map['history_code'])
current_only = df_attr[~df_attr['drv_code'].isin(all_history_codes)][['drv_code']].copy()
current_only['current_code'] = current_only['drv_code']
current_only = current_only.rename(columns={'drv_code': 'history_code'})
 
non_conflict = pd.concat([
    hist_map[['history_code', 'current_code']],
    current_only[['history_code', 'current_code']]
], ignore_index=True).drop_duplicates()
 
# Enrich with driver info from df_attr (one row per code -> merge does not fan out).
driver_info = df_attr[['drv_code', 'drv_full_name', 'drv_social_security', 'drv_create_date']]
 
non_conflict = non_conflict.merge(
    driver_info.rename(columns={
        'drv_code': 'history_code',
        'drv_full_name': 'history_full_name',
        'drv_social_security': 'history_ssn',
        'drv_create_date': 'history_create_date'
    }),
    on='history_code', how='left'
)
 
non_conflict = non_conflict.merge(
    driver_info.rename(columns={
        'drv_code': 'current_code',
        'drv_full_name': 'current_full_name',
        'drv_social_security': 'current_ssn',
        'drv_create_date': 'current_create_date'
    }),
    on='current_code', how='left'
)
 
non_conflict['is_conflict'] = False
 
# ---- Conflict part (shared-code conflicts, e.g. PRIS) ----
# One row per real person (distinct code + valid SSN); each is a self-mapping.
conflict_people = (
    df_conflicts[df_conflicts['drv_social_security'].apply(valid_ssn)]
    .drop_duplicates(subset=['drv_code', 'drv_social_security'])
    [['drv_code', 'drv_full_name', 'drv_social_security', 'drv_create_date']]
    .copy()
)
 
conflict_part = pd.DataFrame({
    'history_code':        conflict_people['drv_code'].values,
    'current_code':        conflict_people['drv_code'].values,
    'history_full_name':   conflict_people['drv_full_name'].values,
    'history_ssn':         conflict_people['drv_social_security'].values,
    'history_create_date': conflict_people['drv_create_date'].values,
    'current_full_name':   conflict_people['drv_full_name'].values,
    'current_ssn':         conflict_people['drv_social_security'].values,
    'current_create_date': conflict_people['drv_create_date'].values,
})
conflict_part['is_conflict'] = True
 
# ---- Combine ----
reference_table = pd.concat([non_conflict, conflict_part], ignore_index=True)
 
expected = df_attr['drv_code'].nunique() + len(conflict_part)
print(f"\nFinal reference table rows  : {len(reference_table)}")
print(f"  non-conflict rows         : {len(non_conflict)}  (= df_attr unique codes {df_attr['drv_code'].nunique()})")
print(f"  conflict rows (is_conflict): {len(conflict_part)}")
print(f"  expected total            : {expected}")
 
# Sanity check: any current-side NaN means a chain endpoint landed on a dropped code.
print(f"Rows with current-side NaN  : {reference_table['current_full_name'].isna().sum()}")
print(reference_table.head(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 5: Write to a TEMP Delta table (for verifying full output)
# (clean NaN -> None, dates -> string for stable Spark schema inference;
#  a row-count assert acts as a fuse so a bad load cannot silently
#  overwrite the table)
# ============================================================

# 1) Pre-write cleanup: dates -> string, NaN -> None.
out = reference_table.copy()

for c in ['history_create_date', 'current_create_date']:
    if c in out.columns:
        out[c] = out[c].astype(str).replace({'NaT': None, 'nan': None, 'None': None})

# Any remaining NaN -> None so Spark reads them as null.
out = out.where(pd.notna(out), None)

# 2) Pre-write validation fuse: row count must equal expected, else abort.
expected = df_attr['drv_code'].nunique() + int(out['is_conflict'].sum())
actual = len(out)
print(f"Pre-write check | actual {actual} | expected {expected}")
assert actual == expected, f"Row count mismatch ({actual} != {expected}); aborting before overwrite."

# 3) Write to a TEMP Delta table in the default lakehouse (data_central_lh / dev_kacey).
result_spark_df = spark.createDataFrame(out)

result_spark_df.write \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("tmp_driver_code_reference_table")

print("Written to Delta table: tmp_driver_code_reference_table")

# 4) Post-write validation: confirm the persisted row count and spot-check.
cnt = spark.sql("SELECT COUNT(*) AS n FROM tmp_driver_code_reference_table").collect()[0]['n']
print(f"Delta table rows: {cnt}")
spark.sql("SELECT * FROM tmp_driver_code_reference_table LIMIT 10").show()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

##clear tmp table
# spark.sql("DROP TABLE IF EXISTS tmp_driver_code_reference_table")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 5b: Build the review table with FULL gold detail (in memory, no write yet)
# (all original gold columns for every flagged code; tagged by conflict_type)
# ============================================================

# All codes that need manual review: shared-code conflicts + SSN-mismatch breaks
shared_code_set = set(df_conflicts['drv_code'])
ssn_break_set   = set(df_ssn_conflict_review['history_code'])
review_codes    = shared_code_set | ssn_break_set

# Pull every original gold row (all columns) for those codes
df_review = df_full[df_full['drv_code'].isin(review_codes)].copy()

# Tag each row with why it's flagged (a code could in theory hit both types)
def classify(code):
    tags = []
    if code in shared_code_set:
        tags.append('shared_code')
    if code in ssn_break_set:
        tags.append('ssn_mismatch')
    return '+'.join(tags)

df_review.insert(0, 'conflict_type', df_review['drv_code'].apply(classify))
df_review = df_review.sort_values(['conflict_type', 'drv_code']).reset_index(drop=True)

# Summary
print(f"Review rows (full gold detail): {len(df_review)}")
print(f"  shared_code : {(df_review['conflict_type'] == 'shared_code').sum()}")
print(f"  ssn_mismatch: {(df_review['conflict_type'] == 'ssn_mismatch').sum()}")
print(f"  codes flagged: {sorted(review_codes)}")

# Key columns first (fits on screen for a quick scan)
key_cols = ['conflict_type', 'drv_code', 'drv_full_name', 'drv_social_security',
            'drv_address_line_1', 'drv_address_city', 'drv_address_state', 'drv_create_date']
print("\n--- key columns ---")
display(df_review[key_cols])

# Full gold detail (all columns, horizontally scrollable)
print("\n--- full gold detail ---")
display(df_review)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ———————————下面是分割线———————————— 
# 
# 核验tmp成表数量数量
