rem
rem Header: hotel_setup.sql
rem
rem Copyright (c) 2024
rem 
rem Permission is hereby granted, free of charge, to any person obtaining
rem a copy of this software and associated documentation files (the
rem "Software"), to deal in the Software without restriction, including
rem without limitation the rights to use, copy, modify, merge, publish,
rem distribute, sublicense, and/or sell copies of the Software, and to
rem permit persons to whom the Software is furnished to do so, subject to
rem the following conditions:
rem 
rem The above copyright notice and this permission notice shall be
rem included in all copies or substantial portions of the Software.
rem 
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
rem EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
rem MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
rem NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
rem LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
rem OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
rem WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
rem
rem Owner: Group3
rem
rem NAME
rem   hotel_setup.sql - Main script for Hotel schema
rem
rem DESCRIPTION
rem   This script sets up the Hotel schema with all required tables and constraints.
rem
rem NOTES
rem   Run as SYS or SYSTEM
rem

SET ECHO OFF
SET VERIFY OFF

PROMPT 
PROMPT specify password for HOTEL_USER as parameter 1:
DEFINE pass     = &1
PROMPT 
PROMPT specify default tablespace for HOTEL_USER as parameter 2:
DEFINE tbs      = &2
PROMPT 
PROMPT specify temporary tablespace for HOTEL_USER as parameter 3:
DEFINE ttbs     = &3
PROMPT 
PROMPT specify password for SYS as parameter 4:
DEFINE pass_sys = &4
PROMPT 
PROMPT specify log path as parameter 5:
DEFINE log_path = &5
PROMPT
PROMPT specify connect string as parameter 6:
DEFINE connect_string     = &6
PROMPT

-- The first dot in the spool command below is 
-- the SQL*Plus concatenation character

DEFINE spool_file = &log_path.hotel_setup.log
SPOOL &spool_file

REM =======================================================
REM cleanup section
REM =======================================================

DROP USER hotel_user CASCADE;

REM =======================================================
REM create user
REM =======================================================

CREATE USER hotel_user IDENTIFIED BY &pass;

ALTER USER hotel_user DEFAULT TABLESPACE &tbs
              QUOTA UNLIMITED ON &tbs;

ALTER USER hotel_user TEMPORARY TABLESPACE &ttbs;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, UNLIMITED TABLESPACE TO hotel_user;

REM =======================================================
REM grants from sys schema
REM =======================================================

CONNECT sys/&pass_sys@&connect_string AS SYSDBA;

REM =======================================================
REM create hotel schema objects
REM =======================================================

CONNECT hotel_user/&pass@&connect_string
ALTER SESSION SET NLS_LANGUAGE=American;
ALTER SESSION SET NLS_TERRITORY=America;

-- Crear tablas
CREATE TABLE HUESPED (
    ID_HUESPED NUMBER(10) PRIMARY KEY,
    NOMBRE VARCHAR2(255),
    EMAIL VARCHAR2(255) UNIQUE,
    TELEFONO VARCHAR2(20)
);

CREATE TABLE HABITACION (
    ID_HABITACION NUMBER(10) PRIMARY KEY,
    TIPO VARCHAR2(100),
    PRECIO NUMBER(10, 2),
    CAPACIDAD NUMBER(3)
);

CREATE TABLE RESERVA (
    ID_RESERVA NUMBER(10) PRIMARY KEY,
    ID_HABITACION NUMBER(10),
    ID_HUESPED NUMBER(10),
    FECHA_ENTRADA DATE,
    FECHA_SALIDA DATE,
    FOREIGN KEY (ID_HABITACION) REFERENCES HABITACION(ID_HABITACION),
    FOREIGN KEY (ID_HUESPED) REFERENCES HUESPED(ID_HUESPED)
);

CREATE TABLE SERVICIO (
    ID_SERVICIO NUMBER(10) PRIMARY KEY,
    NOMBRE_SERVICIO VARCHAR2(255),
    DESCRIPCION VARCHAR2(1000),
    PRECIO NUMBER(10, 2)
);

CREATE TABLE PAGO (
    ID_PAGO NUMBER(10) PRIMARY KEY,
    ID_RESERVA NUMBER(10) UNIQUE,
    MONTO NUMBER(10, 2),
    FECHA DATE,
    METODO_PAGO VARCHAR2(50),
    FOREIGN KEY (ID_RESERVA) REFERENCES RESERVA(ID_RESERVA)
);

CREATE TABLE PROMOCION (
    ID_PROMOCION NUMBER(10) PRIMARY KEY,
    DESCRIPCION VARCHAR2(1000),
    DESCUENTO NUMBER(5, 2),
    FECHA_INICIO DATE,
    FECHA_FIN DATE
);

