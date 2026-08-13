# Proyecto SQL: Análisis de Retail - Optimización de Inventario y Ventas

## Resumen (Overview)

El equipo comercial y de operaciones de la compañía de retail desea optimizar el rendimiento de sus sucursales, entender la rotación de sus productos y medir el riesgo comercial en el anaquel. Sin embargo, no cuentan con una visión unificada ni estructurada de los datos operativos de sus ventas históricas. Mi objetivo es utilizar T-SQL dentro de SQL Server Management Studio para auditar, limpiar y analizar estos datos, proporcionando insights estratégicos y recomendaciones que faciliten la toma de decisiones gerenciales exitosas.

## Sobre los Datos

Los datos originales extraídos del repositorio público de [Big Mart Sales en Kaggle](https://www.kaggle.com/datasets/akashdeepkuila/big-mart-sales?select=Train-Set.csv), junto con una copia local disponible en la carpeta [`dataset/`](dataset/) de este repositorio, incluyen información detallada que captura características de los productos, niveles de grasa, visibilidad en anaquel, precios MRP, tipos de tiendas y ventas históricas, distribuidos en más de 8,500 registros.

<img width="1091" height="252" alt="Imagen1" src="https://github.com/user-attachments/assets/bc027647-b9bb-4d60-8d1c-438b7cd8b263" />

## Áreas de Análisis (Tasks)

En este análisis, desarrollo consultas orientadas a responder las siguientes preguntas clave de negocio:

1. ¿Cuáles son los ingresos históricos totales de la compañía y cuál es la venta promedio generada por transacción?
2. ¿Cómo se pueden clasificar las tiendas objetivamente en cuatro niveles de rendimiento financiero según sus ingresos?
3. ¿Cuáles son exactamente los 10 mejores productos del negocio y cuáles son los 10 con peor desempeño comercial?
4. ¿Qué porcentaje de los ingresos totales de la empresa aporta cada categoría de producto?
5. ¿Cuáles son los artículos líderes dentro de cada categoría comercial?
6. ¿Cómo influyen las características nutricionales de los productos en el volumen de ventas y en el ticket promedio?
7. ¿Cómo se comparan los supermercados frente a las tiendas de conveniencia en cuanto a su rendimiento comercial?
8. ¿Cómo se comportan las ventas y el factor de retorno al agrupar los productos según su rango de precio (MRP)?
9. ¿Cuáles son los códigos específicos de producto que arrastran el rendimiento a la baja dentro de una categoría crítica?
10. ¿Cuál es el nivel de volatilidad y dispersión de las ventas que permite detectar riesgos operativos por categoría?

## Entender el Terreno (Exploración, Auditoría y Limpieza)

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

## Análisis Exploratorio de Datos (EDA) e Insights

### Pregunta #1: ¿Cuáles son los ingresos históricos totales de la compañía y cuál es la venta promedio generada por transacción?

Encontré el volumen total de ingresos y la venta promedio utilizando las funciones de agregación `SUM` y `AVG`.
```sql
SELECT SUM([OutletSales]) AS ingreso_historico
FROM [RetailDB].[dbo].[Staging_Train_Clean];

SELECT AVG([OutletSales]) AS venta_promedio_transaccion
FROM [RetailDB].[dbo].[Staging_Train_Clean];
```
<img width="282" height="160" alt="image" src="https://github.com/user-attachments/assets/a3442be9-8efc-4ff1-b443-40979e1dd897" />

#### Ingresos históricos totales y venta promedio por transacción
La compañía acumuló ingresos históricos totales por **18,591,125.41** unidades monetarias, estableciendo una venta promedio de **2,181.29** por cada transacción o registro analizado en la cadena.
La gerencia podría utilizar estos indicadores base como línea de referencia para medir con precisión el crecimiento financiero de futuras campañas comerciales y evaluar el ticket promedio de salida de los productos.

### Pregunta #2: ¿Cómo se pueden clasificar las tiendas objetivamente en cuatro niveles de rendimiento financiero según sus ingresos?

Agrupé los ingresos por cada sucursal utilizando una expresión de tabla común (`WITH`) y apliqué la función de distribución avanzada `NTILE(4)` junto con un condicional `CASE` para segmentar el rendimiento financiero en cuatro cuartiles exactos.
```sql
WITH VentasPorTienda AS (
    SELECT 
        [OutletID] AS id_tienda,
        SUM([OutletSales]) AS ingreso_total
    FROM [RetailDB].[dbo].[Staging_Train_Clean]
    GROUP BY [OutletID]
),
ClasificacionCuartiles AS (
    SELECT 
        id_tienda,
        ingreso_total,
        NTILE(4) OVER (ORDER BY ingreso_total DESC) AS cuartil_rendimiento
    FROM VentasPorTienda
)
SELECT 
    id_tienda,
    ingreso_total,
    cuartil_rendimiento,
    CASE 
        WHEN cuartil_rendimiento = 1 THEN 'Alto Rendimiento (Q1 - Top 25%)'
        WHEN cuartil_rendimiento = 2 THEN 'Medio-Alto (Q2 - 25% al 50%)'
        WHEN cuartil_rendimiento = 3 THEN 'Medio-Bajo (Q3 - 50% al 75%)'
        ELSE 'Bajo Rendimiento (Q4 - Bottom 25%)'
    END AS categoria_tienda
FROM ClasificacionCuartiles
ORDER BY cuartil_rendimiento ASC;
```
<img width="562" height="258" alt="image" src="https://github.com/user-attachments/assets/0e091166-b00c-4ff5-bbc7-50fe1d1dbff6" />

#### Segmentación de Sucursales
El análisis mediante cuartiles dejó en evidencia una disparidad crítica en el rendimiento de las sucursales: la tienda **OUT027** lidera el mercado con una facturación excepcional de **3,453,926.05**, distanciándose fuertemente del resto del Top 25% (Q1). En el extremo opuesto, sucursales como la **OUT010** y **OUT019** se hunden en el Bottom 25% (Q4) con ingresos muy rezagados que apenas rondan los **188,340** y **179,694**.
La gerencia debe usar esta clasificación para replicar las buenas prácticas comerciales de la tienda estrella OUT027 en las sucursales intermedias, y aplicar una intervención de emergencia o auditoría operativa en el grupo de bajo rendimiento (Q4) para evitar mayores pérdidas.

### Pregunta #3: ¿Cuáles son exactamente los 10 mejores productos del negocio y cuáles son los 10 con peor desempeño comercial?

Utilicé expresiones de tabla común y la función analítica de ranking `DENSE_RANK` para ordenar de forma descendente y ascendente el volumen de ventas por cada código de producto, combinando los resultados mediante un operador `UNION ALL`.
```sql
WITH Ranking AS (
    SELECT 
        [ProductID] AS id_producto,
        SUM([OutletSales]) AS ingreso_total,
        DENSE_RANK() OVER (ORDER BY SUM([OutletSales]) DESC) AS rnk_top,
        DENSE_RANK() OVER (ORDER BY SUM([OutletSales]) ASC) AS rnk_bottom
    FROM [RetailDB].[dbo].[Staging_Train_Clean]
    GROUP BY [ProductID]
)
SELECT id_producto, ingreso_total, 'Top 10' AS clasificacion FROM Ranking WHERE rnk_top <= 10
UNION ALL
SELECT id_producto, ingreso_total, 'Bottom 10' AS clasificacion FROM Ranking WHERE rnk_bottom <= 10
ORDER BY ingreso_total DESC;
```

<img width="330" height="452" alt="image" src="https://github.com/user-attachments/assets/3d6b2095-b1cc-4602-acad-4600fa92c9f4" />

#### Productos Estrella vs. Baja Salida
El análisis de extremos dejó al descubierto una brecha comercial masiva en el catálogo: el producto líder **FDY55** encabeza el Top 10 con una facturación de **42,661.80**, seguido muy de cerca por el **FDA15** con **41,584.54**. En stark contraste, los artículos catalogados como Bottom 10 presentan ingresos críticos y cercanos a cero, destacando el producto **FDQ60** que apenas recauda **120.51** y el **NCR42** con **332.90**.
La empresa debe implementar urgentemente una política de abastecimiento prioritario y protección de stock para los códigos estrella del Top 10, mientras que los ítems del Bottom 10 requieren una evaluación inmediata para su liquidación o baja definitiva del inventario, evitando así el costo de almacenamiento de productos sin rotación.    


