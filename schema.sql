-- schema.sql
-- Base de datos de e-commerce para Actividad 4.2: IA y Bases de datos.

DROP DATABASE IF EXISTS ecommerce_ia;
CREATE DATABASE ecommerce_ia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce_ia;

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    telefono VARCHAR(30),
    ciudad VARCHAR(100) NOT NULL,
    estado VARCHAR(100) NOT NULL,
    fecha_registro DATE NOT NULL
);

CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre VARCHAR(140) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente', 'pagado', 'enviado', 'cancelado') NOT NULL DEFAULT 'pendiente',
    total DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_pedido (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    metodo ENUM('tarjeta', 'transferencia', 'paypal', 'efectivo') NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago DATETIME NOT NULL,
    estatus ENUM('aprobado', 'rechazado', 'pendiente') NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

CREATE TABLE envios (
    id_envio INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    empresa VARCHAR(100),
    guia VARCHAR(100),
    fecha_envio DATETIME,
    fecha_entrega DATETIME,
    estatus ENUM('preparando', 'en camino', 'entregado', 'devuelto') NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

CREATE INDEX idx_clientes_ciudad ON clientes(ciudad);
CREATE INDEX idx_clientes_fecha_registro ON clientes(fecha_registro);
CREATE INDEX idx_pedidos_cliente ON pedidos(id_cliente);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_detalle_pedido ON detalle_pedido(id_pedido);
CREATE INDEX idx_detalle_producto ON detalle_pedido(id_producto);
CREATE INDEX idx_productos_stock ON productos(stock_actual, stock_minimo);

INSERT INTO categorias (nombre) VALUES
('Laptops'), ('Celulares'), ('Accesorios'), ('Audio'), ('Monitores'), ('Gaming'), ('Almacenamiento'), ('Redes');

INSERT INTO clientes (nombre, email, telefono, ciudad, estado, fecha_registro) VALUES
('Ana Torres', 'ana.torres@example.com', '555-0101', 'Monterrey', 'Nuevo León', '2026-01-12'),
('Luis Ramírez', 'luis.ramirez@example.com', '555-0102', 'Guadalajara', 'Jalisco', '2026-02-03'),
('María González', 'maria.gonzalez@example.com', '555-0103', 'Ciudad de México', 'CDMX', '2026-03-20'),
('Carlos Méndez', 'carlos.mendez@example.com', '555-0104', 'Puebla', 'Puebla', '2026-04-02'),
('Sofía Hernández', 'sofia.hernandez@example.com', '555-0105', 'Querétaro', 'Querétaro', '2026-04-05'),
('Diego López', 'diego.lopez@example.com', '555-0106', 'Monterrey', 'Nuevo León', '2026-04-10'),
('Valeria Cruz', 'valeria.cruz@example.com', '555-0107', 'Mérida', 'Yucatán', '2026-04-13'),
('Jorge Castillo', 'jorge.castillo@example.com', '555-0108', 'Tijuana', 'Baja California', '2026-04-18'),
('Fernanda Ruiz', 'fernanda.ruiz@example.com', '555-0109', 'Guadalajara', 'Jalisco', '2026-05-01'),
('Ricardo Pérez', 'ricardo.perez@example.com', '555-0110', 'Ciudad de México', 'CDMX', '2026-05-03'),
('Camila Soto', 'camila.soto@example.com', '555-0111', 'León', 'Guanajuato', '2026-05-04'),
('Andrés Vega', 'andres.vega@example.com', '555-0112', 'Monterrey', 'Nuevo León', '2026-05-06'),
('Paola Navarro', 'paola.navarro@example.com', '555-0113', 'Toluca', 'Estado de México', '2026-05-07'),
('Emiliano Flores', 'emiliano.flores@example.com', '555-0114', 'Cancún', 'Quintana Roo', '2026-05-08'),
('Daniela Ríos', 'daniela.rios@example.com', '555-0115', 'Guadalajara', 'Jalisco', '2026-05-09'),
('Hugo Molina', 'hugo.molina@example.com', '555-0116', 'Puebla', 'Puebla', '2026-05-10'),
('Regina Salas', 'regina.salas@example.com', '555-0117', 'Mérida', 'Yucatán', '2026-05-11'),
('Mateo Ortiz', 'mateo.ortiz@example.com', '555-0118', 'Ciudad de México', 'CDMX', '2026-05-12'),
('Lucía Cabrera', 'lucia.cabrera@example.com', '555-0119', 'Monterrey', 'Nuevo León', '2026-05-13'),
('Sebastián Aguilar', 'sebastian.aguilar@example.com', '555-0120', 'Querétaro', 'Querétaro', '2026-05-14');

INSERT INTO productos (id_categoria, nombre, precio, stock_actual, stock_minimo, activo) VALUES
(1, 'Laptop Ultrabook 14', 18500.00, 12, 4, 1),
(1, 'Laptop Gamer RTX', 32999.00, 5, 3, 1),
(1, 'Laptop Ejecutiva Pro', 24500.00, 3, 5, 1),
(2, 'Smartphone Nova X', 11999.00, 20, 8, 1),
(2, 'Smartphone Pixel Max', 15999.00, 6, 6, 1),
(2, 'Smartphone Económico A1', 4999.00, 25, 10, 1),
(3, 'Teclado Mecánico RGB', 1450.00, 30, 10, 1),
(3, 'Mouse Inalámbrico Pro', 890.00, 8, 10, 1),
(3, 'Hub USB-C 7 en 1', 1250.00, 4, 8, 1),
(4, 'Audífonos Noise Cancelling', 3999.00, 14, 5, 1),
(4, 'Bocina Bluetooth Mini', 1299.00, 18, 6, 1),
(4, 'Micrófono Streaming', 2199.00, 7, 5, 1),
(5, 'Monitor 24 pulgadas', 3899.00, 9, 4, 1),
(5, 'Monitor 27 pulgadas 4K', 8999.00, 2, 4, 1),
(5, 'Monitor Curvo Gaming', 7499.00, 4, 4, 1),
(6, 'Control inalámbrico Gaming', 1599.00, 16, 6, 1),
(6, 'Silla Gamer Ergonómica', 5999.00, 3, 4, 1),
(6, 'Mousepad XL RGB', 699.00, 40, 10, 1),
(7, 'SSD 1TB NVMe', 2299.00, 11, 5, 1),
(7, 'Disco Duro Externo 2TB', 1899.00, 6, 5, 1),
(7, 'Memoria USB 128GB', 399.00, 60, 15, 1),
(8, 'Router WiFi 6', 2499.00, 5, 5, 1),
(8, 'Switch 8 Puertos', 999.00, 9, 5, 1),
(8, 'Adaptador WiFi USB', 499.00, 20, 8, 1);

INSERT INTO pedidos (id_cliente, fecha_pedido, estado, total) VALUES
(1, '2026-01-15 10:12:00', 'pagado', 19950),
(2, '2026-01-18 16:45:00', 'enviado', 12889),
(3, '2026-02-02 09:30:00', 'pagado', 32999),
(4, '2026-02-15 14:05:00', 'cancelado', 3899),
(5, '2026-03-01 18:20:00', 'pagado', 18999),
(6, '2026-03-08 11:15:00', 'enviado', 6598),
(7, '2026-03-15 20:42:00', 'pagado', 11999),
(8, '2026-03-22 13:10:00', 'pendiente', 8999),
(9, '2026-04-01 08:55:00', 'pagado', 24500),
(10, '2026-04-03 19:30:00', 'pendiente', 7499),
(11, '2026-04-05 12:00:00', 'pagado', 5098),
(12, '2026-04-07 15:17:00', 'enviado', 15999),
(13, '2026-04-10 09:05:00', 'pagado', 2299),
(14, '2026-04-12 21:10:00', 'pendiente', 6898),
(15, '2026-04-15 10:45:00', 'pagado', 10449),
(16, '2026-04-18 17:25:00', 'enviado', 18500),
(17, '2026-04-20 22:15:00', 'pendiente', 5999),
(18, '2026-04-22 07:40:00', 'pagado', 4298),
(19, '2026-04-25 13:35:00', 'pagado', 32999),
(20, '2026-04-28 16:05:00', 'cancelado', 2499),
(1, '2026-05-01 09:12:00', 'pagado', 8999),
(2, '2026-05-02 11:31:00', 'pendiente', 5698),
(3, '2026-05-03 15:44:00', 'pagado', 15999),
(4, '2026-05-04 18:05:00', 'enviado', 747),
(5, '2026-05-05 20:50:00', 'pagado', 3700),
(6, '2026-05-06 08:10:00', 'pendiente', 11999),
(7, '2026-05-07 12:22:00', 'pagado', 5198),
(8, '2026-05-08 14:37:00', 'pagado', 18500),
(9, '2026-05-09 16:48:00', 'pendiente', 32999),
(10, '2026-05-10 19:01:00', 'enviado', 4499),
(11, '2026-05-11 21:16:00', 'pagado', 1398),
(12, '2026-05-12 10:30:00', 'pagado', 2499),
(13, '2026-05-13 13:43:00', 'pendiente', 8999),
(14, '2026-05-14 17:18:00', 'pagado', 24500),
(15, '2026-05-15 22:05:00', 'pagado', 4598),
(16, '2026-05-16 09:33:00', 'pendiente', 7499),
(17, '2026-05-17 11:21:00', 'pagado', 15999),
(18, '2026-05-18 18:42:00', 'enviado', 32999),
(19, '2026-05-19 20:15:00', 'pendiente', 12998),
(20, '2026-05-20 07:55:00', 'pagado', 9698);

INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 1, 18500, 18500),
(1, 7, 1, 1450, 1450),
(2, 4, 1, 11999, 11999),
(2, 8, 1, 890, 890),
(3, 2, 1, 32999, 32999),
(4, 13, 1, 3899, 3899),
(5, 5, 1, 15999, 15999),
(5, 10, 1, 3999, 3999),
(5, 21, 1, 399, 399),
(6, 17, 1, 5999, 5999),
(6, 18, 1, 699, 699),
(7, 4, 1, 11999, 11999),
(8, 14, 1, 8999, 8999),
(9, 3, 1, 24500, 24500),
(10, 15, 1, 7499, 7499),
(11, 20, 2, 1899, 3798),
(11, 21, 2, 399, 798),
(11, 24, 1, 499, 499),
(12, 5, 1, 15999, 15999),
(13, 19, 1, 2299, 2299),
(14, 10, 1, 3999, 3999),
(14, 19, 1, 2299, 2299),
(14, 21, 1, 399, 399),
(15, 13, 1, 3899, 3899),
(15, 12, 3, 2199, 6597),
(16, 1, 1, 18500, 18500),
(17, 17, 1, 5999, 5999),
(18, 19, 1, 2299, 2299),
(18, 11, 1, 1299, 1299),
(18, 18, 1, 699, 699),
(19, 2, 1, 32999, 32999),
(20, 22, 1, 2499, 2499),
(21, 14, 1, 8999, 8999),
(22, 7, 2, 1450, 2900),
(22, 10, 1, 3999, 3999),
(23, 5, 1, 15999, 15999),
(24, 21, 1, 399, 399),
(24, 24, 1, 499, 499),
(25, 19, 1, 2299, 2299),
(25, 7, 1, 1450, 1450),
(26, 4, 1, 11999, 11999),
(27, 11, 4, 1299, 5196),
(28, 1, 1, 18500, 18500),
(29, 2, 1, 32999, 32999),
(30, 22, 1, 2499, 2499),
(30, 20, 1, 1899, 1899),
(30, 21, 1, 399, 399),
(31, 18, 2, 699, 1398),
(32, 22, 1, 2499, 2499),
(33, 14, 1, 8999, 8999),
(34, 3, 1, 24500, 24500),
(35, 19, 2, 2299, 4598),
(36, 15, 1, 7499, 7499),
(37, 5, 1, 15999, 15999),
(38, 2, 1, 32999, 32999),
(39, 4, 1, 11999, 11999),
(39, 24, 2, 499, 998),
(40, 13, 1, 3899, 3899),
(40, 10, 1, 3999, 3999),
(40, 18, 2, 699, 1398);

INSERT INTO pagos (id_pedido, metodo, monto, fecha_pago, estatus) VALUES
(1, 'paypal', 19950, '2026-01-15 10:12:00', 'aprobado'),
(2, 'transferencia', 12889, '2026-01-18 16:45:00', 'aprobado'),
(3, 'efectivo', 32999, '2026-02-02 09:30:00', 'aprobado'),
(4, 'tarjeta', 0, '2026-02-15 14:05:00', 'rechazado'),
(5, 'paypal', 18999, '2026-03-01 18:20:00', 'aprobado'),
(6, 'transferencia', 6598, '2026-03-08 11:15:00', 'aprobado'),
(7, 'efectivo', 11999, '2026-03-15 20:42:00', 'aprobado'),
(8, 'tarjeta', 0, '2026-03-22 13:10:00', 'pendiente'),
(9, 'paypal', 24500, '2026-04-01 08:55:00', 'aprobado'),
(10, 'transferencia', 0, '2026-04-03 19:30:00', 'pendiente'),
(11, 'efectivo', 5098, '2026-04-05 12:00:00', 'aprobado'),
(12, 'tarjeta', 15999, '2026-04-07 15:17:00', 'aprobado'),
(13, 'paypal', 2299, '2026-04-10 09:05:00', 'aprobado'),
(14, 'transferencia', 0, '2026-04-12 21:10:00', 'pendiente'),
(15, 'efectivo', 10449, '2026-04-15 10:45:00', 'aprobado'),
(16, 'tarjeta', 18500, '2026-04-18 17:25:00', 'aprobado'),
(17, 'paypal', 0, '2026-04-20 22:15:00', 'pendiente'),
(18, 'transferencia', 4298, '2026-04-22 07:40:00', 'aprobado'),
(19, 'efectivo', 32999, '2026-04-25 13:35:00', 'aprobado'),
(20, 'tarjeta', 0, '2026-04-28 16:05:00', 'rechazado'),
(21, 'paypal', 8999, '2026-05-01 09:12:00', 'aprobado'),
(22, 'transferencia', 0, '2026-05-02 11:31:00', 'pendiente'),
(23, 'efectivo', 15999, '2026-05-03 15:44:00', 'aprobado'),
(24, 'tarjeta', 747, '2026-05-04 18:05:00', 'aprobado'),
(25, 'paypal', 3700, '2026-05-05 20:50:00', 'aprobado'),
(26, 'transferencia', 0, '2026-05-06 08:10:00', 'pendiente'),
(27, 'efectivo', 5198, '2026-05-07 12:22:00', 'aprobado'),
(28, 'tarjeta', 18500, '2026-05-08 14:37:00', 'aprobado'),
(29, 'paypal', 0, '2026-05-09 16:48:00', 'pendiente'),
(30, 'transferencia', 4499, '2026-05-10 19:01:00', 'aprobado'),
(31, 'efectivo', 1398, '2026-05-11 21:16:00', 'aprobado'),
(32, 'tarjeta', 2499, '2026-05-12 10:30:00', 'aprobado'),
(33, 'paypal', 0, '2026-05-13 13:43:00', 'pendiente'),
(34, 'transferencia', 24500, '2026-05-14 17:18:00', 'aprobado'),
(35, 'efectivo', 4598, '2026-05-15 22:05:00', 'aprobado'),
(36, 'tarjeta', 0, '2026-05-16 09:33:00', 'pendiente'),
(37, 'paypal', 15999, '2026-05-17 11:21:00', 'aprobado'),
(38, 'transferencia', 32999, '2026-05-18 18:42:00', 'aprobado'),
(39, 'efectivo', 0, '2026-05-19 20:15:00', 'pendiente'),
(40, 'tarjeta', 9698, '2026-05-20 07:55:00', 'aprobado');

INSERT INTO envios (id_pedido, empresa, guia, fecha_envio, fecha_entrega, estatus) VALUES
(2, 'DHL', 'DHL10002', '2026-01-19 09:00:00', '2026-01-21 15:00:00', 'entregado'),
(6, 'FedEx', 'FDX10006', '2026-03-09 10:00:00', '2026-03-12 18:00:00', 'entregado'),
(12, 'Estafeta', 'EST10012', '2026-04-08 08:00:00', '2026-04-11 16:00:00', 'entregado'),
(16, 'DHL', 'DHL10016', '2026-04-19 09:30:00', '2026-04-21 12:10:00', 'entregado'),
(23, 'FedEx', 'FDX10023', '2026-05-04 08:00:00', '2026-05-06 11:00:00', 'entregado'),
(28, 'DHL', 'DHL10028', '2026-05-09 12:00:00', '2026-05-11 17:30:00', 'entregado'),
(30, 'Estafeta', 'EST10030', '2026-05-11 10:30:00', NULL, 'en camino'),
(36, 'FedEx', 'FDX10036', NULL, NULL, 'preparando'),
(38, 'DHL', 'DHL10038', '2026-05-19 08:00:00', NULL, 'en camino'),
(40, 'Estafeta', 'EST10040', '2026-05-20 11:00:00', NULL, 'en camino');
