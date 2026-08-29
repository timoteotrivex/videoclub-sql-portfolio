/* ============================================================
   06. FUNCIONES DE VENTANA — Videoclub
   Técnicas: ROW_NUMBER, RANK, DENSE_RANK, LAG/LEAD, SUM() OVER
   (totales acumulados), PARTITION BY.
   ============================================================ */

USE Videoclub;
GO

-- Consulta 01: Ranking de clientes según gasto total
-- Objetivo de negocio: Marketing quiere el ranking completo de clientes por
-- gasto, para definir los primeros puestos del programa de fidelización.
SELECT
    cl.nombre, cl.apellido,
    SUM(p.monto) AS gasto_total,
    RANK() OVER (ORDER BY SUM(p.monto) DESC) AS ranking_gasto
FROM Pago p
INNER JOIN Cliente cl ON cl.cliente_id = p.cliente_id
GROUP BY cl.cliente_id, cl.nombre, cl.apellido
ORDER BY ranking_gasto;
GO

-- Consulta 02: Top 3 películas más alquiladas POR CATEGORÍA (RANK con PARTITION BY)
-- Objetivo de negocio: Contenidos quiere destacar en vidriera las 3 películas
-- más populares de cada género, no solo un top general.
WITH AlquileresPorPelicula AS (
    SELECT inv.pelicula_id, COUNT(*) AS total_alquileres
    FROM Alquiler al
    INNER JOIN Inventario inv ON inv.inventario_id = al.inventario_id
    GROUP BY inv.pelicula_id
),
RankingPorCategoria AS (
    SELECT
        cat.nombre AS categoria,
        pe.titulo,
        ap.total_alquileres,
        RANK() OVER (PARTITION BY cat.nombre ORDER BY ap.total_alquileres DESC) AS ranking
    FROM AlquileresPorPelicula ap
    INNER JOIN Pelicula pe ON pe.pelicula_id = ap.pelicula_id
    INNER JOIN Pelicula_Categoria pc ON pc.pelicula_id = pe.pelicula_id
    INNER JOIN Categoria cat ON cat.categoria_id = pc.categoria_id
)
SELECT categoria, titulo, total_alquileres, ranking
FROM RankingPorCategoria
WHERE ranking <= 3
ORDER BY categoria, ranking;
GO

-- Consulta 03: Numerar cronológicamente los alquileres de cada cliente (ROW_NUMBER)
-- Objetivo de negocio: Atención al cliente quiere ver, para cada cliente,
-- cuál fue su 1er, 2do, 3er alquiler, etc., en orden.
SELECT
    cliente_id,
    alquiler_id,
    fecha_alquiler,
    ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY fecha_alquiler) AS numero_alquiler
FROM Alquiler
ORDER BY cliente_id, numero_alquiler;
GO

-- Consulta 04: Primer alquiler de cada cliente (usando ROW_NUMBER dentro de una CTE)
-- Objetivo de negocio: Marketing quiere saber qué película eligió cada
-- cliente en su primera visita, para entender qué "engancha" a los nuevos.
WITH AlquileresNumerados AS (
    SELECT
        al.cliente_id, al.alquiler_id, al.fecha_alquiler, inv.pelicula_id,
        ROW_NUMBER() OVER (PARTITION BY al.cliente_id ORDER BY al.fecha_alquiler) AS numero_alquiler
    FROM Alquiler al
    INNER JOIN Inventario inv ON inv.inventario_id = al.inventario_id
)
SELECT an.cliente_id, cl.nombre, cl.apellido, pe.titulo AS primera_pelicula, an.fecha_alquiler
FROM AlquileresNumerados an
INNER JOIN Cliente cl ON cl.cliente_id = an.cliente_id
INNER JOIN Pelicula pe ON pe.pelicula_id = an.pelicula_id
WHERE an.numero_alquiler = 1
ORDER BY an.fecha_alquiler;
GO

-- Consulta 05: Evolución mensual de ingresos, comparando cada mes con el anterior (LAG)
-- Objetivo de negocio: Dirección quiere ver la tendencia mes a mes de
-- ingresos, y cuánto varió respecto al mes anterior.
WITH IngresosPorMes AS (
    SELECT
        FORMAT(fecha_pago, 'yyyy-MM') AS mes,
        SUM(monto) AS ingresos_totales
    FROM Pago
    GROUP BY FORMAT(fecha_pago, 'yyyy-MM')
)
SELECT
    mes,
    ingresos_totales,
    LAG(ingresos_totales) OVER (ORDER BY mes) AS ingresos_mes_anterior,
    ingresos_totales - LAG(ingresos_totales) OVER (ORDER BY mes) AS variacion
