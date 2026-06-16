/***************************************************************************************************
Procedure:          dbo.usp_reports_wbr_goals
Create Date:        2026-05-20
Author:             Jeremy Shahan
Description:        Truncate and load of WBR Goals to Gold
Called by:            Azure Data Factory
					Pipeline: dim_reports_wbr_goals
Affected table(s):  gold.dim_reports_wbr_goals
Usage:              EXEC dbo.usp_reports_wbr_goals

****************************************************************************************************
SUMMARY OF CHANGES
#             Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------ ------------------------------------------------------------
1            
***************************************************************************************************/

CREATE     PROCEDURE [dbo].[usp_reports_wbr_goals]
AS

SET NOCOUNT ON

DELETE FROM gold.dim_reports_wbr_goals

INSERT INTO gold.dim_reports_wbr_goals

SELECT
       CONVERT(DATE, a.[Date])            AS wbr_goals_date
      ,TRIM(a.[Interval])                 AS wbr_goals_interval
      ,TRIM(a.[Section])                  AS wbr_goals_section
      ,TRIM(a.[Category])                 AS wbr_goals_category
      ,[Goal]                             AS wbr_goals_goal
      --,[__filepath__]
      --,[__sheetname__]
--INTO data_central_wh.gold.dim_reports_wbr_goals
FROM data_central_lh.dbo.wbr_goals_bronze a
WHERE [__filepath__] = 'T_Goals_WBR.xlsx' 
    AND [__sheetname__] = 'Sheet1'