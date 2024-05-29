REM ----------------------------------------- AJUSTE DE SALIDA -----------------------------------------

SET ECHO OFF
SET VERIFY OFF
SET LINESIZE 1000
SET PAGESIZE 30000
SET TRIMSPOOL ON

REM ----------------------------------------------------------------------------------------------------


REM -------------------------- CONEXIÓN A LA BASE DE DATOS COMO ADMINISTRADOR --------------------------

DISCONN
CONN sys/oracle@localhost:1521/xepdb1 as SYSDBA
SHOW CON_NAME

REM ----------------------------------------------------------------------------------------------------


REM ---------------------------- CREACIÓN DEL USUARIO Y CESIÓN DE PERMISOS -----------------------------

PROMPT
PROMPT Define tu usuario:
DEFINE user_hotel = &userHotel
PROMPT Define una clave para el usuario &user_hotel:
DEFINE password = &pass
PROMPT
SPOOL ./hotel_setup.log

DROP USER &user_hotel CASCADE;

CREATE USER &user_hotel IDENTIFIED BY &password;

ALTER USER &user_hotel DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
ALTER USER &user_hotel TEMPORARY TABLESPACE temp;

GRANT CREATE SESSION, CREATE VIEW, ALTER SESSION, CREATE SEQUENCE TO &user_hotel;
GRANT CREATE SYNONYM, CREATE DATABASE LINK, RESOURCE , UNLIMITED TABLESPACE TO &user_hotel;
GRANT execute ON sys.dbms_stats TO &user_hotel;

REM ----------------------------------------------------------------------------------------------------


REM ---------------------- CONEXIÓN A LA BASE DE DATOS CON EL NUEVO USUARIO ----------------------------

CONNECT &user_hotel/&password@localhost:1521/xepdb1
ALTER SESSION SET NLS_LANGUAGE=American;
ALTER SESSION SET NLS_TERRITORY=America;

REM ----------------------------------------------------------------------------------------------------

REM ---------------------------------------- CREACIÓN DE TABLAS ----------------------------------------

CREATE TABLE huespedes (
    id_huesped NUMBER(10) CONSTRAINT id_hues_nn NOT NULL,
    nombre NVARCHAR2(30),
    email VARCHAR2(30),
    telefono VARCHAR2(20)
);

ALTER TABLE huespedes ADD (
    CONSTRAINT id_hues_pk PRIMARY KEY (id_huesped),
    CONSTRAINT em_arrob CHECK (INSTR(email, '@') > 0),
    CONSTRAINT em_un UNIQUE (email)
);

CREATE TABLE opiniones (
    id_opinion NUMBER(10) CONSTRAINT id_op_nn NOT NULL,
    id_huesped NUMBER(10),
    comentario VARCHAR2(500),
    puntuacion NUMBER(2),
    fecha DATE
);

ALTER TABLE opiniones ADD (
    CONSTRAINT id_op_pk PRIMARY KEY (id_opinion),
    CONSTRAINT id_hues_fk FOREIGN KEY (id_huesped) REFERENCES huespedes (id_huesped)
);

CREATE TABLE servicios (
    id_servicio NUMBER(10) CONSTRAINT id_ser_nn NOT NULL,
    nombre_servicio VARCHAR2(30),
    descripcion VARCHAR2(500),
    precio NUMBER(10, 2)
);

ALTER TABLE servicios ADD (
    CONSTRAINT id_ser_pk PRIMARY KEY (id_servicio)
);

CREATE TABLE habitaciones (
    id_habitacion NUMBER(10) CONSTRAINT id_hab_nn NOT NULL,
    tipo VARCHAR2(100),
    precio NUMBER(10, 2),
    capacidad NUMBER(3)
);

ALTER TABLE habitaciones ADD (
    CONSTRAINT id_hab_pk PRIMARY KEY (id_habitacion)
);

CREATE TABLE reservas (
    id_reserva NUMBER(10) CONSTRAINT id_res_nn NOT NULL,
    id_habitacion NUMBER(10),
    id_huesped NUMBER(10),
    fecha_entrada DATE,
    fecha_salida DATE
);

