/* ============================================================
   04. JOINS — Videoclub
   Relaciones entre tablas: INNER JOIN, LEFT JOIN, joins múltiples.
   ============================================================ */

USE Videoclub;
GO

-- Consulta 01: Actores que participan en películas de la categoría "Terror"
-- Objetivo de negocio: Marketing arma una campaña de Halloween y necesita
-- el listado de actores para promocionar en redes sociales.
SELECT DISTINCT a.nombre, a.apellido
FROM Actor a
INNER JOIN Pelicula_Actor pa ON pa.actor_id = a.actor_id
INNER JOIN Pelicula_Categoria pc ON pc.pelicula_id = pa.pelicula_id
INNER JOIN Categoria c ON c.categoria_id = pc.categoria_id
WHERE c.nombre = 'Terror'
ORDER BY a.apellido;
GO

-- Consulta 02: Detalle de alquileres con nombre de cliente y título de película
-- Objetivo de negocio: Atención al cliente necesita ver, en una sola pantalla,
-- qué película alquiló cada cliente sin tener que cruzar tablas a mano.
SELECT al.alquiler_id, cl.nombre, cl.apellido, pe.titulo, al.fecha_alquiler
FROM Alquiler al
INNER JOIN Cliente cl ON cl.cliente_id = al.cliente_id
INNER JOIN Inventario inv ON inv.inventario_id = al.inventario_id
INNER JOIN Pelicula pe ON pe.pelicula_id = inv.pelicula_id
ORDER BY al.fecha_alquiler DESC;
GO

-- Consulta 03: Clientes que NUNCA hicieron un alquiler
-- Objetivo de negocio: Marketing quiere identificar clientes registrados
-- que nunca usaron el servicio, para mandarles un incentivo de bienvenida.
SELECT cl.cliente_id, cl.nombre, cl.apellido
FROM Cliente cl
LEFT JOIN Alquiler al ON al.cliente_id = cl.cliente_id
WHERE al.alquiler_id IS NULL;
GO

-- Consulta 04: Copias de inventario que nunca fueron alquiladas
-- Objetivo de negocio: Operaciones quiere detectar stock "muerto" que nunca
-- generó ingresos, para evaluar si conviene reubicarlo o darlo de baja.
SELECT inv.inventario_id, pe.titulo, s.nombre AS sucursal
FROM Inventario inv
INNER JOIN Pelicula pe ON pe.pelicula_id = inv.pelicula_id
INNER JOIN Sucursal s ON s.sucursal_id = inv.sucursal_id
LEFT JOIN Alquiler al ON al.inventario_id = inv.inventario_id
WHERE al.alquiler_id IS NULL;
GO

-- Consulta 05: Todos los clientes con su cantidad de alquileres (incluyendo
-- los que tienen 0)
-- Objetivo de negocio: Reporte completo para Marketing, donde los clientes
-- sin actividad también deben aparecer (con 0), no quedar ocultos.
SELECT cl.cliente_id, cl.nombre, cl.apellido, COUNT(al.alquiler_id) AS total_alquileres
FROM Cliente cl
LEFT JOIN Alquiler al ON al.cliente_id = cl.cliente_id
GROUP BY cl.cliente_id, cl.nombre, cl.apellido
ORDER BY total_alquileres DESC;
GO

-- Consulta 06: Películas con su categoría y cantidad de actores en el elenco
-- Objetivo de negocio: Contenidos quiere revisar qué películas tienen
-- elencos más grandes, por categoría, para destacarlas en el catálogo.
SELECT pe.titulo, cat.nombre AS categoria, COUNT(pa.actor_id) AS cantidad_actores
FROM Pelicula pe
INNER JOIN Pelicula_Categoria pc ON pc.pelicula_id = pe.pelicula_id
INNER JOIN Categoria cat ON cat.categoria_id = pc.categoria_id
INNER JOIN Pelicula_Actor pa ON pa.pelicula_id = pe.pelicula_id
GROUP BY pe.titulo, cat.nombre
ORDER BY cantidad_actores DESC;
GO

-- Consulta 07: Empleados (personal) con la sucursal en la que trabajan y su
-- dirección
-- Objetivo de negocio: RR.HH. necesita un legajo básico con datos de
-- contacto y sucursal asignada para cada empleado.
SELECT per.nombre, per.apellido, s.nombre AS sucursal, d.direccion, d.telefono
FROM Personal per
INNER JOIN Sucursal s ON s.sucursal_id = per.sucursal_id
INNER JOIN Direccion d ON d.direccion_id = per.direccion_id
ORDER BY s.nombre, per.apellido;
GO

-- Consulta 08: Ingresos generados por cada empleado (según los pagos que gestionó)
-- Objetivo de negocio: Gerencia quiere evaluar el desempeño individual de
-- cada empleado según el monto total de pagos que procesó.
SELECT per.nombre, per.apellido, SUM(p.monto) AS total_gestionado
FROM Personal per
INNER JOIN Pago p ON p.personal_id = per.personal_id
GROUP BY per.nombre, per.apellido
ORDER BY total_gestionado DESC;
GO

-- Consulta 09: Categorías que nunca tuvieron un alquiler asociado
-- Objetivo de negocio: Compras evalúa si hay géneros del catálogo que
-- directamente no generan actividad, para replantear la inversión ahí.
SELECT cat.nombre AS categoria
FROM Categoria cat
LEFT JOIN Pelicula_Categoria pc ON pc.categoria_id = cat.categoria_id
LEFT JOIN Inventario inv ON inv.pelicula_id = pc.pelicula_id
LEFT JOIN Alquiler al ON al.inventario_id = inv.inventario_id
GROUP BY cat.nombre
HAVING COUNT(al.alquiler_id) = 0;
GO

-- Consulta 10: Desafío integrador — Detalle completo de pagos: cliente,
-- empleado que lo atendió, sucursal y película alquilada
-- Objetivo de negocio: Auditoría pide un reporte que cruce las 5 tablas
-- clave del negocio en una sola vista, para revisar un lote de pagos.
SELECT
    p.pago_id,
    cl.nombre + ' ' + cl.apellido AS cliente,
    per.nombre + ' ' + per.apellido AS empleado,
    s.nombre AS sucursal,
    pe.titulo AS pelicula,
    p.monto,
    p.fecha_pago
FROM Pago p
INNER JOIN Cliente cl ON cl.cliente_id = p.cliente_id
INNER JOIN Personal per ON per.personal_id = p.personal_id
INNER JOIN Alquiler al ON al.alquiler_id = p.alquiler_id
INNER JOIN Inventario inv ON inv.inventario_id = al.inventario_id
INNER JOIN Pelicula pe ON pe.pelicula_id = inv.pelicula_id
INNER JOIN Sucursal s ON s.sucursal_id = inv.sucursal_id
ORDER BY p.fecha_pago DESC;
GO
