CREATE TABLE [silver].[ibmi_tlb_negotiations] (

	[tlb_negotiations_status_code] varchar(8000) NULL, 
	[tlb_negotiations_company_number] varchar(8000) NULL, 
	[tlb_negotiations_sequence_number] decimal(34,6) NULL, 
	[tlb_negotiations_owner_code] varchar(8000) NULL, 
	[tlb_negotiations_load_number] varchar(8000) NULL, 
	[tlb_negotiations_flat_amount] decimal(34,6) NULL, 
	[tlb_negotiations_contact_phone_number] int NULL, 
	[tlb_negotiations_contact_name] varchar(8000) NULL, 
	[tlb_negotiations_result_code] varchar(8000) NULL, 
	[tlb_negotiations_negotiation_date] date NULL, 
	[tlb_negotiations_negotiation_time] time(0) NULL, 
	[tlb_negotiations_negotiation_user_code] varchar(8000) NULL
);