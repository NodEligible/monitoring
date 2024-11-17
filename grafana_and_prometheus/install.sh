#!/bin/bash

# Завантаження та вивід лого (опціонально)
curl -s https://raw.githubusercontent.com/NodEligible/programs/refs/heads/main/display_logo.sh | bash

# Колір для повідомлень
YELLOW='\e[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Налаштування портів і версій
PROMETHEUS_VERSION="2.51.1"
GRAFANA_VERSION="10.4.2"
PROMETHEUS_PORT=19980

# Автоматичне отримання IP-адреси сервера
PROMETHEUS_IP=$(hostname -I | awk '{print $1}')
PROMETHEUS_URL="http://${PROMETHEUS_IP}:${PROMETHEUS_PORT}"

echo -e "${YELLOW}Автоматично визначена IP-адреса сервера: ${PROMETHEUS_IP}${NC}"
echo -e "${YELLOW}Prometheus URL: ${PROMETHEUS_URL}${NC}"

# Відкриття портів
echo -e "${YELLOW}Відкриваємо порт ${PROMETHEUS_PORT}...${NC}"
sudo ufw allow ${PROMETHEUS_PORT}/tcp

# Установка Prometheus
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
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:${PROMETHEUS_PORT}"]
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
  --web.listen-address=":${PROMETHEUS_PORT}"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Перевірка статусу Prometheus
if ! systemctl is-active --quiet prometheus; then
  echo -e "${RED}Помилка під час запуску Prometheus! Перевірте логи.${NC}"
  exit 1
fi
echo -e "${GREEN}Prometheus встановлено успішно!${NC}"

# Установка Grafana
echo -e "${YELLOW}Установка Grafana...${NC}"
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common wget curl
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

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

# Завантаження прикладу дашборда
mkdir -p /etc/grafana/dashboards/
curl -o /etc/grafana/dashboards/dashboard.json https://raw.githubusercontent.com/NodEligible/monitoring/refs/heads/main/dashboard/settings.json

# Перезавантаження та запуск Grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Перевірка статусу Grafana
systemctl status grafana-server

echo -e "${GREEN}Grafana успішно встановлено!${NC}"
echo -e "${YELLOW}Перейдіть за адресою: http://${PROMETHEUS_IP}:3000 для доступу до Grafana.${NC}"
echo -e "${YELLOW}Prometheus доступний за адресою: http://${PROMETHEUS_IP}:${PROMETHEUS_PORT}${NC}"
