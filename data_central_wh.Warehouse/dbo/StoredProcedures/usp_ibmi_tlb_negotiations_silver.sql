/***************************************************************************************************
Procedure:          dbo.usp_ibmi_tlb_negotiations_silver
Create Date:        2026-05-21
Author:             Jeremy Shahan
Description:        Truncate and load of Brokerage Negotiations to Silver
Called by:          Fabric
					Pipeline: ibmi_tlb_negotiations
Affected table(s):  silver.ibmi_tlb_negotiations
Usage:              EXEC dbo.usp_ibmi_tlb_negotiations_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE         PROCEDURE [dbo].[usp_ibmi_tlb_negotiations_silver]
AS

SET NOCOUNT ON

DELETE FROM silver.ibmi_tlb_negotiations

INSERT INTO silver.ibmi_tlb_negotiations
SELECT
        TRIM(a.BNSTAT)                                                                          AS tlb_negotiations_status_code
      , TRIM(a.BNCO)                                                                            AS tlb_negotiations_company_number
      , a.BNSEQ                                                                                 AS tlb_negotiations_sequence_number
      , TRIM(a.BNOWNR)                                                                          AS tlb_negotiations_owner_code
      , TRIM(a.BNORD)                                                                           AS tlb_negotiations_load_number
      --, a.BNPERC                                                                               
      --, a.BNLRAT
      --, a.BNERAT
      , a.BNFAMT                                                                                AS tlb_negotiations_flat_amount
      , CONVERT(INT, a.BNAC) + CONVERT(INT, a.BNTEL)                                            AS tlb_negotiations_contact_phone_number
      , TRIM(a.BNCNAM)                                                                          AS tlb_negotiations_contact_name
      , TRIM(a.BNRSLT)                                                                          AS tlb_negotiations_result_code
      --, a.BNOCNT
      --, a.BNODSP
      --, TRIM(a.BNORIG)
      --, TRIM(a.BNSHIP)
      --, TRIM(a.BNDEST)
      --, a.BNCMPL
      , BNDATE.date_key_pk															            AS tlb_negotiations_negotiation_date
	  , CASE 
			WHEN TRIM(a.BNTIME) <= 2359 
				AND LEN(CONVERT(VARCHAR(4),CONVERT(INT,TRIM(a.BNTIME)))) = 4 
			THEN TIMEFROMPARTS(LEFT(CONVERT(INT,TRIM(a.BNTIME)),2),RIGHT(CONVERT(INT,TRIM(a.BNTIME)),2),0,0,0)
			WHEN TRIM(a.BNTIME) <= 2359 
				AND LEN(CONVERT(VARCHAR(4),CONVERT(INT,TRIM(a.BNTIME)))) = 3 
			THEN TIMEFROMPARTS(LEFT(CONVERT(INT,TRIM(a.BNTIME)),1),RIGHT(CONVERT(INT,TRIM(a.BNTIME)),2),0,0,0)
			WHEN TRIM(a.BNTIME) <= 2359 
				AND LEN(CONVERT(VARCHAR(4),CONVERT(INT,TRIM(a.BNTIME)))) IN (1,2)
			THEN TIMEFROMPARTS(0,CONVERT(INT,TRIM(a.BNTIME)),0,0,0)
			ELSE NULL END						                        						AS tlb_negotiations_negotiation_time     
      , TRIM(a.BNUSER)                                                                          AS tlb_negotiations_negotiation_user_code
--INTO data_central_wh.silver.ibmi_tlb_negotiations
FROM data_central_lh.dbo.ibmi_tlb_negotiations_bronze a
LEFT JOIN gold.dim_date BNDATE ON a.BNDATE = BNDATE.date_ordinal