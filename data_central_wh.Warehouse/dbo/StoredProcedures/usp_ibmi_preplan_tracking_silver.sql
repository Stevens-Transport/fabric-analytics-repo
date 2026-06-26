/***************************************************************************************************
Procedure:          dbo.usp_ibmi_preplan_tracking_silver
Create Date:        2026-06-26
Author:             Jeremy Shahan
Description:        Truncate and load of Preplan Tracking to Silver
Called by:          Fabric
					Pipeline: ibmi_preplan_tracking
Affected table(s):  silver.ibmi_preplan_tracking
Usage:              EXEC dbo.usp_ibmi_preplan_tracking_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/


CREATE             PROCEDURE [dbo].[usp_ibmi_preplan_tracking_silver]
AS

SET NOCOUNT ON

DELETE FROM silver.ibmi_preplan_tracking

INSERT INTO silver.ibmi_preplan_tracking

SELECT

        TRIM([OPODR])                                       AS preplan_tracking_load_number
      , TRIM([OPUNIT])                                      AS preplan_tracking_truck_number
      , TRIM([OPDR1])                                       AS preplan_tracking_driver_seat_1
      , TRIM([OPDR2])                                       AS preplan_tracking_driver_seat_2
      , TRIM([OPTEAM])                                      AS preplan_tracking_team_status_code
      , TRIM([OPSUPR])                                      AS preplan_tracking_dm
      , TRIM([OPFMGR])                                      AS preplan_tracking_dmol
      , CASE
            WHEN [OPDSNT] = '0001-01-01'
                THEN NULL
            ELSE [OPDSNT] 
            END                                             AS preplan_tracking_sent_date
      , CASE
            WHEN [OPDSNT] = '0001-01-01'
                THEN NULL
            ELSE CAST(REPLACE([OPTSNT], '.', ':') AS TIME(6))
            END                                             AS preplan_tracking_sent_time
      , TRIM([OPSUSR])                                      AS preplan_tracking_sent_user_code
      , CASE
            WHEN [OPDRSP] = '0001-01-01'
                THEN NULL
            ELSE [OPDRSP] 
            END                                             AS preplan_tracking_response_date
      , CASE
            WHEN [OPDRSP] = '0001-01-01'
                THEN NULL
            ELSE CAST(REPLACE([OPTRSP], '.', ':') AS TIME(6))
            END                                             AS preplan_tracking_response_time
      , CASE 
            TRIM(OPACPT) 
            WHEN 'Y' then 'TRUE'
            WHEN 'N' then 'FALSE' 
            ELSE 'unknown'
            END                                             AS is_accepted
      , CASE
            WHEN [OPDCNL] = '0001-01-01'
                THEN NULL
            ELSE [OPDCNL] 
            END                                             AS preplan_tracking_cancel_date
      , CASE
            WHEN [OPDCNL] = '0001-01-01'
                THEN NULL
            ELSE CAST(REPLACE([OPTCNL], '.', ':') AS TIME(6))
            END                                             AS preplan_tracking_cancel_time
      , TRIM([OPCUSR])                                      AS preplan_tracking_cancel_user_code
      , CASE 
            TRIM(OPCNCL)
            WHEN 'Y' then 'TRUE' 
            ELSE 'FALSE' 
            END                                     AS is_canceled
      , CASE
            WHEN [OPCRTD] = '0001-01-01'
                THEN NULL
            ELSE [OPCRTD] 
            END                                             AS preplan_tracking_create_date
      , CASE
            WHEN [OPCRTD] = '0001-01-01'
                THEN NULL
            ELSE CAST(REPLACE([OPCRTT], '.', ':') AS TIME(6))
            END                                             AS preplan_tracking_create_time
--INTO data_central_wh.silver.ibmi_preplan_tracking
FROM data_central_lh.dbo.ibmi_preplan_tracking_bronze