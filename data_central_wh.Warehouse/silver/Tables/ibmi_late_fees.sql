CREATE TABLE [silver].[ibmi_late_fees] (

	[late_fees_load_number] varchar(8000) NULL, 
	[late_fees_dispatch] varchar(8000) NULL, 
	[late_fees_truck_number] varchar(8000) NULL, 
	[late_fees_driver_seat_1] varchar(8000) NULL, 
	[late_fees_driver_seat_2] varchar(8000) NULL, 
	[late_fees_create_date] date NULL, 
	[late_fees_create_user_code] varchar(8000) NULL, 
	[late_fees_house_late] decimal(34,6) NULL, 
	[late_fees_reason_why] varchar(8000) NULL, 
	[late_fees_fee_description] varchar(8000) NULL, 
	[late_fees_reimbursment_flag] varchar(8000) NULL, 
	[late_fees_alternative] varchar(8000) NULL, 
	[late_fees_last_updated_date] date NULL, 
	[late_fees_last_updated_user_code] varchar(8000) NULL, 
	[is_verified] varchar(7) NOT NULL, 
	[late_fees_amount] decimal(34,6) NULL, 
	[late_fees_stop_number] decimal(34,6) NULL
);