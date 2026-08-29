/* ============================================================
   07. VISTAS Y PROCEDIMIENTOS ALMACENADOS — Videoclub
   Convertimos las consultas más usadas en objetos reutilizables:
   VIEWS para reportes recurrentes y STORED PROCEDURES con parámetros
   para consultas que varían según el caso de uso.
   ============================================================ */

USE Videoclub;
GO

-- ============================================================
-- VISTA 01: Ingresos totales por sucursal
-- Objetivo de negocio: Dirección consulta este reporte todas las semanas.
-- En vez de repetir el JOIN + GROUP BY cada vez, queda guardado como vista.
-- ============================================================
CREATE VIEW vw_IngresosPorSucursal AS
SELECT
    s.sucursal_id,
    s.nombre AS sucursal,
    COUNT(p.pago_id) AS cantidad_pagos,
    SUM(p.monto) AS ingresos_totales
FROM Pago p
INNER JOIN Cliente c ON c.cliente_id = p.cliente_id
INNER JOIN Sucursal s ON s.sucursal_id = c.sucursal_id
GROUP BY s.sucursal_id, s.nombre;
GO

-- Uso: SELECT * FROM vw_IngresosPorSucursal ORDER BY ingresos_totales DESC;

-- ============================================================
-- VISTA 02: Catálogo de películas con su categoría e idioma (desnormalizado
-- para consulta rápida desde el mostrador o desde Power BI)
-- Objetivo de negocio: El sistema del mostrador necesita mostrar el detalle
-- completo de una película sin hacer 3 JOINs cada vez que un empleado busca algo.
-- ============================================================
CREATE VIEW vw_CatalogoPeliculas AS
SELECT
    pe.pelicula_id,
    pe.titulo,
    pe.anio_lanzamiento,
    pe.clasificacion,
    pe.tarifa_alquiler,
    pe.duracion_minutos,
    idi.nombre AS idioma,
    cat.nombre AS categoria
FROM Pelicula pe
INNER JOIN Idioma idi ON idi.idioma_id = pe.idioma_id
LEFT JOIN Pelicula_Categoria pc ON pc.pelicula_id = pe.pelicula_id
LEFT JOIN Categoria cat ON cat.categoria_id = pc.categoria_id;
GO

-- Uso: SELECT * FROM vw_CatalogoPeliculas WHERE categoria = 'Acción';

-- ============================================================
-- VISTA 03: Clientes activos con su gasto total y cantidad de alquileres
-- (pensada como fuente directa para el dashboard de Power BI)
-- Objetivo de negocio: Power BI va a conectarse a esta vista para armar
-- el análisis de clientes, sin necesitar la lógica de JOINs en el dashboard.
-- ============================================================
CREATE VIEW vw_ResumenClientes AS
SELECT
    cl.cliente_id,
    cl.nombre,
    cl.apellido,
    s.nombre AS sucursal,
    cl.activo,
    cl.fecha_alta,
    COUNT(DISTINCT al.alquiler_id) AS total_alquileres,
    ISNULL(SUM(p.monto), 0) AS gasto_total
FROM Cliente cl
INNER JOIN Sucursal s ON s.sucursal_id = cl.sucursal_id
LEFT JOIN Alquiler al ON al.cliente_id = cl.cliente_id
LEFT JOIN Pago p ON p.alquiler_id = al.alquiler_id
GROUP BY cl.cliente_id, cl.nombre, cl.apellido, s.nombre, cl.activo, cl.fecha_alta;
GO

-- Uso: SELECT * FROM vw_ResumenClientes ORDER BY gasto_total DESC;

-- ============================================================
-- PROCEDIMIENTO 01: Historial completo de alquileres de un cliente puntual
-- Objetivo de negocio: Cuando un cliente llama por teléfono, el empleado
-- del mostrador necesita ver su historial completo pasando solo su ID.
-- ============================================================
CREATE PROCEDURE sp_HistorialCliente
    @cliente_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        al.alquiler_id,
        pe.titulo,
        al.fecha_alquiler,
        al.fecha_devolucion,
        p.monto
    FROM Alquiler al
    INNER JOIN Inventario inv ON inv.inventario_id = al.inventario_id
    INNER JOIN Pelicula pe ON pe.pelicula_id = inv.pelicula_id
    LEFT JOIN Pago p ON p.alquiler_id = al.alquiler_id
    WHERE al.cliente_id = @cliente_id
    ORDER BY al.fecha_alquiler DESC;
END;
GO

-- Uso: EXEC sp_HistorialCliente @cliente_id = 15;

-- ============================================================
-- PROCEDIMIENTO 02: Reporte de ingresos de una sucursal en un rango de fechas
-- Objetivo de negocio: Cada gerente de sucursal necesita poder pedir su
-- propio reporte de ingresos para cualquier período, sin escribir SQL.
-- ============================================================
CREATE PROCEDURE sp_IngresosPorSucursalYFecha
    @sucursal_id INT,
    @fecha_desde DATE,
    @fecha_hasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.nombre AS sucursal,
        COUNT(p.pago_id) AS cantidad_pagos,
        SUM(p.monto) AS ingresos_totales
    FROM Pago p
    INNER JOIN Cliente cl ON cl.cliente_id = p.cliente_id
    INNER JOIN Sucursal s ON s.sucursal_id = cl.sucursal_id
    WHERE s.sucursal_id = @sucursal_id
      AND p.fecha_pago BETWEEN @fecha_desde AND @fecha_hasta
    GROUP BY s.nombre;
END;
GO

-- Uso: EXEC sp_IngresosPorSucursalYFecha
--          @sucursal_id = 1, @fecha_desde = '2026-01-01', @fecha_hasta = '2026-06-30';

-- ============================================================
-- PROCEDIMIENTO 03: Dar de baja a un cliente (ejemplo de procedimiento que
-- modifica datos, no solo consulta)
-- Objetivo de negocio: Cuando un cliente pide dar de baja su cuenta, el
-- empleado ejecuta un único procedimiento en vez de un UPDATE manual.
-- ============================================================
CREATE PROCEDURE sp_DarDeBajaCliente
    @cliente_id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Cliente
    SET activo = 0
    WHERE cliente_id = @cliente_id;

    SELECT cliente_id, nombre, apellido, activo
    FROM Cliente
    WHERE cliente_id = @cliente_id;
END;
GO

-- Uso: EXEC sp_DarDeBajaCliente @cliente_id = 42;
