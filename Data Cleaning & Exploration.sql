
--Data Cleaning AND Exploration

--A.Data Cleaning
--1. Create a table named 'sba_naics_sector_codes_description' of desired fields from data set (data cleaning)

select 
	* 
into 
	sba_naics_sector_codes_description
from 

	(SELECT
			[NAICS_Industry_Description],
			iif([NAICS_Industry_Description] like '%–%', SUBSTRING([NAICS_Industry_Description], 8,2),'') as LookupCodes,
			--case when [NAICS_Industry_Description] like '%–%' then SUBSTRING([NAICS_Industry_Description], 8,2) end as When_LookUpCodes
			iif([NAICS_Industry_Description] like '%–%', ltrim( SUBSTRING([NAICS_Industry_Description], CHARINDEX( '–', [NAICS_Industry_Description]) +1, LEN([NAICS_Industry_Description]))),'') as sector
	  FROM 
			[PortfolioProjects].[dbo].[sba_industry_standards]
	  where 
			NAICS_Codes = '') as main

where 
	lookupCodes !='' ;

insert into
	sba_naics_sector_codes_description
values 
	('Sector 31-33 – Manufacturing' , 32, 'Manufacturing'),
	('Sector 31-33 – Manufacturing' , 33, 'Manufacturing'),
	('Sector 44-45 – Retail Trade' , 45, 'Retail Trade'),
	('Sector 48-49 – Transportation and Warehousing' , 49, 'Transportation and Warehousing');
	
select 
	* 
from 
	sba_naics_sector_codes_description;

update
	sba_naics_sector_codes_description
set 
	sector = 'Manufacturing'
where
	LookupCodes = 31;


 --B. Data Exploration 
--1.What is the summary of all approved ppp loans?

select 
	COUNT( LoanNumber) as Number_of_Approved,
	sum (InitialApprovalAmount) as Approved_Amount,
	AVG(InitialApprovalAmount) as Average_Loan_Size
from sba_public_data;

-- Number_of_Approved= 11,460,475
-- Approved_Amount = $793,828,505,984.661
-- Average_Loan_Size = 69,266.6321408721


--2 What is the yearly numbers and amount of loans that were approved?
select 
	year(DateApproved) as year_approved,
	COUNT( LoanNumber) as Number_of_Approved,
	sum (InitialApprovalAmount) as Approved_Amount,
	AVG(InitialApprovalAmount) as Average_Loan_Size
from 
	sba_public_data 
where
	year(DateApproved) = 2020 -- for year 2020 
group by
	year(DateApproved)

 union

select 
	year(DateApproved) as year_approved,
	COUNT( LoanNumber) as Number_of_Approved,
	sum (InitialApprovalAmount) as Approved_Amount,
	AVG(InitialApprovalAmount) as Average_Loan_Size
from 
	sba_public_data
where
	year(DateApproved) = 2021  -- for year 2021
group by
	year(DateApproved);



--3. Who are the top 15 originating lenders by loan count, total amount and average in 2021 and 2021?

select top 15
	originatingLender,
	COUNT( LoanNumber) as Number_of_Approved,
	sum (InitialApprovalAmount) as Approved_Amount,
	AVG(InitialApprovalAmount) as Average_Loan_Size
from 
	sba_public_data 
where
	YEAR(DateApproved) = 2021
group by 
	originatingLender
order by 
	Approved_Amount desc;

--4. who are the top 20 industries that recieved the ppp loans in 2021 and 2020?


; with High_loan_recieving_Sector as 
(
select top 20
	d.sector,
	COUNT( LoanNumber) as Number_of_Approved,
	sum (InitialApprovalAmount) as Approved_Amount,
	AVG(InitialApprovalAmount) as Average_Loan_Size
from  
	sba_public_data  p
	inner join sba_naics_sector_codes_description d
	on left(p.NAICSCode,2) = d.LookupCodes
where
	YEAR(DateApproved) = 2020
group by
	d.sector
)

select sector,
	Number_of_Approved, 
	Approved_Amount,
	Approved_Amount/ sum(Approved_Amount) over() *100  as percent_by_amount
into 
	#Industries_With_High_loan_Approval	
from
	High_loan_recieving_Sector
order by
	Approved_Amount desc;

Select 
	*
from
	#Industries_With_High_loan_Approval;

--5. How much of the ppp loans of 2021 have been fully forgiven and by what Percent?
		--Answer: for 2020 approved_amount= $519,496,939,809.756  and forgiven_amount =$ 502,654,270,136.273 making 96.75 % of loan forgiven

select 
	COUNT( LoanNumber) as Number_of_Approved,
	sum (CurrentApprovalAmount) as Current_Approved_Amount,
	sum (ForgivenessAmount) as Forgiven_Amount,
	AVG(CurrentApprovalAmount) as Average_Loan_Size,
	sum (ForgivenessAmount)/sum (CurrentApprovalAmount) *100 as Percent_forgiven

from  
	sba_public_data  p

where
	YEAR(DateApproved) = 2020
order by
	3 desc;


--6.What year and month have the highest approved ppp loan? 
select 
	YEAR(dateapproved) as year_approved,
	Month(dateapproved) as month_approved,
	COUNT( LoanNumber) as Number_of_Approved,
	sum (InitialApprovalAmount) as Total_Approved_Amount,
	avg (InitialApprovalAmount) as Approved_Amount

from  
	sba_public_data  p
group by
	YEAR(dateapproved),
	Month(dateapproved) 
order by
	4 desc; 


--7. Creating a view for visualization

drop view if exists ppp_main;
go 
Create view ppp_main as 

	select 
		d.sector,
		originatingLender, 
		BorrowerState,
		Race,
		Gender,
		Ethnicity,
		YEAR(dateapproved) as year_approved,
		Month(dateapproved) as month_approved,
		COUNT( LoanNumber) as Number_of_Approved,
		sum (CurrentApprovalAmount) as Current_Approved_Amount,
		AVG(CurrentApprovalAmount) as Current_Average_Loan_Size,
		sum(ForgivenessAmount) as Amount_forgiven,

		sum (InitialApprovalAmount) as Approved_Amount,
		AVG(InitialApprovalAmount) as Average_Loan_Size
	from  
		sba_public_data  p
		inner join sba_naics_sector_codes_description d
		on left(p.NAICSCode,2) = d.LookupCodes

	where
		YEAR(DateApproved) = 2020
	group by
		d.sector,
		originatingLender, 
		BorrowerState,
		Race,
		Gender,
		Ethnicity,
		YEAR(dateapproved),
		Month(dateapproved)
go
select top 10 * from ppp_main









