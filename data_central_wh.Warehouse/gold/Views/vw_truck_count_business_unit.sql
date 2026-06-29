-- Auto Generated (Do not modify) B3483F0E862E0A982076ED50C065A955A14BA2B33042BA164C9EB5D31E5314B5
CREATE   VIEW [gold].[vw_truck_count_business_unit]
AS

WITH base AS
(
    SELECT
          [unit_truck_number]
        , [unit_extn_business_unit_code]
        , [unit_seat_1_driver_code]
        , [refreshDate]
        , [refreshHourKey]
    FROM [data_central_wh].[gold].[fact_ibmi_unit_hourly_snapshot]
    WHERE [unit_truck_number] NOT LIKE 'T%'
),

classified AS
(
    SELECT
          [unit_truck_number]
        , [refreshDate]
        , [refreshHourKey]

        , CASE 
            WHEN NULLIF(TRIM([unit_seat_1_driver_code]), '') IS NOT NULL 
                THEN 'ASSIGNED'
            ELSE 'UNASSIGNED'
          END AS [assignment_status]

        , CASE 
            WHEN NULLIF(TRIM([unit_seat_1_driver_code]), '') IS NULL
                THEN 'UNASSIGNED'
            ELSE COALESCE(NULLIF(TRIM([unit_extn_business_unit_code]), ''), 'UNKNOWN')
          END AS [business_unit_code]

    FROM base
),

business_unit_allocation AS
(
    SELECT
          [unit_truck_number]
        , [refreshDate]
        , [business_unit_code]
        , [assignment_status]
        , COUNT(DISTINCT [refreshHourKey]) AS [allocated_hour_count]
    FROM classified
    GROUP BY
          [unit_truck_number]
        , [refreshDate]
        , [business_unit_code]
        , [assignment_status]
)

SELECT
      CONCAT(
            [unit_truck_number],
            '|',
            CONVERT(varchar(8), [refreshDate], 112)
        ) AS [truck_snapshot_date_key]

    , [unit_truck_number] AS [truck_number]
    , [refreshDate] AS [snapshot_date]
    , [business_unit_code]
    , [assignment_status]
    , [allocated_hour_count]
    , 24 AS [total_daily_hours]

    , CAST([allocated_hour_count] * 1.0 / 24 AS DECIMAL(10,4)) AS [allocation_percentage]

FROM business_unit_allocation;