-- Auto Generated (Do not modify) 42A9BBAF7E1336836120BEC584272FF145AA0A6F379BCD40E5DE4F636532DF4F
CREATE   VIEW [gold].[vw_daily_utilization_snapshot] AS

SELECT
      [utlfile_truck_number]                  AS [truck_number]
    , [utlfile_driver_code]                   AS [driver_code]
    , [utlfile_driver_type]                   AS [driver_type]

    , [utlfile_truck_dm_code]                 AS [truck_dm_code]
    , [utlfile_driver_dm_code]                AS [driver_dm_code]
    , [utlfile_dmol_code]                     AS [dmol_code]
    , [utlfile_safety_manager_code]           AS [safety_manager_code]
    , [utlfile_counselor_code]                AS [counselor_code]

    , [utlfile_seat]                          AS [seat_code]
    , [utlfile_first_seat_code]               AS [first_seat_driver_code]
    , [utlfile_second_seat_code]              AS [second_seat_driver_code]
    , [utlfile_training_level_code]           AS [training_level_code]

    , [is_team_truck]                         AS [is_team_truck]
    , [is_training_team]                      AS [is_training_team]

    , [utlfile_miles_hub]                     AS [hub_miles]
    , [utlfile_miles_adj_hub]                 AS [adjusted_hub_miles]
    , [utlfile_miles_goal]                    AS [miles_goal]
    , [utlfile_utilization_ratio]             AS [utilization_ratio]

    , [utlfile_projected_date_available]      AS [projected_available_date]
    , [utlfile_projected_time_available]      AS [projected_available_time]

    , [is_home_time]                          AS [is_home_time]
    , [utlfile_hold_codes]                    AS [hold_codes]
    , [utlfile_equipment_breakdown]           AS [equipment_breakdown_code]
    , [is_resweep]                            AS [is_resweep]

    , [utlfile_load_number]                   AS [load_number]
    , [is_grad_hold]                          AS [is_grad_hold]
    , [is_omitted]                            AS [is_omitted]

    , [utlfile_division]                      AS [division_code]
    , [utlfile_requested_days_out]            AS [requested_days_out]

    , [is_trainer]                            AS [is_trainer]
    , [utlfile_trainer_availability_code]     AS [trainer_availability_code]
    , [utlfile_trainer_status_code]           AS [trainer_status_code]

    , [is_allowed_to_drive]                   AS [is_allowed_to_drive]
    , [utlfile_record_date]                   AS [record_date]

    , [utlfile_comfort_zone_code]             AS [comfort_zone_code]
    , [is_on_yard]                            AS [is_on_yard]

    , [utlfile_business_unit_code]            AS [business_unit_code]
    , [utlfile_business_class]                AS [business_class_code]
    , [utlfile_business_description]          AS [business_class_description]

FROM [silver].[ibmi_utlfile];