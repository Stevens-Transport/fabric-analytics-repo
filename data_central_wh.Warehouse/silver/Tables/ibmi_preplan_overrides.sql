CREATE TABLE [silver].[ibmi_preplan_overrides] (

	[preplan_overrides_load_number] varchar(8000) NULL, 
	[preplan_overrides_dispatch] varchar(8000) NULL, 
	[preplan_overrides_planned_truck_number] varchar(8000) NULL, 
	[preplan_overrides_model_recommended_truck_number] varchar(8000) NULL, 
	[is_unplanned] varchar(5) NOT NULL, 
	[preplan_overrides_model_plan_code] varchar(8000) NULL, 
	[preplan_overrides_override_code] varchar(8000) NULL, 
	[preplan_overrides_override_description] varchar(8000) NULL, 
	[preplan_overrides_dispatch_datetime] datetime2(6) NULL, 
	[preplan_overrides_create_datetime] datetime2(6) NULL, 
	[preplan_overrides_model_recommended_at_dispatch] varchar(8000) NULL, 
	[preplan_overrides_model_plan_at_dispatch] varchar(8000) NULL, 
	[preplan_overrides_user_code] varchar(8000) NULL, 
	[preplan_overrides_area_code] varchar(8000) NULL
);