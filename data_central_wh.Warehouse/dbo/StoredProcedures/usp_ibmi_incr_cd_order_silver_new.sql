CREATE   PROCEDURE [dbo].[usp_ibmi_incr_cd_order_silver_new]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF OBJECT_ID('tempdb..#DedupedWithDates') IS NOT NULL DROP TABLE #DedupedWithDates;

        SELECT a.*,
               ORDATE.date_key_pk AS ORDATE_key,
               ORPDAT.date_key_pk AS ORPDAT_key,
               ORDDAT.date_key_pk AS ORDDAT_key,
               ORAPDT.date_key_pk AS ORAPDT_key,
               ORADDT.date_key_pk AS ORADDT_key,
               ORUPDD.date_key_pk AS ORUPDD_key,
               ORLCDT.date_key_pk AS ORLCDT_key,
               ORECDT.date_key_pk AS ORECDT_key,
               ORSHDT.date_key_pk AS ORSHDT_key
        INTO #DedupedWithDates
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY ORODR
                       ORDER BY loadDate DESC, recordNumber DESC
                   ) AS rn
            FROM data_central_lh.dbo.ibmi_incr_cd_order_bronze_new
        ) a
        LEFT JOIN gold.dim_date ORDATE ON a.ORDATE = ORDATE.date_ordinal
        LEFT JOIN gold.dim_date ORPDAT ON a.ORPDAT = ORPDAT.date_ordinal
        LEFT JOIN gold.dim_date ORDDAT ON a.ORDDAT = ORDDAT.date_ordinal
        LEFT JOIN gold.dim_date ORAPDT ON a.ORAPDT = ORAPDT.date_ordinal
        LEFT JOIN gold.dim_date ORADDT ON a.ORADDT = ORADDT.date_ordinal
        LEFT JOIN gold.dim_date ORUPDD ON a.ORUPDD = ORUPDD.date_ordinal
        LEFT JOIN gold.dim_date ORLCDT ON a.ORLCDT = ORLCDT.date_ordinal
        LEFT JOIN gold.dim_date ORECDT ON a.ORECDT = ORECDT.date_ordinal
        LEFT JOIN gold.dim_date ORSHDT ON a.ORSHDT = ORSHDT.date_ordinal
        WHERE a.rn = 1;

        IF OBJECT_ID('tempdb..#CdOrdersToDelete') IS NOT NULL DROP TABLE #CdOrdersToDelete;

        SELECT DISTINCT TRIM(ORODR) AS cd_order_load_number
        INTO #CdOrdersToDelete
        FROM #DedupedWithDates
        WHERE ORODR IS NOT NULL;

        DELETE TGT
        FROM silver.ibmi_incr_cd_order_new TGT
        JOIN #CdOrdersToDelete D
          ON TGT.cd_order_load_number = D.cd_order_load_number;

        INSERT INTO silver.ibmi_incr_cd_order_new (
            cd_order_origin_area_code,
            cd_order_load_number,
            cd_order_status_code,
            cd_order_date,
            cd_order_time,
            cd_order_customer_code,
            cd_order_consignee_code,
            cd_order_billto_code,
            cd_order_loadat_code,
            cd_order_early_pickup_date,
            cd_order_early_pickup_time,
            is_pickup_required,
            cd_order_early_delivery_date,
            cd_order_early_delivery_time,
            is_delivery_required,
            cd_order_commodity_code,
            cd_order_commodity_description,
            cd_order_creation_initials,
            cd_order_customer_phone_area_code,
            cd_order_customer_phone_number,
            cd_order_consignee_phone_area_code,
            cd_order_consignee_phone_number,
            cd_order_load_weight,
            cd_order_pallet_count,
            cd_order_origin_city_code,
            cd_order_origin_state,
            cd_order_origin_bea_code,
            cd_order_origin_gu_code,
            cd_order_origin_city_short_name,
            cd_order_destination_city_code,
            cd_order_destination_state,
            cd_order_destination_bea_code,
            cd_order_destination_gu_code,
            cd_order_destination_city_short_name,
            cd_order_miles_billable,
            cd_order_load_type,
            cd_order_stop_count,
            cd_order_dispatch_count,
            cd_order_preload_trailer,
            cd_order_revenue_estimation,
            cd_order_new_origin_area_code,
            cd_order_destination_area_code,
            cd_order_bill_of_lading,
            cd_order_purchase_order,
            cd_order_pick_up_code,
            cd_order_piece_count,
            cd_order_collection_method_code,
            cd_order_load_volume,
            cd_order_message,
            cd_order_late_pickup_date,
            cd_order_late_pickup_time,
            cd_order_late_delivery_date,
            cd_order_late_delivery_time,
            cd_order_required_pallet_count,
            cd_order_ship_date,
            cd_order_ship_time,
            cd_order_temp_high,
            cd_order_temp_low,
            cd_order_last_update_date,
            cd_order_last_update_time,
            cd_order_last_update_initials,
            cd_order_company_code,
            cd_order_division_code,
            cd_order_lane_code,
            cd_order_seal_code,
            cd_order_service_failure_code,
            cd_order_driver_commit_flag,
            is_edi_load,
            is_edi_stats_complete,
            is_driver_loaded,
            is_driver_unloaded,
            is_delivery_receipt_signed,
            cd_order_delivery_receipt_req,
            cd_order_edi_message_billing_flag,
            is_load_just_in_time,
            cd_order_edi_billing_code,
            is_edi_inbound_or_outbound,
            cd_order_current_city_code,
            cd_order_current_state,
            cd_order_loaded_call_date,
            cd_order_empty_call_date,
            cd_order_trailer_length,
            cd_order_trailer_height,
            has_permit,
            has_permit_complete,
            cd_order_latitude,
            cd_order_longitude,
            is_tentitive_load,
            cd_order_hours_under_dispatch,
            cd_order_origin_zone_code,
            cd_order_origin_region_code,
            cd_order_destination_zone_code,
            cd_order_destination_region_code,
            is_to_be_rated,
            has_new_gu_code,
            is_exclude_from_model,
            cd_order_carry_over_flag,
            cd_order_truck_type_requirement_code,
            cd_order_delivery_code
        )
        SELECT 
            TRIM(SRC.ORARA),
            TRIM(SRC.ORODR),
            TRIM(SRC.ORSTAT),
            SRC.ORDATE_key,

            CASE WHEN SRC.ORTIME LIKE '%[^0-9]%' THEN NULL
                 WHEN CONVERT(INT, SRC.ORTIME) <= 2359
                  AND LEN(TRIM(SRC.ORTIME)) = 4
                  AND CONVERT(INT, RIGHT(TRIM(SRC.ORTIME), 2)) < 60
                 THEN CONVERT(TIME(0), CONCAT(LEFT(SRC.ORTIME, 2), ':', RIGHT(SRC.ORTIME, 2)))
                 ELSE NULL END,

            TRIM(SRC.ORCUST),
            TRIM(SRC.ORCONS),
            TRIM(SRC.ORBILL),
            TRIM(SRC.ORLDAT),
            SRC.ORPDAT_key,

            CASE WHEN SRC.ORPTIM LIKE '%[^0-9]%' THEN NULL
                 WHEN CONVERT(INT, SRC.ORPTIM) <= 2359
                  AND LEN(TRIM(SRC.ORPTIM)) = 4
                  AND CONVERT(INT, RIGHT(TRIM(SRC.ORPTIM), 2)) < 60
                 THEN CONVERT(TIME(0), CONCAT(LEFT(SRC.ORPTIM, 2), ':', RIGHT(SRC.ORPTIM, 2)))
                 ELSE NULL END,

            CASE TRIM(SRC.ORRPIK) WHEN 'Y' THEN 'TRUE' WHEN 'N' THEN 'FALSE' ELSE 'unknown' END,
            SRC.ORDDAT_key,

            CASE WHEN SRC.ORDTIM LIKE '%[^0-9]%' THEN NULL
                 WHEN CONVERT(INT, SRC.ORDTIM) <= 2359
                  AND LEN(TRIM(SRC.ORDTIM)) = 4
                  AND CONVERT(INT, RIGHT(TRIM(SRC.ORDTIM), 2)) < 60
                 THEN CONVERT(TIME(0), CONCAT(LEFT(SRC.ORDTIM, 2), ':', RIGHT(SRC.ORDTIM, 2)))
                 ELSE NULL END,

            CASE TRIM(SRC.ORRDEL) WHEN 'Y' THEN 'TRUE' WHEN 'N' THEN 'FALSE' ELSE 'unknown' END,
            TRIM(SRC.ORCOMC),
            TRIM(SRC.ORCOMD),
            TRIM(SRC.ORINIT),
            CONVERT(VARCHAR, SRC.ORCAC),
            CONVERT(VARCHAR, SRC.ORCPHN),
            CONVERT(VARCHAR, SRC.ORRAC),
            CONVERT(VARCHAR, SRC.ORRPHN),
            SRC.ORWGT,
            TRIM(SRC.ORPLLT),
            TRIM(SRC.OROCTY),
            TRIM(SRC.OROST),
            SRC.OROBEA,
            TRIM(SRC.OROGU),
            TRIM(SRC.OROSNM),
            TRIM(SRC.ORDCTY),
            TRIM(SRC.ORDST),
            SRC.ORDBEA,
            TRIM(SRC.ORDGU),
            TRIM(SRC.ORDSNM),
            SRC.ORMILE,
            TRIM(SRC.ORRST),
            TRIM(SRC.ORSTP),
            TRIM(SRC.OR_DSP),
            TRIM(SRC.ORTRLR),
            SRC.ORESTR,
            TRIM(SRC.ORNWPK),
            TRIM(SRC.ORINAR),
            TRIM(SRC.ORCSH),
            TRIM(SRC.ORCNS),
            TRIM(SRC.ORORBY),
            TRIM(SRC.ORPIEC),
            TRIM(SRC.ORPORC),
            TRIM(SRC.ORCUBE),
            TRIM(SRC.ORSPEC),
            SRC.ORAPDT_key,

            CASE WHEN SRC.ORAPTM LIKE '%[^0-9]%' THEN NULL
                 WHEN CONVERT(INT, SRC.ORAPTM) <= 2359
                  AND LEN(TRIM(SRC.ORAPTM)) = 4
                  AND CONVERT(INT, RIGHT(TRIM(SRC.ORAPTM), 2)) < 60
                 THEN CONVERT(TIME(0), CONCAT(LEFT(SRC.ORAPTM, 2), ':', RIGHT(SRC.ORAPTM, 2)))
                 ELSE NULL END,

            SRC.ORADDT_key,

            CASE WHEN SRC.ORADTM LIKE '%[^0-9]%' THEN NULL
                 WHEN CONVERT(INT, SRC.ORADTM) <= 2359
                  AND LEN(TRIM(SRC.ORADTM)) = 4
                  AND CONVERT(INT, RIGHT(TRIM(SRC.ORADTM), 2)) < 60
                 THEN CONVERT(TIME(0), CONCAT(LEFT(SRC.ORADTM, 2), ':', RIGHT(SRC.ORADTM, 2)))
                 ELSE NULL END,

            SRC.ORPREQ,
            SRC.ORSHDT_key,

            CASE WHEN SRC.ORSHTM LIKE '%[^0-9]%' THEN NULL
                 WHEN CONVERT(INT, SRC.ORSHTM) <= 2359
                  AND LEN(TRIM(SRC.ORSHTM)) = 4
                  AND CONVERT(INT, RIGHT(TRIM(SRC.ORSHTM), 2)) < 60
                 THEN CONVERT(TIME(0), CONCAT(LEFT(SRC.ORSHTM, 2), ':', RIGHT(SRC.ORSHTM, 2)))
                 ELSE NULL END,

            SRC.ORTMPH,
            SRC.ORTMPL,
            SRC.ORUPDD_key,

            CASE WHEN SRC.ORUPDT LIKE '%[^0-9]%' THEN NULL
                 WHEN CONVERT(INT, SRC.ORUPDT) <= 2359
                  AND LEN(TRIM(SRC.ORUPDT)) = 4
                  AND CONVERT(INT, RIGHT(TRIM(SRC.ORUPDT), 2)) < 60
                 THEN CONVERT(TIME(0), CONCAT(LEFT(SRC.ORUPDT, 2), ':', RIGHT(SRC.ORUPDT, 2)))
                 ELSE NULL END,

            TRIM(SRC.ORUPDI),
            TRIM(SRC.ORCO),
            TRIM(SRC.ORDV),
            TRIM(SRC.ORTM),
            TRIM(SRC.ORSEL1),
            TRIM(SRC.ORSERV),
            TRIM(SRC.ORCMTM),
            TRIM(SRC.OREDI),
            TRIM(SRC.OREDIC),
            TRIM(SRC.ORDLD),
            TRIM(SRC.ORDULD),
            TRIM(SRC.ORSDR),
            TRIM(SRC.ORSDRR),
            TRIM(SRC.OREDMB),
            TRIM(SRC.ORJIT),
            TRIM(SRC.OREDFB),
            CASE TRIM(SRC.OREDIO) WHEN 'I' THEN 'INBOUND' WHEN 'O' THEN 'OUTBOUND' ELSE 'unknown' END,
            TRIM(SRC.ORCCTY),
            TRIM(SRC.ORCST),
            SRC.ORLCDT_key,
            SRC.ORECDT_key,
            SRC.ORLGT,
            SRC.ORHGT,
            TRIM(SRC.ORPMTF),
            TRIM(SRC.ORPCOM),
            SRC.ORLAT,
            SRC.ORLONG,
            TRIM(SRC.ORTEN),
            SRC.ORHRS,
            TRIM(SRC.OROZN),
            TRIM(SRC.ORORG),
            TRIM(SRC.ORDZN),
            TRIM(SRC.ORDRG),
            TRIM(SRC.ORTBRT),
            TRIM(SRC.ORNGU),
            TRIM(SRC.OREFM),
            TRIM(SRC.ORCARF),
            TRIM(SRC.ORUTYP),
            TRIM(SRC.ORFIL)
        FROM #DedupedWithDates SRC
        WHERE NOT EXISTS (
            SELECT 1
            FROM silver.ibmi_incr_cd_order_new TGT
            WHERE TGT.cd_order_load_number = TRIM(SRC.ORODR)
        );

        DROP TABLE #DedupedWithDates;
        DROP TABLE #CdOrdersToDelete;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('usp_ibmi_incr_cd_order_silver_new failed. %s', 16, 1, @ErrMsg) WITH NOWAIT;
    END CATCH
END;