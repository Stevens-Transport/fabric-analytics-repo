-- Auto Generated (Do not modify) 22A969E3518EC5839676229D7256289CB8CF0B3C10C552D1CA491FF27C2522D9
CREATE   VIEW [gold].[vw_repowers]
AS

SELECT
      [repowers_truck_number_1]                  AS [first_truck_number]
    , [repowers_load_number_1]                   AS [first_load_number]
    , [repowers_dispatch_1]                      AS [first_dispatch_number]

    , [repowers_truck_number_2]                  AS [second_truck_number]
    , [repowers_load_number_2]                   AS [second_load_number]
    , [repowers_dispatch_2]                      AS [second_dispatch_number]

    , [repowers_status]                          AS [repower_status]
    , [repowers_status_datetime]                 AS [repower_status_datetime]

    , [repowers_swap_user_code]                  AS [swap_user_code]
    , [repowers_swap_location_code]              AS [swap_location_code]
    , [repowers_swap_stop_number]                AS [swap_stop_number]
    , [repowers_swap_datetime]                   AS [swap_datetime]

    , [repowers_next_location_code_post_swap_1]  AS [first_next_location_code_after_swap]
    , [repowers_next_location_code_post_swap_2]  AS [second_next_location_code_after_swap]

    , [repowers_swap_reason_code]                AS [swap_reason_code]

    , [repowers_create_user_code]                AS [created_by_user_code]
    , [repowers_create_datetime]                 AS [created_datetime]

    , [is_chargeable_to_driver]                  AS [is_chargeable_to_driver]

FROM [silver].[ibmi_repowers];