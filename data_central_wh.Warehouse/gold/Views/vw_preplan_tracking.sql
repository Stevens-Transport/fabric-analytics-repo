-- Auto Generated (Do not modify) 2284B7DD3D8AF4D60AB1418E30C69E71293435E00B505F06118570931728CB5C
CREATE       VIEW [gold].[vw_preplan_tracking]
AS

SELECT
      [preplan_tracking_load_number]        AS [load_number]
    , [preplan_tracking_truck_number]       AS [truck_number]

    , [preplan_tracking_driver_seat_1]      AS [primary_driver_code]
    , [preplan_tracking_driver_seat_2]      AS [secondary_driver_code]
    , [preplan_tracking_team_status_code]   AS [team_status_code]

    , [preplan_tracking_dm]                 AS [driver_manager_code]
    , [preplan_tracking_dmol]               AS [driver_manager_operations_lead_code]

    , [preplan_tracking_sent_date]          AS [preplan_sent_date]
    , [preplan_tracking_sent_time]          AS [preplan_sent_time]
    , [preplan_tracking_sent_user_code]     AS [preplan_sent_by_user_code]

    , [preplan_tracking_response_date]      AS [response_date]
    , [preplan_tracking_response_time]      AS [response_time]
    , [is_accepted]                         AS [is_accepted]

    , [preplan_tracking_cancel_date]        AS [cancel_date]
    , [preplan_tracking_cancel_time]        AS [cancel_time]
    , [preplan_tracking_cancel_user_code]   AS [canceled_by_user_code]
    , [is_canceled]                         AS [is_canceled]

    , [preplan_tracking_create_date]        AS [created_date]
    , [preplan_tracking_create_time]        AS [created_time]

FROM [silver].[ibmi_preplan_tracking];