/* ============================================================
   01. EXPLORACIÓN DE DATOS — Videoclub
   Primer contacto con las tablas: tamaño, valores distintos, rangos.
   Técnicas: COUNT(), DISTINCT, TOP, MIN/MAX de fechas.
   ============================================================ */

USE Videoclub;
GO

-- Consulta 01: Total de películas en catálogo
-- Objetivo de negocio: Gerencia quiere saber el tamaño total del catálogo.
SELECT COUNT(*) AS total_peliculas
FROM Pelicula;
GO

-- Consulta 02: Total de clientes registrados (activos e inactivos)
-- Objetivo de negocio: Administración necesita el total de clientes en el sistema.
SELECT COUNT(*) AS total_clientes
FROM Cliente;
GO

-- Consulta 03: Categorías de películas disponibles
-- Objetivo de negocio: Compras quiere ver qué géneros maneja el catálogo.
SELECT DISTINCT nombre AS categoria
FROM Categoria
ORDER BY categoria;
GO

-- Consulta 04: Idiomas disponibles en el catálogo
-- Objetivo de negocio: Compras evalúa si conviene sumar más idiomas al catálogo.
SELECT DISTINCT nombre AS idioma
FROM Idioma
ORDER BY idioma;
GO

-- Consulta 05: Clasificaciones de contenido existentes
-- Objetivo de negocio: Atención al cliente necesita saber qué clasificaciones
-- de edad (ATP, +13, +16, +18) maneja el catálogo para asesorar a las familias.
SELECT DISTINCT clasificacion
FROM Pelicula
ORDER BY clasificacion;
GO

-- Consulta 06: Sucursales activas
-- Objetivo de negocio: Dirección quiere el listado de puntos de venta físicos.
SELECT sucursal_id, nombre
FROM Sucursal;
GO

-- Consulta 07: Las 10 películas con mayor costo de reemplazo
-- Objetivo de negocio: Seguros necesita identificar qué títulos representan
-- mayor riesgo económico en caso de pérdida o daño.
SELECT TOP 10 titulo, costo_reemplazo
FROM Pelicula
ORDER BY costo_reemplazo DESC;
GO

-- Consulta 08: Rango de fechas de alta de clientes (primer y último registro)
-- Objetivo de negocio: Marketing quiere saber desde cuándo el sistema tiene
-- clientes cargados, para planificar una campaña de aniversario.
SELECT
    MIN(fecha_alta) AS primer_cliente_registrado,
    MAX(fecha_alta) AS ultimo_cliente_registrado
FROM Cliente;
GO

-- Consulta 09: Cantidad de países desde donde hay clientes
-- Objetivo de negocio: Expansión quiere entender el alcance geográfico actual.
SELECT COUNT(DISTINCT p.pais_id) AS paises_con_clientes
FROM Pais p
INNER JOIN Ciudad c ON c.pais_id = p.pais_id
INNER JOIN Direccion d ON d.ciudad_id = c.ciudad_id
INNER JOIN Cliente cl ON cl.direccion_id = d.direccion_id;
GO

-- Consulta 10: Total de copias físicas en inventario (todas las sucursales)
-- Objetivo de negocio: Operaciones necesita el total de unidades físicas
-- disponibles para alquiler en toda la empresa.
SELECT COUNT(*) AS total_copias_inventario
FROM Inventario;
GO
