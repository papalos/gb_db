USE volunteer;
SET SQL_SAFE_UPDATES = 0;

-- Хранимая функция (процедура) - генерирует случайное число для уникальной ссылки подтверждения регистрации
drop function if exists hhash; 
DELIMITER // 
CREATE FUNCTION hhash() RETURNS BIGINT
    DETERMINISTIC
BEGIN
    DECLARE result BIGINT;   
	SET result = RAND()*1000000000; 
RETURN (result); 
END// 
DELIMITER ;


-- Триггер - удаляет из таблицы предварительной регистрации пользователя при переносе его в таблицу подтвержденной регистрации
drop trigger if exists `del_from_temp`; 
DELIMITER //
CREATE TRIGGER `del_from_temp`
AFTER INSERT ON person FOR EACH ROW
BEGIN 
DELETE FROM temp_user WHERE temp_user.surname = NEW.surname_prsn AND temp_user.`name`= NEW.name_prsn AND temp_user.patronymic = NEW.patronymic_prsn;
END//
DELIMITER ;

-- Создание временной таблицы для переноса данных из таблицы предварительной регистрации в таблицу подтвержденной регистрации
-- так как нельзя удалить запись из таблицы присутствующей в запросе.
-- !может временная таблица пойдет в зачет второй требуемой вьюхи?
DROP TEMPORARY TABLE IF EXISTS `tmp_table`;
CREATE TEMPORARY TABLE `tmp_table` 
SELECT surname, `name`, patronymic, faculty, email, phone, birthday, login, `password`, date_reg, sex, year_st 
FROM temp_user
WHERE `hash` = 4564699;

-- Собственно активация триггера и выполнение переноса
INSERT INTO person 
(surname_prsn, name_prsn, patronymic_prsn, faculty, email, phone, birthday, login, `password`, date_reg, sex, year_st) 
SELECT * FROM tmp_table;


-- Вызов функции hhash()
INSERT INTO temp_user 
VALUES (hhash(),'Киса','Арина','Глебовна',89,'agva_1@edu.ru','89052','1999-04-25','agkiseleva','Gleb09032014','2019-12-23','ж',4);

-- ### скрипты характерных выборок (включающие группировки, JOIN'ы, вложенные таблицы) ###
-- количество регистраций на мероприятия и количество посещенных мероприятий
SELECT p.*, r.num, t.num
FROM person AS p 
LEFT JOIN (SELECT id_prsn, COUNT(visit) AS num FROM registration GROUP BY id_prsn) AS r ON p.id_prsn = r.id_prsn
LEFT JOIN (SELECT id_prsn, COUNT(visit) AS num FROM registration WHERE visit=1 GROUP BY id_prsn) AS t ON p.id_prsn = t.id_prsn;

-- Выборка волонтеров зарегистрированных на конкретное событие
SELECT p.id_prsn, surname_prsn, name_prsn, patronymic_prsn, faculty, email, phone, birthday, r.role, r.visit, r.classroom FROM registration AS r JOIN person AS p ON r.id_prsn=p.id_prsn WHERE r.id_evt = 10 ORDER BY surname_prsn;


-- Вьюха расширяющая информацию по таблице reserve
DROP VIEW IF EXISTS `view_reserve`;
CREATE VIEW `view_reserve` AS
SELECT `event`, activity, `date`, surname_prsn, name_prsn, patronymic_prsn, r.email FROM reserve r JOIN `event` USING (id_evt) JOIN person USING (id_prsn);