ALTER TABLE reservas ADD (
    CONSTRAINT id_res_pk PRIMARY KEY (id_reserva),
    CONSTRAINT id_hab_fk FOREIGN KEY (id_habitacion) REFERENCES habitaciones (id_habitacion),
    CONSTRAINT id_hue_fk FOREIGN KEY (id_huesped) REFERENCES huespedes (id_huesped)
);

CREATE TABLE pagos (
    id_pago NUMBER(10) CONSTRAINT id_pag_nn NOT NULL,
    id_reserva NUMBER(10),
    monto NUMBER(10, 2),
    fecha DATE,
    metodo_pago VARCHAR2(50)
);

ALTER TABLE pagos ADD (
    CONSTRAINT id_pag_pk PRIMARY KEY (id_pago),
    CONSTRAINT id_res_un UNIQUE (id_reserva),
    CONSTRAINT id_res_fk FOREIGN KEY (id_reserva) REFERENCES reservas (id_reserva)
);

CREATE TABLE promociones (
    id_promocion NUMBER(10) CONSTRAINT id_prom_nn NOT NULL,
    descripcion VARCHAR2(500),
    descuento NUMBER(5, 2),
    fecha_inicio DATE,
    fecha_fin DATE
);

ALTER TABLE promociones ADD (
    CONSTRAINT id_prom_pk PRIMARY KEY (id_promocion),
    CONSTRAINT check_fechas CHECK (fecha_inicio <= fecha_fin)
);

CREATE TABLE reservas_promociones (
    id_reserva NUMBER(10),
    id_promocion NUMBER(10)
);

ALTER TABLE reservas_promociones ADD (
    CONSTRAINT id_res_prom_pk PRIMARY KEY (id_reserva, id_promocion),
    CONSTRAINT id_res_prom_fk FOREIGN KEY (id_reserva) REFERENCES reservas (id_reserva),
    CONSTRAINT id_prom_res_fk FOREIGN KEY (id_promocion) REFERENCES promociones (id_promocion)
);

REM ----------------------------------------------------------------------------------------------------

REM ------------------------------------- CREACIÓN DE DISPARADORES -------------------------------------

CREATE OR REPLACE TRIGGER trg_reservas
AFTER INSERT OR UPDATE OR DELETE ON reservas FOR EACH ROW
BEGIN
    IF UPDATING THEN
        DELETE FROM reservas_promociones
        WHERE id_reserva = :OLD.id_reserva;
    END IF;

    INSERT INTO reservas_promociones (id_reserva, id_promocion)
    SELECT :NEW.id_reserva, p.id_promocion
    FROM promociones p
    WHERE ((SELECT COUNT(*) FROM reservas_promociones WHERE id_reserva = :NEW.id_reserva) < 3) AND (:NEW.fecha_entrada BETWEEN p.fecha_inicio AND p.fecha_fin);

    IF DELETING THEN
        DELETE FROM reservas_promociones
        WHERE id_reserva = :OLD.id_reserva;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_promociones
AFTER INSERT OR UPDATE OR DELETE ON promociones FOR EACH ROW
BEGIN
    IF UPDATING THEN
        DELETE FROM reservas_promociones
        WHERE id_promocion = :OLD.id_promocion;
    END IF;

    INSERT INTO reservas_promociones (id_reserva, id_promocion)
    SELECT r.id_reserva, :NEW.id_promocion
    FROM reservas r
    WHERE ((SELECT COUNT(*) FROM reservas_promociones WHERE id_reserva = r.id_reserva) < 3) AND (r.fecha_entrada BETWEEN :NEW.fecha_inicio AND :NEW.fecha_fin);

    IF DELETING THEN
        DELETE FROM reservas_promociones
        WHERE id_promocion = :OLD.id_promocion;
    END IF;
END;
/

REM ----------------------------------------------------------------------------------------------------


REM -------------------------------------- COMENTARIOS AL ESQUEMA --------------------------------------

COMMENT ON TABLE huespedes
IS 'Tabla que almacena la información de los huéspedes';
COMMENT ON COLUMN huespedes.id_huesped
IS 'Identificador único del huésped';
COMMENT ON COLUMN huespedes.nombre
IS 'Nombre del huésped';
COMMENT ON COLUMN huespedes.email
IS 'Correo electrónico del huésped, debe contener un "@" y ser único';
COMMENT ON COLUMN huespedes.telefono
IS 'Número de teléfono del huésped';

