/*----------------------------------------------------
Scott Peters
Solutions for Advanced SQL Puzzles
https://advancedsqlpuzzles.com
Last Updated: 12/30/2023
PostgreSQL pl/pgsql

*/----------------------------------------------------

/*----------------------------------------------------
Answer to Puzzle #1
Shopping Carts
*/----------------------------------------------------

DROP TABLE IF EXISTS Cart1;
DROP TABLE IF EXISTS Cart2;


CREATE TEMPORARY TABLE Cart1
(
Item  VARCHAR(100) PRIMARY KEY
);


CREATE TEMPORARY TABLE Cart2
(
Item  VARCHAR(100) PRIMARY KEY
);


INSERT INTO Cart1 (Item) VALUES
('Sugar'),('Bread'),('Juice'),('Soda'),('Flour');


INSERT INTO Cart2 (Item) VALUES
('Sugar'),('Bread'),('Butter'),('Cheese'),('Fruit');


--Solution 1
--FULL OUTER JOIN
SELECT  a.Item AS ItemCart1,
        b.Item AS ItemCart2
FROM    Cart1 a FULL OUTER JOIN
        Cart2 b ON a.Item = b.Item;


--Solution 2
--LEFT JOIN, UNION and RIGHT JOIN
SELECT  a.Item AS Item1,
        b.Item AS Item2
FROM    Cart1 a 
        LEFT JOIN Cart2 b ON a.Item = b.Item
UNION
SELECT  a.Item AS Item1,
        b.Item AS Item2
FROM    Cart1 a 
        RIGHT JOIN Cart2 b ON a.Item = b.Item;

--Solution 3
--This solution does not use a FULL OUTER JOIN
SELECT  a.Item AS Item1,
        b.Item AS Item2
FROM    Cart1 a INNER JOIN
        Cart2 b ON a.Item = b.Item
UNION
SELECT  a.Item AS Item1,
        NULL AS Item2
FROM    Cart1 a
WHERE   a.Item NOT IN (SELECT b.Item FROM Cart2 b)
UNION
SELECT  NULL AS Item1, 
        b.Item AS Item2
FROM    Cart2 b
WHERE b.Item NOT IN (SELECT a.Item FROM Cart1 a)
ORDER BY 1,2;


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

/*----------------------------------------------------
Answer to Puzzle #3
Fiscal Year Table Constraints
*/----------------------------------------------------

DROP TABLE IF EXISTS EmployeePayRecords;


CREATE TEMPORARY TABLE EmployeePayRecords
(
EmployeeID  INTEGER,
FiscalYear  INTEGER,
StartDate   DATE,
EndDate     DATE,
PayRate     MONEY
);


--NOT NULL
ALTER TABLE EmployeePayRecords ALTER COLUMN EmployeeID SET NOT NULL;
ALTER TABLE EmployeePayRecords ALTER COLUMN FiscalYear SET NOT NULL;
ALTER TABLE EmployeePayRecords ALTER COLUMN StartDate SET NOT NULL;
ALTER TABLE EmployeePayRecords ALTER COLUMN EndDate SET NOT NULL;
ALTER TABLE EmployeePayRecords ALTER COLUMN PayRate SET NOT NULL;

--PRIMARY KEY
ALTER TABLE EmployeePayRecords ADD CONSTRAINT PK_FiscalYearCalendar
                                    PRIMARY KEY (EmployeeID,FiscalYear);
--CHECK CONSTRAINTS
ALTER TABLE EmployeePayRecords ADD CONSTRAINT Check_Year_StartDate
CHECK (FiscalYear = EXTRACT(YEAR FROM StartDate));
ALTER TABLE EmployeePayRecords ADD CONSTRAINT Check_Month_StartDate 
CHECK (EXTRACT(MONTH FROM StartDate) = 1);
ALTER TABLE EmployeePayRecords ADD CONSTRAINT Check_Day_StartDate 
CHECK (EXTRACT(DAY FROM StartDate) = 1);
ALTER TABLE EmployeePayRecords ADD CONSTRAINT Check_Year_EndDate
CHECK (FiscalYear = EXTRACT(YEAR FROM EndDate));
ALTER TABLE EmployeePayRecords ADD CONSTRAINT Check_Month_EndDate 
CHECK (EXTRACT(MONTH FROM EndDate) = 12);
ALTER TABLE EmployeePayRecords ADD CONSTRAINT Check_Day_EndDate 
CHECK (EXTRACT(DAY FROM EndDate) = 31);
ALTER TABLE EmployeePayRecords ADD CONSTRAINT Check_Payrate
CHECK (PayRate > CAST(0 AS MONEY));


/*----------------------------------------------------
Answer to Puzzle #4
Two Predicates
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;


CREATE TEMPORARY TABLE Orders
(
CustomerID     INTEGER,
OrderID        INTEGER,
DeliveryState  VARCHAR(100) NOT NULL,
Amount         MONEY NOT NULL,
PRIMARY KEY (CustomerID, OrderID)
);


INSERT INTO Orders (CustomerID, OrderID, DeliveryState, Amount) VALUES
(1001,1,'CA',340),(1001,2,'TX',950),(1001,3,'TX',670),
(1001,4,'TX',860),(2002,5,'WA',320),(3003,6,'CA',650),
(3003,7,'CA',830),(4004,8,'TX',120);


--Solution 1
--INNER JOIN
WITH cte_CA AS
(
SELECT  DISTINCT CustomerID
FROM    Orders
WHERE   DeliveryState = 'CA'
)
SELECT  b.CustomerID, b.OrderID, b.DeliveryState, b.Amount
FROM    cte_CA a INNER JOIN
        Orders b ON a.CustomerID = B.CustomerID
WHERE   b.DeliveryState = 'TX';


--Solution 2
--IN
WITH cte_CA AS
(
SELECT  CustomerID
FROM    Orders
WHERE   DeliveryState = 'CA'
)
SELECT  CustomerID,
        OrderID,
        DeliveryState,
        Amount
FROM    Orders
WHERE   DeliveryState = 'TX' AND
        CustomerID IN (SELECT b.CustomerID FROM cte_CA b);


/*----------------------------------------------------
Answer to Puzzle #5
Phone Directory
*/----------------------------------------------------

DROP TABLE IF EXISTS PhoneDirectory;


CREATE TEMPORARY TABLE PhoneDirectory
(
CustomerID   INTEGER,
"Type"       VARCHAR(100),
PhoneNumber  VARCHAR(12) NOT NULL,
PRIMARY KEY (CustomerID, "Type")
);


INSERT INTO PhoneDirectory (CustomerID, "Type", PhoneNumber) VALUES
(1001,'Cellular','555-897-5421'),
(1001,'Work','555-897-6542'),
(1001,'Home','555-698-9874'),
(2002,'Cellular','555-963-6544'),
(2002,'Work','555-812-9856'),
(3003,'Cellular','555-987-6541');


--Solution 1
--MAX and CASE
SELECT  CustomerID,
        MAX(CASE "Type" WHEN 'Cellular' THEN PhoneNumber END),
        MAX(CASE "Type" WHEN 'Work' THEN PhoneNumber END),
        MAX(CASE "Type" WHEN 'Home' THEN PhoneNumber END)
FROM    PhoneDirectory
GROUP BY CustomerID;

--Solution 2 (PIVOT is not a supported PostgreSQL operator)
--PIVOT 
--SELECT  CustomerID,Cellular,Work,Home
--FROM    PhoneDirectory PIVOT
--       (MAX(PhoneNumber) FOR Type IN (Cellular,Work,Home)) AS PivotClause;


--Solution 3
--OUTER JOIN
WITH cte_Cellular AS
(
SELECT  CustomerID, PhoneNumber AS Cellular
FROM    PhoneDirectory
WHERE   "Type" = 'Cellular'
),
cte_Work AS
(
SELECT  CustomerID, PhoneNumber AS Work
FROM    PhoneDirectory
WHERE   "Type" = 'Work'
),
cte_Home AS
(
SELECT  CustomerID, PhoneNumber AS Home
FROM    PhoneDirectory
WHERE   "Type" = 'Home'
)
SELECT  a.CustomerID,
        b.Cellular,
        c.Work,
        d.Home
FROM    (SELECT DISTINCT CustomerID FROM PhoneDirectory) a LEFT OUTER JOIN
        cte_Cellular b ON a.CustomerID = b.CustomerID LEFT OUTER JOIN
        cte_Work c ON a.CustomerID = c.CustomerID LEFT OUTER JOIN
        cte_Home d ON a.CustomerID = d.CustomerID;

--Solution 3
--MAX
WITH cte_PhoneNumbers AS
(
SELECT  CustomerID,
        PhoneNumber AS Cellular,
        NULL AS "Work",
        NULL AS Home
FROM    PhoneDirectory
WHERE   "Type" = 'Cellular'
UNION
SELECT  CustomerID,
        NULL AS Cellular,
        PhoneNumber AS "Work",
        NULL AS Home
FROM    PhoneDirectory
WHERE   "Type" = 'Work'
UNION
SELECT  CustomerID,
        NULL AS Cellular,
        NULL AS "Work",
        PhoneNumber AS Home
FROM    PhoneDirectory
WHERE   "Type" = 'Home'
)
SELECT  CustomerID,
        MAX(Cellular) AS Cellular,
        MAX("Work") AS "Work",
        MAX(Home) AS Home
FROM    cte_PhoneNumbers
GROUP BY CustomerID;

/*----------------------------------------------------
Answer to Puzzle #6
Workflow Steps
*/----------------------------------------------------

DROP TABLE IF EXISTS WorkflowSteps;


CREATE TEMPORARY TABLE WorkflowSteps
(
Workflow        VARCHAR(100),
StepNumber      INTEGER,
CompletionDate  DATE NULL,
PRIMARY KEY (Workflow, StepNumber)
);


INSERT INTO WorkflowSteps (Workflow, StepNumber, CompletionDate) VALUES
('Alpha',1,'7/2/2018'),('Alpha',2,'7/2/2018'),('Alpha',3,'7/1/2018'),
('Bravo',1,'6/25/2018'),('Bravo',2,NULL),('Bravo',3,'6/27/2018'),
('Charlie',1,NULL),('Charlie',2,'7/1/2018');


--Solution 1
--NULL operators
WITH cte_NotNull AS
(
SELECT  DISTINCT
        Workflow
FROM    WorkflowSteps
WHERE   CompletionDate IS NOT NULL
),
cte_Null AS
(
SELECT  Workflow
FROM    WorkflowSteps
WHERE   CompletionDate IS NULL
)
SELECT  Workflow
FROM    cte_NotNull
WHERE   Workflow IN (SELECT Workflow FROM cte_Null);


--Solution 2
--HAVING clause and COUNT functions
SELECT  Workflow
FROM    WorkflowSteps
GROUP BY Workflow
HAVING  COUNT(*) <> COUNT(CompletionDate);


--Solution 3
--HAVING clause with MAX function
SELECT  Workflow
FROM    WorkflowSteps
GROUP BY Workflow
HAVING  MAX(CASE WHEN CompletionDate IS NULL THEN 1 ELSE 0 END) = 1;


/*----------------------------------------------------
Answer to Puzzle #7
Mission to Mars
*/----------------------------------------------------

DROP TABLE IF EXISTS Candidates;
DROP TABLE IF EXISTS Requirements;


CREATE TEMPORARY TABLE Candidates
(
CandidateID  INTEGER,
Occupation   VARCHAR(100),
PRIMARY KEY (CandidateID, Occupation)
);


INSERT INTO Candidates (CandidateID, Occupation) VALUES
(1001,'Geologist'),(1001,'Astrogator'),(1001,'Biochemist'),
(1001,'Technician'),(2002,'Surgeon'),(2002,'Machinist'),
(3003,'Cryologist'),(4004,'Selenologist');


CREATE TEMPORARY TABLE Requirements
(
Requirement  VARCHAR(100) PRIMARY KEY
);


INSERT INTO Requirements (Requirement) VALUES
('Geologist'),('Astrogator'),('Technician');


SELECT  CandidateID
FROM    Candidates
WHERE   Occupation IN (SELECT Requirement FROM Requirements)
GROUP BY CandidateID
HAVING COUNT(*) = (SELECT COUNT(*) FROM Requirements);


/*----------------------------------------------------
Answer to Puzzle #8
Workflow Cases
*/----------------------------------------------------

DROP TABLE IF EXISTS WorkflowCases;


CREATE TEMPORARY TABLE WorkflowCases
(
Workflow  VARCHAR(100) PRIMARY KEY,
Case1     INTEGER NOT NULL DEFAULT 0,
Case2     INTEGER NOT NULL DEFAULT 0,
Case3     INTEGER NOT NULL DEFAULT 0
);


INSERT INTO WorkflowCases (Workflow, Case1, Case2, Case3) VALUES
('Alpha',0,0,0),('Bravo',0,1,1),('Charlie',1,0,0),('Delta',0,0,0);


--Solution 1
--Add each column
SELECT  Workflow,
        Case1 + Case2 + Case3 AS PassFail
FROM    WorkflowCases;


--Solution 2 (UNPIVOT is not a supported PostgreSQL operator)
--UNPIVOT operator
--WITH cte_PassFail AS
--(
--SELECT  Workflow, CaseNumber, PassFail
--FROM    (
--        SELECT Workflow,Case1,Case2,Case3
--        FROM WorkflowCases
--        ) p UNPIVOT (PassFail FOR CaseNumber IN (Case1,Case2,Case3)) AS UNPVT
--)
--SELECT  Workflow,
--        SUM(PassFail) AS PassFail
--FROM    cte_PassFail
--GROUP BY Workflow
--ORDER BY 1;


