# Here is a growing list of various features between SQL Server and PostgreSQL.

| Feature | SQL Server | PostgreSQL | Comments |
| ------- | ---------- | ---------- | -------- |
| Table | Yes | Yes | |
| Indexes | Yes | Yes | |
| Triggers | Yes | Yes | |
| Views | Yes | Yes | |
| Updatable Views | Yes | Yes | |
| Materialized Views | Yes | Yes, starting v9.3 | |
| Computed Column | Yes | Yes, available in v12. Use Views for earlier versions | Computed Columns are called Generated Columns in PostgreSQL.  Generated columns must reference a current column in the table. |
| Stored Procedures | Yes | Yes, starting v11 | Prior to PostgreSQL 11, developers used Functions instead of Stored Procedures |
| User Defined Functions | Yes | Yes | |
| Overloaded Functions | No | Yes | PostgreSQL supports overloaded functions |
| Functions | No | Yes | PostgreSQL supports multiple functions with the same name but different parameters. |
| Common Table Expressions (CTE) | Yes | Yes | PostgreSQL 11 and older: CTEs are always materialized and may not perform well. PostgreSQL 12 and later: Query hints allow CTEs to be either materialized or non-materialized. |
| Functional Indexes | No | Yes | |
| Max Table Size | Unlimited | 32 Terabytes (32TB) in PostgreSQL 9.6 and older. 2 Exabytes (2EB) in PostgreSQL 10 and later. | |
| Max Columns per Table | 1024 (non-wide) 30000 (wide) | 250 – 1600 depending on column types | |
| Max Database Size | 524,272 Terabytes | Unlimited | |
| Max Varchar Length | `Varchar(Max)` | `Varchar(10485760)` | Use `text` for longer strings in PostgreSQL |
| Scheduler | SQL Server Agent | pgAgent | |

---------------------------

Here are data type conversions.

**Text**
| Microsoft SQL Server | PostgreSQL | Description |
| -------------------- | ---------- | ----------- |
| CHAR(n) | CHAR(n) | Fixed length char string, 1 <= n <= 8000 |
| VARCHAR(n) | VARCHAR(n) | Variable length char string, 1 <= n <= 8000 |
| VARCHAR(max) | TEXT | Variable length char string, <= 2GB |
| NVARCHAR(n) | VARCHAR(n) | Variable length Unicode UCS-2 string |
| NVARCHAR(max) | TEXT | Variable length Unicode UCS-2 data, <= 2GB |
| TEXT | TEXT | Variable length character data, <= 2GB |
| NTEXT | TEXT | Variable length Unicode UCS-2 data, <= 2GB |
| UNIQUEIDENTIFIER | CHAR(16) | 16 byte GUID(UUID) data |

**Numeric**
| Microsoft SQL Server | PostgreSQL | Description |
| -------------------- | ---------- | ----------- |
| MONEY | MONEY | PostgreSQL requires conversion of integer to money (100::money). |
| BIGINT | BIGINT | 64-bit integer |
| INTEGER | INTEGER | 32 bit integer |
| TINYINT | SMALLINT | 8 bit unsigned integer, 0 to 255 |
| DOUBLE PRECISION | DOUBLE PRECISION | Double precision floating point number |
| FLOAT(p) | DOUBLE PRECISION | Floating point number |
| NUMERIC(p,s) | NUMERIC(p,s) | Fixed point number |
| SMALLMONEY | MONEY | 32 bit currency amount |

**Date**
| Microsoft SQL Server | PostgreSQL | Description |
| -------------------- | ---------- | ----------- |
| DATE | DATE | Date includes year, month, and day |
| DATETIME | TIMESTAMP(3) | Date and Time with fraction |
| DATETIME2(p) | TIMESTAMP(n) | Date and Time with fraction |
| DATETIMEOFFSET(p) | TIMESTAMP(p) WITH TIME ZONE | Date and Time with fraction and time zone |
| SMALLDATETIME | TIMESTAMP(0) | Date and Time |

**Boolean**
| Microsoft SQL Server | PostgreSQL | Description |
| -------------------- | ---------- | ----------- |
| BOOLEAN | BIT | 1, 0 or NULL |

**Binary**
| Microsoft SQL Server | PostgreSQL | Description |
| -------------------- | ---------- | ----------- |
| BINARY(n) | BYTEA | Fixed length byte string |
| VARBINARY(n) | BYTEA | Variable length byte string, 1 <= n <= 8000 |
| VARBINARY(max) | BYTEA | Variable length byte string, <= 2GB |
| ROWVERSION | BYTEA | Automatically updated binary data |
| IMAGE | BYTEA | Variable length binary data, <= 2GB |

---------------------------

Below is a list of common functions that differ in syntax between SQL Server and PostgreSQL.

| Function/Operator | Microsoft SQL Server | PostgreSQL |
| ----------------- | -------------------- | ---------- |
| Extract Part of a Date | DATEPART | DATE_PART |
| Check Null Value | ISNULL | COALESCE |
| Concatenate Spaces | SPACE | REPEAT |
| Add Dates | DATEADD | + |
| String Concatenation | + or CONCAT | Double Pipes or CONCAT |
| Find Position of Character in a String | CHARINDEX | POSITION |
| Get Current Date/Time | GETDATE | NOW |
| Replace Strings | REPLACE | OVERLAY |
| Get String Length | LEN | OCTET_LENGTH |
| AutoIncrement Data Type | INT IDENTITY | SERIAL |
