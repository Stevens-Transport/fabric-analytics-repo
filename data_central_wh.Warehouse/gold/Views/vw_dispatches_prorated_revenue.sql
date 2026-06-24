-- Auto Generated (Do not modify) 63714F1FDA5657F092B9A809735749E36935900F3AFFAADA4C8ECE0528A41657
CREATE   VIEW gold.vw_dispatches_prorated_revenue AS

SELECT
      [load_origin_area_code]              AS [origin_area_code]
    , [load_load_number]                   AS [load_number]
    , [load_dispatch]                      AS [dispatch_number]
    , [load_status]                        AS [load_status_code]

    , [load_dispatch_date]                 AS [dispatch_start_date]
    , [load_dispatch_time]                 AS [dispatch_start_time]
    , [load_dispatch_end_date]             AS [dispatch_end_date]
    , [load_dispatch_end_time]             AS [dispatch_end_time]

    , [load_truck_number]                  AS [truck_number]
    , [load_trailer_number]                AS [trailer_number]
    , [load_seat_1_driver_code]            AS [primary_driver_code]
    , [load_seat_2_driver_code]            AS [secondary_driver_code]

    , [load_route_line_codes]              AS [route_path_code]
    , [load_route_status]                  AS [route_status_code]
    , [load_destination_area_code]         AS [destination_area_code]
    , [load_route_line_extension]          AS [route_line_extension]

    , [load_miles_dead_head]               AS [deadhead_miles]
    , [load_miles_total]                   AS [load_total_miles]
    , [load_miles_loaded]                  AS [loaded_miles]
    , [load_mile_flag]                     AS [mileage_flag]
    , [load_miles_hub_start]               AS [hub_start_miles]
    , [load_miles_hub_end]                 AS [hub_end_miles]

    , [load_multiple_trailers_on_dispatch] AS [multiple_trailers_flag]
    , [load_settlement_flag]               AS [settlement_flag]
    , [load_payroll_approval_flag]         AS [payroll_approval_flag]

    , [load_trip_jacket_received_flag]     AS [trip_jacket_received_flag]
    , [load_trip_jacket_received_date]     AS [trip_jacket_received_date]

    , [load_truck_dmol_code]               AS [truck_dmol_code]
    , [load_truck_dm_code]                 AS [truck_dm_code]
    , [load_driver_dmol_code]              AS [driver_dmol_code]
    , [load_driver_dm_code]                AS [driver_dm_code]

    , [load_unit_division_code]            AS [unit_division_code]
    , [load_team_status_code]              AS [team_status_code]
    , [load_trainer_team_code]             AS [trainer_team_code]
    , [load_initials]                      AS [entered_by_initials]

    , [is_deleted]                         AS [is_deleted]

    , [load_business_unit_code]            AS [business_unit_code]
    , [load_business_class]                AS [business_class_code]
    , [load_business_description]          AS [business_class_description]

    , [miles_indicator]                    AS [mileage_proration_indicator]
    , [TotalMilesPerLoad]                  AS [total_miles_per_load]
    , [DispatchCount]                      AS [dispatch_count]
    , [PercentMiles]                       AS [dispatch_miles_percentage]
    , [PercentMilesDecimal]                AS [dispatch_miles_ratio]

    , [BillingAmount]                      AS [billed_total_amount]
    , [BillingAmountFSC]                   AS [billed_fuel_surcharge_amount]
    , [BillingAmountLH]                    AS [billed_linehaul_amount]
    , [OrderRevenueEstimation]             AS [estimated_order_revenue]

    , [OrderLoadedCallDate]                AS [order_loaded_call_date]
    , [DispatchLoadedCallDate]             AS [dispatch_loaded_call_date]
    , [DispatchLoadedCallTime]             AS [dispatch_loaded_call_time]
    , [DispatchLoadedCallNumber]           AS [dispatch_loaded_call_number]
    , [DispatchLoadedCallTypeCode]         AS [dispatch_loaded_call_type_code]

    , [ProrationLoadedCallDate]            AS [revenue_proration_loaded_call_date]
    , [ProratedRevenue]                    AS [prorated_total_revenue]
    , [ProRevFSC]                          AS [prorated_fuel_surcharge_revenue]
    , [ProRevLH]                           AS [prorated_linehaul_revenue]

FROM [data_central_wh].[gold].[vw_ibmi_load_prorated_revenue];