## Proyecto: Limpieza de Datos en MySQL

Este proyecto muestra cómo limpiar un dataset de despidos (`layoffs`) en MySQL.

### Archivos incluidos
- `layoffs.csv` → Dataset original.
- `data_cleaning.sql` → Script SQL con todo el proceso de limpieza.

### Proceso realizado
1. Creación de tablas de staging (`layoffs_staging`, `layoffs_staging2`).
2. Eliminación de duplicados con `ROW_NUMBER()`.
3. Estandarización de datos (TRIM, unificación de industrias, corrección de países, conversión de fechas).
4. Manejo de valores nulos y vacíos.
5. Eliminación de registros incompletos.
6. Eliminación de columnas auxiliares.

### Resultado
La tabla final `layoffs_staging2` contiene los datos limpios y listos para análisis.
