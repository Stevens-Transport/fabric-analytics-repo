CREATE   PROCEDURE [dbo].[usp_ibmi_incr_repowers_silver]
AS
BEGIN
    SET NOCOUNT ON;

    /* ------------------------------------------------------------
       Step 0: Prep + dedupe bronze on the composite key
       Key = SDDRVR1, SDLOAD1, SDDISP1, SDDRVR2, SDLOAD2, SDDISP2
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#REPOWERS_Deduped','U') IS NOT NULL
        DROP TABLE #REPOWERS_Deduped;

    WITH Prep AS
    (
        SELECT
              TRIM(a.SDDRVR1) AS repowers_truck_number_1
            , TRIM(a.SDLOAD1) AS repowers_load_number_1
            , TRIM(a.SDDISP1) AS repowers_dispatch_1
            , TRIM(a.SDDRVR2) AS repowers_truck_number_2
            , TRIM(a.SDLOAD2) AS repowers_load_number_2
            , TRIM(a.SDDISP2) AS repowers_dispatch_2
            , CASE
                TRIM(a.SDSTATUS)
                    WHEN 'FLD' THEN 'FAILED'
                    WHEN 'RMV' THEN 'REMOVED'
                    WHEN 'PLN' THEN 'PLANNED'
                    WHEN 'CMP' THEN 'COMPLETED'
                    WHEN 'HLD' THEN 'HOLD'
                    ELSE 'unknown'
              END AS repowers_status
            , a.STATUS_DATETIME AS repowers_status_datetime
            , TRIM(a.SDUSER) AS repowers_swap_user_code
            , TRIM(a.SDLOC) AS repowers_swap_location_code
            , TRIM(a.SDSTOP) AS repowers_swap_stop_number
            , a.SWAP_DATETIME AS repowers_swap_datetime
            , TRIM(a.SDNXT1) AS repowers_next_location_code_post_swap_1
            , TRIM(a.SDNXT2) AS repowers_next_location_code_post_swap_2
            , TRIM(a.SDREAS) AS repowers_swap_reason_code
            , TRIM(a.SDCRTU) AS repowers_create_user_code
            , a.CREATE_DATETIME AS repowers_create_datetime
            , CASE
                TRIM(a.SDCHRG)
                    WHEN 'Y' THEN 'TRUE'
                    WHEN 'N' THEN 'FALSE'
                    ELSE 'unknown'
              END AS is_chargeable_to_driver
            , a.loadDate
            , a.recordNumber
        FROM data_central_lh.dbo.ibmi_incr_repowers_bronze a
    )
    SELECT *
    INTO #REPOWERS_Deduped
    FROM
    (
        SELECT
              p.*
            , ROW_NUMBER() OVER
              (
                  PARTITION BY
                        p.repowers_truck_number_1
                      , p.repowers_load_number_1
                      , p.repowers_dispatch_1
                      , p.repowers_truck_number_2
                      , p.repowers_load_number_2
                      , p.repowers_dispatch_2
                  ORDER BY p.loadDate DESC, p.recordNumber DESC
              ) AS rn
        FROM Prep p
    ) x
    WHERE x.rn = 1;

    /* ------------------------------------------------------------
       Step 1: UPDATE matches
       ------------------------------------------------------------ */
    UPDATE T
       SET T.repowers_status                          = S.repowers_status
         , T.repowers_status_datetime                 = S.repowers_status_datetime
         , T.repowers_swap_user_code                  = S.repowers_swap_user_code
         , T.repowers_swap_location_code              = S.repowers_swap_location_code
         , T.repowers_swap_stop_number                = S.repowers_swap_stop_number
         , T.repowers_swap_datetime                   = S.repowers_swap_datetime
         , T.repowers_next_location_code_post_swap_1 = S.repowers_next_location_code_post_swap_1
         , T.repowers_next_location_code_post_swap_2 = S.repowers_next_location_code_post_swap_2
         , T.repowers_swap_reason_code                = S.repowers_swap_reason_code
         , T.repowers_create_user_code                = S.repowers_create_user_code
         , T.repowers_create_datetime                 = S.repowers_create_datetime
         , T.is_chargeable_to_driver                  = S.is_chargeable_to_driver
    FROM silver.ibmi_repowers T
    INNER JOIN #REPOWERS_Deduped S
        ON T.repowers_truck_number_1 = S.repowers_truck_number_1
       AND T.repowers_load_number_1  = S.repowers_load_number_1
       AND T.repowers_dispatch_1     = S.repowers_dispatch_1
       AND T.repowers_truck_number_2 = S.repowers_truck_number_2
       AND T.repowers_load_number_2  = S.repowers_load_number_2
       AND T.repowers_dispatch_2     = S.repowers_dispatch_2;

    /* ------------------------------------------------------------
       Step 2: INSERT non-matches
       ------------------------------------------------------------ */
    INSERT INTO silver.ibmi_repowers
    (
          repowers_truck_number_1
        , repowers_load_number_1
        , repowers_dispatch_1
        , repowers_truck_number_2
        , repowers_load_number_2
        , repowers_dispatch_2
        , repowers_status
        , repowers_status_datetime
        , repowers_swap_user_code
        , repowers_swap_location_code
        , repowers_swap_stop_number
        , repowers_swap_datetime
        , repowers_next_location_code_post_swap_1
        , repowers_next_location_code_post_swap_2
        , repowers_swap_reason_code
        , repowers_create_user_code
        , repowers_create_datetime
        , is_chargeable_to_driver
    )
    SELECT
          S.repowers_truck_number_1
        , S.repowers_load_number_1
        , S.repowers_dispatch_1
        , S.repowers_truck_number_2
        , S.repowers_load_number_2
        , S.repowers_dispatch_2
        , S.repowers_status
        , S.repowers_status_datetime
        , S.repowers_swap_user_code
        , S.repowers_swap_location_code
        , S.repowers_swap_stop_number
        , S.repowers_swap_datetime
        , S.repowers_next_location_code_post_swap_1
        , S.repowers_next_location_code_post_swap_2
        , S.repowers_swap_reason_code
        , S.repowers_create_user_code
        , S.repowers_create_datetime
        , S.is_chargeable_to_driver
    FROM #REPOWERS_Deduped S
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM silver.ibmi_repowers T
        WHERE T.repowers_truck_number_1 = S.repowers_truck_number_1
          AND T.repowers_load_number_1  = S.repowers_load_number_1
          AND T.repowers_dispatch_1     = S.repowers_dispatch_1
          AND T.repowers_truck_number_2 = S.repowers_truck_number_2
          AND T.repowers_load_number_2  = S.repowers_load_number_2
          AND T.repowers_dispatch_2     = S.repowers_dispatch_2
    );

    DROP TABLE #REPOWERS_Deduped;
END;