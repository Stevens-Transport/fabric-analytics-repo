-- Auto Generated (Do not modify) 4B24C31666C3926CE7FBEE0347C516A865616EBC64E04AD4BA3101B43241D60C
CREATE   VIEW gold.vw_stops AS

SELECT
      [stopoff_load_number]                 AS [load_number]
    , [stopoff_stop_number]                 AS [stop_number]
    , [stopoff_stop_type]                   AS [stop_type]
    , [stopoff_stop_code]                   AS [stop_code]

    , [stopoff_customer_code]               AS [customer_code]
    , [stopoff_city_code]                   AS [stop_city_code]
    , [stopoff_state]                       AS [stop_state]
    , [stopoff_customer_area_code]          AS [customer_phone_area_code]
    , [stopoff_customer_phone_number]       AS [customer_phone_number]
    , [stopoff_contact_info]                AS [contact_information]

    , [stopoff_shipper_edi_code]            AS [shipper_edi_code]
    , [stopoff_consignee_edi_code]          AS [consignee_edi_code]
    , [stopoff_last_status]                 AS [last_stop_status]

    , [stopoff_est_arrival_date]            AS [estimated_arrival_date]
    , [stopoff_est_arrival_time]            AS [estimated_arrival_time]

    , [stopoff_appt_early_date]             AS [appointment_early_date]
    , [stopoff_appt_early_time]             AS [appointment_early_time]
    , [stopoff_appt_late_date]              AS [appointment_late_date]
    , [stopoff_appt_late_time]              AS [appointment_late_time]

    , [stopoff_arrival_date]                AS [arrival_date]
    , [stopoff_arrival_time]                AS [arrival_time]

    , [stopoff_load_unload_date]            AS [load_unload_date]
    , [stopoff_load_unload_time]            AS [load_unload_time]

    , [is_appt_required]                    AS [is_appointment_required]
    , [is_appt_created]                     AS [is_appointment_created]

    , [stopoff_appt_created_initials]       AS [appointment_created_by_initials]
    , [stopoff_appt_created_date]           AS [appointment_created_date]
    , [stopoff_appt_created_time]           AS [appointment_created_time]

    , [stopoff_appt_date_at_dispatch]       AS [appointment_date_at_dispatch]
    , [stopoff_appt_time_at_dispatch]       AS [appointment_time_at_dispatch]

    , [stopoff_shipper_specific_code]       AS [shipper_specific_code]
    , [stopoff_seal_1_code]                 AS [seal_1_code]
    , [stopoff_seal_2_code]                 AS [seal_2_code]

    , [stopoff_weight]                      AS [stop_weight]
    , [stopoff_pieces]                      AS [piece_count]
    , [stopoff_unit_of_measure]             AS [unit_of_measure_code]
    , [stopoff_pallets_on]                  AS [pallets_on_count]
    , [stopoff_pallets_off]                 AS [pallets_off_count]
    , [stopoff_load_unload_type]            AS [load_unload_type]

    , [stopoff_truck_number]                AS [truck_number]
    , [stopoff_trailer_number]              AS [trailer_number]
    , [stopoff_dispatch]                    AS [dispatch_number]
    , [stopoff_dispatch_new]                AS [normalized_dispatch_number]

    , [stopoff_message]                     AS [stop_message]

    , [actual_arrival_dt]                   AS [actual_arrival_datetime]
    , [appt_late_date]                      AS [appointment_late_datetime]
    , [og_appt_late_dt]                     AS [original_appointment_late_datetime]

    , [division_code]                       AS [division_code]

    , [HasLateServiceException]             AS [has_late_service_exception]
    , [LateServiceExceptionReasonCode]      AS [late_service_exception_reason_code]

    , [OnTimePickupLateCount]               AS [on_time_pickup_late_count]
    , [OnTimeDeliveryLateCount]             AS [on_time_delivery_late_count]
    , [OnTimePickupLateCount_OG]            AS [original_on_time_pickup_late_count]
    , [OnTimeDeliveryLateCount_OG]          AS [original_on_time_delivery_late_count]

FROM [data_central_wh].[gold].[vw_ibmi_stopoff];