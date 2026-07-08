CREATE TABLE [gold].[dim_driver_code_reference_table] (

	[history_code] varchar(8000) NULL, 
	[current_code] varchar(8000) NULL, 
	[history_create_date] varchar(8000) NULL, 
	[ssn] varchar(8000) NULL, 
	[current_create_date] varchar(8000) NULL, 
	[is_conflict] bit NULL
);