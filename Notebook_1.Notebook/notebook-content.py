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

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 1b: 属性去重 + 冲突隔离（不碰 df，Step 2 仍在全量 df 上抽指针）
# ============================================================
INVALID_SSN = {None, '', '000000000'}
df['drv_code'] = df['drv_code'].astype(str).str.strip().str.upper()

# 标记哪些行带有效 SSN
df['_ssn_valid'] = (
    (~df['drv_social_security'].isna()) &
    (~df['drv_social_security'].astype(str).str.strip().isin(INVALID_SSN))
).astype(int)

# 同一 code 下有 2 个及以上「不同的有效 SSN」= 两个真人共用一个 code（如 PRIS）
multi = df[df['_ssn_valid'] == 1].groupby('drv_code')['drv_social_security'].nunique()
collision_codes = set(multi[multi >= 2].index)

# 属性表：每个 code 只留一行，优先留有效 SSN 那条；冲突 code 先排除
df_attr = (df[~df['drv_code'].isin(collision_codes)]
           .sort_values('_ssn_valid', ascending=False)
           .drop_duplicates(subset=['drv_code'], keep='first')
           .drop(columns='_ssn_valid'))

# 冲突 code 明细单独留出来人工核查
df_collisions = df[df['drv_code'].isin(collision_codes)].drop(columns='_ssn_valid').copy()

df = df.drop(columns='_ssn_valid')   # df 复原，给 Step 2 抽指针用

print(f"原始行数/orignial table rows   : {len(df)}")
print(f"唯一code/unduplicate code number  : {df['drv_code'].nunique()}")
print(f"冲突 code/conflict code number  : {len(collision_codes)} -> {sorted(collision_codes)}")
print(f"df_attr 行 : {len(df_attr)}") #去掉真实重名‘PRIS’后的行数（无重复）

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# #查看code重复项
# all_dup = df['drv_code'].value_counts()
# all_dup = set(all_dup[all_dup > 1].index)
# #
# print(f"共有 {len(all_dup)} 个 code 存在重复物理记录：{sorted(all_dup)}")
# print(df[df['drv_code'].isin(all_dup)]
#       .sort_values(['drv_code', 'drv_create_date'])
#       .to_string(index=False))

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
# ============================================================
import re
def extract_code_from_address(address):
    if pd.isna(address):
        return None
 
    address = str(address).strip()
 
    # If the address line doesn't contain 'CODE', it's a normal address
    if 'CODE' not in address.upper():
        return None
 
    # 'CHANGED TO xxx' pattern -> take the code after 'TO'
    changed_match = re.search(r'CHANGED\s+TO\s+([A-Z0-9]+)', address)
    if changed_match:
        return changed_match.group(1)
 
    # Otherwise take the code after the last occurrence of 'CODE'
    all_matches = re.findall(r'CODE\s+([A-Z0-9]+)', address)
    if all_matches:
        candidate = all_matches[-1]
        # Contains a space or is empty -> noise, not a valid code
        if ' ' in candidate or candidate == '':
            return None
        return candidate
 
    return None
 
df['extracted_code'] = df['drv_address_line_1'].apply(extract_code_from_address)
 
# History codes: address line points to another code
history_codes = df[df['extracted_code'].notna()][['drv_code', 'extracted_code']].copy()
history_codes.columns = ['history_code', 'current_code']
history_codes = history_codes.drop_duplicates(subset=['history_code'], keep='first') ###新增

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
        # Circular reference guard
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

 # ---- Validation cases ----

# SEE NEW CODE
adams = history_codes[history_codes['history_code'].isin(['AANDR', 'AAND1', 'AANDR1'])]
print("\n SEE NEW CODE1:")
print(adams)
 
rojob = history_codes[history_codes['history_code'].isin(['ROJOB1', 'ROJO1', 'ROJOB'])]
print("\n SEE NEW CODE2:")
print(rojob)


# SEE OLD CODE
yatt = history_codes[history_codes['history_code'].isin(['YATT', 'YATTO'])]
print("\n SEE OLD CODE:")
print(yatt)

