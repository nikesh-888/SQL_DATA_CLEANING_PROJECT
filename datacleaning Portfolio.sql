SELECT * FROM dataprotfolio.housingdata;

-- Standardize saledate column
-- In MySQL, the STR_TO_DATE() function is used to convert a string representation of a date and/or time into a MySQL date and/or time value. 
-- It's particularly useful when you have date or time information stored as strings in your database, and you want to convert them to the MySQL DATE, TIME, or DATETIME data types.
select SaleDate, str_to_date('April 9, 2013','%M %e, %Y') as date1 FROM dataprotfolio.housingdata;

update dataprotfolio.housingdata
set SaleDate=str_to_date('April 9, 2013','%M %e, %Y');
 
 select saleDate from housingdata;
 
 alter table housingdata
 add column saleDateconvert date;
 
 update housingdata
 set saleDateconvert =str_to_date('April 9, 2013','%M %e, %Y');
 
 -- Populating property Address
 
 SELECT * from dataprotfolio.housingdata
 where PropertyAddress is null;
 
 -- since the records are empty we are updating those empty string with "NUll" so we can access the values
 UPDATE dataprotfolio.housingdata
SET PropertyAddress = NULL
WHERE PropertyAddress = '';

-- the query provide all the null values
select PropertyAddress from housingdata where PropertyAddress is null;

-- here we are updating the null values by joining.
-- coalesce() it is used to fill the null values with provided values.
select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,coalesce(a.PropertyAddress,b.PropertyAddress) 
from housingdata a join
housingdata b on 
a.ParcelID=b.ParcelID and 
a.UniqueID<>b.UniqueID
where a.PropertyAddress is null;


-- updating the column records with null values.
UPDATE housingdata a
JOIN housingdata b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

select * from housingdata where PropertyAddress is not null;

-- breaking down the address into three individual columns
-- to separate the column we need to use substring where define the char length 

select PropertyAddress from housingdata;

-- The INSTR() function in MySQL is used to find the position of the first occurrence of a substring within a string. 
-- The function returns the position of the substring if found, and 0 if the substring is not present in the string.

select substring(PropertyAddress,1,instr(PropertyAddress,',')-1 ) as Address,
substring(PropertyAddress,instr(PropertyAddress,',')+1) as Address
from housingdata;

-- altering and updating the columns

alter table housingdata
 add column PropertysplitAddress nvarchar(255);
 
 update housingdata
 set PropertysplitAddress =substring(PropertyAddress,1,instr(PropertyAddress,',')-1 );
 
 alter table housingdata
 add column Propertysplitcity nvarchar(255);
 
 update housingdata
 set Propertysplitcity =substring(PropertyAddress,instr(PropertyAddress,',')+1);
 
 -- separinting the column into three column using substring_index()
 -- The SUBSTRING_INDEX() function in MySQL is used to extract a substring from a string before or after a specified delimiter. 
 -- This function is particularly useful when working with strings that are delimited by a specific character or sequence of characters.
 
 select OwnerAddress from housingdata;
 SELECT
  OwnerAddress,
  TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)) AS Address,
  TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)) AS City,
  TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS State
FROM housingdata;

-- creating the three new columns
alter table housingdata
 add column ownersplitAddress nvarchar(255);
 
 -- updating the reocrds in created columns
 update housingdata
 set ownersplitAddress =TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));
 
 alter table housingdata
 add column ownersplitcity nvarchar(255);
 
 update housingdata
 set ownersplitcity =TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1));
  
 alter table housingdata
 add column ownersplitstate nvarchar(255);
 
 update housingdata
 set ownersplitstate =TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));
 
 select * from housingdata;
 
 -- changing Y to Yes and N to NO
 
 select distinct(SoldAsVacant),count(SoldAsVacant) from housingdata
 group by 1 order by 2;
 
 select SoldAsVacant,
 case 
     when SoldAsVacant= "N" then "No"
     when SoldAsVacant="Y" then "Yes"
     else SoldAsVacant
     end
 from housingdata;
 
update housingdata
set SoldAsVacant= case 
     when SoldAsVacant= "N" then "No"
     when SoldAsVacant="Y" then "Yes"
     else SoldAsVacant
 end;
 
 -- Remove Duplicates
 --  In MySQL, you can use the ROW_NUMBER() window function along with the PARTITION BY clause to assign row numbers within each partition, 
 -- helping to identify and remove duplicates
 
 select * from housingdata;
 with rowNumber as(
 select *,
 row_number() over(partition by 
					ParcelId,
                    PropertyAddress,
                    SaleDate,
                    SalePrice,
                    LegalReference
                    order by 
                    uniqueId) row_num
from housingdata
)

-- The cte table will give all the duplicated records due to cte we can't delete the duplicate record to delete it
-- we have to create a temporary table and delete the records from permanent table
select * from rowNumber where row_num>1;

-- creating the temporary table to permanently delete the duplicate records from the table

-- Create a temporary table with row numbers
CREATE TEMPORARY TABLE temp_table AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY ParcelId, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY uniqueId) AS row_num
  FROM housingdata
);

-- Delete duplicates from the original table
DELETE FROM housingdata
WHERE (ParcelId, PropertyAddress, SaleDate, SalePrice, LegalReference, uniqueId) IN (
  SELECT ParcelId, PropertyAddress, SaleDate, SalePrice, LegalReference, uniqueId
  FROM temp_table
  WHERE row_num > 1
);

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS temp_table;



-- Drop the unwanted columns from the table
select * from housingdata LIMIT 188;

Alter table  housingdata
drop column PropertyAddress,
drop column SaleDate,
drop column OwnerAddress,
drop column TaxDistrict ;

-- we succesfully deleted the unwanted columns
-- the purpose of the project is to make the data clean and make it useful which means standardize the data and clean the duplicates to make it useful

alter table housingdata
modify column UniqueID int,
modify column ParcelId nvarchar(255);


-- updating the column datatype

update housingdata
set SalePrice=replace(Saleprice,",","");

-- REGEXP '[^0-9]' returns all the numbers/numeric with special characters(%,@,#) other then 0-9
SELECT *
FROM housingdata
WHERE SalePrice REGEXP '[^0-9]';

Update housingdata
set SalePrice = replace(SalePrice,"$",'')
where SalePrice like "%$%";

alter table housingdata
modify column SalePrice bigint,
modify column LegalReference char(17),
modify column SoldAsVacant char(3);

-- due to some empty values in data remaining column data types are not able to specified.alter
-- if u can make any changes in column datatype proceed and update me  
select * from housingdata ; 


  
