-- Data Cleaninig and Cohort Retention Analysis
	
--1. Data inspecting
		---- Total Records = 541909
			--Total fields = 8
select
	* 
from 
	OnlineRetail

--2. Which rows in the 'CustomerID' field have null values
	--using the first CTE (Online_Retail),135080 records have no CustomerID and 406829 records have  CustomerID
		
;with Online_Retail as
	(
		select 
			*
		from
			OnlineRetail
		where
			not CustomerID is null
	),

--3. What is the number of records whose Quantity & UnitPrice fields aren't null. Answer: 397884 Records with Quantity and Unit Price
	Quantity_Unit_price as
	(
		select
			*
		from
			Online_Retail
		where
			Quantity >0 and UnitPrice>0
	),

--4. Checking for Duplicates records with 'ROW_NUMBER()' function
		-- 5215 duplicated rows present after filtering out the null 'CustomerID',with Quantity and UnitPrice fields with  zero values
	Dup_check as
	(
	
		select 
			*, 
			ROW_NUMBER() over (partition by InvoiceNo, StockCode, Quantity order by InvoiceNo) as Dup_flag
		from
			Quantity_Unit_price
	)
			
select
	* 
from 
	Dup_check
where
	Dup_flag >1;
 
--5.What is number of rows of unique rocords (cleaned data). Annswer: 392669 rows of unique records (present in temp. table #Online_Retail_cleaned )

select 
	*
into
	#Online_Retail_cleaned
 from 
	Dup_check
where 
	Dup_flag =1;


-- 6. Time-based Cohort Analysis on cleaned data (#Online_Retail_cleaned)
			--Parameters for creating a cohort:
				--i. Unique Identifier (CustomerID)
				--ii. Initial start date (first invoice date)
				--iii. Revenue data (quantity or Unit price)

select 
	* 
from
	#Online_Retail_cleaned;



--7. Creating Cohort for the first time a purchase was made
		--4338 records present in the #cohort
select 
	CustomerID,
	MIN( InvoiceDate) as First_purchase_date,
	DATEFROMPARTS(year(MIN( InvoiceDate)),MONTH(MIN( InvoiceDate)),1) as Cohort_date
into
	#cohort
from
	#Online_Retail_cleaned
group by
	CustomerID;

select
	* 
from 
	#cohort

--8. Creating the Cohort Index (an integer representing the number of months that has passed since a customer made the first purchased)

select mmm.* ,
		cohort_index = year_diff * 12 + month_diff + 1
	into #cohort_retention

from
	(
	select mm.*,
		year_diff= invoice_year - cohort_year,
		month_diff = invoice_month - cohort_month

		from 
		(
			select 
				rc.*,
				c.Cohort_date,
				YEAR(rc.InvoiceDate) as invoice_year,
				MONTH(rc.InvoiceDate) as invoice_month,
				YEAR( c.Cohort_date) as cohort_year,
				MONTH(c.Cohort_date) as cohort_month
			from 
				#Online_Retail_cleaned as rc 
			left join
				#cohort as c 
				on rc.CustomerID = c.CustomerID
			) as mm

		) as mmm;

select
	*
from
	#cohort_retention;

-- Grouping customers by Cohort Index
	-- Pivot the data to see how many customers returned in a given cohort month
	-- Pivot data to see the cohort table 
 
select 
	* 
into
	#cohort_pivot
from (

	select 
		distinct CustomerID,
		Cohort_date,
		cohort_index
	from
		#cohort_retention
	) as tbl 
pivot (
	count(CustomerID)
	for
		cohort_index in
			(
			[1],
			[2],
			[3],
			[4],
			[5], 
			[6],
			[7],
			[8],
			[9],
			[10],
			[11],
			[12],
			[13]
			)

	) as pivot_table;

select
	* 
from
	#cohort_pivot
order by
	Cohort_date;

select 
	1.0 * [1]/[1] * 100 as [1],
	1.0 * [2]/[1] * 100 as [2],
	1.0 * [3]/[1] * 100 as [3],
	1.0 * [4]/[1] * 100 as [4],
	1.0 * [5]/[1] * 100 as [5],
	1.0 * [6]/[1] * 100 as [6],
	1.0 * [7]/[1] * 100 as [7],
	1.0 * [8]/[1] * 100 as [8],
	1.0 * [9]/[1] * 100 as [9],
	1.0 * [10]/[1] * 100 as [10],
	1.0 * [11]/[1] * 100 as [11],
	1.0 * [12]/[1] * 100 as [12],
	1.0 * [13]/[1] * 100 as [13]

from
	#cohort_pivot
order by
	Cohort_date;






