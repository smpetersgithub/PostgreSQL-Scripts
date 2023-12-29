-- Create Routes table and populate it
DROP TABLE IF EXISTS Routes;
CREATE TEMPORARY TABLE Routes (
    RouteID        INTEGER NOT NULL,
    DepartureCity  VARCHAR(30) NOT NULL,
    ArrivalCity    VARCHAR(30) NOT NULL,
    Cost           MONEY NOT NULL,
    PRIMARY KEY (DepartureCity, ArrivalCity)
);
INSERT INTO Routes (RouteID, DepartureCity, ArrivalCity, Cost)
VALUES
(1, 'Austin', 'Dallas', 100),
(2, 'Dallas', 'Memphis', 200),
(3, 'Memphis', 'Des Moines', 300),
(4, 'Dallas', 'Des Moines', 400);

-- Create RoutesList table
DROP TABLE IF EXISTS RoutesList;
CREATE TEMPORARY TABLE RoutesList (
    InsertDate     TIMESTAMP DEFAULT CURRENT_DATE NOT NULL,
    RouteInsertID  INTEGER NOT NULL,
    RoutePath      VARCHAR(8000) NOT NULL,
    TotalCost      MONEY NOT NULL,
    LastArrival    VARCHAR(100)
);

INSERT INTO RoutesList (RouteInsertID, RoutePath, TotalCost, LastArrival)
SELECT  1,
        DepartureCity || ',' || ArrivalCity,
        Cost,
        ArrivalCity
FROM    Routes
WHERE   DepartureCity = 'Austin';


DO $$
DECLARE
    vRowCount INTEGER := 1;
    vRouteInsertID INTEGER := 2;
BEGIN
    LOOP
        -- Insert based on the last arrival
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
            a.TotalCost + b.Cost,
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

-- Select final results
SELECT * FROM RoutesList;
