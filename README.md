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
8. ¿Cómo influye el nivel de visibilidad de los productos en el anaquel sobre la cantidad de artículos y su venta promedio?
9. ¿Cómo se comportan el volumen de productos, el precio promedio y el factor de retorno de ventas al segmentar el catálogo según los rangos de precios (MRP)?
10. ¿Cómo varía la variedad de productos, el precio MRP promedio y el factor de retorno comercial al analizar el rendimiento específico de cada categoría?
11. ¿Cuáles son los productos específicos de menor rendimiento o baja rotación ("zombies") dentro de la categoría comercial con menor tracción?
12. ¿Cuál es el nivel de estabilidad y riesgo comercial medido a través de la desviación estándar y el índice de volatilidad en las ventas de cada categoría de producto?
13. ¿Cómo impacta la ubicación del producto en el anaquel (bajo diferentes niveles de visibilidad) en el precio MRP promedio, la venta promedio generada y el factor de retorno de visibilidad?

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

### Pregunta #4: ¿Qué porcentaje de los ingresos totales de la empresa aporta cada categoría de producto?

Agrupé las ventas por categoría utilizando una expresión de tabla común y calculé la proporción exacta frente al ingreso global aplicando una función de ventana vacía (`SUM OVER`).

```sql
WITH VentasPorCategoria AS (
    SELECT 
        ProductType, 
        SUM([OutletSales]) AS ingreso_categoria
    FROM [RetailDB].[dbo].[Staging_Train_Clean]
    GROUP BY ProductType
)
SELECT 
    ProductType,
    ingreso_categoria,
    SUM(ingreso_categoria) OVER() AS gran_total_empresa, 
    CAST((ingreso_categoria * 100.0) / SUM(ingreso_categoria) OVER() AS DECIMAL(5,2)) AS porcentaje_participacion
FROM VentasPorCategoria
ORDER BY porcentaje_participacion DESC;
```
<img width="586" height="378" alt="image" src="https://github.com/user-attachments/assets/a3a2b82c-89c3-4104-a93f-7f59d84e7af8" />



#### Participación y Ley de Pareto
El análisis de concentración demuestra que las ventas de la compañía se apoyan fuertemente en las dos primeras categorías: **Fruits and Vegetables** lidera con un ingreso de **2,820,059.82** (15.17% de participación), seguida muy de cerca por **Snack Foods** con **2,732,786.09** (14.70%). Juntas, estas dos líneas concentran casi el 30% de toda la facturación histórica. En el otro extremo, categorías como **Breakfast** (1.25%) y **Seafood** (0.80%) registran la menor incidencia en el modelo de negocio.
La gerencia debe proteger y priorizar el abastecimiento absoluto de las categorías principales en los puntos de venta para evitar cualquier quiebre de stock que impacte los ingresos globales, mientras que las de menor participación deben ser evaluadas para determinar si su baja rotación justifica el espacio de anaquel que ocupan.

### Pregunta #5: ¿Cuáles son los artículos líderes dentro de cada categoría comercial?

Agrupé las ventas por cada tipo y código de producto, y apliqué la función analítica de particionamiento `ROW_NUMBER` para aislar de forma justa los tres principales artículos de cada línea comercial.
```sql
WITH ingresoporcategoria AS (
    SELECT 
        ProductType,
        ProductID,
        SUM([OutletSales]) AS ingreso_categoria
    FROM [RetailDB].[dbo].[Staging_Train_Clean]
    GROUP BY ProductType, ProductID
), 
topproducto AS (
    SELECT 
        ProductType,
        ProductID,
        ingreso_categoria,
        ROW_NUMBER() OVER (PARTITION BY ProductType ORDER BY ingreso_categoria DESC) AS ranking
    FROM ingresoporcategoria
)
SELECT 
    ProductType,
    ProductID,
    ingreso_categoria,
    ranking
FROM topproducto
WHERE ranking <= 2
ORDER BY ProductType, ranking ASC;
```
<img width="452" height="697" alt="image" src="https://github.com/user-attachments/assets/71988c08-072a-46cd-8312-aea97b5cfc8a" />

#### Líderes por Categoría
El desglose particionado permitió identificar con precisión los artículos tractores dentro de cada familia de productos, destacando que los líderes varían notablemente en facturación según la categoría: por ejemplo, en **Dairy** el producto **FDA15** lidera con **41,584.54**, y en **Fruits and Vegetables** el **FDY55** alcanza **42,661.80** en el primer puesto. Por el contrario, categorías de menor escala muestran líderes con menor volumen, como en **Breakfast** donde el artículo **FDO37** registra **30,958.37**.
La compañía puede utilizar esta jerarquía por categoría para diseñar estrategias de comercialización focalizadas, asegurando que estos productos punteros cuenten siempre con el stock y el espacio de exhibición preferencial necesario para mantener traccionada a su respectiva familia comercial.

