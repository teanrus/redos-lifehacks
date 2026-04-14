#!/bin/bash
##############################################################################
# mount-manager.sh — Управление монтированием сетевых шар (CIFS/SMB)
#
# Автор: pagrishaevich
#
# Описание:
#   Скрипт для управления монтированием пользовательских директорий
#   по протоколу CIFS/SMB. Поддерживает интерактивное меню, командные
#   аргументы, сохранение пресетов и автоматическое добавление в fstab.
#
# Использование:
#   sudo ./mount-manager.sh [ОПЦИИ]
#
# Опции:
#   -h, --help        Справка
#   -l, --list        Список смонтированных шар
#   -a, --add         Добавить новую шару (интерактивно)
#   -r, --remove      Размонтировать шару (интерактивно)
#       --load        Загрузить пресет из конфига
#       --mount-all   Монтировать все шары из fstab
#
# Зависимости: bash, coreutils, mount, cifs-utils (mount.cifs), grep, sed
# Опционально: smbclient (диагностика SMB)
#
# Совместимость: РЕД ОС 7.x ✅, РЕД ОС 8.x ✅
##############################################################################

set -e

# ─── Цвета ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Константы ────────────────────────────────────────────────────────────
MOUNT_BASE="/mnt"
FSTAB="/etc/fstab"
CREDENTIALS_DIR="/root"
CONFIG_FILE="/etc/mount-manager.conf"

# ─── Проверка прав root ──────────────────────────────────────────────────
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Ошибка: скрипт требует прав root${NC}"
        echo "Запустите: sudo $0"
        exit 1
    fi
}

# ─── Проверка зависимостей ───────────────────────────────────────────────
check_dependencies() {
    command -v mount.cifs &>/dev/null || {
        echo -e "${RED}Ошибка: не установлен cifs-utils${NC}"
        echo "Установите: dnf install cifs-utils"
        exit 1
    }

    if ! command -v smbclient &>/dev/null; then
        echo -e "${YELLOW}Предупреждение: smbclient не найден (для диагностики может потребоваться)${NC}"
    fi
}

# ─── Создание файла учётных данных ───────────────────────────────────────
create_credentials_file() {
    local username="$1"
    local password="$2"
    local domain="${3:-}"
    local cred_file="${4:-}"

    if [[ -z "$cred_file" ]]; then
        cred_file="${CREDENTIALS_DIR}/.smbuser_$(echo "$username" | tr '[:upper:]' '[:lower:]')"
    fi

    cat > "$cred_file" <<EOF
username=${username}
password=${password}
EOF

    if [[ -n "$domain" ]]; then
        echo "domain=${domain}" >> "$cred_file"
    fi

    chmod 600 "$cred_file"
    echo "$cred_file"
}

# ─── Монтирование шары ───────────────────────────────────────────────────
mount_share() {
    local server="$1"
    local share="$2"
    local mount_name="$3"
    local cred_file="$4"
    local is_domain="$5"
    local add_to_fstab="$6"

    local mount_point="${MOUNT_BASE}/${mount_name}"
    local extra_opts="nobrl,iocharset=utf8,file_mode=0777,dir_mode=0777"

    if [[ "$is_domain" == "1" ]]; then
        extra_opts="${extra_opts},nofail"
    fi

    mkdir -p "$mount_point"

    local mount_opts="credentials=${cred_file},${extra_opts}"

    echo -e "${BLUE}Монтирование //${server}/${share} -> ${mount_point}${NC}"

    if mount -t cifs "//${server}/${share}" "$mount_point" -o "$mount_opts"; then
        echo -e "${GREEN}Успешно смонтировано: ${mount_point}${NC}"

        if [[ "$add_to_fstab" == "1" ]]; then
            add_to_fstab_entry "$server" "$share" "$mount_name" "$cred_file" "$is_domain"
        fi
    else
        echo -e "${RED}Ошибка монтирования! Проверьте:${NC}"
        echo "  - Доступность сервера: ping ${server}"
        echo "  - Учётные данные в: ${cred_file}"
        echo "  - Сетевое соединение"
        return 1
    fi
}

