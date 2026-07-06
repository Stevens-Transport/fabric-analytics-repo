/***************************************************************************************************
Procedure:          dbo.usp_ibmi_appointment_changes_silver
Create Date:        2026-06-30
Author:             Jeremy Shahan
Description:        Truncate and load of Appointment Changes to Silver
Called by:          Fabric
					Pipeline: ibmi_appointment_changes
Affected table(s):  silver.ibmi_appointment_changes
Usage:              EXEC dbo.usp_ibmi_appointment_changes_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE         PROCEDURE [dbo].[usp_ibmi_appointment_changes_silver]
AS

SET NOCOUNT ON

DELETE FROM silver.ibmi_appointment_changes

INSERT INTO silver.ibmi_appointment_changes
SELECT
       TRIM([AHORD])                                                    AS appt_chgs_load_number
      ,[AHSTP]                                                          AS appt_chgs_stop_number
      ,CASE
        TRIM([AHTYPE])
            WHEN 'P' THEN 'PICKUP'
            WHEN 'D' THEN 'DELIVERY'
            WHEN 'S' THEN 'STOP'
            ELSE 'unknown' END                                          AS appt_chgs_type
      ,[AHORDT]                                                         AS appt_chgs_original_appointment_datetime
      ,[AHCHDT]                                                         AS appt_chgs_changed_appointment_datetime
      ,[AHCUSR]                                                         AS appt_chgs_appointment_change_user_code
      ,[AHCHGD]                                                         AS appt_chgs_change_datetime
      --,[AHFLD]                                                        AS appt_chgs_
--INTO data_central_wh.silver.ibmi_appointment_changes
FROM data_central_lh.dbo.ibmi_appointment_changes_bronze