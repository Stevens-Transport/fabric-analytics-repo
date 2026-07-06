/***************************************************************************************************
Procedure:          dbo.usp_ibmi_late_fees_silver
Create Date:        2026-06-25
Author:             Jeremy Shahan
Description:        Truncate and load of Late Fees to Silver
Called by:          Fabric
					Pipeline: ibmi_late_fees
Affected table(s):  silver.ibmi_late_fees
Usage:              EXEC dbo.usp_late_fees_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE     PROCEDURE [dbo].[usp_ibmi_late_fees_silver]
AS

SET NOCOUNT ON

DELETE FROM silver.ibmi_late_fees

INSERT INTO silver.ibmi_late_fees
SELECT 
        TRIM(a.LFODR)                                     AS late_fees_load_number
      , TRIM(a.LFDSP)                                     AS late_fees_dispatch
      , TRIM(a.LFUNIT)                                    AS late_fees_truck_number
      , TRIM(a.LFDRV1)                                    AS late_fees_driver_seat_1 
      , TRIM(a.LFDRV2)                                    AS late_fees_driver_seat_2
      , a.LFCRTDT                                         AS late_fees_create_date
      , TRIM(a.LFCRTUR)                                   AS late_fees_create_user_code
      , a.LFHRSLAT                                        AS late_fees_house_late
      , TRIM(a.LFWHY)                                     AS late_fees_reason_why
      , TRIM(a.LFWHAT)                                    AS late_fees_fee_description
      , TRIM(a.LFWILL)                                    AS late_fees_reimbursment_flag
      , TRIM(a.LFIFNOT)                                   AS late_fees_alternative   
      , a.LFDATE                                          AS late_fees_last_updated_date
      , TRIM(a.LFUSER)                                    AS late_fees_last_updated_user_code
      , CASE TRIM(a.LFVRFY)
            WHEN 'Y' THEN 'TRUE'
            WHEN 'N' THEN 'FALSE'
            ELSE 'unknown' END                            AS is_verified
      , a.LFAMT                                           AS late_fees_amount
      , a.LFSTP                                           AS late_fees_stop_number
--INTO data_central_wh.silver.ibmi_late_fees
FROM data_central_lh.dbo.ibmi_late_fees_bronze a