#!/bin/bash

# Cloudflared Container Stack Generator
# Creates a Docker-based Cloudflare Tunnel setup

create_cloudflared_stack() {
    local stack_name="${1:-cloudflared}"
    local token="$2"
    local log_prefix="[CLOUDFLARED]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating Cloudflared container stack: $stack_name"
    
    # Validate token parameter
    if [ -z "$token" ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Cloudflare tunnel token is required!"
        echo ""
        echo "Usage: $0 <stack_name> <cloudflare_tunnel_token>"
        echo ""
        echo "To get your token:"
        echo "1. Go to https://one.dash.cloudflare.com/"
        echo "2. Navigate to Zero Trust > Access > Tunnels"
        echo "3. Create a new tunnel or select existing one"
        echo "4. Copy the token from the installation command"
        echo ""
        return 1
    fi
    
    # Create project directory
    mkdir -p "$stack_name"
    cd "$stack_name"
    
    # Create docker-compose.yml
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${token}
    networks:
      - cloudflare
    environment:
      - TUNNEL_TOKEN=${token}
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:8080/ready || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  # Example web service to tunnel
  web-example:
    image: nginx:alpine
    container_name: web-example
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    networks:
      - cloudflare
    depends_on:
      - cloudflared

networks:
  cloudflare:
    driver: bridge
EOF

    # Create example HTML content
    mkdir -p html
    cat > html/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloudflare Tunnel Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .status {
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
        }
        .info {
            background: #d1ecf1;
            border: 1px solid #bee5eb;
            color: #0c5460;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Cloudflare Tunnel Active</h1>
        
        <div class="status">
            ✅ Your Cloudflare Tunnel is working correctly!
        </div>
        
        <div class="info">
            <h3>📊 System Information</h3>
            <p><strong>Server Time:</strong> <span id="time"></span></p>
            <p><strong>User Agent:</strong> <span id="userAgent"></span></p>
            <p><strong>Tunnel Status:</strong> Connected via Cloudflare</p>
        </div>
        
        <h3>🔧 Next Steps</h3>
        <ul>
            <li>Configure your domain in the Cloudflare dashboard</li>
            <li>Set up routing rules for your services</li>
            <li>Add SSL/TLS settings if needed</li>
            <li>Monitor tunnel health and performance</li>
        </ul>
        
        <h3>📚 Useful Links</h3>
        <ul>
            <li><a href="https://one.dash.cloudflare.com/" target="_blank">Cloudflare Dashboard</a></li>
            <li><a href="https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/" target="_blank">Tunnel Documentation</a></li>
        </ul>
    </div>
    
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
        document.getElementById('userAgent').textContent = navigator.userAgent;
    </script>
</body>
</html>
EOF

    # Create environment file template
    cat > .env.example << EOF
# Cloudflare Tunnel Configuration
TUNNEL_TOKEN=your_cloudflare_tunnel_token_here

# Optional: Custom tunnel name
TUNNEL_NAME=my-tunnel

# Optional: Log level (debug, info, warn, error)
LOG_LEVEL=info
EOF

    # Create management script
    cat > manage.sh << 'EOF'
#!/bin/bash
# Cloudflared stack management

case "$1" in
    "start")
        docker compose up -d
        echo "Cloudflared tunnel started!"
        echo "Check status: ./manage.sh status"
        echo "View logs: ./manage.sh logs"
        ;;
    "stop")
        docker compose down
        echo "Cloudflared tunnel stopped!"
        ;;
    "restart")
        docker compose restart
        echo "Cloudflared tunnel restarted!"
        ;;
    "logs")
        docker compose logs -f "${2:-cloudflared}"
        ;;
    "status")
        echo "=== Container Status ==="
        docker compose ps
        echo ""
        echo "=== Cloudflared Health ==="
        docker compose exec cloudflared wget -qO- http://localhost:8080/ready 2>/dev/null && echo "✅ Tunnel is healthy" || echo "❌ Tunnel may have issues"
        echo ""
        echo "=== Recent Logs ==="
        docker compose logs --tail=10 cloudflared
        ;;
    "shell")
        docker compose exec cloudflared sh
        ;;
    "update")
        docker compose pull
        docker compose up -d
        echo "Cloudflared updated to latest version!"
        ;;
    "config")
        echo "=== Current Configuration ==="
        docker compose config
        ;;
    *)
        echo "Cloudflared Stack Management"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|status|shell|update|config}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the Cloudflared tunnel"
        echo "  stop     - Stop the Cloudflared tunnel"
        echo "  restart  - Restart the Cloudflared tunnel"
        echo "  logs     - View tunnel logs (add service name for specific logs)"
        echo "  status   - Show tunnel status and health"
        echo "  shell    - Access Cloudflared container shell"
        echo "  update   - Update to latest Cloudflared version"
        echo "  config   - Show current Docker Compose configuration"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 logs cloudflared"
        echo "  $0 status"
        ;;
esac
EOF

    chmod +x manage.sh
    
    # Create README for the stack
    cat > README.md << EOF
# Cloudflared Docker Stack

This stack provides a containerized Cloudflare Tunnel setup with an example web service.

## Quick Start

1. **Configure your tunnel token:**
   \`\`\`bash
   cp .env.example .env
   # Edit .env and add your TUNNEL_TOKEN
   \`\`\`

2. **Start the stack:**
   \`\`\`bash
   ./manage.sh start
   \`\`\`

3. **Check status:**
   \`\`\`bash
   ./manage.sh status
   \`\`\`

## Services

- **cloudflared**: Cloudflare Tunnel daemon
- **web-example**: Example Nginx service (accessible via tunnel)

## Management Commands

- \`./manage.sh start\` - Start all services
- \`./manage.sh stop\` - Stop all services  
- \`./manage.sh status\` - Check tunnel health
- \`./manage.sh logs\` - View logs
- \`./manage.sh update\` - Update to latest version

## Configuration

Configure your tunnel routing in the Cloudflare dashboard:
https://one.dash.cloudflare.com/

## Troubleshooting

1. **Check tunnel status:** \`./manage.sh status\`
2. **View logs:** \`./manage.sh logs\`
3. **Verify token:** Ensure your TUNNEL_TOKEN is correct
4. **Network issues:** Check Docker network connectivity

## Security Notes

- Keep your tunnel token secure
- Regularly update the Cloudflared image
- Monitor tunnel logs for suspicious activity
- Use Cloudflare Access policies for additional security
EOF

    echo -e "\033[0;32m${log_prefix}\033[0m Cloudflared container stack created successfully!"
    echo -e "\033[0;32m${log_prefix}\033[0m Next steps:"
    echo "  1. Configure your tunnel in Cloudflare dashboard"
    echo "  2. Run: ./manage.sh start"
    echo "  3. Check status: ./manage.sh status"
    echo "  4. View logs: ./manage.sh logs"
    echo "  5. Access example service via your Cloudflare domain"
    
    return 0
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <stack_name> <cloudflare_tunnel_token>"
        echo ""
        echo "Example:"
        echo "  $0 my-tunnel eyJhIjoiYWJjZGVmZ2hpams..."
        echo ""
        echo "To get your token:"
        echo "1. Go to https://one.dash.cloudflare.com/"
        echo "2. Navigate to Zero Trust > Access > Tunnels"
        echo "3. Create a new tunnel or select existing one"
        echo "4. Copy the token from the installation command"
        exit 1
    fi
    
    create_cloudflared_stack "$1" "$2"
fi
