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
# META     }
# META   }
# META }

# CELL ********************

import pandas as pd

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = pd.read_excel(
    "/lakehouse/default/Files/Driver Code Change Examples.xlsx",
    sheet_name="Sheet1"
)

print(df.shape)
print(df.head())

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# standardize column name
df.columns = ['current_code', 'orientation_date', 'ssn', 'tier_1', 'tier_2', 'tier_3']

# write into delta table
spark.createDataFrame(df).write \
    .mode("overwrite") \
    .saveAsTable("driver_code_excel_upload")

print("wirting complete!")

# validation
spark.sql("SELECT * FROM driver_code_excel_upload LIMIT 5").show()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# delete this table when finish use
spark.sql("DROP TABLE IF EXISTS driver_code_excel_upload")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