COMMENT ON TABLE opiniones
IS 'Tabla que almacena las opiniones de los huéspedes sobre su estancia';
COMMENT ON COLUMN opiniones.id_opinion
IS 'Identificador único de la opinión';
COMMENT ON COLUMN opiniones.id_huesped
IS 'Identificador del huésped que dejó la opinión';
COMMENT ON COLUMN opiniones.comentario
IS 'Comentario del huésped sobre su estancia (máximo 500 caracteres)';
COMMENT ON COLUMN opiniones.puntuacion
IS 'Puntuación otorgada por el huésped (valor entre 0 y 99)';
COMMENT ON COLUMN opiniones.fecha
IS 'Fecha en la que se dejó la opinión';

COMMENT ON TABLE servicios
IS 'Tabla que almacena información sobre los servicios ofrecidos por el establecimiento';
COMMENT ON COLUMN servicios.id_servicio
IS 'Identificador único del servicio';
COMMENT ON COLUMN servicios.nombre_servicio
IS 'Nombre del servicio ofrecido';
COMMENT ON COLUMN servicios.descripcion
IS 'Descripción detallada del servicio (máximo 500 caracteres)';
COMMENT ON COLUMN servicios.precio
IS 'Precio del servicio';

COMMENT ON TABLE habitaciones
IS 'Tabla que almacena información sobre las habitaciones disponibles en el establecimiento';
COMMENT ON COLUMN habitaciones.id_habitacion
IS 'Identificador único de la habitación';
COMMENT ON COLUMN habitaciones.tipo
IS 'Tipo de habitación';
COMMENT ON COLUMN habitaciones.precio
IS 'Precio de la habitación por noche';
COMMENT ON COLUMN habitaciones.capacidad
IS 'Capacidad máxima de personas que pueden alojarse en la habitación';

COMMENT ON TABLE reservas
IS 'Tabla que almacena información sobre las reservas de habitaciones realizadas por los huéspedes';
COMMENT ON COLUMN reservas.id_reserva
IS 'Identificador único de la reserva';
COMMENT ON COLUMN reservas.id_habitacion
IS 'Identificador de la habitación reservada';
COMMENT ON COLUMN reservas.id_huesped
IS 'Identificador del huésped que realizó la reserva';
COMMENT ON COLUMN reservas.fecha_entrada
IS 'Fecha de entrada para la reserva';
COMMENT ON COLUMN reservas.fecha_salida
IS 'Fecha de salida para la reserva';

COMMENT ON TABLE pagos
IS 'Tabla que almacena información sobre los pagos realizados por los huéspedes';
COMMENT ON COLUMN pagos.id_pago
IS 'Identificador único del pago';
COMMENT ON COLUMN pagos.id_reserva
IS 'Identificador de la reserva asociada al pago';
COMMENT ON COLUMN pagos.monto
IS 'Monto del pago';
COMMENT ON COLUMN pagos.fecha
IS 'Fecha en que se realizó el pago';
COMMENT ON COLUMN pagos.metodo_pago
IS 'Método de pago utilizado';

COMMENT ON TABLE promociones
IS 'Tabla que almacena información sobre las promociones disponibles en el establecimiento';
COMMENT ON COLUMN promociones.id_promocion
IS 'Identificador único de la promoción';
COMMENT ON COLUMN promociones.descripcion
IS 'Descripción de la promoción (máximo 500 caracteres)';
COMMENT ON COLUMN promociones.descuento
IS 'Descuento aplicado por la promoción (en porcentaje)';
COMMENT ON COLUMN promociones.fecha_inicio
IS 'Fecha de inicio de la promoción';
COMMENT ON COLUMN promociones.fecha_fin
IS 'Fecha de finalización de la promoción';

COMMENT ON TABLE reservas_promociones
IS 'Tabla que almacena las relaciones entre reservas y promociones';
COMMENT ON COLUMN reservas_promociones.id_reserva
IS 'Identificador de la reserva';
COMMENT ON COLUMN reservas_promociones.id_promocion
IS 'Identificador de la promoción';

REM ----------------------------------------------------------------------------------------------------


REM --------------------------------------- POPULACIÓN DE TABLAS ---------------------------------------