FROM IngresosPorMes
ORDER BY mes;
GO

-- Consulta 06: Total acumulado de ingresos a lo largo del tiempo (running total)
-- Objetivo de negocio: Finanzas necesita ver el acumulado de ingresos desde
-- el inicio de operaciones hasta cada mes, para proyectar el cierre anual.
WITH IngresosPorMes AS (
    SELECT
        FORMAT(fecha_pago, 'yyyy-MM') AS mes,
        SUM(monto) AS ingresos_del_mes
    FROM Pago
    GROUP BY FORMAT(fecha_pago, 'yyyy-MM')
)
SELECT
    mes,
    ingresos_del_mes,
    SUM(ingresos_del_mes) OVER (ORDER BY mes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ingresos_acumulados
FROM IngresosPorMes
ORDER BY mes;
GO

-- Consulta 07: Siguiente alquiler de cada cliente después del actual (LEAD)
-- Objetivo de negocio: Atención al cliente quiere detectar cuánto tiempo
-- pasa un cliente entre un alquiler y el siguiente, para medir frecuencia real.
SELECT
    cliente_id,
    fecha_alquiler,
    LEAD(fecha_alquiler) OVER (PARTITION BY cliente_id ORDER BY fecha_alquiler) AS siguiente_alquiler,
    DATEDIFF(
        DAY,
        fecha_alquiler,
        LEAD(fecha_alquiler) OVER (PARTITION BY cliente_id ORDER BY fecha_alquiler)
    ) AS dias_hasta_siguiente
FROM Alquiler
ORDER BY cliente_id, fecha_alquiler;
GO

-- Consulta 08: Clasificar películas en 4 grupos según su tarifa de alquiler (NTILE)
-- Objetivo de negocio: Gerencia comercial quiere dividir el catálogo en 4
-- franjas de precio parejas (cuartiles), para armar promociones por franja.
SELECT
    titulo,
    tarifa_alquiler,
    NTILE(4) OVER (ORDER BY tarifa_alquiler) AS franja_precio
FROM Pelicula
ORDER BY franja_precio, tarifa_alquiler;
GO

-- Consulta 09: Diferencia entre DENSE_RANK y RANK en el ranking de sucursales
-- por ingresos (útil cuando hay empates)
-- Objetivo de negocio: Dirección quiere un ranking de sucursales sin "saltos"
-- de posición en caso de empate en ingresos, para un reporte más claro.
WITH IngresosPorSucursal AS (
    SELECT s.nombre AS sucursal, SUM(p.monto) AS ingresos_totales
    FROM Pago p
    INNER JOIN Cliente c ON c.cliente_id = p.cliente_id
    INNER JOIN Sucursal s ON s.sucursal_id = c.sucursal_id
    GROUP BY s.nombre
)
SELECT
    sucursal,
    ingresos_totales,
    RANK() OVER (ORDER BY ingresos_totales DESC) AS ranking_con_saltos,
    DENSE_RANK() OVER (ORDER BY ingresos_totales DESC) AS ranking_sin_saltos
FROM IngresosPorSucursal
ORDER BY ingresos_totales DESC;
GO

-- Consulta 10 (integrador): Top 3 clientes más valiosos por sucursal, con su
-- gasto total y el promedio de gasto de esa sucursal para comparar
-- Objetivo de negocio: Cada sucursal quiere su propio "top 3 de clientes VIP"
-- junto con el promedio general, para saber cuánto se destacan por encima del resto.
WITH GastoPorCliente AS (
    SELECT
        cl.cliente_id, cl.nombre, cl.apellido, s.nombre AS sucursal,
        SUM(p.monto) AS gasto_total
    FROM Pago p
    INNER JOIN Cliente cl ON cl.cliente_id = p.cliente_id
    INNER JOIN Sucursal s ON s.sucursal_id = cl.sucursal_id
    GROUP BY cl.cliente_id, cl.nombre, cl.apellido, s.nombre
),
RankingPorSucursal AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY sucursal ORDER BY gasto_total DESC) AS ranking,
        AVG(gasto_total) OVER (PARTITION BY sucursal) AS promedio_sucursal
    FROM GastoPorCliente
)
SELECT sucursal, nombre, apellido, gasto_total, promedio_sucursal, ranking
FROM RankingPorSucursal
WHERE ranking <= 3
ORDER BY sucursal, ranking;
GO
