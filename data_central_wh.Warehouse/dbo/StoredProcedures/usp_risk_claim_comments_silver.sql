/***************************************************************************************************
Procedure:          dbo.usp_risk_claim_comments_silver
Create Date:        2026-06-30
Author:             Jeremy Shahan
Description:        Truncate and load of Claim Comments to Silver
Called by:            Fabric
					Pipeline: risk_claim_comments
Affected table(s):  silver.risk_claim_comments
Usage:              EXEC dbo.usp_risk_claim_comments_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE   PROCEDURE [dbo].[usp_risk_claim_comments_silver]
AS

SET NOCOUNT ON

TRUNCATE TABLE silver.risk_claim_comments

INSERT INTO silver.risk_claim_comments
SELECT
       [CLAIMMASTERRECORDID]                            AS claim_comments_record_code
      ,[INVOLVEDPARTYRECORDID]                          AS claim_comments_involved_party_code
      ,[COMMENTRECORDID]                                AS claim_comments_comment_code
      ,[COMMENTS]                                       AS claim_comments_comment
      ,[COMMENTDATE]                                    AS claim_comments_comment_datetime
      ,[CREATEDATE]                                     AS claim_comments_create_datetime
      ,[CREATEUSER]                                     AS claim_comments_create_user_code
      ,[CHANGEDATE]                                     AS claim_comments_last_updat_datetime
      ,[CHANGEUSER]                                     AS claim_comments_last_update_user
      ,[COMMENTTYPE]                                    AS claim_comments_comment_type_code
--INTO data_central_wh.silver.risk_claim_comments
FROM data_central_lh.dbo.risk_file_comment_bronze a