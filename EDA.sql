-- EDA (Análisis Exploratorio de Datos)
-- Vamos a explorar los datos y buscar tendencias, patrones o cualquier cosa interesante como valores atípicos
-- Normalmente cuando se inicia el proceso de EDA ya se tiene alguna idea de lo que se busca
-- Con estos datos simplemente vamos a explorar y ver qué encontramos

SELECT * 
FROM world_layoffs.layoffs_staging2;


-- CONSULTAS SIMPLES

SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;

-- Miramos el porcentaje para ver qué tan grandes fueron estos despidos
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;

-- Qué empresas tuvieron un valor de 1, es decir, básicamente el 100% de su personal despedido
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1;
-- En su mayoría parecen ser startups que cerraron durante este período

-- Si ordenamos por funds_raised_millions podemos ver qué tan grandes eran algunas de estas empresas
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- BritishVolt parece ser una empresa de vehículos eléctricos.
-- Recaudó como 2 mil millones de dólares y cerró.


-- CONSULTAS INTERMEDIAS - PRINCIPALMENTE CON GROUP BY --------------------------------------------------------------------------------------------------

-- Empresas con el mayor despido en un solo evento
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging
ORDER BY 2 DESC
LIMIT 5;
-- Esto es solo en un único día

-- Empresas con el mayor total de despidos acumulados
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- Por ubicación
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- Este es el total en los últimos 3 años o en el dataset completo
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;

SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- CONSULTAS AVANZADAS ------------------------------------------------------------------------------------------------------------------------------------

-- Antes vimos las empresas con más despidos en total. Ahora veamos eso por año
WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS anio, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, anio, total_laid_off, DENSE_RANK() OVER (PARTITION BY anio ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, anio, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND anio IS NOT NULL
ORDER BY anio ASC, total_laid_off DESC;

-- Total acumulado de despidos por mes
SELECT SUBSTRING(date,1,7) AS fechas, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY fechas
ORDER BY fechas ASC;

-- Ahora lo usamos dentro de un CTE para poder consultarlo
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) AS fechas, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY fechas
ORDER BY fechas ASC
)
SELECT fechas, SUM(total_laid_off) OVER (ORDER BY fechas ASC) AS total_acumulado_despidos
FROM DATE_CTE
ORDER BY fechas ASC;
