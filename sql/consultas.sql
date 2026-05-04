-- ============================================================
-- ANÁLISIS: Capital real vs. capital en papel
-- MREID Public Release 1.0 · USITC
-- ============================================================
-- El MREID agrega actividad multinacional por par origen-destino,
-- sector y año. Una lectura superficial del dataset trata a todos
-- los países destino como equivalentes. Este análisis cuestiona
-- esa equivalencia: ¿reciben todos los países el mismo tipo de
-- inversión, o hay jurisdicciones que acumulan capital sin
-- generar actividad económica real?
-- ============================================================


-- ------------------------------------------------------------
-- QUERY 1: Perfil de inversión por país destino
-- Detecta el patrón "capital sin trabajo": jurisdicciones donde
-- la inversión por empleado es órdenes de magnitud superior a
-- la media global, señal de que el capital se registra ahí
-- pero el trabajo ocurre en otro lugar.
-- ------------------------------------------------------------

SELECT
    country_d AS destination_country,
    SUM(TotalassetsthUSD) AS total_investment_usd,
    SUM(Numberofemployees) AS total_employees,
    SUM(extensive) AS total_subsidiaries,
    ROUND(SUM(TotalassetsthUSD) / NULLIF(SUM(Numberofemployees), 0), 2) AS investment_per_employee_usd,
    ROUND(SUM(TotalassetsthUSD) / NULLIF(SUM(extensive), 0), 2) AS investment_per_subsidiary_usd
FROM mreid_database
WHERE country_o != country_d
GROUP BY country_d
HAVING SUM(TotalassetsthUSD) > 0
ORDER BY investment_per_employee_usd DESC;


-- ------------------------------------------------------------
-- QUERY 2: Exportadores de capital — volumen vs. empleo generado
-- Clasifica los países origen por cuánto capital exportan y
-- cuántos empleos generan fuera. La distancia entre ambas
-- métricas define si un país exporta trabajo real o papel.
-- ------------------------------------------------------------

SELECT
    country_o AS origin_country,
    SUM(TotalassetsthUSD) AS total_capital_exported_usd,
    SUM(Numberofemployees) AS total_jobs_generated_abroad,
    SUM(extensive) AS total_subsidiaries_abroad,
    ROUND(SUM(TotalassetsthUSD) / NULLIF(SUM(Numberofemployees), 0), 2) AS capital_per_job_usd
FROM mreid_database
WHERE country_o != country_d
GROUP BY country_o
HAVING SUM(TotalassetsthUSD) > 0
ORDER BY total_capital_exported_usd DESC
LIMIT 30;
