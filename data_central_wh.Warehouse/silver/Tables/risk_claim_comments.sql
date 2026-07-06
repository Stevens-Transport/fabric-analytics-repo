CREATE TABLE [silver].[risk_claim_comments] (

	[claim_comments_record_code] float NULL, 
	[claim_comments_involved_party_code] float NULL, 
	[claim_comments_comment_code] float NULL, 
	[claim_comments_comment] varchar(8000) NULL, 
	[claim_comments_comment_datetime] datetime2(6) NULL, 
	[claim_comments_create_datetime] datetime2(6) NULL, 
	[claim_comments_create_user_code] varchar(8000) NULL, 
	[claim_comments_last_updat_datetime] datetime2(6) NULL, 
	[claim_comments_last_update_user] varchar(8000) NULL, 
	[claim_comments_comment_type_code] float NULL
);