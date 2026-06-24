-- Auto Generated (Do not modify) 56D0A36C5BC4527506CE3E294ACC014DED71A994F2F56295E6CD496CC4C82312
CREATE   VIEW gold.vw_contrator_settlement_earnings AS

SELECT
      [set_rev_hist_owner_code]                  AS [owner_code]
    , [set_rev_hist_truck_number]                AS [truck_number]
    , [set_rev_hist_load_number]                 AS [load_number]
    , [set_rev_hist_dispatch_number]             AS [dispatch_number]
    , [set_rev_hist_sequence_number]             AS [settlement_revenue_sequence_number]

    , [set_rev_hist_load_date]                   AS [load_date_code]
    , [set_rev_hist_load_year]                   AS [load_year]
    , [set_rev_hist_load_date_revised]           AS [revised_load_date]
    , [set_rev_hist_record_date]                 AS [record_date]

    , [set_rev_hist_origin_city]                 AS [origin_city]
    , [set_rev_hist_destination_city]            AS [destination_city]

    , [set_rev_hist_revenue_amount]              AS [revenue_amount]
    , [set_rev_hist_fund_code]                   AS [revenue_fund_code]
    , [set_rev_hist_segment_status_code]         AS [segment_status_code]

    , [set_rev_hist_miles_total]                 AS [total_miles]
    , [set_rev_hist_origin_code]                 AS [origin_code]
    , [set_rev_hist_destination_code]            AS [destination_code]

    , [set_rev_hist_additional_pay_amount]       AS [additional_pay_amount]
    , [set_rev_hist_additional_pay_fund_code]    AS [additional_pay_fund_code]

    , [set_rev_hist_miles_loaded]                AS [loaded_miles]
    , [set_rev_hist_loaded_mileage_rate]         AS [loaded_mileage_rate]
    , [set_rev_hist_miles_dead_head]             AS [deadhead_miles]
    , [set_rev_hist_dead_head_mileage_rate]      AS [deadhead_mileage_rate]
    , [set_rev_hist_mileage_rate_fund_code]      AS [mileage_rate_fund_code]

    , [set_rev_hist_debit_account_number]        AS [debit_account_number]
    , [set_rev_hist_credit_account_number]       AS [credit_account_number]

    , [set_rev_hist_expense_month]               AS [expense_book_month]
    , [set_rev_hist_expense_year]                AS [expense_book_year]
    , [set_rev_hist_paid_month]                  AS [paid_book_month]
    , [set_rev_hist_paid_year]                   AS [paid_book_year]
    , [is_expensed]                              AS [is_expensed]

    , [set_rev_hist_domestic_amount]             AS [domestic_amount]
    , [set_rev_hist_domestic_expensed_date]      AS [domestic_expensed_date]

    , [set_rev_hist_revenue_type_code]           AS [revenue_type_code]
    , [set_rev_hist_voucher_number]              AS [voucher_number]

    , [set_rev_hist_last_update_date]            AS [last_update_date]
    , [set_rev_hist_last_update_time]            AS [last_update_time]
    , [set_rev_hist_last_update_initials]        AS [last_update_initials]

FROM silver.ibmi_settlement_revenue_history;