/* 
Cleaning Data with SQL Queries
*/

select * 
from nashvillehousing;
-------------------------------------------------------------------------------

-- Standardize date format

SELECT SaleDate, STR_TO_DATE(SaleDate, '%M %e, %Y') AS ConvertedSaleDate
FROM NashvilleHousing;

update nashvillehousing
set saledate = STR_TO_DATE(SaleDate, '%M %e, %Y');
-------------------------------------------------------------------------------

-- Populate Property Address Data (Using Self Join)

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
       COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress) AS new1
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress = '';

UPDATE nashvillehousing a
JOIN nashvillehousing b 
	ON a.ParcelID = b.ParcelID 
	AND a.UniqueID <> b.UniqueID
SET a.propertyaddress = COALESCE(NULLIF(a.propertyaddress, ''), b.propertyaddress)
WHERE a.propertyaddress = '';
-------------------------------------------------------------------------------

-- Breaking out Address Into Individual Columns (Address, City, State)

select PropertyAddress
from nashvillehousing;

SELECT 
       SUBSTRING(propertyaddress, 1, LOCATE(',', propertyaddress) - 1) as address_before_comma,
       SUBSTRING(propertyaddress, LOCATE(',', propertyaddress) + 1) as address_after_comma
FROM nashvillehousing;


-- Adding New splitted columns
alter table nashvillehousing
add PropertySplitAddress nvarchar(255);

update nashvillehousing
set PropertySplitAddress = SUBSTRING(propertyaddress, 1, LOCATE(',', propertyaddress) - 1);

alter table nashvillehousing
add PropertySplitCity varchar(255);

update nashvillehousing
set PropertySplitCity = SUBSTRING(propertyaddress, LOCATE(',', propertyaddress) + 1);

select *
from nashvillehousing;
-------------------------------------------------------------------------------

select OwnerAddress
from nashvillehousing;

SELECT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 1), ',', -1) AS street,
    SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1) AS city,
    SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 3), ',', -1) AS state
FROM nashvillehousing;


alter table nashvillehousing
add OwnerAddressStreet varchar(255);

update nashvillehousing
set OwnerAddressStreet = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 1), ',', -1);

alter table nashvillehousing
add OwnerAddressCity varchar(255);

update nashvillehousing
set OwnerAddressCity = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1);

alter table nashvillehousing
add OwnerAddressState varchar(255);

update nashvillehousing
set OwnerAddressState = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 3), ',', -1);
-------------------------------------------------------------------------------

-- Change Y And N to Yes and No in 'Sold as vacant' field

select distinct(SoldAsVacant), count(SoldAsVacant) as count1
from nashvillehousing
group by SoldAsVacant
order by count1 desc;

-- Using CASE statement
select SoldAsVacant,
case 
	when SoldAsVacant = 'Y' then 'Yes'
    when SoldAsVacant = 'N' then 'No'
    else SoldAsVacant
End as New_SoldAsVacant
from nashvillehousing;

update nashvillehousing
set soldasvacant = case 
	when SoldAsVacant = 'Y' then 'Yes'
    when SoldAsVacant = 'N' then 'No'
    else SoldAsVacant
End;
-------------------------------------------------------------------------------

-- Removing Duplicates

WITH DuplicateCTE AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
           ORDER BY UniqueID
         ) AS row_num
  FROM nashvillehousing
)
SELECT *
FROM DuplicateCTE
WHERE row_num > 1;

WITH DuplicateCTE AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
           ORDER BY UniqueID
         ) AS row_num
  FROM nashvillehousing
)
DELETE t
FROM nashvillehousing t
JOIN DuplicateCTE d 
	ON t.UniqueID = d.UniqueID
where d.row_num > 1;
-------------------------------------------------------------------------------

-- Deleting Columns

select *
from nashvillehousing;

ALTER TABLE nashvillehousing
DROP COLUMN LandUse,
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict;