/*----------------------------------------------------
Answer to Puzzle #9
Matching Sets
*/----------------------------------------------------

DROP TABLE IF EXISTS Employees;


CREATE TEMPORARY TABLE Employees
(
EmployeeID  INTEGER,
License     VARCHAR(100),
PRIMARY KEY (EmployeeID, License)
);


INSERT INTO Employees (EmployeeID, License) VALUES
(1001,'Class A'),(1001,'Class B'),(1001,'Class C'),
(2002,'Class A'),(2002,'Class B'),(2002,'Class C'),
(3003,'Class A'),(3003,'Class D'),
(4004,'Class A'),(4004,'Class B'),(4004,'Class D'),
(5005,'Class A'),(5005,'Class B'),(5005,'Class D');


WITH cte_Count AS
(
SELECT  EmployeeID,
        COUNT(*) AS LicenseCount
FROM    Employees
GROUP BY EmployeeID
),
cte_CountWindow AS
(
SELECT  a.EmployeeID AS EmployeeID_A,
        b.EmployeeID AS EmployeeID_B,
        COUNT(*) OVER (PARTITION BY a.EmployeeID, b.EmployeeID) AS CountWindow
FROM    Employees a CROSS JOIN
        Employees b
WHERE   a.EmployeeID <> b.EmployeeID and a.License = b.License
)
SELECT  DISTINCT
        a.EmployeeID_A,
        a.EmployeeID_B,
        a.CountWindow AS LicenseCount
FROM    cte_CountWindow a INNER JOIN
        cte_Count b ON a.CountWindow = b.LicenseCount AND a.EmployeeID_A = b.EmployeeID INNER JOIN
        cte_Count c ON a.CountWindow = c.LicenseCount AND a.EmployeeID_B = c.EmployeeID;


/*----------------------------------------------------
Answer to Puzzle #10
Mean, Median, Mode, and Range
*/----------------------------------------------------

DROP TABLE IF EXISTS SampleData;


CREATE TEMPORARY TABLE SampleData
(
IntegerValue  INTEGER NOT NULL
);

INSERT INTO SampleData (IntegerValue) VALUES
(5),(6),(10),(10),(13),(14),(17),(20),(81),(90),(76);

--Median
WITH OrderedValues AS (
    SELECT IntegerValue,
           ROW_NUMBER() OVER (ORDER BY IntegerValue) AS RowNum,
           COUNT(*) OVER () AS TotalCount
    FROM SampleData
)
SELECT
    CASE
        WHEN TotalCount % 2 = 0 THEN -- Even number of rows
            (SELECT AVG(IntegerValue)
             FROM (
                 SELECT IntegerValue FROM OrderedValues WHERE RowNum IN (TotalCount / 2, TotalCount / 2 + 1)
             ) AS EvenRows)
        ELSE -- Odd number of rows
            (SELECT IntegerValue FROM OrderedValues WHERE RowNum = (TotalCount + 1) / 2)
    END AS Median
FROM OrderedValues
LIMIT 1;


--Mean and Range
SELECT  AVG(IntegerValue) AS Mean,
        MAX(IntegerValue) - MIN(IntegerValue) AS Range
FROM    SampleData;


--Mode
SELECT  IntegerValue AS Mode,
        COUNT(*) AS ModeCount
FROM    SampleData
GROUP BY IntegerValue
ORDER BY ModeCount DESC
LIMIT 1;


/*----------------------------------------------------
Answer to Puzzle #11
Permutations
*/----------------------------------------------------

DROP TABLE IF EXISTS TestCases;

CREATE TEMPORARY TABLE TestCases 
(
TestCase  VARCHAR(1) PRIMARY KEY
);

INSERT INTO TestCases (TestCase) VALUES
('A'), ('B'), ('C');

WITH RECURSIVE cte_Permutations (Permutation, Id, Depth) AS 
(
SELECT  CAST(TestCase AS VARCHAR) AS Permutation,
        CAST(TestCase AS VARCHAR) || ';' AS Id,
        1 AS Depth
FROM    TestCases
UNION ALL
SELECT  a.Permutation || ',' || b.TestCase,
        a.Id || b.TestCase || ';',
        a.Depth + 1
FROM    cte_Permutations a,
        TestCases b
WHERE   a.Depth < (SELECT COUNT(*) FROM TestCases) AND
        a.Id NOT LIKE '%' || b.TestCase || ';%'
)
SELECT  Permutation
FROM    cte_Permutations
WHERE   Depth = (SELECT COUNT(*) FROM TestCases);


/*----------------------------------------------------
Answer to Puzzle #12
Average Days
*/----------------------------------------------------

DROP TABLE IF EXISTS ProcessLog;


CREATE TEMPORARY TABLE ProcessLog
(
Workflow       VARCHAR(100),
ExecutionDate  DATE,
PRIMARY KEY (Workflow, ExecutionDate)
);


INSERT INTO ProcessLog (Workflow, ExecutionDate) VALUES
('Alpha','6/01/2018'),('Alpha','6/14/2018'),('Alpha','6/15/2018'),
('Bravo','6/1/2018'),('Bravo','6/2/2018'),('Bravo','6/19/2018'),
('Charlie','6/1/2018'),('Charlie','6/15/2018'),('Charlie','6/30/2018');


WITH cte_DayDiff AS
(
SELECT  Workflow,
        (EXTRACT(DAY FROM age(ExecutionDate, LAG(ExecutionDate, 1) OVER 
         (PARTITION BY Workflow ORDER BY ExecutionDate)))) AS DateDifference
FROM    ProcessLog
)
SELECT  Workflow,
        AVG(DateDifference)
FROM    cte_DayDiff
WHERE   DateDifference IS NOT NULL
GROUP BY Workflow;


/*----------------------------------------------------
Answer to Puzzle #13
Inventory Tracking
*/----------------------------------------------------

DROP TABLE IF EXISTS Inventory;


CREATE TEMPORARY TABLE Inventory
(
InventoryDate       DATE PRIMARY KEY,
QuantityAdjustment  INTEGER NOT NULL
);


INSERT INTO Inventory (InventoryDate, QuantityAdjustment) VALUES
('7/1/2018',100),('7/2/2018',75),('7/3/2018',-150),
('7/4/2018',50),('7/5/2018',-75);


SELECT  InventoryDate,
        QuantityAdjustment,
        SUM(QuantityAdjustment) OVER (ORDER BY InventoryDate)
FROM    Inventory;


/*----------------------------------------------------
Answer to Puzzle #14
Indeterminate Process Log
*/----------------------------------------------------

DROP TABLE IF EXISTS ProcessLog;


CREATE TEMPORARY TABLE ProcessLog
(
Workflow    VARCHAR(100),
StepNumber  INTEGER,
RunStatus   VARCHAR(100) NOT NULL,
PRIMARY KEY (Workflow, StepNumber)
);


INSERT INTO ProcessLog (Workflow, StepNumber, RunStatus) VALUES
('Alpha',1,'Error'),('Alpha',2,'Complete'),('Alpha',3,'Running'),
('Bravo',1,'Complete'),('Bravo',2,'Complete'),
('Charlie',1,'Running'),('Charlie',2,'Running'),
('Delta',1,'Error'),('Delta',2,'Error'),
('Echo',1,'Running'),('Echo',2,'Complete');


--Solution 1
--MIN and MAX
WITH cte_MinMax AS
(
SELECT  Workflow,
        MIN(RunStatus) AS MinStatus,
        MAX(RunStatus) AS MaxStatus
FROM    ProcessLog
GROUP BY Workflow
),
cte_Error AS
(
SELECT  Workflow,
        MAX(CASE RunStatus WHEN 'Error' THEN RunStatus END) AS ErrorState,
        MAX(CASE RunStatus WHEN 'Running' THEN RunStatus END) AS RunningState
FROM    ProcessLog
WHERE   RunStatus IN ('Error','Running')
GROUP BY Workflow
)
SELECT  a.Workflow,
        CASE WHEN a.MinStatus = a.MaxStatus THEN a.MinStatus
             WHEN b.ErrorState = 'Error' THEN 'Indeterminate'
             WHEN b.RunningState = 'Running' THEN b.RunningState END AS RunStatus
FROM    cte_MinMax a LEFT OUTER JOIN
        cte_Error b ON a.WorkFlow = b.WorkFlow
ORDER BY 1;


--Solution 2
--COUNT and STRING_AGG
WITH cte_Distinct AS
(
SELECT DISTINCT
       Workflow,
       RunStatus
FROM   ProcessLog
),
cte_StringAgg AS
(
SELECT  Workflow,
        STRING_AGG(RunStatus,', ') AS RunStatus_Agg,
        COUNT(DISTINCT RunStatus) AS DistinctCount
FROM    cte_Distinct
GROUP BY Workflow
)
SELECT  Workflow,
        CASE WHEN DistinctCount = 1 THEN RunStatus_Agg
             WHEN RunStatus_Agg LIKE '%Error%' THEN 'Indeterminate'
             WHEN RunStatus_Agg LIKE '%Running%' THEN 'Running' END AS RunStatus
FROM    cte_StringAgg
ORDER BY 1;


/*----------------------------------------------------
Answer to Puzzle #15
Group Concatenation
*/----------------------------------------------------

DROP TABLE IF EXISTS DMLTable;


CREATE TEMPORARY TABLE DMLTable
(
SequenceNumber  INTEGER PRIMARY KEY,
String          VARCHAR(100) NOT NULL
);


INSERT INTO DMLTable (SequenceNumber, String) VALUES
(1,'SELECT'),
(2,'Product,'),
(3,'UnitPrice,'),
(4,'EffectiveDate'),
(5,'FROM'),
(6,'Products'),
(7,'WHERE'),
(8,'UnitPrice'),
(9,'> 100');


--Solution 1
--STRING_AGG
SELECT STRING_AGG(String::text, ' ' ORDER BY SequenceNumber ASC)
FROM DMLTable;



--Solution 2
--Recursion
WITH RECURSIVE cte_DMLGroupConcat AS 
(
SELECT  CAST('' AS VARCHAR) AS String2,
        MAX(SequenceNumber)::INTEGER AS Depth
FROM    DMLTable
UNION ALL
SELECT  cte_Ordered.String || ' ' || cte_Concat.String2, 
        cte_Concat.Depth - 1
FROM    cte_DMLGroupConcat cte_Concat INNER JOIN 
        DMLTable cte_Ordered ON cte_Concat.Depth = cte_Ordered.SequenceNumber
)
SELECT  String2
FROM    cte_DMLGroupConcat
WHERE   Depth = 0;



--Solution 3 (PostgreSQL does not have a FOR XML PATH equivalent)
--XML Path
--SELECT  DISTINCT
--        STUFF((
--            SELECT  CAST(' ' AS VARCHAR(MAX)) + String
--            FROM    DMLTable U
--            ORDER BY SequenceNumber
--        FOR XML PATH('')), 1, 1, '') AS DML_String
--FROM    DMLTable;


/*----------------------------------------------------
Answer to Puzzle #16
Reciprocals
*/----------------------------------------------------

DROP TABLE IF EXISTS PlayerScores;


CREATE TEMPORARY TABLE PlayerScores
(
PlayerA  INTEGER,
PlayerB  INTEGER,
Score    INTEGER NOT NULL,
PRIMARY KEY (PlayerA, PlayerB)
);


INSERT INTO PlayerScores (PlayerA, PlayerB, Score) VALUES
(1001,2002,150),(3003,4004,15),(4004,3003,125);


SELECT  PlayerA,
        PlayerB,
        SUM(Score) AS Score
FROM    (
        SELECT
                (CASE WHEN PlayerA <= PlayerB THEN PlayerA ELSE PlayerB END) PlayerA,
                (CASE WHEN PlayerA <= PlayerB THEN PlayerB ELSE PlayerA END) PlayerB,
                Score
        FROM    PlayerScores
        ) a
GROUP BY PlayerA, PlayerB;


/*----------------------------------------------------
Answer to Puzzle #17
De-Grouping
*/----------------------------------------------------

DROP TABLE IF EXISTS Ungroup;
DROP TABLE IF EXISTS Numbers;


CREATE TEMPORARY TABLE Ungroup
(
ProductDescription  VARCHAR(100) PRIMARY KEY,
Quantity            INTEGER NOT NULL
);


INSERT INTO Ungroup (ProductDescription, Quantity) VALUES
('Pencil',3),('Eraser',4),('Notebook',2);


--Solution 1
--Numbers Table
CREATE TEMPORARY TABLE Numbers 
(
IntegerValue  INTEGER PRIMARY KEY
);

INSERT INTO Numbers (IntegerValue) VALUES (1), (2), (3), (4);


ALTER TABLE Ungroup ADD FOREIGN KEY (Quantity) REFERENCES Numbers(IntegerValue);

--Solution 1
SELECT  a.ProductDescription,
        1 AS Quantity
FROM    Ungroup a CROSS JOIN
        Numbers b
WHERE   a.Quantity >= b.IntegerValue;

--Solution 2
--Recursion
WITH RECURSIVE cte_Recursion AS 
(
SELECT  ProductDescription,
        Quantity
FROM    Ungroup
UNION ALL
SELECT  ProductDescription,
        Quantity - 1
FROM    cte_Recursion
WHERE   Quantity >= 2
)
SELECT  ProductDescription,
        1 AS Quantity
