CREATE     PROCEDURE [dbo].[usp_ibmi_incr_tlb_negotiations_silver]
AS
BEGIN
    SET NOCOUNT ON;

    /* ------------------------------------------------------------
       Step 0: Prep + dedupe bronze on the composite key
       Key = BNOWNR, BNORD
       ------------------------------------------------------------ */
    IF OBJECT_ID('tempdb..#TLB_NEGOTIATIONS_Deduped','U') IS NOT NULL
        DROP TABLE #TLB_NEGOTIATIONS_Deduped;

    WITH Prep AS
    (
        SELECT
              TRIM(a.BNSTAT) AS tlb_negotiations_status_code
            , TRIM(a.BNCO) AS tlb_negotiations_company_number
            , a.BNSEQ AS tlb_negotiations_sequence_number
            , TRIM(a.BNOWNR) AS tlb_negotiations_owner_code
            , TRIM(a.BNORD) AS tlb_negotiations_load_number
            , a.BNFAMT AS tlb_negotiations_flat_amount
            , CONVERT(INT, a.BNAC) + CONVERT(INT, a.BNTEL) AS tlb_negotiations_contact_phone_number
            , TRIM(a.BNCNAM) AS tlb_negotiations_contact_name
            , TRIM(a.BNRSLT) AS tlb_negotiations_result_code
            , BNDATE.date_key_pk AS tlb_negotiations_negotiation_date
            , CASE 
                WHEN TRIM(a.BNTIME) <= 2359
                     AND LEN(CONVERT(VARCHAR(4), CONVERT(INT, TRIM(a.BNTIME)))) = 4
                    THEN TIMEFROMPARTS(
                            LEFT(CONVERT(INT, TRIM(a.BNTIME)), 2),
                            RIGHT(CONVERT(INT, TRIM(a.BNTIME)), 2),
                            0,0,0
                         )
                WHEN TRIM(a.BNTIME) <= 2359
                     AND LEN(CONVERT(VARCHAR(4), CONVERT(INT, TRIM(a.BNTIME)))) = 3
                    THEN TIMEFROMPARTS(
                            LEFT(CONVERT(INT, TRIM(a.BNTIME)), 1),
                            RIGHT(CONVERT(INT, TRIM(a.BNTIME)), 2),
                            0,0,0
                         )
                WHEN TRIM(a.BNTIME) <= 2359
                     AND LEN(CONVERT(VARCHAR(4), CONVERT(INT, TRIM(a.BNTIME)))) IN (1,2)
                    THEN TIMEFROMPARTS(
                            0,
                            CONVERT(INT, TRIM(a.BNTIME)),
                            0,0,0
                         )
                ELSE NULL
              END AS tlb_negotiations_negotiation_time
            , TRIM(a.BNUSER) AS tlb_negotiations_negotiation_user_code
            , a.loadDate
            , a.recordNumber
        FROM data_central_lh.dbo.ibmi_incr_tlb_negotiations_bronze a
        LEFT JOIN gold.dim_date BNDATE
            ON a.BNDATE = BNDATE.date_ordinal
    )
    SELECT *
    INTO #TLB_NEGOTIATIONS_Deduped
    FROM
    (
        SELECT
              p.*
            , ROW_NUMBER() OVER
              (
                  PARTITION BY
                        p.tlb_negotiations_owner_code
                      , p.tlb_negotiations_load_number
                  ORDER BY p.loadDate DESC, p.recordNumber DESC
              ) AS rn
        FROM Prep p
    ) x
    WHERE x.rn = 1;

    /* ------------------------------------------------------------
       Step 1: UPDATE matches
       ------------------------------------------------------------ */
    UPDATE T
       SET T.tlb_negotiations_status_code            = S.tlb_negotiations_status_code
         , T.tlb_negotiations_company_number         = S.tlb_negotiations_company_number
         , T.tlb_negotiations_sequence_number        = S.tlb_negotiations_sequence_number
         , T.tlb_negotiations_flat_amount            = S.tlb_negotiations_flat_amount
         , T.tlb_negotiations_contact_phone_number   = S.tlb_negotiations_contact_phone_number
         , T.tlb_negotiations_contact_name           = S.tlb_negotiations_contact_name
         , T.tlb_negotiations_result_code            = S.tlb_negotiations_result_code
         , T.tlb_negotiations_negotiation_date       = S.tlb_negotiations_negotiation_date
         , T.tlb_negotiations_negotiation_time       = S.tlb_negotiations_negotiation_time
         , T.tlb_negotiations_negotiation_user_code  = S.tlb_negotiations_negotiation_user_code
    FROM silver.ibmi_tlb_negotiations T
    INNER JOIN #TLB_NEGOTIATIONS_Deduped S
        ON T.tlb_negotiations_owner_code = S.tlb_negotiations_owner_code
       AND T.tlb_negotiations_load_number = S.tlb_negotiations_load_number;

    /* ------------------------------------------------------------
       Step 2: INSERT non-matches
       ------------------------------------------------------------ */
    INSERT INTO silver.ibmi_tlb_negotiations
    (
          tlb_negotiations_status_code
        , tlb_negotiations_company_number
        , tlb_negotiations_sequence_number
        , tlb_negotiations_owner_code
        , tlb_negotiations_load_number
        , tlb_negotiations_flat_amount
        , tlb_negotiations_contact_phone_number
        , tlb_negotiations_contact_name
        , tlb_negotiations_result_code
        , tlb_negotiations_negotiation_date
        , tlb_negotiations_negotiation_time
        , tlb_negotiations_negotiation_user_code
    )
    SELECT
          S.tlb_negotiations_status_code
        , S.tlb_negotiations_company_number
        , S.tlb_negotiations_sequence_number
        , S.tlb_negotiations_owner_code
        , S.tlb_negotiations_load_number
        , S.tlb_negotiations_flat_amount
        , S.tlb_negotiations_contact_phone_number
        , S.tlb_negotiations_contact_name
        , S.tlb_negotiations_result_code
        , S.tlb_negotiations_negotiation_date
        , S.tlb_negotiations_negotiation_time
        , S.tlb_negotiations_negotiation_user_code
    FROM #TLB_NEGOTIATIONS_Deduped S
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM silver.ibmi_tlb_negotiations T
        WHERE T.tlb_negotiations_owner_code = S.tlb_negotiations_owner_code
          AND T.tlb_negotiations_load_number = S.tlb_negotiations_load_number
    );

    DROP TABLE #TLB_NEGOTIATIONS_Deduped;
END;