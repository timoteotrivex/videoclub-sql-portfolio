/* ============================================================
   03. AGREGACIONES, GROUP BY Y HAVING — Videoclub
   Técnicas: SUM, AVG, MAX, MIN, COUNT, GROUP BY, HAVING.
   ============================================================ */

USE Videoclub;
GO

-- Consulta 01: Cantidad de películas por categoría
-- Objetivo de negocio: Compras quiere saber qué géneros están sobre-representados
-- en el catálogo antes de decidir qué comprar a futuro.
SELECT c.nombre AS categoria, COUNT(*) AS cantidad_peliculas
FROM Pelicula_Categoria pc
INNER JOIN Categoria c ON c.categoria_id = pc.categoria_id
GROUP BY c.nombre
ORDER BY cantidad_peliculas DESC;
GO

-- Consulta 02: Ingresos totales por sucursal
-- Objetivo de negocio: Dirección necesita saber qué sucursal factura más
-- para decidir dónde reforzar personal o stock.
SELECT s.nombre AS sucursal, SUM(p.monto) AS ingresos_totales
FROM Pago p
INNER JOIN Cliente c ON c.cliente_id = p.cliente_id
INNER JOIN Sucursal s ON s.sucursal_id = c.sucursal_id
GROUP BY s.nombre
ORDER BY ingresos_totales DESC;
GO

-- Consulta 03: Tarifa de alquiler promedio por categoría
-- Objetivo de negocio: Gerencia comercial evalúa si algún género está
-- sobrevalorado o subvalorado respecto al resto del catálogo.
SELECT cat.nombre AS categoria, AVG(pe.tarifa_alquiler) AS tarifa_promedio
FROM Pelicula pe
INNER JOIN Pelicula_Categoria pc ON pc.pelicula_id = pe.pelicula_id
INNER JOIN Categoria cat ON cat.categoria_id = pc.categoria_id
GROUP BY cat.nombre
ORDER BY tarifa_promedio DESC;
GO

-- Consulta 04: Película más cara y más barata de reemplazar, por año de lanzamiento
-- Objetivo de negocio: Seguros quiere entender cómo varió el costo de
-- reposición de películas a lo largo de los años.
SELECT anio_lanzamiento,
       MAX(costo_reemplazo) AS costo_maximo,
       MIN(costo_reemplazo) AS costo_minimo
FROM Pelicula
GROUP BY anio_lanzamiento
ORDER BY anio_lanzamiento;
GO

-- Consulta 05: Cantidad de alquileres por cliente
-- Objetivo de negocio: Marketing quiere identificar a los clientes más
-- frecuentes para armar un programa de fidelización.
SELECT cliente_id, COUNT(*) AS total_alquileres
FROM Alquiler
GROUP BY cliente_id
ORDER BY total_alquileres DESC;
GO

-- Consulta 06: Sucursales con más de 250 alquileres registrados
-- Objetivo de negocio: Operaciones necesita detectar qué sucursales están
-- por encima de cierto volumen de actividad para reforzar personal.
SELECT s.nombre AS sucursal, COUNT(a.alquiler_id) AS total_alquileres
FROM Alquiler a
INNER JOIN Inventario i ON i.inventario_id = a.inventario_id
INNER JOIN Sucursal s ON s.sucursal_id = i.sucursal_id
GROUP BY s.nombre
HAVING COUNT(a.alquiler_id) > 250
ORDER BY total_alquileres DESC;
GO

-- Consulta 07: Categorías cuyo ingreso total supera los $500
-- Objetivo de negocio: Compras quiere reforzar el stock de los géneros que
-- más ingresos generan, no solo los más alquilados en cantidad.
SELECT cat.nombre AS categoria, SUM(p.monto) AS ingresos
FROM Pago p
INNER JOIN Alquiler a ON a.alquiler_id = p.alquiler_id
INNER JOIN Inventario i ON i.inventario_id = a.inventario_id
INNER JOIN Pelicula_Categoria pc ON pc.pelicula_id = i.pelicula_id
INNER JOIN Categoria cat ON cat.categoria_id = pc.categoria_id
GROUP BY cat.nombre
HAVING SUM(p.monto) > 500
ORDER BY ingresos DESC;
GO

-- Consulta 08: Clientes con más de 5 alquileres (clientes frecuentes)
-- Objetivo de negocio: Atención al cliente quiere ofrecerles un beneficio
-- especial a los clientes más activos del videoclub.
SELECT cliente_id, COUNT(*) AS total_alquileres
FROM Alquiler
GROUP BY cliente_id
HAVING COUNT(*) > 5
ORDER BY total_alquileres DESC;
GO

-- Consulta 09: Cantidad de películas por idioma, solo idiomas con más de 20 títulos
-- Objetivo de negocio: Compras evalúa si conviene seguir sumando películas
-- en idiomas que ya están bien representados o diversificar.
SELECT idi.nombre AS idioma, COUNT(*) AS cantidad_peliculas
FROM Pelicula pe
INNER JOIN Idioma idi ON idi.idioma_id = pe.idioma_id
GROUP BY idi.nombre
HAVING COUNT(*) > 20
ORDER BY cantidad_peliculas DESC;
GO

-- Consulta 10: Desafío integrador — Ingreso total y cantidad de pagos por
-- sucursal, solo sucursales con más de 200 pagos, ordenado de mayor a menor ingreso
-- Objetivo de negocio: Reporte ejecutivo mensual para el directorio, cruzando
-- volumen de actividad con ingresos generados por sucursal.
SELECT s.nombre AS sucursal,
       COUNT(p.pago_id) AS cantidad_pagos,
       SUM(p.monto) AS ingresos_totales
FROM Pago p
INNER JOIN Cliente c ON c.cliente_id = p.cliente_id
INNER JOIN Sucursal s ON s.sucursal_id = c.sucursal_id
GROUP BY s.nombre
HAVING COUNT(p.pago_id) > 200
ORDER BY ingresos_totales DESC;
GO
