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

