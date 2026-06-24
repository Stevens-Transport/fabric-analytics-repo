-- Auto Generated (Do not modify) E63218335CC31B4A725108410D4B587EEC7CB555FAAE82BEB55C657DE4D609C0
CREATE   VIEW gold.vw_company_driver_earnings AS

SELECT
      [earnings_history_employee_code]                  AS [employee_code]
    , [earnings_history_company_code]                   AS [company_code]
    , [earnings_history_run_code]                       AS [payroll_run_code]
    , [earnings_history_benefit_package_code]           AS [benefit_package_code]
    , [earnings_history_department_code]                AS [department_code]
    , [earnings_history_division_code]                  AS [division_code]
    , [earnings_history_job_description]                AS [job_description]

    , [earnings_history_pay_date]                       AS [pay_date]
    , [earnings_history_pay_week_number]                AS [pay_week_number]
    , [earnings_history_sequence_number]                AS [earnings_sequence_number]

    , [earnings_history_quantity]                       AS [earnings_quantity]
    , [earnings_history_unit_type_code]                 AS [unit_type_code]
    , [is_paid_hours]                                   AS [is_paid_hours]
    , [earnings_history_pay_class_code]                 AS [pay_class_code]
    , [earnings_history_pay_rate]                       AS [pay_rate_type]
    , [earnings_history_per_unit_rate]                  AS [per_unit_rate]
    , [earnings_history_gross_amount]                   AS [gross_amount]
    , [earnings_history_pay_quantity_worked]            AS [pay_quantity_worked]

    , [earnings_history_load_number]                    AS [load_number]
    , [earnings_history_dispatch_number]                AS [dispatch_number]
    , [earnings_history_miles_loaded]                   AS [loaded_miles]
    , [earnings_history_miles_dead_head]                AS [deadhead_miles]
    , [earnings_history_truck_number]                   AS [truck_number]
    , [earnings_history_owner_code]                     AS [owner_code]

    , [earnings_history_origin_city]                    AS [origin_city]
    , [earnings_history_origin_state]                   AS [origin_state]
    , [earnings_history_destination_city]               AS [destination_city]
    , [earnings_history_destination_state]              AS [destination_state]

    , [earnings_history_description]                    AS [earnings_description]
    , [is_solo_or_team]                                 AS [solo_or_team]
    , [has_additional_pay]                              AS [has_additional_pay]
    , [is_wage_dump]                                    AS [is_wage_dump]

    , [earnings_history_truck_expense_account_number]   AS [truck_expense_account_number]
    , [earnings_history_pay_period_end_date]            AS [pay_period_end_date]
    , [earnings_history_expense_account_number]         AS [expense_account_number]
    , [is_expensed]                                     AS [is_expensed]
    , [earnings_history_expensed_book_month]            AS [expensed_book_month]
    , [earnings_history_expensed_book_year]             AS [expensed_book_year]

    , [earnings_history_check_date]                     AS [check_date]
    , [earnings_history_check_number]                   AS [check_number]
    , [earnings_history_paid_book_month]                AS [paid_book_month]
    , [earnings_history_paid_book_year]                 AS [paid_book_year]
    , [is_voided]                                       AS [is_voided]

    , [earnings_history_taxable_days_for_retroactivity] AS [taxable_days_for_retroactivity]
    , [is_on_hold]                                      AS [is_on_hold]

    , [earnings_history_audit_user_code]                AS [audit_user_code]
    , [earnings_history_audit_date]                     AS [audit_date]
    , [earnings_history_audit_time]                     AS [audit_time]

FROM silver.ibmi_earnings_history;