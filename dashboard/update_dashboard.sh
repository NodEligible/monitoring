#!/bin/bash

# Оригінальний JSON
INPUT_JSON="settings.json"
# Новий JSON
OUTPUT_JSON="updated_settings.json"

# Оновлюємо JSON, видаляючи старі джерела та додаючи змінні
jq 'walk(
    if type == "object" then
        with_entries(
            if .key == "datasource" then .value = "$\{DS_PROMETHEUS}" else . end
        )
    else
        .
    end
)' "$INPUT_JSON" > "$OUTPUT_JSON"

echo "Оновлений файл збережено як $OUTPUT_JSON"