### Pregunta #6: ¿Cómo influyen las características nutricionales de los productos en el volumen de ventas y en el ticket promedio?

Agrupé los registros comerciales según el contenido de grasa (`FatContent`) de los productos, calculando el total de transacciones, las ventas acumuladas y el promedio por operación.
```sql
SELECT 
    FatContent AS tipo_grasa,
    COUNT([ProductID]) AS total_productos_vendidos,
    SUM([OutletSales]) AS ventas_totales,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio_por_transaccion
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY FatContent
ORDER BY ventas_totales DESC;
```
<img width="606" height="97" alt="image" src="https://github.com/user-attachments/assets/17f7c49a-53e7-4828-927a-30454dbc04d1" />

####Impacto del Contenido de Grasa
El análisis nutricional refleja una clara preferencia de consumo hacia los productos del segmento **Low Fat**, los cuales registran un volumen masivo de **5,517** productos vendidos y generan ventas totales por **11,904,094.53**, superando ampliamente al segmento **Regular**, que alcanza **3,006** unidades vendidas y **6,687,030.88** en ingresos. Sin embargo, en términos de ticket o venta promedio por transacción, el segmento Regular muestra un leve liderazgo con **2,224.56** frente a los **2,157.71** de las opciones bajas en grasa.
La empresa puede aprovechar esta información para respaldar la alta rotación y disponibilidad de los productos bajos en grasa en los anaqueles debido a su masiva demanda, mientras optimiza las estrategias de precio o empaque en el segmento Regular para capitalizar su mayor ticket por transacción.

### Pregunta #7: ¿Cómo se comparan los supermercados frente a las tiendas de conveniencia en cuanto a su rendimiento comercial?

Agrupé los registros por el tipo de tienda (`OutletType`), calculando el volumen de transacciones, las ventas totales y la venta promedio por producto para cada formato comercial.
```sql
SELECT 
    [OutletType] AS tipo_tienda,
    COUNT([ProductID]) AS total_transacciones_o_productos,
    SUM([OutletSales]) AS ventas_totales,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio_por_producto
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [OutletType]
ORDER BY venta_promedio_por_producto DESC;
```
<img width="692" height="148" alt="image" src="https://github.com/user-attachments/assets/52c71d49-1d6d-4855-b6cc-236874c5fba9" />

#### Eficiencia por Formato
El análisis comparativo revela diferencias drásticas en el rendimiento entre los formatos de la cadena: **Supermarket Type1** encabeza el volumen operativo con **5,577** transacciones y recauda las mayores ventas totales con **12,917,342.26**, mientras que **Supermarket Type3**, a pesar de tener solo **935** transacciones, domina con holgura la eficiencia y el ticket promedio por producto alcanzando **3,694.04**. En marcado contraste, el formato **Grocery Store** registra un volumen considerable de **1,083** transacciones pero se rezaga fuertemente al fondo con ventas totales de apenas **368,034.27** y una venta promedio muy baja de **339.83**.
La compañía debe usar estos hallazgos para potenciar el modelo de alta rentabilidad del Supermarket Type3 e impulsar la estrategia comercial en las tiendas de tipo Grocery Store, cuyo bajo ticket promedio limita seriamente la generación de ingresos frente al esfuerzo operativo invertido.

### Pregunta #8: ¿Cómo influye el nivel de visibilidad de los productos en el anaquel sobre la cantidad de artículos y su venta promedio?

Agrupé los registros comerciales segmentando el porcentaje de exposición en el anaquel, calculando la cantidad total de artículos y la venta promedio generada en cada nivel de visibilidad.
```sql
SELECT 
    CASE 
        WHEN [ProductVisibility] < 0.05 THEN '1. Baja Visibilidad (< 5%)'
        WHEN [ProductVisibility] BETWEEN 0.05 AND 0.15 THEN '2. Media Visibilidad (5% - 15%)'
        ELSE '3. Alta Visibilidad (> 15%)'
    END AS nivel_visibilidad,
    COUNT([ProductID]) AS cantidad_productos,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY 
    CASE 
        WHEN [ProductVisibility] < 0.05 THEN '1. Baja Visibilidad (< 5%)'
        WHEN [ProductVisibility] BETWEEN 0.05 AND 0.15 THEN '2. Media Visibilidad (5% - 15%)'
        ELSE '3. Alta Visibilidad (> 15%)'
    END
ORDER BY nivel_visibilidad ASC;
```
<img width="480" height="117" alt="image" src="https://github.com/user-attachments/assets/cbaf7490-ee7b-48ac-beae-ca3ae6b293d2" />