FROM    cte_Recursion
ORDER BY ProductDescription DESC;


/*----------------------------------------------------
Answer to Puzzle #18
Seating Chart
*/----------------------------------------------------

DROP TABLE IF EXISTS SeatingChart;


CREATE TEMPORARY TABLE SeatingChart
(
SeatNumber  INTEGER PRIMARY KEY
);


INSERT INTO SeatingChart (SeatNumber) VALUES
(7),(13),(14),(15),(27),(28),(29),(30),(31),(32),(33),(34),(35),(52),(53),(54);


--Place a value of 0 in the SeatingChart table
INSERT INTO SeatingChart VALUES (0);


-------------------
--Gap start and gap end
WITH cte_Gaps AS 
(
SELECT  SeatNumber AS GapStart,
        LEAD(SeatNumber,1,0) OVER (ORDER BY SeatNumber) AS GapEnd,
        LEAD(SeatNumber,1,0) OVER (ORDER BY SeatNumber) - SeatNumber AS Gap
FROM    SeatingChart
)
SELECT  GapStart + 1 AS GapStart,
        GapEnd - 1 AS GapEnd
FROM    cte_Gaps
WHERE Gap > 1;


-------------------
--Missing Numbers
--Solution 1
--This solution provides a method if you need to window/partition the records
WITH cte_Rank
AS
(
SELECT  SeatNumber,
        ROW_NUMBER() OVER (ORDER BY SeatNumber) AS RowNumber,
        SeatNumber - ROW_NUMBER() OVER (ORDER BY SeatNumber) AS Rnk
FROM    SeatingChart
WHERE   SeatNumber > 0
)
SELECT  MAX(Rnk) AS MissingNumbers 
FROM    cte_Rank;


--Solution 2
SELECT  MAX(SeatNumber) - COUNT(SeatNumber) AS MissingNumbers
FROM    SeatingChart
WHERE   SeatNumber <> 0;


-------------------
--Odd and even number count
SELECT  (CASE SeatNumber%2 WHEN 1 THEN 'Odd' WHEN 0 THEN 'Even' END) AS Modulus,
        COUNT(*) AS Count
FROM    SeatingChart
GROUP BY (CASE SeatNumber%2 WHEN 1 THEN 'Odd' WHEN 0 THEN 'Even' END);


/*----------------------------------------------------
Answer to Puzzle #19
Back to the Future
*/----------------------------------------------------

DROP TABLE IF EXISTS TimePeriods;
DROP TABLE IF EXISTS Distinct_StartDates;
DROP TABLE IF EXISTS OuterJoin;
DROP TABLE IF EXISTS DetermineValidEndDates;
DROP TABLE IF EXISTS DetermineValidEndDates2;


CREATE TEMPORARY TABLE TimePeriods
(
StartDate  DATE,
EndDate    DATE,
PRIMARY KEY (StartDate, EndDate)
);


INSERT INTO TimePeriods (StartDate, EndDate) VALUES
('1/1/2018','1/5/2018'),
('1/3/2018','1/9/2018'),
('1/10/2018','1/11/2018'),
('1/12/2018','1/16/2018'),
('1/15/2018','1/19/2018');


--Step 1
SELECT  DISTINCT
        StartDate
INTO    Distinct_StartDates
FROM    TimePeriods;


--Step 2
SELECT  a.StartDate AS StartDate_A,
        a.EndDate AS EndDate_A,
        b.StartDate AS StartDate_B,
        b.EndDate AS EndDate_B
INTO    OuterJoin
FROM    TimePeriods AS a LEFT OUTER JOIN
        TimePeriods AS b ON a.EndDate >= b.StartDate AND
                                a.EndDate < b.EndDate;


--Step 3
SELECT  EndDate_A
INTO    DetermineValidEndDates
FROM    OuterJoin
WHERE   StartDate_B IS NULL
GROUP BY EndDate_A;


--Step 4
SELECT  a.StartDate, MIN(b.EndDate_A) AS MinEndDate_A
INTO    DetermineValidEndDates2
FROM    Distinct_StartDates a INNER JOIN
        DetermineValidEndDates b ON a.StartDate <= b.EndDate_A
GROUP BY a.StartDate;


--Results
SELECT  MIN(StartDate) AS StartDate,
        MAX(MinEndDate_A) AS EndDate
FROM    DetermineValidEndDates2
GROUP BY MinEndDate_A;


/*----------------------------------------------------
Answer to Puzzle #20
Price Points
*/----------------------------------------------------

DROP TABLE IF EXISTS ValidPrices;


CREATE TEMPORARY TABLE ValidPrices
(
ProductID      INTEGER,
UnitPrice      MONEY,
EffectiveDate  DATE,
PRIMARY KEY (ProductID, UnitPrice, EffectiveDate)
);


INSERT INTO ValidPrices (ProductID, UnitPrice, EffectiveDate) VALUES
(1001,1.99,'1/01/2018'),
(1001,2.99,'4/15/2018'),
(1001,3.99,'6/8/2018'),
(2002,1.99,'4/17/2018'),
(2002,2.99,'5/19/2018');


--Solution 1
--NOT EXISTS
SELECT  ProductID,
        EffectiveDate,
        COALESCE(UnitPrice,CAST(0 AS MONEY)) AS UnitPrice
FROM    ValidPrices AS pp
WHERE   NOT EXISTS (SELECT    1
                    FROM      ValidPrices AS ppl
                    WHERE     ppl.ProductID = pp.ProductID AND
                              ppl.EffectiveDate > pp.EffectiveDate);


--Solution 2
--RANK
WITH cte_ValidPrices AS
(
SELECT  RANK() OVER (PARTITION BY ProductID ORDER BY EffectiveDate DESC) AS Rnk,
        ProductID,
        EffectiveDate,
        UnitPrice
FROM    ValidPrices
)
SELECT  Rnk, ProductID, EffectiveDate, UnitPrice
FROM    cte_ValidPrices
WHERE   Rnk = 1;


--Solution 3
--MAX
WITH cte_MaxEffectiveDate AS
(
SELECT  ProductID,
        MAX(EffectiveDate) AS MaxEffectiveDate
FROM    ValidPrices
GROUP BY ProductID
)
SELECT  a.*
FROM    ValidPrices a INNER JOIN
        cte_MaxEffectiveDate b ON a.EffectiveDate = b.MaxEffectiveDate AND a.ProductID = b.ProductID;


/*----------------------------------------------------
Answer to Puzzle #21
Average Monthly Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;


CREATE TEMPORARY TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
OrderDate   DATE NOT NULL,
Amount      MONEY NOT NULL,
"State"     VARCHAR(2) NOT NULL
);


INSERT INTO Orders (OrderID, CustomerID, OrderDate, Amount, "State") VALUES
(1,1001,'1/1/2018',100,'TX'),
(2,1001,'1/1/2018',150,'TX'),
(3,1001,'1/1/2018',75,'TX'),
(4,1001,'2/1/2018',100,'TX'),
(5,1001,'3/1/2018',100,'TX'),
(6,2002,'2/1/2018',75,'TX'),
(7,2002,'2/1/2018',150,'TX'),
(8,3003,'1/1/2018',100,'IA'),
(9,3003,'2/1/2018',100,'IA'),
(10,3003,'3/1/2018',100,'IA'),
(11,4004,'4/1/2018',100,'IA'),
(12,4004,'5/1/2018',50,'IA'),
(13,4004,'5/1/2018',100,'IA');


WITH cte_AvgMonthlySalesCustomer AS
(
SELECT  CustomerID,
        OrderDate,
	    "State",
        AVG(Amount::numeric) AS AverageValue        
FROM    Orders
GROUP BY CustomerID, OrderDate, "State"
),
cte_MinAverageValueState AS
(
SELECT  "State"
FROM    cte_AvgMonthlySalesCustomer
GROUP BY "State"
HAVING  MIN(AverageValue) >= 100
)
SELECT  "State"
FROM    cte_MinAverageValueState;


/*----------------------------------------------------
Answer to Puzzle #22
Occurrences
*/----------------------------------------------------

DROP TABLE IF EXISTS ProcessLog;


CREATE TEMPORARY TABLE ProcessLog
(
Workflow     VARCHAR(100),
LogMessage   VARCHAR(100),
Occurrences  INTEGER NOT NULL,
PRIMARY KEY (Workflow, LogMessage)
);


INSERT INTO ProcessLog (Workflow, LogMessage, Occurrences) VALUES
('Alpha','Error: Conversion Failed',5),
('Alpha','Status Complete',8),
('Alpha','Error: Unidentified error occurred',9),
('Bravo','Error: Cannot Divide by 0',3),
('Bravo','Error: Unidentified error occurred',1),
('Charlie','Error: Unidentified error occurred',10),
('Charlie','Error: Conversion Failed',7),
('Charlie','Status Complete',6);


--Solution 1
--MAX
WITH cte_LogMessageCount AS
(
SELECT  LogMessage,
        MAX(Occurrences) AS MaxOccurrences
FROM    ProcessLog
GROUP BY LogMessage
)
SELECT  a.Workflow,
        a.LogMessage,
        a.Occurrences
FROM    ProcessLog a INNER JOIN
        cte_LogMessageCount b ON a.LogMessage = b.LogMessage AND
                                 a.Occurrences = b.MaxOccurrences
ORDER BY 1;


--Solution 2
--ALL
SELECT  WorkFlow,
        LogMessage,
        Occurrences
FROM    ProcessLog AS e1
WHERE   Occurrences > ALL(SELECT    e2.Occurrences
                            FROM    ProcessLog AS e2
                            WHERE   e2.LogMessage = e1.LogMessage AND
                                    e2.WorkFlow <> e1.WorkFlow);


/*----------------------------------------------------
Answer to Puzzle #23
Divide in Half
*/----------------------------------------------------

DROP TABLE IF EXISTS PlayerScores;


CREATE TEMPORARY TABLE PlayerScores
(
PlayerID  INTEGER PRIMARY KEY,
Score     INTEGER NOT NULL
);


INSERT INTO PlayerScores (PlayerID, Score) VALUES
(1001,2343),(2002,9432),
(3003,6548),(4004,1054),
(5005,6832);


SELECT  NTILE(2) OVER (ORDER BY Score DESC) AS Quartile,
        PlayerID,
        Score
FROM    PlayerScores a
ORDER BY Score DESC;


