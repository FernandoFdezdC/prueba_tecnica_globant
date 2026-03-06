# 1. Start from the official MySQL 8.x image
FROM mysql:8.0.43

# 2. Copy our custom configuration
#    MySQL automatically reads files in /etc/mysql/conf.d/
COPY my.cnf /etc/mysql/conf.d/

# 3. Copy SQL or shell scripts for initialization
#    The container executes these files only if the /var/lib/mysql directory is empty
COPY init-db/ /docker-entrypoint-initdb.d/

# 4. Expose the port (optional, usually done in docker run or docker-compose)
EXPOSE 3306

# 5. The CMD command is already defined by the base image as mysqld
#    and it takes standard environment variables into account (no duplication needed)