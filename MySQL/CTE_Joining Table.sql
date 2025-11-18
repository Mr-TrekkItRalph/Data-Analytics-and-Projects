SELECT *
FROM layoffs_staging2;

SELECT DISTINCT stage
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE stage IS NULL;

SELECT company, location
FROM layoffs_staging2
WHERE stage IS NULL;

WITH CTE_Companies_With_Stage_Null AS
(
SELECT company AS company_null, location AS location_null
FROM layoffs_staging2
WHERE stage IS NULL
)
SELECT *
FROM layoffs_staging2
WHERE company = `company_null` AND location = `location_null`;

WITH CTE_Companies_With_Stage_Null AS 
(
	SELECT company, location
    FROM layoffs_staging2
    WHERE stage IS NULL
)
SELECT table1.*
FROM layoffs_staging2 table1
JOIN CTE_Companies_With_Stage_Null table2
    ON table1.company = table2.company
   AND table1.location = table2.location;