/***************************************************************************************************
Procedure:          dbo.usp_risk_claim_type_silver
Create Date:        2026-06-30
Author:             Jeremy Shahan
Description:        Truncate and load of Claim Type Silver
Called by:            Fabric
					Pipeline: risk_claim_type
Affected table(s):  silver.risk_claim_type
Usage:              EXEC dbo.usp_risk_claim_type_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE       PROCEDURE [dbo].[usp_risk_claim_type_silver]
AS

SET NOCOUNT ON

TRUNCATE TABLE silver.risk_claim_type

INSERT INTO silver.risk_claim_type
SELECT
        [CLAIMMASTERTYPECODE]                            AS claim_type_code
      , TRIM([CLAIMMASTERTYPEDESC])                      AS claim_type_description
      , [CREATEDATE]                                     AS claim_type_create_datetime
      , TRIM([CREATEUSER])                               AS claim_type_create_user_code
      , [CHANGEDATE]                                     AS claim_type_last_updated_datetime
      , [CHANGEUSER]                                     AS claim_type_last_updated_user_code
      , CASE
            [ACTIVEYN]
            WHEN 'Y' THEN 'TRUE'
            ELSE 'FALSE' END                             AS is_active
--INTO data_central_wh.silver.risk_claim_type
FROM data_central_lh.dbo.risk_claim_type_bronze