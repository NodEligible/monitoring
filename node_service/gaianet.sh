#!/bin/bash

YELLOW='\e[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[38;5;81m'
NC='\033[0m'

echo -e "${YELLOW}Удаляем сервис если есть...${NC}"
sudo systemctl stop gaianet-monitor &>/dev/null
sudo systemctl disable gaianet-monitor &>/dev/null
systemctl daemon-reload 
rm -rf /root/gaianet_service &>/dev/null
rm -rf /etc/systemd/system/gaianet-monitor.service &>/dev/null

INSTALL_DIR="/root/gaianet_service"
SERVICE_NAME="gaianet-monitor"
LOG_FILE="$INSTALL_DIR/monitor.log"

echo -e "${YELLOW}📁 Создание директории $INSTALL_DIR...${NC}"
mkdir -p "$INSTALL_DIR"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

echo -e "${YELLOW}📝 Создание скрипта мониторинга...${NC}"
cat <<EOF > "$INSTALL_DIR/monitor.sh"
#!/bin/bash

YELLOW='\\e[0;33m'
GREEN='\\033[0;32m'
RED='\\033[0;31m'
BLUE='\\033[38;5;81m'
NC='\\033[0m'

LOG_FILE="/root/gaianet_service/monitor.log"
CHECK_LIST=("wasmedge" "frpc" "gaia-nexus")

while true; do
    restart_needed=false
    for proc in "\${CHECK_LIST[@]}"; do
        if ! pgrep -f "\$proc" > /dev/null; then
            echo -e "\$(date '+%Y-%m-%d %H:%M:%S') ⛔️ \${RED}Процес \$proc не работает.${NC}" | tee -a "\$LOG_FILE"
            restart_needed=true
        fi
    done

    if [ "\$restart_needed" = true ]; then
        echo -e "\$(date '+%Y-%m-%d %H:%M:%S') 🔁 \${BLUE}Перезапуск GaiaNet...${NC}" | tee -a "\$LOG_FILE"
        /root/gaianet/bin/gaianet stop >> "\$LOG_FILE" 2>&1
        sleep 20
        /root/gaianet/bin/gaianet start >> "\$LOG_FILE" 2>&1
        echo -e "\$(date '+%Y-%m-%d %H:%M:%S') ✅ \${GREEN}GaiaNet перезапущен.${NC}" | tee -a "\$LOG_FILE"
    else
        echo -e "\$(date '+%Y-%m-%d %H:%M:%S') ✅ \${GREEN}Все процессы GaiaNet работают.${NC}" | tee -a "\$LOG_FILE"
    fi
    sleep 3m
done
EOF

chmod +x "$INSTALL_DIR/monitor.sh"

echo -e "${YELLOW}📝 Создание systemd-сервісу...${NC}"
cat <<EOF > "/etc/systemd/system/$SERVICE_NAME.service"
[Unit]
Description=Мониторинг GaiaNet Node
After=network.target

[Service]
ExecStart=/bin/bash $INSTALL_DIR/monitor.sh
Restart=always
User=root
StandardOutput=append:$INSTALL_DIR/service.log
StandardError=append:$INSTALL_DIR/service.log

[Install]
WantedBy=multi-user.target
EOF

echo -e "${YELLOW}🔄 Перезапуск systemd...${NC}"
systemctl daemon-reload

echo -e "${YELLOW}🔧 Активация и запуск сервиса...${NC}"
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

echo -e "${GREEN}✅ Watchdog для GaiaNet успешно установлено!${NC}"
