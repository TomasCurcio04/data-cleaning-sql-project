-- Proyecto SQL - Limpieza de Datos

SELECT * 
FROM world_layoffs.layoffs;

-- Lo primero que queremos hacer es crear una tabla de staging. Es en la que vamos a trabajar y limpiar los datos.
-- Queremos conservar la tabla original con los datos crudos por si algo sale mal.
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;


-- Cuando limpiamos datos generalmente seguimos estos pasos:
-- 1. Verificar duplicados y eliminarlos
-- 2. Estandarizar los datos y corregir errores
-- 3. Revisar los valores nulos y decidir qué hacer con ellos
-- 4. Eliminar columnas y filas que no sean necesarias



-- 1. Eliminar Duplicados

-- Primero verifiquemos si hay duplicados

SELECT *
FROM world_layoffs.layoffs_staging;

SELECT company, industry, total_laid_off, `date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off, `date`) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

SELECT *
FROM (
	SELECT company, industry, total_laid_off, `date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off, `date`
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicados
WHERE 
	row_num > 1;
    
-- Veamos Oda para confirmar
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda';
-- Parece que todas son entradas legítimas y no deberían eliminarse.
-- Necesitamos revisar cada fila con cuidado para ser precisos.

-- Estos son los duplicados reales
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicados
WHERE 
	row_num > 1;

-- Estos son los que queremos eliminar donde el número de fila es mayor a 1

-- Una forma de escribirlo sería así:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicados
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE;


WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- Una buena solución es crear una nueva columna y agregar los números de fila.
-- Luego eliminar donde el número de fila sea mayor a 2, y finalmente borrar esa columna.

ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;

SELECT *
FROM world_layoffs.layoffs_staging;

CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location` text,
`industry` text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage` text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- Ahora que tenemos esto podemos eliminar las filas donde row_num sea mayor a 2
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;


-- 2. Estandarizar los Datos

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- Si miramos la columna industry vemos que hay filas nulas y vacías, revisémoslas
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- Veamos estos casos
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';
-- Nada incorrecto aquí

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- Parece que Airbnb es de la industria Travel, pero esta fila no tiene ese valor.
-- Lo mismo debe ocurrir con las demás. Podemos escribir una consulta que,
-- si existe otra fila con el mismo nombre de empresa, actualice el valor de industry al que no es nulo.
-- Así, si hubiera miles de registros, no tendríamos que revisarlos manualmente.

-- Primero convertimos los vacíos a nulos, ya que son más fáciles de manejar
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Verificamos que ahora todos sean nulos
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- Ahora poblamos esos nulos donde sea posible
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Al verificar, parece que Bally's fue el único sin otra fila para poblar el valor nulo
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- ---------------------------------------------------

-- También notamos que Crypto tiene múltiples variaciones. Necesitamos estandarizarlo, en este caso todo como 'Crypto'
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Listo, verificamos:
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- --------------------------------------------------
-- También necesitamos revisar lo siguiente:

SELECT *
FROM world_layoffs.layoffs_staging2;

-- Todo se ve bien excepto que tenemos "United States" y "United States." con punto al final. Vamos a estandarizarlo.
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- Al ejecutarlo nuevamente queda corregido
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;


-- Corrijamos también la columna de fecha:
SELECT *
FROM world_layoffs.layoffs_staging2;

-- Usamos STR_TO_DATE para actualizar este campo
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Ahora convertimos el tipo de dato correctamente
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM world_layoffs.layoffs_staging2;


-- 3. Revisar Valores Nulos

-- Los valores nulos en total_laid_off, percentage_laid_off y funds_raised_millions parecen normales. No quiero modificarlos.
-- Prefiero dejarlos nulos porque facilita los cálculos durante la fase de análisis exploratorio (EDA).

-- No hay nada que quiera cambiar con los valores nulos.


-- 4. Eliminar columnas y filas innecesarias

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Eliminamos datos inútiles que no podemos aprovechar
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM world_layoffs.layoffs_staging2;
