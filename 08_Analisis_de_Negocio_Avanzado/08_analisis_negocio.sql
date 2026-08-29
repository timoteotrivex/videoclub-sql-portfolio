/* ============================================================
   08. ANÁLISIS DE NEGOCIO AVANZADO — Videoclub
   Consultas que resuelven preguntas reales de gestión: segmentación de
   clientes (RFM), riesgo de fuga, rentabilidad y retención.
   ============================================================ */

USE Videoclub;
GO

-- ============================================================
-- Consulta 01: Segmentación RFM de clientes (Recencia, Frecuencia, Monto)
-- Objetivo de negocio: Marketing necesita clasificar a cada cliente en un
-- segmento accionable (Campeón, Leal, En Riesgo, Perdido) para decidir qué
-- campaña recibe cada uno, en vez de tratar a todos los clientes igual.
-- ============================================================
WITH MetricasCliente AS (
    SELECT
        cl.cliente_id,
        cl.nombre,
        cl.apellido,
        DATEDIFF(DAY, MAX(al.fecha_alquiler), '2026-08-01') AS recencia_dias,
        COUNT(DISTINCT al.alquiler_id) AS frecuencia,
        ISNULL(SUM(p.monto), 0) AS monto_total
    FROM Cliente cl
    LEFT JOIN Alquiler al ON al.cliente_id = cl.cliente_id
    LEFT JOIN Pago p ON p.alquiler_id = al.alquiler_id
    WHERE cl.activo = 1
    GROUP BY cl.cliente_id, cl.nombre, cl.apellido
),
ScoresRFM AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recencia_dias DESC) AS score_recencia,
        NTILE(5) OVER (ORDER BY frecuencia ASC) AS score_frecuencia,
        NTILE(5) OVER (ORDER BY monto_total ASC) AS score_monetario
    FROM MetricasCliente
)
SELECT
    cliente_id, nombre, apellido, recencia_dias, frecuencia, monto_total,
    score_recencia, score_frecuencia, score_monetario,
    (score_recencia + score_frecuencia + score_monetario) AS score_total,
    CASE
        WHEN (score_recencia + score_frecuencia + score_monetario) >= 12 THEN 'Campeón'
        WHEN (score_recencia + score_frecuencia + score_monetario) >= 9  THEN 'Cliente Leal'
        WHEN (score_recencia + score_frecuencia + score_monetario) >= 6  THEN 'En Riesgo'
        ELSE 'Perdido / Bajo Valor'
    END AS segmento_rfm
FROM ScoresRFM
ORDER BY score_total DESC;
GO

-- ============================================================
-- Consulta 02: Clientes en riesgo de fuga (churn)
-- Objetivo de negocio: Antes eran clientes frecuentes (5+ alquileres
-- históricos) pero no alquilan hace más de 90 días. Marketing necesita
-- este listado puntual para una campaña de reactivación urgente.
-- ============================================================
WITH ActividadCliente AS (
    SELECT
        cl.cliente_id, cl.nombre, cl.apellido,
        COUNT(al.alquiler_id) AS total_historico,
        MAX(al.fecha_alquiler) AS ultimo_alquiler
    FROM Cliente cl
    INNER JOIN Alquiler al ON al.cliente_id = cl.cliente_id
    WHERE cl.activo = 1
    GROUP BY cl.cliente_id, cl.nombre, cl.apellido
)
SELECT
    cliente_id, nombre, apellido, total_historico, ultimo_alquiler,
    DATEDIFF(DAY, ultimo_alquiler, '2026-08-01') AS dias_sin_alquilar
FROM ActividadCliente
WHERE total_historico >= 5
  AND DATEDIFF(DAY, ultimo_alquiler, '2026-08-01') > 90
ORDER BY dias_sin_alquilar DESC;
GO

-- ============================================================
-- Consulta 03: Rentabilidad por película — ingresos generados vs. costo de
-- reemplazo (ROI aproximado)
-- Objetivo de negocio: Compras necesita saber qué películas "se pagaron
-- solas" varias veces y cuáles todavía no recuperan ni su costo de reposición,
-- para decidir qué renovar y qué dar de baja.
-- ============================================================
WITH IngresosPelicula AS (
    SELECT inv.pelicula_id, ISNULL(SUM(p.monto), 0) AS ingresos_generados
    FROM Inventario inv
    LEFT JOIN Alquiler al ON al.inventario_id = inv.inventario_id
    LEFT JOIN Pago p ON p.alquiler_id = al.alquiler_id
    GROUP BY inv.pelicula_id
)
SELECT
    pe.titulo,
    pe.costo_reemplazo,
    ip.ingresos_generados,
    ROUND(ip.ingresos_generados / NULLIF(pe.costo_reemplazo, 0) * 100, 1) AS porcentaje_recuperado,
    CASE
        WHEN ip.ingresos_generados >= pe.costo_reemplazo THEN 'Rentable'
        WHEN ip.ingresos_generados = 0 THEN 'Sin ingresos'
        ELSE 'Aún no recupera costo'
    END AS estado_rentabilidad
