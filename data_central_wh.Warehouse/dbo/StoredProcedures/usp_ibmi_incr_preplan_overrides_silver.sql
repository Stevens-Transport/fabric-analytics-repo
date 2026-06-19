CREATE   PROCEDURE [dbo].[usp_ibmi_incr_preplan_overrides_silver]
AS
BEGIN
    SET NOCOUNT ON;

    /* ------------------------------------------------------------
       Step 0: Prep + dedupe bronze on the composite key
       Key = PVORD#, PVSEG, PVUNIT
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#PREPLAN_OVERRIDES_Deduped','U') IS NOT NULL
        DROP TABLE #PREPLAN_OVERRIDES_Deduped;

    WITH Prep AS
    (
        SELECT
              TRIM(a.PVORD#)          AS preplan_overrides_load_number
            , TRIM(a.PVSEG)           AS preplan_overrides_dispatch
            , TRIM(a.PVUNIT)          AS preplan_overrides_planned_truck_number
            , TRIM(a.PVMODL)          AS preplan_overrides_model_recommended_truck_number
            , CASE
                WHEN TRIM(a.PVUNPL) = 'Y' THEN 'TRUE'
                ELSE 'FALSE'
              END                     AS is_unplanned
            , TRIM(a.PVMDPL)          AS preplan_overrides_model_plan_code
            , TRIM(a.PVOVCD)          AS preplan_overrides_override_code
            , TRIM(a.PVDESC)          AS preplan_overrides_override_description
            , a.DISPATCH_DATETIME     AS preplan_overrides_dispatch_datetime
            , a.CREATE_DATETIME       AS preplan_overrides_create_datetime
            , TRIM(a.PVDMOD)          AS preplan_overrides_model_recommended_at_dispatch
            , TRIM(a.PVDMDP)          AS preplan_overrides_model_plan_at_dispatch
            , TRIM(a.PVUSER)          AS preplan_overrides_user_code
            , TRIM(a.PVAREA)          AS preplan_overrides_area_code
            , a.loadDate
            , a.recordNumber
        FROM data_central_lh.dbo.ibmi_incr_preplan_overrides_bronze a
    )
    SELECT *
    INTO #PREPLAN_OVERRIDES_Deduped
    FROM
    (
        SELECT
              p.*
            , ROW_NUMBER() OVER
              (
                  PARTITION BY
                        p.preplan_overrides_load_number
                      , p.preplan_overrides_dispatch
                      , p.preplan_overrides_planned_truck_number
                  ORDER BY p.loadDate DESC, p.recordNumber DESC
              ) AS rn
        FROM Prep p
    ) x
    WHERE x.rn = 1;

    /* ------------------------------------------------------------
       Step 1: UPDATE matches
       ------------------------------------------------------------ */
    UPDATE T
       SET T.preplan_overrides_model_recommended_truck_number = S.preplan_overrides_model_recommended_truck_number
         , T.is_unplanned                                     = S.is_unplanned
         , T.preplan_overrides_model_plan_code                = S.preplan_overrides_model_plan_code
         , T.preplan_overrides_override_code                  = S.preplan_overrides_override_code
         , T.preplan_overrides_override_description           = S.preplan_overrides_override_description
         , T.preplan_overrides_dispatch_datetime              = S.preplan_overrides_dispatch_datetime
         , T.preplan_overrides_create_datetime                = S.preplan_overrides_create_datetime
         , T.preplan_overrides_model_recommended_at_dispatch  = S.preplan_overrides_model_recommended_at_dispatch
         , T.preplan_overrides_model_plan_at_dispatch         = S.preplan_overrides_model_plan_at_dispatch
         , T.preplan_overrides_user_code                      = S.preplan_overrides_user_code
         , T.preplan_overrides_area_code                      = S.preplan_overrides_area_code
    FROM silver.ibmi_preplan_overrides T
    INNER JOIN #PREPLAN_OVERRIDES_Deduped S
        ON T.preplan_overrides_load_number          = S.preplan_overrides_load_number
       AND T.preplan_overrides_dispatch             = S.preplan_overrides_dispatch
       AND T.preplan_overrides_planned_truck_number = S.preplan_overrides_planned_truck_number;

    /* ------------------------------------------------------------
       Step 2: INSERT non-matches
       ------------------------------------------------------------ */
    INSERT INTO silver.ibmi_preplan_overrides
    (
          preplan_overrides_load_number
        , preplan_overrides_dispatch
        , preplan_overrides_planned_truck_number
        , preplan_overrides_model_recommended_truck_number
        , is_unplanned
        , preplan_overrides_model_plan_code
        , preplan_overrides_override_code
        , preplan_overrides_override_description
        , preplan_overrides_dispatch_datetime
        , preplan_overrides_create_datetime
        , preplan_overrides_model_recommended_at_dispatch
        , preplan_overrides_model_plan_at_dispatch
        , preplan_overrides_user_code
        , preplan_overrides_area_code
    )
    SELECT
          S.preplan_overrides_load_number
        , S.preplan_overrides_dispatch
        , S.preplan_overrides_planned_truck_number
        , S.preplan_overrides_model_recommended_truck_number
        , S.is_unplanned
        , S.preplan_overrides_model_plan_code
        , S.preplan_overrides_override_code
        , S.preplan_overrides_override_description
        , S.preplan_overrides_dispatch_datetime
        , S.preplan_overrides_create_datetime
        , S.preplan_overrides_model_recommended_at_dispatch
        , S.preplan_overrides_model_plan_at_dispatch
        , S.preplan_overrides_user_code
        , S.preplan_overrides_area_code
    FROM #PREPLAN_OVERRIDES_Deduped S
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM silver.ibmi_preplan_overrides T
        WHERE T.preplan_overrides_load_number          = S.preplan_overrides_load_number
          AND T.preplan_overrides_dispatch             = S.preplan_overrides_dispatch
          AND T.preplan_overrides_planned_truck_number = S.preplan_overrides_planned_truck_number
    );

    DROP TABLE #PREPLAN_OVERRIDES_Deduped;
END;