INSERT INTO huespedes VALUES (1234567890, 'Juan Pérez', 'juanperez@hotmail.com', '3101234567');
INSERT INTO huespedes VALUES (1234567891, 'María Gómez', 'mariagomez@gmail.com', '3157654321');
INSERT INTO huespedes VALUES (1234567892, 'Carlos López', 'carloslopez@outlook.com', '3209876543');
INSERT INTO huespedes VALUES (1234567893, 'Ana Martínez', 'anamartinez@hotmail.com', '3176543210');
INSERT INTO huespedes VALUES (1234567894, 'Pedro Rodríguez', 'pedrorodriguez@yahoo.com', '3101234890');
INSERT INTO huespedes VALUES (1234567895, 'Laura Sánchez', 'laurasanchez@gmail.com', '3187654321');
INSERT INTO huespedes VALUES (1234567896, 'Andrés González', 'andresgonzalez@gmail.com', '3120987654');
INSERT INTO huespedes VALUES (1234567897, 'Sofía Ramírez', 'sofiaramirez@gmail.com', '3112345678');
INSERT INTO huespedes VALUES (1234567898, 'Luisa Hernández', 'luisahernandez@yahoo.com', '3198765432');
INSERT INTO huespedes VALUES (1234567899, 'Diego Díaz', 'diegodiaz@hotmail.com', '3145678901');
INSERT INTO huespedes VALUES (2234567890, 'Valentina Álvarez', 'valentinaalvarez@outlook.com', '3109876543');
INSERT INTO huespedes VALUES (2234567891, 'Javier Castro', 'javiercastro@outlook.com', '3176543120');
INSERT INTO huespedes VALUES (2234567892, 'Camila Gutiérrez', 'camilagutierrez@yahoo.com', '3187654309');
INSERT INTO huespedes VALUES (2234567893, 'Daniel Ruiz', 'danielruiz@yahoo.com', '3112345789');
INSERT INTO huespedes VALUES (2234567894, 'Natalia Ospina', 'nataliaospina@outlook.com', '3120987564');
INSERT INTO huespedes VALUES (2234567895, 'Gabriel Vargas', 'gabrielvargas@gmail.com', '3198765342');
INSERT INTO huespedes VALUES (2234567896, 'Paula López', 'paulalopez@hotmail.com', '3145678908');
INSERT INTO huespedes VALUES (2234567897, 'Andrea Soto', 'andreasoto@outlook.com', '3109876453');
INSERT INTO huespedes VALUES (2234567898, 'Sebastián Ríos', 'sebastianrios@yahoo.com', '3176543209');
INSERT INTO huespedes VALUES (2234567899, 'Manuela Gómez', 'manuelagomez@gmail.com', '3187654390');

