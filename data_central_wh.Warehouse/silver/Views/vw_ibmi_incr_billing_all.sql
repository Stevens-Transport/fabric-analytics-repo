-- Auto Generated (Do not modify) 75E381826EB3DFC6B4FFD50AC501BBE5E0A8A384884D183B6D3AC978BD1F0347
CREATE     VIEW silver.vw_ibmi_incr_billing_all
AS

WITH cd_load_totals AS (
    SELECT
        cd_billing_load_number AS billing_load_number,
        SUM(CAST(cd_billing_billed_amount AS decimal(19,4))) AS cd_total
    FROM silver.ibmi_incr_cd_billing_new
    WHERE is_deleted = 0
    GROUP BY cd_billing_load_number
),

co_load_totals AS (
    SELECT
        billing_load_number,
        SUM(CAST(billing_billed_amount AS decimal(19,4))) AS co_total
    FROM silver.ibmi_incr_billing_new
    WHERE is_deleted = 0
    GROUP BY billing_load_number
),

cd_artifact_loads AS (
    SELECT
        cd.billing_load_number
    FROM cd_load_totals cd
    INNER JOIN co_load_totals co
        ON cd.billing_load_number = co.billing_load_number
    WHERE cd.cd_total = 1.00
      AND co.co_total > 1.00
),

cd_eligible_loads AS (
    SELECT
        cd.billing_load_number
    FROM cd_load_totals cd
    WHERE NOT EXISTS (
        SELECT 1
        FROM cd_artifact_loads artifact
        WHERE artifact.billing_load_number = cd.billing_load_number
    )
),

tlb_eligible_loads AS (
    SELECT DISTINCT
        tlb_billing_load_number AS billing_load_number
    FROM silver.ibmi_incr_tlb_billing_new tlb
    WHERE is_deleted = 0
      AND NOT EXISTS (
          SELECT 1
          FROM cd_eligible_loads cd
          WHERE cd.billing_load_number = tlb.tlb_billing_load_number
      )
)

SELECT 
       [cd_billing_load_number]           AS billing_load_number
      ,[cd_billing_sequence_number]       AS billing_sequence_number
      ,[cd_billing_record_number]         AS billing_record_number
      ,[is_deleted]
      ,[cd_billing_commodity_code]        AS billing_commodity_code
      ,[cd_billing_commodity_description] AS billing_commodity_description
      ,[cd_billing_piece_count]           AS billing_piece_count
      ,[cd_billing_actual_quantity_count] AS billing_actual_quantity_count
      ,[cd_billing_billed_quantity_count] AS billing_billed_quantity_count
      ,[cd_billing_billed_rate]           AS billing_billed_rate
      ,[cd_billing_billed_amount]         AS billing_billed_amount
      ,[cd_billing_method_code]           AS billing_method_code
      ,[cd_billing_error_code]            AS billing_error_code
      ,[cd_billing_gl_account_number]     AS billing_gl_account_number
      ,'CD'                               AS [entity]
FROM silver.ibmi_incr_cd_billing_new cd
WHERE EXISTS (
    SELECT 1
    FROM cd_eligible_loads eligible_cd
    WHERE eligible_cd.billing_load_number = cd.cd_billing_load_number
)

UNION ALL

SELECT
       [tlb_billing_load_number]           AS billing_load_number
      ,[tlb_billing_sequence_number]       AS billing_sequence_number
      ,[tlb_billing_record_number]         AS billing_record_number
      ,[is_deleted]
      ,[tlb_billing_commodity_code]        AS billing_commodity_code
      ,[tlb_billing_commodity_description] AS billing_commodity_description
      ,[tlb_billing_piece_count]           AS billing_piece_count
      ,[tlb_billing_actual_quantity_count] AS billing_actual_quantity_count
      ,[tlb_billing_billed_quantity_count] AS billing_billed_quantity_count
      ,[tlb_billing_billed_rate]           AS billing_billed_rate
      ,[tlb_billing_billed_amount]         AS billing_billed_amount
      ,[tlb_billing_method_code]           AS billing_method_code
      ,[tlb_billing_error_code]            AS billing_error_code
      ,[tlb_billing_gl_account_number]     AS billing_gl_account_number
      ,'TL'                                AS [entity]
FROM silver.ibmi_incr_tlb_billing_new tlb
WHERE EXISTS (
    SELECT 1
    FROM tlb_eligible_loads eligible_tlb
    WHERE eligible_tlb.billing_load_number = tlb.tlb_billing_load_number
)

UNION ALL

SELECT
       [billing_load_number]               AS billing_load_number
      ,[billing_sequence_number]           AS billing_sequence_number
      ,[billing_record_number]             AS billing_record_number
      ,[is_deleted]
      ,[billing_commodity_code]            AS billing_commodity_code
      ,[billing_commodity_description]     AS billing_commodity_description
      ,[billing_piece_count]               AS billing_piece_count
      ,[billing_actual_quantity_count]     AS billing_actual_quantity_count
      ,[billing_billed_quantity_count]     AS billing_billed_quantity_count
      ,[billing_billed_rate]               AS billing_billed_rate
      ,[billing_billed_amount]             AS billing_billed_amount
      ,[billing_method_code]               AS billing_method_code
      ,[billing_error_code]                AS billing_error_code
      ,[billing_gl_account_number]         AS billing_gl_account_number
      ,'CO'                                AS [entity]
FROM silver.ibmi_incr_billing_new co
WHERE NOT EXISTS (
    SELECT 1
    FROM cd_eligible_loads eligible_cd
    WHERE eligible_cd.billing_load_number = co.billing_load_number
)
AND NOT EXISTS (
    SELECT 1
    FROM tlb_eligible_loads eligible_tlb
    WHERE eligible_tlb.billing_load_number = co.billing_load_number
);