/*----------------------------------------------------
Answer to Puzzle #24
Page Views
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;


CREATE TEMPORARY TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
OrderDate   DATE NOT NULL,
Amount      MONEY NOT NULL,
State     VARCHAR(2) NOT NULL
);


INSERT INTO Orders (OrderID, CustomerID, OrderDate, Amount, State) VALUES
(1,1001,'1/1/2018',100,'TX'),
(2,1001,'1/1/2018',150,'TX'),
(3,1001,'1/1/2018',75,'TX'),
(4,1001,'2/1/2018',100,'TX'),
(5,1001,'3/1/2018',100,'TX'),
(6,2002,'2/1/2018',75,'TX'),
(7,2002,'2/1/2018',150,'TX'),
(8,3003,'1/1/2018',100,'IA'),
(9,3003,'2/1/2018',100,'IA'),
(10,3003,'3/1/2018',100,'IA'),
(11,4004,'4/1/2018',100,'IA'),
(12,4004,'5/1/2018',50,'IA'),
(13,4004,'5/1/2018',100,'IA');


--Solution 1
--OFFSET FETCH NEXT
SELECT  OrderID, CustomerID, OrderDate, Amount, State
FROM    Orders
ORDER BY OrderID
OFFSET 4 ROWS FETCH NEXT 6 ROWS ONLY;


--Solution 2
--RowNumber
WITH cte_RowNumber AS
(
SELECT  ROW_NUMBER() OVER (ORDER BY OrderID) AS RowNumber,
        OrderID, CustomerID, OrderDate, Amount, State
FROM    Orders
)
SELECT  OrderID, CustomerID, OrderDate, Amount, State
FROM    cte_RowNumber
WHERE   RowNumber BETWEEN 5 AND 10;


/*----------------------------------------------------
Answer to Puzzle #25
Top Vendors
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;


CREATE TEMPORARY TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
Count       INTEGER NOT NULL,
Vendor      VARCHAR(100) NOT NULL
);


INSERT INTO Orders (OrderID, CustomerID, Count, Vendor) VALUES
(1,1001,12,'Direct Parts'),
(2,1001,54,'Direct Parts'),
(3,1001,32,'ACME'),
(4,2002,7,'ACME'),
(5,2002,16,'ACME'),
(6,2002,5,'Direct Parts');


--Solution 1
--MAX window function
WITH cte_Max AS
(
SELECT  OrderID, CustomerID, Count, Vendor,
        MAX(Count) OVER (PARTITION BY CustomerID ORDER BY CustomerID) AS MaxCount
FROM    Orders
)
SELECT  CustomerID, Vendor
FROM    cte_Max
WHERE   Count = MaxCount
ORDER BY 1, 2;


--Solution 1
--RANK function
WITH cte_Rank AS
(
SELECT  CustomerID,
        Vendor,
        RANK() OVER (PARTITION BY CustomerID ORDER BY Count DESC) AS Rnk
FROM    Orders
GROUP BY CustomerID, Vendor, Count
)
SELECT  DISTINCT b.CustomerID, b.Vendor
FROM    Orders a INNER JOIN
        cte_Rank b ON a.CustomerID = b.CustomerID AND a.Vendor = b.Vendor
WHERE   Rnk = 1
ORDER BY 1, 2;


--Solution 3
--MAX with Correlated SubQuery
WITH cte_Max AS
(
SELECT  CustomerID,
        MAX(Count) AS MaxOrderCount
FROM    Orders
GROUP BY CustomerID
)
SELECT  CustomerID, Vendor
FROM    Orders a
WHERE   EXISTS (SELECT 1 FROM cte_Max b WHERE a.CustomerID = b.CustomerID and a.Count = MaxOrderCount)
ORDER BY 1, 2;


--Solution 4
--ALL Operator
SELECT  CustomerID, Vendor
FROM    Orders a
WHERE   Count >= ALL(SELECT Count FROM Orders b WHERE a.CustomerID = b.CustomerID)
ORDER BY 1, 2;


--Solution 5
--MAX Function
SELECT  CustomerID, Vendor
FROM    Orders a
WHERE   Count >= (SELECT MAX(Count) FROM Orders b WHERE a.CustomerID = b.CustomerID)
ORDER BY 1, 2;


/*----------------------------------------------------
Answer to Puzzle #26
Previous Years Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Sales;


CREATE TEMPORARY TABLE Sales
(
"Year"  INTEGER NOT NULL,
Amount  INTEGER NOT NULL
);


INSERT INTO Sales ("Year", Amount) VALUES
(EXTRACT(YEAR FROM CURRENT_DATE), 352645),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 year'), 165565),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 year'), 254654),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '2 years'), 159521),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '2 years'), 251696),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '3 years'), 111894);


--Solution 1 (PIVOT is not a supported PostgreSQL operator)
--PIVOT
--SELECT 2018,2017,2016 FROM Sales
--PIVOT (SUM(Amount) FOR Year IN (2018,2017,2016)) AS PivotClause;


--Solution 2
--LAG
WITH cte_AggregateTotal AS
(
SELECT  "Year",
        SUM(Amount) AS Amount
FROM    Sales
GROUP BY "Year"
),
cte_Lag AS
(
SELECT  "Year",
        Amount,
        LAG(Amount,1,0) OVER (ORDER BY "Year") AS Lag1,
        LAG(Amount,2,0) OVER (ORDER BY "Year") AS Lag2
FROM    cte_AggregateTotal
)
SELECT  Amount AS "2023",
        Lag1 AS "2022",
        Lag2 AS "2021"
FROM    cte_Lag
WHERE   "Year" = 2023;


--Solution 3
--Dynamic SQL without hardcoded dates
DROP TABLE IF EXISTS SalesPivot;

DO $$
DECLARE
    CurrentYear text := TO_CHAR(CURRENT_DATE, 'YYYY');
    CurrentYearLag1 text := TO_CHAR(CURRENT_DATE - INTERVAL '1 year', 'YYYY');
    CurrentYearLag2 text := TO_CHAR(CURRENT_DATE - INTERVAL '2 years', 'YYYY');
    DynamicSQL text;
BEGIN
    DynamicSQL := 'CREATE TEMPORARY TABLE SalesPivot AS SELECT 
                          SUM(CASE WHEN "Year" = ' || CurrentYear || ' THEN amount ELSE 0 END) AS "' || CurrentYear || '",
                          SUM(CASE WHEN "Year" = ' || CurrentYearLag1 || ' THEN amount ELSE 0 END) AS "' || CurrentYearLag1 || '",
                          SUM(CASE WHEN "Year" = ' || CurrentYearLag2 || ' THEN amount ELSE 0 END) AS "' || CurrentYearLag2 || '"
                   FROM Sales;';

    RAISE NOTICE '%', DynamicSQL;
    EXECUTE DynamicSQL;
END $$;

SELECT * FROM SalesPivot;

/*----------------------------------------------------
Answer to Puzzle #27
Delete the Duplicates
*/----------------------------------------------------

DROP TABLE IF EXISTS SampleData;


CREATE TEMPORARY TABLE SampleData
(
IntegerValue  INTEGER NOT NULL
);


INSERT INTO SampleData (IntegerValue) VALUES
(1),(1),(2),(3),(3),(4);


DELETE FROM SampleData
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM SampleData
    GROUP BY IntegerValue
);


/*----------------------------------------------------
Answer to Puzzle #28
Fill the Gaps

This is often called a Flash Fill or a Data Smudge
*/----------------------------------------------------

DROP TABLE IF EXISTS Gaps;


CREATE TEMPORARY TABLE Gaps
(
RowNumber  INTEGER PRIMARY KEY,
TestCase   VARCHAR(100) NULL
);


INSERT INTO Gaps (RowNumber, TestCase) VALUES
(1,'Alpha'),(2,NULL),(3,NULL),(4,NULL),
(5,'Bravo'),(6,NULL),(7,'Charlie'),(8,NULL),(9,NULL);


--Solution 1
--MAX and COUNT function
WITH cte_Count AS
(
SELECT RowNumber,
       TestCase,
       COUNT(TestCase) OVER (ORDER BY RowNumber) AS DistinctCount
FROM Gaps
)
SELECT  RowNumber,
        MAX(TestCase) OVER (PARTITION BY DistinctCount) AS TestCase
FROM    cte_Count
ORDER BY RowNumber;


--Solution 2
--MAX function without windowing
SELECT  a.RowNumber,
        (SELECT b.TestCase
        FROM    Gaps b
        WHERE   b.RowNumber =
                    (SELECT MAX(c.RowNumber)
                    FROM Gaps c
                    WHERE c.RowNumber <= a.RowNumber AND c.TestCase != '')) TestCase
FROM Gaps a;


/*----------------------------------------------------
Answer to Puzzle #29
Count the Groupings
*/----------------------------------------------------
DROP TABLE IF EXISTS Groupings;


CREATE TEMPORARY TABLE Groupings
(
StepNumber  INTEGER PRIMARY KEY,
TestCase    VARCHAR(100) NOT NULL,
Status      VARCHAR(100) NOT NULL
);


INSERT INTO Groupings (StepNumber, TestCase, Status) VALUES
(1,'Test Case 1','Passed'),
(2,'Test Case 2','Passed'),
(3,'Test Case 3','Passed'),
(4,'Test Case 4','Passed'),
(5,'Test Case 5','Failed'),
(6,'Test Case 6','Failed'),
(7,'Test Case 7','Failed'),
(8,'Test Case 8','Failed'),
(9,'Test Case 9','Failed'),
(10,'Test Case 10','Passed'),
(11,'Test Case 11','Passed'),
(12,'Test Case 12','Passed');


--Solution 1
WITH cte_Groupings AS
(
SELECT  StepNumber,
        Status,
        StepNumber - ROW_NUMBER() OVER (PARTITION BY Status ORDER BY StepNumber) AS Rnk
FROM    Groupings
)
SELECT  MIN(StepNumber) AS MinStepNumber,
        MAX(StepNumber) AS MaxStepNumber,
        Status,
        COUNT(*) AS ConsecutiveCount,
        MAX(StepNumber) - MIN(StepNumber) + 1 AS ConsecutiveCount_MinMax
FROM    cte_Groupings
GROUP BY Rnk,
        Status
ORDER BY 1, 2;


--Solution 2
WITH cte_Lag AS
(
SELECT  *,
        LAG(Status) OVER(ORDER BY StepNumber) AS PreviousStatus
FROM    Groupings
),
cte_Groupings AS
(
SELECT  *,
        SUM(CASE WHEN PreviousStatus <> Status THEN 1 ELSE 0 END) OVER (ORDER BY StepNumber) AS GroupNumber
FROM    cte_Lag
)
SELECT  MIN(StepNumber) AS MinStepNumber,
        MAX(StepNumber) AS MaxStepNumber,
        Status,
        COUNT(*) AS ConsecutiveCount,
        MAX(StepNumber) - MIN(StepNumber) + 1 AS ConsecutiveCount_MinMax
FROM    cte_Groupings
GROUP BY Status, GroupNumber;


/*----------------------------------------------------
Answer to Puzzle #30
Select Star
*/----------------------------------------------------

DROP TABLE IF EXISTS Products;


CREATE TEMPORARY TABLE Products
(
ProductID    INTEGER PRIMARY KEY,
ProductName  VARCHAR(100) NOT NULL
);


--Add the following constraint
--ALTER TABLE Products ADD ComputedColumn AS (0/0);

/*
It is not possible to add a computed column in PostgreSQL without referencing another column.
See the following documentation
https://www.postgresql.org/docs/current/ddl-generated-columns.html
*/

/*----------------------------------------------------
Answer to Puzzle #31
Second Highest
*/----------------------------------------------------

DROP TABLE IF EXISTS SampleData;


CREATE TEMPORARY TABLE SampleData
(
IntegerValue  INTEGER PRIMARY KEY
);


INSERT INTO SampleData (IntegerValue) VALUES
(3759),(3760),(3761),(3762),(3763);


--Solution 1
--RANK
WITH cte_Rank AS
(
SELECT  RANK() OVER (ORDER BY IntegerValue DESC) AS MyRank,
        *
FROM    SampleData
)
SELECT  *
FROM    cte_Rank
WHERE   MyRank = 2;


--Solution 2
--Top 1 and Max
SELECT  *
FROM    SampleData
WHERE   IntegerValue <> (SELECT MAX(IntegerValue) FROM SampleData)
ORDER BY IntegerValue DESC
LIMIT 1;


--Solution 3
--Offset and Fetch
SELECT  *
FROM    SampleData
ORDER BY IntegerValue DESC
OFFSET 1 ROWS
FETCH NEXT 1 ROWS ONLY;


--Solution 4
--Top 1 and Top 2
SELECT  *
FROM    (
        SELECT  *
        FROM    SampleData
        ORDER BY IntegerValue DESC
        LIMIT 2
        ) a
ORDER BY IntegerValue ASC
LIMIT 1;


--Solution 5
--Min and Top 2
WITH cte_TopMin AS
(
SELECT  MIN(IntegerValue) AS MinIntegerValue
FROM   (
       SELECT  *
       FROM    SampleData
       ORDER BY IntegerValue DESC
       LIMIT 2
       ) a
)
SELECT  *
FROM    SampleData
WHERE   IntegerValue IN (SELECT MinIntegerValue FROM cte_TopMin);


--Solution 6
--Correlated Sub-Query
SELECT  *
FROM    SampleData a
WHERE   2 = (SELECT COUNT(DISTINCT b.IntegerValue)
             FROM SampleData b
             WHERE a.IntegerValue <= b.IntegerValue);


--Solution 7
--Top 1 and Lag
WITH cte_LeadLag AS
(
SELECT  *,
        LAG(IntegerValue, 1, NULL) OVER (ORDER BY IntegerValue DESC) AS PreviousValue
FROM    SampleData
)
SELECT  *
FROM    cte_LeadLag
WHERE   PreviousValue IS NOT NULL
ORDER BY IntegerValue DESC
LIMIT 1;


/*----------------------------------------------------
Answer to Puzzle #32
First and Last
*/----------------------------------------------------

DROP TABLE IF EXISTS Personal;


CREATE TEMPORARY TABLE Personal
(
SpacemanID      INTEGER PRIMARY KEY,
JobDescription  VARCHAR(100) NOT NULL,
MissionCount    INTEGER NOT NULL
);


INSERT INTO Personal (SpacemanID, JobDescription, MissionCount) VALUES
(1001,'Astrogator',6),(2002,'Astrogator',12),(3003,'Astrogator',17),
(4004,'Geologist',21),(5005,'Geologist',9),(6006,'Geologist',8),
(7007,'Technician',13),(8008,'Technician',2),(9009,'Technician',7);


--MIN and MAX
WITH cte_MinMax AS
(
SELECT  JobDescription,
        MAX(MissionCount) AS MaxMissionCount,
        MIN(MissionCount) AS MinMissionCount
FROM    Personal
GROUP BY JobDescription
)
SELECT  a.JobDescription,
        b.SpacemanID AS MostExperienced,
        c.SpacemanID AS LeastExperienced
FROM    cte_MinMax a INNER JOIN
        Personal b ON a.JobDescription = b.JobDescription AND
                       a.MaxMissionCount = b.MissionCount  INNER JOIN
        Personal c ON a.JobDescription = c.JobDescription AND
                       a.MinMissionCount = c.MissionCount;


/*----------------------------------------------------
Answer to Puzzle #33
Deadlines
*/----------------------------------------------------

DROP TABLE IF EXISTS ManufacturingTimes;
DROP TABLE IF EXISTS Orders;


CREATE TEMPORARY TABLE ManufacturingTimes
(
PartID             VARCHAR(100),
Product            VARCHAR(100),
DaysToManufacture  INTEGER NOT NULL,
PRIMARY KEY (PartID, Product)
);

CREATE TEMPORARY TABLE Orders
(
OrderID        INTEGER PRIMARY KEY,
Product        VARCHAR(100) NOT NULL /*REFERENCES ManufacturingTimes (Product)*/, --ERROR:  there is no unique constraint matching given keys for referenced table "manufacturingtimes" 
DaysToDeliver  INTEGER NOT NULL
);


INSERT INTO ManufacturingTimes (PartID, Product, DaysToManufacture) VALUES
('AA-111','Widget',7),
('BB-222','Widget',2),
('CC-333','Widget',3),
('DD-444','Widget',1),
('AA-111','Gizmo',7),
('BB-222','Gizmo',2),
('AA-111','Doodad',7),
('DD-444','Doodad',1);


