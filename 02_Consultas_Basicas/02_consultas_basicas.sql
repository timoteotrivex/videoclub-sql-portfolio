/* ============================================================
   02. CONSULTAS BÁSICAS — Videoclub
   Filtros y ordenamientos sobre una o dos tablas.
   Técnicas: WHERE, LIKE, BETWEEN, IN, IS NULL/IS NOT NULL, ORDER BY.
   ============================================================ */

USE Videoclub;
GO

-- Consulta 01: Películas aptas para todo público (ATP)
-- Objetivo de negocio: Atención al cliente arma una sección "para toda
-- la familia" en el local, y necesita el listado de títulos ATP.
SELECT titulo, anio_lanzamiento, clasificacion
FROM Pelicula
WHERE clasificacion = 'ATP'
ORDER BY titulo;
GO

-- Consulta 02: Películas estrenadas entre 2015 y 2020
-- Objetivo de negocio: Marketing arma una promoción "Lo mejor de la década
-- pasada" y necesita el catálogo filtrado por ese rango de años.
SELECT titulo, anio_lanzamiento
FROM Pelicula
WHERE anio_lanzamiento BETWEEN 2015 AND 2020
ORDER BY anio_lanzamiento;
GO

-- Consulta 03: Películas cuyo título empieza con "Noche"
-- Objetivo de negocio: Un cliente llama preguntando por películas de
-- "Noche algo", y el empleado necesita buscarlas rápido en el sistema.
SELECT titulo
FROM Pelicula
WHERE titulo LIKE 'Noche%'
ORDER BY titulo;
GO

-- Consulta 04: Películas cuyo título contiene la palabra "Fuego" en cualquier parte
-- Objetivo de negocio: Búsqueda general del sistema de mostrador, cuando el
-- cliente solo recuerda una palabra suelta del título.
SELECT titulo
FROM Pelicula
WHERE titulo LIKE '%Fuego%'
ORDER BY titulo;
GO

-- Consulta 05: Clientes de las sucursales Centro o Norte
-- Objetivo de negocio: Se va a hacer un envío de mail solo a clientes de
-- esas dos sucursales por una promoción local.
SELECT c.nombre, c.apellido, s.nombre AS sucursal
FROM Cliente c
INNER JOIN Sucursal s ON s.sucursal_id = c.sucursal_id
WHERE s.nombre IN ('Videoclub Centro', 'Videoclub Norte')
ORDER BY c.apellido;
GO

-- Consulta 06: Alquileres que todavía no fueron devueltos
-- Objetivo de negocio: Operaciones necesita el listado de alquileres
-- pendientes de devolución para hacer seguimiento.
SELECT alquiler_id, cliente_id, fecha_alquiler
FROM Alquiler
WHERE fecha_devolucion IS NULL
ORDER BY fecha_alquiler;
GO

-- Consulta 07: Clientes inactivos (dados de baja)
-- Objetivo de negocio: Antes de una campaña de reactivación, Marketing
-- necesita saber a cuántos clientes contactar.
SELECT nombre, apellido, fecha_alta
FROM Cliente
WHERE activo = 0
ORDER BY fecha_alta DESC;
GO

-- Consulta 08: Películas con tarifa de alquiler mayor a $3.99, ordenadas de
-- mayor a menor
-- Objetivo de negocio: Gerencia comercial revisa el segmento "premium"
-- del catálogo, el de mayor tarifa por alquiler.
SELECT titulo, tarifa_alquiler
FROM Pelicula
WHERE tarifa_alquiler > 3.99
ORDER BY tarifa_alquiler DESC;
GO

-- Consulta 09: Desafío integrador — Películas +16 o +18, estrenadas después
-- de 2018, con duración mayor a 100 minutos
-- Objetivo de negocio: Un cliente adulto pide recomendaciones de películas
-- "largas y recientes" para su clasificación de edad preferida.
SELECT titulo, anio_lanzamiento, duracion_minutos, clasificacion
FROM Pelicula
WHERE clasificacion IN ('+16', '+18')
  AND anio_lanzamiento > 2018
  AND duracion_minutos > 100
ORDER BY anio_lanzamiento DESC;
GO

-- Consulta 10: Pagos registrados en un rango de fechas específico
-- Objetivo de negocio: Contabilidad necesita revisar todos los pagos
-- recibidos durante enero de 2026 para el cierre mensual.
SELECT pago_id, cliente_id, monto, fecha_pago
FROM Pago
WHERE fecha_pago BETWEEN '2026-01-01' AND '2026-01-31'
ORDER BY fecha_pago;
GO
