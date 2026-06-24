-- Auto Generated (Do not modify) 368E31370F200E8BFA0B5675E21CF3958F814DFA61CB53BB7F1CFDE03C59F8F4
CREATE   VIEW [gold].[vw_orders] AS

WITH orders_combined AS
(
    SELECT
          [order_origin_area_code]
        , [order_load_number]
        , [order_status_code]
        , [order_date]
        , [order_time]
        , [order_customer_code]
        , [order_consignee_code]
        , [order_billto_code]
        , [order_loadat_code]
        , [order_early_pickup_date]
        , [order_early_pickup_time]
        , [is_pickup_required]
        , [order_early_delivery_date]
        , [order_early_delivery_time]
        , [is_delivery_required]
        , [order_commodity_code]
        , [order_commodity_description]
        , [order_creation_initials]
        , [order_customer_phone_area_code]
        , [order_customer_phone_number]
        , [order_consignee_phone_area_code]
        , [order_consignee_phone_number]
        , [order_load_weight]
        , [order_pallet_count]
        , [order_origin_city_code]
        , [order_origin_state]
        , [order_origin_bea_code]
        , [order_origin_gu_code]
        , [order_origin_city_short_name]
        , [order_destination_city_code]
        , [order_destination_state]
        , [order_destination_bea_code]
        , [order_destination_gu_code]
        , [order_destination_city_short_name]
        , [order_miles_billable]
        , [order_load_type]
        , [order_stop_count]
        , [order_dispatch_count]
        , [order_preload_trailer]
        , [order_revenue_estimation]
        , [order_new_origin_area_code]
        , [order_destination_area_code]
        , [order_bill_of_lading]
        , [order_purchase_order]
        , [order_pick_up_code]
        , [order_piece_count]
        , [order_collection_method_code]
        , [order_load_volume]
        , [order_message]
        , [order_late_pickup_date]
        , [order_late_pickup_time]
        , [order_late_delivery_date]
        , [order_late_delivery_time]
        , [order_required_pallet_count]
        , [order_ship_date]
        , [order_ship_time]
        , [order_temp_high]
        , [order_temp_low]
        , [order_last_update_date]
        , [order_last_update_time]
        , [order_last_update_initials]
        , [order_company_code]
        , [order_division_code]
        , [order_lane_code]
        , [order_seal_code]
        , [order_service_failure_code]
        , [order_driver_commit_flag]
        , [is_edi_load]
        , [is_edi_stats_complete]
        , [is_driver_loaded]
        , [is_driver_unloaded]
        , [is_delivery_receipt_signed]
        , [order_delivery_receipt_req]
        , [order_edi_message_billing_flag]
        , [is_load_just_in_time]
        , [order_edi_billing_code]
        , [is_edi_inbound_or_outbound]
        , [order_current_city_code]
        , [order_current_state]
        , [order_loaded_call_date]
        , [order_empty_call_date]
        , [order_trailer_length]
        , [order_trailer_height]
        , [has_permit]
        , [has_permit_complete]
        , [order_latitude]
        , [order_longitude]
        , [is_tentitive_load]
        , [order_hours_under_dispatch]
        , [order_origin_zone_code]
        , [order_origin_region_code]
        , [order_destination_zone_code]
        , [order_destination_region_code]
        , [is_to_be_rated]
        , [has_new_gu_code]
        , [is_exclude_from_model]
        , [is_deleted]
        , [order_carry_over_flag]
        , [order_truck_type_requirement_code]
        , [order_delivery_code]

    FROM [data_central_wh].[silver].[vw_ibmi_incr_order_all]

    UNION ALL

    SELECT
          o.[order_origin_area_code]
        , o.[order_load_number]
        , o.[order_status_code]
        , o.[order_date]
        , o.[order_time]
        , o.[order_customer_code]
        , o.[order_consignee_code]
        , o.[order_billto_code]
        , o.[order_loadat_code]
        , o.[order_early_pickup_date]
        , o.[order_early_pickup_time]
        , o.[is_pickup_required]
        , o.[order_early_delivery_date]
        , o.[order_early_delivery_time]
        , o.[is_delivery_required]
        , o.[order_commodity_code]
        , o.[order_commodity_description]
        , o.[order_creation_initials]
        , o.[order_customer_phone_area_code]
        , o.[order_customer_phone_number]
        , o.[order_consignee_phone_area_code]
        , o.[order_consignee_phone_number]
        , o.[order_load_weight]
        , o.[order_pallet_count]
        , o.[order_origin_city_code]
        , o.[order_origin_state]
        , o.[order_origin_bea_code]
        , o.[order_origin_gu_code]
        , o.[order_origin_city_short_name]
        , o.[order_destination_city_code]
        , o.[order_destination_state]
        , o.[order_destination_bea_code]
        , o.[order_destination_gu_code]
        , o.[order_destination_city_short_name]
        , o.[order_miles_billable]
        , o.[order_load_type]
        , o.[order_stop_count]
        , o.[order_dispatch_count]
        , o.[order_preload_trailer]
        , o.[order_revenue_estimation]
        , o.[order_new_origin_area_code]
        , o.[order_destination_area_code]
        , o.[order_bill_of_lading]
        , o.[order_purchase_order]
        , o.[order_pick_up_code]
        , o.[order_piece_count]
        , o.[order_collection_method_code]
        , o.[order_load_volume]
        , o.[order_message]
        , o.[order_late_pickup_date]
        , o.[order_late_pickup_time]
        , o.[order_late_delivery_date]
        , o.[order_late_delivery_time]
        , o.[order_required_pallet_count]
        , o.[order_ship_date]
        , o.[order_ship_time]
        , o.[order_temp_high]
        , o.[order_temp_low]
        , o.[order_last_update_date]
        , o.[order_last_update_time]
        , o.[order_last_update_initials]
        , o.[order_company_code]
        , o.[order_division_code]
        , o.[order_lane_code]
        , o.[order_seal_code]
        , o.[order_service_failure_code]
        , o.[order_driver_commit_flag]
        , o.[is_edi_load]
        , o.[is_edi_stats_complete]
        , o.[is_driver_loaded]
        , o.[is_driver_unloaded]
        , o.[is_delivery_receipt_signed]
        , o.[order_delivery_receipt_req]
        , o.[order_edi_message_billing_flag]
        , o.[is_load_just_in_time]
        , o.[order_edi_billing_code]
        , o.[is_edi_inbound_or_outbound]
        , o.[order_current_city_code]
        , o.[order_current_state]
        , o.[order_loaded_call_date]
        , o.[order_empty_call_date]
        , o.[order_trailer_length]
        , o.[order_trailer_height]
        , o.[has_permit]
        , o.[has_permit_complete]
        , o.[order_latitude]
        , o.[order_longitude]
        , o.[is_tentitive_load]
        , o.[order_hours_under_dispatch]
        , o.[order_origin_zone_code]
        , o.[order_origin_region_code]
        , o.[order_destination_zone_code]
        , o.[order_destination_region_code]
        , o.[is_to_be_rated]
        , o.[has_new_gu_code]
        , o.[is_exclude_from_model]
        , o.[is_deleted]
        , o.[order_carry_over_flag]
        , o.[order_truck_type_requirement_code]
        , o.[order_delivery_code]

    FROM [data_central_wh].[silver].[vw_ibmi_order_all] o
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [data_central_wh].[silver].[vw_ibmi_incr_order_all] i
        WHERE i.[order_load_number] = o.[order_load_number]
    )
),

