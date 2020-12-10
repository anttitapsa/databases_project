-- Creating the tables

PRAGMA foreign_keys = ON;
CREATE TABLE Projects(
  ID INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT CHECK (end_date >= start_date) NOT NULL
);

CREATE TABLE Subprojects(
  ID INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT CHECK (end_date >= start_date) NOT NULL,
  projectID INTEGER NOT NULL,
  FOREIGN KEY (projectID) REFERENCES Projects(ID)
);

CREATE TABLE Depends_on(
  dependantID TEXT NOT NULL,
  depends_onID TEXT NOT NULL,
  PRIMARY KEY(dependantID, depends_onID),
  FOREIGN KEY (dependantID) REFERENCES Subprojects(ID),
  FOREIGN KEY (depends_onID) REFERENCES Subprojects(ID)
);

CREATE TABLE Required_professions(
  subprojectID INTEGER NOT NULL, 
  profession TEXT NOT NULL,
  required_amount INTEGER CHECK(required_amount > 0) NOT NULL,
  PRIMARY KEY(subprojectID, profession),
  FOREIGN KEY(subprojectID) REFERENCES Subprojects(ID),
  FOREIGN KEY(profession) REFERENCES Professions(profession)
);

CREATE TABLE Employee_reservations(
  subprojectID INTEGER NOT NULL,
  profession TEXT NOT NULL,
  employeeSSnumber TEXT NOT NULL,
  PRIMARY KEY(subprojectID, profession, employeeSSnumber),
  FOREIGN KEY(SubprojectID) REFERENCES Subprojects(ID),
  FOREIGN KEY(employeeSSnumber, profession) REFERENCES Has_professions(employeeID, profession)
);

