#!/bin/bash
#--------------------------------------------------------------------
# Скрипт для встановлення Grafana Server на Ubuntu (22.04, 24.04) з дашбордом
#--------------------------------------------------------------------

# Версія Grafana
GRAFANA_VERSION="10.4.2"

# Автоматичне отримання IP-адреси сервера
PROMETHEUS_IP=$(hostname -I | awk '{print $1}')
PROMETHEUS_URL="http://${PROMETHEUS_IP}:19980"

echo "Автоматично визначена IP-адреса сервера: $PROMETHEUS_IP"
echo "Prometheus URL: $PROMETHEUS_URL"

# Встановлення необхідних залежностей
apt-get install -y apt-transport-https software-properties-common wget curl
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y adduser libfontconfig1 musl

# Завантаження та встановлення Grafana
wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb
dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb

sudo sed -i 's/;http_port = 3000/http_port = 19970/' /etc/grafana/grafana.ini

# Додавання Grafana до PATH
echo "export PATH=/usr/share/grafana/bin:\$PATH" >> /etc/profile

# Налаштування джерела даних Prometheus
mkdir -p /etc/grafana/provisioning/datasources/
cat <<EOF > /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: ${PROMETHEUS_URL}
EOF

# Налаштування дашборда
mkdir -p /etc/grafana/provisioning/dashboards/
cat <<EOF > /etc/grafana/provisioning/dashboards/dashboard.yaml
apiVersion: 1

providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/dashboards
EOF

# Завантаження дашборда
mkdir -p /etc/grafana/dashboards/
curl -o /etc/grafana/dashboards/dashboard.json https://raw.githubusercontent.com/NodEligible/monitoring/refs/heads/main/dashboard/settings.json

# Перезавантаження та запуск сервісу Grafana
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# Виведення статусу Grafana
systemctl status grafana-server

echo "Grafana встановлено з дашбордом!"
echo "Перейдіть до Grafana, щоб перевірити дашборд за адресою: http://${PROMETHEUS_IP}:19970"