CREATE TABLE OPINION (
    ID_OPINION NUMBER(10) PRIMARY KEY,
    ID_HUESPED NUMBER(10),
    COMENTARIO VARCHAR2(1000),
    PUNTUACION NUMBER(2),
    FECHA DATE,
    FOREIGN KEY (ID_HUESPED) REFERENCES HUESPED(ID_HUESPED)
);

-- Relaciones adicionales
CREATE TABLE RESERVA_PROMOCION (
    ID_RESERVA NUMBER(10),
    ID_PROMOCION NUMBER(10),
    PRIMARY KEY (ID_RESERVA, ID_PROMOCION),
    FOREIGN KEY (ID_RESERVA) REFERENCES RESERVA(ID_RESERVA),
    FOREIGN KEY (ID_PROMOCION) REFERENCES PROMOCION(ID_PROMOCION)
);

-- Insertar datos en HUESPED
INSERT INTO HUESPED (ID_HUESPED, NOMBRE, EMAIL, TELEFONO)
VALUES (1, 'Juan Perez', 'juan.perez@example.com', '1234567890');

INSERT INTO HUESPED (ID_HUESPED, NOMBRE, EMAIL, TELEFONO)
VALUES (2, 'Maria Lopez', 'maria.lopez@example.com', '0987654321');

-- Insertar datos en HABITACION
INSERT INTO HABITACION (ID_HABITACION, TIPO, PRECIO, CAPACIDAD)
VALUES (1, 'Individual', 50.00, 1);

INSERT INTO HABITACION (ID_HABITACION, TIPO, PRECIO, CAPACIDAD)
VALUES (2, 'Doble', 75.00, 2);

-- Insertar datos en RESERVA
INSERT INTO RESERVA (ID_RESERVA, ID_HUESPED, ID_HABITACION, FECHA_ENTRADA, FECHA_SALIDA)
VALUES (1, 1, 1, TO_DATE('2024-06-01', 'YYYY-MM-DD'), TO_DATE('2024-06-05', 'YYYY-MM-DD'));

INSERT INTO RESERVA (ID_RESERVA, ID_HUESPED, ID_HABITACION, FECHA_ENTRADA, FECHA_SALIDA)
VALUES (2, 2, 2, TO_DATE('2024-06-10', 'YYYY-MM-DD'), TO_DATE('2024-06-15', 'YYYY-MM-DD'));

-- Insertar datos en SERVICIO
INSERT INTO SERVICIO (ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION, PRECIO)
VALUES (1, 'Desayuno', 'Desayuno buffet completo', 10.00);

INSERT INTO SERVICIO (ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION, PRECIO)
VALUES (2, 'Spa', 'Acceso al spa y tratamientos', 50.00);

-- Insertar datos en PAGO
INSERT INTO PAGO (ID_PAGO, ID_RESERVA, MONTO, FECHA, METODO_PAGO)
VALUES (1, 1, 200.00, TO_DATE('2024-06-01', 'YYYY-MM-DD'), 'Tarjeta de Crédito');

INSERT INTO PAGO (ID_PAGO, ID_RESERVA, MONTO, FECHA, METODO_PAGO)
VALUES (2, 2, 375.00, TO_DATE('2024-06-10', 'YYYY-MM-DD'), 'Transferencia Bancaria');

-- Insertar datos en PROMOCION
INSERT INTO PROMOCION (ID_PROMOCION, DESCRIPCION, DESCUENTO, FECHA_INICIO, FECHA_FIN)
VALUES (1, 'Descuento del 10% por reserva anticipada', 10.00, TO_DATE('2024-05-01', 'YYYY-MM-DD'), TO_DATE('2024-05-31', 'YYYY-MM-DD'));

INSERT INTO PROMOCION (ID_PROMOCION, DESCRIPCION, DESCUENTO, FECHA_INICIO, FECHA_FIN)
VALUES (2, 'Oferta especial de verano', 15.00, TO_DATE('2024-07-01', 'YYYY-MM-DD'), TO_DATE('2024-07-31', 'YYYY-MM-DD'));

-- Insertar datos en OPINION
INSERT INTO OPINION (ID_OPINION, ID_HUESPED, COMENTARIO, PUNTUACION, FECHA)
VALUES (1, 1, 'Excelente servicio y atención.', 95, TO_DATE('2024-06-06', 'YYYY-MM-DD'));

INSERT INTO OPINION (ID_OPINION, ID_HUESPED, COMENTARIO, PUNTUACION, FECHA)
VALUES (2, 2, 'Muy buena experiencia.', 90, TO_DATE('2024-06-16', 'YYYY-MM-DD'));