# ─── Добавление записи в fstab ───────────────────────────────────────────
add_to_fstab_entry() {
    local server="$1"
    local share="$2"
    local mount_name="$3"
    local cred_file="$4"
    local is_domain="$5"

    local mount_point="${MOUNT_BASE}/${mount_name}/"
    local extra_opts="nobrl,iocharset=utf8,file_mode=0777,dir_mode=0777"

    if [[ "$is_domain" == "1" ]]; then
        extra_opts="${extra_opts},nofail"
    fi

    local fstab_entry="//${server}/${share} ${mount_point} cifs credentials=${cred_file},${extra_opts} 0 0"

    if grep -q "^//${server}/${share}" "$FSTAB" 2>/dev/null; then
        echo -e "${YELLOW}Запись уже существует в /etc/fstab${NC}"
        return 0
    fi

    echo "$fstab_entry" >> "$FSTAB"
    echo -e "${GREEN}Запись добавлена в /etc/fstab${NC}"
}

# ─── Размонтирование ─────────────────────────────────────────────────────
unmount_share() {
    local mount_name="$1"
    local mount_point="${MOUNT_BASE}/${mount_name}"

    if [[ ! -d "$mount_point" ]]; then
        echo -e "${RED}Точка монтирования не найдена: ${mount_point}${NC}"
        return 1
    fi

    if ! mountpoint -q "$mount_point"; then
        echo -e "${YELLOW}Не смонтировано: ${mount_point}${NC}"
        read -rp "Удалить директорию ${mount_point}? (y/n): " confirm_rm
        if [[ "$confirm_rm" == "y" || "$confirm_rm" == "Y" ]]; then
            rm -rf "$mount_point"
            echo -e "${GREEN}Директория удалена: ${mount_point}${NC}"
        fi
        return 0
    fi

    echo -e "${BLUE}Размонтирование: ${mount_point}${NC}"

    if umount "$mount_point"; then
        echo -e "${GREEN}Успешно размонтировано: ${mount_point}${NC}"
    else
        echo -e "${RED}Ошибка размонтирования. Попытка принудительного...${NC}"
        umount -l "$mount_point" 2>/dev/null && echo -e "${GREEN}Принудительно размонтировано${NC}" || {
            echo -e "${RED}Не удалось размонтировать${NC}"
            return 1
        }
    fi

    if [[ -d "$mount_point" ]]; then
        rmdir "$mount_point" 2>/dev/null && echo -e "${GREEN}Директория удалена: ${mount_point}${NC}" || {
            echo -e "${YELLOW}Директория не пуста, удаляем принудительно...${NC}"
            rm -rf "$mount_point" && echo -e "${GREEN}Директория удалена: ${mount_point}${NC}" || echo -e "${RED}Не удалось удалить директорию${NC}"
        }
    fi
}

# ─── Список смонтированных шар ────────────────────────────────────────────
list_mounts() {
    echo -e "${BLUE}=== Смонтированные CIFS шары ===${NC}"
    echo ""

    local count=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "type cifs"; then
            echo -e "  ${GREEN}●${NC} $line"
            ((count++)) || true
        fi
    done < <(mount | grep cifs)

    if [[ $count -eq 0 ]]; then
        echo -e "  ${YELLOW}Нет смонтированных CIFS шар${NC}"
    fi

    echo ""
    echo -e "${BLUE}=== Записи из /etc/fstab (CIFS) ===${NC}"
    echo ""

    if [[ -f "$FSTAB" ]]; then
        local fstab_count=0
        while IFS= read -r line; do
            if echo "$line" | grep -q "^//.*cifs"; then
                echo -e "  ${GREEN}●${NC} $line"
                ((fstab_count++)) || true
            fi
        done < "$FSTAB"

        if [[ $fstab_count -eq 0 ]]; then
            echo -e "  ${YELLOW}Нет записей CIFS в /etc/fstab${NC}"
        fi
    else
        echo -e "  ${RED}/etc/fstab не найден${NC}"
    fi

    echo ""
}

