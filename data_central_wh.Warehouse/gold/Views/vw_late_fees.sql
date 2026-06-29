-- Auto Generated (Do not modify) EDC1A97EB6B192A7B0ABB2C33734CD3BFB11CBC1B2D8864E135BE9D72B6C96A1
CREATE   VIEW [gold].[vw_late_fees]
AS

SELECT
      [late_fees_load_number]              AS [load_number]
    , [late_fees_dispatch]                 AS [dispatch_number]
    , [late_fees_truck_number]             AS [truck_number]

    , [late_fees_driver_seat_1]            AS [primary_driver_code]
    , [late_fees_driver_seat_2]            AS [secondary_driver_code]

    , [late_fees_create_date]              AS [created_date]
    , [late_fees_create_user_code]         AS [created_by_user_code]

    , [late_fees_house_late]               AS [house_late_flag]
    , [late_fees_reason_why]               AS [late_fee_reason]
    , [late_fees_fee_description]          AS [late_fee_description]

    , [late_fees_reimbursment_flag]        AS [reimbursement_flag]
    , [late_fees_alternative]              AS [alternative_description]

    , [late_fees_last_updated_date]        AS [last_updated_date]
    , [late_fees_last_updated_user_code]   AS [last_updated_by_user_code]

    , [is_verified]                        AS [is_verified]
    , [late_fees_amount]                   AS [late_fee_amount]
    , [late_fees_stop_number]              AS [stop_number]

FROM [silver].[ibmi_late_fees];