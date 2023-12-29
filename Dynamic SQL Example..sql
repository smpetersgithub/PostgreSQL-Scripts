
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

