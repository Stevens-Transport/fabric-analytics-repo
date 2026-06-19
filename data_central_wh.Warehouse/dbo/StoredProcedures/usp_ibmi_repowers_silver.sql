/***************************************************************************************************
Procedure:          dbo.usp_ibmi_repowers_silver
Create Date:        2026-06-19
Author:             Jeremy Shahan
Description:        Truncate and load of Repowers to Silver
Called by:          Fabric
					Pipeline: ibmi_repowers
Affected table(s):  silver.ibmi_repowers
Usage:              EXEC dbo.usp_ibmi_repowers_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE         PROCEDURE [dbo].[usp_ibmi_repowers_silver]
AS

SET NOCOUNT ON

DELETE FROM silver.ibmi_repowers

INSERT INTO silver.ibmi_repowers
SELECT

        TRIM(a.SDDRVR1)                                                                     AS repowers_truck_number_1
      , TRIM(a.SDLOAD1)                                                                     AS repowers_load_number_1
      , TRIM(a.SDDISP1)                                                                     AS repowers_dispatch_1
      , TRIM(a.SDDRVR2)                                                                     AS repowers_truck_number_2
      , TRIM(a.SDLOAD2)                                                                     AS repowers_load_number_2
      , TRIM(a.SDDISP2)                                                                     AS repowers_dispatch_2
      , CASE
            TRIM(a.SDSTATUS)
                WHEN 'FLD' THEN 'FAILED'
                WHEN 'RMV' THEN 'REMOVED'
                WHEN 'PLN' THEN 'PLANNED'
                WHEN 'CMP' THEN 'COMPLETED'
                WHEN 'HLD' THEN 'HOLD'
                ELSE 'unknown' END                                                          AS repowers_status
      --, a.SDSTSD
      --, a.SDSTST
      , a.STATUS_DATETIME                                                                   AS repowers_status_datetime
      , TRIM(a.SDUSER)                                                                      AS repowers_swap_user_code
      , TRIM(a.SDLOC)                                                                       AS repowers_swap_location_code
      , TRIM(a.SDSTOP)                                                                      AS repowers_swap_stop_number
      --, a.SDDATE
      --, a.SDTIME
      , a.SWAP_DATETIME                                                                     AS repowers_swap_datetime
      , TRIM(a.SDNXT1)                                                                      AS repowers_next_location_code_post_swap_1
      , TRIM(a.SDNXT2)                                                                      AS repowers_next_location_code_post_swap_2
      , TRIM(a.SDREAS)                                                                      AS repowers_swap_reason_code
      , TRIM(a.SDCRTU)                                                                      AS repowers_create_user_code
      --, a.SDCRTD
      --, a.SDCRTT
      , a.CREATE_DATETIME                                                                   AS repowers_create_datetime
      , CASE
            TRIM(a.SDCHRG)
                WHEN 'Y' THEN 'TRUE'
                WHEN 'N' THEN 'FALSE'
                ELSE 'unknown' END                                                          AS is_chargeable_to_driver
--INTO data_central_wh.silver.ibmi_repowers
FROM data_central_lh.dbo.ibmi_repowers_bronze a