/*----------------------------------------------------
Answer to Puzzle #2
Managers and Employees
*/----------------------------------------------------

DROP TABLE IF EXISTS Employees;


CREATE TEMPORARY TABLE Employees
(
EmployeeID  INTEGER PRIMARY KEY,
ManagerID   INTEGER NULL,
JobTitle    VARCHAR(100) NOT NULL
);


INSERT INTO Employees (EmployeeID, ManagerID, JobTitle) VALUES
(1001,NULL,'President'),(2002,1001,'Director'),
(3003,1001,'Office Manager'),(4004,2002,'Engineer'),
(5005,2002,'Engineer'),(6006,2002,'Engineer');


--Recursion
WITH RECURSIVE cte_Recursion AS 
(
SELECT  EmployeeID, ManagerID, JobTitle, 0 AS Depth
FROM    Employees
WHERE   ManagerID IS NULL
UNION ALL
SELECT  b.EmployeeID, b.ManagerID, b.JobTitle, a.Depth + 1
FROM    cte_Recursion a INNER JOIN 
        Employees b ON a.EmployeeID = b.ManagerID
)
SELECT  EmployeeID, ManagerID, JobTitle, Depth
FROM    cte_Recursion;

