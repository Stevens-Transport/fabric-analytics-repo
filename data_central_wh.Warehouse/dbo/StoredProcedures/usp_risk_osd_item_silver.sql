/***************************************************************************************************
Procedure:          dbo.usp_risk_osd_item_silver
Create Date:        2026-06-30
Author:             Jeremy Shahan
Description:        Truncate and load of OS & D Items to Silver
Called by:            Fabric
					Pipeline: risk_osd_item
Affected table(s):  silver.risk_osd_item
Usage:              EXEC dbo.usp_risk_osd_item_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE       PROCEDURE [dbo].[usp_risk_osd_item_silver]
AS

SET NOCOUNT ON

TRUNCATE TABLE silver.risk_osd_item

INSERT INTO silver.risk_osd_item
SELECT
       [ATTACHEDTORECORDID]                              AS osd_item_attached_record_code
      ,[OSDITEMRECORDID]                                 AS osd_item_item_record_code
      ,[DISCREPANCYTYPECODE]                             AS osd_item_discrepancy_type_code
      ,[DAMAGETYPECODE]                                  AS osd_item_damage_type_code
      ,[DISPOSITIONCODE]                                 AS osd_item_disposition_code
      ,[DAMAGECAUSECODE]                                 AS osd_item_damage_cause_code
      ,[QUANTITY]                                        AS osd_item_quantity
      ,[UNITOFMEASURECODE]                               AS osd_item_unit_of_measure_code
      ,[PRODUCTCODE]                                     AS osd_item_product_code
      ,[PRODUCTDESCRITION]                               AS osd_item_product_description
      ,[COMMODITYCODE]                                   AS osd_item_commodity_code
      ,[STOPOFF]                                         AS osd_item_stopoff
      ,[RETURNFEE]                                       AS osd_item_return_fee_amount
      ,[EXPECTEDWEIGHT]                                  AS osd_item_expected_weight
      ,[DELIVEREDWEIGHT]                                 AS osd_item_delivered_weight
      ,[EXPECTEDCONDCODE]                                AS osd_item_expected_condition_code
      ,[DELIVEREDCONDCODE]                               AS osd_item_delivered_condition_code
      ,[COMMENTS]                                        AS osd_item_comments
      ,[CREATEDATE]                                      AS osd_item_created_datetime
      ,[CREATEUSER]                                      AS osd_item_created_by_user_code
      ,[CHANGEDATE]                                      AS osd_item_last_updated_datetime
      ,[CHANGEUSER]                                      AS osd_item_last_updated_by_user_code
      ,[QUANTITYREFUSED]                                 AS osd_item_quantity_refused
      --,[SIGNEDBY]                                        AS osd_item_signed_by
      ,[QUANTITYDAMAGED]                                 AS osd_item_quantity_damaged
      ,[QUANTITYOVER]                                    AS osd_item_quantity_over
      ,[QUANTITYSHORT]                                   AS osd_item_quantity_short
      ,[QUANTITYKEPT]                                    AS osd_item_quantity_kept
--INTO data_central_wh.silver.risk_osd_item
FROM data_central_lh.dbo.risk_osditem_bronze