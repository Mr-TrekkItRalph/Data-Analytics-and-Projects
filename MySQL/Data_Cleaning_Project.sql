-- Data Cleaning

SELECT *
FROM layoffs
;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns


-- In real world, you need to create a staging database or a duplicate so you won't be messing with the raw or original data and avoid making huge mistakes.

CREATE TABLE layoffs_staging
LIKE layoffs
;

SELECT *
FROM layoffs
;

INSERT layoffs_staging
SELECT *
FROM layoffs
;

SELECT *
FROM layoffs_staging
;

-- Removing Duplicates

SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`) AS row_num -- We created this so we can identify which has number 2 in the row_number. If there's a number 2 then it means it is a duplicate.
FROM layoffs_staging
;

WITH CTE_Duplicate AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)

SELECT *
FROM CTE_Duplicate
WHERE row_num > 1
;

SELECT *    		-- We just created this to view and confirm if the results are duplicates.
FROM layoffs_staging
WHERE company = 'Casper' OR company = 'Cazoo' OR company = 'Hibob' OR company = 'Wildlife Studios' OR company = 'Yahoo'
ORDER BY company
;

WITH CTE_Duplicate AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)

SELECT *
FROM CTE_Duplicate
WHERE company = 'Casper' OR company = 'Cazoo' OR company = 'Hibob' OR company = 'Wildlife Studios' OR company = 'Yahoo'
ORDER BY company
;

WITH CTE_Duplicate AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)

DELETE 		-- DELETE will not work in CTE since DELETE is like an UPDATE and it will only work on tables.
FROM CTE_Duplicate
WHERE row_num > 1
;

-- So we will create another table that includes the rows inside the CTE, so we can delete the duplicates.

CREATE TABLE `layoffs_staging2` (		-- This code came from 'Copy to Clipboard' and 'Create Statement' by right clicking on the Table.
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2
;

INSERT INTO layoffs_staging2 
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num  -- This came from inside the CTE where we use ROW_NUMBER() to find duplicates.
FROM layoffs_staging
;

SET SQL_SAFE_UPDATES = 0;    -- This disables the safe mode which prevents the update or delete on a table.
DELETE  -- We DELETE the duplicates that has row_num > 1 in the layoffs_staging2 table.
FROM layoffs_staging2
WHERE row_num > 1
;
SET SQL_SAFE_UPDATES = 1;    -- This enables the safe mode which prevents the update or delete on a table.

SELECT *
FROM layoffs_staging2
WHERE row_num > 1
;

-- Standardizing Data
-- It is finding issues on your data and fixing it.
-- Like Remove spaces using TRIM

SELECT *
FROM layoffs_staging2;

SELECT DISTINCT(TRIM(company)) -- This shows unique values and removing spaces before and after the word using TRIM().
FROM layoffs_staging2;

SELECT company, TRIM(company)
FROM layoffs_staging2;

SET SQL_SAFE_UPDATES = 0;		-- This disables the safe mode which prevents the update or delete on a table.
UPDATE layoffs_staging2			-- This will update the company column within the layoffs_staging2 table.
SET company = TRIM(company);

SELECT location  -- This checks if there are leading and trailing spaces in the column location.
FROM layoffs_staging2
WHERE location <> TRIM(location);

SELECT DISTINCT industry -- We use DISTINCT to show unique values.
FROM layoffs_staging2
ORDER BY 1;   -- Since we order it by 1st column.

SELECT *		-- This checks if there are other spellings on the industry besides Crypto
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2   -- This updates everything where 'CryptoCurrency' or 'Crypto Currency' to only 'Crypto'.
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)   -- This removes the character you specified in either LEADING OR TRAILING.
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2     -- This removes the dot in the end of the United States in Country Column.
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT *
FROM layoffs_staging2;

-- THE DATE Column Data Type must be changed since it is a 'text' and not a 'date'. You can check it by going to the table and go to the column on the list.

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')  -- This is a conversion of String to Date which is (Date and Time Function).
FROM layoffs_staging2;

UPDATE layoffs_staging2 				-- This updates the Date column to a date format.
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2 -- This is used to change the Data Type of a Column.
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;

-- NULL VALUES or BLANK VALUES
-- Should we make it all NULL or BLANK or Populate them. We are going to find out.

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL -- This is how we check for NULL Values.
AND percentage_laid_off IS NULL;    -- This result seems to have NULL for both column so it seems to be useless and needs to be removed.


-- We are checking all the company's where the industry column is blank or Null and we will try to populate them by checking if there are similar entries which has the same company and same location or same data.

SELECT *               
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';      		-- This means blank ''.

-- We are trying to check if there are other company named and same location as Airbnb so we can populate the blank or null values.

SELECT *
FROM layoffs_staging2
WHERE company =  'Airbnb' OR company = 'Juul' OR company = 'Carvana' OR company = "Bally's Interactive";

-- We're joining the table on itself using SELF JOIN to show on the first table those industry that are blank and null, and on the other are the one's which are not blank.

SELECT *       
FROM layoffs_staging2 table1
JOIN layoffs_staging2 table2
	ON table1.company = table2.company
    AND table1.location = table2.location
WHERE (table1.industry IS NULL OR table1.industry = '')
AND table2.industry IS NOT NULL;			-- IS NOT NULL means Not Null.


SELECT table1.industry, table2.industry
FROM layoffs_staging2 table1
JOIN layoffs_staging2 table2
	ON table1.company = table2.company
    AND table1.location = table2.location
WHERE (table1.industry IS NULL OR table1.industry = '')
AND table2.industry IS NOT NULL;			-- IS NOT NULL means Not Null.

UPDATE layoffs_staging2 table1  			-- This will populate the Null Values using the industry of those who have the same company and location.
JOIN layoffs_staging2 table2				-- This will not work since there are blank on the table1. It needs to be set to Null first and not blank to make this work.
	ON table1.company = table2.company
    AND table1.location = table2.location
SET table1.industry = table2.industry
WHERE (table1.industry IS NULL OR table1.industry = '')
AND table2.industry IS NOT NULL;

-- You can run this first to set those industries that are blank to Null.
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- We can run the select statement to check the joined table again.
SELECT table1.industry, table2.industry
FROM layoffs_staging2 table1
JOIN layoffs_staging2 table2
	ON table1.company = table2.company
    AND table1.location = table2.location
WHERE (table1.industry IS NULL OR table1.industry = '')
AND table2.industry IS NOT NULL;			-- IS NOT NULL means Not Null.

-- Then we can run this to update those Null to the industry with similar company and location.
UPDATE layoffs_staging2 table1  			
JOIN layoffs_staging2 table2				
	ON table1.company = table2.company
    AND table1.location = table2.location
SET table1.industry = table2.industry
WHERE table1.industry IS NULL
AND table2.industry IS NOT NULL;

-- We can run this to check if the tables are populated and there's no NULL or Blank Values in the industry column. 
SELECT *
from layoffs_staging2
WHERE industry IS NULL OR industry = '';


-- Remove Columns that are not necessary and cannot be able to populate. The total_laid_off and percentage_laid_off with Null or blank values are to be removed since there's no use for that data.

SELECT *			-- This will select all the total_laid_off and percentage_laid_off with NULL values which we believe is useless.
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- So we delete it
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- We need to remove the row_num column that we had used to remove the duplicates.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;