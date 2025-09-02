#!/bin/bash

# Django Stack Generator
# Creates a complete Django development environment with Docker Compose

create_django_stack() {
    local project_name="${1:-django-app}"
    local db_type="${2:-postgresql}"
    local log_prefix="[DJANGO-STACK]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating Django stack: $project_name"
    
    # Create project directory
    mkdir -p "$project_name"
    cd "$project_name"
    
    # Create docker-compose.yml
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis
    environment:
      - DEBUG=1
      - DATABASE_URL=${db_type}://django:django@db:5432/django_db
      - REDIS_URL=redis://redis:6379/0

  db:
    image: ${db_type}:15
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_DB=django_db
      - POSTGRES_USER=django
      - POSTGRES_PASSWORD=django
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./static:/var/www/static:ro
    depends_on:
      - web

volumes:
  postgres_data:
EOF

    # Create Dockerfile
    cat > Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /code

# Install system dependencies
RUN apt-get update \\
    && apt-get install -y --no-install-recommends \\
        postgresql-client \\
        build-essential \\
        libpq-dev \\
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /code/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /code/

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EOF

    # Create requirements.txt
    cat > requirements.txt << EOF
Django>=4.2,<5.0
psycopg2-binary>=2.9
redis>=4.5
celery>=5.3
django-environ>=0.10
gunicorn>=21.0
whitenoise>=6.5
EOF

    # Create nginx.conf
    cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream web {
        server web:8000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://web;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /static/ {
            alias /var/www/static/;
        }
    }
}
EOF

    # Create .env template
    cat > .env.example << EOF
DEBUG=1
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://django:django@db:5432/django_db
REDIS_URL=redis://redis:6379/0
ALLOWED_HOSTS=localhost,127.0.0.1
EOF

    # Create management scripts
    cat > manage.sh << 'EOF'
#!/bin/bash
# Django management helper

case "$1" in
    "start")
        docker compose up -d
        ;;
    "stop")
        docker compose down
        ;;
    "restart")
        docker compose restart
        ;;
    "logs")
        docker compose logs -f "${2:-web}"
        ;;
    "shell")
        docker compose exec web python manage.py shell
        ;;
    "migrate")
        docker compose exec web python manage.py migrate
        ;;
    "makemigrations")
        docker compose exec web python manage.py makemigrations
        ;;
    "collectstatic")
        docker compose exec web python manage.py collectstatic --noinput
        ;;
    "createsuperuser")
        docker compose exec web python manage.py createsuperuser
        ;;
    "test")
        docker compose exec web python manage.py test
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|shell|migrate|makemigrations|collectstatic|createsuperuser|test}"
        ;;
esac
EOF

    chmod +x manage.sh
    
    echo -e "\033[0;32m${log_prefix}\033[0m Django stack created successfully!"
    echo -e "\033[0;32m${log_prefix}\033[0m Next steps:"
    echo "  1. Copy .env.example to .env and configure"
    echo "  2. Run: ./manage.sh start"
    echo "  3. Create Django project: docker compose exec web django-admin startproject myproject ."
    echo "  4. Run migrations: ./manage.sh migrate"
    echo "  5. Create superuser: ./manage.sh createsuperuser"
    
    return 0
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_django_stack "$@"
fi
