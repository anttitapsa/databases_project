-- Querys

--Tapaus 1.
-- Vapaana olevan koneen tarkistus

SELECT ID, model
FROM Machine_items
 EXCEPT
SELECT Mi.ID, Mi.model
FROM Machine_items AS Mi, Machine_reservations AS Mres, Required_machines AS RM,
 Not_in_use AS N
WHERE Mi.ID = Mres.machine_itemID AND Mres.requirementID = RM.ID AND
 (RM.end_date >= '2020-01-08' AND RM.start_date <= '2020-06-01') OR 
 (N.end_date >= '2020-01-08' AND N.start_date <= '2020-06-01');
 
--Koneen varaus

INSERT INTO Required_machines
VALUES(4, 11, 'DELL-99', 1, '2020-01-06', '2020-13-06');

INSERT INTO Machine_reservations
VALUES(6, 4);



--2.
--Poistetaan kone käytöstä
INSERT INTO Not_in_use
VALUES(6, '2021-03-01', '2021-04-01');

--tarkistetaan oliko kone varattu jollekin osaprojektille 

SELECT S.ID
FROM Subprojects AS S, machine_reservations AS MR, Required_machines AS R
WHERE S.ID = subprojectID  AND MR.requirementID = R.ID AND MR.Machine_itemID = 6 AND (R.end_date >= '2021-03-01' AND  R.end_date <= '2021-04-01');

--kone oli varattu osaprojektiin 21
--tarkistetaan onko vapaana samaa kone tyyppiä olevaa konetta

SELECT ID, model
FROM Machine_items
 EXCEPT
SELECT Mi.ID, Mi.model
FROM Machine_items AS Mi, Machine_reservations AS Mres, Required_machines AS RM,
 Not_in_use AS N, Machines AS M
WHERE Mi.ID = Mres.machine_itemID AND Mres.requirementID = RM.ID AND Mi.model = M.model AND 
M.description = 'läppäri' AND
 (RM.end_date >= '2021-03-22' AND RM.start_date <= '2021-03-01') OR 
 (N.end_date >= '2021-03-22' AND N.start_date <= '2021-03-01');
 
/*koska toista samalla kuvauksella olevaa konetta ei löytynyt, viivästytetään osaprojektia ja projektia
ja pidennetään koneen varausta*/

---tarkistetaan ensin onko jokin muu osaprojekti riippuvainen osaprojektista, joka viivästyy

SELECT dependantID
FROM Subprojects, Depends_on
WHERE ID = depends_onID AND ID = 21;

--myöhennetään molempia osaprojekteja, projektia ja pidennetään varausta
UPDATE Subprojects
SET end_date = '2021-04-22'
WHERE ID = 21;

UPDATE Subprojects
SET end_date = '2021-06-01', start_date = '2021-04-23'
WHERE ID = 21;

--tarkistetaan mihin projektiin osaprojekti 21 kuuluu

SELECT P.ID
FROM Projects AS P, Subprojects AS S
WHERE ProjectID = P.ID AND S.ID = 21;

--päivitetään projekti 2
UPDATE Projects
SET end_date = '2021-06-01'
WHERE ID = 2;

--tarkistetaan oliko osaprojektilla 22 konevarauksia, joita pitäisi pidentää
SELECT COUNT(RequirementID)
FROM Required_machines, Machine_reservations
WHERE ID = requirementID AND subprojectID = 22;

--Koska varauksia ei ollut pidennetään 21 varausta koneesta 6
--Tätä ennen tarkistetaan, onko kone vapaa uudella aikavälillä

SELECT DISTINCT SubprojectID
FROM Machine_items AS Mi, Machine_reservations AS Mres, Required_machines AS RM,
Not_in_use AS N
WHERE Mi.ID = Mres.machine_itemID AND Mres.requirementID = RM.ID AND Mi.ID = 6 AND
(RM.end_date >= '2021-04-22' AND RM.start_date <= '2021-04-01');

 
--Koska kone on vapaa pidennetään varausta
UPDATE Required_machines
SET end_date = '2021-04-22'
WHERE subprojectID = 21 AND model = 'DELL-99';


--Tapaus 3.
--Hankitaan uusi työkone, jonka malli on Samsung-G55 ja kuvaus puhelin
--Tarkistetaan onko samanmallisia koneita valmiiksi tietokannassa

SELECT COUNT(model)
FROM Machines
WHERE model = 'Samsung-G55';

--Koska koneita ei ollut lisätään kone  tietokantaan

INSERT INTO Machines
VALUES('Samsung-G55', 'puhelin', 'SCI', 1, 100);

INSERT INTO Machine_items
VALUES(155,'Samsung-G55');


/* Tapaus 4. */
/* Lisää uusi tarvittava pätevyys osaprojektille jonka ID=22 */
INSERT INTO Required_professions VALUES(22, 'maisema-arkkitehti', 1);

/* Etsi vapaana olevat työntekijät, joilla on tarvittava pätevyys. */
SELECT employeeID FROM Has_professions 
  WHERE profession = 'maisema-arkkitehti' 
