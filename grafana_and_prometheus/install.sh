#!/bin/bash

curl -s https://raw.githubusercontent.com/NodEligible/programs/refs/heads/main/display_logo.sh | bash

YELLOW='\e[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PROMETHEUS_VERSION="2.51.1"
GRAFANA_VERSION="6.4.3"

PROMETHEUS_IP=$(hostname -I | awk '{print $1}')
PROMETHEUS_URL="http://${PROMETHEUS_IP}:19980"

echo -e "${YELLOW}Автоматически определен IP-адрес сервера: ${PROMETHEUS_IP}${NC}"

echo -e "${YELLOW}Открываем порт 19980${NC}"
sudo ufw allow 19980/tcp

echo -e "${YELLOW}Установка Prometheus...${NC}"
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64

sudo mv prometheus /usr/bin/
sudo mkdir -p /etc/prometheus/data

cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 20s
  
scrape_configs:
  - job_name      : "prometheus"
    static_configs:
      - targets: ["localhost:19980"]

  - job_name      : "NAME"
    scrape_interval: 15s
    static_configs:
      - targets:
          - localhost:9100
        labels:
          instance: '1_server'
      - targets:
          - localhost:9100
        labels:
          instance: '2_server'
      - targets:
          - localhost:9100
        labels:
          instance: '3_server'
      - targets:
          - localhost:9100

EOF

sudo useradd -rs /bin/false prometheus
sudo chown prometheus:prometheus /usr/bin/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus

cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /etc/prometheus/data \
  --web.listen-address=":19980"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

if ! systemctl is-active --quiet prometheus; then
  echo -e "${RED}Ошибка при запуске Prometheus! Проверьте логи.${NC}"
  exit 1
fi
echo -e "${GREEN}Prometheus установлен успешно!${NC}"

echo -e "${YELLOW}Установка Grafana...${NC}"
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common wget curl
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
apt-get install -y adduser libfontconfig1 musl

wget https://dl.grafana.com/oss/release/grafana_6.4.3_amd64.deb
dpkg -i grafana_6.4.3_amd64.deb

mkdir -p /etc/grafana/provisioning/datasources/
cat <<EOF > /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: ${PROMETHEUS_URL}
EOF

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

mkdir -p /etc/grafana/dashboards/
curl -o /etc/grafana/dashboards/dashboard.json https://raw.githubusercontent.com/NodEligible/monitoring/refs/heads/main/dashboard/settings.json

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
rm -rf grafana_6.4.3_amd64.deb

echo -e "${GREEN}Grafana успешно установлена!${NC}"
echo -e "${YELLOW}Grafana доступна по адресу: http://${PROMETHEUS_IP}:3000 Login:admin  Password:admin${NC}"
echo -e "${YELLOW}Prometheus доступен по адресу: http://${PROMETHEUS_IP}:19980/targets?search=${NC}"