#### Impacto de la Visibilidad en el Anaquel
El análisis según el nivel de exposición muestra un comportamiento contraintuitivo pero revelador en el punto de venta: el segmento de **Baja Visibilidad (< 5%)** concentra la mayor cantidad de productos con **4,051** registros y lidera el rendimiento con una venta promedio superior de **2,289.54**, seguido de cerca por la **Media Visibilidad (5% - 15%)** con **3,822** productos y una venta promedio de **2,192.72**. En contraste, el segmento de **Alta Visibilidad (> 15%)** agrupa una oferta reducida de **650** productos y experimenta una caída marcada en su venta promedio, situándose en **1,439.41**.
La gerencia debe reevaluar la asignación de espacios preferenciales en los anaqueles, ya que los datos sugieren que una alta exposición visual por sí sola no garantiza un mayor ticket de venta; se deben investigar factores adicionales como la demanda natural del producto o posibles sobreexhibiciones en artículos de menor rotación.

### Pregunta #9: ¿Cómo se comportan el volumen de productos, el precio promedio y el factor de retorno de ventas al segmentar el catálogo según los rangos de precios (MRP)?

Agrupé los registros clasificando el precio de venta recomendado (MRP) en cuatro segmentos estratégicos (Económico, Medio, Alto y Premium), calculando la cantidad de artículos, el precio promedio, la venta promedio y el factor de retorno por cada categoría de precio.
```sql
WITH SegmentoMRP AS (
    SELECT 
        [ProductID],
        [MRP],
        [ProductVisibility],
        [OutletSales],
        CASE 
            WHEN [MRP] < 70 THEN '1. Económico (< 70)'
            WHEN [MRP] BETWEEN 70 AND 140 THEN '2. Medio (70 - 140)'
            WHEN [MRP] BETWEEN 140 AND 200 THEN '3. Alto (140 - 200)'
            ELSE '4. Premium (> 200)'
        END AS categoria_mrp
    FROM [RetailDB].[dbo].[Staging_Train_Clean]
)
SELECT 
    categoria_mrp,
    COUNT([ProductID]) AS total_productos,
    CAST(AVG([MRP]) AS DECIMAL(10,2)) AS mrp_promedio,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio,
    CAST(SUM([OutletSales]) / NULLIF(SUM([MRP]), 0) AS DECIMAL(10,4)) AS factor_retorno_ventas
FROM SegmentoMRP
GROUP BY categoria_mrp
ORDER BY mrp_promedio ASC;
```
<img width="642" height="140" alt="image" src="https://github.com/user-attachments/assets/50eee5f6-1094-4eb7-9b11-e049e546af28" />

#### Impacto del Nivel de Precios (MRP) y Factor de Retorno
El análisis por rangos de precios demuestra una progresión ascendente muy clara en la venta promedio a medida que se incrementa el valor del producto: el segmento **Económico (< 70)** registra **1,341** productos con un MRP promedio de **48.59** y una venta promedio de **736.47**, mientras que el segmento **Medio (70 - 140)** agrupa **2,778** artículos con **105.01** de MRP y **1,621.15** en ventas. Por su parte, el segmento **Alto (140 - 200)** cuenta con **2,964** productos, un MRP de **169.76** y **2,632.41** de venta promedio, y finalmente el segmento **Premium (> 200)** alcanza **1,440** artículos con un MRP promedio de **237.25** y la venta promedio más alta de **3,678.82**. Además, el factor de retorno de ventas se mantiene sumamente estable y competitivo entre **15.1570** y **15.5069** en todas las categorías.
La gerencia puede utilizar estos datos para confirmar que los segmentos **Alto** y **Medio** concentran la mayor variedad de inventario, mientras que el factor de retorno constante valida que los incrementos en el precio de etiqueta se traducen de forma proporcional y saludable en los ingresos comerciales del negocio.

### Pregunta #10: ¿Cómo varía la variedad de productos, el precio MRP promedio y el factor de retorno comercial al analizar el rendimiento específico de cada categoría?

