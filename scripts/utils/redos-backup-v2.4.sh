#!/bin/bash
##############################################################################
# redos-backup-v2.4.sh — Backup tool для РЕД ОС
#
# Возможности:
# - backup пользовательских данных через XDG
# - полный backup HOME
# - проверка свободного места
# - красивый progress rsync
# - безопасная обработка ошибок
# - поддержка русских каталогов
# - логирование
##############################################################################

set -euo pipefail

trap 'echo -e "\n${RED}Ошибка в строке $LINENO${NC}"' ERR

# ─── Цвета ───────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# ─── ЛОГ ─────────────────────────────────────────────────────────────────

LOG_FILE="/tmp/redos-backup.log"

# ─── ИСКЛЮЧЕНИЯ ──────────────────────────────────────────────────────────

EXCLUDES_COMMON=(
    ".cache"
    ".local/share/Trash"
    ".thumbnails"
    ".gvfs"
    ".npm"
    ".cargo"
    ".steam"
    ".var/app"
    "thinclient_drives"
)

EXCLUDES_PRIVATE=(
    ".ssh"
    ".gnupg"
    ".pki"
)

# ─── УТИЛИТЫ ─────────────────────────────────────────────────────────────

read_from_terminal() {
    local prompt="$1"
    local answer

    echo -e "$prompt" >&2

    read -r answer < /dev/tty 2>/dev/null || true

    echo "$answer"
}

confirm() {
    local msg="$1"
    local ans

    ans=$(read_from_terminal "${YELLOW}${msg} (y/n): ${NC}")

    [[ "$ans" =~ ^[Yy]$ ]]
}

human_size() {
    numfmt --to=iec --suffix=B "$1"
}

# ─── XDG ─────────────────────────────────────────────────────────────────

get_xdg_dir() {
    local key="$1"
    local path

    path=$(grep "^${key}=" "$HOME_DIR/.config/user-dirs.dirs" 2>/dev/null \
        | cut -d= -f2 \
        | tr -d '"')

    path=${path/\$HOME/$HOME_DIR}

    if [[ -d "$path" ]]; then
        echo "$path"
    fi
}

get_user_data_dirs() {
    USER_DIRS=()

    local xdg_keys=(
        XDG_DESKTOP_DIR
        XDG_DOCUMENTS_DIR
        XDG_DOWNLOAD_DIR
        XDG_MUSIC_DIR
        XDG_PICTURES_DIR
        XDG_VIDEOS_DIR
    )

    local dir

    for key in "${xdg_keys[@]}"; do
        dir=$(get_xdg_dir "$key")

        if [[ -n "$dir" && -d "$dir" ]]; then
            USER_DIRS+=("$dir")
        fi
    done
}

# ─── ПОЛЬЗОВАТЕЛЬ ────────────────────────────────────────────────────────

