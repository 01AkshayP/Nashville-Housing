-- Cleaning Nashville Housing Data in SQL

SELECT *
FROM ..NashvilleHousing


-- 1. Standardize Date Format
-- Remove Time Stamp from Date as it serves no purpose

Select SaleDate, CONVERT(Date, SaleDate)
From ..NashvilleHousing

Update NashvilleHousing
Set SaleDate = Convert(Date,SaleDate)


-- 2. Populate Missing Property Addresses
Select *
From housingData.dbo.NashvilleHousing
Where PropertyAddress is NULL


Select *
From housingData.dbo.NashvilleHousing
Order BY ParcelID

-- Using ParcelID to populate Missing PropertyAddress

SELECT a.parcelID, a.PropertyAddress, b.parcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ..NashvilleHousing a
JOIN ..NashvilleHousing b
    ON a.PARCELID = b.PARCELID
    AND a.UNIQUEID <> b. UNIQUEID
WHERE a.PropertyAddress is NULL
-- Updating Missing Addresses in PropertyAddress Column
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ..NashvilleHousing a
JOIN ..NashvilleHousing b
    ON a.PARCELID = b.PARCELID
    AND a.UNIQUEID <> b. UNIQUEID

-- 3. Breaking Property Address into Individual Columns (Address, City)
Select PropertyAddress
FROM ..NashvilleHousing
-- Split The Address into seperate columns where there is a comma using Substring
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM ..NashvilleHousing 

--Adding New Columns for Address and City to Table
ALTER TABLE NashvilleHousing
Add PropertySplitAddress NVARCHAR(225);

ALTER TABLE NashvilleHousing
Add PropertySplitCity NVARCHAR(225);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1 )

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- 4. Spliting Owner Address into Individual Columns (Address, City, State)
SELECT n.OwnerAddress
FROM ..NashvilleHousing n

--Using Parsename to split Address into seperate Columns by Replacing commas with periods
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) AS Addres
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) AS City
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) As State
FROM ..NashvilleHousing 

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress NVARCHAR(225);
ALTER TABLE NashvilleHousing
Add OwnerSplitCity NVARCHAR(225);
ALTER TABLE NashvilleHousing
Add OwnerSplitState NVARCHAR(225);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


-- 5. Updating Format in "Sold as Vacant" column (Changing Y and N to Yes and No)
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From ..NashvilleHousing
Group By SoldAsVacant
Order by 2 DESC


Select SoldAsVacant
,   CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
        WHEN SoldAsVacant = 'N' THEN 'NO'
        ELSE SoldAsVacant
    END

From ..NashvilleHousing

-- Updating "SoldAsVacant" Column
UPDATE NashvilleHousing
SET SoldAsVacant =  CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
                    WHEN SoldAsVacant = 'N' THEN 'NO'
                    ELSE SoldAsVacant
                    END



-- 6. Removing Duplicates
-- Finding All the Duplicates in the Table by Using Partition to count rows that have exact same information
WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID,
                    PropertyAddress,
                    SalePrice,
                    SaleDate,
                    LegalReference
                    ORDER BY 
                        UniqueID
    ) row_num
FROM ..NashvilleHousing
)
SELECT *
FROM RowNumCTE
Where row_num > 1
Order BY PropertyAddress

--Deleting Duplicate Rows Found
WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID,
                    PropertyAddress,
                    SalePrice,
                    SaleDate,
                    LegalReference
                    ORDER BY 
                        UniqueID
    ) row_num
FROM ..NashvilleHousing
)
Delete
FROM RowNumCTE
Where row_num > 1


-- 7. Deleting Old Columns that have been Replaced
SELECT *
FROM ..NashvilleHousing

ALTER TABLE ..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

