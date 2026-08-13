# Proyecto SQL: Análisis de Retail - Optimización de Inventario y Ventas

## Resumen (Overview)

El equipo comercial y de operaciones de la compañía de retail desea optimizar el rendimiento de sus sucursales, entender la rotación de sus productos y medir el riesgo comercial en el anaquel. Sin embargo, no cuentan con una visión unificada ni estructurada de los datos operativos de sus ventas históricas. Mi objetivo es utilizar T-SQL dentro de SQL Server Management Studio para auditar, limpiar y analizar estos datos, proporcionando insights estratégicos y recomendaciones que faciliten la toma de decisiones gerenciales exitosas.

## Sobre los Datos

Los datos originales extraídos del repositorio público de [Big Mart Sales en Kaggle](https://www.kaggle.com/datasets/akashdeepkuila/big-mart-sales?select=Train-Set.csv), junto con una copia local disponible en la carpeta [`dataset/`](dataset/) de este repositorio, incluyen información detallada que captura características de los productos, niveles de grasa, visibilidad en anaquel, precios MRP, tipos de tiendas y ventas históricas, distribuidos en más de 8,500 registros.

<img width="1091" height="252" alt="Imagen1" src="https://github.com/user-attachments/assets/bc027647-b9bb-4d60-8d1c-438b7cd8b263" />

## Áreas de Análisis (Tasks)

En este análisis, desarrollo consultas orientadas a responder las siguientes preguntas clave de negocio:

* **Auditoría y Limpieza (Pilar 1):** ¿Cuál es el estado inicial de los registros y cómo se homologan las inconsistencias de texto y nulos en el contenido de grasa (`FatContent`)?
* **Rendimiento Global (Pilar 2):** ¿Cuáles son los ingresos históricos globales y cómo se comportan las ventas según el tipo de ubicación y el año de establecimiento de las sucursales?
* **Segmentación de Sucursales (Pilar 2):** ¿Cómo se pueden clasificar las tiendas en cuartiles de rendimiento financiero utilizando funciones de distribución (`NTILE`)?
* **Productos Estrella y Descartables (Pilar 3):** ¿Cuáles son los 10 mejores productos (Top) y los 10 con peor salida (Bottom) utilizando funciones de ranking (`DENSE_RANK`)?
* **Participación por Categoría (Pilar 3):** ¿Cuál es el porcentaje de aporte de cada tipo de producto frente al gran total de la empresa utilizando funciones de ventana vacías (`SUM() OVER()`)?
* **Top por Categoría (Pilar 3):** ¿Cuáles son los 3 principales productos de cada categoría aplicando particionamiento por tipo de producto (`ROW_NUMBER`)?
* **Eficiencia por Formato de Tienda (Pilar 4):** ¿Cómo se comparan los supermercados frente a las tiendas de conveniencia en cuanto a su venta promedio por producto?
* **Impacto de la Visibilidad (Pilar 4):** ¿Existe una anomalía de ventas en los productos según su nivel de exposición o visibilidad en los anaqueles?
* **Factor de Rotación y Precio (Pilar 5):** ¿Cómo se comportan las ventas y la velocidad de rotación esperada al segmentar los productos según su precio de etiqueta (`MRP`)?
* **Ley de Pareto (Pilar 5):** ¿Qué porcentaje de las ventas totales concentra cada categoría de producto dentro del negocio?
* **Estabilidad y Riesgo Comercial (Pilar 5):** ¿Cuál es el nivel de volatilidad y dispersión de las ventas (desviación estándar) dentro de cada categoría para detectar riesgos operativos?

## Pilar 1: Entender el Terreno (Exploración, Auditoría y Limpieza)

El objetivo principal de esta primera fase fue conocer la salud general de los datos, detectar valores nulos y homologar las variables categóricas irregulares antes de avanzar con el análisis de negocio.

### 1. Auditoría de Estructura
Ejecuté una auditoría estructural para validar los tipos de datos asignados a cada columna de la tabla.

```sql
EXEC sp_help 'Staging_Train_Raw';
```
<img width="925" height="523" alt="image" src="https://github.com/user-attachments/assets/9f9a5ea5-12aa-4a96-8ccb-a250dc3bf428" />

### 2. Perfilamiento y Detección de Nulos
Verifiqué la existencia de valores faltantes en los campos críticos del dataset utilizando condicionales de conteo para asegurar la integridad de la información.

```sql
SELECT 
    SUM(CASE WHEN [ProductID] IS NULL THEN 1 ELSE 0 END) AS nulos_id_producto,
    SUM(CASE WHEN [Weight] IS NULL THEN 1 ELSE 0 END) AS nulos_peso,
    SUM(CASE WHEN [FatContent] IS NULL THEN 1 ELSE 0 END) AS nulos_contenido_grasa,
    SUM(CASE WHEN [ProductVisibility] IS NULL THEN 1 ELSE 0 END) AS nulos_visibilidad_producto,
    SUM(CASE WHEN [ProductType] IS NULL THEN 1 ELSE 0 END) AS nulos_tipo_producto,
    SUM(CASE WHEN [MRP] IS NULL THEN 1 ELSE 0 END) AS nulos_precio_mrp,
    SUM(CASE WHEN [OutletID] IS NULL THEN 1 ELSE 0 END) AS nulos_id_tienda,
    SUM(CASE WHEN [EstablishmentYear] IS NULL THEN 1 ELSE 0 END) AS nulos_anio_establecimiento,
    SUM(CASE WHEN [OutletSize] IS NULL THEN 1 ELSE 0 END) AS nulos_tamano_tienda,
    SUM(CASE WHEN [LocationType] IS NULL THEN 1 ELSE 0 END) AS nulos_tipo_ubicacion,
    SUM(CASE WHEN [OutletType] IS NULL THEN 1 ELSE 0 END) AS nulos_tipo_tienda,
    SUM(CASE WHEN [OutletSales] IS NULL THEN 1 ELSE 0 END) AS nulos_ventas_tienda
FROM [RetailDB].[dbo].[Staging_Train_Raw];
```
<img width="1587" height="138" alt="image" src="https://github.com/user-attachments/assets/f3d54644-54b9-4fc5-a518-3d9850e35970" />


### 3. Detección de Inconsistencias de Texto
Analicé los valores categóricos de la columna de contenido de grasa (`FatContent`), detectando variaciones de escritura que significaban lo mismo (como `'LF'` / `'Low Fat'` y `'reg'` / `'Regular'`).

```sql
SELECT 
    FatContent, 
    COUNT(FatContent) AS cantidad
FROM [RetailDB].[dbo].[Staging_Train_Raw]
GROUP BY FatContent;
```
<img width="231" height="143" alt="image" src="https://github.com/user-attachments/assets/fb5abb32-ad81-4308-a059-d8f3943d09ef" />

### 4. Plan de Limpieza y Tabla Homologada
Finalmente, para corregir las anomalías encontradas, diseñé un script que unifica los textos irregulares, reemplaza los valores nulos por defecto con funciones lógicas (`ISNULL`, `CASE`) y genera una tabla limpia oficial llamada `Staging_Train_Clean`.

```sql
IF OBJECT_ID('[RetailDB].[dbo].[Staging_Train_Clean]', 'U') IS NOT NULL
DROP TABLE [RetailDB].[dbo].[Staging_Train_Clean];

SELECT 
     [ProductID]           
    ,ISNULL([Weight],0) AS [Weight]            
    ,CASE 
        WHEN [FatContent] IN ('Low Fat', 'LF') THEN 'Low Fat'
        WHEN [FatContent] IN ('Regular', 'reg') THEN 'Regular'
        ELSE [FatContent]
     END AS [FatContent]
    ,[ProductVisibility]  
    ,[ProductType]         
    ,[MRP]                 
    ,[OutletID]            
    ,[EstablishmentYear]   
    ,ISNULL([OutletSize],'Desconocido') AS [OutletSize]          
    ,[LocationType]        
    ,[OutletType]          
    ,[OutletSales]    
INTO [RetailDB].[dbo].[Staging_Train_Clean]
FROM [RetailDB].[dbo].[Staging_Train_Raw];
```
<img width="1116" height="468" alt="image" src="https://github.com/user-attachments/assets/d5f5063b-6fe9-48b0-a3c1-e299ebea6472" />



