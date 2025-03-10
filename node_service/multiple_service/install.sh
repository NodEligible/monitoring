#!/bin/bash

curl -s https://raw.githubusercontent.com/NodEligible/programs/refs/heads/main/display_logo.sh | bash

YELLOW='\e[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

CONFIG_FILE="/etc/multiple-healthcheck.conf"

# Запитуємо у користувача дані
echo -e "${YELLOW}Введите IDENTIFIER: ${NC}"
read IDENTIFIER
echo -e "${YELLOW}Введите PIN: ${NC}"
read PIN

# Зберігаємо дані у файл
echo "IDENTIFIER=$IDENTIFIER" | sudo tee $CONFIG_FILE > /dev/null
echo "PIN=$PIN" | sudo tee -a $CONFIG_FILE > /dev/null
if [[ -z "$IDENTIFIER" || -z "$PIN" ]]; then
    echo -e "${RED}❌ Ошибка: IDENTIFIER или PIN не могут быть пустыми!${NC}"
    exit 1
fi

# Дозволяємо читання тільки root
sudo chmod 600 $CONFIG_FILE

# Створюємо systemd-сервіс
SERVICE_FILE="/etc/systemd/system/multiple-healthcheck.service"

echo "[Unit]
Description=Multiple Health Check Service
After=network.target

[Service]
User=$USER
EnvironmentFile=$CONFIG_FILE
ExecStart=/bin/bash -c 'bash <(curl -s https://raw.githubusercontent.com/NodEligible/monitoring/main/node_service/multiple_service/healthcheck.sh) $IDENTIFIER $PIN'
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target" | sudo tee $SERVICE_FILE > /dev/null

# Перезапускаємо systemd, вмикаємо та запускаємо сервіс
sudo systemctl daemon-reload
sudo systemctl enable multiple-healthcheck
sudo systemctl start multiple-healthcheck

echo "Installation complete! Multiple Health Check is now running."