# SEE CORRECT CODE
wince = history_codes[history_codes['history_code'].isin(['WINCE','WINJON'])]
print("\n SEE CORRECT CODE:")
print(wince)

# CODE CHANGE TO
'ROHECT','ROHEC1','ROHE1'
rohec = history_codes[history_codes['history_code'].isin(['ROHECT','ROHEC1','ROHE1'])]
print("\n CODE CHANGE TO:")
print(rohec)

# SEE ORIGINAL CODE
coscha = history_codes[history_codes['history_code'].isin(['COSCHA','COCHAR'])]
print("\n SEE ORIGINAL CODE:")
print(coscha)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 3b: SSN 反验关卡
# 链条追溯后，比对两端 SSN：都有效且不一致 → 判可疑，断链回自己 + 记入 review
# ============================================================
INVALID_SSN = {None, '', '000000000'}
def valid_ssn(s):
    return pd.notna(s) and str(s).strip() not in INVALID_SSN

# 用 df_attr 取每个 code 的 SSN（每 code 一行，不会一对多）
ssn_lookup = df_attr.set_index('drv_code')['drv_social_security'].to_dict()

hc = history_codes.copy()
hc['_hist_ssn'] = hc['history_code'].map(ssn_lookup)
hc['_curr_ssn'] = hc['current_code'].map(ssn_lookup)

# 可疑条件：两端 SSN 都有效、且不相等、且不是自己映射自己
suspect = (
    hc['_hist_ssn'].apply(valid_ssn) &
    hc['_curr_ssn'].apply(valid_ssn) &
    (hc['_hist_ssn'].astype(str).str.strip() != hc['_curr_ssn'].astype(str).str.strip()) &
    (hc['history_code'] != hc['current_code'])
)

# review 表：保留断链前的原始指向，供人工核查
df_ssn_conflict_review = hc[suspect][
    ['history_code', 'current_code', '_hist_ssn', '_curr_ssn']
].rename(columns={'current_code': 'original_target',
                  '_hist_ssn': 'history_ssn', '_curr_ssn': 'current_ssn'}).copy()

# 断链：可疑行的 current_code 改回它自己
hc.loc[suspect, 'current_code'] = hc.loc[suspect, 'history_code']

history_codes = hc.drop(columns=['_hist_ssn', '_curr_ssn'])

print(f"SSN 反验：断开 {suspect.sum()} 条可疑映射")
if suspect.sum() > 0:
    print(df_ssn_conflict_review.to_string(index=False))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# 新Step 4: Build the final reference table
# 用 df_attr（每 code 一行、已排除冲突 code）替代 df，避免脏数据放大行数
# ============================================================

# 1) history mapping：去掉指向冲突 code 或自身是冲突 code 的边
hist_map = history_codes[
    ~history_codes['history_code'].isin(collision_codes) &
    ~history_codes['current_code'].isin(collision_codes)
][['history_code', 'current_code']].copy()

# 2) 从未作为 history_code 出现的，就是自身的 current code
#    骨架用 df_attr（干净、每 code 一行、不含冲突），而不是 df
all_history_codes = set(hist_map['history_code'])
current_only_codes = df_attr[~df_attr['drv_code'].isin(all_history_codes)][['drv_code']].copy()
current_only_codes['current_code'] = current_only_codes['drv_code']
current_only_codes = current_only_codes.rename(columns={'drv_code': 'history_code'})

# 3) 合并
reference_table = pd.concat([
    hist_map[['history_code', 'current_code']],
    current_only_codes[['history_code', 'current_code']]
], ignore_index=True).drop_duplicates()

# 4) 补属性：用 df_attr（每 code 一行，merge 不会一对多放大）
driver_info = df_attr[['drv_code', 'drv_full_name', 'drv_social_security', 'drv_create_date']]

reference_table = reference_table.merge(
    driver_info.rename(columns={
        'drv_code': 'history_code',
        'drv_full_name': 'history_full_name',
        'drv_social_security': 'history_ssn',
        'drv_create_date': 'history_create_date'
    }),
    on='history_code', how='left'
)

