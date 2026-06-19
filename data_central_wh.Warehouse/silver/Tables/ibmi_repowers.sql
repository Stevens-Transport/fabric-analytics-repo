CREATE TABLE [silver].[ibmi_repowers] (

	[repowers_truck_number_1] varchar(8000) NULL, 
	[repowers_load_number_1] varchar(8000) NULL, 
	[repowers_dispatch_1] varchar(8000) NULL, 
	[repowers_truck_number_2] varchar(8000) NULL, 
	[repowers_load_number_2] varchar(8000) NULL, 
	[repowers_dispatch_2] varchar(8000) NULL, 
	[repowers_status] varchar(9) NOT NULL, 
	[repowers_status_datetime] datetime2(6) NULL, 
	[repowers_swap_user_code] varchar(8000) NULL, 
	[repowers_swap_location_code] varchar(8000) NULL, 
	[repowers_swap_stop_number] varchar(8000) NULL, 
	[repowers_swap_datetime] datetime2(6) NULL, 
	[repowers_next_location_code_post_swap_1] varchar(8000) NULL, 
	[repowers_next_location_code_post_swap_2] varchar(8000) NULL, 
	[repowers_swap_reason_code] varchar(8000) NULL, 
	[repowers_create_user_code] varchar(8000) NULL, 
	[repowers_create_datetime] datetime2(6) NULL, 
	[is_chargeable_to_driver] varchar(7) NOT NULL
);