# ─── Монтирование всех шар из fstab ──────────────────────────────────────
mount_all_fstab() {
    echo -e "${BLUE}Монтирование всех шар из /etc/fstab...${NC}"
    mount -a -t cifs
    echo -e "${GREEN}Готово${NC}"
}

# ─── Удаление записи из fstab ────────────────────────────────────────────
remove_from_fstab() {
    local mount_name="$1"
    local mount_point="${MOUNT_BASE}/${mount_name}/"

    if [[ ! -f "$FSTAB" ]]; then
        echo -e "${RED}/etc/fstab не найден${NC}"
        return 1
    fi

    if grep -q "${mount_point}" "$FSTAB"; then
        sed -i "\|${mount_point}|d" "$FSTAB"
        echo -e "${GREEN}Запись удалена из /etc/fstab${NC}"
    else
        echo -e "${YELLOW}Запись не найдена в /etc/fstab${NC}"
    fi
}

# ─── Сохранение в конфиг-файл ────────────────────────────────────────────
save_to_config() {
    local name="$1"
    local server="$2"
    local share="$3"
    local username="$4"
    local password="$5"
    local domain="$6"
    local is_domain="$7"

    cat >> "$CONFIG_FILE" <<EOF
[${name}]
server=${server}
share=${share}
username=${username}
password=${password}
domain=${domain}
is_domain=${is_domain}

EOF

    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}Конфигурация сохранена: ${CONFIG_FILE}${NC}"
}

# ─── Загрузка из конфиг-файла ────────────────────────────────────────────
load_from_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}Конфиг-файл не найден: ${CONFIG_FILE}${NC}"
        return 0
    fi

    echo -e "${BLUE}=== Доступные пресеты ===${NC}"
    echo ""

    grep '^\[' "$CONFIG_FILE" | sed 's/\[//;s/\]//' | nl -w2 -s') '
    echo ""

    read -rp "Выберите пресет (номер): " preset_num
    local total
    total=$(grep -c '^\[' "$CONFIG_FILE")

    if [[ "$preset_num" -lt 1 || "$preset_num" -gt "$total" ]]; then
        echo -e "${RED}Неверный номер${NC}"
        return 0
    fi

    local preset_name
    preset_name=$(grep '^\[' "$CONFIG_FILE" | sed -n "${preset_num}p" | sed 's/\[//;s/\]//')

    local in_section=0
    local server="" share="" username="" password="" domain="" is_domain="0"

    while IFS= read -r line; do
        if [[ "$line" == "[${preset_name}]" ]]; then
            in_section=1
            continue
        fi

        if [[ $in_section -eq 1 ]]; then
            if [[ "$line" == "["* ]]; then
                break
            fi

            local key
            key=$(echo "$line" | cut -d'=' -f1)
            local value
            value=$(echo "$line" | cut -d'=' -f2-)

            case "$key" in
                server) server="$value" ;;
                share) share="$value" ;;
                username) username="$value" ;;
                password) password="$value" ;;
                domain) domain="$value" ;;
                is_domain) is_domain="$value" ;;
            esac
        fi
    done < "$CONFIG_FILE"

    if [[ -z "$server" ]]; then
        echo -e "${RED}Не удалось загрузить пресет${NC}"
        return 0
    fi

    echo -e "${GREEN}Загружен пресет: ${preset_name}${NC}"

    local cred_file
    cred_file=$(create_credentials_file "$username" "$password" "$domain")

    read -rp "Смонтировать? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        mount_share "$server" "$share" "$preset_name" "$cred_file" "$is_domain" "1"
    fi
}

