# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# MARKDOWN ********************

# # 🧩 Fabric Notebook Template — Environment-Aware LH & WH
# 
# Copy as the start of any notebook. **Never hardcode a LH/WH name or GUID** — values come from `vl_fabricConfig` (vars: `defaultLakehouseName`, `defaultLakehouseGuid`, `defaultWorkspaceGuid`, `warehouseName`).
# 
# `%%configure` must stay the first cell.


# CELL ********************

# MAGIC %%configure
# MAGIC {
# MAGIC     "defaultLakehouse": {
# MAGIC         "name": { "variableName": "$(/**/vl_fabricConfig/defaultLakehouseName)" },
# MAGIC         "id": { "variableName": "$(/**/vl_fabricConfig/defaultLakehouseGuid)" },
# MAGIC         "workspaceId": { "variableName": "$(/**/vl_fabricConfig/defaultWorkspaceGuid)" }
# MAGIC     }
# MAGIC }

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

vl = notebookutils.variableLibrary.getLibrary("vl_fabricConfig")
warehouseName = vl.warehouseName

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Lakehouse read 
spark.conf.set("spark.sql.parquet.datetimeRebaseModeInRead", "LEGACY")

df_lh = spark.read.table("ibmi_preplan_tracking_bronze").limit(10)
display(df_lh)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Warehouse read (connector uses warehouseName)
from com.microsoft.spark.fabric.Constants import Constants
df_wh = spark.read.synapsesql(f"{warehouseName}.gold.dim_area").limit(10)
display(df_wh)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
