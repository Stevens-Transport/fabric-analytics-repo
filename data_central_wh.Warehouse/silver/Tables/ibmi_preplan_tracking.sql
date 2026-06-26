CREATE TABLE [silver].[ibmi_preplan_tracking] (

	[preplan_tracking_load_number] varchar(8000) NULL, 
	[preplan_tracking_truck_number] varchar(8000) NULL, 
	[preplan_tracking_driver_seat_1] varchar(8000) NULL, 
	[preplan_tracking_driver_seat_2] varchar(8000) NULL, 
	[preplan_tracking_team_status_code] varchar(8000) NULL, 
	[preplan_tracking_dm] varchar(8000) NULL, 
	[preplan_tracking_dmol] varchar(8000) NULL, 
	[preplan_tracking_sent_date] date NULL, 
	[preplan_tracking_sent_time] time(6) NULL, 
	[preplan_tracking_sent_user_code] varchar(8000) NULL, 
	[preplan_tracking_response_date] date NULL, 
	[preplan_tracking_response_time] time(6) NULL, 
	[is_accepted] varchar(7) NOT NULL, 
	[preplan_tracking_cancel_date] date NULL, 
	[preplan_tracking_cancel_time] time(6) NULL, 
	[preplan_tracking_cancel_user_code] varchar(8000) NULL, 
	[is_canceled] varchar(5) NOT NULL, 
	[preplan_tracking_create_date] date NULL, 
	[preplan_tracking_create_time] time(6) NULL
);