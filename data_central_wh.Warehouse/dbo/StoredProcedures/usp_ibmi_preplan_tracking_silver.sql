CREATE           PROCEDURE [dbo].[usp_ibmi_preplan_tracking_silver]
AS

SET NOCOUNT ON

DELETE FROM silver.ibmi_preplan_tracking

INSERT INTO silver.ibmi_preplan_tracking
SELECT

      TRIM([OPODR])                  AS preplan_tracking_load_number,
      TRIM([OPUNIT])                 AS preplan_tracking_truck_number,
      TRIM([OPDR1])                  AS preplan_tracking_driver_seat_1,
      TRIM([OPDR2])                  AS preplan_tracking_driver_seat_2,
      TRIM([OPTEAM])                 AS preplan_tracking_team_status_code,
      TRIM([OPSUPR])                 AS preplan_tracking_dm,
      TRIM([OPFMGR])                 AS preplan_tracking_dmol,
      [OPDSNT]                       AS preplan_tracking_sent_date,
      [OPTSNT]                       AS preplan_tracking_sent_time,
      TRIM([OPSUSR])                 AS preplan_tracking_sent_user_code,
      [OPDRSP]                       AS preplan_tracking_responded_date,
      [OPTRSP]                       AS preplan_tracking_responded_time,
      CASE 
            TRIM(OPACPT) 
            WHEN 'Y' then 'TRUE'
            WHEN 'N' then 'FALSE' 
            ELSE 'unknown'
            END                     AS is_accepted,
      [OPDCNL]                      AS preplan_tracking_cancel_date,
      [OPTCNL]                      AS preplan_tracking_cancel_time,
      TRIM([OPCUSR])                AS preplan_tracking_cancel_user_code,
      CASE 
            TRIM(OPCNCL)
            WHEN 'Y' then 'TRUE' 
            ELSE 'FALSE' 
            END                     AS is_canceled,
      [OPCRTD]                      AS preplan_tracking_data_created,
      [OPCRTT]                      AS preplan_tracking_time_created

--INTO data_central_wh.silver.ibmi_preplan_tracking
FROM data_central_lh.dbo.ibmi_preplan_tracking_bronze