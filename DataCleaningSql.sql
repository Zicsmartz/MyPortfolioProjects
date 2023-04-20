--Date Cleaning with SQL

--1. Converting and updating the SaleDate field which is in datetime to date format
select
	SaleDate, 
	CONVERT(date,SaleDate)
from
	NashvilleHouses;


update
	NashvilleHouses
set 
	SaleDate= convert(date, SaleDate); --OR

alter table
	nashVilleHouses
add
	SaleDateConverted date;

update 
	NashvilleHouses
set 
	SaleDateConverted= convert(date, SaleDate);

select
	SaleDateConverted
from
	NashvilleHouses;

--2. Filling up (Updating) the 'propertyAddress' field having null values with data (Using ISNULL function and JOIN)

select 
	*
from
	nashVilleHouses
where
	PropertyAddress is null
order by 
	ParcelID;

select
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
from 
	NashvilleHouses a 
join 
	NashvilleHouses b
on 
	a.ParcelID = b.ParcelID and
	a.[UniqueID] != b.[UniqueID]
where 
	a.PropertyAddress is null;

update a
set 
	PropertyAddress= ISNULL(a.PropertyAddress,b.PropertyAddress)
from 
	NashvilleHouses a
join 
	NashvilleHouses b
on 
	a.ParcelID = b.ParcelID and
	a.[UniqueID] != b.[UniqueID]
where
	a.PropertyAddress is null;


--3 breaking out 'PropertyAddress' and 'OwnerAddress' field into individual columns (Address, city, state)
	--3a. Using Substring Function (Method 1)
select 
	PropertyAddress 
	from NashvilleHouses;


select
	SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1 ) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 ,LEN(PropertyAddress)) as Address
from 
	NashvilleHouses;

alter table 
	nashVilleHouses
add
	PropertySplitAddress Nvarchar(255);

alter table
	nashVilleHouses
add 
	PropertySplitCity Nvarchar(255);

update 
	NashvilleHouses
set
	PropertySplitAddress=SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1 );

update
	NashvilleHouses
set
	PropertySplitCity= SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 ,LEN(PropertyAddress));

select
	PropertyAddress,
	PropertySplitAddress,
	PropertySplitCity 
from 
NashvilleHouses;

	--3b. Using Parsename Function (Method 2)-This function works with period

select 
	OwnerAddress
from
	NashvilleHouses;

select
	OwnerAddress,
	parsename(REPLACE(OwnerAddress,',','.'),3) ,
	parsename(REPLACE(OwnerAddress,',','.'),2),
	parsename(REPLACE(OwnerAddress,',','.'),1) 
from 
	NashvilleHouses;

alter table 
	nashVilleHouses
add 
	OwnerSplitAddress nvarchar(255);

alter table
	nashVilleHouses
add 
	OwnerSplitCity nvarchar(255);

alter table 
	nashVilleHouses
add 
	OwnerSplitState nvarchar(255);

update 
	nashVilleHouses
set
	OwnerSplitAddress = parsename(REPLACE(OwnerAddress,',','.'),3);

update 
	nashVilleHouses
set
	OwnerSplitCity = parsename(REPLACE(OwnerAddress,',','.'),2);

update
	nashVilleHouses
set
	OwnerSplitState= parsename(REPLACE(OwnerAddress,',','.'),1);


select
	OwnerSplitAddress,
	OwnerSplitCity,
	OwnerSplitState
from 
	nashVilleHouses;

--4.Replacing the 'N' with 'No' and 'Y' with 'Yes' in  'SoldAsVacant' Columnn

select
	distinct(SoldAsVacant),
	COUNT(SoldAsVacant)
from 
	NashvilleHouses
group by 
	SoldAsVacant 
order by 
	2;


select
	SoldAsVacant, 
	case 
		when SoldAsVacant ='Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant end
from
	NashvilleHouses;


update 
	nashVilleHousing
set 
	SoldAsVacant = case 
						when SoldAsVacant ='Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant end
from 
	nashVilleHousing;


--5. Removing Duplicates using the 'ROW_NUMBER' or 'RANK' Functions (windows functions)
		-- 5a. WITH Table (CTE)
select
	*
from
	nashVilleHousing;

with RowNumCTE 
	as (

		select 
			*, 
			ROW_NUMBER() over(partition by ParcelID, propertyAddress, SalePrice,LegalReference order by uniqueID ) as RowNum

		from 
			NashvilleHouses
		) 

Select 
	*
from 
	RowNumCTE
where
	RowNum >1;
Delete from
	RowNumCTE
where
	RowNum >1;

	--5b Using Tem Table 

select
	*, 
	ROW_NUMBER() over(partition by ParcelID, propertyAddress, SalePrice,LegalReference order by uniqueID ) as RowNum
into 
	#DuplicateValues
from
	NashvilleHouses;


Select 
	* 
from
	#DuplicateValues
where 
	RowNum >1;

Delete from 
	#DuplicateValues
where 
	RowNum >1;

--6. Deleting unused columns from the data


select
	*
from 
	nashVilleHousing;

alter table
	nashVilleHousing
drop column
	propertyAddress, OwnerAddress, TaxDistrict


alter table
	nashVilleHousing
drop column
	SaleDate




