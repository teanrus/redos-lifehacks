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
PROGRESS_WIDTH=40
RSYNC_LINK_ARGS=()
DU_LINK_ARGS=()

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
    ".config/chromium/Singleton*"
    ".config/google-chrome/Singleton*"
    ".config/yandex-browser*/Singleton*"
    ".pcsc*/pcscd.comm"
    "*.sock"
)

EXCLUDES_PRIVATE=(
    ".ssh"
    ".gnupg"
    ".pki"
)

# ─── УТИЛИТЫ ─────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
REDOS BACKUP v2.4

Утилита резервного копирования для РЕД ОС.

Использование:
  sudo ./redos-backup-v2.4.sh                 # интерактивный режим
  sudo ./redos-backup-v2.4.sh [опции]         # CLI-режим

Основные опции:
  -u, --user USER             Пользователь для резервного копирования
  -m, --mode data|home        data = XDG-каталоги, home = весь HOME
  -d, --dest DIR              Полный каталог назначения
      --usb DIR               Базовый каталог накопителя (/run/media/...)
  -n, --name NAME             Имя папки бэкапа внутри --usb
  -y, --yes                   Не спрашивать подтверждение
      --check                 Только проверить размер и свободное место

Справочные команды:
      --list-users            Показать доступных пользователей
      --list-usb              Показать смонтированные USB/внешние каталоги
  -h, --help                  Показать эту справку

Примеры:
  sudo ./redos-backup-v2.4.sh --user eduadmin --mode data --dest /mnt/backup/eduadmin --yes
  sudo ./redos-backup-v2.4.sh -u eduadmin -m home --usb /run/media/eduadmin/USB -n backup-home -y
  sudo ./redos-backup-v2.4.sh -u eduadmin -m data -d /mnt/backup/eduadmin --check
EOF
}

fail() {
    echo -e "${RED}$1${NC}" >&2
    exit 1
}

check_dependencies() {
    local deps=(
        awk
        cut
        df
        du
        findmnt
        grep
        ln
        numfmt
        rm
        rsync
        tail
        tr
    )
    local missing=()
    local dep

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Не найдены необходимые команды: ${missing[*]}"
    fi
}

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

valid_index() {
    local idx="$1"
    local count="$2"

    [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= count ))
}

draw_progress_bar() {
    local percent="$1"
    local filled
    local empty

    if (( percent < 0 )); then
        percent=0
    elif (( percent > 100 )); then
        percent=100
    fi

    filled=$((percent * PROGRESS_WIDTH / 100))
    empty=$((PROGRESS_WIDTH - filled))

    printf "\r["
    printf '%*s' "$filled" "" | tr ' ' '#'
    printf '%*s' "$empty" ""
    printf "] %3d%%" "$percent"
}

process_rsync_output() {
    local line
    local percent

    while IFS= read -r line; do
        printf '%s\n' "$line" >> "$LOG_FILE"

        if [[ "$line" =~ ([0-9]{1,3})% ]]; then
            percent="${BASH_REMATCH[1]}"
            draw_progress_bar "$percent"
        elif [[ -n "$line" ]]; then
            printf "\n%s\n" "$line"
        fi
    done
}

configure_link_handling() {
    local test_target
    local test_link

    test_target="$DEST_DIR/.redos-backup-link-test-target.$$"
    test_link="$DEST_DIR/.redos-backup-link-test.$$"

    RSYNC_LINK_ARGS=()
    DU_LINK_ARGS=()

    : > "$test_target"

    if ln -s "${test_target##*/}" "$test_link" 2>/dev/null; then
        rm -f -- "$test_link" "$test_target"
        echo -e "${GREEN}Накопитель поддерживает символические ссылки${NC}"
    else
        rm -f -- "$test_link" "$test_target"
        RSYNC_LINK_ARGS=(--copy-links)
        DU_LINK_ARGS=(-L)
        echo -e "${YELLOW}Накопитель не поддерживает символические ссылки${NC}"
        echo "Ссылки будут скопированы как обычные файлы"
    fi
}

# ─── XDG ─────────────────────────────────────────────────────────────────

