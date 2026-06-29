CREATE   PROCEDURE [dbo].[usp_ibmi_incr_preplan_tracking_silver]
AS
BEGIN
    SET NOCOUNT ON;

    /* ------------------------------------------------------------
       Step 0: Prep + dedupe bronze on the composite key
       Key = OPODR, OPUNIT, OPCRTD, OPCRTT
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#PREPLAN_TRACKING_Deduped','U') IS NOT NULL
        DROP TABLE #PREPLAN_TRACKING_Deduped;

    WITH Prep AS
    (
        SELECT
              TRIM([OPODR]) AS preplan_tracking_load_number
            , TRIM([OPUNIT]) AS preplan_tracking_truck_number
            , TRIM([OPDR1]) AS preplan_tracking_driver_seat_1
            , TRIM([OPDR2]) AS preplan_tracking_driver_seat_2
            , TRIM([OPTEAM]) AS preplan_tracking_team_status_code
            , TRIM([OPSUPR]) AS preplan_tracking_dm
            , TRIM([OPFMGR]) AS preplan_tracking_dmol
            , CASE
                WHEN [OPDSNT] = '0001-01-01' THEN NULL
                ELSE [OPDSNT]
              END AS preplan_tracking_sent_date
            , CASE
                WHEN [OPDSNT] = '0001-01-01' THEN NULL
                ELSE CAST(REPLACE([OPTSNT], '.', ':') AS TIME(6))
              END AS preplan_tracking_sent_time
            , TRIM([OPSUSR]) AS preplan_tracking_sent_user_code
            , CASE
                WHEN [OPDRSP] = '0001-01-01' THEN NULL
                ELSE [OPDRSP]
              END AS preplan_tracking_response_date
            , CASE
                WHEN [OPDRSP] = '0001-01-01' THEN NULL
                ELSE CAST(REPLACE([OPTRSP], '.', ':') AS TIME(6))
              END AS preplan_tracking_response_time
            , CASE 
                WHEN TRIM(OPACPT) = 'Y' THEN 'TRUE'
                WHEN TRIM(OPACPT) = 'N' THEN 'FALSE'
                ELSE 'unknown'
              END AS is_accepted
            , CASE
                WHEN [OPDCNL] = '0001-01-01' THEN NULL
                ELSE [OPDCNL]
              END AS preplan_tracking_cancel_date
            , CASE
                WHEN [OPDCNL] = '0001-01-01' THEN NULL
                ELSE CAST(REPLACE([OPTCNL], '.', ':') AS TIME(6))
              END AS preplan_tracking_cancel_time
            , TRIM([OPCUSR]) AS preplan_tracking_cancel_user_code
            , CASE 
                WHEN TRIM(OPCNCL) = 'Y' THEN 'TRUE'
                ELSE 'FALSE'
              END AS is_canceled
            , CASE
                WHEN [OPCRTD] = '0001-01-01' THEN NULL
                ELSE [OPCRTD]
              END AS preplan_tracking_create_date
            , CASE
                WHEN [OPCRTD] = '0001-01-01' THEN NULL
                ELSE CAST(REPLACE([OPCRTT], '.', ':') AS TIME(6))
              END AS preplan_tracking_create_time
            , a.loadDate
            , a.recordNumber
        FROM data_central_lh.dbo.ibmi_incr_preplan_tracking_bronze a
    )
    SELECT *
    INTO #PREPLAN_TRACKING_Deduped
    FROM
    (
        SELECT
              p.*
            , ROW_NUMBER() OVER
              (
                  PARTITION BY
                        p.preplan_tracking_load_number
                      , p.preplan_tracking_truck_number
                      , p.preplan_tracking_create_date
                      , p.preplan_tracking_create_time
                  ORDER BY p.loadDate DESC, p.recordNumber DESC
              ) AS rn
        FROM Prep p
    ) x
    WHERE x.rn = 1;

    /* ------------------------------------------------------------
       Step 1: UPDATE matches
       ------------------------------------------------------------ */
    UPDATE T
       SET T.preplan_tracking_driver_seat_1      = S.preplan_tracking_driver_seat_1
         , T.preplan_tracking_driver_seat_2      = S.preplan_tracking_driver_seat_2
         , T.preplan_tracking_team_status_code   = S.preplan_tracking_team_status_code
         , T.preplan_tracking_dm                 = S.preplan_tracking_dm
         , T.preplan_tracking_dmol               = S.preplan_tracking_dmol
         , T.preplan_tracking_sent_date          = S.preplan_tracking_sent_date
         , T.preplan_tracking_sent_time          = S.preplan_tracking_sent_time
         , T.preplan_tracking_sent_user_code     = S.preplan_tracking_sent_user_code
         , T.preplan_tracking_response_date      = S.preplan_tracking_response_date
         , T.preplan_tracking_response_time      = S.preplan_tracking_response_time
         , T.is_accepted                         = S.is_accepted
         , T.preplan_tracking_cancel_date        = S.preplan_tracking_cancel_date
         , T.preplan_tracking_cancel_time        = S.preplan_tracking_cancel_time
         , T.preplan_tracking_cancel_user_code   = S.preplan_tracking_cancel_user_code
         , T.is_canceled                         = S.is_canceled
    FROM silver.ibmi_preplan_tracking T
    INNER JOIN #PREPLAN_TRACKING_Deduped S
        ON T.preplan_tracking_load_number  = S.preplan_tracking_load_number
       AND T.preplan_tracking_truck_number = S.preplan_tracking_truck_number
       AND (
            (T.preplan_tracking_create_date IS NULL AND S.preplan_tracking_create_date IS NULL)
            OR T.preplan_tracking_create_date = S.preplan_tracking_create_date
           )
       AND (
            (T.preplan_tracking_create_time IS NULL AND S.preplan_tracking_create_time IS NULL)
            OR T.preplan_tracking_create_time = S.preplan_tracking_create_time
           );

    /* ------------------------------------------------------------
       Step 2: INSERT non-matches
       ------------------------------------------------------------ */
    INSERT INTO silver.ibmi_preplan_tracking
    (
          preplan_tracking_load_number
        , preplan_tracking_truck_number
        , preplan_tracking_driver_seat_1
        , preplan_tracking_driver_seat_2
        , preplan_tracking_team_status_code
        , preplan_tracking_dm
        , preplan_tracking_dmol
        , preplan_tracking_sent_date
        , preplan_tracking_sent_time
        , preplan_tracking_sent_user_code
        , preplan_tracking_response_date
        , preplan_tracking_response_time
        , is_accepted
        , preplan_tracking_cancel_date
        , preplan_tracking_cancel_time
        , preplan_tracking_cancel_user_code
        , is_canceled
        , preplan_tracking_create_date
        , preplan_tracking_create_time
    )
    SELECT
          S.preplan_tracking_load_number
        , S.preplan_tracking_truck_number
        , S.preplan_tracking_driver_seat_1
        , S.preplan_tracking_driver_seat_2
        , S.preplan_tracking_team_status_code
        , S.preplan_tracking_dm
        , S.preplan_tracking_dmol
        , S.preplan_tracking_sent_date
        , S.preplan_tracking_sent_time
        , S.preplan_tracking_sent_user_code
        , S.preplan_tracking_response_date
        , S.preplan_tracking_response_time
        , S.is_accepted
        , S.preplan_tracking_cancel_date
        , S.preplan_tracking_cancel_time
        , S.preplan_tracking_cancel_user_code
        , S.is_canceled
        , S.preplan_tracking_create_date
        , S.preplan_tracking_create_time
    FROM #PREPLAN_TRACKING_Deduped S
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM silver.ibmi_preplan_tracking T
        WHERE T.preplan_tracking_load_number  = S.preplan_tracking_load_number
          AND T.preplan_tracking_truck_number = S.preplan_tracking_truck_number
          AND (
                (T.preplan_tracking_create_date IS NULL AND S.preplan_tracking_create_date IS NULL)
                OR T.preplan_tracking_create_date = S.preplan_tracking_create_date
              )
          AND (
                (T.preplan_tracking_create_time IS NULL AND S.preplan_tracking_create_time IS NULL)
                OR T.preplan_tracking_create_time = S.preplan_tracking_create_time
              )
    );

    DROP TABLE #PREPLAN_TRACKING_Deduped;
END;