Agrupé los registros comerciales por tipo de producto (`ProductType`), calculando la variedad total de artículos, el precio MRP promedio, la venta promedio y el factor de retorno de la categoría para identificar cuáles familias de productos maximizan la eficiencia comercial.
```sql
SELECT 
    [ProductType] AS categoria_producto,
    COUNT([ProductID]) AS total_variedad_productos,
    CAST(AVG([MRP]) AS DECIMAL(10,2)) AS precio_mrp_promedio,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio,
    CAST(SUM([OutletSales]) / NULLIF(SUM([MRP]), 0) AS DECIMAL(10,4)) AS factor_retorno_categoria
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [ProductType]
ORDER BY venta_promedio DESC
```
<img width="778" height="372" alt="image" src="https://github.com/user-attachments/assets/c1ba2d44-9ffa-4cf5-aabd-f3ffe022db18" />

#### Rendimiento y Factor de Retorno por Categoría
El análisis por categoría detalla el comportamiento financiero y la eficiencia de inventario de cada línea comercial: **Stachy Foods** encabeza la venta promedio con **2,374.33** (148 productos, MRP promedio de **147.84** y un factor de retorno de **16.0604**), seguida muy de cerca por **Seafood** con una venta promedio de **2,326.07** (64 productos, MRP de **141.84** y el factor de retorno más alto de **16.3990**). En contraste, categorías de alta masividad como **Fruits and Vegetables** agrupan la mayor variedad con **1,232** productos y una venta promedio de **2,289.01**, mientras que en la parte baja del ranking se ubica **Others** con **169** artículos y una venta promedio de **1,926.14** (factor de retorno de **14.4984**).
La empresa puede utilizar estos indicadores para focalizar las estrategias de reposición de inventario y optimizar la asignación de recursos en aquellas categorías que demuestran una mayor rentabilidad y tracción en el punto de venta.

### Pregunta #11: ¿Cuáles son los productos específicos de menor rendimiento o baja rotación ("zombies") dentro de la categoría comercial con menor tracción?

Filtré los registros por la categoría comercial específica y calculé un factor de rendimiento individual dividiendo las ventas totales históricas entre su precio de etiqueta (MRP), ordenando los resultados de menor a mayor para aislar los artículos más ineficientes.

```sql
SELECT 
    [ProductType] AS categoria,
    [ProductID] AS producto_zombie,
    [MRP] AS precio_etiqueta,
    [OutletSales] AS ventas_totales_historicas,
    CAST([OutletSales] / NULLIF([MRP], 0) AS DECIMAL(10,2)) AS factor_individual
FROM [RetailDB].[dbo].[Staging_Train_Clean]
WHERE [ProductType] = 'Others'
ORDER BY factor_individual ASC;
```
<img width="608" height="627" alt="image" src="https://github.com/user-attachments/assets/cafdc89e-b700-4e5d-a029-1399818aa97c" />


#### Identificación de Productos de Baja Rotación (Zombies)
El análisis a nivel de detalle de SKU permite detectar con precisión los productos específicos que arrastran el rendimiento comercial dentro de la categoría **Others**: el artículo **NCP55** registra el menor rendimiento con un factor individual de **0.98** (precio de etiqueta de **56.4614** y ventas históricas de **55.2614**), seguido de cerca por productos como **NCM26** (factor individual de **0.99**, MRP de **153.934** y ventas de **153.134**), **NCL31** (factor de **0.99**, MRP de **144.747** y ventas de **143.147**), **NCL07** (factor de **0.99**, MRP de **40.548** y ventas de **39.948**) y **NCP43** (factor de **0.99**, MRP de **181.766** y ventas de **179.766**).
La gerencia puede utilizar esta auditoría a nivel de artículo individual para descontinuar o liquidar estos productos de baja tracción, liberando valioso espacio de anaquel y reduciendo costos innecesarios de almacenamiento operativo.

### Pregunta #12: ¿Cuál es el nivel de estabilidad y riesgo comercial medido a través de la desviación estándar y el índice de volatilidad en las ventas de cada categoría de producto?

Agrupé los registros por categoría de producto (`ProductType`), calculando la variedad total, la venta promedio, la desviación estándar y el porcentaje del índice de volatilidad para identificar qué familias de artículos presentan un comportamiento de demanda más inestable o disperso.
```sql
SELECT 
    [ProductType] AS categoria_producto,
    COUNT([ProductID]) AS total_variedad_productos,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio,
    CAST(STDEV([OutletSales]) AS DECIMAL(10,2)) AS desviacion_ventas,
    CAST((STDEV([OutletSales]) / AVG([OutletSales])) * 100 AS DECIMAL(5,2)) AS indice_volatilidad_porcentaje
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [ProductType]
ORDER BY indice_volatilidad_porcentaje DESC;

```
<img width="746" height="381" alt="image" src="https://github.com/user-attachments/assets/90fb1a07-4ae0-4f14-9d1a-445767b879e0" />

