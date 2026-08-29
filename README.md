# 🎬 Videoclub — SQL Server Portfolio (Proyecto Insignia)

Proyecto de análisis de datos end-to-end sobre una base de datos relacional de un
videoclub de alquiler de películas (14 tablas, +2.000 registros), diseñada desde
cero en español para este portfolio. Es el proyecto más completo de mi portfolio:
recorre todo el espectro de SQL, desde exploración básica hasta vistas,
procedimientos almacenados y análisis de negocio avanzado (segmentación de
clientes, detección de fuga), con un dashboard de Power BI como cierre.

## 🧰 Herramientas
- SQL Server 2022 (Express)
- SQL Server Management Studio (SSMS)
- Power BI Desktop *(próximamente)*

## 🗄️ Modelo de datos
Base de datos **Videoclub**, con 14 tablas relacionadas: `Pais`, `Ciudad`, `Direccion`,
`Categoria`, `Idioma`, `Actor`, `Pelicula`, `Pelicula_Actor`, `Pelicula_Categoria`,
`Sucursal`, `Personal`, `Cliente`, `Inventario`, `Alquiler`, `Pago`.

Diseño inspirado en la clásica base "Sakila", adaptado y traducido íntegramente al
español para SQL Server, con datos generados de forma realista:

| Entidad | Volumen |
|---|---|
| Películas | 220 |
| Actores | 90 |
| Clientes | 260 |
| Copias en inventario | 450 |
| Alquileres | 900 |
| Pagos | 860 |

El script completo de creación (`CREATE DATABASE`, tablas, índices y carga de
datos) está en [`00_Modelo_de_Datos/videoclub_sql_server.sql`](./00_Modelo_de_Datos/videoclub_sql_server.sql).

## 📁 Estructura del proyecto

| Carpeta | Contenido |
|---|---|
| `00_Modelo_de_Datos` | Script de creación de la base + diagrama entidad-relación |
| `01_Exploracion` | COUNT, DISTINCT, TOP — primer contacto con los datos |
| `02_Consultas_Basicas` | WHERE, LIKE, BETWEEN, IN, ORDER BY |
| `03_Agregaciones_GROUP_BY_HAVING` | SUM, AVG, MAX, MIN, GROUP BY, HAVING |
| `04_JOINS` | INNER JOIN, LEFT JOIN, joins múltiples |
| `05_Subconsultas_y_CTE` | Subconsultas, Common Table Expressions |
| `06_Funciones_de_Ventana` | ROW_NUMBER, RANK, LAG/LEAD, totales acumulados |
| `07_Vistas_y_Procedimientos_Almacenados` | VIEWs reutilizables y stored procedures |
| `08_Analisis_de_Negocio_Avanzado` | Segmentación RFM, clientes en riesgo de fuga, rentabilidad |
| `09_Power_BI` | Dashboard conectado a las vistas SQL *(próximamente)* |

Cada carpeta tiene su propio detalle de consultas con la pregunta de negocio que
responde cada una — el mismo formato que uso en mis otros dos proyectos.

## 🔗 Parte del portfolio completo
- [SQL Server Portfolio — AdventureWorks](https://github.com/timoteotrivex/sql-server-adventureworks-portfolio)
- [World Cup SQL Analysis](https://github.com/timoteotrivex/world-cup-sql-analysis)

## 👤 Autor
**Timoteo Trivellini** — Data Analyst | SQL Server | Power BI | Excel |
[LinkedIn](https://www.linkedin.com/in/timotrive42)