INSERT INTO opiniones VALUES (  1, 1234567890, 'Excelente servicio y atención.', 95, TO_DATE('2024-06-06', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (2, 1234567891, 'Muy buena experiencia.', 90, TO_DATE('2024-06-16', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (3, 1234567892, 'Habitaciones limpias y comodas.', 95, TO_DATE('2024-06-18', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (4, 1234567893, 'El personal fue muy amable y servicial.', 85, TO_DATE('2024-06-25', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (5, 1234567894, 'Las instalaciones estaban impecables.', 98, TO_DATE('2024-07-03', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (6, 1234567895, 'La comida del restaurante era deliciosa.', 92, TO_DATE('2024-07-10', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (7, 1234567896, 'Volvería sin dudarlo.', 94, TO_DATE('2024-07-15', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (8, 1234567897, 'Excelente ubicación y vistas increíbles.', 96, TO_DATE('2024-07-22', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (9, 1234567898, 'El spa era muy relajante.', 88, TO_DATE('2024-07-30', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (10, 1234567899, 'El desayuno era variado y delicioso.', 90, TO_DATE('2024-08-05', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (11, 2234567890, 'El personal de recepción fue muy atento.', 88, TO_DATE('2024-08-12', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (12, 2234567891, 'Las instalaciones estaban muy limpias y bien mantenidas.', 95, TO_DATE('2024-08-20', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (13, 2234567892, 'La conexión Wi-Fi era rápida y estable.', 92, TO_DATE('2024-08-25', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (14, 2234567893, 'Las camas eran muy cómodas.', 96, TO_DATE('2024-09-02', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (15, 2234567894, 'El servicio de limpieza era impecable.', 94, TO_DATE('2024-09-10', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (16, 2234567895, 'El servicio de habitaciones fue rápido y eficiente.', 93, TO_DATE('2024-09-15', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (17, 2234567896, 'El ambiente del hotel era muy tranquilo y relajante.', 94, TO_DATE('2024-10-10', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (18, 2234567897, 'El check-in fue rápido y sin complicaciones.', 88, TO_DATE('2024-09-25', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (19, 2234567898, 'La relación calidad-precio fue excelente.', 91, TO_DATE('2024-10-01', 'YYYY-MM-DD'));
INSERT INTO opiniones VALUES (20, 2234567899, 'El gimnasio estaba bien equipado.', 89, TO_DATE('2024-10-05', 'YYYY-MM-DD'));

INSERT INTO servicios VALUES (1, 'Spa', 'Tratamiento relajante en el spa', 120000.00);
INSERT INTO servicios VALUES (2, 'Desayuno Buffet', 'Desayuno buffet disponible de 7:00 a.m. a 10:00 a.m.', 30000.00);
INSERT INTO servicios VALUES (3, 'Cena Romántica', 'Cena romántica para dos personas', 150000.00);
INSERT INTO servicios VALUES (4, 'Excursión', 'Excursión guiada a sitios turísticos locales', 80000.00);
INSERT INTO servicios VALUES (5, 'Traslado al Aeropuerto', 'servicios de traslado al aeropuerto en vehículo privado', 50000.00);
INSERT INTO servicios VALUES (6, 'Gimnasio', 'Acceso ilimitado al gimnasio del hotel', 20000.00);
INSERT INTO servicios VALUES (7, 'Lavandería', 'servicios de lavandería y planchado', 35000.00);
INSERT INTO servicios VALUES (8, 'Alquiler de Bicicletas', 'Alquiler de bicicletas por día', 25000.00);
INSERT INTO servicios VALUES (9, 'Masaje', 'Masaje de una hora en el spa', 100000.00);
INSERT INTO servicios VALUES (10, 'Sala de Conferencias', 'Alquiler de sala de conferencias por día', 200000.00);
INSERT INTO servicios VALUES (11, 'servicios a la Habitación', 'servicios a la habitación las 24 horas', 40000.00);
INSERT INTO servicios VALUES (12, 'Mini Bar', 'Consumo del mini bar en la habitación', 50000.00);
INSERT INTO servicios VALUES (13, 'Clases de Yoga', 'Clases de yoga diarias en la mañana', 15000.00);
INSERT INTO servicios VALUES (14, 'Cuidado de Niños', 'servicios de cuidado de niños por hora', 30000.00);
INSERT INTO servicios VALUES (15, 'Paseo a Caballo', 'Paseo a caballo de dos horas', 60000.00);
INSERT INTO servicios VALUES (16, 'Tour de Vinos', 'Tour de vinos con degustación incluida', 90000.00);
INSERT INTO servicios VALUES (17, 'Tratamiento Facial', 'Tratamiento facial completo en el spa', 85000.00);
INSERT INTO servicios VALUES (18, 'Manicura/Pedicura', 'servicios de manicura y pedicura', 45000.00);
INSERT INTO servicios VALUES (19, 'Desayuno en la Habitación', 'Desayuno servido en la habitación', 35000.00);
INSERT INTO servicios VALUES (20, 'Paquete Romántico', 'Paquete romántico que incluye cena, spa y decoración especial en la habitación', 200000.00);

INSERT INTO habitaciones VALUES (1001, 'Sencilla', 100000, 1);
INSERT INTO habitaciones VALUES (1002, 'Doble', 150000, 2);
INSERT INTO habitaciones VALUES (1003, 'Suite', 200000, 2);
INSERT INTO habitaciones VALUES (1004, 'VIP', 300000, 2);
INSERT INTO habitaciones VALUES (1005, 'Doble', 350000, 4);
INSERT INTO habitaciones VALUES (2001, 'Suite', 280000, 2);
INSERT INTO habitaciones VALUES (2002, 'Sencilla', 200000, 2);
INSERT INTO habitaciones VALUES (2003, 'VIP', 350000, 2);
INSERT INTO habitaciones VALUES (2004, 'Sencilla', 3000000, 3);
INSERT INTO habitaciones VALUES (2005, 'Doble', 160000, 2);
INSERT INTO habitaciones VALUES (3001, 'Suite', 230000, 2);
INSERT INTO habitaciones VALUES (3002, 'VIP', 320000, 2);
INSERT INTO habitaciones VALUES (3003, 'Doble', 155000, 2);
INSERT INTO habitaciones VALUES (3004, 'Sencilla', 105000, 1);
INSERT INTO habitaciones VALUES (3005, 'VIP', 310000, 2);
INSERT INTO habitaciones VALUES (4001, 'Suite', 240000, 2);
INSERT INTO habitaciones VALUES (4002, 'Sencilla', 115000, 1);
INSERT INTO habitaciones VALUES (4003, 'Doble', 170000, 2);
INSERT INTO habitaciones VALUES (4004, 'Suite', 460000, 4);
INSERT INTO habitaciones VALUES (4005, 'VIP', 500000, 4);

INSERT INTO reservas VALUES (501, 1001, 1234567890, TO_DATE('2024-06-01', 'YYYY-MM-DD'), TO_DATE('2024-06-05', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (502, 1002, 1234567891, TO_DATE('2024-06-03', 'YYYY-MM-DD'), TO_DATE('2024-06-07', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (503, 1003, 1234567892, TO_DATE('2024-06-02', 'YYYY-MM-DD'), TO_DATE('2024-06-06', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (504, 1004, 1234567893, TO_DATE('2024-06-04', 'YYYY-MM-DD'), TO_DATE('2024-06-08', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (505, 1005, 1234567894, TO_DATE('2024-06-01', 'YYYY-MM-DD'), TO_DATE('2024-06-10', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (506, 2001, 1234567895, TO_DATE('2024-06-05', 'YYYY-MM-DD'), TO_DATE('2024-06-09', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (507, 2002, 1234567896, TO_DATE('2024-06-06', 'YYYY-MM-DD'), TO_DATE('2024-06-10', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (508, 2003, 1234567897, TO_DATE('2024-06-08', 'YYYY-MM-DD'), TO_DATE('2024-06-14', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (509, 2004, 1234567898, TO_DATE('2024-06-03', 'YYYY-MM-DD'), TO_DATE('2024-06-07', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (510, 2005, 1234567899, TO_DATE('2024-06-04', 'YYYY-MM-DD'), TO_DATE('2024-06-08', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (511, 3001, 2234567890, TO_DATE('2024-06-06', 'YYYY-MM-DD'), TO_DATE('2024-06-11', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (512, 3002, 2234567891, TO_DATE('2024-06-05', 'YYYY-MM-DD'), TO_DATE('2024-06-10', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (513, 3003, 2234567892, TO_DATE('2024-06-07', 'YYYY-MM-DD'), TO_DATE('2024-06-12', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (514, 3004, 2234567893, TO_DATE('2024-06-09', 'YYYY-MM-DD'), TO_DATE('2024-06-14', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (515, 3005, 2234567894, TO_DATE('2024-06-10', 'YYYY-MM-DD'), TO_DATE('2024-06-15', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (516, 4001, 2234567895, TO_DATE('2024-06-11', 'YYYY-MM-DD'), TO_DATE('2024-06-16', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (517, 4002, 2234567896, TO_DATE('2024-06-12', 'YYYY-MM-DD'), TO_DATE('2024-06-17', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (518, 4003, 2234567897, TO_DATE('2024-06-10', 'YYYY-MM-DD'), TO_DATE('2024-06-13', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (519, 4004, 2234567898, TO_DATE('2024-06-11', 'YYYY-MM-DD'), TO_DATE('2024-06-16', 'YYYY-MM-DD'));
INSERT INTO reservas VALUES (520, 4005, 2234567899, TO_DATE('2024-06-12', 'YYYY-MM-DD'), TO_DATE('2024-06-20', 'YYYY-MM-DD'));

INSERT INTO pagos VALUES (1, 501, 100000, TO_DATE('2024-05-05', 'YYYY-MM-DD'), 'Tarjeta de Crédito');
INSERT INTO pagos VALUES (2, 502, 350000, TO_DATE('2024-05-10', 'YYYY-MM-DD'), 'Transferencia Bancaria');
INSERT INTO pagos VALUES (3, 503, 2310000, TO_DATE('2024-05-04', 'YYYY-MM-DD'), 'Efectivo');
INSERT INTO pagos VALUES (4, 504, 350000, TO_DATE('2024-05-10', 'YYYY-MM-DD'), 'Transferencia Bancaria');
INSERT INTO pagos VALUES (5, 505, 460000, TO_DATE('2024-05-09', 'YYYY-MM-DD'), 'Tarjeta de Crédito');
INSERT INTO pagos VALUES (6, 506, 3000000, TO_DATE('2024-05-08', 'YYYY-MM-DD'), 'Transferencia Bancaria');
INSERT INTO pagos VALUES (7, 507, 460000, TO_DATE('2024-06-07', 'YYYY-MM-DD'), 'Tarjeta de Crédito');
INSERT INTO pagos VALUES (8, 508, 500000, TO_DATE('2024-05-10', 'YYYY-MM-DD'), 'Transferencia Bancaria');
INSERT INTO pagos VALUES (9, 509, 3000000, TO_DATE('2024-03-01', 'YYYY-MM-DD'), 'Tarjeta Debito');
INSERT INTO pagos VALUES (10, 510, 310000, TO_DATE('2024-04-10', 'YYYY-MM-DD'), 'Transferencia Bancaria');
INSERT INTO pagos VALUES (11, 511, 160000, TO_DATE('2024-06-21', 'YYYY-MM-DD'), 'Efectivo');
INSERT INTO pagos VALUES (12, 512, 230000, TO_DATE('2024-03-10', 'YYYY-MM-DD'), 'Transferencia Bancaria');
INSERT INTO pagos VALUES (13, 513, 155000, TO_DATE('2024-06-01', 'YYYY-MM-DD'), 'Tarjeta de Crédito');
INSERT INTO pagos VALUES (14, 514, 460000, TO_DATE('2024-04-30', 'YYYY-MM-DD'), 'Efectivo');
INSERT INTO pagos VALUES (15, 515, 105000, TO_DATE('2024-05-30', 'YYYY-MM-DD'), 'Tarjeta de Crédito');
INSERT INTO pagos VALUES (16, 516, 115000, TO_DATE('2024-04-21', 'YYYY-MM-DD'), 'Tarjeta debito');
INSERT INTO pagos VALUES (17, 517, 240000, TO_DATE('2024-05-15', 'YYYY-MM-DD'), 'Efectivo');

INSERT INTO promociones VALUES (1, 'Descuento del 10% por reserva anticipada', 10.00, TO_DATE('2024-05-01', 'YYYY-MM-DD'), TO_DATE('2024-05-31', 'YYYY-MM-DD'));
INSERT INTO promociones VALUES (2, 'Oferta especial de verano', 15.00, TO_DATE('2024-07-01', 'YYYY-MM-DD'), TO_DATE('2024-07-31', 'YYYY-MM-DD'));
INSERT INTO promociones VALUES (3, 'Paquete Familiar: 20% de descuento para familias de 4 o más personas', 20.00, TO_DATE('2024-06-15', 'YYYY-MM-DD'), TO_DATE('2024-08-31', 'YYYY-MM-DD'));
INSERT INTO promociones VALUES (4, 'Descuento del 25% para estancias durante la temporada baja', 25.00, TO_DATE('2024-10-01', 'YYYY-MM-DD'), TO_DATE('2025-03-31', 'YYYY-MM-DD'));
INSERT INTO promociones VALUES (5, 'Descuento del 20% para estancias durante la semana de aniversario del hotel', 20.00, TO_DATE('2024-09-15', 'YYYY-MM-DD'), TO_DATE('2024-09-21', 'YYYY-MM-DD'));
INSERT INTO promociones VALUES (7, 'Oferta del Día del Padre: 15% de descuento', 15.00, TO_DATE('2024-06-16', 'YYYY-MM-DD'), TO_DATE('2024-06-16', 'YYYY-MM-DD'));
INSERT INTO promociones VALUES (8, 'Descuento del 10% por estancia de más de 5 noches', 10.00, TO_DATE('2024-05-01', 'YYYY-MM-DD'), TO_DATE('2024-12-31', 'YYYY-MM-DD'));

COMMIT;

SPOOL OFF