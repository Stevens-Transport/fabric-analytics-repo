# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "f9a73da1-08e4-4f3d-a67f-74623bfde721",
# META       "default_lakehouse_name": "data_central_lh",
# META       "default_lakehouse_workspace_id": "a6d2c31b-0b03-4c60-a258-c2664c56fe3d",
# META       "known_lakehouses": [
# META         {
# META           "id": "f9a73da1-08e4-4f3d-a67f-74623bfde721"
# META         }
# META       ]
# META     },
# META     "warehouse": {
# META       "known_warehouses": [
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

# Extract edges from address line
import re

def extract_next_code(address):
    if pd.isna(address):
        return None
    
    address = str(address).strip()
    
    # Handle 'CHANGED TO xxx' pattern first
    changed_match = re.search(r'CHANGED\s+TO\s+([A-Z0-9]+)', address)
    if changed_match:
        return changed_match.group(1)
    
    # Find last occurrence of 'CODE' followed by a space and a code
    # Match 'CODE' + whitespace + alphanumeric code
    all_matches = re.findall(r'CODE\s+([A-Z0-9]+)', address)
    if all_matches:
        candidate = all_matches[-1]  # take the last match
        return candidate
    
    return None

# re-applay
edges_df = df[df['drv_address_line_1'].str.contains('CODE', na=False)].copy()
edges_df['next_code'] = edges_df['drv_address_line_1'].apply(extract_next_code)
edges_df = edges_df[edges_df['next_code'].notna()][['drv_code', 'next_code']]

print(f"Total edges: {len(edges_df)}")
print(edges_df.head(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Build edge map and recursively find current code
edge_map = dict(zip(edges_df['drv_code'], edges_df['next_code']))

def find_current_code(code, visited=None):
    """Follow the chain until no more next_code."""
    if visited is None:
        visited = set()
    if code in visited:
        print(f"Warning: circular reference at {code}")
        return code
    visited.add(code)
    if code not in edge_map:
        return code  # end of chain
    return find_current_code(edge_map[code], visited)

# Apply to all old codes
edges_df['current_code'] = edges_df['drv_code'].apply(find_current_code)

print("Sample results:")
print(edges_df[['drv_code', 'next_code', 'current_code']].head(10))

# Verify: check a known case (Andrew Adams)
known_codes = edges_df[edges_df['drv_code'].isin(['AANDR', 'AAND1', 'AANDR1'])]
print("\nAndrew Adams case:")
print(known_codes)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Step 3: 找到每条链上的所有成员，再用create_date判断current code
edge_map = dict(zip(edges_df['drv_code'], edges_df['next_code']))

def find_chain(code, visited=None):
    """Find all codes in the same chain"""
    if visited is None:
        visited = set()
    if code in visited:
        return visited
    visited.add(code)
    if code in edge_map:
        find_chain(edge_map[code], visited)
    return visited

# 建立create_date字典
date_map = dict(zip(df['drv_code'], df['drv_create_date']))

# 对每个有edge的code找出整条链，再找最新的
results = []
processed = set()

for code in edges_df['drv_code']:
    if code in processed:
        continue
    chain = find_chain(code)
    processed.update(chain)
    
    # 找链上create_date最新的作为current code
    chain_with_dates = [(c, date_map.get(c)) for c in chain if date_map.get(c) is not None]
    if chain_with_dates:
        current_code = max(chain_with_dates, key=lambda x: x[1])[0]
        for old_code in chain:
            if old_code != current_code:
                results.append({'history_code': old_code, 'current_code': current_code})

mapping_df = pd.DataFrame(results)
print(f"Total mappings: {len(mapping_df)}")

# 验证Andrew Adams
# adams = mapping_df[mapping_df['history_code'].isin(['AANDR', 'AAND1', 'AANDR1'])]
# print("\nAndrew Adams case:")
# print(adams)

rojob = mapping_df[mapping_df['history_code'].isin(['ROJOB1', 'ROJO1', 'ROJOB'])]
print("\n rojob case:")
print(rojob)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# 查看Andrew Adams三个code的创建日期
# adams_codes = df[df['drv_code'].isin(['AANDR', 'AAND1', 'AANDR1'])]
# print(adams_codes[['drv_code', 'drv_create_date', 'drv_status_code', 'drv_address_line_1']])

test = df[df['drv_full_name'].isin(['ROWELL, JOHN B.','LEMUS, JORGE','KNIGHT, PAUL A.','WILSON, ANTHONY(TONY)'])]
print(test[['drv_code', 'drv_create_date', 'drv_status_code', 'drv_address_line_1']])

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# 对全量数据执行提取逻辑
def extract_code_from_address(address):
    if pd.isna(address):
        return None
    
    address = str(address).strip()
    
    # 如果地址栏不含CODE，直接返回None（正常地址）
    if 'CODE' not in address.upper():
        return None
    
    # CHANGED TO → 取TO后面的code
    changed_match = re.search(r'CHANGED\s+TO\s+([A-Z0-9]+)', address)
    if changed_match:
        return changed_match.group(1)
    
    # 找最后一个CODE后面的内容
    all_matches = re.findall(r'CODE\s+([A-Z0-9]+)', address)
    if all_matches:
        candidate = all_matches[-1]
        # 包含空格或为空 → NULL（噪音）
        if ' ' in candidate or candidate == '':
            return None
        return candidate
    
    return None

# 对全量数据执行
df['extracted_code'] = df['drv_address_line_1'].apply(extract_code_from_address)

# current code = extracted_code为空的
current_codes = df[df['extracted_code'].isna()][['drv_code', 'drv_full_name', 'drv_social_security', 'drv_create_date']]

# history code = extracted_code有值的
history_codes = df[df['extracted_code'].notna()][['drv_code', 'extracted_code']]
history_codes.columns = ['history_code', 'current_code']

print(f"Current codes: {len(current_codes)}")
print(f"History codes: {len(history_codes)}")
print("\nSample history codes:")
print(history_codes.head(10))

# 验证Andrew Adams
adams = history_codes[history_codes['history_code'].isin(['AANDR', 'AAND1', 'AANDR1'])]
print("\nAndrew Adams case:")
print(adams)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# 【最新】

# 建立edge map
edge_map = dict(zip(history_codes['history_code'], history_codes['current_code']))

# 找到链条终点（没有被指向的那个）
def find_final_current(code, visited=None):
    if visited is None:
        visited = set()
    if code in visited:  # 循环引用
        return code
    visited.add(code)
    if code not in edge_map:
        return code  # 终点
    return find_final_current(edge_map[code], visited)

# 对所有history code追溯到最终current code
history_codes['current_code'] = history_codes['history_code'].apply(find_final_current)

print(f"Total mappings: {len(history_codes)}")

# 验证Andrew Adams
adams = history_codes[history_codes['history_code'].isin(['AANDR', 'AAND1', 'AANDR1'])]
print("\nAndrew Adams case:")
print(adams)

rojob = history_codes[history_codes['history_code'].isin(['ROJOB1', 'ROJO1', 'ROJOB'])]
print("\n rojob case:")
print(rojob)

anjo = history_codes[history_codes['history_code'].isin(['ANJO1', 'ANJOH1', 'ANJOH'])]
print("\n anjo case:")
print(anjo)

# see old code
yatt = history_codes[history_codes['history_code'].isin(['YATT', 'YATTO'])]
print("\n yatt case:")
print(yatt)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
