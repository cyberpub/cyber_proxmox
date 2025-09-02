#!/bin/bash

# Monitoring Stack Generator
# Creates Prometheus + Grafana + Node Exporter monitoring stack

create_monitoring_stack() {
    local stack_name="${1:-monitoring}"
    local log_prefix="[MONITORING]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating monitoring stack: $stack_name"
    
    # Create project directory
    mkdir -p "$stack_name"
    cd "$stack_name"
    
    # Create docker-compose.yml
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
EOF

    # Create Prometheus configuration
    cat > prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

    # Create Grafana provisioning directories
    mkdir -p grafana/provisioning/{dashboards,datasources}
    
    # Create Grafana datasource
    cat > grafana/provisioning/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    # Create Grafana dashboard provisioning
    cat > grafana/provisioning/dashboards/dashboard.yml << EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    # Create management script
    cat > manage.sh << 'EOF'
#!/bin/bash
# Monitoring stack management

case "$1" in
    "start")
        docker compose up -d
        echo "Monitoring stack started!"
        echo "Grafana: http://localhost:3000 (admin/admin123)"
        echo "Prometheus: http://localhost:9090"
        echo "Node Exporter: http://localhost:9100"
        echo "cAdvisor: http://localhost:8080"
        ;;
    "stop")
        docker compose down
        ;;
    "restart")
        docker compose restart
        ;;
    "logs")
        docker compose logs -f "${2:-grafana}"
        ;;
    "status")
        docker compose ps
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status}"
        ;;
esac
EOF

    chmod +x manage.sh
    
    echo -e "\033[0;32m${log_prefix}\033[0m Monitoring stack created successfully!"
    echo -e "\033[0;32m${log_prefix}\033[0m Next steps:"
    echo "  1. Run: ./manage.sh start"
    echo "  2. Access Grafana: http://localhost:3000 (admin/admin123)"
    echo "  3. Access Prometheus: http://localhost:9090"
    echo "  4. Import dashboards from grafana.com"
    
    return 0
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_monitoring_stack "$@"
fi
