#!/bin/bash
# Скрипт поиска и удаления сохранённых паролей сетевых ресурсов на РЕД ОС
# Сканирует все возможные хранилища учётных данных и предлагает удалить в интерактивном режиме
# Версия 2.0 - Расширенная с поддержкой KDE Wallet, Autofs, Systemd и пакетным режимом

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Счётчики
FOUND_COUNT=0
DELETED_COUNT=0
FAILED_COUNT=0

# Массивы для хранения найденных записей
declare -a ENTRY_SOURCES=()
declare -a ENTRY_LABELS=()
declare -a ENTRY_KEYS=()
declare -a ENTRY_SERVERS=()
declare -a ENTRY_URIS=()
declare -a ENTRY_PATHS=()

# Режимы работы
MODE="interactive" # interactive, scan-only, batch-delete, export
EXPORT_FILE=""

# ============================================
# Утилиты
# ============================================

# Функция для безопасного чтения ввода из терминала
read_from_terminal() {
    local prompt=$1
    local answer
    echo -e "$prompt" >&2
    read -r answer < /dev/tty 2>/dev/null || true
    echo "$answer"
}

# Функция для запроса подтверждения
confirm_action() {
    local message=$1
    local answer

    answer=$(read_from_terminal "${YELLOW}$message (y/n)${NC}")
    if [[ $answer =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Функция вывода заголовка
print_header() {
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${GREEN}  Управление паролями сетевых ресурсов (РЕД ОС)${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo ""
}

# Функция вывода ошибки
print_error() {
    echo -e "${RED}Ошибка: $1${NC}" >&2
}

# Функция вывода информации
print_info() {
    echo -e "${CYAN}$1${NC}"
}

# Функция вывода предупреждения
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Добавление записи в список
add_entry() {
    local source=$1
    local label=$2
    local key=$3
    local server=${4:-""}
    local uri=${5:-""}
    local path=${6:-""}

    ENTRY_SOURCES+=("$source")
    ENTRY_LABELS+=("$label")
    ENTRY_KEYS+=("$key")
    ENTRY_SERVERS+=("$server")
    ENTRY_URIS+=("$uri")
    ENTRY_PATHS+=("$path")
    FOUND_COUNT=$((FOUND_COUNT + 1))
}

# ============================================
# Сканирование хранилищ
# ============================================

# 1. GNOME Keyring через secret-tool
scan_gnome_keyring() {
    if ! command -v secret-tool &>/dev/null; then
        return
    fi

    # Ищем SMB/CIFS записи
    local smb_entries
    smb_entries=$(secret-tool search --all smb 2>/dev/null || true)

    if [ -n "$smb_entries" ]; then
        local current_label=""
        local current_server=""
        local current_user=""
        local current_path=""

        while IFS= read -r line; do
            if [[ "$line" =~ ^\[(.+)\]$ ]]; then
                # Новый блок — сохраняем предыдущий
                if [ -n "$current_server" ]; then
                    local label="${current_label:-SMB}"
                    [ -n "$current_path" ] && label="$label/$current_path"
                    [ -n "$current_user" ] && label="$label ($current_user)"
                    add_entry "GNOME Keyring" "$label" "smb:$current_server" "$current_server" "smb://$current_server" ""
                fi
                current_label="${BASH_REMATCH[1]}"
                current_server=""
                current_user=""
                current_path=""
            elif [[ "$line" =~ ^server=\ *(.+)$ ]]; then
                current_server="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^username=\ *(.+)$ ]]; then
                current_user="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^path=\ *(.+)$ ]]; then
                current_path="${BASH_REMATCH[1]}"
            fi
        done <<< "$smb_entries"

        # Сохраняем последнюю запись
        if [ -n "$current_server" ]; then
            local label="${current_label:-SMB}"
            [ -n "$current_path" ] && label="$label/$current_path"
            [ -n "$current_user" ] && label="$label ($current_user)"
            add_entry "GNOME Keyring" "$label" "smb:$current_server" "$current_server" "smb://$current_server" ""
        fi
    fi

    # Ищем записи по ключевым словам (cifs, network, share)
    for search_term in "cifs" "network" "share"; do
        local entries
        entries=$(secret-tool search --all "$search_term" 2>/dev/null | grep -iE "smb|cifs|10\.|192\.168\." || true)
        if [ -n "$entries" ]; then
            add_entry "GNOME Keyring" "Сетевые ресурсы ($search_term)" "network:$search_term" "" "" ""
        fi
    done
}

# 2. Файлы учётных данных Samba
scan_samba_credentials() {
    # Проверяем ~/.smbcredentials
    if [ -f "$HOME/.smbcredentials" ]; then
        local server="unknown"
        if grep -q "server" "$HOME/.smbcredentials" 2>/dev/null; then
            server=$(grep "server" "$HOME/.smbcredentials" | head -1 | cut -d'=' -f2)
        fi
        add_entry "Файл ~/.smbcredentials" "Учётные данные SMB" "file:$HOME/.smbcredentials" "$server" "" "$HOME/.smbcredentials"
    fi

    # Проверяем /etc/samba/
    if [ -d "/etc/samba" ]; then
        local cred_files
        cred_files=$(find /etc/samba -name "*cred*" -o -name "*pass*" -o -name "*auth*" 2>/dev/null || true)

        if [ -n "$cred_files" ]; then
            while IFS= read -r file; do
                [ -f "$file" ] || continue
                add_entry "Файл Samba" "$(basename $file)" "file:$file" "" "" "$file"
            done <<< "$cred_files"
        fi
    fi

    # Проверяем /etc/fstab на наличие учётных данных
    if [ -f "/etc/fstab" ]; then
        local fstab_entries
        fstab_entries=$(grep -E "//.*smb|//.*cifs|username=|credentials=" /etc/fstab 2>/dev/null || true)
        if [ -n "$fstab_entries" ]; then
            while IFS= read -r line; do
                local mount_point=""
                local server=""
                server=$(echo "$line" | grep -oP '//\K[^/\s]+' || echo "unknown")
                mount_point=$(echo "$line" | awk '{print $2}')
                add_entry "/etc/fstab" "Сетевое монтирование: $server" "fstab:$server" "$server" "smb://$server" "$mount_point"
            done <<< "$fstab_entries"
        fi
    fi
}

# 3. Кэш Samba
scan_samba_cache() {
    if [ -d "/var/cache/samba" ]; then
        local cache_files
        cache_files=$(find /var/cache/samba -type f 2>/dev/null | head -5 || true)

        if [ -n "$cache_files" ]; then
            add_entry "Кэш Samba" "Файлы кэша (/var/cache/samba)" "cache:/var/cache/samba" "" "" "/var/cache/samba"
        fi
    fi

    if [ -d "$HOME/.cache/samba" ]; then
        local cache_files
        cache_files=$(find "$HOME/.cache/samba" -type f 2>/dev/null | head -5 || true)
        if [ -n "$cache_files" ]; then
            add_entry "Кэш Samba (пользователь)" "Файлы кэша (~/.cache/samba)" "cache:$HOME/.cache/samba" "" "" "$HOME/.cache/samba"
        fi
    fi
}

# 4. Файлы ~/.netrc
scan_netrc() {
    if [ -f "$HOME/.netrc" ]; then
        local machines
        machines=$(grep "^machine" "$HOME/.netrc" 2>/dev/null | awk '{print $2}' || true)

        if [ -n "$machines" ]; then
            while IFS= read -r machine; do
                [ -n "$machine" ] || continue
                add_entry "Файл ~/.netrc" "Сервер: $machine" "netrc:$machine" "$machine" "" "$HOME/.netrc"
            done <<< "$machines"
        fi
    fi
}

# 5. Файлы ~/.config/gvfs/
scan_gvfs() {
    if [ -d "$HOME/.config/gvfs" ] || [ -d "$HOME/.gvfs" ]; then
        add_entry "GVFS" "Смонтированные сетевые ресурсы" "gvfs:mounted" "" "smb://" ""
    fi
}

# 6. Файлы ~/.local/share/gvfs-metadata/
scan_gvfs_metadata() {
    if [ -d "$HOME/.local/share/gvfs-metadata" ]; then
        local metadata_files
        metadata_files=$(ls "$HOME/.local/share/gvfs-metadata/" 2>/dev/null || true)

        if [ -n "$metadata_files" ]; then
            add_entry "GVFS Metadata" "Метаданные сетевых ресурсов" "gvfs:metadata" "" "" "$HOME/.local/share/gvfs-metadata"
        fi
    fi
}

# 7. Файлы ~/.smb/
scan_smb_config() {
    if [ -d "$HOME/.smb" ]; then
        if [ -f "$HOME/.smb/smb.conf" ]; then
            add_entry "Конфиг Samba (~/.smb)" "Пользовательская конфигурация" "smbconf:$HOME/.smb/smb.conf" "" "" "$HOME/.smb/smb.conf"
        fi
    fi
}

# 8. KDE Wallet (новый)
scan_kde_wallet() {
    # Проверяем наличие kwalletcli или kwalletmanager5
    if ! command -v kwalletcli &>/dev/null && ! command -v kwalletmanager5 &>/dev/null; then
        return
    fi

    # Проверяем наличие файлов KDE Wallet
    local wallet_files=("$HOME/.local/share/kwalletd" "$HOME/.kde/share/apps/kwalletd" "$HOME/.local/share/kwallet")
    
    for wallet_dir in "${wallet_files[@]}"; do
        if [ -d "$wallet_dir" ]; then
            local wallet_files_found
            wallet_files_found=$(find "$wallet_dir" -name "*.kwl" -o -name "*.xml" 2>/dev/null | head -5 || true)
            if [ -n "$wallet_files_found" ]; then
                add_entry "KDE Wallet" "Кошелёк KDE ($wallet_dir)" "kdewallet:$wallet_dir" "" "" "$wallet_dir"
                return
            fi
        fi
    done

    # Проверяем через qdbus (если KDE Wallet запущен)
    if command -v qdbus &>/dev/null; then
        local wallets
        wallets=$(qdbus org.kde.kwalletd5 /modules/kwalletd5 org.kde.KWallet.wallets 2>/dev/null || true)
        if [ -n "$wallets" ]; then
            while IFS= read -r wallet; do
                [ -n "$wallet" ] || continue
                add_entry "KDE Wallet (активный)" "Кошелёк: $wallet" "kdewallet:active:$wallet" "" "" ""
            done <<< "$wallets"
        fi
    fi
}

# 9. Autofs (новый)
scan_autofs() {
    # Проверяем наличие autofs
    if ! command -v automount &>/dev/null && [ ! -f "/etc/auto.master" ]; then
        return
    fi

    # Проверяем /etc/auto.master
    if [ -f "/etc/auto.master" ]; then
        local auto_maps
        auto_maps=$(grep -v "^#" /etc/auto.master | grep -v "^$" | awk '{print $2}' || true)
        
        if [ -n "$auto_maps" ]; then
            while IFS= read -r map_file; do
                [ -f "$map_file" ] || continue
                local smb_entries
                smb_entries=$(grep -E "smb|cifs|//|fstype=cifs" "$map_file" 2>/dev/null || true)
                if [ -n "$smb_entries" ]; then
                    while IFS= read -r entry; do
                        local mount_name=""
                        local server=""
                        mount_name=$(echo "$entry" | awk '{print $1}')
                        server=$(echo "$entry" | grep -oP '://\K[^:/\s]+' || echo "unknown")
                        add_entry "Autofs" "Авто-монтирование: $mount_name" "autofs:$map_file:$mount_name" "$server" "smb://$server" "$map_file"
                    done <<< "$smb_entries"
                fi
            done <<< "$auto_maps"
        fi
    fi

    # Проверяем службу autofs
    if systemctl is-active --quiet autofs 2>/dev/null; then
        add_entry "Autofs (служба)" "Служба autofs активна" "autofs:service" "" "" ""
    fi
}

# 10. Systemd mount units (новый)
scan_systemd_mounts() {
    # Ищем .mount юниты для SMB/CIFS
    local mount_units
    mount_units=$(systemctl list-units --type=mount --all 2>/dev/null | grep -iE "smb|cifs|network" || true)

    if [ -n "$mount_units" ]; then
        while IFS= read -r line; do
            local unit_name=""
            unit_name=$(echo "$line" | awk '{print $1}')
            [ -n "$unit_name" ] || continue
            
            # Получаем информацию о юните
            local mount_point=""
            local what=""
            mount_point=$(systemctl show "$unit_name" --property=Where 2>/dev/null | cut -d'=' -f2)
            what=$(systemctl show "$unit_name" --property=What 2>/dev/null | cut -d'=' -f2)
            
            if [[ "$what" == *"//"* ]] || [[ "$what" == *"smb"* ]] || [[ "$what" == *"cifs"* ]]; then
                local server=""
                server=$(echo "$what" | grep -oP '//\K[^/\s]+' || echo "unknown")
                add_entry "Systemd mount" "Юнит: $unit_name" "systemd:$unit_name" "$server" "$what" "$mount_point"
            fi
        done <<< "$mount_units"
    fi

    # Ищем файлы .mount в /etc/systemd/system/
    if [ -d "/etc/systemd/system" ]; then
        local mount_files
        mount_files=$(find /etc/systemd/system -name "*.mount" 2>/dev/null || true)
        
        if [ -n "$mount_files" ]; then
            while IFS= read -r file; do
                [ -f "$file" ] || continue
                if grep -qE "cifs|smb|//" "$file" 2>/dev/null; then
                    local unit_name=""
                    unit_name=$(basename "$file")
                    add_entry "Systemd mount (файл)" "Файл: $unit_name" "systemd:file:$file" "" "" "$file"
                fi
            done <<< "$mount_files"
        fi
    fi
}

# 11. Активные GVFS монтирования (расширенный)
scan_gvfs_active() {
    if ! command -v gio &>/dev/null; then
        return
    fi

    local mounts
    mounts=$(gio mount --list 2>/dev/null | grep -E "smb://|cifs://|ftp://|dav://" || true)

    if [ -n "$mounts" ]; then
        while IFS= read -r mount; do
            local uri=""
            uri=$(echo "$mount" | awk '{print $NF}')
            local server=""
            server=$(echo "$uri" | grep -oP '(smb|cifs|ftp|dav)://\K[^:/\s]+' || echo "unknown")
            add_entry "GVFS (активный)" "Активное подключение: $uri" "gvfs:active:$uri" "$server" "$uri" ""
        done <<< "$mounts"
    fi
}

# 12. Файлы ~/.config/dconf/ ( GNOME настройки)
scan_dconf() {
    if [ -f "$HOME/.config/dconf/user" ] && command -v dconf &>/dev/null; then
        local smb_paths
        smb_paths=$(dconf dump / 2>/dev/null | grep -iE "smb://|cifs://|last-servers" || true)
        
        if [ -n "$smb_paths" ]; then
            add_entry "Dconf (GNOME)" "Настройки GNOME (последние серверы)" "dconf:last-servers" "" "" "$HOME/.config/dconf/user"
        fi
    fi
}

# ============================================
# Удаление записей
# ============================================

# Удаление записи GNOME Keyring
delete_gnome_keyring_entry() {
    local key=$1
    local server=$2

    if [[ "$key" == smb:* ]]; then
        server="${server:-${key#smb:}}"
        if secret-tool clear server "$server" 2>/dev/null; then
            return 0
        fi
        return 1
    elif [[ "$key" == network:* ]]; then
        print_info "Для удаления общих записей используйте: seahorse (графический интерфейс)"
        print_info "Или выполните: secret-tool search --all <термин> | grep -A10 '<метка>'"
        return 1
    fi
}

# Удаление файла учётных данных
delete_credentials_file() {
    local filepath=$1

    if [ -f "$filepath" ]; then
        if rm -f "$filepath"; then
            return 0
        fi
    fi
    return 1
}

# Очистка кэша Samba
clear_samba_cache() {
    local path=$1

    if [ -d "$path" ]; then
        if rm -rf "${path:?}"/*; then
            return 0
        fi
    fi
    return 1
}

# Удаление записи из ~/.netrc
delete_netrc_entry() {
    local machine=$1
    local netrc_file="$HOME/.netrc"

    if [ -f "$netrc_file" ]; then
        # Проверяем, есть ли такая машина
        if grep -q "^machine $machine" "$netrc_file" 2>/dev/null; then
            # Удаляем блок machine (machine + login + password)
            sed -i "/^machine $machine/,+2d" "$netrc_file"
            return $?
        fi
    fi
    return 1
}

# Отмонтирование GVFS
unmount_gvfs() {
    local uri=$1

    if command -v gio &>/dev/null; then
        if [ -n "$uri" ]; then
            # Отмонтируем конкретный URI
            if gio mount -u "$uri" 2>/dev/null; then
                return 0
            fi
        else
            # Отмонтируем все SMB ресурсы
            local mounts
            mounts=$(gio mount --list 2>/dev/null | grep -E "smb://|cifs://" | awk '{print $NF}' || true)
            if [ -n "$mounts" ]; then
                local all_success=true
                while IFS= read -r mount_uri; do
                    if ! gio mount -u "$mount_uri" 2>/dev/null; then
                        all_success=false
                    fi
                done <<< "$mounts"
                if $all_success; then
                    return 0
                fi
            fi
        fi
        return 1
    fi
    return 1
}

# Удаление KDE Wallet записей
delete_kde_wallet_entry() {
    local key=$1

    if [[ "$key" == kdewallet:* ]]; then
        if [[ "$key" == kdewallet:active:* ]]; then
            print_info "Для удаления из KDE Wallet используйте kwalletmanager5"
            print_info "Запустите: kwalletmanager5, найдите SMB-записи и удалите их"
            return 1
        else
            local wallet_path="${key#kdewallet:}"
            print_warning "Файлы KDE Wallet: $wallet_path"
            if confirm_action "Удалить файлы кошелька KDE?"; then
                if [ -d "$wallet_path" ]; then
                    rm -rf "${wallet_path:?}"
                    return $?
                fi
            fi
            return 1
        fi
    fi
    return 1
}

# Управление Autofs
manage_autofs() {
    local key=$1

    if [[ "$key" == autofs:* ]]; then
        if [[ "$key" == autofs:service ]]; then
            print_info "Для отключения autofs выполните: sudo systemctl stop autofs"
            if confirm_action "Остановить службу autofs?"; then
                if sudo systemctl stop autofs 2>/dev/null; then
                    return 0
                fi
            fi
            return 1
        else
            # Формат: autofs:map_file:mount_name
            local map_file=""
            map_file=$(echo "$key" | cut -d: -f2)
            if [ -f "$map_file" ]; then
                print_info "Отредактируйте файл: $map_file"
                print_info "Удалите или закомментируйте строки с SMB-ресурсами"
                return 1
            fi
        fi
    fi
    return 1
}

# Управление Systemd mount
manage_systemd_mount() {
    local key=$1

    if [[ "$key" == systemd:* ]]; then
        local unit_name=""
        unit_name=$(echo "$key" | cut -d: -f2)
        
        print_info "Unit: $unit_name"
        
        if confirm_action "Остановить и отключить юнит?"; then
            sudo systemctl stop "$unit_name" 2>/dev/null || true
            sudo systemctl disable "$unit_name" 2>/dev/null || true
            
            if [[ "$key" == systemd:file:* ]]; then
                local file_path=""
                file_path=$(echo "$key" | cut -d: -f3-)
                if [ -f "$file_path" ] && confirm_action "Удалить файл юнита?"; then
                    sudo rm -f "$file_path"
                    sudo systemctl daemon-reload
                    return $?
                fi
            fi
            return 0
        fi
        return 1
    fi
    return 1
}

# Удаление записи fstab (только рекомендация)
manage_fstab_entry() {
    local server=$1
    local mount_point=$2

    print_info "Для удаления записи из /etc/fstab:"
    print_info "  1. Откройте файл: sudo nano /etc/fstab"
    print_info "  2. Найдите строку с сервером: $server"
    print_info "  3. Удалите или закомментируйте строку"
    print_info "  4. Выполните: sudo mount -a"
    
    if [ -n "$mount_point" ] && mount | grep -q "$mount_point" 2>/dev/null; then
        if confirm_action "Отмонтировать $mount_point сейчас?"; then
            sudo umount "$mount_point" 2>/dev/null || true
        fi
    fi
    return 1
}

# Выполнение удаления
perform_deletion() {
    local index=$1
    local source="${ENTRY_SOURCES[$index]}"
    local key="${ENTRY_KEYS[$index]}"
    local server="${ENTRY_SERVERS[$index]}"
    local uri="${ENTRY_URIS[$index]}"
    local path="${ENTRY_PATHS[$index]}"

    case "$source" in
        "GNOME Keyring")
            delete_gnome_keyring_entry "$key" "$server"
            ;;
        "Файл ~/.smbcredentials")
            delete_credentials_file "$HOME/.smbcredentials"
            ;;
        "Файл Samba")
            delete_credentials_file "$path"
            ;;
        "/etc/fstab")
            manage_fstab_entry "$server" "$path"
            ;;
        "Кэш Samba"|"Кэш Samba (пользователь)")
            clear_samba_cache "$path"
            ;;
        "Файл ~/.netrc")
            delete_netrc_entry "$server"
            ;;
        "GVFS"|"GVFS (активный)")
            unmount_gvfs "$uri"
            ;;
        "GVFS Metadata")
            rm -rf "${HOME:?}/.local/share/gvfs-metadata/"*
            ;;
        "Конфиг Samba (~/.smb)")
            delete_credentials_file "$path"
            ;;
        "KDE Wallet"|"KDE Wallet (активный)")
            delete_kde_wallet_entry "$key"
            ;;
        "Autofs"|"Autofs (служба)")
            manage_autofs "$key"
            ;;
        "Systemd mount"|"Systemd mount (файл)")
            manage_systemd_mount "$key"
            ;;
        "Dconf (GNOME)")
            print_info "Настройки GNOME хранятся в dconf. Для сброса:"
            print_info "  dconf reset -f /org/gnome/shell/"
            return 1
            ;;
        *)
            print_error "Неизвестный источник: $source"
            return 1
            ;;
    esac
}

# ============================================
# Проверка после удаления
# ============================================

# Проверка, что записи удалены
verify_deletion() {
    local index=$1
    local source="${ENTRY_SOURCES[$index]}"
    local key="${ENTRY_KEYS[$index]}"
    local server="${ENTRY_SERVERS[$index]}"

    echo -e "\n${CYAN}Проверка удаления:${NC}"

    case "$source" in
        "GNOME Keyring")
            if [[ "$key" == smb:* ]] && command -v secret-tool &>/dev/null; then
                local remaining
                remaining=$(secret-tool search server "$server" 2>/dev/null || true)
                if [ -z "$remaining" ]; then
                    echo -e "${GREEN}✓ Запись удалена из GNOME Keyring${NC}"
                else
                    echo -e "${YELLOW}⚠ Запись всё ещё присутствует в GNOME Keyring${NC}"
                fi
            fi
            ;;
        "GVFS"|"GVFS (активный)")
            if command -v gio &>/dev/null; then
                local mounts
                mounts=$(gio mount --list 2>/dev/null | grep -c "smb://" || echo "0")
                echo -e "${GREEN}✓ Активных SMB монтирований: $mounts${NC}"
            fi
            ;;
    esac
}

# ============================================
# Интерактивный режим
# ============================================

# Отображение всех найденных записей
display_entries() {
    echo ""
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${GREEN}  Найдено сохранённых записей: $FOUND_COUNT${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo ""

    if [ $FOUND_COUNT -eq 0 ]; then
        echo -e "${YELLOW}  Сохранённые учётные данные не обнаружены${NC}"
        echo ""
        return
    fi

    for i in "${!ENTRY_LABELS[@]}"; do
        local num=$((i+1))
        echo -e "${CYAN}  [$num]${NC} ${ENTRY_LABELS[$i]}"
        echo -e "      ${YELLOW}Источник:${NC} ${ENTRY_SOURCES[$i]}"
        [ -n "${ENTRY_SERVERS[$i]}" ] && echo -e "      ${YELLOW}Сервер:${NC} ${ENTRY_SERVERS[$i]}"
        [ -n "${ENTRY_URIS[$i]}" ] && echo -e "      ${YELLOW}URI:${NC} ${ENTRY_URIS[$i]}"
        echo -e "      ${YELLOW}Ключ:${NC} ${ENTRY_KEYS[$i]}"
        echo ""
    done
}

# Интерактивное удаление
interactive_delete() {
    if [ $FOUND_COUNT -eq 0 ]; then
        return
    fi

    while true; do
        local choice
        choice=$(read_from_terminal "${BLUE}Введите номер записи для удаления (или 'q' для выхода, 'a' для удаления всех):${NC} ")

        if [[ "$choice" == "q" ]] || [[ "$choice" == "Q" ]]; then
            echo ""
            echo -e "${GREEN}Завершение работы.${NC}"
            break
        fi

        # Удаление всех записей
        if [[ "$choice" == "a" ]] || [[ "$choice" == "A" ]]; then
            if confirm_action "Удалить ВСЕ $FOUND_COUNT записей?"; then
                delete_all_entries
                break
            fi
            continue
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$FOUND_COUNT" ]; then
            local idx=$((choice-1))
            echo ""
            echo -e "${MAGENTA}Удаление записи: ${ENTRY_LABELS[$idx]}${NC}"
            echo -e "${YELLOW}Источник: ${ENTRY_SOURCES[$idx]}${NC}"
            [ -n "${ENTRY_SERVERS[$idx]}" ] && echo -e "${YELLOW}Сервер: ${ENTRY_SERVERS[$idx]}${NC}"
            echo ""

            if confirm_action "Подтверждаете удаление?"; then
                if perform_deletion $idx; then
                    echo -e "${GREEN}✓ Запись успешно удалена${NC}"
                    DELETED_COUNT=$((DELETED_COUNT + 1))
                    verify_deletion $idx

                    # Удаляем из массивов
                    unset 'ENTRY_SOURCES[idx]'
                    unset 'ENTRY_LABELS[idx]'
                    unset 'ENTRY_KEYS[idx]'
                    unset 'ENTRY_SERVERS[idx]'
                    unset 'ENTRY_URIS[idx]'
                    unset 'ENTRY_PATHS[idx]'

                    # Переиндексация массивов
                    ENTRY_SOURCES=("${ENTRY_SOURCES[@]}")
                    ENTRY_LABELS=("${ENTRY_LABELS[@]}")
                    ENTRY_KEYS=("${ENTRY_KEYS[@]}")
                    ENTRY_SERVERS=("${ENTRY_SERVERS[@]}")
                    ENTRY_URIS=("${ENTRY_URIS[@]}")
                    ENTRY_PATHS=("${ENTRY_PATHS[@]}")
                    FOUND_COUNT=$((FOUND_COUNT - 1))
                else
                    echo -e "${RED}✗ Не удалось удалить запись${NC}"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                fi
            else
                echo -e "${CYAN}Удаление отменено${NC}"
            fi
            echo ""

            # Показываем обновлённый список
            if [ $FOUND_COUNT -gt 0 ]; then
                display_entries
            else
                echo -e "${GREEN}Все записи удалены${NC}"
                break
            fi
        else
            echo -e "${RED}Неверный номер. Введите число от 1 до $FOUND_COUNT, 'q' для выхода или 'a' для удаления всех${NC}"
        fi
    done
}

# Удаление всех записей
delete_all_entries() {
    echo -e "\n${MAGENTA}Удаление всех записей...${NC}\n"

    for i in "${!ENTRY_LABELS[@]}"; do
        echo -e "${CYAN}[$((i+1))/${FOUND_COUNT}]${NC} ${ENTRY_LABELS[$i]}"
        
        if perform_deletion $i; then
            echo -e "${GREEN}  ✓ Удалено${NC}"
            DELETED_COUNT=$((DELETED_COUNT + 1))
        else
            echo -e "${RED}  ✗ Не удалось удалить${NC}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    done

    FOUND_COUNT=0
}

# ============================================
# Пакетный режим (batch-delete)
# ============================================

batch_delete() {
    echo -e "${MAGENTA}ПАКЕТНЫЙ РЕЖИМ: Удаление всех найденных записей${NC}\n"

    if [ $FOUND_COUNT -eq 0 ]; then
        echo -e "${YELLOW}Записи не найдены${NC}"
        return
    fi

    for i in "${!ENTRY_LABELS[@]}"; do
        echo -e "${CYAN}[$((i+1))/${FOUND_COUNT}]${NC} ${ENTRY_LABELS[$i]} (${ENTRY_SOURCES[$i]})"
        
        if perform_deletion $i; then
            echo -e "${GREEN}  ✓ Удалено${NC}"
            DELETED_COUNT=$((DELETED_COUNT + 1))
        else
            echo -e "${YELLOW}  ⚠ Пропущено или ошибка${NC}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    done

    echo -e "\n${GREEN}Удалено: $DELETED_COUNT, Ошибок: $FAILED_COUNT${NC}"
}

# ============================================
# Режим экспорта
# ============================================

export_report() {
    local output_file="${1:-/dev/stdout}"

    {
        echo "========================================================="
        echo "  ОТЧЁТ: Сохранённые учётные данные сетевых ресурсов"
        echo "  Дата: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "  Хост: $(hostname)"
        echo "  Пользователь: $(whoami)"
        echo "========================================================="
        echo ""
        echo "Всего найдено записей: $FOUND_COUNT"
        echo ""

        for i in "${!ENTRY_LABELS[@]}"; do
            echo "[$((i+1))] ${ENTRY_LABELS[$i]}"
            echo "    Источник: ${ENTRY_SOURCES[$i]}"
            [ -n "${ENTRY_SERVERS[$i]}" ] && echo "    Сервер: ${ENTRY_SERVERS[$i]}"
            [ -n "${ENTRY_URIS[$i]}" ] && echo "    URI: ${ENTRY_URIS[$i]}"
            [ -n "${ENTRY_PATHS[$i]}" ] && echo "    Путь: ${ENTRY_PATHS[$i]}"
            echo "    Ключ: ${ENTRY_KEYS[$i]}"
            echo ""
        done

        echo "========================================================="
        echo "  Для удаления запустите: $0 --batch"
        echo "========================================================="
    } > "$output_file" 2>&1

    if [ "$output_file" != "/dev/stdout" ]; then
        echo -e "${GREEN}Отчёт сохранён в: $output_file${NC}"
    fi
}

# ============================================
# Диагностика
# ============================================

run_diagnostics() {
    echo -e "${BLUE}=======================================================${NC}"
    echo -e "${GREEN}  ДИАГНОСТИКА${NC}"
    echo -e "${BLUE}=======================================================${NC}"
    echo ""

    # Проверяем активные SMB монтирования
    echo -e "${CYAN}Активные SMB монтирования:${NC}"
    if command -v gio &>/dev/null; then
        local gio_mounts
        gio_mounts=$(gio mount --list 2>/dev/null | grep -E "smb://|cifs://" || echo "  Нет активных монтирований")
        echo "$gio_mounts"
    else
        echo "  gio не установлен"
    fi
    echo ""

    # Проверяем /etc/fstab
    echo -e "${CYAN}Записи SMB в /etc/fstab:${NC}"
    if [ -f "/etc/fstab" ]; then
        local fstab_smb
        fstab_smb=$(grep -E "//.*smb|//.*cifs|credentials=" /etc/fstab 2>/dev/null || echo "  Нет записей")
        echo "$fstab_smb"
    fi
    echo ""

    # Проверяем GNOME Keyring
    echo -e "${CYAN}Записи SMB в GNOME Keyring:${NC}"
    if command -v secret-tool &>/dev/null; then
        local keyring_count
        keyring_count=$(secret-tool search --all smb 2>/dev/null | grep -c "^\[" || echo "0")
        echo "  Найдено записей: $keyring_count"
    else
        echo "  secret-tool не установлен"
    fi
    echo ""

    # Проверяем кэш Samba
    echo -e "${CYAN}Кэш Samba:${NC}"
    local system_cache=0
    local user_cache=0
    [ -d "/var/cache/samba" ] && system_cache=$(find /var/cache/samba -type f 2>/dev/null | wc -l)
    [ -d "$HOME/.cache/samba" ] && user_cache=$(find "$HOME/.cache/samba" -type f 2>/dev/null | wc -l)
    echo "  Системный кэш: $system_cache файлов"
    echo "  Пользовательский кэш: $user_cache файлов"
    echo ""

    # Проверяем autofs
    echo -e "${CYAN}Служба autofs:${NC}"
    if systemctl is-active --quiet autofs 2>/dev/null; then
        echo "  ${YELLOW}Активна${NC}"
    else
        echo "  Не активна"
    fi
    echo ""

    # Проверяем systemd mount units
    echo -e "${CYAN}Systemd mount units (SMB/CIFS):${NC}"
    local systemd_mounts
    systemd_mounts=$(systemctl list-units --type=mount --all 2>/dev/null | grep -iE "smb|cifs" || echo "  Нет SMB mount units")
    echo "$systemd_mounts"
    echo ""
}

# ============================================
# Справка
# ============================================

show_help() {
    echo "Использование: $0 [ОПЦИИ]"
    echo ""
    echo "ОПЦИИ:"
    echo "  --scan, -s              Только сканирование (без удаления)"
    echo "  --batch, -b             Пакетный режим (удаление всех записей)"
    echo "  --export [ФАЙЛ], -e     Экспорт отчёта (в файл или stdout)"
    echo "  --diagnose, -d          Запуск диагностики"
    echo "  --help, -h              Показать эту справку"
    echo ""
    echo "ПРИМЕРЫ:"
    echo "  $0                      # Интерактивный режим"
    echo "  $0 --scan               # Только показать найденные записи"
    echo "  $0 --batch              # Удалить все найденные записи"
    echo "  $0 --export report.txt  # Сохранить отчёт в файл"
    echo "  $0 --diagnose           # Показать диагностику"
    echo ""
    echo "ОПИСАНИЕ:"
    echo "  Скрипт сканирует 12 хранилищ учётных данных:"
    echo "  1.  GNOME Keyring (secret-tool)"
    echo "  2.  Файлы учётных данных Samba"
    echo "  3.  Кэш Samba"
    echo "  4.  Файл ~/.netrc"
    echo "  5.  GVFS (монтирования)"
    echo "  6.  GVFS Metadata"
    echo "  7.  Конфиг Samba пользователя"
    echo "  8.  KDE Wallet"
    echo "  9.  Autofs"
    echo "  10. Systemd mount units"
    echo "  11. Активные GVFS монтирования"
    echo "  12. Dconf (настройки GNOME)"
    echo ""
}

# ============================================
# Основная функция
# ============================================

main() {
    # Обработка аргументов командной строки
    case "${1:-}" in
        --scan|-s)
            MODE="scan-only"
            ;;
        --batch|-b)
            MODE="batch-delete"
            ;;
        --export|-e)
            MODE="export"
            EXPORT_FILE="${2:-}"
            ;;
        --diagnose|-d)
            MODE="diagnose"
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            MODE="interactive"
            ;;
        *)
            print_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
    esac

    print_header

    echo -e "${CYAN}Сканирование хранилищ учётных данных...${NC}"
    echo ""

    # Сканирование всех хранилищ
    scan_gnome_keyring
    scan_samba_credentials
    scan_samba_cache
    scan_netrc
    scan_gvfs
    scan_gvfs_metadata
    scan_smb_config
    scan_kde_wallet
    scan_autofs
    scan_systemd_mounts
    scan_gvfs_active
    scan_dconf

    # Действия в зависимости от режима
    case "$MODE" in
        "scan-only")
            display_entries
            echo -e "${BLUE}=======================================================${NC}"
            echo -e "${GREEN}  Найдено: $FOUND_COUNT записей${NC}"
            echo -e "${BLUE}=======================================================${NC}"
            echo ""
            echo -e "${CYAN}Для удаления запустите: $0 --batch${NC}"
            echo -e "${CYAN}Для интерактивного удаления: $0${NC}"
            ;;
        "batch-delete")
            display_entries
            batch_delete
            ;;
        "export")
            export_report "$EXPORT_FILE"
            ;;
        "diagnose")
            display_entries
            run_diagnostics
            ;;
        "interactive")
            display_entries

            # Итоговая статистика
            echo -e "${BLUE}=======================================================${NC}"
            echo -e "${GREEN}  Найдено: $FOUND_COUNT записей${NC}"
            echo -e "${BLUE}=======================================================${NC}"
            echo ""

            # Интерактивное удаление
            if [ $FOUND_COUNT -gt 0 ]; then
                interactive_delete
            fi
            ;;
    esac

    # Финальная статистика
    if [ "$MODE" != "scan-only" ] && [ "$MODE" != "export" ] && [ "$MODE" != "diagnose" ]; then
        echo ""
        echo -e "${BLUE}=======================================================${NC}"
        echo -e "${GREEN}  Удалено: $DELETED_COUNT, Ошибок: $FAILED_COUNT${NC}"
        echo -e "${BLUE}=======================================================${NC}"
    fi

    echo ""
    echo -e "${CYAN}Рекомендация: после удаления учётных данных попробуйте${NC}"
    echo -e "${CYAN}подключиться к сетевому ресурсу — система запросит новый пароль.${NC}"
    echo ""
}

# Запуск
main "$@"