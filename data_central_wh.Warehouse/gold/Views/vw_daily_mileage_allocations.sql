-- Auto Generated (Do not modify) 920DD8ECEA23693C61D89A1C7403E4F56A24B759D6B9FE51715172CBCE5749B3
CREATE   VIEW [gold].[vw_daily_mileage_allocations]
AS
SELECT
      [mile_hist_date]                         AS [mileage_date]
    , [mile_hist_driver_code]                  AS [driver_code]
    , [mile_hist_truck_number]                 AS [truck_number]
    , [mile_hist_load_number]                  AS [load_number]
    , [mile_hist_dispatch]                     AS [dispatch_number]
    , [mile_hist_distributed_dispatch_miles]   AS [distributed_dispatch_miles]
    , [mile_hist_hub_miles]                    AS [hub_miles]
    , [mile_hist_hub_ratio]                    AS [hub_miles_ratio]
    , [mile_hist_adj_dispatch_miles]           AS [adjusted_dispatch_miles]
    , [mile_hist_goal_miles]                   AS [goal_miles]
FROM [silver].[ibmi_miles_history];