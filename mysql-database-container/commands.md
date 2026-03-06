# In order to stop local Windows SQL server:
```powershell
Stop-Service MySQL80
```

# Build with no cache
```bash
docker build -t db-migration-mysql:latest --no-cache .
```

# Run with new volume
```bash
docker run --name db-migration-mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=db_migration_ddbb -e MYSQL_PASSWORD=root -p 3306:3306 -v db-data:/var/lib/mysql -d db-migration-mysql:latest
```

# Eliminar servicio completamente
```bash
docker stop db-migration-mysql
docker rm db-migration-mysql
docker volume rm db-data
```

The container logs should end with

```bash
0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.43'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.
```

In an emergency, execute:

```bash
docker build -t db-migration-mysql:latest --no-cache .
```