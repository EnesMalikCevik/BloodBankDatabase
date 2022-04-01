USE BloodWorks

--Tablolari kod yazmadan olusturdum. 
INSERT INTO ADRESSE
VALUES('Istanbul', 'Bahcelievler', '34300')
DELETE FROM ADRESSE 
WHERE District='Tuzla' AND codePostal='34100'
INSERT INTO ADRESSE
VALUES('Istanbul', 'Besiktas', '34200')
INSERT INTO ADRESSE
VALUES('Ankara', 'Bahcelievler', '06200')
SELECT *
FROM ADRESSE
INSERT INTO BANQUEDUSANG
VALUES( 'Edna''sHome', '7')
INSERT INTO RECEVEUR
VALUES('Sainz', 'Carlos', '1994-09-01', 185441, 'A RH-', 20)
INSERT INTO DONDESANG
VALUES(350, '2021-01-25', 3, 2)
--ve daha bircok insert islemi...


--5 Requêtes
--Tum blood banklerin genel bilgileri
SELECT B.Nom, A.Ville, A.District, A.codePostal
FROM BANQUEDUSANG B INNER JOIN ADRESSE A ON B.AdresseID=A.AdresseID
--1970 yilindan bu yana dogmus kan nakli alan tum kisilerin sayilarinin sehirlere gore dagilimi
SELECT COUNT(R.receveurID) AS ToplamKisiSayisi, Ville
FROM RECEVEUR R INNER JOIN ADRESSE A ON R.AdresseID=A.AdresseID
WHERE dateNaissance > '1970-01-01'
GROUP BY Ville
ORDER BY ToplamKisiSayisi
--Istanbul sehrinde yasayip kan bagislayan kisilerin ad ve soyadlari
SELECT D.Prénom, D.Nom
FROM DONNEUR D INNER JOIN ADRESSE A ON D.AdresseID=A.AdresseID
WHERE Ville = 'Istanbul'
--Blood banklere 2021-10-10 itibariyle yapilan toplam bagis miktarlarinin kan gruplarina gore gosterimi
SELECT B.Nom, SUM(DON.quantitéML) AS Amount, groupSanguin
FROM BANQUEDUSANG B INNER JOIN ADRESSE A ON B.AdresseID=A.AdresseID
INNER JOIN DONDESANG DON ON B.banqueID=DON.banqueID
INNER JOIN DONNEUR D ON D.donneurID=DON.donneurID
WHERE dateDON > '2021-10-10'
GROUP BY groupSanguin, B.Nom
--Yapilan kan bagislarinin genel bilgisi
SELECT D.Prénom, D.Nom, D.dateNaissance, D.Tel, A.Ville, A.District, D.groupSanguin, DON.dateDon, B.Nom AS NomBanque, DON.quantitéML
FROM DONNEUR D INNER JOIN DONDESANG DON ON D.donneurID = DON.donneurID
INNER JOIN ADRESSE A ON D.AdresseID=A.AdresseID
INNER JOIN BANQUEDUSANG B ON DON.banqueID=B.banqueID


--Stored Procedures
--donneur ekleme, receveur güncelleme, receveur silme
CREATE PROCEDURE addDonor (
@LastName nvarchar(50),
@FirstName nvarchar(50),
@BirthDate date,
@TelNo int,
@BloodGroup nvarchar(50),
@AddressNo int
)
AS
BEGIN TRANSACTION 
	DECLARE @S INT;
		BEGIN
		INSERT INTO [dbo].[DONNEUR](donneurID, Nom, Prénom, dateNaissance, Tel, groupSanguin, 
		AdresseID)
		VALUES(@LastName,@FirstName,@BirthDate,@TelNo,@BloodGroup, @AddressNo)
		SET @S = @@ROWCOUNT

		IF @S > 0
			BEGIN
				PRINT('New donor successfully added')
				COMMIT TRANSACTION
			END
		ELSE
			BEGIN
				PRINT('New donor couldn''t be added')
				ROLLBACK TRANSACTION
			END
		END


CREATE PROCEDURE updateReceiver(@receiverID int,
@LastName nvarchar(50),
@FirstName nvarchar(50),
@BirthDate date,
@TelNo int,
@BloodGroup nvarchar(50),
@AddressNo int)
AS
BEGIN TRANSACTION 
	DECLARE @S INT;
	BEGIN
		UPDATE [dbo].[RECEVEUR]
		SET Nom=@LastName, 
			Prénom=@FirstName,
			dateNaissance=@BirthDate,
			Tel=@TelNo,
			groupSanguin=@BloodGroup,
			AdresseID=@AddressNo
		WHERE receveurID=@receiverID
		SET @S = @@ROWCOUNT

		IF @S > 0
			BEGIN
				PRINT('Receiver infos has been updated')
				COMMIT TRANSACTION
			END
		ELSE
			BEGIN
				PRINT('Receiver infos couldn''t be updated')
				ROLLBACK TRANSACTION
			END
	END

CREATE PROCEDURE deleteReceiver(@receiverID int)
AS
BEGIN TRANSACTION 
	DECLARE @S INT;
	BEGIN
		DELETE FROM RECEVEUR
		WHERE receveurID=@receiverID
		DELETE FROM TRANSACTIONDESANG
		WHERE receveurID=@receiverID
		SET @S = @@ROWCOUNT

		IF @S > 0
			BEGIN
				PRINT('Receiver infos has been deleted')
				COMMIT TRANSACTION
			END
		ELSE
			BEGIN
				PRINT('Receiver infos couldn''t be deleted')
				ROLLBACK TRANSACTION
			END
	END


--2 farkli view; Ilki tum bankalara yapilan toplam bagis miktarlarını gosteriyor; digeri de toplam nakil miktarlarını
CREATE VIEW TotalDonByGroup AS
SELECT SUM(quantitéML) AS GivenAmount, D.groupSanguin
FROM BANQUEDUSANG B INNER JOIN ADRESSE A ON B.AdresseID=A.AdresseID
INNER JOIN DONDESANG DON ON B.banqueID=DON.banqueID
INNER JOIN DONNEUR D ON DON.donneurID=D.donneurID
GROUP BY D.groupSanguin

SELECT *
FROM TotalDonByGroup
ORDER BY GivenAmount DESC

CREATE VIEW TotalTranByGroup AS
SELECT SUM(quantitéML) AS TakenAmount, R.groupSanguin
FROM BANQUEDUSANG B INNER JOIN ADRESSE A ON B.AdresseID=A.AdresseID
INNER JOIN TRANSACTIONDESANG T ON B.banqueID=T.banqueID
INNER JOIN RECEVEUR R ON R.receveurID=T.receveurID
GROUP BY R.groupSanguin

SELECT *
FROM TotalTranByGroup
ORDER BY TakenAmount DESC


--2 indexes
CREATE INDEX idx_bloodGroup
ON DONNEUR(groupSanguin)
CREATE INDEX idx_city
ON ADRESSE(Ville)



--18 yasindan kucuk donneur eklenmesini onleyen trigger
CREATE TRIGGER TR ON DONNEUR
AFTER INSERT
AS
BEGIN
	IF EXISTS(
		SELECT *
		FROM DONNEUR
		WHERE DATEDIFF(year, DONNEUR.dateNaissance, GETDATE()) < 18
	)
	BEGIN
		RAISERROR('Anyone under 18 can''t donate blood without their parents', 16, 1)
		ROLLBACK TRANSACTION
	END
END

INSERT INTO DONNEUR
VALUES('Cevik Jr.', 'Enes Malik', '2020-07-09', 185741, 'A RH+', 10) --This baby isn't real