SPOOL OFF
rem
rem Header: hotel_setup.sql
rem
rem Copyright (c) 2024
rem 
rem Permission is hereby granted, free of charge, to any person obtaining
rem a copy of this software and associated documentation files (the
rem "Software"), to deal in the Software without restriction, including
rem without limitation the rights to use, copy, modify, merge, publish,
rem distribute, sublicense, and/or sell copies of the Software, and to
rem permit persons to whom the Software is furnished to do so, subject to
rem the following conditions:
rem 
rem The above copyright notice and this permission notice shall be
rem included in all copies or substantial portions of the Software.
rem 
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
rem EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
rem MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
rem NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
rem LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
rem OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
rem WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
rem
rem Owner: Your Name
rem
rem NAME
rem   hotel_setup.sql - Main script for Hotel schema
rem
rem DESCRIPTION
rem   This script sets up the Hotel schema with all required tables and constraints.
rem
rem NOTES
rem   Run as SYS or SYSTEM
rem

SET ECHO OFF
SET VERIFY OFF

PROMPT 
PROMPT specify password for HOTEL_USER as parameter 1:
DEFINE pass     = &1
PROMPT 
PROMPT specify default tablespace for HOTEL_USER as parameter 2:
DEFINE tbs      = &2
PROMPT 
PROMPT specify temporary tablespace for HOTEL_USER as parameter 3:
DEFINE ttbs     = &3
PROMPT 
PROMPT specify password for SYS as parameter 4:
DEFINE pass_sys = &4
PROMPT 
PROMPT specify log path as parameter 5:
DEFINE log_path = &5
PROMPT
PROMPT specify connect string as parameter 6:
DEFINE connect_string     = &6
PROMPT

-- The first dot in the spool command below is 
-- the SQL*Plus concatenation character

DEFINE spool_file = &log_path.hotel_setup.log
SPOOL &spool_file

REM =======================================================
REM cleanup section
REM =======================================================

DROP USER hotel_user CASCADE;

REM =======================================================
REM create user
REM =======================================================

CREATE USER hotel_user IDENTIFIED BY &pass;

ALTER USER hotel_user DEFAULT TABLESPACE &tbs
              QUOTA UNLIMITED ON &tbs;

ALTER USER hotel_user TEMPORARY TABLESPACE &ttbs;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, UNLIMITED TABLESPACE TO hotel_user;

REM =======================================================
REM grants from sys schema
REM =======================================================

CONNECT sys/&pass_sys@&connect_string AS SYSDBA;

REM =======================================================
REM create hotel schema objects
REM =======================================================

CONNECT hotel_user/&pass@&connect_string
ALTER SESSION SET NLS_LANGUAGE=American;
ALTER SESSION SET NLS_TERRITORY=America;

-- Crear tablas
CREATE TABLE HUESPED (
    ID_HUESPED NUMBER(10) PRIMARY KEY,
    NOMBRE VARCHAR2(255),
    EMAIL VARCHAR2(255) UNIQUE,
    TELEFONO VARCHAR2(20)
);

CREATE TABLE HABITACION (
    ID_HABITACION NUMBER(10) PRIMARY KEY,
    TIPO VARCHAR2(100),
    PRECIO NUMBER(10, 2),
    CAPACIDAD NUMBER(3)
);

CREATE TABLE RESERVA (
    ID_RESERVA NUMBER(10) PRIMARY KEY,
    ID_HABITACION NUMBER(10),
    ID_HUESPED NUMBER(10),
    FECHA_ENTRADA DATE,
    FECHA_SALIDA DATE,
    FOREIGN KEY (ID_HABITACION) REFERENCES HABITACION(ID_HABITACION),
    FOREIGN KEY (ID_HUESPED) REFERENCES HUESPED(ID_HUESPED)
);

CREATE TABLE SERVICIO (
    ID_SERVICIO NUMBER(10) PRIMARY KEY,
    NOMBRE_SERVICIO VARCHAR2(255),
    DESCRIPCION VARCHAR2(1000),
    PRECIO NUMBER(10, 2)
);

CREATE TABLE PAGO (
    ID_PAGO NUMBER(10) PRIMARY KEY,
    ID_RESERVA NUMBER(10) UNIQUE,
    MONTO NUMBER(10, 2),
    FECHA DATE,
    METODO_PAGO VARCHAR2(50),
    FOREIGN KEY (ID_RESERVA) REFERENCES RESERVA(ID_RESERVA)
);

CREATE TABLE PROMOCION (
    ID_PROMOCION NUMBER(10) PRIMARY KEY,
    DESCRIPCION VARCHAR2(1000),
    DESCUENTO NUMBER(5, 2),
    FECHA_INICIO DATE,
    FECHA_FIN DATE
);

