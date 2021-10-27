-- Changing the SalesDate from TEXT to DATE

ALTER TABLE nashville_housing
ALTER COLUMN "SaleDate" TYPE date
USING "SaleDate"::date;

------------------------------------------------------------------------------------------------------------------------

-- Populate PropertyAddress

with a as (
       select
       coalesce(a."PropertyAddress",b."PropertyAddress") as populated_address
from nashville_housing a
join nashville_housing b
on a."ParcelID" = b."ParcelID" and a."UniqueID " <> b."UniqueID "
where a."PropertyAddress" is null )


UPDATE nashville_housing
SET "PropertyAddress" = a.populated_address
from a
where "PropertyAddress"is null;

------------------------------------------------------------------------------------------------------------------------

-- Braking out PropertyAddress into individual columns (Address, City) - USING SUBSTRING

select "PropertyAddress",
       substring("PropertyAddress", 1, strpos("PropertyAddress",',') - 1) as Address,
       substring("PropertyAddress", strpos("PropertyAddress",',') + 1 ,length("PropertyAddress"))as town
from nashville_housing;

ALTER TABLE nashville_housing
ADD COLUMN property_address varchar(255),
ADD COLUMN property_town varchar(255);

UPDATE nashville_housing
SET property_address = substring("PropertyAddress", 1, strpos("PropertyAddress",',') - 1),
    property_town = substring("PropertyAddress", strpos("PropertyAddress",',') + 1 ,length("PropertyAddress"));


-- Braking out OwnerAddress into individual columns (Address, City, State) -USING SPLIT_PART

select "OwnerAddress",
       owner_address,
       owner_town,
       owner_state
from nashville_housing;

ALTER TABLE nashville_housing
ADD COLUMN owner_address varchar(255),
ADD COLUMN owner_town varchar(255),
ADD COLUMN owner_state varchar(255);

UPDATE nashville_housing
SET owner_address = split_part("OwnerAddress",',',1),
    owner_town = split_part("OwnerAddress",',',2),
    owner_state =  split_part("OwnerAddress",',',3);


------------------------------------------------------------------------------------------------------------------------

-- Replace Y and N in SoldAsVacant with Yes and No

UPDATE nashville_housing
SET "SoldAsVacant" = CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
            WHEN "SoldAsVacant" = 'N' THEN 'No'
            ElSE "SoldAsVacant"
            END;

------------------------------------------------------------------------------------------------------------------------

-- Finding and removing duplicates

with row_num_cte as (
select *,
       row_number() over (partition by
           "ParcelID",
           "property_address",
           "SalePrice",
           "SaleDate",
           "LegalReference"
           order by "UniqueID ") as row_num
from nashville_housing
)

DELETE
from nashville_housing
where "UniqueID " in (select "UniqueID " from row_num_cte where row_num > 1);


------------------------------------------------------------------------------------------------------------------------

-- Removing unused columns

ALTER TABLE nashville_housing
DROP COLUMN "PropertyAddress",
DROP COLUMN "OwnerAddress";