#### Estabilidad y Riesgo Comercial por Categoría
El análisis de dispersión y riesgo comercial permite a la gerencia evaluar la previsibilidad de los ingresos por cada línea de producto: la categoría **Breakfast** encabeza la volatilidad con el índice más alto de dispersión alcanzando un **90.52%** (110 productos, venta promedio de **2,111.81** y desviación estándar de **1,911.69**), seguida de cerca por **Dairy** con un índice de **84.41%** (682 productos, venta de **2,232.54** y desviación de **1,884.40**) y **Soft Drinks** con **83.44%** (445 productos, venta de **2,006.51** y desviación de **1,674.25**). En el extremo opuesto, las categorías más estables son **Others** con un índice de **74.34%** (169 productos, venta de **1,926.14** y desviación de **1,431.86**) y **Canned** registrando la menor volatilidad con **73.94%** (649 productos, venta de **2,225.19** y desviación de **1,645.24**).
La empresa debe utilizar estas métricas de volatilidad para implementar políticas de control de inventario diferenciadas; las categorías con alta inestabilidad como **Breakfast** exigen modelos de reabastecimiento más estrictos para prevenir quiebres de stock o sobrecostos por almacenamiento de productos con demanda impredecible.

### Pregunta #13: ¿Cómo impacta la ubicación del producto en el anaquel (bajo diferentes niveles de visibilidad) en el precio MRP promedio, la venta promedio generada y el factor de retorno de visibilidad?

Agrupé los registros clasificando el porcentaje de exposición física en tres zonas estratégicas del anaquel (Baja Visibilidad o Escondido, Visibilidad Media y Alta Visibilidad o Zona Caliente), calculando el total de productos, el precio de etiqueta promedio, la venta promedio y el factor de retorno de visibilidad.

```sql
SELECT 
    CASE 
        WHEN [ProductVisibility] < 0.05 THEN '1. Baja Visibilidad (Escondido)'
        WHEN [ProductVisibility] BETWEEN 0.05 AND 0.12 THEN '2. Visibilidad Media'
        ELSE '3. Alta Visibilidad (Zona caliente / Ojos)'
    END AS nivel_visibilidad_anaquel,
    COUNT([ProductID]) AS total_productos,
    CAST(AVG([MRP]) AS DECIMAL(10,2)) AS precio_mrp_promedio,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio_generada,
    CAST(SUM([OutletSales]) / SUM([MRP]) AS DECIMAL(10,4)) AS factor_retorno_visibilidad
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY 
    CASE 
        WHEN [ProductVisibility] < 0.05 THEN '1. Baja Visibilidad (Escondido)'
        WHEN [ProductVisibility] BETWEEN 0.05 AND 0.12 THEN '2. Visibilidad Media'
        ELSE '3. Alta Visibilidad (Zona caliente / Ojos)'
    END
ORDER BY factor_retorno_visibilidad DESC;
```
<img width="860" height="127" alt="image" src="https://github.com/user-attachments/assets/aea04ad6-3e60-45cd-85dc-e3d752910378" />

#### Impacto de la Ubicación en el Anaquel y Factor de Retorno
El análisis por zonas de exposición detalla la eficiencia comercial del espacio físico con los resultados exactos de la auditoría: el segmento de **1. Baja Visibilidad (Escondido)** lidera con contundencia el rendimiento con un factor de retorno de visibilidad de **16.4157** (concentrando **4,051** productos, un MRP promedio de **139.47** y una venta promedio generada de **2,289.54**), seguido por la **2. Visibilidad Media** con un factor de retorno de **15.5272** (**3,131** productos, MRP promedio de **144.42** y una venta promedio de **2,242.45**). En la parte inferior se encuentra el segmento de **3. Alta Visibilidad (Zona caliente / Ojos)** con un factor de retorno de **12.4396** (**1,341** productos, MRP de **137.58** y una venta promedio de **1,711.46**).
La gerencia debe utilizar estos hallazgos para reevaluar la distribución del espacio en los puntos de venta, ya que los datos evidencian que las zonas de mayor exposición visual no necesariamente maximizan el retorno comercial por unidad monetaria de precio, sugiriendo una oportunidad clave para optimizar la asignación de anaqueles.
