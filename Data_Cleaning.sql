-- Data Cleaning 

SELECT *
FROM layoffs;


-- Create staging table 
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- 1. Remove Duplicates 

#give row numbers showing duplicates
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

#cte that shows all rows that have duplicates (row num > 1)
WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

#check if duplicates are actually duplicates 
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';


#create another staging table that we can edit/update
CREATE TABLE `layoffs_staging2` (
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
WHERE row_num > 1;

#copy all data from layoffs_staging into new staging table 
INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

#delete duplicate rows 
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;



-- 2. Standardize the data (finding issues and fixing)

SELECT company, TRIM((company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);


#check industry (distinct rows)
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

#change CryptoCurrency and Crypto to 'Crypto' (same industry)

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT(country)
FROM layoffs_staging2;

SELECT country
FROM layoffs_staging2
WHERE country LIKE 'United States%';

#found United States Duplicate (one is 'United States.')
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

#change date from text to date format
SELECT `date`
FROM layoffs_staging2;

#update date column 
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

#alter table to change date to date data type 
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


--  3. Null Values or Blank Values 

SELECT *
FROM layoffs_staging2;

SELECT total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

#fill empty cells with NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

#Populating empty or NULL cells with found info
#Find all companies that have an empty or NULL industry cell AND a filled cell (using a join)
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
#shows Airbnb, Carvana, and Juul have both filled and empty industry cells (can update/fill)

#update those companies 
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

#found 1 last company where industry is NULL (check for same comp with filled cell)
SELECT *
FROM layoffs_staging2
WHERE company = "Bally's Interactive";
#Only 1 lisitng, cant update 

#Delete data where total_laid_off AND percent_laid_off is NULL (useless data, cant trust)
SELECT *
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


-- 4. Remove any Columns or Rows not needed
#remove row_num column (dont need anymore)
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

