/* ============================================================
   05. SUBCONSULTAS Y CTE — Videoclub
   Subconsultas escalares, correlacionadas, EXISTS, y Common Table
   Expressions (CTE) para organizar lógica en pasos legibles.
   ============================================================ */

USE Videoclub;
GO

-- Consulta 01: Películas con tarifa de alquiler mayor al promedio general
-- Objetivo de negocio: Gerencia comercial quiere identificar el segmento
-- de películas "por encima del promedio" para analizar su rentabilidad.
SELECT titulo, tarifa_alquiler
FROM Pelicula
WHERE tarifa_alquiler > (SELECT AVG(tarifa_alquiler) FROM Pelicula)
ORDER BY tarifa_alquiler DESC;
GO

-- Consulta 02: Clientes que gastaron más que el promedio general de gasto
-- Objetivo de negocio: Marketing quiere armar un segmento VIP con los
-- clientes que gastan por encima de la media, para ofrecerles beneficios.
SELECT cliente_id, SUM(monto) AS gasto_total
FROM Pago
GROUP BY cliente_id
HAVING SUM(monto) > (
    SELECT AVG(gasto_por_cliente)
    FROM (
        SELECT SUM(monto) AS gasto_por_cliente
        FROM Pago
        GROUP BY cliente_id
    ) AS gastos
)
ORDER BY gasto_total DESC;
GO

-- Consulta 03: Películas que nunca fueron alquiladas (con subconsulta NOT IN)
-- Objetivo de negocio: Compras necesita este listado para decidir si retira
-- esos títulos del catálogo o los promociona más.
SELECT titulo
FROM Pelicula
WHERE pelicula_id NOT IN (
    SELECT DISTINCT inv.pelicula_id
    FROM Inventario inv
    INNER JOIN Alquiler al ON al.inventario_id = inv.inventario_id
)
ORDER BY titulo;
GO

-- Consulta 04: Clientes que alquilaron al menos una vez en la sucursal "Videoclub Sur"
-- (subconsulta con EXISTS, correlacionada)
-- Objetivo de negocio: Esa sucursal quiere armar una base de clientes propios
-- para una promoción exclusiva del local.
SELECT cl.nombre, cl.apellido
FROM Cliente cl
WHERE EXISTS (
    SELECT 1
    FROM Alquiler al
    INNER JOIN Inventario inv ON inv.inventario_id = al.inventario_id
    INNER JOIN Sucursal s ON s.sucursal_id = inv.sucursal_id
    WHERE al.cliente_id = cl.cliente_id
      AND s.nombre = 'Videoclub Sur'
);
GO

-- Consulta 05: Actor con más películas en el catálogo (subconsulta escalar en WHERE)
-- Objetivo de negocio: Marketing quiere destacar al actor "estrella" del
-- catálogo en la vidriera del local.
SELECT a.nombre, a.apellido, COUNT(*) AS cantidad_peliculas
FROM Actor a
INNER JOIN Pelicula_Actor pa ON pa.actor_id = a.actor_id
GROUP BY a.actor_id, a.nombre, a.apellido
HAVING COUNT(*) = (
    SELECT MAX(cantidad) FROM (
        SELECT COUNT(*) AS cantidad
        FROM Pelicula_Actor
        GROUP BY actor_id
    ) AS conteos
);
GO

-- Consulta 06 (CTE): Ingresos totales por sucursal, usando una CTE para
-- separar el cálculo del filtro final
-- Objetivo de negocio: Dirección pide un reporte de sucursales que facturaron
-- por encima de los $600, mostrando el cálculo de forma clara y reutilizable.
WITH IngresosPorSucursal AS (
    SELECT s.nombre AS sucursal, SUM(p.monto) AS ingresos_totales
    FROM Pago p
    INNER JOIN Cliente c ON c.cliente_id = p.cliente_id
    INNER JOIN Sucursal s ON s.sucursal_id = c.sucursal_id
    GROUP BY s.nombre
)
SELECT sucursal, ingresos_totales
FROM IngresosPorSucursal
WHERE ingresos_totales > 600
ORDER BY ingresos_totales DESC;
GO