FROM Pelicula pe
INNER JOIN IngresosPelicula ip ON ip.pelicula_id = pe.pelicula_id
ORDER BY porcentaje_recuperado DESC;
GO

-- ============================================================
-- Consulta 04: Rentabilidad por categoría — ingresos generados vs. tamaño
-- de la inversión en inventario
-- Objetivo de negocio: Dirección quiere saber qué géneros generan más
-- ingresos POR CADA COPIA que se compró, no solo en total, para invertir
-- mejor el próximo presupuesto de compras.
-- ============================================================
WITH InventarioPorCategoria AS (
    SELECT pc.categoria_id, COUNT(DISTINCT inv.inventario_id) AS copias_totales
    FROM Pelicula_Categoria pc
    INNER JOIN Inventario inv ON inv.pelicula_id = pc.pelicula_id
    GROUP BY pc.categoria_id
),
IngresosPorCategoria AS (
    SELECT pc.categoria_id, SUM(p.monto) AS ingresos_totales
    FROM Pelicula_Categoria pc
    INNER JOIN Inventario inv ON inv.pelicula_id = pc.pelicula_id
    INNER JOIN Alquiler al ON al.inventario_id = inv.inventario_id
    INNER JOIN Pago p ON p.alquiler_id = al.alquiler_id
    GROUP BY pc.categoria_id
)
SELECT
    cat.nombre AS categoria,
    inv.copias_totales,
    ISNULL(ing.ingresos_totales, 0) AS ingresos_totales,
    ROUND(ISNULL(ing.ingresos_totales, 0) / NULLIF(inv.copias_totales, 0), 2) AS ingreso_por_copia
FROM Categoria cat
INNER JOIN InventarioPorCategoria inv ON inv.categoria_id = cat.categoria_id
LEFT JOIN IngresosPorCategoria ing ON ing.categoria_id = cat.categoria_id
ORDER BY ingreso_por_copia DESC;
GO

-- ============================================================
-- Consulta 05: Retención simplificada por cohorte de alta (mes de registro)
-- Objetivo de negocio: Dirección quiere saber si los clientes que se
-- registraron en un mes determinado siguen activos y alquilando meses
-- después, para medir qué tan efectiva es la retención a lo largo del tiempo.
-- ============================================================
WITH Cohortes AS (
    SELECT
        cliente_id,
        FORMAT(fecha_alta, 'yyyy-MM') AS mes_cohorte
    FROM Cliente
),
AlquileresConCohorte AS (
    SELECT
        c.mes_cohorte,
        al.cliente_id,
        FORMAT(al.fecha_alquiler, 'yyyy-MM') AS mes_alquiler
    FROM Alquiler al
    INNER JOIN Cohortes c ON c.cliente_id = al.cliente_id
)
SELECT
    mes_cohorte,
    COUNT(DISTINCT cliente_id) AS clientes_con_actividad,
    COUNT(*) AS total_alquileres_generados
FROM AlquileresConCohorte
GROUP BY mes_cohorte
ORDER BY mes_cohorte;
GO

-- ============================================================
-- Consulta 06: Resumen ejecutivo — panel de KPIs generales del negocio
-- Objetivo de negocio: El directorio pide un resumen de una sola vista con
-- los números clave del videoclub, para la reunión mensual.
-- ============================================================
SELECT
    (SELECT COUNT(*) FROM Cliente WHERE activo = 1)              AS clientes_activos,
    (SELECT COUNT(*) FROM Pelicula)                                AS total_peliculas,
    (SELECT COUNT(*) FROM Alquiler)                                AS total_alquileres,
    (SELECT SUM(monto) FROM Pago)                                  AS ingresos_totales,
    (SELECT ROUND(AVG(monto), 2) FROM Pago)                        AS ticket_promedio,
    (SELECT COUNT(*) FROM Alquiler WHERE fecha_devolucion IS NULL) AS alquileres_pendientes;
GO
