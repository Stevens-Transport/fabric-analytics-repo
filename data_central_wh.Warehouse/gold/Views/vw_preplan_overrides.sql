-- Auto Generated (Do not modify) 827F38CF224AC1C3A35F29C52669384AE08C74323A6945D0F0B3ACA9CA759A76
CREATE   VIEW [gold].[vw_preplan_overrides]
AS

SELECT
      [preplan_overrides_load_number]                    AS [load_number]
    , [preplan_overrides_dispatch]                       AS [dispatch_number]

    , [preplan_overrides_planned_truck_number]           AS [planned_truck_number]
    , [preplan_overrides_model_recommended_truck_number] AS [model_recommended_truck_number]

    , [is_unplanned]                                     AS [is_unplanned]

    , [preplan_overrides_model_plan_code]                AS [model_plan_code]
    , [preplan_overrides_override_code]                  AS [override_code]
    , [preplan_overrides_override_description]           AS [override_description]

    , [preplan_overrides_dispatch_datetime]              AS [dispatch_datetime]
    , [preplan_overrides_create_datetime]                AS [created_datetime]

    , [preplan_overrides_model_recommended_at_dispatch]  AS [model_recommendation_at_dispatch]
    , [preplan_overrides_model_plan_at_dispatch]         AS [model_plan_at_dispatch]

    , [preplan_overrides_user_code]                      AS [override_user_code]
    , [preplan_overrides_area_code]                      AS [area_code]

FROM [silver].[ibmi_preplan_overrides];