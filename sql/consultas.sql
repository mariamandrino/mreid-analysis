-- =============================================================================
-- MREID — Análisis de actividad empresarial multinacional
-- Curso de Data Analytics EOI 2025-26 | Mariam Andrino Lahlou
-- =============================================================================
-- Descripción del dataset:
--   Cada fila resume la actividad anual de filiales multinacionales agrupadas
--   por país de origen (country_o), país de destino (country_d), sector (naics2)
--   y año (year). Cubre 185 países y 25 sectores entre 2010 y 2021.
--
-- Consideraciones importantes:
--   - Los valores 0 son válidos: indican ausencia de actividad registrada
--     o falta de datos reportados, no errores en los datos.
--   - Cuando country_o = country_d → inversión doméstica.
--     Cuando country_o ≠ country_d → inversión internacional.
--   - Las variables monetarias están expresadas en miles de USD (thUSD).
-- =============================================================================


-- =============================================================================
-- SECCIÓN 1 — CREACIÓN DE TABLAS
-- =============================================================================

CREATE TABLE currency_exchange_rates (
    date DATE,
    usd  DECIMAL(10,8),
    eur  DECIMAL(10,8)
);

-- Tabla principal con datos de actividad de empresas multinacionales.
-- Clave primaria compuesta: combinación única de origen, destino, año y sector.
CREATE TABLE mreid_database (
    iso3_o                          CHAR(3)        NOT NULL,
    country_o                       VARCHAR(100)   NOT NULL,
    iso3_d                          CHAR(3)        NOT NULL,
    country_d                       VARCHAR(100)   NOT NULL,
    year                            INT            NOT NULL,
    naics2                          INT            NOT NULL,
    naics2description               VARCHAR(255),
    extensive                       INT,
    greenfield                      INT,
    mergers                         INT,
    OperatingrevenueTurnover        NUMERIC(18,6),
    OperatingrevenueTurnover_green  NUMERIC(18,6),
    OperatingrevenueTurnover_mergers NUMERIC(18,6),
    TotalassetsthUSD                NUMERIC(18,6),
    TotalassetsthUSD_green          NUMERIC(18,6),
    TotalassetsthUSD_mergers        NUMERIC(18,6),
    Numberofemployees               INT,
    Numberofemployees_green         INT,
    Numberofemployees_mergers       INT,
    FixedassetsthUSD                NUMERIC(18,6),
    FixedassetsthUSD_green          NUMERIC(18,6),
    FixedassetsthUSD_mergers        NUMERIC(18,6),
    PRIMARY KEY (iso3_o, iso3_d, year, naics2)
);


-- =============================================================================
-- SECCIÓN 2 — EXPLORACIÓN INICIAL
-- =============================================================================
-- Consultas de reconocimiento del dataset: volumen de datos, dimensiones
-- disponibles y una primera vista de los registros.
-- =============================================================================

-- Vista general de la tabla completa
SELECT * FROM mreid_database md;

-- Volumen total y métricas agregadas de ejemplo (Canadá, 2016)
-- Útil para verificar que la carga de datos se realizó correctamente
SELECT
    SUM(md.Numberofemployees)                                AS empleados,
    SUM(md.TotalassetsthUSD)                                 AS inversion,
    SUM(md.OperatingrevenueTurnover)                         AS facturacion,
    SUM(md.OperatingrevenueTurnover) / SUM(md.Numberofemployees) AS facturacion_empleado
FROM mreid_database md
WHERE md.country_d = 'Canada'
  AND year = 2016;

-- Países de destino disponibles en el dataset
SELECT DISTINCT country_d
FROM mreid_database m;

-- Sectores económicos disponibles en el dataset
SELECT DISTINCT naics2description
FROM mreid_database m;


-- =============================================================================
-- SECCIÓN 3 — VALIDACIÓN DE CALIDAD DE DATOS
-- =============================================================================
-- Antes de interpretar cualquier resultado es importante entender el estado
-- real de los datos: cuántos registros tienen valores cero o nulos en las
-- métricas clave, y qué impacto tiene eso en los análisis posteriores.
--
-- Nota metodológica:
--   En este dataset los ceros pueden significar dos cosas distintas:
--   (a) ausencia real de actividad registrada → dato válido
--   (b) métrica no reportada por la empresa → equivale a un nulo
--   No es posible distinguir ambos casos desde los datos. Esta limitación
--   es inherente al dataset y debe tenerse en cuenta al interpretar resultados
--   extremos, especialmente en países con pocas observaciones.
-- =============================================================================

