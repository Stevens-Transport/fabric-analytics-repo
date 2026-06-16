-- Auto Generated (Do not modify) 1A4E25025201988FAFC183655048A86DBEADE5D247D5B7DCC450D3F1E9D6D25B
CREATE     VIEW gold.vw_ibmi_billing_combined AS

-- Incremental Billing
SELECT 
     i.billing_load_number
    ,i.billing_sequence_number
    ,i.billing_record_number
    ,i.is_deleted
    ,i.billing_commodity_code
    ,i.billing_commodity_description
    ,i.billing_piece_count
    ,i.billing_actual_quantity_count
    ,i.billing_billed_quantity_count
    ,i.billing_billed_rate
    ,i.billing_billed_amount
    ,i.billing_method_code
    ,i.billing_error_code
    ,i.billing_gl_account_number
    ,i.[entity]
    ,ord.order_loaded_call_date AS order_loaded_call_date
FROM silver.vw_ibmi_incr_billing_all AS i
INNER JOIN gold.vw_ibmi_order_combined AS ord
    ON i.billing_load_number = ord.order_load_number
WHERE ord.order_status_code <> 'C'

UNION ALL

-- Historical Billing Exclude Incremental
SELECT 
     b.billing_load_number
    ,b.billing_sequence_number
    ,b.billing_record_number
    ,b.is_deleted
    ,b.billing_commodity_code
    ,b.billing_commodity_description
    ,b.billing_piece_count
    ,b.billing_actual_quantity_count
    ,b.billing_billed_quantity_count
    ,b.billing_billed_rate
    ,b.billing_billed_amount
    ,b.billing_method_code
    ,b.billing_error_code
    ,b.billing_gl_account_number
    ,b.[entity]
    ,ord.order_loaded_call_date AS order_loaded_call_date
FROM silver.vw_ibmi_billing_all AS b
INNER JOIN gold.vw_ibmi_order_combined AS ord
    ON b.billing_load_number = ord.order_load_number
WHERE ord.order_status_code <> 'C'
  AND NOT EXISTS (
        SELECT 1
        FROM silver.vw_ibmi_incr_billing_all AS i
        WHERE i.billing_load_number     = b.billing_load_number
          AND i.billing_sequence_number = b.billing_sequence_number
          AND i.billing_record_number   = b.billing_record_number
  );