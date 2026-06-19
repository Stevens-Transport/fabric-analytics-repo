/***************************************************************************************************
Procedure:          dbo.usp_ibmi_preplan_overrides_silver
Create Date:        2026-06-19
Author:             Jeremy Shahan
Description:        Truncate and load of Preplan Overrides to Silver
Called by:          Fabric
					Pipeline: ibmi_preplan_overrides
Affected table(s):  silver.ibmi_preplan_overrides
Usage:              EXEC dbo.usp_ibmi_preplan_overrides_silver

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE         PROCEDURE [dbo].[usp_ibmi_preplan_overrides_silver]
AS

SET NOCOUNT ON

DELETE FROM silver.ibmi_preplan_overrides

INSERT INTO silver.ibmi_preplan_overrides
SELECT

        TRIM(a.PVORD#)                                                                                AS preplan_overrides_load_number
      , TRIM(a.PVSEG)                                                                                 AS preplan_overrides_dispatch
      , TRIM(a.PVUNIT)                                                                                AS preplan_overrides_planned_truck_number
      , TRIM(a.PVMODL)                                                                                AS preplan_overrides_model_recommended_truck_number
      , CASE
            WHEN TRIM(a.PVUNPL) = 'Y' 
                THEN 'TRUE'
            ELSE 'FALSE' END                                                                          AS is_unplanned
      , TRIM(a.PVMDPL)                                                                                AS preplan_overrides_model_plan_code
      , TRIM(a.PVOVCD)                                                                                AS preplan_overrides_override_code
      , TRIM(a.PVDESC)                                                                                AS preplan_overrides_override_description
      , a.DISPATCH_DATETIME                                                                           AS preplan_overrides_dispatch_datetime
      , a.CREATE_DATETIME                                                                             AS preplan_overrides_create_datetime
      , TRIM(a.PVDMOD)                                                                                AS preplan_overrides_model_recommended_at_dispatch
      , TRIM(a.PVDMDP)                                                                                AS preplan_overrides_model_plan_at_dispatch
      , TRIM(a.PVUSER)                                                                                AS preplan_overrides_user_code
      , TRIM(a.PVAREA)                                                                                AS preplan_overrides_area_code
--INTO data_central_wh.silver.ibmi_preplan_overrides
FROM data_central_lh.dbo.ibmi_preplan_overrides_bronze a