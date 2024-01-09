-- Check your version
SELECT 
    SERVERPROPERTY('babelfishversion') AS BabelfishVersion, 
    aurora_version() AS AuroraPostgreSQLVersion, 
    @@VERSION AS ClassicSqlServerVersion;
GO

-- Configure Babelfish escape hatches to ignore
EXECUTE sp_babelfish_configure '%', 'ignore', 'server';
GO

-- Create a database
CREATE DATABASE Northwind;
GO

-- Verify the database
SELECT * FROM sys.databases;
GO

-- Check the mapping between Babelfish and PostgreSQL
SELECT 
    pg.dbname AS babelfishDBName,
    be.orig_name AS schemaname,
    pg.nspname AS pgSchemaNameForDMS,
    pg.oid,
    SCHEMA_ID(be.orig_name) AS MapsToPGOID
FROM 
    sys.pg_namespace_ext AS pg 
INNER JOIN 
    sys.babelfish_namespace_ext AS be 
    ON pg.nspname = be.nspname 
WHERE 
    dbname = DB_NAME() 
ORDER BY 
    schemaname;
GO
