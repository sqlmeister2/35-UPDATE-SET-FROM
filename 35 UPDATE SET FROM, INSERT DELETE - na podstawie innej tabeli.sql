--Aktualizowanie, dodawanie i usuwanie wierszy na podstawie drugiej tabeli

----------------------------------
--Kod na potrzeby æwiczeñ
USE Sklep;
DROP TABLE IF EXISTS produkt;
DROP TABLE current_products;

--Stworzenie tabeli produktow
CREATE TABLE produkt_bazowy (
	product_id INT,
	product_name VARCHAR(30),
	price FLOAT
)
INSERT INTO produkt_bazowy
VALUES (1, 'Herbata', 11.50),
	(2, 'Kawa', 28.00),
	(3, 'Czekolada', 5.50),
	(4, 'Ciastka', NULL),
	(5, 'Jogurt', NULL),
	(6, 'Maslo', NULL)



--Stworzenie tabeli z aktualnymi cenami produktow
CREATE TABLE produkt_aktualny (
	product_id INT,
	product_name VARCHAR(30),
	price FLOAT
);
INSERT INTO produkt_aktualny
VALUES (1, 'Herbata', 9.50),
	(2, 'Kawa czarna', 35.00),
	(3, 'Czekolada', NULL),
	(7, 'Czekolada Milka', 3.50),
	(8, 'Mleko', NULL);
----------------------------------------


-- UPDATE SET FROM, INSERT, DELETE

--1 UPDATE SET FROM - zwyk³e sparowanie po kluczu

--1a (WYDAJNE) wersja bez JOIN. W klauzuli UPDATE nie mo¿na tworzyæ aliasow
UPDATE produkt_bazowy
SET produkt_bazowy.price = pa.price
FROM produkt_aktualny pa 
WHERE produkt_bazowy.product_id = pa.product_id

SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

EXEC Wstaw_produkty_bazowe;
EXEC Wstaw_tabele_produktow_aktualnych;

--1b (WYDAJNE) UPDATE SET FROM JOIN (w klauzuli UPDATE alias z FROM)
--Wydajniejszeod 1a? Chyba tak https://www.sqlshack.com/how-to-update-from-a-select-statement-in-sql-server/
UPDATE pb
SET pb.price = pa.price
FROM produkt_bazowy pb -- w klauzuli FROM dodajemy tabele która updateujemy i dalej standardowo z³aczenie JOIN
INNER JOIN produkt_aktualny pa ON pa.product_id = pb.product_id


--1c (NIEWYDAJNE) UPDATE SET FROM JOIN (brak aliasu w UPDATE czyli jakby 2 razy czytamy obiekt produkt_bazowy - w FROM i UPDATE)
SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

UPDATE produkt_bazowy
SET produkt_bazowy.price = pa.price
FROM produkt_bazowy pb -- w klauzuli FROM dodajemy tabele która updateujemy i dalej standardowo z³aczenie JOIN
INNER JOIN produkt_aktualny pa ON pa.product_id = pb.product_id




--1d (NIEWYDAJNE) UPDATE SET FROM JOIN  -Zmiana kolejnoœci tabel we FROM i INNER JOIN
UPDATE produkt_bazowy
SET produkt_bazowy.price = pa.price
FROM produkt_aktualny pa 
INNER JOIN  produkt_bazowy pb ON pa.product_id = pb.product_id

SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

EXEC Wstaw_produkty_bazowe;
EXEC Wstaw_tabele_produktow_aktualnych;

--1E Sparowanie podzapytaniem (RACZEJ NIEWYDAJNE - -podzapytanie skorelowane)
--UPDATE SET PODZAPYTANIE WHERE - Pozwala zaktualizowac pierwsza tabele wartoscia z drugiej jako podzapytanie (NIE DZIA£A POPRAWNIE,
--poniewa¿ gdy nie znajdzie klucza to podstawia wartoœæ NULL i j¹ przypisuje!!!!!!!!!!!!)
EXEC Wstaw_produkty_bazowe;
EXEC Wstaw_tabele_produktow_aktualnych;
SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny; 

UPDATE produkt_bazowy
SET price = (
	SELECT price
	FROM produkt_aktualny 
	WHERE produkt_bazowy.product_id = produkt_aktualny.product_id
	)

--Nadmiarowy FROM
UPDATE produkt_bazowy
SET price = (
	SELECT price
	FROM produkt_aktualny pa
	WHERE pa.product_id = pb.product_id
)
FROM produkt_bazowy pb


SELECT *
FROM produkt_bazowy;

--1F ( NIEWYDAJNE) Sparowanie UPDATE SET FROM PODZAPYTANIE WHERE. Podzapytanie tab nie ma sensu
UPDATE produkt_bazowy
SET price = tab.price
FROM (
	SELECT pa.product_id,
		pa.price
	FROM produkt_bazowy pb
	INNER JOIN produkt_aktualny pa ON pb.product_id = pa.product_id
) tab
WHERE produkt_bazowy.product_id = tab.product_id


SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

--2 Sparowanie po kluczu oraz dodatkowa logika biznesowa
USE Sklep;

EXEC Wstaw_produkty_bazowe;
EXEC Wstaw_tabele_produktow_aktualnych;

SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

--2A (WYDAJNE) Wy³acznie klauzula WHERE
UPDATE produkt_bazowy
SET produkt_bazowy.price = pa.price
FROM produkt_aktualny pa
WHERE pa.product_id = produkt_bazowy.product_id
	AND pa.price IS NOT NULL --dodatkowa logika biznesowa w postaci WHERE

SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

--2B (WYDAJNE) Wydajniejsze od 2A? Dodatkowo klauzula JOIN - u¿ycie aliasu w UPDATE 
SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

UPDATE pb
SET pb.price = pa.price
FROM produkt_bazowy pb
INNER JOIN produkt_aktualny pa ON pb.product_id = pa.product_id
WHERE pa.price IS NOT NULL --dodatkowa logika biznesowa w postaci WHERE

SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

--2C (NIEWYDAJNE) Dodatkowo klauzula JOIN - 2 razy (nadmiarowo) odwo³anie do tej samej tabeli
SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

UPDATE produkt_bazowy
SET produkt_bazowy.price = pa.price
FROM produkt_bazowy pb
INNER JOIN produkt_aktualny pa ON pb.product_id = pa.product_id
WHERE pa.price IS NOT NULL --dodatkowa logika biznesowa w postaci WHERE

SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;

--3A UPDATE CASE - Aktualizowanie wartoœci w zale¿noœci od wartoœci innego atrybutu w innej kolumnie
EXEC Wstaw_produkty_bazowe
SELECT *
FROM produkt_bazowy
SELECT *
FROM produkt_aktualny

UPDATE produkt_bazowy
SET price = 
	CASE
		WHEN product_name = 'Herbata' THEN 29.99
		WHEN product_name = 'Jogurt' THEN 39.99
		ELSE price
	END

--3B Aktualizowanie wartoœci w zale¿noœci od wartoœci innego atrybutu w innej tabeli
EXEC Wstaw_produkty_bazowe
SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny

UPDATE pb
SET price = 
	CASE
		WHEN pa.product_name = pb.product_name THEN pb.price * 4
		WHEN pb.product_name = 'Kawa' THEN pb.price / 2
		ELSE pa.price * 0.5
	END
FROM produkt_bazowy pb
INNER JOIN produkt_aktualny pa ON pb.product_id = pa.product_id

SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny

-- 4 UPDATE n tabel -- to nie zadzia³a w MS SQL, zadzia³a chyba w mySQL
UPDATE produkt, current_products
SET produkt.price = current_products.price
WHERE produkt.product_id = current_products.id

--5 Z IIFem równie¿ nie dzia³a i dodaje NULLE
EXEC Wstaw_produkty_bazowe;
EXEC Wstaw_tabele_produktow_aktualnych;

UPDATE produkt_bazowy
SET price = IIF (
	(
		SELECT price
		FROM produkt_aktualny
		WHERE produkt_bazowy.product_id = produkt_aktualny.product_id
	) = NULL,
	produkt_bazowy.price,
	(
		SELECT price
		FROM produkt_aktualny
		WHERE produkt_bazowy.product_id = produkt_aktualny.product_id
	)
)


-- 6 INSERT - Dodanie tylko tych rekordow do pierwszej tabeli z drugiej, które nie wystepuja w pierwszej
SELECT *
FROM produkt;
SELECT *
FROM current_products;

INSERT INTO produkt
--Wyznaczenie current_products, które nie wystepuj¹ w produktach (po ID)
SELECT *
FROM current_products
WHERE current_products.id NOT IN (
	SELECT product_id
	FROM produkt
)

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--7A INSERT -- Lepsze dodanie tylko tych rekordow do pierwszej tabeli z drugiej, które nie wystepuja w pierwszej
--- na potrzeby zadania
EXEC Wstaw_produkty_bazowe
EXEC Wstaw_tabele_produktow_aktualnych
SELECT *
FROM produkt_bazowy;
SELECT *
FROM produkt_aktualny;
---

--W takiej formie wypisuje te które nie zmatchowa³y siê (ró¿nicê miêdzy zbiorami)
INSERT INTO produkt_bazowy
SELECT pa.*
FROM produkt_aktualny pa
LEFT JOIN produkt_bazowy pb
ON pa.product_id = pb.product_id
WHERE pb.product_id IS NULL -- Wa¿ne jest IS 





SELECT *
FROM produkt;

--8 DELETE - Usuniecie rekordow z pierwszej tabeli, które nie wystepuja w drugiej
SELECT *
FROM produkt;
SELECT *
FROM current_products;

DELETE produkt
WHERE product_id NOT IN ( --wyszukiwanie id w produktach ktore nie istnieja w current_products i wtedy ich usuniecie
	SELECT id
	FROM current_products
	)

SELECT *
FROM produkt;