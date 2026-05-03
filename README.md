# MREID — Análisis de actividad empresarial multinacional

Proyecto de análisis de datos desarrollado como caso práctico del **Curso de Data Analytics EOI 2025–26**.

Cubre el pipeline completo desde la ingesta de datos hasta el análisis SQL: ETL automatizado con n8n, almacenamiento relacional en MySQL y visualización interactiva en Power BI.

---

## Descripción del proyecto

La [base de datos MREID](https://www.usitc.gov/data/gravity/mreid.htm) (Multinational Revenue and Investment Database) contiene datos anuales sobre la actividad de empresas multinacionales en **185 países** y **25 sectores económicos** para el periodo **2010–2021**. Cada fila resume la actividad de filiales agrupadas por país de origen, país de destino, sector y año.

Este proyecto:
1. **Ingesta** el dataset MREID (329.543 registros) y los tipos de cambio históricos USD/EUR en MySQL mediante workflows automatizados en n8n
2. **Analiza** los datos con consultas SQL sobre productividad empresarial, evolución sectorial e inversión doméstica vs. internacional en España
3. **Visualiza** los principales indicadores en un dashboard de Power BI con filtros dinámicos por país, sector y año

---

## Stack tecnológico

| Capa | Herramienta |
|---|---|
| Orquestación ETL | [n8n](https://n8n.io/) (autoalojado en Docker) |
| Base de datos | MySQL (contenedor Docker) |
| Cliente SQL | DBeaver |
| Visualización | Power BI Desktop |
| Datos de divisas | [currencyapi.com](https://currencyapi.com/) |
| Datos fuente | [USITC MREID v1.0](https://www.usitc.gov/data/gravity/mreid/mreid_public_release_1.0.csv) |

---

## Estructura del repositorio

```
mreid-analysis/
│
├── README.md
│
├── n8n/
│   ├── mreid_workflow.json          # Descarga CSV de MREID e inserta en MySQL por lotes
│   └── currency_workflow.json       # Obtiene tipos de cambio USD/EUR de la API e inserta en MySQL
│
├── sql/
│   └── consultas.sql                # Definición de tablas + 6 consultas de análisis
│
└── docs/
    └── caso_practico.pdf            # Documentación completa del proyecto con metodología y resultados
```

---

## Proceso ETL

### Workflow 1 — Dataset MREID

El workflow se ejecuta íntegramente en n8n y sigue esta secuencia:

```
Trigger manual
    ├── Limpiar tabla (TRUNCATE mreid_database)
    └── Descargar CSV desde USITC
            └── Parsear filas del CSV
                    └── Dividir en lotes de 20.000 filas  ← Loop Over Items
                            └── Convertir lote en chunk de archivo
                                    └── Extraer filas del chunk
                                            └── Insertar en MySQL (automapeo)
```

El procesamiento por lotes es necesario porque el dataset contiene 329.543 registros. Dividirlos en bloques de 20.000 evita problemas de memoria y mantiene n8n estable durante toda la carga.

### Workflow 2 — Tipos de cambio

Obtiene el tipo de cambio USD/EUR para cada año (2010–2021) desde el endpoint histórico de currencyapi.com, transforma la respuesta JSON y inserta una fila por año en la tabla `currency_exchange_rates`.

> **Nota:** La clave de API no está incluida en este repositorio. Es necesario registrarse en [currencyapi.com](https://currencyapi.com/) y usar una clave propia.

---

## Esquema de base de datos

### `mreid_database`

| Columna | Tipo | Descripción |
|---|---|---|
| `iso3_o` / `country_o` | CHAR(3) / VARCHAR | País de origen (código ISO + nombre) |
| `iso3_d` / `country_d` | CHAR(3) / VARCHAR | País de destino (código ISO + nombre) |
| `year` | INT | Año (2010–2021) |
| `naics2` / `naics2description` | INT / VARCHAR | Código y descripción del sector NAICS |
| `extensive` | INT | Número total de filiales |
| `greenfield` | INT | Filiales de nueva creación |
| `mergers` | INT | Filiales procedentes de fusiones y adquisiciones |
| `OperatingrevenueTurnover` | NUMERIC | Ingresos operativos totales, sin impuestos (miles de USD) |
| `TotalassetsthUSD` | NUMERIC | Activos totales — aproximación a la inversión (miles de USD) |
| `Numberofemployees` | INT | Total de empleados en todas las filiales |
| `FixedassetsthUSD` | NUMERIC | Activos fijos (miles de USD) |
| `*_green` / `*_mergers` | NUMERIC/INT | Mismas métricas desglosadas por greenfield / fusiones |

Clave primaria: `(iso3_o, iso3_d, year, naics2)`

> Dos consideraciones importantes sobre este dataset:
> - Los valores cero son válidos e indican ausencia de actividad o falta de datos reportados, no errores.
> - Cuando `country_o = country_d`, la fila representa **inversión doméstica**. Cuando difieren, es **inversión internacional**.

### `currency_exchange_rates`

| Columna | Tipo | Descripción |
|---|---|---|
| `date` | DATE | Último día de cada año |
| `usd` | DECIMAL | Tipo USD (base = 1) |
| `eur` | DECIMAL | Tipo EUR/USD para ese año |

---

## Análisis SQL

El archivo `sql/consultas.sql` incluye seis consultas analíticas:

| # | Pregunta | Técnica principal |
|---|---|---|
| 1 | Top 10 países por facturación por empleado | `GROUP BY`, agregación, `ORDER BY DESC` |
| 2 | Bottom 10 países por facturación por empleado | Igual, `ORDER BY ASC` |
| 3 | Top 5 sectores con mejor evolución en inversión doméstica en España (2010–2021) | Subquery con pivot mediante `CASE WHEN` |
| 4 | Bottom 5 sectores con peor evolución en inversión internacional en España (2010–2021) | Mismo patrón, `country_o != country_d` |
| 5 | Inversión extranjera en la Península Ibérica — Finanzas y Seguros 2020 en EUR | `JOIN` con tabla de tipos de cambio |
| 6 | Facturación por empleado en el sector inmobiliario de Italia, 2015 en EUR | `JOIN` + `NULLIF` para división segura |

---

## Cómo reproducir el proyecto

### Requisitos previos

- Docker y Docker Compose
- Instancia de n8n (local o en la nube)
- Instancia de MySQL conectada a n8n
- Power BI Desktop (Windows)
- Clave de API gratuita de [currencyapi.com](https://currencyapi.com/)

### Pasos

1. **Crear las tablas** — ejecutar los `CREATE TABLE` del inicio de `sql/consultas.sql` en tu instancia de MySQL.

2. **Importar el workflow de MREID** — en n8n, ir a *Workflows → Importar desde archivo* y seleccionar `n8n/mreid_workflow.json`. Actualizar el nodo de credenciales MySQL con los datos de tu entorno y ejecutar.

3. **Importar el workflow de divisas** — mismo proceso con `n8n/currency_workflow.json`. Añadir tu clave de currencyapi.com en el nodo HTTP Request y ejecutar una vez por año (2010–2021) cambiando el parámetro `date` en cada ejecución.

4. **Ejecutar las consultas SQL** — abrir `sql/consultas.sql` en DBeaver o cualquier cliente MySQL conectado a tu base de datos.

5. **Abrir el dashboard** — conectar Power BI Desktop a tu instancia MySQL (*Obtener datos → MySQL*), seleccionar ambas tablas y cargar el archivo `.pbix`.

---

## Principales hallazgos

- **Mayor facturación por empleado:** Curazao, Siria y Singapur lideran a nivel global, aunque las primeras posiciones están influidas por un bajo volumen de observaciones.
- **Menor facturación por empleado:** Cuba, Paraguay y Myanmar, reflejo de economías con menor renta y actividad más intensiva en mano de obra.
- **Inversión doméstica en España:** Finanzas y Seguros registró el mayor crecimiento en inversión por empresa entre 2010 y 2021 (+592.223 miles de USD/empresa).
- **Inversión internacional en España:** Utilities experimentó el mayor retroceso (−30.099 miles de USD/empresa), seguido de Servicios Jurídicos.
- **Península Ibérica — Finanzas y Seguros 2020:** España recibió la mayor inversión extranjera (≈185M EUR), seguida de Portugal (≈130M EUR) y Andorra (≈770K EUR).
- **Sector inmobiliario en Italia, 2015:** Facturación por empleado de aproximadamente 719 EUR.

---

## Notas y limitaciones

- Los valores monetarios del dataset fuente están expresados en **miles de dólares estadounidenses (USD)**. Los resultados en EUR utilizan el tipo de cambio de fin de año correspondiente a cada periodo.
- El análisis trabaja con datos agregados por país, sector y año — el dataset MREID no contiene datos a nivel de empresa individual.
- Los valores cero en facturación y empleados se excluyen de los cálculos de ratios para evitar distorsiones, pero su presencia en el dataset es esperada y válida.

---

## Autora

**Mariam Andrino Lahlou**  
Curso de Data Analytics EOI 2025–26