INSERT INTO Orders (OrderID, Product, DaysToDeliver) VALUES
(1,'Widget',7),
(2,'Gizmo',3),
(3,'Doodad',9);


--Solution 1
--MAX with INNER JOIN
WITH cte_Max AS
(
SELECT  Product,
        MAX(DaysToManufacture) AS MaxDaysToManufacture
FROM    ManufacturingTimes b
GROUP BY Product
)
SELECT  a.OrderID,
        a.Product
FROM    Orders a INNER JOIN
        cte_Max b ON a.Product = b.Product AND a.DaysToDeliver >= b.MaxDaysToManufacture;


--Solution 2
--MAX with correlated subquery
WITH cte_Max AS
(
SELECT  Product, MAX(DaysToManufacture) AS MaxDaysToManufacture
FROM    ManufacturingTimes b
GROUP BY Product
)
SELECT  OrderID,
        Product
FROM    Orders a
WHERE   EXISTS (SELECT  1
                FROM    cte_Max b 
                WHERE   a.Product = b.Product AND
                        a.DaysToDeliver >= b.MaxDaysToManufacture);


--Solution 3
--ALL
SELECT  OrderID,
        Product
FROM    Orders a
WHERE   DaysToDeliver >= ALL(SELECT  DaysToManufacture 
                              FROM    ManufacturingTimes b 
                              WHERE   a.Product = b.Product);




/*----------------------------------------------------
Answer to Puzzle #34
Specific Exclusion
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;


CREATE TEMPORARY TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
Amount      MONEY NOT NULL
);


INSERT INTO Orders (OrderID, CustomerID, Amount) VALUES
(1,1001,25),(2,1001,50),(3,2002,65),(4,3003,50);


--Solutions 1 and 2 show Morgan's Law.
--Solution 1
--NOT
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
WHERE   NOT(CustomerID = 1001 AND Amount = (50::money));


--Solution 2 
--OR
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
WHERE   CustomerID <> 1001 OR Amount <> (50::money);


--Solution 3
--EXCEPT
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
EXCEPT
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
WHERE   CustomerID <> 1001 OR Amount <> (50::money);


/*----------------------------------------------------
Answer to Puzzle #35
International vs Domestic Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;


CREATE TEMPORARY TABLE Orders
(
InvoiceID   INTEGER PRIMARY KEY,
SalesRepID  INTEGER NOT NULL,
Amount      MONEY NOT NULL,
SalesType   VARCHAR(100) NOT NULL
);


INSERT INTO Orders (InvoiceID, SalesRepId, Amount, SalesType) VALUES
(1,1001,13454,'International'),
(2,1001,3434,'International'),
(3,2002,54645,'International'),
(4,3003,234345,'International'),
(5,4004,776,'International'),
(6,1001,4564,'Domestic'),
(7,2002,34534,'Domestic'),
(8,2002,345,'Domestic'),
(9,5005,6543,'Domestic'),
(10,6006,67,'Domestic');


WITH cte_InterDomestic AS
(
SELECT  SalesRepID
FROM    Orders
GROUP BY SalesRepID
HAVING   COUNT(DISTINCT SalesType) = 2
)
SELECT  DISTINCT SalesRepID
FROM    Orders 
WHERE   SalesRepID NOT IN (SELECT SalesRepID FROM cte_InterDomestic);

/*----------------------------------------------------
Answer to Puzzle #36
Traveling Salesman
*/----------------------------------------------------
DROP TABLE IF EXISTS Routes;

CREATE TEMPORARY TABLE Routes
(
RouteID        INTEGER NOT NULL,
DepartureCity  VARCHAR(30) NOT NULL,
ArrivalCity    VARCHAR(30) NOT NULL,
"Cost"         MONEY NOT NULL,
PRIMARY KEY (DepartureCity, ArrivalCity)
);


INSERT INTO Routes (RouteID, DepartureCity, ArrivalCity, "Cost") VALUES
(1,'Austin','Dallas',100),
(2,'Dallas','Memphis',200),
(3,'Memphis','Des Moines',300),
(4,'Dallas','Des Moines',400);

