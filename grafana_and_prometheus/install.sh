#!/bin/bash

curl -s https://raw.githubusercontent.com/NodEligible/programs/refs/heads/main/display_logo.sh | bash

# Color codes for output
YELLOW='\e[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Открываем порты...${NC}"
sudo ufw allow 19970/tcp
sudo ufw allow 19980/tcp
echo -e "${GREEN}Порты открыты!${NC}"

echo -e "${YELLOW}Установка Prometheus...${NC}"
PROMETHEUS_VERSION="2.51.1"
PROMETHEUS_FOLDER_CONFIG="/etc/prometheus"
PROMETHEUS_FOLDER_TSDATA="/etc/prometheus/data"

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar xvfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64

mv prometheus /usr/bin/
rm -rf /tmp/prometheus*

mkdir -p $PROMETHEUS_FOLDER_CONFIG
mkdir -p $PROMETHEUS_FOLDER_TSDATA


cat <<EOF> $PROMETHEUS_FOLDER_CONFIG/prometheus.yml
global:
  scrape_interval: 20s

scrape_configs:
  - job_name      : "prometheus"
    static_configs:
      - targets: ["localhost:19980"]
EOF

useradd -rs /bin/false prometheus
chown prometheus:prometheus /usr/bin/prometheus
chown prometheus:prometheus $PROMETHEUS_FOLDER_CONFIG
chown prometheus:prometheus $PROMETHEUS_FOLDER_CONFIG/prometheus.yml
chown prometheus:prometheus $PROMETHEUS_FOLDER_TSDATA


cat <<EOF> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/bin/prometheus \
  --config.file       ${PROMETHEUS_FOLDER_CONFIG}/prometheus.yml \
  --storage.tsdb.path ${PROMETHEUS_FOLDER_TSDATA} \
  --web.listen-address=":19980"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
systemctl status prometheus --no-pager
prometheus --version
echo -e "${GREEN}Prometheus установлен!${NC}"

echo -e "${YELLOW}Установка Grafana...${NC}"

# Автоматическое получение IP-адреса сервера
PROMETHEUS_IP=$(hostname -I | awk '{print $1}')
PROMETHEUS_URL="http://${PROMETHEUS_IP}:19980"

echo "Автоматически определен IP-адрес сервера: $PROMETHEUS_IP"
echo "Prometheus URL: $PROMETHEUS_URL"

# Установление необходимых зависимостей
apt-get install -y apt-transport-https software-properties-common wget curl
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y adduser libfontconfig1 musl

# Загрузка и установка Grafana
wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb
dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb

# Добавление Grafana в PATH
echo "export PATH=/usr/share/grafana/bin:\$PATH" >> /etc/profile

# Настройка источника данных Prometheus
mkdir -p /etc/grafana/provisioning/datasources/
cat <<EOF > /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: ${PROMETHEUS_URL}
EOF

# Настройка дашборда
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

# Загрузка дашборда
mkdir -p /etc/grafana/dashboards/
curl -o /etc/grafana/dashboards/dashboard.json https://raw.githubusercontent.com/NodEligible/monitoring/refs/heads/main/dashboard/settings.json

# Перезагрузка и запуск Grafana
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# Вывод статуса Grafana
systemctl status grafana-server

echo -e "${GREEN}Grafana установлена ​​с дашбордом!${NC}"
echo -e "${YELLOW}Перейдите к Grafana, чтобы проверить дашборд по адресу: http://${PROMETHEUS_IP}:19970${NC}"
echo -e "${YELLOW}Перейдите к Prometheus, чтобы проверить дашборд по адресу: http://${PROMETHEUS_IP}:19980${NC}"