CREATE TABLE Employees(
  SSnumber TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE Absences(
  employeeID TEXT NOT NULL,
  substituteID TEXT,
  start_date TEXT NOT NULL,
  end_date TEXT CHECK (end_date >= start_date),
  PRIMARY KEY(employeeID, start_date),
  FOREIGN KEY(employeeID) REFERENCES Employees(SSnumber),
  FOREIGN KEY(substituteID) REFERENCES Employees(SSnumber)
);

CREATE TABLE Has_professions(
  employeeID TEXT NOT NULL,
  profession TEXT NOT NULL,
  PRIMARY KEY (employeeID, profession),
  FOREIGN KEY(employeeID) REFERENCES Employees(SSnumber),
  FOREIGN KEY(profession) REFERENCES Professions(profession)
);

CREATE TABLE Professions(
  profession TEXT PRIMARY KEY NOT NULL
);

CREATE TABLE Machines(
  model TEXT PRIMARY KEY NOT NULL,
  description TEXT,
  manufacturer TEXT,
  size INTEGER CHECK(size > 0),
  energy_consumption INTEGER CHECK(energy_consumption > 0)
);

CREATE TABLE Machine_items(
  ID INTEGER PRIMARY KEY NOT NULL,
  model TEXT NOT NULL,
  FOREIGN KEY(model) REFERENCES Machines(model)
);

CREATE TABLE Required_machines(
  ID INTEGER PRIMARY KEY NOT NULL,
  subprojectID INTEGER NOT NULL,
  model TEXT NOT NULL,
  required_amount INTEGER CHECK(required_amount >0) NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT CHECK(end_date >= start_date) NOT NULL,
  FOREIGN KEY(model) REFERENCES Machines(model),
  FOREIGN KEY(subprojectID) REFERENCES Subprojects(ID)
);

CREATE TABLE Machine_reservations(
  machine_itemID INTEGER NOT NULL,
  requirementID INTEGER NOT NULL,
  PRIMARY KEY(machine_itemID, requirementID),
  FOREIGN KEY(machine_itemID) REFERENCES Machine_items(ID),
  FOREIGN KEY(requirementID) REFERENCES Required_machines(ID)
);

CREATE TABLE Not_in_use(
  machine_itemID INTEGER NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT CHECK(end_date >= start_date),
  PRIMARY KEY(machine_itemID, start_date),
  FOREIGN KEY(machine_itemID) REFERENCES Machine_items(ID)
);

CREATE INDEX ProfessionReservationIndex ON Required_professions(subprojectID);
CREATE INDEX EmployeeReservationIndex ON Employee_reservations(subprojectID);

CREATE INDEX RequiredMachinesIndex ON Required_machines(subprojectID);
CREATE INDEX ReservedMachinesIndex ON Machine_reservations(requirementID);

CREATE INDEX ProjectIndex ON Subprojects(ProjectID);

CREATE VIEW currentlyOnLeave AS
  SELECT * FROM Absences WHERE (end_date >= date('now') OR end_date IS NULL) AND start_date <= date('now');

CREATE VIEW missingSubstitute AS
  SELECT * FROM Absences WHERE substituteID IS NULL;

-- Selvitetään kaikkien työntekijöiden poissaolojen pituuksien keskiarvot ja lisätään perään kaikkien poissaolojen pituuksien keskiarvo
CREATE VIEW AverageAbsences AS SELECT employeeID, MAX(A) AS 'Average lenght of absence'
FROM (SELECT employeeID, AVG(julianday(end_date) - julianday(start_date)) AS A FROM Absences GROUP BY employeeID
UNION SELECT SSnumber, 0 FROM Employees
UNION SELECT 'All', AVG(julianday(end_date) - julianday(start_date)) FROM Absences)
GROUP BY employeeID;

INSERT INTO Projects
VALUES (1, 'Inkuterde', 'Päälafka', '2020-06-01', '2020-08-03');

INSERT INTO Projects
VALUES (2, 'Kiltis_laajennus', 'Päälafka', '2021-01-05', '2021-05-01');

INSERT INTO Subprojects
VALUES (11, 'Oven rakennus', '2020-06-01', '2020-06-22', 1);

INSERT INTO Subprojects
VALUES (12, 'Terassin rakennus', '2020-06-15', '2020-08-02', 1);

INSERT INTO Subprojects
VALUES (21, 'seinän hajotus', '2021-01-05', '2021-03-22', 2);

INSERT INTO Subprojects
VALUES (22, 'sähkö ja putkityöt', '2021-03-23', '2021-05-01', 2);

INSERT INTO Depends_on
VALUES (22, 21);

INSERT INTO Depends_on
VALUES (12, 11);

INSERT INTO Employees
VALUES ('12031996-66P', 'Jones');

INSERT INTO Employees
VALUES ('30121995-69X', 'Nalle');

INSERT INTO Employees
VALUES ('25061999-99O', 'Tauski');

INSERT INTO Employees
VALUES ('09112015A70O', 'Maikki');

INSERT INTO Employees
VALUES ('12345678A123', 'Puuha Pete');

INSERT INTO Professions
VALUES ('putkimies');

INSERT INTO Professions
VALUES ('koodari');

INSERT INTO Professions
VALUES ('sähkömies');

INSERT INTO Professions
VALUES ('kirvesmies');

INSERT INTO Professions
VALUES ('maisema-arkkitehti');

INSERT INTO Has_professions
VALUES ('12031996-66P', 'putkimies');

INSERT INTO Has_professions
VALUES ('12031996-66P', 'koodari');

INSERT INTO Has_professions
VALUES ('30121995-69X', 'koodari');

INSERT INTO Has_professions
VALUES ('30121995-69X', 'sähkömies');

INSERT INTO Has_professions
VALUES ('25061999-99O', 'maisema-arkkitehti');

INSERT INTO Has_professions
VALUES ('09112015A70O', 'kirvesmies');

INSERT INTO Has_professions
VALUES ('12345678A123', 'putkimies');

INSERT INTO Has_professions
VALUES ('12345678A123', 'koodari');

INSERT INTO Required_professions
VALUES (11, 'kirvesmies', 1);

INSERT INTO Required_professions
VALUES (11, 'sähkömies', 1);

INSERT INTO Required_professions
VALUES (11, 'putkimies', 1);

INSERT INTO Required_professions
VALUES (12, 'maisema-arkkitehti', 1);

INSERT INTO Required_professions
VALUES (12, 'kirvesmies', 1);

INSERT INTO Required_professions
VALUES (21, 'koodari', 2);

INSERT INTO Required_professions
VALUES (21, 'sähkömies', 1);

INSERT INTO Required_professions
VALUES (21, 'putkimies', 1);

INSERT INTO Required_professions
VALUES (21, 'kirvesmies', 1);

INSERT INTO Required_professions
VALUES (22, 'sähkömies', 1);

INSERT INTO Required_professions
VALUES (22, 'putkimies', 1);

INSERT INTO Required_professions
VALUES (22, 'kirvesmies', 1);

INSERT INTO Employee_reservations
VALUES (21, 'koodari', '12031996-66P');

INSERT INTO Employee_reservations
VALUES (12, 'sähkömies', '30121995-69X');

INSERT INTO Employee_reservations
VALUES (11, 'sähkömies', '30121995-69X');

INSERT INTO Employee_reservations
VALUES (11, 'putkimies','12345678A123');

INSERT INTO Employee_reservations
VALUES (21, 'putkimies','12345678A123');

INSERT INTO Absences
VALUES ('12031996-66P', '30121995-69X', '2020-02-25', NULL);

INSERT INTO Absences
VALUES ('09112015A70O', NULL, '2020-03-12','2020-11-13');

INSERT INTO Machines
VALUES ('Super500', 'vasara', 'ENG', 2, 1);

INSERT INTO Machines
VALUES ('Mega99', 'pora', 'ENG', 3, 5);

INSERT INTO Machines
VALUES ('DELL-99', 'läppäri', 'SCI', 5, 9);

INSERT INTO Machines
VALUES ('Fiskars33', 'lapio', 'ENG', 6, 1);

INSERT INTO Machines
VALUES ('galaxy5', 'saha', 'ELEC', 3, 5);

INSERT INTO Machine_items
VALUES (1, 'Super500');

INSERT INTO Machine_items
VALUES (2, 'Super500');

INSERT INTO Machine_items
VALUES (3, 'Super500');

INSERT INTO Machine_items
VALUES (4, 'Mega99');

INSERT INTO Machine_items
VALUES (5, 'Mega99');

INSERT INTO Machine_items
VALUES (6, 'DELL-99');

INSERT INTO Machine_items
VALUES (7, 'Fiskars33');

INSERT INTO Machine_items
VALUES (8, 'Fiskars33');

INSERT INTO Machine_items
VALUES (9, 'Fiskars33');

INSERT INTO Machine_items
VALUES (10, 'galaxy5');

INSERT INTO Required_machines
VALUES(1, 11, 'galaxy5', 1, '2020-06-01', '2020-06-22');

INSERT INTO Required_machines
VALUES(2, 11, 'Super500', 1, '2020-06-01', '2020-06-22');

INSERT INTO Required_machines
VALUES(3, 21, 'DELL-99', 2, '2021-01-05', '2021-03-22');

INSERT INTO Machine_reservations
VALUES(10, 1);
INSERT INTO Machine_reservations
VALUES(6, 3);

INSERT INTO Machine_reservations
VALUES(2, 2);

INSERT INTO Not_in_use
VALUES(2, '2020-6-1', '2020-6-22');
