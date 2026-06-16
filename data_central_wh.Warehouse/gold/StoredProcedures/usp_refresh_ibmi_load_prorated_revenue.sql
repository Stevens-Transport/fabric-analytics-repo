CREATE     PROCEDURE [gold].[usp_refresh_ibmi_load_prorated_revenue]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF OBJECT_ID(N'[gold].[fact_ibmi_load_prorated_revenue_build]', N'U') IS NOT NULL
            DROP TABLE [gold].[fact_ibmi_load_prorated_revenue_build];

        IF OBJECT_ID(N'[gold].[fact_ibmi_load_prorated_revenue_old]', N'U') IS NOT NULL
            DROP TABLE [gold].[fact_ibmi_load_prorated_revenue_old];

        CREATE TABLE [gold].[fact_ibmi_load_prorated_revenue_build]
        AS
        WITH base AS (
            SELECT *
            FROM [data_central_wh].[gold].[vw_ibmi_load_combined]
            WHERE load_dispatch_date >= DATEFROMPARTS(2023, 11, 1)
        ),
        miles_filtered AS (
            SELECT
                load_load_number,
                SUM(load_miles_total) AS TotalMilesPerLoad,
                COUNT(*) AS DispatchCount
            FROM base
            WHERE miles_indicator = 1
            GROUP BY load_load_number
        ),
        loaded_call_ranked AS (
            SELECT
                loaded_call_load_number,
                loaded_call_dispatch,
                loaded_call_call_number,
                loaded_call_contact_date,
                loaded_call_contact_time,
                loaded_call_type_code,
                ROW_NUMBER() OVER (
                    PARTITION BY loaded_call_load_number, loaded_call_dispatch
                    ORDER BY loaded_call_contact_date, loaded_call_contact_time, loaded_call_call_number
                ) AS rn
            FROM [data_central_wh].[gold].[vw_ibmi_loaded_call]
            WHERE loaded_call_contact_date IS NOT NULL
        ),
        loaded_call_dispatch AS (
            SELECT
                loaded_call_load_number,
                loaded_call_dispatch,
                loaded_call_call_number AS DispatchLoadedCallNumber,
                CAST(loaded_call_contact_date AS date) AS DispatchLoadedCallDate,
                loaded_call_contact_time AS DispatchLoadedCallTime,
                loaded_call_type_code AS DispatchLoadedCallTypeCode
            FROM loaded_call_ranked
            WHERE rn = 1
        ),
        billing AS (
            SELECT
                bf.billing_load_number,
                SUM(bf.billing_billed_amount) AS BillingAmount,
                SUM(CASE WHEN TRIM(bc.billing_category) = 'Fuel Surcharge' THEN bf.billing_billed_amount END) AS BillingAmountFSC,
                SUM(CASE WHEN TRIM(bc.billing_category) = 'Linehaul' THEN bf.billing_billed_amount END) AS BillingAmountLH
            FROM [data_central_wh].[gold].[vw_ibmi_billing_combined] AS bf
            LEFT JOIN [data_central_wh].[gold].[dim_billing_categories] AS bc
                ON TRIM(bf.billing_commodity_code) = TRIM(bc.type_code)
            GROUP BY bf.billing_load_number
        ),
        orders AS (
            SELECT
                order_load_number,
                MAX(order_revenue_estimation) AS OrderRevenueEstimation,
                CAST(MAX(order_loaded_call_date) AS date) AS OrderLoadedCallDate
            FROM [data_central_wh].[gold].[vw_ibmi_order_combined]
            WHERE order_early_pickup_date >= DATEFROMPARTS(2024, 1, 1)
            GROUP BY order_load_number
        ),
        calc AS (
            SELECT
                b.*,
                mf.TotalMilesPerLoad,
                mf.DispatchCount,
                CASE
                    WHEN b.miles_indicator <> 1 THEN NULL
                    WHEN mf.DispatchCount = 1 THEN 100.0
                    WHEN mf.TotalMilesPerLoad IS NULL OR mf.TotalMilesPerLoad = 0 THEN NULL
                    ELSE ROUND((b.load_miles_total / NULLIF(mf.TotalMilesPerLoad, 0)) * 100.0, 2)
                END AS PercentMiles,
                CASE
                    WHEN b.miles_indicator <> 1 THEN NULL
                    WHEN mf.DispatchCount = 1 THEN 1.0
                    WHEN mf.TotalMilesPerLoad IS NULL OR mf.TotalMilesPerLoad = 0 THEN NULL
                    ELSE (b.load_miles_total / NULLIF(mf.TotalMilesPerLoad, 0))
                END AS PercentMilesDecimal,
                bil.BillingAmount,
                bil.BillingAmountFSC,
                bil.BillingAmountLH,
                ord.OrderRevenueEstimation,
                ord.OrderLoadedCallDate,
                lc.DispatchLoadedCallDate,
                lc.DispatchLoadedCallTime,
                lc.DispatchLoadedCallNumber,
                lc.DispatchLoadedCallTypeCode,
                COALESCE(lc.DispatchLoadedCallDate, ord.OrderLoadedCallDate) AS ProrationLoadedCallDate
            FROM base b
            LEFT JOIN miles_filtered mf
                ON b.load_load_number = mf.load_load_number
            LEFT JOIN billing bil
                ON b.load_load_number = bil.billing_load_number
            LEFT JOIN orders ord
                ON b.load_load_number = ord.order_load_number
            LEFT JOIN loaded_call_dispatch lc
                ON b.load_load_number = lc.loaded_call_load_number
               AND b.load_dispatch = lc.loaded_call_dispatch
            WHERE b.miles_indicator = 1
        )
        SELECT
            *,
            CASE
                WHEN PercentMilesDecimal IS NULL THEN NULL
                ELSE ROUND(COALESCE(BillingAmount, OrderRevenueEstimation) * PercentMilesDecimal, 2)
            END AS ProratedRevenue,
            CASE
                WHEN PercentMilesDecimal IS NULL OR BillingAmountFSC IS NULL THEN NULL
                ELSE ROUND(BillingAmountFSC * PercentMilesDecimal, 2)
            END AS ProRevFSC,
            CASE
                WHEN PercentMilesDecimal IS NULL OR BillingAmountLH IS NULL THEN NULL
                ELSE ROUND(BillingAmountLH * PercentMilesDecimal, 2)
            END AS ProRevLH
        FROM calc;

        BEGIN TRAN;

            IF OBJECT_ID(N'[gold].[fact_ibmi_load_prorated_revenue]', N'U') IS NOT NULL
                EXEC sp_rename 
                    N'gold.fact_ibmi_load_prorated_revenue',
                    N'fact_ibmi_load_prorated_revenue_old',
                    N'OBJECT';

            EXEC sp_rename 
                N'gold.fact_ibmi_load_prorated_revenue_build',
                N'fact_ibmi_load_prorated_revenue',
                N'OBJECT';

        COMMIT TRAN;

        IF OBJECT_ID(N'[gold].[fact_ibmi_load_prorated_revenue_old]', N'U') IS NOT NULL
            DROP TABLE [gold].[fact_ibmi_load_prorated_revenue_old];

        SELECT 
            COUNT_BIG(*) AS refreshedRowCount
        FROM [gold].[fact_ibmi_load_prorated_revenue];

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        IF OBJECT_ID(N'[gold].[fact_ibmi_load_prorated_revenue_build]', N'U') IS NOT NULL
            DROP TABLE [gold].[fact_ibmi_load_prorated_revenue_build];

        THROW;

    END CATCH
END;