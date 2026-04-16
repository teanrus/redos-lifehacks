#!/usr/bin/env bash
# Скрипт для автоматического обновления CHANGELOG.md
# Поддерживает: Добавлено/Изменено, авто-создание секций, формат redos-lifehacks
set -euo pipefail

CHANGELOG="CHANGELOG.md"
TEMP_FILE="${CHANGELOG}.tmp"

# Извлечение описания из скрипта
get_script_description() {
    local script="$1"
    local desc=""
    
    if [[ -f "$script" ]]; then
        desc=$(grep -m1 "^#[^!]" "$script" 2>/dev/null | sed 's/^#[[:space:]]*//' | cut -c1-80 || echo "")
    fi
    if [[ -z "$desc" ]] && [[ -f "$(dirname "$script")/readme.md" ]]; then
        desc=$(grep -A1 "$(basename "$script")" "$(dirname "$script")/readme.md" 2>/dev/null | grep -v "^\`\`\`" | head -1 | cut -c1-80 || echo "")
    fi
    echo "${desc:-Новый скрипт}" | sed 's/|/\\|/g'
}

# Форматирование строки таблицы (многострочный формат)
format_table_row() {
    local script="$1"
    local desc="$2"
    local filename=$(basename "$script")
    local category=$(echo "$script" | sed -n 's|^scripts/\([^/]*\)/.*|\1|p')
    local doc_path="docs/${category}/$(basename "$script" .sh).md"
    local doc_link="[Открыть]($doc_path)"
    [[ ! -f "$doc_path" ]] && doc_link="—"
    
    cat <<EOF
| $filename
|$desc
|$doc_link
|
EOF
}

# Проверка: есть ли скрипт уже в таблице
script_exists_in_changelog() {
    local filename="$1"
    grep -q "^| $filename$" "$CHANGELOG" 2>/dev/null
}

# Авто-создание секций, если их нет
ensure_sections_exist() {
    local content
    content=$(cat "$CHANGELOG")
    
    # Если нет [Добавлено] после [Unreleased] — добавляем
    if ! echo "$content" | grep -q '^\[Добавлено\]'; then
        content=$(echo "$content" | sed '/^\[Unreleased\]/a\
\
[Добавлено]\
\
[Скрипты]\
\
| Скрипт\
|Описание\
|Документация\
|\
| ---|---|---|')
    fi
    
    # Если нет [Скрипты] внутри [Добавлено]
    if ! echo "$content" | grep -q '^\[Скрипты\]'; then
        content=$(echo "$content" | sed '/^\[Добавлено\]/a\
\
[Скрипты]\
\
| Скрипт\
|Описание\
|Документация\
|\
| ---|---|---|')
    fi
    
    # Если нет заголовка таблицы
    if ! echo "$content" | grep -q '^| ---|---|---|'; then
        content=$(echo "$content" | sed '/^\[Скрипты\]/a\
\
| Скрипт\
|Описание\
|Документация\
|\
| ---|---|---|')
    fi
    
    echo "$content" > "$CHANGELOG"
}

