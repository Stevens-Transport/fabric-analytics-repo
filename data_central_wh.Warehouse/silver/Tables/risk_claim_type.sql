CREATE TABLE [silver].[risk_claim_type] (

	[claim_type_code] float NULL, 
	[claim_type_description] varchar(8000) NULL, 
	[claim_type_create_datetime] datetime2(6) NULL, 
	[claim_type_create_user_code] varchar(8000) NULL, 
	[claim_type_last_updated_datetime] datetime2(6) NULL, 
	[claim_type_last_updated_user_code] varchar(8000) NULL, 
	[is_active] varchar(5) NOT NULL
);