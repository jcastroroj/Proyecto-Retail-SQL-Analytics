
-- =========================================================================
-- PILAR 1: ENTENDER EL TERRENO (Exploración, Auditoría y Limpieza)
-- Objetivo: Conocer la salud de los datos, detectar nulos y homologar variables.
-- =========================================================================

-- 1. Carga inicial de datos (Total de registros: 8,523)
SELECT 
    [ProductID]            AS [id_producto] 
   ,[Weight]               AS [peso]
   ,[FatContent]           AS [contenido_grasa]
   ,[ProductVisibility]    AS [visibilidad_producto]
   ,[ProductType]          AS [tipo_producto]
   ,[MRP]                  AS [precio_mrp]
   ,[OutletID]             AS [id_tienda]
   ,[EstablishmentYear]    AS [anio_establecimiento]
   ,[OutletSize]           AS [tamano_tienda]
   ,[LocationType]         AS [tipo_ubicacion]
   ,[OutletType]           AS [tipo_tienda]
   ,[OutletSales]          AS [ventas_tienda]
FROM [RetailDB].[dbo].[Staging_Train_Raw];


-- 2. Auditoría de estructura y tipos de datos
EXEC sp_help 'Staging_Train_Raw';


-- 3. Perfilamiento de datos (Detección de valores nulos)
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


-- 4. Detección de inconsistencias de texto en FatContent
SELECT 
    FatContent, 
    COUNT(FatContent) AS cantidad
FROM [RetailDB].[dbo].[Staging_Train_Raw]
GROUP BY FatContent;


-- 5. Plan de limpieza y creación de tabla homologada
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


-- =========================================================================
-- PILAR 2: DIAGNÓSTICO DEL NEGOCIO (El Pasado - Descriptivo)
-- Objetivo: Medir el rendimiento global, totales históricos y sucursales clave.
-- =========================================================================

-- A. KPIs Financieros Globales

SELECT SUM([OutletSales]) AS ingreso_historico
FROM [RetailDB].[dbo].[Staging_Train_Clean];

SELECT AVG([OutletSales]) AS venta_promedio_transaccion
FROM [RetailDB].[dbo].[Staging_Train_Clean];


-- B. Rendimiento por Zona y Antigüedad

SELECT TOP 1 
    [LocationType] AS tipo_ubicacion,
    SUM([OutletSales]) AS ingreso_total
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [LocationType] 
ORDER BY ingreso_total DESC;

SELECT 
    [EstablishmentYear] AS anio_fundacion,
    SUM([OutletSales]) AS ingreso_total
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [EstablishmentYear] 
ORDER BY ingreso_total DESC;


-- C. Top Sucursales por Ingresos

SELECT TOP 3 
    [OutletID] AS tienda,
    SUM([OutletSales]) AS ingreso_total
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [OutletID] 
ORDER BY ingreso_total DESC;

SELECT 
    [OutletSize] AS tamano_tienda,
    SUM([OutletSales]) AS ingreso_total
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [OutletSize] 
ORDER BY ingreso_total DESC;


-- D. Segmentación de Tiendas en Cuartiles (NTILE)

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


-- =========================================================================
-- PILAR 3: DETECTAR OPORTUNIDADES Y ANOMALÍAS (Insights de Productos)
-- Objetivo: Encontrar productos estrella, categorías y el impacto del inventario.
-- =========================================================================

-- A. Productos Estrella vs. de Baja Salida (DENSE_RANK)

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


-- B. Participación por Categoría (SUM OVER vacío)

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


-- C. Top 3 por Categoría (ROW_NUMBER con PARTITION BY)

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
WHERE ranking <= 3
ORDER BY ProductType, ranking ASC;


-- D. Impacto de la Grasa en las Ventas

SELECT 
    FatContent AS tipo_grasa,
    COUNT([ProductID]) AS total_productos_vendidos,
    SUM([OutletSales]) AS ventas_totales,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio_por_transaccion
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY FatContent
ORDER BY ventas_totales DESC;


-- =========================================================================
-- PILAR 4: VALOR PARA EL NEGOCIO (Estrategia y Eficiencia Operativa)
-- Objetivo: Tomar decisiones sobre formatos de tienda y espacios de exhibición.
-- =========================================================================

-- A. Comparativa de Tipos de Tienda (Supermercados vs. Conveniencia)

