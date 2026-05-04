# mreid-analysis

Pipeline de datos end-to-end y análisis propio sobre el dataset MREID
(Multinational Research on Enterprise and Industry Data), publicado por
la Comisión de Comercio Internacional de EE.UU.

El MREID recoge la actividad de empresas multinacionales en 185 países,
25 sectores y 12 años (2010–2021), a partir de la base de datos Orbis
de Bureau van Dijk. Más de 329.000 registros. ~1,2GB en CSV.

---

## De qué va esto

Una lectura estándar de este dataset produce rankings: los países que
más inversión reciben, los sectores con mayor facturación. Útil, pero
no interesante.

Este proyecto parte de una pregunta distinta: **¿es todo el capital de
este dataset el mismo tipo de capital?**

La respuesta es no. Hay países que atraen inversión productiva: fábricas,
oficinas, personas en nómina. Y hay jurisdicciones que acumulan capital
en papel: holdings, estructuras societarias, vehículos financieros que
registran activos sin generar actividad económica real.

Luxemburgo recibe 59.664 USD de inversión por cada empleado registrado.
Alemania recibe 1.052 USD. Ambos aparecen en el mismo dataset, tratados
como equivalentes. No lo son.

---

## Stack técnico

| Capa | Tecnología |
|---|---|
| Orquestación | n8n (self-hosted, Docker) |
| Almacenamiento | MySQL |
| Fuente de datos | USITC MREID Public Release 1.0 |
| Tipo de cambio | currencyapi.com |
| Análisis | SQL |
| Visualización | Power BI + web propia |

---

## Pipelines

**`mreid_workflow`** — Descarga el CSV completo desde el servidor del
USITC, lo extrae, lo procesa en batches de 20.000 filas y lo carga en
MySQL. Se ejecuta una vez para poblar la base de datos.

**`currency_workflow`** — Consulta el tipo de cambio USD/EUR histórico
para cualquier fecha y hace upsert en una tabla auxiliar. Permite
convertir cifras del dataset a euros para cualquier año.

---

## Análisis

El núcleo analítico del proyecto son dos queries que operan sobre el
dataset completo y clasifican países según el tipo de capital que mueven.

La metodología y los hallazgos están documentados en la web del proyecto.

---

## Web

[mreid-analysis.com](#) — análisis completo, visualizaciones interactivas
y conclusiones.

---

## Datos

El dataset MREID es de acceso público:
https://www.usitc.gov/data/gravity/mreid.htm

Este repositorio no incluye el CSV original por su tamaño (~1,2GB).
El workflow de n8n lo descarga directamente desde el servidor del USITC.