main() {
    local changed_files="${1:-}"
    [[ -z "$changed_files" ]] && { echo "⚠️ Нет списка файлов"; exit 0; }
    
    # Собираем изменённые .sh скрипты
    declare -A new_scripts
    declare -A modified_scripts
    
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        if [[ "$file" =~ ^scripts/.*\.sh$ ]] && [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            if script_exists_in_changelog "$filename"; then
                modified_scripts["$file"]=1
                echo "📝 $filename — изменён (обновим в 'Изменено')"
            else
                new_scripts["$file"]=1
                echo "✨ $filename — новый (добавим в 'Добавлено')"
            fi
        fi
    done <<< "$changed_files"
    
    # Если нет изменений — выходим
    [[ ${#new_scripts[@]} -eq 0 && ${#modified_scripts[@]} -eq 0 ]] && { echo "ℹ️ Нет изменений в скриптах"; exit 0; }
    
    # Гарантируем наличие секций
    ensure_sections_exist
    
    echo "🔄 Обновляем CHANGELOG.md..."
    
    # Генерируем записи для "Добавлено"
    local new_entries=""
    for script in "${!new_scripts[@]}"; do
        local desc=$(get_script_description "$script")
        new_entries+="$(format_table_row "$script" "$desc")"$'\n'
    done
    
    # Генерируем записи для "Изменено"
    local modified_entries=""
    for script in "${!modified_scripts[@]}"; do
        local desc=$(get_script_description "$script")
        modified_entries+="$(format_table_row "$script" "$desc")"$'\n'
    done
    
    # Обновление файла через awk
    awk -v new="$new_entries" -v modified="$modified_entries" '
    BEGIN { 
        in_unreleased=0
        in_added=0
        in_changed=0
        in_scripts_added=0
        in_scripts_changed=0
        inserted_added=0
        inserted_changed=0
    }
    
    # Начало [Unreleased]
    /^\[Unreleased\]/ { 
        in_unreleased=1
        in_added=0; in_changed=0
        in_scripts_added=0; in_scripts_changed=0
        print; next 
    }
    
    # Конец [Unreleased]
    /^\[v[0-9]/ { 
        # Вставляем непрописанное перед переходом к версии
        if (in_unreleased && in_scripts_added && !inserted_added && new != "") {
            printf "%s", new; inserted_added=1
        }
        if (in_unreleased && in_scripts_changed && !inserted_changed && modified != "") {
            printf "%s", modified; inserted_changed=1
        }
        in_unreleased=0; in_added=0; in_changed=0
        print; next 
    }
    
    # Секция [Добавлено]
    in_unreleased && /^\[Добавлено\]/ { 
        in_added=1; in_changed=0
        in_scripts_added=0; in_scripts_changed=0
        print; next 
    }
    
    # Секция [Изменено] — создаём если есть модификации и секции нет
    in_unreleased && /^\[Изменено\]/ { 
        in_changed=1; in_added=0
        in_scripts_changed=0
        print; next 
    }
    
    # [Скрипты] внутри [Добавлено]
    in_added && /^\[Скрипты\]/ { 
        in_scripts_added=1
        print; next 
    }
    
    # [Скрипты] внутри [Изменено]
    in_changed && /^\[Скрипты\]/ { 
        in_scripts_changed=1
        print; next 
    }
    
    # Заголовок таблицы в "Добавлено" → вставляем новые записи после него
    in_scripts_added && /^\| ---\|---\|---\|/ && !inserted_added && new != "" { 
        print
        printf "%s", new
        inserted_added=1
        next 
    }
    
    # Заголовок таблицы в "Изменено" → вставляем изменённые записи после него
    in_scripts_changed && /^\| ---\|---\|---\|/ && !inserted_changed && modified != "" { 
        print
        printf "%s", modified
        inserted_changed=1
        next 
    }
    
    # Если встретили новую секцию — сбрасываем флаги
    /^\[/ && !/^\|/ { 
        if (in_scripts_added) in_scripts_added=0
        if (in_scripts_changed) in_scripts_changed=0
    }
    
    # Обычная печать
    { print }
    
    END {
        # Крайний случай: если не вставили — добавляем в конец [Unreleased]
        if (!inserted_added && new != "") {
            # Проверяем, есть ли секция [Добавлено]
            if (in_unreleased) {
                printf "\n[Добавлено]\n[Скрипты]\n| Скрипт\n|Описание\n|Документация\n|\n| ---|---|---|\n%s", new
            }
        }
        if (!inserted_changed && modified != "") {
            if (in_unreleased) {
                printf "\n[Изменено]\n[Скрипты]\n| Скрипт\n|Описание\n|Документация\n|\n| ---|---|---|\n%s", modified
            }
        }
    }
    ' "$CHANGELOG" > "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$CHANGELOG"
    echo "✅ CHANGELOG.md обновлён"
}

main "$@"