edi_api_flags AS
(
    SELECT
          [edi_ord_hist_bill_of_lading]
        , 1 AS [edi_division_078_flag]
        , MAX(
            CASE
                WHEN [edi_ord_hist_edi_customer_code] <> 'GM'
                THEN 1
                ELSE 0
            END
          ) AS [edi_api_customer_flag]
    FROM [gold].[vw_ibmi_edi_order_history]
    WHERE [edi_ord_hist_division_code] = '078'
    GROUP BY [edi_ord_hist_bill_of_lading]
)

SELECT
      o.[order_origin_area_code]              AS [origin_area_code]
    , o.[order_load_number]                   AS [load_number]
    , o.[order_status_code]                   AS [order_status_code]

    , o.[order_date]                          AS [order_created_date]
    , o.[order_time]                          AS [order_created_time]

    , o.[order_customer_code]                 AS [customer_code]
    , o.[order_consignee_code]                AS [consignee_code]
    , o.[order_billto_code]                   AS [bill_to_customer_code]
    , o.[order_loadat_code]                   AS [load_at_customer_code]

    , o.[order_early_pickup_date]             AS [pickup_window_start_date]
    , o.[order_early_pickup_time]             AS [pickup_window_start_time]
    , o.[is_pickup_required]                  AS [is_pickup_required]

    , o.[order_late_pickup_date]              AS [pickup_window_end_date]
    , o.[order_late_pickup_time]              AS [pickup_window_end_time]

    , o.[order_early_delivery_date]           AS [delivery_window_start_date]
    , o.[order_early_delivery_time]           AS [delivery_window_start_time]
    , o.[is_delivery_required]                AS [is_delivery_required]

    , o.[order_late_delivery_date]            AS [delivery_window_end_date]
    , o.[order_late_delivery_time]            AS [delivery_window_end_time]

    , o.[order_ship_date]                     AS [ship_date]
    , o.[order_ship_time]                     AS [ship_time]

    , o.[order_commodity_code]                AS [commodity_code]
    , o.[order_commodity_description]         AS [commodity_description]

    , o.[order_load_weight]                   AS [load_weight]
    , o.[order_pallet_count]                  AS [pallet_count]
    , o.[order_required_pallet_count]         AS [required_pallet_count]
    , o.[order_piece_count]                   AS [piece_count]
    , o.[order_load_volume]                   AS [load_volume]

    , o.[order_origin_city_code]              AS [origin_city_code]
    , o.[order_origin_state]                  AS [origin_state]
    , o.[order_origin_city_short_name]        AS [origin_city_name]
    , o.[order_origin_area_code]              AS [original_origin_area_code]
    , o.[order_new_origin_area_code]          AS [current_origin_area_code]
    , o.[order_origin_bea_code]               AS [origin_bea_code]
    , o.[order_origin_gu_code]                AS [origin_gu_code]
    , o.[order_origin_zone_code]              AS [origin_zone_code]
    , o.[order_origin_region_code]            AS [origin_region_code]

    , o.[order_destination_city_code]         AS [destination_city_code]
    , o.[order_destination_state]             AS [destination_state]
    , o.[order_destination_city_short_name]   AS [destination_city_name]
    , o.[order_destination_area_code]         AS [destination_area_code]
    , o.[order_destination_bea_code]          AS [destination_bea_code]
    , o.[order_destination_gu_code]           AS [destination_gu_code]
    , o.[order_destination_zone_code]         AS [destination_zone_code]
    , o.[order_destination_region_code]       AS [destination_region_code]

    , o.[order_current_city_code]             AS [current_city_code]
    , o.[order_current_state]                 AS [current_state]

    , o.[order_miles_billable]                AS [billable_miles]
    , o.[order_load_type]                     AS [load_type_code]
    , o.[order_stop_count]                    AS [stop_count]
    , o.[order_dispatch_count]                AS [dispatch_count]
    , o.[order_preload_trailer]               AS [preloaded_trailer_number]
    , o.[order_revenue_estimation]            AS [estimated_order_revenue]

    , o.[order_bill_of_lading]                AS [bill_of_lading_number]
    , o.[order_purchase_order]                AS [purchase_order_number]
    , o.[order_pick_up_code]                  AS [pickup_code]
    , o.[order_collection_method_code]        AS [collection_method_code]

    , o.[order_temp_high]                     AS [temperature_high]
    , o.[order_temp_low]                      AS [temperature_low]

    , o.[order_company_code]                  AS [company_code]
    , o.[order_division_code]                 AS [division_code]
    , o.[order_lane_code]                     AS [lane_code]
    , o.[order_seal_code]                     AS [seal_code]
    , o.[order_service_failure_code]          AS [service_failure_code]
    , o.[order_driver_commit_flag]            AS [driver_commit_flag]

    , o.[is_edi_load]                         AS [is_edi_load]
    , o.[is_edi_stats_complete]               AS [is_edi_stats_complete]
    , o.[order_edi_message_billing_flag]      AS [edi_message_billing_flag]
    , o.[order_edi_billing_code]              AS [edi_billing_code]
    , o.[is_edi_inbound_or_outbound]          AS [edi_direction]

    , o.[is_driver_loaded]                    AS [is_driver_loaded]
    , o.[is_driver_unloaded]                  AS [is_driver_unloaded]
    , o.[is_delivery_receipt_signed]          AS [is_delivery_receipt_signed]
    , o.[order_delivery_receipt_req]          AS [delivery_receipt_requirement_code]

    , o.[is_load_just_in_time]                AS [is_just_in_time_load]

    , o.[order_loaded_call_date]              AS [loaded_call_date]
    , o.[order_empty_call_date]               AS [empty_call_date]

    , o.[order_trailer_length]                AS [trailer_length]
    , o.[order_trailer_height]                AS [trailer_height]

    , o.[has_permit]                          AS [has_permit]
    , o.[has_permit_complete]                 AS [is_permit_complete]

    , o.[order_latitude]                      AS [latitude]
    , o.[order_longitude]                     AS [longitude]

    , o.[is_tentitive_load]                   AS [is_tentative_load]
    , o.[order_hours_under_dispatch]          AS [hours_under_dispatch]

    , o.[is_to_be_rated]                      AS [is_to_be_rated]
    , o.[has_new_gu_code]                     AS [has_new_gu_code]
    , o.[is_exclude_from_model]               AS [is_excluded_from_model]
    , o.[is_deleted]                          AS [is_deleted]

    , o.[order_carry_over_flag]               AS [carry_over_flag]
    , o.[order_truck_type_requirement_code]   AS [truck_type_requirement_code]
    , o.[order_delivery_code]                 AS [delivery_code]

    , o.[order_message]                       AS [order_message]

    , o.[order_customer_phone_area_code]      AS [customer_phone_area_code]
    , o.[order_customer_phone_number]         AS [customer_phone_number]
    , o.[order_consignee_phone_area_code]     AS [consignee_phone_area_code]
    , o.[order_consignee_phone_number]        AS [consignee_phone_number]

    , o.[order_creation_initials]             AS [created_by_initials]
    , o.[order_last_update_date]              AS [last_update_date]
    , o.[order_last_update_time]              AS [last_update_time]
    , o.[order_last_update_initials]          AS [last_update_initials]

    , CASE
        WHEN d.[division_fleet_name] = 'Brokerage'
            AND d.[division_code] <> '025'
            AND o.[order_status_code] <> 'C'
            AND e.[edi_division_078_flag] = 1
            AND
            (
                o.[order_truck_type_requirement_code] = 'SXVN'
                OR e.[edi_api_customer_flag] = 1
            )
        THEN 1
        ELSE 0
      END AS [is_api_order]

FROM orders_combined o
LEFT JOIN [gold].[vw_ibmi_division] d
    ON o.[order_division_code] = d.[division_code]
LEFT JOIN edi_api_flags e
    ON o.[order_bill_of_lading] = e.[edi_ord_hist_bill_of_lading];