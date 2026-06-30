-- Auto Generated (Do not modify) BADD59CC373A7BDAB0311A20CB89BA9491ADE0BDC5D485359D06837C4FCCD1F5
CREATE       VIEW [gold].[vw_empty_call]
AS

SELECT
      [empty_call_truck_number]        AS [truck_number]
    , [empty_call_load_number]         AS [load_number]
    , [empty_call_dispatch]            AS [dispatch_number]
    , [empty_call_call_number]         AS [call_number]

    , [empty_call_trailer_number]      AS [trailer_number]
    , [empty_call_seat_1_driver_code]  AS [first_seat_driver_code]
    , [empty_call_seat_2_driver_code]  AS [second_seat_driver_code]

    , [empty_call_contact_date]        AS [contact_date]
    , [empty_call_contact_time]        AS [contact_time]
    , [empty_call_type_code]           AS [empty_call_type_code]

    , [empty_call_location_code]       AS [location_code]
    , [empty_call_city_short_name]     AS [city_name]

    , [empty_call_initials]            AS [entered_by_initials]
    , [empty_call_message_details]     AS [message_details]

    , [empty_call_hub_reading]         AS [hub_reading]
    , [empty_call_temp_reading]        AS [temperature_reading]
    , [empty_call_hub_flag]            AS [hub_flag]

FROM [silver].[ibmi_empty_call];