# ─── Интерактивный режим — добавление новой шары ─────────────────────────
interactive_add() {
    echo -e "${BLUE}=== Добавление новой шары ===${NC}"
    echo ""

    read -rp "IP/имя сервера: " server
    read -rp "Имя шары: " share
    read -rp "Имя точки монтирования (будет в /mnt/): " mount_name
    read -rp "Имя пользователя: " username
    read -rsp "Пароль: " password
    echo ""
    read -rp "Доменная шара? (y/n): " is_domain_answer

    local is_domain="0"
    local domain=""
    if [[ "$is_domain_answer" == "y" || "$is_domain_answer" == "Y" ]]; then
        is_domain="1"
        read -rp "Домен (необязательно, Enter для пропуска): " domain
    fi

    read -rp "Добавить в /etc/fstab? (y/n): " add_fstab_answer
    local add_to_fstab="0"
    if [[ "$add_fstab_answer" == "y" || "$add_fstab_answer" == "Y" ]]; then
        add_to_fstab="1"
    fi

    read -rp "Сохранить в конфиг-файл? (y/n): " save_config_answer

    local cred_file
    cred_file=$(create_credentials_file "$username" "$password" "$domain")

    mount_share "$server" "$share" "$mount_name" "$cred_file" "$is_domain" "$add_to_fstab"

    if [[ "$save_config_answer" == "y" || "$save_config_answer" == "Y" ]]; then
        save_to_config "$mount_name" "$server" "$share" "$username" "$password" "$domain" "$is_domain"
    fi
}

# ─── Интерактивный режим — удаление шары ─────────────────────────────────
interactive_remove() {
    echo -e "${BLUE}=== Удаление шары ===${NC}"
    echo ""

    local mounts=()
    while IFS= read -r line; do
        if echo "$line" | grep -q "type cifs"; then
            local mp
            mp=$(echo "$line" | awk '{print $3}')
            local name
            name=$(basename "$mp")
            mounts+=("$name")
        fi
    done < <(mount | grep cifs)

    if [[ ${#mounts[@]} -eq 0 ]]; then
        echo -e "${YELLOW}Нет смонтированных шар${NC}"
        return 0
    fi

    echo "Смонтированные шары:"
    for i in "${!mounts[@]}"; do
        echo "  $((i+1))) ${mounts[$i]}"
    done
    echo ""

    read -rp "Выберите для размонтирования (номер): " num
    if [[ $num -ge 1 && $num -le ${#mounts[@]} ]]; then
        local selected="${mounts[$((num-1))]}"

        read -rp "Размонтировать '${selected}'? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            unmount_share "$selected"

            read -rp "Удалить из /etc/fstab? (y/n): " fstab_confirm
            if [[ "$fstab_confirm" == "y" || "$fstab_confirm" == "Y" ]]; then
                remove_from_fstab "$selected"
            fi
        fi
    else
        echo -e "${RED}Неверный номер${NC}"
    fi
}

# ─── Главное меню ─────────────────────────────────────────────────────────
main_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║     Управление монтированием шар         ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Добавить и смонтировать новую шару"
        echo "  2) Загрузить из конфиг-файла"
        echo "  3) Размонтировать шару"
        echo "  4) Список смонтированных"
        echo "  5) Монтировать все из fstab"
        echo "  6) Выход"
        echo ""
        read -rp "Выбор: " choice

        case $choice in
            1) interactive_add ;;
            2) load_from_config ;;
            3) interactive_remove ;;
            4) list_mounts ;;
            5) mount_all_fstab ;;
            6) echo "Выход..."; exit 0 ;;
            *) echo -e "${RED}Неверный выбор${NC}" ;;
        esac
    done
}

# ─── Справка ──────────────────────────────────────────────────────────────
show_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --list, -l      Список смонтированных шар"
    echo "  --add, -a       Добавить новую шару (интерактивно)"
    echo "  --remove, -r    Размонтировать шару (интерактивно)"
    echo "  --load          Загрузить пресет из конфига"
    echo "  --mount-all     Монтировать все шары из fstab"
    echo "  --help, -h      Эта справка"
    echo ""
    echo "Без опций запускается интерактивное меню"
}

# ─── Основная логика ─────────────────────────────────────────────────────
main() {
    check_root
    check_dependencies

    if [[ $# -gt 0 ]]; then
        case "$1" in
            --list|-l)      list_mounts ;;
            --add|-a)       interactive_add ;;
            --remove|-r)    interactive_remove ;;
            --load)         load_from_config ;;
            --mount-all)    mount_all_fstab ;;
            --help|-h)      show_help ;;
            *)
                echo -e "${RED}Неизвестная опция: $1${NC}"
                echo "Используйте --help для справки"
                exit 1
                ;;
        esac
    else
        main_menu
    fi
}

main "$@"
