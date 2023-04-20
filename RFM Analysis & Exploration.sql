--1. inspecting data
select 
	*
from
sales_data_sample

--2. Checking distinct value (good for ploting/visualization)

select
	distinct STATUS
from sales_data_sample;	-- Nice to plot

select 
	distinct YEAR_ID 
from
	sales_data_sample;

select
	distinct PRODUCTLINE
from sales_data_sample; 

select 
	distinct COUNTRY 
from 
	sales_data_sample; 

select 
	distinct DEALSIZE 
from
	sales_data_sample; 

select 
	distinct TERRITORY
from
	sales_data_sample;

--3. Analysis
	-- 3a. What is the summary of the sales by ProductLine?
		--Insight: Classic cars is the best productline having the highest revenue and the leaast productline is trains across 3 years time frame
	
select 
	distinct PRODUCTLINE,
	Round(sum(SALES),3) as TotalSales, 
	COUNT(PRODUCTLINE) as QtySold, 
	Round(avg(SALES),3) as AverageTotalSales
from 
	sales_data_sample
group by
	PRODUCTLINE
order by
	TotalSales desc;

	-- 3b.  Which year had the highest sales?
			-- (deduction: the highest sales was made in year 2005)
select 
	YEAR_ID,
	sum(SALES)
from 
	sales_data_sample
group by 
	YEAR_ID
order by 
	2 desc;

	--3c. What is the total sales made from each productLine in each year?
select
	PRODUCTLINE,
	YEAR_ID, 
	sum(SALES) as Revenue 
from 
	sales_data_sample
group by 
	PRODUCTLINE, YEAR_ID
order by 
	3,1,2 desc;
	--3d. Amount made from each dealsize

select 
	DEALSIZE,
	sum(SALES) 
from 
	sales_data_sample
group by
	DEALSIZE
order by
	2 desc

-- 3c.i. what was the best month for sales in a specific year? and how much was earned that month
		--(deduction: for year 2003 the highest sales was made in November)

select
	MONTH_ID , 
	sum(SALES) as RevenueMade, 
	COUNT(ORDERNUMBER) as frequency
from
	sales_data_sample
where
	YEAR_ID = 2003 -- change year to see the rest
group by 
	MONTH_ID
order by 
	RevenueMade desc
 

-- 3c.ii. what productline sold most in the highest sales month-November?
		-- (deduction: More quantity of classic cars were sold and they made the highest revenue) 

select
	PRODUCTLINE , 
	COUNT(ORDERNUMBER) as QtySold, 
	SUM(SALES) as RevenueMade 
from 
	sales_data_sample
where 
	YEAR_ID= 2003 and MONTH_ID= 11
group by
	PRODUCTLINE
order by
	3 desc


--4a. RFM Analysis for the best customers
	--Recency--Last order date
	--Frequency-- Count of total orders
	--Monetary Value-- Total Amount spent 

select
	distinct CUSTOMERNAME 
from 
	sales_data_sample; -- gives unique 92 customers


drop table if exists #rfm
;
with rfm as (
				select distinct CUSTOMERNAME,
				COUNT(ORDERNUMBER) as frequency,
				SUM(sales) as MonetaryValue,
				AVG(sales) as AvgMonetaryValue, 
				max(convert(date, ORDERDATE)) as LastOrderDate,
				(select max(convert(date, ORDERDATE)) from sales_data_sample) as MaximumOrderDate,
				DATEDIFF(DD,max(convert(date, ORDERDATE)),(select max(convert(date, ORDERDATE)) from sales_data_sample)) as Recency
	from sales_data_sample
	group by CUSTOMERNAME
			),

	rfm_calc as
			(
				select
					r.* , 
					NTILE(4) over(order by Recency desc) as rfmRecency,
					NTILE(4) over(order by frequency ) as rfmFrequency,
					NTILE(4) over(order by MonetaryValue) as rfmMonetaryValue 
				from
					rfm as r
			)

select 
	c.* ,
	rfmRecency + rfmFrequency + rfmMonetaryValue as rfm_cell,
	cast(rfmRecency as varchar) + cast(rfmFrequency as varchar) + cast(rfmMonetaryValue as varchar) as rfm_cell_string
into
	#rfm
from 
	rfm_calc as c;

select 
	CUSTOMERNAME, 
	rfmRecency, 
	rfmFrequency,
	rfmMonetaryValue,
	case 
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers' --lost customers
		when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away, cannot lose' --Big spenders who have not purchased lately) slipping away
		when rfm_cell_string in (311,411,331) then 'new customers'
		when rfm_cell_string in (222,223,233,322) then 'potential churners'
		when rfm_cell_string in (323,333,321,422,332,432) then 'Active' -- (customers who buy often and recently, but at low points)
		when rfm_cell_string in (433,434,443,444) then 'Loyal'
		end rfm_segment
from #rfm

--4b. what products are mostly sold together?
 --select ORDERNUMBER from sales_data_sample


select
	distinct ORDERNUMBER,
	STUFF(
			(select 
				',' +PRODUCTCODE 
			from 
				sales_data_sample as p
			where
				ORDERNUMBER in
					(
					select
						ORDERNUMBER 
					from 
						(
							select 
								ORDERNUMBER,
								COUNT(*) as RowNum
							from
								sales_data_sample
							where 
								STATUS = 'shipped'
							group by 
								ORDERNUMBER
						) as m
					where RowNum =2
					)
				and p.ORDERNUMBER= s.ORDERNUMBER
			for xml path('')
			),
			1,
			1,
			''
		) as ProductCodes
from 
	sales_data_sample s
order by
	2 Desc



