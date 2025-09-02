#!/bin/bash

# Reverse Proxy Stack Generator
# Creates Nginx or Traefik reverse proxy configurations

create_nginx_stack() {
    local stack_name="${1:-nginx-proxy}"
    local log_prefix="[NGINX]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating Nginx reverse proxy stack: $stack_name"
    
    mkdir -p "$stack_name"
    cd "$stack_name"
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx_proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./sites:/etc/nginx/sites-available:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./logs:/var/log/nginx
    restart: unless-stopped

  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - ./ssl:/etc/letsencrypt
      - ./certbot-webroot:/var/www/certbot
    command: certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@example.com --agree-tos --no-eff-email -d example.com

volumes:
  ssl_data:
EOF

    # Create main nginx.conf
    cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Include site configurations
    include /etc/nginx/sites-available/*.conf;
}
EOF

    # Create sites directory and example configuration
    mkdir -p sites
    cat > sites/example.conf << EOF
server {
    listen 80;
    server_name example.com www.example.com;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/example.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Proxy to backend service
    location / {
        proxy_pass http://backend:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}
EOF

    create_proxy_management_script "nginx"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Nginx proxy stack created!"
    echo "  Edit sites/*.conf for your domains"
    echo "  Run: ./manage.sh ssl example.com to get SSL certificate"
}

create_traefik_stack() {
    local stack_name="${1:-traefik-proxy}"
    local log_prefix="[TRAEFIK]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating Traefik reverse proxy stack: $stack_name"
    
    mkdir -p "$stack_name"
    cd "$stack_name"
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/etc/traefik/traefik.yml:ro
      - ./dynamic:/etc/traefik/dynamic:ro
      - ./ssl:/etc/traefik/ssl
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(\`traefik.localhost\`)"
      - "traefik.http.routers.dashboard.service=api@internal"

  # Example backend service
  whoami:
    image: traefik/whoami
    container_name: whoami
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(\`whoami.localhost\`)"
      - "traefik.http.routers.whoami.entrypoints=web"

networks:
  default:
    name: traefik
EOF

    # Create Traefik configuration
    cat > traefik.yml << EOF
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /etc/traefik/ssl/acme.json
      httpChallenge:
        entryPoint: web

# Global redirect to HTTPS
http:
  redirections:
    entryPoint:
      to: websecure
      scheme: https
EOF

    mkdir -p dynamic ssl
    
    create_proxy_management_script "traefik"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Traefik proxy stack created!"
    echo "  Dashboard: http://localhost:8080"
    echo "  Example: http://whoami.localhost"
}

create_proxy_management_script() {
    local proxy_type="$1"
    
    cat > manage.sh << EOF
#!/bin/bash
# Proxy stack management

case "\$1" in
    "start")
        docker compose up -d
        echo "$proxy_type proxy stack started!"
        ;;
    "stop")
        docker compose down
        ;;
    "restart")
        docker compose restart
        ;;
    "logs")
        docker compose logs -f "\${2:-$proxy_type}"
        ;;
    "ssl")
        if [ "$proxy_type" = "nginx" ]; then
            domain="\$2"
            if [ -z "\$domain" ]; then
                echo "Usage: \$0 ssl <domain>"
                exit 1
            fi
            docker compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@\$domain --agree-tos --no-eff-email -d \$domain
        else
            echo "SSL is automatic with Traefik"
        fi
        ;;
    "reload")
        if [ "$proxy_type" = "nginx" ]; then
            docker compose exec nginx nginx -s reload
        else
            echo "Traefik reloads automatically"
        fi
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|logs|ssl|reload}"
        ;;
esac
EOF

    chmod +x manage.sh
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-nginx}" in
        "nginx")
            create_nginx_stack "$2"
            ;;
        "traefik")
            create_traefik_stack "$2"
            ;;
        *)
            echo "Usage: $0 [nginx|traefik] [stack_name]"
            exit 1
            ;;
    esac
fi
