---
name: bx-jdbc
description: Use this skill when selecting and installing JDBC driver modules for BoxLang database connectivity: bx-derby, bx-mysql, bx-mariadb, bx-mssql, bx-postgresql, bx-sqlite, bx-oracle, bx-hypersql. Each module packages the appropriate JDBC driver.
---

# bx-jdbc: JDBC Driver Modules

BoxLang provides separate installable JDBC driver modules — one per database vendor. Install only the driver you need.

## Available JDBC Driver Modules

| Module | Database | Install Command |
|--------|----------|-----------------|
| `bx-derby` | Apache Derby (embedded/server) | `install-bx-module bx-derby` |
| `bx-hypersql` | HyperSQL (in-memory/file) | `install-bx-module bx-hypersql` |
| `bx-mysql` | MySQL 8+ | `install-bx-module bx-mysql` |
| `bx-mariadb` | MariaDB | `install-bx-module bx-mariadb` |
| `bx-mssql` | Microsoft SQL Server | `install-bx-module bx-mssql` |
| `bx-oracle` | Oracle DB | `install-bx-module bx-oracle` |
| `bx-postgresql` | PostgreSQL | `install-bx-module bx-postgresql` |
| `bx-sqlite` | SQLite (embedded file) | `install-bx-module bx-sqlite` |

## Installation

```bash
# OS runtime (global install)
install-bx-module bx-postgresql

# CommandBox / web server project
box install bx-postgresql
```

## Datasource Configuration (boxlang.json)

After installing the JDBC driver module, configure a datasource:

```json
{
  "datasources": {
    "myDB": {
      "driver": "postgresql",
      "host": "localhost",
      "port": 5432,
      "database": "myapp",
      "username": "appuser",
      "password": "secret"
    }
  }
}
```

## Datasource in Application.bx

```javascript
class {
    this.name = "MyApp"

    // Single datasource
    this.datasource = {
        driver   : "mysql",
        host     : "db.example.com",
        port     : 3306,
        database : "myapp",
        username : server.system.environment.DB_USER,
        password : server.system.environment.DB_PASS
    }

    // Named datasources
    this.datasources = {
        primary : {
            driver   : "postgresql",
            host     : "db.example.com",
            port     : 5432,
            database : "maindb",
            username : server.system.environment.PG_USER,
            password : server.system.environment.PG_PASS
        },
        reporting : {
            driver   : "postgresql",
            host     : "read-replica.example.com",
            port     : 5432,
            database : "reportdb",
            username : server.system.environment.PG_USER,
            password : server.system.environment.PG_PASS
        }
    }
}
```

## Querying After Driver is Installed

```javascript
// Default datasource
result = queryExecute( "SELECT * FROM users WHERE active = :active", { active: true } )

// Named datasource
result = queryExecute(
    "SELECT * FROM orders WHERE created_at > :since",
    { since: dateAdd( "d", -7, now() ) },
    { datasource: "reporting" }
)
```

## Driver-Specific Notes

### SQLite (embedded, no server needed)
```json
{
  "datasources": {
    "localDB": {
      "driver": "sqlite",
      "database": "/path/to/myapp.db"
    }
  }
}
```

### Derby (embedded)
```json
{
  "datasources": {
    "testDB": {
      "driver": "derby",
      "database": "/path/to/derby-db",
      "create": true
    }
  }
}
```

## Common Pitfalls

- ❌ Don't hardcode DB credentials — use environment variables (`server.system.environment.MY_VAR`)
- ✅ Install only ONE driver module per database vendor
- ✅ Driver module must match the `driver` key in your datasource config
- ❌ Module `bx-mysql` is for MySQL — use `bx-mariadb` for MariaDB (different driver)
