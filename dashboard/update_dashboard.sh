#!/bin/bash

# Змінні
GRAFANA_VERSION="10.4.2"
PROMETHEUS_IP=$(hostname -I | awk '{print $1}')
PROMETHEUS_URL="http://${PROMETHEUS_IP}:19980"
DASHBOARD_ID="11074"
DASHBOARD_JSON_PATH="/etc/grafana/provisioning/dashboards/node-exporter-dashboard.json"

# Встановлення залежностей
apt-get update
apt-get install -y apt-transport-https software-properties-common wget gpg libfontconfig1

# Додавання Grafana репозиторію
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Встановлення Grafana
apt-get update
wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb
dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb

# Налаштування PATH
echo "export PATH=/usr/share/grafana/bin:$PATH" >> /etc/profile

# Створення Data Source для Prometheus
mkdir -p /etc/grafana/provisioning/datasources
cat <<EOF> /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: ${PROMETHEUS_URL}
    isDefault: true
EOF

# Завантаження JSON дашборда
mkdir -p /etc/grafana/provisioning/dashboards
wget -q -O ${DASHBOARD_JSON_PATH} https://grafana.com/api/dashboards/${DASHBOARD_ID}/revisions/1/download

# Додавання конфігурації для дашборда
cat <<EOF> /etc/grafana/provisioning/dashboards/dashboard.yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Запуск Grafana
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# Перевірка статусу
systemctl status grafana-server