reference_table = reference_table.merge(
    driver_info.rename(columns={
        'drv_code': 'current_code',
        'drv_full_name': 'current_full_name',
        'drv_social_security': 'current_ssn',
        'drv_create_date': 'current_create_date'
    }),
    on='current_code', how='left'
)

print(f"\nFinal reference table rows: {len(reference_table)}")
print(f"Expected (= df_attr 唯一 code): {df_attr['drv_code'].nunique()}")
print(reference_table.head(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

#查看history_ssn和current_ssn的关系
print(reference_table[
    (reference_table['history_ssn']!='') & 
    (reference_table['history_ssn'].notna()) & 
    (reference_table['history_ssn']!=reference_table['current_ssn'])
    ])


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

INVALID_SSN = {None, '', '000000000'}
def valid_ssn(s):
    return pd.notna(s) and str(s).strip() not in INVALID_SSN

rt = reference_table
mask_real_conflict = (
    rt['history_ssn'].apply(valid_ssn) &
    rt['current_ssn'].apply(valid_ssn) &
    (rt['history_ssn'].astype(str).str.strip() != rt['current_ssn'].astype(str).str.strip()) &
    (rt['history_code'] != rt['current_code'])     # 排除自己映射自己
)
ssn_mismatch = rt[mask_real_conflict]
print(f"真·SSN 冲突映射行数: {len(ssn_mismatch)}")
print(ssn_mismatch[['history_code','current_code','history_full_name',
                    'history_ssn','current_full_name','current_ssn']].to_string(index=False))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

print(reference_table[reference_table['current_full_name'].isna()])

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# # ============================================================
# # Step 4: Build the final reference table
# # (every driver code mapped to its current code, plus SSN /
# #  name / create date pulled in from the driver master)
# # ============================================================
# # Codes that never appear as a history_code are themselves current codes
# all_history_codes = set(history_codes['history_code'])
# current_only_codes = df[~df['drv_code'].isin(all_history_codes)][['drv_code']].copy()
# current_only_codes['current_code'] = current_only_codes['drv_code']
# current_only_codes = current_only_codes.rename(columns={'drv_code': 'history_code'})
 
# # Combine history mappings + current-only codes into one reference table
# reference_table = pd.concat([
#     history_codes[['history_code', 'current_code']],
#     current_only_codes[['history_code', 'current_code']]
# ], ignore_index=True).drop_duplicates()
 
# # Enrich with driver info
# driver_info = df[['drv_code', 'drv_full_name', 'drv_social_security', 'drv_create_date']]
 
# reference_table = reference_table.merge(
#     driver_info.rename(columns={
#         'drv_code': 'history_code',
#         'drv_full_name': 'history_full_name',
#         'drv_social_security': 'history_ssn',
#         'drv_create_date': 'history_create_date'
#     }),
#     on='history_code', how='left'
# )
 
# reference_table = reference_table.merge(
#     driver_info.rename(columns={
#         'drv_code': 'current_code',
#         'drv_full_name': 'current_full_name',
#         'drv_social_security': 'current_ssn',
#         'drv_create_date': 'current_create_date'
#     }),
#     on='current_code', how='left'
# )
 
# print(f"\nFinal reference table rows: {len(reference_table)}")
# print(reference_table.head(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# 检查总数是否对得上
print(f"Reference table rows: {len(reference_table)}")
print(f"Original gold table rows: {len(df)}")
print(f"Original driver codes: {df['drv_code'].nunique()}")

# 找出重复的history_code
dup = reference_table[reference_table.duplicated(subset=['history_code'], keep=False)]
print(f"\nDuplicate history_codes: {len(dup)}")
print(dup.sort_values('history_code'))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# ============================================================
# Step 5: Write to Delta table
# ============================================================
result_spark_df = spark.createDataFrame(reference_table)
 
result_spark_df.write \
    .mode("overwrite") \
    .saveAsTable("driver_code_reference_table")
 
print("Written to Delta table: driver_code_reference_table")
 
spark.sql("SELECT * FROM driver_code_reference_table LIMIT 10").show()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