--Solution 1
--Recursion
DROP TABLE IF EXISTS RoutesList;
CREATE TEMPORARY TABLE RoutesList AS
WITH RECURSIVE cte_Map AS 
(
SELECT  2 AS Nodes,
        ArrivalCity AS LastNode,
        CAST('\' || DepartureCity || '\' || ArrivalCity || '\' AS VARCHAR(5000)) AS NodeMap,
        "Cost"
FROM    Routes
WHERE   DepartureCity = 'Austin'
UNION ALL
SELECT  m.Nodes + 1 AS Nodes,
        r.ArrivalCity AS LastNode,
        CAST(m.NodeMap || r.ArrivalCity || '\' AS VARCHAR(5000)) AS NodeMap,
        m."Cost" + r."Cost" AS "Cost"
FROM    cte_Map AS m INNER JOIN 
        Routes AS r ON r.DepartureCity = m.LastNode
WHERE   m.NodeMap NOT LIKE '%\' || r.ArrivalCity || '\%'
)
SELECT  NodeMap, 
        "Cost"
FROM    cte_Map;

WITH cte_LeftReplace AS
(
SELECT  LEFT(NodeMap,LENGTH(NodeMap)-1) AS RoutePath,
        "Cost"
FROM    RoutesList
WHERE   RIGHT(NodeMap,11) = 'Des Moines\'
),
cte_RightReplace AS
(
SELECT  SUBSTRING(RoutePath,2,LENGTH(RoutePath)-1) AS RoutePath,
        "Cost"
FROM    cte_LeftReplace
)
SELECT  REPLACE(RoutePath,'\', ' -->') AS RoutePath,
        "Cost" AS TotalCost
FROM    cte_RightReplace;

--Solution 2
--WHILE Loop
DROP TABLE IF EXISTS RoutesList;

CREATE TEMPORARY TABLE RoutesList
(
InsertDate     TIMESTAMP DEFAULT CURRENT_DATE NOT NULL,
RouteInsertID  INTEGER NOT NULL,
RoutePath      VARCHAR(8000) NOT NULL,
TotalCost      MONEY NOT NULL,
LastArrival    VARCHAR(100)
);


INSERT INTO RoutesList (RouteInsertID, RoutePath, TotalCost, LastArrival)
SELECT  1,
        CONCAT(DepartureCity,',',ArrivalCity),
        "Cost",
        ArrivalCity
FROM    Routes
WHERE   DepartureCity = 'Austin';

DO $$
DECLARE
    vRowCount INTEGER := 1;
    vRouteInsertID INTEGER := 2;
BEGIN
    LOOP

        WITH cte_LastArrival AS (
            SELECT 
                RoutePath,
                TotalCost,
                REVERSE(SPLIT_PART(REVERSE(RoutePath), ',', 1)) AS LastArrival
            FROM 
                RoutesList
            WHERE 
                LastArrival <> 'Des Moines'
        )
        INSERT INTO RoutesList (RouteInsertID, RoutePath, TotalCost, LastArrival)
        SELECT 
            vRouteInsertID,
            a.RoutePath || ',' || b.ArrivalCity,
            a.TotalCost + b."Cost",
            b.ArrivalCity
        FROM 
            cte_LastArrival a
        INNER JOIN 
            Routes b ON a.LastArrival = b.DepartureCity AND POSITION(b.ArrivalCity IN a.RoutePath) = 0;

        GET DIAGNOSTICS vRowCount := ROW_COUNT;

        -- Exit condition
        IF vRowCount < 1 THEN
            EXIT;
        END IF;

        -- Delete older routes
        DELETE FROM RoutesList
        WHERE RouteInsertID < vRouteInsertID
              AND LastArrival <> 'Des Moines';

        -- Increment RouteInsertID
        vRouteInsertID := vRouteInsertID + 1;
    END LOOP;
END;
$$;

SELECT  REPLACE(RoutePath,',',' --> ') AS RoutePath,
        TotalCost
FROM    RoutesList
ORDER BY 1;


/*----------------------------------------------------
Answer to Puzzle #37
Group Criteria Keys
*/----------------------------------------------------

DROP TABLE IF EXISTS GroupCriteria;


CREATE TEMPORARY TABLE GroupCriteria
(
OrderID      INTEGER PRIMARY KEY,
Distributor  VARCHAR(100) NOT NULL,
Facility     INTEGER NOT NULL,
"Zone"       VARCHAR(100) NOT NULL,
Amount       MONEY NOT NULL
);


INSERT INTO GroupCriteria (OrderID, Distributor, Facility, "Zone", Amount) VALUES
(1,'ACME',123,'ABC',100),
(2,'ACME',123,'ABC',75),
(3,'Direct Parts',789,'XYZ',150),
(4,'Direct Parts',789,'XYZ',125);


SELECT  DENSE_RANK() OVER (ORDER BY Distributor, Facility, "Zone") AS CriteriaID,
        OrderID,
        Distributor,
        Facility,
        "Zone",
        Amount
FROM    GroupCriteria;


/*----------------------------------------------------
Answer to Puzzle #38
Reporting Elements
*/----------------------------------------------------

DROP TABLE IF EXISTS RegionSales;


CREATE TEMPORARY TABLE RegionSales
(
Region       VARCHAR(100),
Distributor  VARCHAR(100),
Sales        INTEGER NOT NULL,
PRIMARY KEY (Region, Distributor)
);


INSERT INTO RegionSales (Region, Distributor, Sales) VALUES
('North','ACE',10),
('South','ACE',67),
('East','ACE',54),
('North','ACME',65),
('South','ACME',9),
('East','ACME',1),
('West','ACME',7),
('North','Direct Parts',8),
('South','Direct Parts',7),
('West','Direct Parts',12);


WITH cte_DistinctRegion AS
(
SELECT  DISTINCT Region
FROM    RegionSales
),
cte_DistinctDistributor AS
(
SELECT  DISTINCT Distributor
FROM    RegionSales
),
cte_CrossJoin AS
(
SELECT  Region, Distributor
FROM    cte_DistinctRegion a CROSS JOIN
        cte_DistinctDistributor b
)
SELECT  a.Region,
        a.Distributor,
        COALESCE(b.Sales,0) AS Sales
FROM    cte_CrossJoin a LEFT OUTER JOIN
        RegionSales b ON a.Region = b.Region and a.Distributor = b.Distributor
ORDER BY a.Distributor,
        (CASE a.Region  WHEN 'North' THEN 1
                        WHEN 'South' THEN 2
                        WHEN 'East'  THEN 3
                        WHEN 'West'  THEN 4 END);


/*----------------------------------------------------
Answer to Puzzle #39
Prime Numbers
*/----------------------------------------------------

DROP TABLE IF EXISTS PrimeNumbers;


CREATE TEMPORARY TABLE PrimeNumbers
(
IntegerValue  INTEGER PRIMARY KEY
);


INSERT INTO PrimeNumbers (IntegerValue) VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10);


WITH cte_Mod AS
(
SELECT  a.IntegerValue, a.IntegerValue % b.IntegerValue AS Modulus
FROM    PrimeNumbers a INNER JOIN
        PrimeNumbers b ON a.IntegerValue >= b.IntegerValue
)
SELECT IntegerValue AS PrimeNumber
FROM   cte_Mod
WHERE  Modulus = 0
GROUP BY IntegerValue
HAVING COUNT(*) = 2;


/*----------------------------------------------------
Answer to Puzzle #40
Sort Order
*/----------------------------------------------------

DROP TABLE IF EXISTS SortOrder;


CREATE TEMPORARY TABLE SortOrder
(
City  VARCHAR(100) PRIMARY KEY
);


INSERT INTO SortOrder (City) VALUES
('Atlanta'),('Baltimore'),('Chicago'),('Denver');


SELECT  City
FROM    SortOrder
ORDER BY (CASE City WHEN 'Atlanta' THEN 2
                    WHEN 'Baltimore' THEN 1
                    WHEN 'Chicago' THEN 4
                    WHEN 'Denver' THEN 1 END);


/*----------------------------------------------------
Answer to Puzzle #41
Associate IDs
*/----------------------------------------------------

DROP TABLE IF EXISTS Associates;
DROP TABLE IF EXISTS Associates2;
DROP TABLE IF EXISTS Associates3;


CREATE TEMPORARY TABLE Associates
(
Associate1  VARCHAR(100),
Associate2  VARCHAR(100),
PRIMARY KEY (Associate1, Associate2)
);


INSERT INTO Associates (Associate1, Associate2) VALUES
('Anne','Betty'),('Anne','Charles'),('Betty','Dan'),('Charles','Emma'),
('Francis','George'),('George','Harriet');


--Step 1
--Recursion
-- Create a new table from a recursive CTE
CREATE TEMPORARY TABLE Associates2 AS
WITH RECURSIVE cte_Recursive AS 
(
SELECT  Associate1,
        Associate2
FROM    Associates
UNION ALL
SELECT  a.Associate1, b.Associate2
FROM    Associates a INNER JOIN 
        cte_Recursive b ON a.Associate2 = b.Associate1
)
SELECT  Associate1,
        Associate2
FROM    cte_Recursive
UNION ALL
SELECT  Associate1, 
        Associate1
FROM    Associates;


--Step 2
SELECT  MIN(Associate1) AS Associate1,
        Associate2
INTO    Associates3
FROM    Associates2
GROUP BY Associate2;


--Results
SELECT  DENSE_RANK() OVER (ORDER BY Associate1) AS GroupingNumber,
        Associate2 AS Associate
FROM    Associates3;


/*----------------------------------------------------
Answer to Puzzle #42
Mutual Friends
*/----------------------------------------------------

DROP TABLE IF EXISTS Friends;
DROP TABLE IF EXISTS Nodes;
DROP TABLE IF EXISTS Edges;
DROP TABLE IF EXISTS Nodes_Edges_To_Evaluate;


CREATE TEMPORARY TABLE Friends
(
Friend1  VARCHAR(100),
Friend2  VARCHAR(100),
PRIMARY KEY (Friend1, Friend2)
);


INSERT INTO Friends (Friend1, Friend2) VALUES
('Jason','Mary'),('Mike','Mary'),('Mike','Jason'),
('Susan','Jason'),('John','Mary'),('Susan','Mary');


--Create reciprocals (Edges)
SELECT  Friend1, Friend2
INTO    Edges
FROM    Friends
UNION
SELECT  Friend2, Friend1
FROM Friends;


--Created Nodes
SELECT Friend1 AS Person
INTO   Nodes
FROM   Friends
UNION
SELECT  Friend2
FROM    Friends;


--Cross join all Edges and Nodes
SELECT  a.Friend1, a.Friend2, b.Person
INTO    Nodes_Edges_To_Evaluate
FROM    Edges a CROSS JOIN
        Nodes b
ORDER BY 1,2,3;


--Evaluates the cross join to the edges
WITH cte_JoinLogic AS
(
SELECT  a.Friend1
        ,a.Friend2
        ,'---' AS Id1
        ,b.Friend2 AS MutualFriend1
        ,'----' AS Id2
        ,c.Friend2 AS MutualFriend2
FROM   Nodes_Edges_To_Evaluate a LEFT OUTER JOIN
       Edges b ON a.Friend1 = b.Friend1 and a.Person = b.Friend2 LEFT OUTER JOIN
       Edges c ON a.Friend2 = c.Friend1 and a.Person = c.Friend2
),
cte_Predicate AS
(
--Apply predicate logic
SELECT  Friend1, Friend2, MutualFriend1 AS MutualFriend
FROM    cte_JoinLogic
WHERE   MutualFriend1 = MutualFriend2 AND MutualFriend1 IS NOT NULL AND MutualFriend2 IS NOT NULL
),
cte_Count AS
(
SELECT  Friend1, Friend2, COUNT(*) AS CountMutualFriends
FROM    cte_Predicate
GROUP BY Friend1, Friend2
)
SELECT  DISTINCT
        (CASE WHEN Friend1 < Friend2 THEN Friend1 ELSE Friend2 END) AS Friend1,
        (CASE WHEN Friend1 < Friend2 THEN Friend2 ELSE Friend1 END) AS Friend2,
        CountMutualFriends
FROM    cte_Count
ORDER BY 1,2;


/*----------------------------------------------------
Answer to Puzzle #43
Unbounded Preceding
*/----------------------------------------------------

DROP TABLE IF EXISTS CustomerOrders;


CREATE TEMPORARY TABLE CustomerOrders
(
OrderID     INTEGER,
CustomerID  INTEGER,
Quantity    INTEGER NOT NULL,
PRIMARY KEY (OrderID, CustomerID)
);


INSERT INTO CustomerOrders (OrderID, CustomerID, Quantity) VALUES 
(1,1001,5),(2,1001,8),(3,1001,3),(4,1001,7),
(1,2002,4),(2,2002,9);


SELECT  OrderID,
        CustomerID,
        Quantity,
        MIN(Quantity) OVER (PARTITION by CustomerID ORDER BY OrderID) AS MinQuantity
FROM    CustomerOrders;


/*----------------------------------------------------
Answer to Puzzle #44
Slowly Changing Dimension Part I
*/----------------------------------------------------

DROP TABLE IF EXISTS Balances;


CREATE TEMPORARY TABLE Balances
(
CustomerID   INTEGER,
BalanceDate  DATE,
Amount       MONEY NOT NULL,
PRIMARY KEY (CustomerID, BalanceDate)
);


INSERT INTO Balances (CustomerID, BalanceDate, Amount) VALUES
(1001,'10/11/2021',54.32),
(1001,'10/10/2021',17.65),
(1001,'9/18/2021',65.56),
(1001,'9/12/2021',56.23),
(1001,'9/1/2021',42.12),
(2002,'10/15/2021',46.52),
(2002,'10/13/2021',7.65),
(2002,'9/15/2021',75.12),
(2002,'9/10/2021',47.34),
(2002,'9/2/2021',11.11);


WITH cte_Customers AS
(
SELECT  CustomerID,
        BalanceDate,
        LAG(BalanceDate) OVER 
                (PARTITION BY CustomerID ORDER BY BalanceDate DESC)
                    AS EndDate,
        Amount
FROM    Balances
)
SELECT  CustomerID,
        BalanceDate AS StartDate,
        COALESCE(EndDate - INTERVAL '1 day', '9999-12-31'::date) AS EndDate,
        Amount
FROM    cte_Customers
ORDER BY CustomerID, BalanceDate DESC;


/*---------------------------------------------------
Answer to Puzzle #45
Slowly Changing Dimension Part 2
*/----------------------------------------------------

DROP TABLE IF EXISTS Balances;


CREATE TEMPORARY TABLE Balances
(
CustomerID  INTEGER,
StartDate   DATE,
EndDate     DATE,
Amount      MONEY,
PRIMARY KEY (CustomerID, StartDate)
);


INSERT INTO Balances (CustomerID, StartDate, EndDate, Amount) VALUES
(1001,'10/11/2021','12/31/9999',54.32),
(1001,'10/10/2021','10/10/2021',17.65),
(1001,'9/18/2021','10/12/2021',65.56),
(2002,'9/12/2021','9/17/2021',56.23),
(2002,'9/1/2021','9/17/2021',42.12),
(2002,'8/15/2021','8/31/2021',16.32);


WITH cte_Lag AS
(
SELECT  CustomerID, StartDate, EndDate, Amount,
        LAG(StartDate) OVER 
            (PARTITION BY CustomerID ORDER BY StartDate DESC) AS StartDate_Lag
FROM    Balances
)
SELECT  CustomerID, StartDate, EndDate, Amount, StartDate_Lag
FROM    cte_Lag
WHERE   EndDate >= StartDate_Lag
ORDER BY CustomerID, StartDate DESC;


/*----------------------------------------------------
Answer to Puzzle #46
Positive Account Balances
*/----------------------------------------------------

DROP TABLE IF EXISTS AccountBalances;


CREATE TEMPORARY TABLE AccountBalances
(
AccountID  INTEGER,
Balance    MONEY,
PRIMARY KEY (AccountID, Balance)
);


INSERT INTO AccountBalances (AccountID, Balance) VALUES
(1001,234.45),(1001,-23.12),(2002,-93.01),(2002,-120.19),
(3003,186.76), (3003,90.23), (3003,10.11);


--Solution 1
--SET Operators
SELECT DISTINCT AccountID FROM AccountBalances WHERE Balance < (0::money)
EXCEPT
SELECT DISTINCT AccountID FROM AccountBalances WHERE Balance > (0::money);


--Solution 2
--MAX
SELECT  AccountID
FROM    AccountBalances
GROUP BY AccountID
HAVING  MAX(Balance) < (0::money);


--Solution 3
--NOT IN
SELECT  DISTINCT AccountID
FROM    AccountBalances
WHERE   AccountID NOT IN (SELECT AccountID FROM AccountBalances WHERE Balance > (0::money));


--Solution 4
--NOT EXISTS
SELECT  DISTINCT AccountID
FROM    AccountBalances a
WHERE   NOT EXISTS (SELECT AccountID FROM AccountBalances b WHERE Balance > (0::money) AND a.AccountID = b.AccountID);


--Solution 5
--LEFT OUTER JOIN
SELECT  DISTINCT a.AccountID
FROM    AccountBalances a LEFT OUTER JOIN
        AccountBalances b ON a.AccountID = b.AccountID AND b.Balance > (0::money)
WHERE   b.AccountID IS NULL;


/*----------------------------------------------------
Answer to Puzzle #47
Work Schedule
*/----------------------------------------------------

DROP TABLE IF EXISTS Activity;
DROP TABLE IF EXISTS Schedule;
DROP TABLE IF EXISTS ScheduleTimes;
DROP TABLE IF EXISTS ActivityCoalesce;


CREATE TEMPORARY TABLE Schedule
(
ScheduleId  CHAR(1) PRIMARY KEY,
StartTime   TIMESTAMP NOT NULL,
EndTime     TIMESTAMP NOT NULL
);


CREATE TEMPORARY TABLE Activity
(
ScheduleID    CHAR(1) REFERENCES Schedule (ScheduleID),
ActivityName  VARCHAR(100),
StartTime     TIMESTAMP,
EndTime       TIMESTAMP,
PRIMARY KEY (ScheduleID, ActivityName, StartTime, EndTime)
);


INSERT INTO Schedule (ScheduleID, StartTime, EndTime) VALUES
('A',CAST('2021-10-01 10:00:00' AS TIMESTAMP),CAST('2021-10-01 15:00:00' AS TIMESTAMP)),
('B',CAST('2021-10-01 10:15:00' AS TIMESTAMP),CAST('2021-10-01 12:15:00' AS TIMESTAMP));


INSERT INTO Activity (ScheduleID, ActivityName, StartTime, EndTime) VALUES
('A','Meeting',CAST('2021-10-01 10:00:00' AS TIMESTAMP),CAST('2021-10-01 10:30:00' AS TIMESTAMP)),
('A','Break',CAST('2021-10-01 12:00:00' AS TIMESTAMP),CAST('2021-10-01 12:30:00' AS TIMESTAMP)),
('A','Meeting',CAST('2021-10-01 13:00:00' AS TIMESTAMP),CAST('2021-10-01 13:30:00' AS TIMESTAMP)),
('B','Break',CAST('2021-10-01 11:00:00'AS TIMESTAMP),CAST('2021-10-01 11:15:00' AS TIMESTAMP));


--Step 1
SELECT  ScheduleID, StartTime AS ScheduleTime 
INTO    ScheduleTimes
FROM    Schedule
UNION
SELECT  ScheduleID, EndTime FROM Schedule
UNION
SELECT  ScheduleID, StartTime FROM Activity
UNION
SELECT  ScheduleID, EndTime FROM Activity;


--Step 2
SELECT  a.ScheduleID
        ,a.ScheduleTime
        ,COALESCE(b.ActivityName, c.ActivityName, 'Work') AS ActivityName
INTO    ActivityCoalesce
FROM    ScheduleTimes a LEFT OUTER JOIN
        Activity b ON a.ScheduleTime = b.StartTime AND a.ScheduleId = b.ScheduleID LEFT OUTER JOIN
        Activity c ON a.ScheduleTime = c.EndTime AND a.ScheduleId = b.ScheduleID LEFT OUTER JOIN
        Schedule d ON a.ScheduleTime = d.StartTime AND a.ScheduleId = b.ScheduleID LEFT OUTER JOIN
        Schedule e ON a.ScheduleTime = e.EndTime AND a.ScheduleId = b.ScheduleID 
ORDER BY a.ScheduleID, a.ScheduleTime;


--Step 3
WITH cte_Lead AS
(
SELECT  ScheduleID,
        ActivityName,
        ScheduleTime AS StartTime,
        LEAD(ScheduleTime) OVER (PARTITION BY ScheduleID ORDER BY ScheduleTime) AS EndTime
FROM    ActivityCoalesce
)
SELECT  ScheduleID, ActivityName, StartTime, EndTime
FROM    cte_Lead
WHERE   EndTime IS NOT NULL;


/*----------------------------------------------------
Answer to Puzzle #48
Consecutive Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Sales;


CREATE TEMPORARY TABLE Sales
(
SalesID  INTEGER,
"Year"   INTEGER,
PRIMARY KEY (SalesID, "Year")
);


INSERT INTO Sales (SalesID, "Year") VALUES
(1001,2018),(1001,2019),(1001,2020),(2002,2020),(2002,2021),
(3003,2018),(3003,2020),(3003,2021),(4004,2019),(4004,2020),(4004,2021);


--Current Year
WITH cte_Current_Year AS
(
SELECT  SalesID,
        "Year"
FROM    Sales
WHERE   "Year" = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY SalesID, "Year"
)
--Previous Years
,cte_Determine_Lag AS
(
SELECT  a.SalesID,
        b."Year",
        EXTRACT(YEAR FROM CURRENT_DATE) - 2 AS Year_Start
FROM    cte_Current_Year a INNER JOIN
        Sales b ON a.SalesID = b.SalesID
WHERE   b."Year" = EXTRACT(YEAR FROM CURRENT_DATE) - 2
)
SELECT  DISTINCT SalesID
FROM    cte_Determine_Lag;

/*----------------------------------------------------
Answer to Puzzle #49
Sumo Wrestlers
*/----------------------------------------------------

DROP TABLE IF EXISTS ElevatorOrder;


CREATE TEMPORARY TABLE ElevatorOrder
(
LineOrder  INTEGER PRIMARY KEY,
"Name"     VARCHAR(100) NOT NULL,
Weight   INTEGER NOT NULL
);


INSERT INTO ElevatorOrder ("Name", Weight, LineOrder)
VALUES
('Haruto',611,1),('Minato',533,2),('Haruki',623,3),
('Sota',569,4),('Aoto',610,5),('Hinata',525,6);


WITH cte_Running_Total AS
(
SELECT  "Name", Weight, LineOrder,
        SUM(Weight) OVER (ORDER BY LineOrder) AS Running_Total
FROM    ElevatorOrder
)
SELECT  "Name", Weight, LineOrder, Running_Total
FROM    cte_Running_Total
WHERE   Running_Total <= 2000
ORDER BY Running_Total DESC
LIMIT 1;


/*----------------------------------------------------
Answer to Puzzle #50
Baseball Balls and Strikes
*/----------------------------------------------------

DROP TABLE IF EXISTS Pitches;
DROP TABLE IF EXISTS BallsStrikes;
DROP TABLE IF EXISTS BallsStrikesSumWidow;
DROP TABLE IF EXISTS BallsStrikesLag;


CREATE TEMPORARY TABLE Pitches
(
BatterID     INTEGER,
PitchNumber  INTEGER,
"Result"     VARCHAR(100) NOT NULL,
PRIMARY KEY (BatterID, PitchNumber)
);


INSERT INTO Pitches (BatterID, PitchNumber, "Result") VALUES
(1001,1,'Foul'), (1001,2,'Foul'),(1001,3,'Ball'),(1001,4,'Ball'),(1001,5,'Strike'),
(2002,1,'Ball'),(2002,2,'Strike'),(2002,3,'Foul'),(2002,4,'Foul'),(2002,5,'Foul'),
(2002,6,'In Play'),(3003,1,'Ball'),(3003,2,'Ball'),(3003,3,'Ball'),
(3003,4,'Ball'),(4004,1,'Foul'),(4004,2,'Foul'),(4004,3,'Foul'),
(4004,4,'Foul'),(4004,5,'Foul'),(4004,6,'Strike');


SELECT  BatterID,
        PitchNumber,
        "Result",
        (CASE WHEN "Result" = 'Ball' THEN 1 ELSE 0 END) AS Ball,
        (CASE WHEN "Result" IN ('Foul','Strike') THEN 1 ELSE 0 END) AS Strike
INTO    BallsStrikes
FROM    Pitches;


SELECT  BatterID,
        PitchNumber,
        "Result",
        SUM(Ball) OVER (PARTITION BY BatterID ORDER BY PitchNumber) AS SumBall,
        SUM(Strike) OVER (PARTITION BY BatterID ORDER BY PitchNumber) AS SumStrike
INTO    BallsStrikesSumWidow
FROM    BallsStrikes;


SELECT  BatterID,
        PitchNumber,
        "Result",
        SumBall,
        SumStrike,
        LAG(SumBall,1,0) OVER (PARTITION BY BatterID ORDER BY PitchNumber) AS SumBallLag,
        (CASE WHEN "Result" IN ('Foul','In-Play') AND LAG(SumStrike,1,0) OVER (PARTITION BY BatterID ORDER BY PitchNumber) >= 3 THEN 2
              WHEN "Result" = 'Strike' AND SumStrike >= 2 THEN 2
              ELSE LAG(SumStrike,1,0) OVER (PARTITION BY BatterID ORDER BY PitchNumber)
        END) AS SumStrikeLag
INTO    BallsStrikesLag
FROM    BallsStrikesSumWidow;


SELECT  BatterID,
        PitchNumber,
        "Result",
        CONCAT(SumBallLag, ' - ', SumStrikeLag) AS StartOfPitchCount,
        (CASE WHEN "Result" = 'In Play' THEN "Result"
              ELSE CONCAT(SumBall, ' - ', (CASE WHEN "Result" = 'Foul' AND SumStrike >= 3 THEN 2
                                                WHEN "Result" = 'Strike' AND SumStrike >= 2 THEN 3
                                                ELSE SumStrike END))
        END) AS EndOfPitchCount
FROM    BallsStrikesLag
ORDER BY 1,2;


/*----------------------------------------------------
Answer to Puzzle #51
Primary Key Creation
*/----------------------------------------------------

DROP TABLE IF EXISTS Assembly;


CREATE TEMPORARY TABLE Assembly
(
AssemblyID  INTEGER,
Part        VARCHAR(100),
PRIMARY KEY (AssemblyID, Part)
);


INSERT INTO Assembly (AssemblyID, Part) VALUES
(1001,'Bolt'),(1001,'Screw'),(2002,'Nut'),
(2002,'Washer'),(3003,'Toggle'),(3003,'Bolt');

/*
SELECT  HASHBYTES('SHA2_512',CONCAT(AssemblyID, Part)) AS ExampleUniqueID1,
        CHECKSUM(CONCAT(AssemblyID, Part)) AS ExampleUniqueID12,
        AssemblyID,
        Part
FROM    Assembly;
*/

/*----------------------------------------------------
Answer to Puzzle #52
Phone Numbers Table
*/----------------------------------------------------

DROP TABLE IF EXISTS CustomerInfo;


CREATE TEMPORARY TABLE CustomerInfo
(
CustomerID   INTEGER PRIMARY KEY,
PhoneNumber  VARCHAR(14) NOT NULL,
CONSTRAINT ckPhoneNumber CHECK (LENGTH(PhoneNumber) = 14
                            AND SUBSTRING(PhoneNumber,1,1)= '('
                            AND SUBSTRING(PhoneNumber,5,1)= ')'
                            AND SUBSTRING(PhoneNumber,6,1)= '-'
                            AND SUBSTRING(PhoneNumber,10,1)= '-')
);


INSERT INTO CustomerInfo (CustomerID, PhoneNumber) VALUES
(1001,'(555)-555-5555'),(2002,'(555)-555-5555'), (3003,'(555)-555-5555');


SELECT  CustomerID, PhoneNumber
FROM    CustomerInfo;


/*----------------------------------------------------
Answer to Puzzle #53
Spouse IDs
*/----------------------------------------------------

DROP TABLE IF EXISTS Spouses;


CREATE TEMPORARY TABLE Spouses
(
PrimaryID  VARCHAR(100),
SpouseID   VARCHAR(100),
PRIMARY KEY (PrimaryID, SpouseID)
);


INSERT INTO Spouses (PrimaryID, SpouseID) VALUES
('Pat','Charlie'),('Jordan','Casey'),
('Ashley','Dee'),('Charlie','Pat'),
('Casey','Jordan'),('Dee','Ashley');


WITH cte_Reciprocals AS
(
SELECT
        (CASE WHEN PrimaryID < SpouseID THEN PrimaryID ELSE SpouseID END) AS ID1,
        (CASE WHEN PrimaryID > SpouseID THEN PrimaryID ELSE SpouseID END) AS ID2,
        PrimaryID,
        SpouseID
FROM    Spouses
),
cte_DenseRank AS
(
SELECT  DENSE_RANK() OVER (ORDER BY ID1) AS GroupID,
        ID1, ID2, PrimaryID, SpouseID
FROM    cte_Reciprocals
)
SELECT  GroupID,
        b.PrimaryID,
        b.SpouseID
FROM    cte_DenseRank a INNER JOIN
        Spouses b ON a.PrimaryID = b.PrimaryID AND a.SpouseID = b.SpouseID;


/*----------------------------------------------------
Answer to Puzzle #54
Winning Numbers
*/----------------------------------------------------

DROP TABLE IF EXISTS WinningNumbers;
DROP TABLE IF EXISTS LotteryTickets;


CREATE TEMPORARY TABLE WinningNumbers
(
"Number"  INTEGER PRIMARY KEY
);


INSERT INTO WinningNumbers ("Number") VALUES
(25),(45),(78);


CREATE TEMPORARY TABLE LotteryTickets
(
TicketID  VARCHAR(3),
"Number"  INTEGER,
PRIMARY KEY (TicketID, "Number")
);


INSERT INTO LotteryTickets (TicketID, "Number") VALUES
('AAA',25),('AAA',45),('AAA',78),
('BBB',25),('BBB',45),('BBB',98),
('CCC',67),('CCC',86),('CCC',91);


WITH cte_Ticket AS
(
SELECT  TicketID,
        COUNT(*) AS MatchingNumbers
FROM    LotteryTickets a INNER JOIN
        WinningNumbers b ON a."Number" = b."Number"
GROUP BY TicketID
),
cte_Payout AS
(
SELECT  (CASE WHEN MatchingNumbers = (SELECT COUNT(*) FROM WinningNumbers) THEN 100 ELSE 10 END) AS Payout
FROM    cte_Ticket
)
SELECT  SUM(Payout) AS TotalPayout
FROM    cte_Payout;


/*----------------------------------------------------
Answer to Puzzle #55
Table Audit
*/----------------------------------------------------

DROP TABLE IF EXISTS ProductsA;
DROP TABLE IF EXISTS ProductsB;


CREATE TEMPORARY TABLE ProductsA
(
ProductName  VARCHAR(100) PRIMARY KEY,
Quantity     INTEGER NOT NULL
);


CREATE TEMPORARY TABLE ProductsB
(
ProductName  VARCHAR(100) PRIMARY KEY,
Quantity     INTEGER NOT NULL
);


INSERT INTO ProductsA (ProductName, Quantity) VALUES
('Widget',7),
('Doodad',9),
('Gizmo',3);


INSERT INTO ProductsB (ProductName, Quantity) VALUES
('Widget',7),
('Doodad',6),
('Dingbat',9);


WITH cte_FullOuter AS
(
SELECT  a.ProductName AS ProductNameA,
        b.ProductName AS ProductNameB,
        a.Quantity AS QuantityA,
        b.Quantity AS QuantityB
FROM    ProductsA a FULL OUTER JOIN
        ProductsB b ON a.ProductName = b.ProductName
)
SELECT  'Matches in both table A and table B' AS Type,
        ProductNameA
FROM    cte_FullOuter
WHERE   ProductNameA = ProductNameB
UNION
SELECT  'Product does not exist in table B' AS Type,
        ProductNameA
FROM    cte_FullOuter
WHERE   ProductNameB IS NULL
UNION
SELECT  'Product does not exist in table A' AS Type,
        ProductNameB
FROM   cte_FullOuter
WHERE  ProductNameA IS NULL
UNION
SELECT  'Quantities in table A and table B do not match' AS Type,
        ProductNameA
FROM    cte_FullOuter
WHERE   QuantityA <> QuantityB;


/*----------------------------------------------------
Answer to Puzzle #56
Numbers Using Recursion
*/----------------------------------------------------

    WITH RECURSIVE cte_Number AS (
        SELECT 1 AS Number
        UNION ALL
        SELECT Number + 1
        FROM cte_Number
        WHERE Number < 10
    )
    SELECT Number
    FROM cte_Number;

/*----------------------------------------------------
Answer to Puzzle #57
Find The Spaces
*/----------------------------------------------------

DROP TABLE IF EXISTS Strings;


CREATE TEMPORARY TABLE Strings
(
QuoteId  SERIAL PRIMARY KEY,
String   VARCHAR(100) NOT NULL
);


INSERT INTO Strings (String) VALUES
('SELECT EmpID FROM Employees;'),('SELECT * FROM Transactions;');


WITH cte_StringSplit AS (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY s.QuoteId ORDER BY s.QuoteId) AS RowNumber,
        s.QuoteId,
        s.String,
        w.Word,
        LENGTH(w.Word) AS WordLength
    FROM 
        Strings s
    JOIN 
        LATERAL regexp_split_to_table(s.String, E'\\s+') WITH ORDINALITY AS w(Word, Ordinal) 
        ON TRUE
)
SELECT 
    RowNumber,
    QuoteId,
    String,
    POSITION(Word IN String) AS Starts,
    POSITION(Word IN String) + WordLength - 1 AS Ends,
    Word
FROM 
    cte_StringSplit;


/*----------------------------------------------------
Answer to Puzzle #58
Add Them Up
*/----------------------------------------------------

DROP TABLE IF EXISTS Equations;


CREATE TEMPORARY TABLE Equations
(
Equation  VARCHAR(200) PRIMARY KEY,
TotalSum  INT NULL
);


INSERT INTO Equations (Equation) VALUES
('123'),('1+2+3'),('1+2-3'),('1+23'),('1-2+3'),('1-2-3'),('1-23'),('12+3'),('12-3');


--Solution 1
--CURSOR and DYNAMIC SQL
--This solution if you have to multiple and divide
DO $$
DECLARE
    vSQLStatement text;
    vEquation text;
    vSum bigint;
    c_cursor refcursor;
BEGIN
    -- Open a cursor for a query
    OPEN c_cursor FOR SELECT Equation FROM Equations;

    LOOP
        -- Fetch the next row from the cursor
        FETCH c_cursor INTO vEquation;
        EXIT WHEN NOT FOUND;

        -- Prepare and execute the dynamic SQL
        vSQLStatement := 'SELECT ' || vEquation || '::bigint';
        EXECUTE vSQLStatement INTO vSum;

        -- Update the Equations table
        UPDATE Equations
        SET TotalSum = vSum
        WHERE Equation = vEquation;
    END LOOP;

    -- Close and deallocate the cursor
    CLOSE c_cursor;
END $$;

-- Select from Equations table
SELECT  Equation, TotalSum
FROM    Equations;


--Solution 2
--STRING_SPLIT
--This solution will work if you need to only add and subtract.
--Note that STRING_SPLIT does not guarantee order.  Use enable_oridinal if you need to order the output.
--The enable_ordinal argument and ordinal output column are currently supported in Azure SQL Database, Azure SQL Managed Instance, 
--and Azure Synapse Analytics (serverless SQL pool only). Beginning with SQL Server 2022 (16.x), the argument and output column are available in SQL Server.
DO $$
DECLARE
    vSQLStatement text;
    vEquation text;
    vSum bigint;
    c_cursor refcursor;
BEGIN
    -- Open a cursor for a query
    OPEN c_cursor FOR SELECT Equation FROM Equations;

    LOOP
        -- Fetch the next row from the cursor
        FETCH c_cursor INTO vEquation;
        EXIT WHEN NOT FOUND;

        -- Prepare and execute the dynamic SQL
        vSQLStatement := 'SELECT ' || vEquation || '::bigint';
        EXECUTE vSQLStatement INTO vSum;

        -- Update the Equations table
        UPDATE Equations
        SET TotalSum = vSum
        WHERE Equation = vEquation;
    END LOOP;

    -- Close and deallocate the cursor
    CLOSE c_cursor;
END $$;

-- Select from Equations table
SELECT Equation, TotalSum
FROM Equations;


/*----------------------------------------------------
Answer to Puzzle #59
Balanced String
*/----------------------------------------------------

DROP TABLE IF EXISTS BalancedString;


CREATE TEMPORARY TABLE BalancedString
(
RowNumber        SERIAL PRIMARY KEY,
ExpectedOutcome  VARCHAR(50),
MatchString      VARCHAR(50),
UpdateString     VARCHAR(50)
);


INSERT INTO BalancedString (ExpectedOutcome, MatchString) VALUES
('Balanced','( )'),
('Balanced',''),
('Balanced','{}'),
('Balanced','( ( {  } ) )'),
('Balanced','( )  '),
('Balanced','( { } )'),
('Unbalanced','( { ) }'),
('Unbalanced','( { ) }}}()'),
('Unbalanced','}{()');


/*----------------------------------------------------
Answer to Puzzle #60
Products Without Duplicates
*/----------------------------------------------------

DROP TABLE IF EXISTS Products;


CREATE TEMPORARY TABLE Products
(
Product      VARCHAR(10),
ProductCode  VARCHAR(2),
PRIMARY KEY  (Product, ProductCode)
);


INSERT INTO Products (Product, ProductCode) VALUES
('Alpha','01'),
('Alpha','02'),
('Bravo','03'),
('Bravo','04'),
('Charlie','02'),
('Delta','01'),
('Echo','EE'),
('Foxtrot','EE'),
('Gulf','GG');


WITH cte_Duplicates AS
(
SELECT Product
FROM   Products
GROUP BY Product
HAVING COUNT(*) >= 2
),
cte_ProductCodes AS
(
SELECT  ProductCode
FROM    Products
WHERE   Product IN (SELECT Product FROM cte_Duplicates)
)
SELECT  DISTINCT ProductCode
FROM    Products
WHERE   ProductCode NOT IN (SELECT ProductCode FROM cte_ProductCodes);


/*----------------------------------------------------
Answer to Puzzle #61
Player Scores
*/----------------------------------------------------

DROP TABLE IF EXISTS PlayerScores;


CREATE TEMPORARY TABLE PlayerScores
(
AttemptID  INTEGER,
PlayerID   INTEGER,
Score      INTEGER,
PRIMARY KEY (AttemptID, PlayerID)
);


INSERT INTO PlayerScores (AttemptID, PlayerID, Score) VALUES
(1,1001,2),(2,1001,7),(3,1001,8),(1,2002,6),(2,2002,9),(3,2002,7);


WITH cte_FirstLastValues AS
(
SELECT  *
        ,FIRST_VALUE(Score) OVER (PARTITION BY PlayerID ORDER BY AttemptID) AS FirstValue
        ,LAST_VALUE(Score) OVER  (PARTITION BY PlayerID ORDER BY AttemptID
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) LastValue
        ,LAG(Score,1,99999999) OVER (PARTITION BY PlayerID ORDER BY AttemptID) AS LagScore
        ,CASE WHEN Score - LAG(Score,1,0) OVER (PARTITION BY PlayerID ORDER BY AttemptID) > 0 THEN 1 ELSE 0 END AS IsImproved
FROM    PlayerScores
)
SELECT
        AttemptID
       ,PlayerID
       ,Score
       ,Score - FirstValue AS Difference_First
       ,Score - LastValue AS Difference_Last
       ,IsImproved AS IsPreviousScoreLower
       ,MIN(IsImproved) OVER (PARTITION BY PlayerID) AS IsOverallImproved
FROM   cte_FirstLastValues;


/*----------------------------------------------------
Answer to Puzzle #62
Car and Boat Purchase
*/----------------------------------------------------

DROP TABLE IF EXISTS Vehicles;


CREATE TEMPORARY TABLE Vehicles (
VehicleID  INTEGER PRIMARY KEY,
"Type"     VARCHAR(20),
Model      VARCHAR(20),
Price      MONEY
);


INSERT INTO Vehicles (VehicleID, "Type", Model, Price) VALUES
(1, 'Car','Rolls-Royce Phantom', 460000),
(2, 'Car','Cadillac CT5', 39000),
(3, 'Car','Porsche Boxster', 63000),
(4, 'Car','Lamborghini Spyder', 290000),
(5, 'Boat','Malibu', 210000),
(6, 'Boat', 'ATX 22-S', 85000),
(7, 'Boat', 'Sea Ray SLX', 520000),
(8, 'Boat', 'Mastercraft', 25000);


SELECT  a.Model AS Car,
        b.Model AS Boat
FROM    Vehicles a CROSS JOIN
        Vehicles B
WHERE   a."Type" = 'Car' AND
        b."Type" = 'Boat' AND
        a.Price > b.Price + (200000::money)
ORDER BY 1,2;

/*----------------------------------------------------
Answer to Puzzle #63
Promotions
*/----------------------------------------------------

DROP TABLE IF EXISTS Promotions;


CREATE TEMPORARY TABLE Promotions (
OrderID   INTEGER NOT NULL,
Product   VARCHAR(255) NOT NULL,
Discount  VARCHAR(255)
);


INSERT INTO Promotions (OrderID, Product, Discount) VALUES 
(1, 'Item1', 'PROMO'),
(1, 'Item1', 'PROMO'),
(1, 'Item1', 'MARKDOWN'),
(1, 'Item2', 'PROMO'),
(2, 'Item2', NULL),
(2, 'Item3', 'MARKDOWN'),
(2, 'Item3', NULL),
(3, 'Item1', 'PROMO'),
(3, 'Item1', 'PROMO'),
(3, 'Item1', 'PROMO');


SELECT OrderID
FROM   Promotions
WHERE  Discount = ALL(SELECT 'PROMO')
GROUP BY OrderID
HAVING COUNT(DISTINCT Product) = 1;


/*----------------------------------------------------
Answer to Puzzle #64
Between Quotes
*/----------------------------------------------------

DROP TABLE IF EXISTS Strings;


CREATE TEMPORARY TABLE Strings
(
ID      SERIAL PRIMARY KEY,
String  VARCHAR(256) NOT NULL
);


INSERT INTO Strings (String) VALUES
('"12345678901234"'),
('1"2345678901234"'),
('123"45678"901234"'),
('123"45678901234"'),
('12345678901"234"'),
('12345678901234');


--Note that STRING_SPLIT does not guarantee order.  Use enable_oridinal if you need to order the output.
--The enable_ordinal argument and ordinal output column are currently supported in Azure SQL Database, Azure SQL Managed Instance, 
--and Azure Synapse Analytics (serverless SQL pool only). Beginning with SQL Server 2022 (16.x), the argument and output column are available in SQL Server.

--Note that STRING_SPLIT does not guarantee order.  Use enable_oridinal if you need to order the output.
--The enable_ordinal argument and ordinal output column are currently supported in Azure SQL Database, Azure SQL Managed Instance, 
--and Azure Synapse Analytics (serverless SQL pool only). Beginning with SQL Server 2022 (16.x), the argument and output column are available in SQL Server.
WITH cte_Strings AS (
    SELECT 
        ID,
        String,
        CASE 
            WHEN LENGTH(String) - LENGTH(REPLACE(String, '"', '')) <> 2 THEN 'Error' 
        END AS Result
    FROM Strings
),
cte_StringSplit AS (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY s.String ORDER BY current_timestamp) AS RowNumber,
        s.ID,
        s.String,
        s.Result,
        w.Value
    FROM cte_Strings s
    JOIN LATERAL regexp_split_to_table(s.String, '"') WITH ORDINALITY AS w(Value, Ordinal) ON TRUE
)
SELECT 
    ID,
    String,
    CASE 
        WHEN LENGTH(Value) > 10 THEN 'True' 
        ELSE 'False' 
    END AS Result
