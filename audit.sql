-- audit.sql
-- Auditoría para el asistente conversacional.
-- Cumple con la integración de trigger de auditoría pedida en la Actividad 4.2.

USE ecommerce_ia;

DROP TRIGGER IF EXISTS trg_auditar_consulta;
DROP TABLE IF EXISTS assistant_audit_log;
DROP TABLE IF EXISTS assistant_query_events;

CREATE TABLE assistant_query_events (
    id_evento INT AUTO_INCREMENT PRIMARY KEY,
    pregunta_original TEXT NOT NULL,
    sql_generado TEXT NOT NULL,
    filas_devueltas INT NOT NULL,
    fecha_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assistant_audit_log (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_evento INT NOT NULL,
    timestamp_auditoria TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pregunta_original TEXT NOT NULL,
    sql_generado TEXT NOT NULL,
    filas_devueltas INT NOT NULL,
    FOREIGN KEY (id_evento) REFERENCES assistant_query_events(id_evento)
);

DELIMITER //

CREATE TRIGGER trg_auditar_consulta
AFTER INSERT ON assistant_query_events
FOR EACH ROW
BEGIN
    INSERT INTO assistant_audit_log (
        id_evento,
        pregunta_original,
        sql_generado,
        filas_devueltas
    )
    VALUES (
        NEW.id_evento,
        NEW.pregunta_original,
        NEW.sql_generado,
        NEW.filas_devueltas
    );
END //

DELIMITER ;