select_user() {
    echo -e "${CYAN}Пользователи:${NC}"

    mapfile -t USERS < <(
        awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
    )

    if [[ ${#USERS[@]} -eq 0 ]]; then
        echo -e "${RED}Пользователи не найдены${NC}"
        exit 1
    fi

    for i in "${!USERS[@]}"; do
        echo "$((i + 1))) ${USERS[$i]}"
    done

    local idx

    idx=$(read_from_terminal "Выберите пользователя:")

    USER_SELECTED="${USERS[$((idx - 1))]:-}"

    if [[ -z "$USER_SELECTED" ]]; then
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
    fi

    HOME_DIR=$(eval echo "~$USER_SELECTED")

    if [[ ! -d "$HOME_DIR" ]]; then
        echo -e "${RED}Домашняя директория не найдена${NC}"
        exit 1
    fi

    echo -e "${GREEN}Выбран: $USER_SELECTED${NC}"
}

# ─── РЕЖИМ ───────────────────────────────────────────────────────────────

select_mode() {
    echo "1) Только пользовательские данные"
    echo "2) Полный бэкап HOME"

    MODE=$(read_from_terminal "Выбор:")

    case "$MODE" in
        1|2)
            ;;
        *)
            echo -e "${RED}Неверный режим${NC}"
            exit 1
            ;;
    esac
}

# ─── USB ────────────────────────────────────────────────────────────────

select_usb() {
    echo -e "${CYAN}Поиск USB-накопителей...${NC}"

    mapfile -t MOUNTS < <(
        findmnt -rn -o TARGET | grep -E "^/run/media|^/media" || true
    )

    if [[ ${#MOUNTS[@]} -eq 0 ]]; then
        echo -e "${RED}USB-накопители не найдены${NC}"
        exit 1
    fi

    for i in "${!MOUNTS[@]}"; do
        echo "$((i + 1))) ${MOUNTS[$i]}"
    done

    local idx

    idx=$(read_from_terminal "Выберите диск:")

    DEST_BASE="${MOUNTS[$((idx - 1))]:-}"

    if [[ -z "$DEST_BASE" ]]; then
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
    fi
}

# ─── КАТАЛОГ НАЗНАЧЕНИЯ ─────────────────────────────────────────────────

select_dest() {
    local name

    name=$(read_from_terminal "Имя папки для бэкапа:")

    if [[ -z "$name" ]]; then
        echo -e "${RED}Имя папки не задано${NC}"
        exit 1
    fi

    DEST_DIR="$DEST_BASE/$name"

    mkdir -p "$DEST_DIR"
}

# ─── EXCLUDES ────────────────────────────────────────────────────────────

build_excludes() {
    EXCLUDE_ARGS=()

    for i in "${EXCLUDES_COMMON[@]}"; do
        EXCLUDE_ARGS+=(--exclude="$i")
    done

    if [[ "$MODE" == "1" ]]; then
        for i in "${EXCLUDES_PRIVATE[@]}"; do
            EXCLUDE_ARGS+=(--exclude="$i")
        done
    fi
}

# ─── РАСЧЁТ РАЗМЕРА ─────────────────────────────────────────────────────

calculate_backup_size() {
    local size=0
    local dir
    local dir_size

    if [[ "$MODE" == "1" ]]; then

        get_user_data_dirs

        for dir in "${USER_DIRS[@]}"; do
            dir_size=$(du -sbx "$dir" 2>/dev/null | awk '{print $1}')

            dir_size=${dir_size:-0}

            size=$((size + dir_size))
        done

    else

        size=$(du -sbx \
            --exclude=".cache" \
            --exclude=".local/share/Trash" \
            --exclude="thinclient_drives" \
            "$HOME_DIR" 2>/dev/null | awk '{print $1}')

        size=${size:-0}
    fi

    echo "$size"
}

# ─── ПРОВЕРКА МЕСТА ─────────────────────────────────────────────────────

check_space() {
    echo
    echo -e "${CYAN}Анализ данных...${NC}"

    SIZE=$(calculate_backup_size)

    FREE=$(df --output=avail -B1 "$DEST_BASE" | tail -1)

    echo
    echo -e "${BLUE}Информация о бэкапе:${NC}"
    echo "Размер данных:      $(human_size "$SIZE")"
    echo "Свободно на диске:  $(human_size "$FREE")"
    echo

    if (( FREE < SIZE )); then

        NEED=$((SIZE - FREE))

        echo -e "${RED}Недостаточно места на накопителе${NC}"
        echo
        echo "Не хватает: $(human_size "$NEED")"
        echo
        echo "Рекомендации:"
        echo "• Используйте накопитель большего объёма"
        echo "• Освободите место на текущем диске"
        echo "• Используйте режим 'Только пользовательские данные'"
        echo

        exit 1
    fi

    echo -e "${GREEN}Места достаточно для копирования${NC}"
}

# ─── КОПИРОВАНИЕ ────────────────────────────────────────────────────────

run_backup() {
    echo
    echo -e "${CYAN}Копирование данных...${NC}"
    echo

    set +e

    if [[ "$MODE" == "1" ]]; then

        get_user_data_dirs

        rsync -aL \
            --info=progress2,name0 \
            --stderr=all \
            --no-inc-recursive \
            --human-readable \
            --no-owner \
            --no-group \
            "${USER_DIRS[@]}" \
            "$DEST_DIR/" \
            2>&1 | tee -a "$LOG_FILE"

    else

        build_excludes

        rsync -aL \
            --info=progress2,name0 \
            --stderr=all \
            --no-inc-recursive \
            --human-readable \
            --no-owner \
            --no-group \
            "${EXCLUDE_ARGS[@]}" \
            "$HOME_DIR/" \
            "$DEST_DIR/" \
            2>&1 | tee -a "$LOG_FILE"

    fi

    RSYNC_EXIT=${PIPESTATUS[0]}

    set -e

    echo

    case "$RSYNC_EXIT" in
        0)
            echo -e "${GREEN}✔ Копирование завершено${NC}"
            ;;
        23|24)
            echo -e "${YELLOW}⚠ Копирование завершено с предупреждениями${NC}"
            ;;
        *)
            echo -e "${RED}✖ Ошибка rsync: код $RSYNC_EXIT${NC}"
            exit "$RSYNC_EXIT"
            ;;
    esac
}

# ─── MAIN ────────────────────────────────────────────────────────────────

main() {
    clear

    echo -e "${GREEN}=== REDOS BACKUP v2.4 ===${NC}"

    select_user

    echo

    select_mode

    echo

    select_usb

    echo

    select_dest

    check_space

    echo

    if confirm "Начать копирование?"; then

        run_backup

        echo
        echo -e "${GREEN}✔ Бэкап успешно завершён${NC}"
        echo "Каталог: $DEST_DIR"
        echo "Лог: $LOG_FILE"

    else

        echo
        echo -e "${YELLOW}Операция отменена${NC}"

    fi
}

main "$@"