FROM cte_StringSplit
WHERE Result IS NULL AND RowNumber = 2

UNION

SELECT 
    ID,
    String,
    Result
FROM cte_Strings
WHERE Result = 'Error'
ORDER BY 1;


/*----------------------------------------------------
Answer to Puzzle #65
Home Listings
*/----------------------------------------------------

DROP TABLE IF EXISTS HomeListings;


CREATE TEMPORARY TABLE HomeListings
(
ListingID  INTEGER PRIMARY KEY,
HomeID     VARCHAR(100),
Status     VARCHAR(100)
);


INSERT INTO HomeListings (ListingID, HomeID, Status) VALUES 
(1, 'Home A', 'New Listing'),
(2, 'Home A', 'Pending'),
(3, 'Home A', 'Relisted'),
(4, 'Home B', 'New Listing'),
(5, 'Home B', 'Under Contract'),
(6, 'Home B', 'Relisted'),
(7, 'Home C', 'New Listing'),
(8, 'Home C', 'Under Contract'),
(9, 'Home C', 'Closed');


WITH cte_Case AS
(
SELECT  *,
        (CASE WHEN Status IN ('New Listing', 'Relisted') THEN 1 END) AS IsNewOrRelisted
FROM    HomeListings
)
SELECT  ListingID, HomeID, Status,
        SUM(IsNewOrRelisted) OVER (ORDER BY ListingID) AS GroupingID
