--1. Выбрать почтовые отделения в которых присутствуют факты неоплаты корреспонденции с объявленной ценностью.--
SELECT DISTINCT
    p.office_id,
    p.city,
    p.address,
    p.district,
    p.postal_code,
    p.phone
FROM Post_offices p
JOIN Mail_acceptance m ON p.office_id = m.office_id
WHERE m.is_paid = FALSE
  AND m.declared_value IS NOT NULL
  AND m.declared_value > 0;

--2. Выбрать трек-номера отправлений, итоговая стоимость которых более чем в два раза превышает объявленную ценность.--
SELECT
    m.tracking_number,
    m.total_cost,
    m.declared_value
FROM Mail_acceptance m
WHERE m.declared_value IS NOT NULL
  AND m.declared_value > 0
  AND m.total_cost > (2 * m.declared_value);

--3. Создать таблицу, содержащую данные 1 запроса с указанием трек-номеров и даты отправки корреспонденции.--
DROP TABLE IF EXISTS Unpaid_valuable_mail CASCADE;
SELECT DISTINCT
    p.office_id,
    p.city,
    p.address,
    p.district,
    p.postal_code,
    p.phone,
    m.tracking_number,
    m.acceptance_datetime,
    m.dispatch_datetime
INTO Unpaid_valuable_mail
FROM Post_offices p
JOIN Mail_acceptance m ON p.office_id = m.office_id
WHERE m.is_paid = FALSE
  AND m.declared_value IS NOT NULL
  AND m.declared_value > 0;
SELECT * FROM Unpaid_valuable_mail;

--4. Добавить в таблицу отделения, осуществлявшие прием корреспонденции в осенний период.--
INSERT INTO Unpaid_valuable_mail (
    office_id,
    city,
    address,
    district,
    postal_code,
    phone,
    tracking_number,
    acceptance_datetime,
    dispatch_datetime
)
SELECT DISTINCT
    p.office_id,
    p.city,
    p.address,
    p.district,
    p.postal_code,
    p.phone,
    m.tracking_number,
    m.acceptance_datetime,
    m.dispatch_datetime
FROM Post_offices p
JOIN Mail_acceptance m ON p.office_id = m.office_id
WHERE EXTRACT(MONTH FROM m.acceptance_datetime) IN (9, 10, 11)
  AND m.tracking_number NOT IN (SELECT tracking_number FROM Unpaid_valuable_mail WHERE tracking_number IS NOT NULL);
SELECT * FROM Unpaid_valuable_mail;

--5. В созданной таблице всем почтовым отделениям с индексом, начинающимся на 115, добавить в адрес «г. Москва».--
UPDATE Unpaid_valuable_mail
SET address = 'г. Москва, ' || address
WHERE postal_code LIKE '115%';
SELECT * FROM Unpaid_valuable_mail;

--6. Удалить из созданной таблицы все отделения, в которых трек-номера сообщений содержат какие-либо символы, кроме цифр.--
DELETE FROM Unpaid_valuable_mail
WHERE tracking_number ~ '[^0-9]';
SELECT * FROM Unpaid_valuable_mail;

--7. Посчитать количество принятых посылок в будни после 18:00 в каждом городе для каждого отделения.--
SELECT
    p.city,
    p.office_id,
    p.address,
    COUNT(m.tracking_number) AS accepted_parcels_count
FROM Post_offices p
JOIN Mail_acceptance m ON p.office_id = m.office_id
WHERE EXTRACT(ISODOW FROM m.acceptance_datetime) BETWEEN 1 AND 5
  AND m.acceptance_datetime::time >= '18:00:00'
GROUP BY p.city, p.office_id, p.address
ORDER BY p.city, p.office_id;
