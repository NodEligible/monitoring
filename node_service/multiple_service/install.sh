#!/bin/bash

CONFIG_FILE="/etc/multiple-healthcheck.conf"

# Запитуємо у користувача дані
read -p "Enter IDENTIFIER: " IDENTIFIER
read -p "Enter PIN: " PIN

# Зберігаємо дані у файл
echo "IDENTIFIER=$IDENTIFIER" | sudo tee $CONFIG_FILE > /dev/null
echo "PIN=$PIN" | sudo tee -a $CONFIG_FILE > /dev/null

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

