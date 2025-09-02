#!/bin/bash

# Database Stack Generator
# Creates database stacks (PostgreSQL, MySQL, Redis, etc.)

create_postgresql_stack() {
    local stack_name="${1:-postgresql}"
    local log_prefix="[POSTGRESQL]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating PostgreSQL stack: $stack_name"
    
    mkdir -p "$stack_name"
    cd "$stack_name"
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: postgres_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d:ro
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=mypassword
    restart: unless-stopped

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    ports:
      - "5050:80"
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=admin123
    depends_on:
      - postgres
    restart: unless-stopped

volumes:
  postgres_data:
  pgadmin_data:
EOF

    mkdir -p init
    cat > init/01-init.sql << EOF
-- Initial database setup
CREATE DATABASE IF NOT EXISTS app_db;
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT ALL PRIVILEGES ON app_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
EOF

    create_db_management_script "postgresql"
    
    echo -e "\033[0;32m${log_prefix}\033[0m PostgreSQL stack created!"
    echo "  PostgreSQL: localhost:5432"
    echo "  pgAdmin: http://localhost:5050 (admin@admin.com/admin123)"
}

create_mysql_stack() {
    local stack_name="${1:-mysql}"
    local log_prefix="[MYSQL]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating MySQL stack: $stack_name"
    
    mkdir -p "$stack_name"
    cd "$stack_name"
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mysql_db
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init:/docker-entrypoint-initdb.d:ro
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=myapp
      - MYSQL_USER=myuser
      - MYSQL_PASSWORD=mypassword
    restart: unless-stopped

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: phpmyadmin
    ports:
      - "8080:80"
    environment:
      - PMA_HOST=mysql
      - PMA_PORT=3306
      - PMA_USER=root
      - PMA_PASSWORD=rootpassword
    depends_on:
      - mysql
    restart: unless-stopped

volumes:
  mysql_data:
EOF

    mkdir -p init
    cat > init/01-init.sql << EOF
-- Initial database setup
CREATE DATABASE IF NOT EXISTS app_db;
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT ALL PRIVILEGES ON app_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
EOF

    create_db_management_script "mysql"
    
    echo -e "\033[0;32m${log_prefix}\033[0m MySQL stack created!"
    echo "  MySQL: localhost:3306"
    echo "  phpMyAdmin: http://localhost:8080"
}

create_redis_stack() {
    local stack_name="${1:-redis}"
    local log_prefix="[REDIS]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating Redis stack: $stack_name"
    
    mkdir -p "$stack_name"
    cd "$stack_name"
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redis_db
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro
    command: redis-server /usr/local/etc/redis/redis.conf
    restart: unless-stopped

  redis-commander:
    image: rediscommander/redis-commander:latest
    container_name: redis_commander
    ports:
      - "8081:8081"
    environment:
      - REDIS_HOSTS=local:redis:6379
    depends_on:
      - redis
    restart: unless-stopped

volumes:
  redis_data:
EOF

    cat > redis.conf << EOF
# Redis configuration
bind 0.0.0.0
port 6379
save 900 1
save 300 10
save 60 10000
rdbcompression yes
dbfilename dump.rdb
dir /data
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

    create_db_management_script "redis"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Redis stack created!"
    echo "  Redis: localhost:6379"
    echo "  Redis Commander: http://localhost:8081"
}

create_db_management_script() {
    local db_type="$1"
    
    cat > manage.sh << EOF
#!/bin/bash
# Database stack management

case "\$1" in
    "start")
        docker compose up -d
        echo "$db_type stack started!"
        ;;
    "stop")
        docker compose down
        ;;
    "restart")
        docker compose restart
        ;;
    "logs")
        docker compose logs -f "\${2:-${db_type}}"
        ;;
    "backup")
        echo "Creating backup..."
        # Add backup logic here
        ;;
    "restore")
        echo "Restoring from backup..."
        # Add restore logic here
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|logs|backup|restore}"
        ;;
esac
EOF

    chmod +x manage.sh
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-postgresql}" in
        "postgresql"|"postgres")
            create_postgresql_stack "$2"
            ;;
        "mysql")
            create_mysql_stack "$2"
            ;;
        "redis")
            create_redis_stack "$2"
            ;;
        *)
            echo "Usage: $0 [postgresql|mysql|redis] [stack_name]"
            exit 1
            ;;
    esac
fi
