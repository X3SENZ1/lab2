--1. Выбрать почтовые отделения в которых присутствуют факты неоплаты корреспонденции с объявленной ценностью.--
SELECT DISTINCT
    p.office_code,
    p.city,
    p.address,
    p.district,
    p.postal_index,
    p.phone
FROM post_offices p
JOIN mail_acceptance m ON p.office_code = m.office_code
WHERE m.is_paid = FALSE
  AND m.declared_value IS NOT NULL
  AND m.declared_value > 0;

--2. Выбрать трек-номера отправлений, итоговая стоимость которых более чем в два раза превышает объявленную ценность.--
SELECT
    m.track_number,
    m.total_cost,
    m.declared_value
FROM mail_acceptance m
WHERE m.declared_value IS NOT NULL
  AND m.declared_value > 0
  AND m.total_cost > (2 * m.declared_value);

--3. Создать таблицу, содержащую данные 1 запроса с указанием трек-номеров и даты отправки корреспонденции.--
DROP TABLE IF EXISTS unpaid_valuable_mail CASCADE;
SELECT DISTINCT
    p.office_code,
    p.city,
    p.address,
    p.district,
    p.postal_index,
    p.phone,
    m.track_number,
    m.accept_time,
    m.dispatch_time
INTO unpaid_valuable_mail
FROM post_offices p
JOIN mail_acceptance m ON p.office_code = m.office_code
WHERE m.is_paid = FALSE
  AND m.declared_value IS NOT NULL
  AND m.declared_value > 0;
SELECT * FROM unpaid_valuable_mail;

--4. Добавить в таблицу отделения, осуществлявшие прием корреспонденции в осенний период.--
INSERT INTO unpaid_valuable_mail (
    office_code,
    city,
    address,
    district,
    postal_index,
    phone,
    track_number,
    accept_time,
    dispatch_time
)
SELECT DISTINCT
    p.office_code,
    p.city,
    p.address,
    p.district,
    p.postal_index,
    p.phone,
    m.track_number,
    m.accept_time,
    m.dispatch_time
FROM post_offices p
JOIN mail_acceptance m ON p.office_code = m.office_code
WHERE EXTRACT(MONTH FROM m.accept_time) IN (9, 10, 11)
  AND m.track_number NOT IN (SELECT track_number FROM unpaid_valuable_mail WHERE track_number IS NOT NULL);
SELECT * FROM unpaid_valuable_mail;

--5. В созданной таблице всем почтовым отделениям с индексом, начинающимся на 115, добавить в адрес «г. Москва».--
UPDATE unpaid_valuable_mail
SET address = 'г. Москва, ' || address
WHERE postal_index LIKE '115%';
SELECT * FROM unpaid_valuable_mail;

--6. Удалить из созданной таблицы все отделения, в которых трек-номера сообщений содержат какие-либо символы, кроме цифр.--
DELETE FROM unpaid_valuable_mail
WHERE track_number ~ '[^0-9]';
SELECT * FROM unpaid_valuable_mail;

--7. Посчитать количество принятых посылок в будни после 18:00 в каждом городе для каждого отделения.--
SELECT
    p.city,
    p.office_code,
    p.address,
    COUNT(m.track_number) AS accepted_parcels_count
FROM post_offices p
JOIN mail_acceptance m ON p.office_code = m.office_code
WHERE EXTRACT(ISODOW FROM m.accept_time) BETWEEN 1 AND 5
  AND m.accept_time::time >= '18:00:00'
GROUP BY p.city, p.office_code, p.address
ORDER BY p.city, p.office_code;
