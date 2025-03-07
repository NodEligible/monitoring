#!/bin/bash

# Відображення логотипу
curl -s https://raw.githubusercontent.com/NodEligible/programs/refs/heads/main/display_logo.sh | bash

# Кольорові змінні
YELLOW='\e[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# URL до бінарного файлу на GitHub
BIN_URL="https://raw.githubusercontent.com/NodEligible/test-gaides/main/container_service/waku-service.bin"

# Місце для завантаження бінарника
BIN_PATH="/tmp/waku-service.bin"

# Завантаження бінарного файлу
echo -e "${YELLOW}📥 Завантаження виконуваного файлу...${NC}"
wget -q -O "$BIN_PATH" "$BIN_URL" || { echo -e "${RED}❌ Помилка завантаження файлу!${NC}"; exit 1; }

# Надання прав на виконання
chmod +x "$BIN_PATH"

# Запуск файлу
echo -e "${YELLOW}🚀 Запуск файлу...${NC}"
"$BIN_PATH"

# Видалення файлу після виконання (опціонально)
rm -f "$BIN_PATH"

echo -e "${GREEN}✅ Виконання завершено!${NC}"