SELECT 
    [OutletType] AS tipo_tienda,
    COUNT([ProductID]) AS total_transacciones_o_productos,
    SUM([OutletSales]) AS ventas_totales,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio_por_producto
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [OutletType]
ORDER BY venta_promedio_por_producto DESC;


-- B. Visibilidad vs. Ventas (Análisis de anomalías en pasillos)

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



-- =========================================================================
-- PILAR 5: ESTIMACIÓN Y TENDENCIA PREDICTIVA BASADA EN EL PRECIO (MRP)
-- Objetivo: Estimar el comportamiento de ventas esperado según el valor del producto (MRP).
-- =========================================================================
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


-- =========================================================================
-- PILAR 5.1: ESTIMACIÓN PREDICTIVA Y FACTOR DE ROTACIÓN POR CATEGORÍA
-- Objetivo: Cruzar el volumen y rendimiento comercial específico por cada tipo de producto.
-- =========================================================================

SELECT 
    [ProductType] AS categoria_producto,
    COUNT([ProductID]) AS total_variedad_productos,
    CAST(AVG([MRP]) AS DECIMAL(10,2)) AS precio_mrp_promedio,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio,
    CAST(SUM([OutletSales]) / NULLIF(SUM([MRP]), 0) AS DECIMAL(10,4)) AS factor_retorno_categoria
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [ProductType]
ORDER BY venta_promedio DESC;


-- =========================================================================
-- PILAR 5.1.1: DRILL-DOWN DE PRODUCTOS ZOMBIES O DE BAJA ROTACIÓN
-- Objetivo: Identificar los códigos específicos que arrastran el rendimiento a la baja en una categoría.
-- =========================================================================

SELECT 
    [ProductType] AS categoria,
    [ProductID] AS producto_zombie,
    [MRP] AS precio_etiqueta,
    [OutletSales] AS ventas_totales_historicas,
    CAST([OutletSales] / NULLIF([MRP], 0) AS DECIMAL(10,2)) AS factor_individual
FROM [RetailDB].[dbo].[Staging_Train_Clean]
WHERE [ProductType] = 'Breakfast'
ORDER BY factor_individual ASC;


-- =========================================================================
-- PILAR 5.2: CONCENTRACIÓN DE VENTAS (Ley de Pareto)
-- Objetivo: Ver qué porcentaje de las ventas totales aporta cada categoría al negocio.
-- =========================================================================


WITH VentasPorCategoria AS (
    SELECT 
        [ProductType] AS categoria_producto,
        SUM([OutletSales]) AS ventas_totales_categoria
    FROM [RetailDB].[dbo].[Staging_Train_Clean]
    GROUP BY [ProductType]
)
SELECT 
    categoria_producto,
    CAST(ventas_totales_categoria AS DECIMAL(12,2)) AS ventas_totales,
    SUM(ventas_totales_categoria) OVER() as ventas_totales_General,
    CAST((ventas_totales_categoria * 100.0) / SUM(ventas_totales_categoria) OVER() AS DECIMAL(5,2)) AS porcentaje_aporte_total
FROM VentasPorCategoria
ORDER BY porcentaje_aporte_total DESC;

-- =========================================================================
-- PILAR 5.3: ESTABILIDAD Y RIESGO COMERCIAL
-- Objetivo: Medir la volatilidad y dispersión de las ventas dentro de cada categoría.
-- =========================================================================

SELECT 
    [ProductType] AS categoria_producto,
    COUNT([ProductID]) AS total_variedad_productos,
    CAST(AVG([OutletSales]) AS DECIMAL(10,2)) AS venta_promedio,
    CAST(STDEV([OutletSales]) AS DECIMAL(10,2)) AS desviacion_ventas,
    CAST((STDEV([OutletSales]) / AVG([OutletSales])) * 100 AS DECIMAL(5,2)) AS indice_volatilidad_porcentaje
FROM [RetailDB].[dbo].[Staging_Train_Clean]
GROUP BY [ProductType]
ORDER BY indice_volatilidad_porcentaje DESC;


-- =========================================================================
-- PILAR 5.4: IMPACTO DE LA VISIBILIDAD EN EL ANAQUEL
-- Objetivo: Evaluar si los productos ubicados en zonas de mayor exposición generan más ventas.
-- =========================================================================
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