EXCEPT 
SELECT employeeSSnumber FROM (SELECT * FROM (
  SELECT DISTINCT employeeSSnumber, start_date, end_date FROM Employee_reservations AS E
  JOIN Subprojects AS S
  ON S.ID=E.subprojectID 
  UNION
  SELECT employeeID, start_date, end_date FROM Absences
  UNION
  SELECT substituteID, start_date, end_date FROM Absences
) CROSS JOIN (SELECT ID AS pID, start_date AS pStart, end_date AS pEnd FROM Subprojects WHERE pID=22))
WHERE (end_date>=pStart OR end_date IS NULL) AND start_date<=pEnd;

/* Varataan osaprojektiin yksi vapaista haluttuun rooliin. */
INSERT INTO employee_reservations VALUES(22, 'maisema-arkkitehti', '25061999-99O');


/* Tapaus 5. */
/* Haetaan Projektin tiedots */
SELECT * FROM Projects WHERE ID=1;

/* Haetaan Projektiin liittyvien osaprojektien tiedot */
SELECT * FROM Subprojects WHERE projectID=1;

/* Haetaan kaikki työntekijät jotka ovat olleet tekemässä projektia kaikista osaprojekteista. */
SELECT subprojectID, SSnumber, name, profession FROM Employee_reservations JOIN Employees AS E ON Employee_reservations.employeeSSnumber = E.SSnumber
WHERE subprojectID IN (SELECT ID FROM Subprojects WHERE projectID=1);

/* Haetaan kaikki koneet, jotka ovat olleet käytössä projektin kaikissa osaprojekteissa. */
SELECT subprojectID, model, machine_itemID FROM Required_machines JOIN Machine_reservations ON Machine_reservations.requirementID = Required_machines.ID
WHERE subprojectID IN (SELECT ID FROM Subprojects WHERE projectID=1);


/* Tapaus 6. */
/* Haetaan kaikki osaprojektit joilla on riippuvuuksia (ja riippuvuuksien määrä) ja joilla on aikaisempi alkupäivämäärä kuin riippuvuksien loppumiset */
SELECT dependantID, COUNT(*) FROM (SELECT * FROM Depends_on AS D
  JOIN (SELECT ID, end_date FROM Subprojects) AS S1
    ON S1.ID = D.depends_onID
  JOIN (SELECT ID, start_date FROM Subprojects) AS S2
    ON S2.ID = D.dependantID)
WHERE end_date > start_date GROUP BY dependantID;

/* Päivitetään saatujen tuloksien arvoja*/
UPDATE Subprojects SET 
end_date = (SELECT DATE((SELECT MAX(julianday(end_date)) FROM Depends_on, Subprojects WHERE dependantID = 12 AND depends_onID = ID) - julianday(start_date) + julianday(end_date))),
start_date = (SELECT MAX(end_date) FROM Depends_on, Subprojects WHERE dependantID = 12 AND depends_onID = ID)
WHERE ID = 12;

UPDATE Subprojects SET 
end_date = (SELECT DATE((SELECT MAX(julianday(end_date)) FROM Depends_on, Subprojects WHERE dependantID = 22 AND depends_onID = ID) - julianday(start_date) + julianday(end_date))),
start_date = (SELECT MAX(end_date) FROM Depends_on, Subprojects WHERE dependantID = 22 AND depends_onID = ID)
WHERE ID = 22;


/* Tapaus 7. */
/* Lisätään työntekijä poissaolevaksi, sijaista ei vielä tällä hetkellä ole */
INSERT INTO Absences
VALUES ('12345678A123', NULL, '2020-06-05', '2020-06-06');

/* Selvitetään mihin osaprojekteihin työntekijä kuuluu poissaolon aikana */
SELECT subprojectID FROM Employee_reservations AS E 
JOIN Subprojects AS S ON S.ID = E.subprojectID 
WHERE (end_date>='2020-06-05' AND start_date<='2020-06-06') AND employeeSSnumber = '12345678A123';

/* Etsitään vapaa työntekijä sopivalla pätevyydellä sijaiseksi. */
SELECT employeeID FROM Has_professions 
WHERE profession = (SELECT profession 
    FROM Employee_reservations WHERE employeeSSnumber = '12345678A123' AND subprojectID = 11)
EXCEPT 
SELECT employeeSSnumber FROM (SELECT employeeSSnumber, start_date, end_date FROM Employee_reservations AS E 
JOIN Subprojects AS S ON S.ID = E.subprojectID
  UNION
  SELECT employeeID, start_date, end_date FROM Absences
  UNION
  SELECT substituteID, start_date, end_date FROM Absences)
WHERE (end_date>='2020-06-05' AND start_date<='2020-06-06');

/* Valitaan tuloksista yksi henkilö ja päivitetään sijaisuus */
UPDATE Absences SET substituteID='12031996-66P' WHERE employeeID='12345678A123' AND start_date='2020-06-05';

/* Tapaus 8. */
/* Halutaan selvittää kuinka paljon osaprojekteja eri projekteilla on*/
SELECT Projects.ID, Projects.name, COUNT(subprojects.ID) AS 'osaprojektien määrä'
FROM Subprojects, Projects
WHERE projectID = Projects.ID
GROUP BY projectID;

/* Halutaan selvittää kuinka paljon eri pätevyyksiä yrityksellä on*/
SELECT profession, Count(employeeID) as 'määrä'
FROM Has_professions
GROUP BY profession
ORDER BY profession;

/* Millaisia koneita ja kuinka paljon yrityksellä on */
SELECT model, COUNT(*) AS 'määrä' FROM Machine_items GROUP BY model;