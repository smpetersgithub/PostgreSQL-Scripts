SELECT  n.nspname AS SchemaName,
        c.relname AS TableName,
        a.attname AS ColumnName,
        pg_catalog.format_type(a.atttypid, a.atttypmod) AS DataType
FROM    pg_catalog.pg_namespace n INNER JOIN 
        pg_catalog.pg_class c ON n.oid = c.relnamespace INNER JOIN 
        pg_catalog.pg_attribute a ON c.oid = a.attrelid
WHERE   a.attnum > 0  AND 
        NOT a.attisdropped AND 
        c.relkind = 'r' -- only include ordinary tables
ORDER BY SchemaName, TableName, ColumnName;
