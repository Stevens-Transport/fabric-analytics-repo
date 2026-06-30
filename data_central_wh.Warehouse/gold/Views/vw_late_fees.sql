-- Auto Generated (Do not modify) 04604A96FC42FBFC6717110B7FB2D39EDDE75D0388955FE519E9BFE9F59CA607
CREATE       VIEW [gold].[vw_late_fees]
AS

SELECT
      [late_fees_load_number]              AS [load_number]
    , [late_fees_dispatch]                 AS [dispatch_number]
    , [late_fees_truck_number]             AS [truck_number]

    , [late_fees_driver_seat_1]            AS [first_seat_driver_code]
    , [late_fees_driver_seat_2]            AS [second_seat_driver_code]

    , [late_fees_create_date]              AS [created_date]
    , [late_fees_create_user_code]         AS [created_by_user_code]

    , [late_fees_house_late]               AS [hours_late]
    , [late_fees_reason_why]               AS [late_reason]
    , [late_fees_fee_description]          AS [late_rules]

    , [late_fees_reimbursment_flag]        AS [reimbursement_flag]
    , [late_fees_alternative]              AS [alternative_description]

    , [late_fees_last_updated_date]        AS [last_updated_date]
    , [late_fees_last_updated_user_code]   AS [last_updated_by_user_code]

    , [is_verified]                        AS [is_verified]
    , [late_fees_amount]                   AS [late_fee_amount]
    , [late_fees_stop_number]              AS [stop_number]

FROM [silver].[ibmi_late_fees];