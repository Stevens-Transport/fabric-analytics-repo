-- Auto Generated (Do not modify) 9BBFC7DDAA1C06F10B5F9F0DB4614D0779EB2B7C8C39E0BF944D5D2B403B9788





CREATE   VIEW [gold].[vw_fact_cargo_claim_details] AS

WITH claimcomments AS
(
SELECT 
    claim_comments_record_code, 
    STRING_AGG(TRIM(claim_comments_comment), ', ') AS comments
FROM silver.risk_claim_comments
GROUP BY claim_comments_record_code
)

SELECT
	  c1.claim_mast_record_code
	, c1.claim_mast_claim_number
	, c1.claim_mast_occurance_date
	, c1.claim_mast_occurance_datetime
	, c1.claim_mast_truck_number
	, d1.involved_drv_driver_code
	, d1.involved_drv_dm_code
	, p1.order_policy_load_number
	, p1.order_policy_dispatch
	, c2.comments

FROM
	silver.risk_claim_master c1
		LEFT OUTER JOIN silver.risk_order_policy p1
			ON c1.claim_mast_record_code = p1.order_policy_claim_record_code
		LEFT OUTER JOIN silver.risk_involved_driver d1
			ON c1.claim_mast_record_code = d1.involved_drv_claim_record_code
		LEFT OUTER JOIN claimcomments c2
			ON c1.claim_mast_record_code = c2.claim_comments_record_code
WHERE c1.claim_mast_type = 'OS&D Cargo Claim'