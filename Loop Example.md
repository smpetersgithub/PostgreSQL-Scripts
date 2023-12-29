Here are some example loops in PostgreSQL.

This solves the traveling salesman problem.

```sql
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
```

The following code uses the for loop statement to iterate over ten numbers from 1 to 10 and display each of them in each iteration:

```sql
do $$
begin
   for cnt in 1..10 loop
    raise notice 'cnt: %', cnt;
   end loop;
end; $$
```

Here is an example of the reverse operator.

```sql
do $$
begin
   for cnt in reverse 10..1 loop
      raise notice 'cnt: %', cnt;
   end loop;
end; $$
```
This iterators over a Customers table.

```sql
do
$$
declare
    f record;
begin
    for f in select employee_id, full_name 
           from employees 
           order by employee_id desc, full_name
           limit 10 
    loop 
    raise notice '% - % ', f.employee_id, f.full_name;
    end loop;
end;
$$;
```

The following code shows how to use the for loop statement to loop through a dynamic query. It has the following two configuration variables:

sort_type: 1 to sort by employee id, 2 to sort by length of name
rec_count: is the number of records to query from the table.

```sql
do $$
declare
    -- sort by 1: employee_id , 2: length of name 
    sort_type smallint := 1; 
    -- return the number of films
    rec_count int := 10;
    -- use to iterate over the film
    rec record;
    -- dynamic query
    query text;
begin
        
    query := 'select full_name, employee_id from employees ';
    
    if sort_type = 1 then
        query := query || 'order by employee_id desc ';
    elsif sort_type = 2 then
      query := query || 'order by length(full_name) desc ';
    else 
       raise 'invalid sort type %s', sort_type;
    end if;

    query := query || ' limit $1';

    for rec in execute query using rec_count
        loop
         raise notice '% - %', rec.employee_id, rec.full_name;
    end loop;
end;
$$
```