FROM    cte_Case;


/*----------------------------------------------------
Answer to Puzzle #66
Matching Parts
*/----------------------------------------------------

DROP TABLE IF EXISTS Parts;


CREATE TEMPORARY TABLE Parts 
(
SerialNumber    VARCHAR(100) PRIMARY KEY,
ManufactureDay  INTEGER,
Product         VARCHAR(100)
);


INSERT INTO Parts (SerialNumber, ManufactureDay, Product) VALUES 
('A111', 1, 'Bolt'),
('B111', 3, 'Bolt'),
('C111', 5, 'Bolt'),
('D222', 2, 'Washer'),
('E222', 4, 'Washer'),
('F222', 6, 'Washer'),
('G333', 3, 'Nut'),
('H333', 5, 'Nut'),
('I333', 7, 'Nut');


WITH cte_RowNumber AS
(
SELECT  ROW_NUMBER() OVER (PARTITION BY Product ORDER BY ManufactureDay) AS RowNumber,
        *
FROM    Parts
)
SELECT  a.SerialNumber AS Bolt,
        b.SerialNumber AS Washer,
        c.SerialNumber AS Nut
FROM    (SELECT * FROM cte_RowNumber WHERE Product = 'Bolt') a INNER JOIN
        (SELECT * FROM cte_RowNumber WHERE Product = 'Washer') b ON a.RowNumber = b.RowNumber INNER JOIN
        (SELECT * FROM cte_RowNumber WHERE Product = 'Nut') c ON a.RowNumber = c.RowNumber;


/*----------------------------------------------------
Answer to Puzzle #67
Matching Birthdays
*/----------------------------------------------------

DROP TABLE IF EXISTS Students;


CREATE TEMPORARY TABLE Students
(
StudentName  VARCHAR(50) PRIMARY KEY,
Birthday     DATE
);


INSERT INTO Students (StudentName, Birthday) VALUES 
('Susan', '2015-04-15'),
('Tim', '2015-04-15'),
('Jacob', '2015-04-15'),
('Earl', '2015-02-05'),
('Mike', '2015-05-23'),
('Angie', '2015-05-23'),
('Jenny', '2015-11-19'),
('Michelle', '2015-12-12'),
('Aaron', '2015-12-18');


SELECT  Birthday, STRING_AGG(StudentName, ', ') AS Students
FROM    Students
GROUP BY Birthday
HAVING  COUNT(*) > 1;


/*----------------------------------------------------
Answer to Puzzle #68
Removing Outliers
*/----------------------------------------------------

DROP TABLE IF EXISTS Teams;


CREATE TEMPORARY TABLE Teams (
Team    VARCHAR(50),
"Year"  INTEGER,
Score   INTEGER,
PRIMARY KEY (Team, "Year")
);


INSERT INTO Teams (Team, "Year", Score) VALUES 
('Cougars', 2015, 50),
('Cougars', 2016, 45),
('Cougars', 2017, 65),
('Cougars', 2018, 92),
('Bulldogs', 2015, 65),
('Bulldogs', 2016, 60),
('Bulldogs', 2017, 58),
('Bulldogs', 2018, 12);


WITH
cte_SummaryStatistics AS
(
SELECT  AVG(Score) OVER (PARTITION BY Team) AS AverageScore
       ,a.*
FROM   Teams a
),
cte_RowNumber AS
(
SELECT  ROW_NUMBER() OVER (PARTITION BY Team ORDER BY ABS(Score - AverageScore) DESC) AS RowNumber,
        *
FROM    cte_SummaryStatistics
)
SELECT Team, AVG(Score) AS Score
FROM   cte_RowNumber
WHERE  RowNumber <> 1
GROUP BY Team;


/*----------------------------------------------------
The End
*/----------------------------------------------------