get_xdg_dir() {
    local key="$1"
    local path

    path=$(grep "^${key}=" "$HOME_DIR/.config/user-dirs.dirs" 2>/dev/null \
        | cut -d= -f2 \
        | tr -d '"' || true)

    path=${path/\$HOME/$HOME_DIR}

    if [[ -d "$path" ]]; then
        echo "$path"
    fi

    return 0
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

    if [[ ${#USER_DIRS[@]} -eq 0 ]]; then
        fail "Пользовательские XDG-каталоги не найдены"
    fi
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

    if ! valid_index "$idx" "${#USERS[@]}"; then
        fail "Неверный выбор"
    fi

    USER_SELECTED="${USERS[$((idx - 1))]}"

    HOME_DIR=$(eval echo "~$USER_SELECTED")

    if [[ ! -d "$HOME_DIR" ]]; then
        fail "Домашняя директория не найдена"
    fi

    echo -e "${GREEN}Выбран: $USER_SELECTED${NC}"
}

list_users() {
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
}

set_user() {
    local user="$1"

    if [[ -z "$user" ]]; then
        fail "Пользователь не задан"
    fi

    if ! awk -F: -v user="$user" '$1 == user && $3 >= 1000 && $1 != "nobody" {found=1} END {exit !found}' /etc/passwd; then
        fail "Пользователь не найден или не является обычным пользователем: $user"
    fi

    USER_SELECTED="$user"
    HOME_DIR=$(eval echo "~$USER_SELECTED")

    if [[ ! -d "$HOME_DIR" ]]; then
        fail "Домашняя директория не найдена: $HOME_DIR"
    fi
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

set_mode() {
    local mode="$1"

    case "$mode" in
        data|user|xdg|1)
            MODE="1"
            ;;
        home|full|2)
            MODE="2"
            ;;
        *)
            fail "Неверный режим: $mode. Используйте data или home"
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

    if ! valid_index "$idx" "${#MOUNTS[@]}"; then
        fail "Неверный выбор"
    fi

    DEST_BASE="${MOUNTS[$((idx - 1))]}"
}

list_usb() {
    findmnt -rn -o TARGET | grep -E "^/run/media|^/media" || true
}

# ─── КАТАЛОГ НАЗНАЧЕНИЯ ─────────────────────────────────────────────────

select_dest() {
    local name

    name=$(read_from_terminal "Имя папки для бэкапа:")

    if [[ -z "$name" ]]; then
        fail "Имя папки не задано"
    fi

    if [[ "$name" == "." || "$name" == ".." || "$name" == *"/"* ]]; then
        fail "Имя папки должно быть простым именем без '/'"
    fi

    DEST_DIR="$DEST_BASE/$name"

    mkdir -p "$DEST_DIR"
}

validate_dest_name() {
    local name="$1"

    if [[ -z "$name" ]]; then
        fail "Имя папки не задано"
    fi

    if [[ "$name" == "." || "$name" == ".." || "$name" == *"/"* ]]; then
        fail "Имя папки должно быть простым именем без '/'"
    fi
}

set_dest_dir() {
    local dest="$1"

    if [[ -z "$dest" ]]; then
        fail "Каталог назначения не задан"
    fi

    DEST_DIR="$dest"

    if [[ "$DEST_DIR" == */* ]]; then
        DEST_BASE="${DEST_DIR%/*}"
        [[ -n "$DEST_BASE" ]] || DEST_BASE="/"
    else
        DEST_BASE="."
    fi

    mkdir -p "$DEST_DIR"
}

set_dest_from_base_and_name() {
    local base="$1"
    local name="$2"

    if [[ -z "$base" ]]; then
        fail "Базовый каталог накопителя не задан"
    fi

    if [[ ! -d "$base" ]]; then
        fail "Базовый каталог не найден: $base"
    fi

    validate_dest_name "$name"

    DEST_BASE="$base"
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
        build_excludes

        for dir in "${USER_DIRS[@]}"; do
            dir_size=$(du -sbx "${DU_LINK_ARGS[@]}" "${EXCLUDE_ARGS[@]}" "$dir" 2>/dev/null | awk '{print $1}' || true)

            dir_size=${dir_size:-0}

            size=$((size + dir_size))
        done

    else

        build_excludes

        size=$(du -sbx \
            "${DU_LINK_ARGS[@]}" \
            "${EXCLUDE_ARGS[@]}" \
            "$HOME_DIR" 2>/dev/null | awk '{print $1}' || true)

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
    : > "$LOG_FILE"

    set +e

    if [[ "$MODE" == "1" ]]; then

        get_user_data_dirs
        build_excludes

        rsync -a \
            "${RSYNC_LINK_ARGS[@]}" \
            --no-devices \
            --no-specials \
            --info=progress2,name0 \
            --stderr=all \
            --no-inc-recursive \
            --human-readable \
            --no-owner \
            --no-group \
            "${EXCLUDE_ARGS[@]}" \
            "${USER_DIRS[@]}" \
            "$DEST_DIR/" \
            2>&1 | tr '\r' '\n' | process_rsync_output
        RSYNC_EXIT=${PIPESTATUS[0]}

    else

        build_excludes

        rsync -a \
            "${RSYNC_LINK_ARGS[@]}" \
            --no-devices \
            --no-specials \
            --info=progress2,name0 \
            --stderr=all \
            --no-inc-recursive \
            --human-readable \
            --no-owner \
            --no-group \
            "${EXCLUDE_ARGS[@]}" \
            "$HOME_DIR/" \
            "$DEST_DIR/" \
            2>&1 | tr '\r' '\n' | process_rsync_output
        RSYNC_EXIT=${PIPESTATUS[0]}

    fi

    set -e

    echo

    case "$RSYNC_EXIT" in
        0)
            BACKUP_RESULT="success"
            echo -e "${GREEN}✔ Копирование завершено${NC}"
            ;;
        23|24)
            BACKUP_RESULT="warning"
            echo -e "${YELLOW}⚠ Копирование завершено с предупреждениями${NC}"
            ;;
        *)
            echo -e "${RED}✖ Ошибка rsync: код $RSYNC_EXIT${NC}"
            exit "$RSYNC_EXIT"
            ;;
    esac
}

# ─── CLI ─────────────────────────────────────────────────────────────────

print_summary() {
    echo
    echo -e "${BLUE}Параметры:${NC}"
    echo "Пользователь: $USER_SELECTED"
    echo "HOME:         $HOME_DIR"
    if [[ "$MODE" == "1" ]]; then
        echo "Режим:        пользовательские данные"
    else
        echo "Режим:        полный HOME"
    fi
    echo "Каталог:      $DEST_DIR"
    echo "Лог:          $LOG_FILE"
}

finish_message() {
    echo
    if [[ "${BACKUP_RESULT:-success}" == "warning" ]]; then
        echo -e "${YELLOW}⚠ Бэкап завершён с предупреждениями${NC}"
    else
        echo -e "${GREEN}✔ Бэкап успешно завершён${NC}"
    fi
    echo "Каталог: $DEST_DIR"
    echo "Лог: $LOG_FILE"
}

run_interactive() {
    clear 2>/dev/null || true

    echo -e "${GREEN}=== REDOS BACKUP v2.4 ===${NC}"

    check_dependencies

    select_user

    echo

    select_mode

    echo

    select_usb

    echo

    select_dest

    configure_link_handling

    check_space

    echo

    if confirm "Начать копирование?"; then
        run_backup
        finish_message
    else
        echo
        echo -e "${YELLOW}Операция отменена${NC}"
    fi
}

run_cli() {
    check_dependencies

    if [[ -z "${CLI_USER:-}" ]]; then
        fail "Не указан пользователь: добавьте --user USER"
    fi

    if [[ -z "${CLI_MODE:-}" ]]; then
        fail "Не указан режим: добавьте --mode data или --mode home"
    fi

    set_user "$CLI_USER"
    set_mode "$CLI_MODE"

    if [[ -n "${CLI_DEST:-}" ]]; then
        set_dest_dir "$CLI_DEST"
    elif [[ -n "${CLI_USB:-}" || -n "${CLI_NAME:-}" ]]; then
        set_dest_from_base_and_name "${CLI_USB:-}" "${CLI_NAME:-}"
    else
        fail "Не указан каталог назначения: добавьте --dest DIR или --usb DIR --name NAME"
    fi

    print_summary
    configure_link_handling
    check_space

    if [[ "${CLI_CHECK_ONLY:-0}" -eq 1 ]]; then
        echo
        echo -e "${GREEN}Проверка завершена, копирование не запускалось${NC}"
        exit 0
    fi

    if [[ "${CLI_YES:-0}" -eq 1 ]] || confirm "Начать копирование?"; then
        run_backup
        finish_message
    else
        echo
        echo -e "${YELLOW}Операция отменена${NC}"
    fi
}

main() {
    if [[ $# -eq 0 ]]; then
        run_interactive
        return
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --list-users)
                list_users
                exit 0
                ;;
            --list-usb)
                list_usb
                exit 0
                ;;
            -u|--user)
                [[ $# -ge 2 ]] || fail "Для $1 нужно указать пользователя"
                CLI_USER="$2"
                shift 2
                ;;
            --user=*)
                CLI_USER="${1#*=}"
                shift
                ;;
            -m|--mode)
                [[ $# -ge 2 ]] || fail "Для $1 нужно указать режим"
                CLI_MODE="$2"
                shift 2
                ;;
            --mode=*)
                CLI_MODE="${1#*=}"
                shift
                ;;
            -d|--dest)
                [[ $# -ge 2 ]] || fail "Для $1 нужно указать каталог"
                CLI_DEST="$2"
                shift 2
                ;;
            --dest=*)
                CLI_DEST="${1#*=}"
                shift
                ;;
            --usb)
                [[ $# -ge 2 ]] || fail "Для $1 нужно указать каталог накопителя"
                CLI_USB="$2"
                shift 2
                ;;
            --usb=*)
                CLI_USB="${1#*=}"
                shift
                ;;
            -n|--name)
                [[ $# -ge 2 ]] || fail "Для $1 нужно указать имя папки"
                CLI_NAME="$2"
                shift 2
                ;;
            --name=*)
                CLI_NAME="${1#*=}"
                shift
                ;;
            -y|--yes)
                CLI_YES=1
                shift
                ;;
            --check)
                CLI_CHECK_ONLY=1
                shift
                ;;
            *)
                usage
                fail "Неизвестный параметр: $1"
                ;;
        esac
    done

    if [[ -n "${CLI_DEST:-}" && ( -n "${CLI_USB:-}" || -n "${CLI_NAME:-}" ) ]]; then
        fail "Используйте либо --dest DIR, либо --usb DIR --name NAME"
    fi

    run_cli
}

main "$@"
