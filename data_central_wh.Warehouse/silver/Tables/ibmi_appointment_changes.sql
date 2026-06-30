CREATE TABLE [silver].[ibmi_appointment_changes] (

	[appt_chgs_load_number] varchar(8000) NULL, 
	[appt_chgs_stop_number] smallint NULL, 
	[appt_chgs_type] varchar(8) NOT NULL, 
	[appt_chgs_original_appointment_datetime] datetime2(6) NULL, 
	[appt_chgs_changed_appointment_datetime] datetime2(6) NULL, 
	[appt_chgs_appointment_change_user_code] varchar(8000) NULL, 
	[appt_chgs_change_datetime] datetime2(6) NULL
);