-- Volumen total de registros cargados
SELECT COUNT(*) AS total_registros
FROM mreid_database;

-- Cobertura temporal: años disponibles en el dataset
SELECT DISTINCT year
FROM mreid_database
ORDER BY year;

-- Número de países de destino distintos
SELECT COUNT(DISTINCT country_d) AS total_paises_destino
FROM mreid_database;

-- Número de sectores distintos
SELECT COUNT(DISTINCT naics2description) AS total_sectores
FROM mreid_database;

-- -----------------------------------------------------------------------------
-- Porcentaje de registros con valor cero en las métricas clave
-- Un porcentaje alto de ceros en un país o sector reduce la fiabilidad
-- de cualquier análisis de ratios sobre ese subconjunto
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                                        AS total_registros,
    SUM(CASE WHEN Numberofemployees        = 0 THEN 1 ELSE 0 END)  AS empleados_cero,
    SUM(CASE WHEN OperatingrevenueTurnover = 0 THEN 1 ELSE 0 END)  AS facturacion_cero,
    SUM(CASE WHEN TotalassetsthUSD         = 0 THEN 1 ELSE 0 END)  AS inversion_cero,
    SUM(CASE WHEN extensive                = 0 THEN 1 ELSE 0 END)  AS empresas_cero,
    ROUND(100.0 * SUM(CASE WHEN Numberofemployees        = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_empleados_cero,
    ROUND(100.0 * SUM(CASE WHEN OperatingrevenueTurnover = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_facturacion_cero,
    ROUND(100.0 * SUM(CASE WHEN TotalassetsthUSD         = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_inversion_cero,
    ROUND(100.0 * SUM(CASE WHEN extensive                = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_empresas_cero
FROM mreid_database;

-- -----------------------------------------------------------------------------
-- Porcentaje de registros con valor NULL en las métricas clave
-- Los nulos explícitos son menos frecuentes que los ceros en este dataset
-- pero igualmente excluyen registros de los cálculos de ratios
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                                          AS total_registros,
    SUM(CASE WHEN Numberofemployees        IS NULL THEN 1 ELSE 0 END) AS empleados_nulo,
    SUM(CASE WHEN OperatingrevenueTurnover IS NULL THEN 1 ELSE 0 END) AS facturacion_nulo,
    SUM(CASE WHEN TotalassetsthUSD         IS NULL THEN 1 ELSE 0 END) AS inversion_nulo,
    SUM(CASE WHEN extensive                IS NULL THEN 1 ELSE 0 END) AS empresas_nulo,
    ROUND(100.0 * SUM(CASE WHEN Numberofemployees        IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_empleados_nulo,
    ROUND(100.0 * SUM(CASE WHEN OperatingrevenueTurnover IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_facturacion_nulo,
    ROUND(100.0 * SUM(CASE WHEN TotalassetsthUSD         IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_inversion_nulo,
    ROUND(100.0 * SUM(CASE WHEN extensive                IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_empresas_nulo
FROM mreid_database;

-- -----------------------------------------------------------------------------
-- Países con bajo volumen de observaciones válidas para el ratio
-- facturación/empleado (empleados > 0 y facturación > 0)
-- Los países con pocas observaciones válidas son más susceptibles de aparecer
-- en posiciones extremas del ranking sin que eso refleje una tendencia real
-- -----------------------------------------------------------------------------
SELECT
    country_d,
    COUNT(*)                                                                    AS total_registros,
    SUM(CASE WHEN Numberofemployees > 0 AND OperatingrevenueTurnover > 0
             THEN 1 ELSE 0 END)                                                 AS registros_validos_ratio,
    ROUND(100.0 * SUM(CASE WHEN Numberofemployees > 0 AND OperatingrevenueTurnover > 0
                           THEN 1 ELSE 0 END) / COUNT(*), 2)                   AS pct_registros_validos
FROM mreid_database
GROUP BY country_d
ORDER BY registros_validos_ratio ASC
LIMIT 20;

-- -----------------------------------------------------------------------------
-- Registros que quedarían excluidos de los análisis de ratios
-- Cuantifica el impacto de los filtros aplicados en las consultas analíticas
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                                                AS total_registros,
    SUM(CASE WHEN Numberofemployees > 0 AND OperatingrevenueTurnover > 0
             THEN 1 ELSE 0 END)                                             AS incluidos_en_ratio,
    COUNT(*) - SUM(CASE WHEN Numberofemployees > 0 AND OperatingrevenueTurnover > 0
                        THEN 1 ELSE 0 END)                                  AS excluidos_del_ratio,
    ROUND(100.0 * SUM(CASE WHEN Numberofemployees > 0 AND OperatingrevenueTurnover > 0
                           THEN 1 ELSE 0 END) / COUNT(*), 2)               AS pct_incluidos
FROM mreid_database;


-- =============================================================================
-- SECCIÓN 4 — ANÁLISIS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Pregunta 1
-- ¿Cuál es el top 10 de países donde el ratio "facturación por empleado"
-- es más alto?
-- -----------------------------------------------------------------------------
-- Se excluyen los registros con empleados o facturación igual a cero para
-- evitar distorsiones en el cálculo del ratio. Los resultados extremos del
-- top pueden estar influidos por países con pocas observaciones válidas
-- (ver sección de validación).
-- -----------------------------------------------------------------------------
SELECT
    country_d,
    SUM(OperatingrevenueTurnover)                                        AS facturacion_total,
    SUM(Numberofemployees)                                               AS empleados_total,
    SUM(OperatingrevenueTurnover) / SUM(Numberofemployees)               AS facturacion_por_empleado
FROM mreid_database
WHERE Numberofemployees        > 0
  AND OperatingrevenueTurnover > 0
GROUP BY country_d
ORDER BY facturacion_por_empleado DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- Pregunta 2
-- ¿Cuál es el bottom 10 de países donde el ratio "facturación por empleado"
-- es más bajo?
-- -----------------------------------------------------------------------------
-- Misma lógica que la pregunta 1 con ordenación ascendente. Los países en
-- las posiciones más bajas tienden a ser economías con menor renta y
-- actividad más intensiva en mano de obra.
-- -----------------------------------------------------------------------------
SELECT
    country_d,
    SUM(OperatingrevenueTurnover)                                        AS facturacion_total,
    SUM(Numberofemployees)                                               AS empleados_total,
    SUM(OperatingrevenueTurnover) / SUM(Numberofemployees)               AS facturacion_por_empleado
FROM mreid_database
WHERE Numberofemployees        > 0
  AND OperatingrevenueTurnover > 0
GROUP BY country_d
ORDER BY facturacion_por_empleado ASC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- Pregunta 3
-- ¿Cuáles son los 5 sectores con mejor evolución entre 2010 y 2021 en la
-- inversión por empresa (TotalassetsthUSD / extensive) de inversión
-- doméstica en España?
-- -----------------------------------------------------------------------------
-- La evolución se mide como la diferencia entre la inversión por empresa
-- en 2021 y en 2010. Un valor positivo indica crecimiento.
--
-- Versión simple: datos anuales completos (útil para ver la serie temporal)
-- -----------------------------------------------------------------------------
SELECT
    m.naics2description                              AS sector,
    m.year                                           AS año,
    SUM(m.extensive)                                 AS numero_empresas,
    SUM(m.TotalassetsthUSD)                          AS inversion_total,
    SUM(m.TotalassetsthUSD) / SUM(m.extensive)       AS inversion_por_empresa
FROM mreid_database m
WHERE m.country_o = m.country_d   -- inversión doméstica
  AND m.iso3_d    = 'ESP'
  AND m.year BETWEEN 2010 AND 2021
GROUP BY sector, año
ORDER BY año;

-- Versión con subquery: top 5 sectores por crecimiento 2010-2021
SELECT
    sector,
    SUM(CASE WHEN year = 2021 THEN inversion_por_empresa ELSE 0 END) -
    SUM(CASE WHEN year = 2010 THEN inversion_por_empresa ELSE 0 END)
        AS crecimiento_inversion_por_empresa_2010_2021
FROM (
    SELECT
        m.naics2description                            AS sector,
        m.year,
        SUM(m.TotalassetsthUSD) / SUM(m.extensive)    AS inversion_por_empresa
    FROM mreid_database m
    WHERE m.country_o = m.country_d   -- inversión doméstica
      AND m.iso3_d    = 'ESP'
      AND m.year IN (2010, 2021)
    GROUP BY sector, year
) AS subquery
GROUP BY sector
ORDER BY crecimiento_inversion_por_empresa_2010_2021 DESC
LIMIT 5;


-- -----------------------------------------------------------------------------
-- Pregunta 4
-- ¿Cuáles son los 5 sectores con peor evolución entre 2010 y 2021 en la
-- inversión por empresa (TotalassetsthUSD / extensive) de inversión
-- internacional en España?
-- -----------------------------------------------------------------------------
-- Misma lógica que la pregunta 3 pero para inversión internacional
-- (country_o ≠ country_d) y ordenando de forma ascendente para obtener
-- los sectores con mayor retroceso.
-- -----------------------------------------------------------------------------

-- Versión simple: datos anuales completos
SELECT
    m.naics2description                              AS sector,
    m.year                                           AS año,
    SUM(m.extensive)                                 AS numero_empresas,
    SUM(m.TotalassetsthUSD)                          AS inversion_total
FROM mreid_database m
WHERE m.country_o != m.country_d   -- inversión internacional
  AND m.iso3_d     = 'ESP'
  AND m.year BETWEEN 2010 AND 2021
GROUP BY sector, año
ORDER BY año, numero_empresas ASC;

-- Versión con subquery: bottom 5 sectores por crecimiento 2010-2021
SELECT
    sector,
    SUM(CASE WHEN year = 2021 THEN inversion_por_empresa ELSE 0 END) -
    SUM(CASE WHEN year = 2010 THEN inversion_por_empresa ELSE 0 END)
        AS crecimiento_inversion_por_empresa_2010_2021
FROM (
    SELECT
        m.naics2description                            AS sector,
        m.year,
        SUM(m.TotalassetsthUSD) / SUM(m.extensive)    AS inversion_por_empresa
    FROM mreid_database m
    WHERE m.country_o != m.country_d   -- inversión internacional
      AND m.iso3_d     = 'ESP'
      AND m.year IN (2010, 2021)
    GROUP BY sector, year
) AS subquery
GROUP BY sector
ORDER BY crecimiento_inversion_por_empresa_2010_2021 ASC   -- peor evolución primero
LIMIT 5;


-- -----------------------------------------------------------------------------
-- Pregunta 5
-- ¿Cuál es el importe en euros de la inversión extranjera en la Península
-- Ibérica (España, Portugal y Andorra) en el sector Finance and Insurance
-- durante el año 2020?
-- -----------------------------------------------------------------------------
-- Se hace un JOIN con la tabla de tipos de cambio usando el año como clave
-- de unión para convertir los activos totales de USD a EUR.
-- La inversión extranjera se filtra con country_o ≠ country_d.
-- -----------------------------------------------------------------------------
SELECT
    m.country_d,
    m.year                                             AS año,
    m.naics2description                                AS sector,
    SUM(m.TotalassetsthUSD)                            AS inversion_total_usd,
    SUM(m.TotalassetsthUSD) * c.eur                    AS inversion_total_eur
FROM mreid_database m
JOIN currency_exchange_rates c ON YEAR(c.date) = m.year
WHERE m.country_o != m.country_d
  AND m.country_d IN ('Spain', 'Portugal', 'Andorra')
  AND m.naics2description = 'Finance and Insurance '
  AND m.year = 2020
GROUP BY m.country_d, m.year, m.naics2description, c.eur;


-- -----------------------------------------------------------------------------
-- Pregunta 6
-- ¿Cuál es el importe en euros de la facturación por empleado en Italia
-- en el sector Real Estate durante el año 2015?
-- -----------------------------------------------------------------------------
-- Se usa NULLIF(SUM(Numberofemployees), 0) para evitar errores de división
-- por cero en caso de que el total de empleados sea 0.
-- El JOIN con la tabla de divisas permite expresar el resultado en EUR.
-- -----------------------------------------------------------------------------

-- Consulta auxiliar: verificar sectores disponibles en Italia para 2015
SELECT DISTINCT naics2description
FROM mreid_database
WHERE country_d = 'Italy'
  AND year      = 2015;

-- Consulta principal
SELECT
    m.country_d,
    m.year                                                              AS año,
    m.naics2description                                                 AS sector,
    SUM(m.OperatingrevenueTurnover)                                     AS facturacion_total_usd,
    SUM(m.Numberofemployees)                                            AS empleados_total,
    SUM(m.OperatingrevenueTurnover) /
        NULLIF(SUM(m.Numberofemployees), 0)                             AS facturacion_por_empleado_usd,
    (SUM(m.OperatingrevenueTurnover) /
        NULLIF(SUM(m.Numberofemployees), 0)) * c.eur                    AS facturacion_por_empleado_eur
FROM mreid_database m
JOIN currency_exchange_rates c ON YEAR(c.date) = m.year
WHERE m.country_d       = 'Italy'
  AND m.naics2description = 'Real Estate '
  AND m.year            = 2015
GROUP BY m.country_d, m.year, m.naics2description, c.eur;
