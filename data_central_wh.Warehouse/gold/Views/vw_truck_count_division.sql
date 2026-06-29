-- Auto Generated (Do not modify) 24ADC9509785D408A191E4A38D84227D5086C8AB2C923F612127679F8C453151
CREATE   VIEW [gold].[vw_truck_count_division]
AS

WITH base AS
(
    SELECT
          [unit_truck_number]
        , [unit_truck_division_code]
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
            ELSE COALESCE(NULLIF(TRIM([unit_truck_division_code]), ''), 'UNKNOWN')
          END AS [division_code]

    FROM base
),

division_allocation AS
(
    SELECT
          [unit_truck_number]
        , [refreshDate]
        , [division_code]
        , [assignment_status]
        , COUNT(DISTINCT [refreshHourKey]) AS [allocated_hour_count]
    FROM classified
    GROUP BY
          [unit_truck_number]
        , [refreshDate]
        , [division_code]
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
    , [division_code]
    , [assignment_status]
    , [allocated_hour_count]
    , 24 AS [total_daily_hours]

    , CAST([allocated_hour_count] * 1.0 / 24 AS DECIMAL(10,4)) AS [allocation_percentage]

FROM division_allocation;