-- ================================================================
-- Stored Procedure: dbo.sp_refresh_driver_code_reference_table
--
-- Materializes the driver code reference table into the WH gold layer.
--
-- Source : LH staging table written by the notebook
--          (stg_driver_code_reference_table)
-- Target : WH gold physical table
--          (gold.dim_driver_code_reference_table)
--
-- Runs as a downstream step AFTER the notebook has refreshed the
-- LH staging table. Daily-refresh safe: drops and rebuilds the gold
-- table each run so it always reflects the latest staging output.
--
-- NOTE: the Lakehouse (data_central_lh) must be in the SAME workspace
-- as this Warehouse for the 3-part name to resolve. Confirm the prod
-- Lakehouse name and replace 'data_central_lh' below if it differs.
-- ================================================================

CREATE     PROCEDURE dbo.usp_refresh_driver_code_reference_table
AS
BEGIN
    -- Rebuild the gold reference table from the LH staging table.
    DROP TABLE IF EXISTS gold.dim_driver_code_reference_table;

    CREATE TABLE gold.dim_driver_code_reference_table AS
    SELECT
        history_code,
        current_code,
        history_create_date,
        ssn,
        current_create_date,
        is_conflict
    FROM data_central_lh.dbo.stg_driver_code_reference_table;
END