CREATE TABLE OPINION (
    ID_OPINION NUMBER(10) PRIMARY KEY,
    ID_HUESPED NUMBER(10),
    COMENTARIO VARCHAR2(1000),
    PUNTUACION NUMBER(2),
    FECHA DATE,
    FOREIGN KEY (ID_HUESPED) REFERENCES HUESPED(ID_HUESPED)
);

-- Relaciones adicionales
CREATE TABLE RESERVA_PROMOCION (
    ID_RESERVA NUMBER(10),
    ID_PROMOCION NUMBER(10),
    PRIMARY KEY (ID_RESERVA, ID_PROMOCION),
    FOREIGN KEY (ID_RESERVA) REFERENCES RESERVA(ID_RESERVA),
    FOREIGN KEY (ID_PROMOCION) REFERENCES PROMOCION(ID_PROMOCION)
);

-- Insertar datos en HUESPED
INSERT INTO HUESPED (ID_HUESPED, NOMBRE, EMAIL, TELEFONO)
VALUES (1, 'Juan Perez', 'juan.perez@example.com', '1234567890');

INSERT INTO HUESPED (ID_HUESPED, NOMBRE, EMAIL, TELEFONO)
VALUES (2, 'Maria Lopez', 'maria.lopez@example.com', '0987654321');

-- Insertar datos en HABITACION
INSERT INTO HABITACION (ID_HABITACION, TIPO, PRECIO, CAPACIDAD)
VALUES (1, 'Individual', 50.00, 1);

INSERT INTO HABITACION (ID_HABITACION, TIPO, PRECIO, CAPACIDAD)
VALUES (2, 'Doble', 75.00, 2);

-- Insertar datos en RESERVA
INSERT INTO RESERVA (ID_RESERVA, ID_HUESPED, ID_HABITACION, FECHA_ENTRADA, FECHA_SALIDA)
VALUES (1, 1, 1, TO_DATE('2024-06-01', 'YYYY-MM-DD'), TO_DATE('2024-06-05', 'YYYY-MM-DD'));

INSERT INTO RESERVA (ID_RESERVA, ID_HUESPED, ID_HABITACION, FECHA_ENTRADA, FECHA_SALIDA)
VALUES (2, 2, 2, TO_DATE('2024-06-10', 'YYYY-MM-DD'), TO_DATE('2024-06-15', 'YYYY-MM-DD'));

-- Insertar datos en SERVICIO
INSERT INTO SERVICIO (ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION, PRECIO)
VALUES (1, 'Desayuno', 'Desayuno buffet completo', 10.00);

INSERT INTO SERVICIO (ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION, PRECIO)
VALUES (2, 'Spa', 'Acceso al spa y tratamientos', 50.00);

-- Insertar datos en PAGO
INSERT INTO PAGO (ID_PAGO, ID_RESERVA, MONTO, FECHA, METODO_PAGO)
VALUES (1, 1, 200.00, TO_DATE('2024-06-01', 'YYYY-MM-DD'), 'Tarjeta de Crédito');

INSERT INTO PAGO (ID_PAGO, ID_RESERVA, MONTO, FECHA, METODO_PAGO)
VALUES (2, 2, 375.00, TO_DATE('2024-06-10', 'YYYY-MM-DD'), 'Transferencia Bancaria');

-- Insertar datos en PROMOCION
INSERT INTO PROMOCION (ID_PROMOCION, DESCRIPCION, DESCUENTO, FECHA_INICIO, FECHA_FIN)
VALUES (1, 'Descuento del 10% por reserva anticipada', 10.00, TO_DATE('2024-05-01', 'YYYY-MM-DD'), TO_DATE('2024-05-31', 'YYYY-MM-DD'));

INSERT INTO PROMOCION (ID_PROMOCION, DESCRIPCION, DESCUENTO, FECHA_INICIO, FECHA_FIN)
VALUES (2, 'Oferta especial de verano', 15.00, TO_DATE('2024-07-01', 'YYYY-MM-DD'), TO_DATE('2024-07-31', 'YYYY-MM-DD'));

-- Insertar datos en OPINION
INSERT INTO OPINION (ID_OPINION, ID_HUESPED, COMENTARIO, PUNTUACION, FECHA)
VALUES (1, 1, 'Excelente servicio y atención.', 95, TO_DATE('2024-06-06', 'YYYY-MM-DD'));

INSERT INTO OPINION (ID_OPINION, ID_HUESPED, COMENTARIO, PUNTUACION, FECHA)
VALUES (2, 2, 'Muy buena experiencia.', 90, TO_DATE('2024-06-16', 'YYYY-MM-DD'));

SPOOL OFF