-- Consulta 07 (CTE): Clientes con su gasto total y cantidad de alquileres,
-- calculados en pasos separados
-- Objetivo de negocio: Atención al cliente necesita un perfil resumido de
-- cada cliente (cuánto gastó y cuántas veces alquiló) en una sola consulta legible.
WITH GastoCliente AS (
    SELECT cliente_id, SUM(monto) AS gasto_total
    FROM Pago
    GROUP BY cliente_id
),
AlquileresCliente AS (
    SELECT cliente_id, COUNT(*) AS total_alquileres
    FROM Alquiler
    GROUP BY cliente_id
)
SELECT cl.nombre, cl.apellido,
       ISNULL(g.gasto_total, 0) AS gasto_total,
       ISNULL(a.total_alquileres, 0) AS total_alquileres
FROM Cliente cl
LEFT JOIN GastoCliente g ON g.cliente_id = cl.cliente_id
LEFT JOIN AlquileresCliente a ON a.cliente_id = cl.cliente_id
ORDER BY gasto_total DESC;
GO

-- Consulta 08 (CTE): Categorías con su cantidad de películas y su tarifa
-- promedio, filtrando solo las que superan cierta tarifa promedio
-- Objetivo de negocio: Compras quiere enfocar el próximo presupuesto en las
-- categorías de mayor valor promedio por alquiler.
WITH ResumenCategoria AS (
    SELECT cat.nombre AS categoria,
           COUNT(pc.pelicula_id) AS cantidad_peliculas,
           AVG(pe.tarifa_alquiler) AS tarifa_promedio
    FROM Categoria cat
    INNER JOIN Pelicula_Categoria pc ON pc.categoria_id = cat.categoria_id
    INNER JOIN Pelicula pe ON pe.pelicula_id = pc.pelicula_id
    GROUP BY cat.nombre
)
SELECT categoria, cantidad_peliculas, tarifa_promedio
FROM ResumenCategoria
WHERE tarifa_promedio > 2.99
ORDER BY tarifa_promedio DESC;
GO

-- Consulta 09: Clientes cuya cantidad de alquileres es mayor al promedio de
-- alquileres por cliente (subconsulta escalar en HAVING)
-- Objetivo de negocio: Marketing arma el segmento de clientes "muy activos",
-- por encima del comportamiento promedio del resto.
SELECT cliente_id, COUNT(*) AS total_alquileres
FROM Alquiler
GROUP BY cliente_id
HAVING COUNT(*) > (
    SELECT AVG(cantidad) FROM (
        SELECT COUNT(*) AS cantidad
        FROM Alquiler
        GROUP BY cliente_id
    ) AS promedio_alquileres
)
ORDER BY total_alquileres DESC;
GO

-- Consulta 10 (CTE integrador): Top 5 películas más rentables, combinando
-- inventario, alquileres y pagos en pasos claros con CTE
-- Objetivo de negocio: Dirección quiere el ranking de películas que más
-- ingresos generaron en total, para decidir qué títulos renovar o replicar.
WITH IngresosPorPelicula AS (
    SELECT inv.pelicula_id, SUM(p.monto) AS ingresos_totales
    FROM Pago p
    INNER JOIN Alquiler al ON al.alquiler_id = p.alquiler_id
    INNER JOIN Inventario inv ON inv.inventario_id = al.inventario_id
    GROUP BY inv.pelicula_id
)
SELECT TOP 5 pe.titulo, ip.ingresos_totales
FROM IngresosPorPelicula ip
INNER JOIN Pelicula pe ON pe.pelicula_id = ip.pelicula_id
ORDER BY ip.ingresos_totales DESC;
GO
