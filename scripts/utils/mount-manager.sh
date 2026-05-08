#!/bin/bash
##############################################################################
# mount-manager.sh — Управление монтированием сетевых шар (CIFS/SMB)
#
# Автор: pagrishaevich
# Версия: 2.1.1
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
#       --dry-run     Показать команды без выполнения
#       --clean-creds Очистить неиспользуемые файлы учётных данных
#
# Зависимости: bash, coreutils, mount, cifs-utils (mount.cifs), grep, sed
# Опционально: smbclient (диагностика SMB)
#
# Совместимость: РЕД ОС 7.x ✅, РЕД ОС 8.x ✅
##############################################################################

set -uo pipefail

# ─── Конфигурация ──────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="2.1.1"
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="/var/log/mount-manager.log"
readonly MOUNT_BASE="/mnt"
readonly FSTAB="/etc/fstab"
readonly CREDENTIALS_DIR="/root/.smb_credentials"
readonly CONFIG_FILE="/etc/mount-manager.conf"
readonly BACKUP_DIR="/root/.mount-manager-backups"

# ─── Цвета ────────────────────────────────────────────────────────────────
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ─── Глобальные переменные ────────────────────────────────────────────────
DRY_RUN=0
QUIET=0

# ─── Вспомогательные функции ──────────────────────────────────────────────

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

# Функция для проверки успешности выполнения
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 успешно выполнено${NC}"
        log "INFO" "$1 успешно выполнено"
    else
        echo -e "${RED}✗ Ошибка при выполнении: $1${NC}"
        log "ERROR" "Ошибка при выполнении: $1"
        exit 1
    fi
}

# ─── Функции логирования ──────────────────────────────────────────────────
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [[ $QUIET -eq 0 ]]; then
        case "$level" in
            ERROR)   echo -e "${RED}[ERROR] $message${NC}" >&2 ;;
            WARN)    echo -e "${YELLOW}[WARN] $message${NC}" >&2 ;;
            INFO)    echo -e "${GREEN}[INFO] $message${NC}" >&2 ;;
            DEBUG)   [[ ${DEBUG:-0} -eq 1 ]] && echo -e "${CYAN}[DEBUG] $message${NC}" ;;
            *)       echo "$message" ;;
        esac
    fi
}

error() { log "ERROR" "$*"; exit 1; }
warn() { log "WARN" "$*"; }
info() { log "INFO" "$*"; }
debug() { log "DEBUG" "$*"; }

# ─── Инициализация ────────────────────────────────────────────────────────
init_directories() {
    mkdir -p "$MOUNT_BASE" "$CREDENTIALS_DIR" "$BACKUP_DIR"
    chmod 700 "$CREDENTIALS_DIR"
    chmod 755 "$MOUNT_BASE"
    
    # Ротация лога (оставляем последние 10 МБ)
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt 10485760 ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        info "Выполнена ротация лога"
    fi
}

# ─── Проверка прав root ──────────────────────────────────────────────────
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Скрипт требует прав root. Запустите: sudo $0"
    fi
}

# ─── Проверка зависимостей ───────────────────────────────────────────────
check_dependencies() {
    local deps=("mount.cifs" "grep" "sed" "awk")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Отсутствуют зависимости: ${missing[*]}. Установите: dnf install cifs-utils"
    fi
    
    if ! command -v smbclient &>/dev/null; then
        warn "smbclient не найден (диагностика SMB будет ограничена)"
    fi
}

# ─── Проверка имени точки монтирования ───────────────────────────────────
validate_mount_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        error "Имя точки монтирования не может быть пустым"
    fi
    
    if [[ "$name" =~ [[:space:]/] ]]; then
        error "Имя точки монтирования не должно содержать пробелы или символ '/'"
    fi
    
    if [[ "$name" =~ ^\. ]]; then
        error "Имя точки монтирования не может начинаться с точки"
    fi
    
    return 0
}

# ─── Проверка сервера ────────────────────────────────────────────────────
validate_server() {
    local server="$1"
    
    if [[ -z "$server" ]]; then
        error "Имя сервера не может быть пустым"
    fi
    
    # Проверка на недопустимые символы
    if [[ "$server" =~ [[:space:]] ]]; then
        error "Имя сервера не должно содержать пробелы"
    fi
    
    return 0
}

# ─── Проверка наличия шары через smbclient ───────────────────────────────
check_smb_share() {
    local server="$1"
    local share="$2"
    local username="$3"
    local password="$4"
    
    if ! command -v smbclient &>/dev/null; then
        return 0  # Пропускаем проверку, если smbclient нет
    fi
    
    info "Проверка доступности шары //${server}/${share}..."
    
    local output
    if output=$(smbclient -L "//${server}" -U "${username}%${password}" -g 2>&1); then
        if echo "$output" | grep -q "Disk.*${share}" || echo "$output" | grep -q "^\\(Disk\\|IPC\\)|.*${share}|"; then
            info "Шара найдена"
            return 0
        else
            warn "Шара '${share}' не найдена на сервере"
            if confirm_action "Монтировать всё равно?"; then
                return 0
            else
                return 1
            fi
        fi
    else
        warn "Не удалось проверить шару: $output"
        if confirm_action "Продолжить монтирование?"; then
            return 0
        else
            return 1
        fi
    fi
}

# ─── Получение опций монтирования ────────────────────────────────────────
get_mount_opts() {
    local is_domain="$1"
    local timeout="${2:-30}"
    local retrans="${3:-2}"
    local opts="nobrl,iocharset=utf8,file_mode=0777,dir_mode=0777,timeo=${timeout},retrans=${retrans}"
    
    if [[ "$is_domain" == "1" ]]; then
        opts="${opts},nofail"
    fi
    
    echo "$opts"
}

# ─── Создание файла учётных данных ───────────────────────────────────────
create_credentials_file() {
    local username="$1"
    local password="$2"
    local domain="${3:-}"
    
    # Генерируем уникальное имя файла
    local hash=$(echo "${username}${domain}$(date +%s%N)" | md5sum | cut -c1-12)
    local cred_file="${CREDENTIALS_DIR}/cred_${hash}"
    
    # Проверяем, не является ли файл симлинком
    if [[ -L "$cred_file" ]]; then
        error "Путь к файлу учётных данных не должен быть симлинком"
    fi
    
    cat > "$cred_file" <<EOF
username=${username}
password=${password}
EOF
    
    if [[ -n "$domain" ]]; then
        echo "domain=${domain}" >> "$cred_file"
    fi
    
    chmod 600 "$cred_file"
    info "Создан файл учётных данных: ${cred_file}"
    echo "$cred_file"
}

# ─── Очистка неиспользуемых файлов учётных данных ────────────────────────
clean_credentials() {
    info "Очистка неиспользуемых файлов учётных данных..."
    
    local used_creds=()
    
    # Поиск используемых cred-файлов в fstab
    if [[ -f "$FSTAB" ]]; then
        while IFS= read -r line; do
            if echo "$line" | grep -q "credentials="; then
                local cred_file=$(echo "$line" | sed -n 's/.*credentials=\([^,]*\).*/\1/p')
                if [[ -n "$cred_file" ]] && [[ -f "$cred_file" ]]; then
                    used_creds+=("$cred_file")
                fi
            fi
        done < "$FSTAB"
    fi
    
    # Очистка
    local count=0
    for cred_file in "$CREDENTIALS_DIR"/cred_*; do
        if [[ -f "$cred_file" ]]; then
            local found=0
            for used in "${used_creds[@]}"; do
                if [[ "$cred_file" == "$used" ]]; then
                    found=1
                    break
                fi
            done
            
            if [[ $found -eq 0 ]]; then
                if [[ $DRY_RUN -eq 1 ]]; then
                    info "[DRY-RUN] Будет удалён: $cred_file"
                else
                    rm -f "$cred_file"
                    ((count++))
                    debug "Удалён: $cred_file"
                fi
            fi
        fi
    done
    
    info "Очистка завершена. Удалено файлов: $count"
    check_success "Очистка неиспользуемых cred-файлов"
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
    local mount_opts=$(get_mount_opts "$is_domain")
    mount_opts="credentials=${cred_file},${mount_opts}"
    
    # Dry-run режим
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] Будет выполнено: mount -t cifs //${server}/${share} ${mount_point} -o ${mount_opts}"
        if [[ "$add_to_fstab" == "1" ]]; then
            info "[DRY-RUN] Будет добавлено в fstab: //${server}/${share} ${mount_point}/ cifs ${mount_opts} 0 0"
        fi
        return 0
    fi
    
    # Создаём точку монтирования
    mkdir -p "$mount_point"
    
    info "Монтирование //${server}/${share} -> ${mount_point}"
    
    # Выполняем монтирование
    if mount -t cifs "//${server}/${share}" "$mount_point" -o "$mount_opts"; then
        info "Успешно смонтировано: ${mount_point}"
        check_success "Монтирование ${mount_name}"
        
        # Проверяем, что монтирование успешно
        if mountpoint -q "$mount_point"; then
            # Только после успешного монтирования спрашиваем про fstab
            if [[ "$add_to_fstab" == "1" ]]; then
                add_to_fstab_entry "$server" "$share" "$mount_name" "$cred_file" "$is_domain"
            fi
        else
            error "Точка монтирования не активна после монтирования"
        fi
    else
        # Очищаем при ошибке
        rmdir "$mount_point" 2>/dev/null
        error "Ошибка монтирования! Проверьте:
  - Доступность сервера: ping ${server}
  - Учётные данные в: ${cred_file}
  - Сетевое соединение
  - Логи: ${LOG_FILE}"
    fi
}

# ─── Добавление записи в fstab с резервным копированием ──────────────────
add_to_fstab_entry() {
    local server="$1"
    local share="$2"
    local mount_name="$3"
    local cred_file="$4"
    local is_domain="$5"
    
    local mount_point="${MOUNT_BASE}/${mount_name}/"
    local mount_opts=$(get_mount_opts "$is_domain")
    local fstab_entry="//${server}/${share} ${mount_point} cifs credentials=${cred_file},${mount_opts} 0 0"
    
    # Проверяем существующую запись
    if grep -q "^//${server}/${share}" "$FSTAB" 2>/dev/null; then
        warn "Запись уже существует в /etc/fstab"
        return 0
    fi
    
    # Создаём резервную копию fstab
    if [[ ! -f "${FSTAB}.backup" ]]; then
        cp "$FSTAB" "${FSTAB}.backup"
        info "Создана резервная копия fstab: ${FSTAB}.backup"
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] Будет добавлено в fstab: $fstab_entry"
        return 0
    fi
    
    echo "$fstab_entry" >> "$FSTAB"
    info "Запись добавлена в /etc/fstab"
    check_success "Добавление записи в fstab"
}

# ─── Размонтирование с проверкой содержимого ─────────────────────────────
unmount_share() {
    local mount_name="$1"
    local mount_point="${MOUNT_BASE}/${mount_name}"
    
    if [[ ! -d "$mount_point" ]]; then
        error "Точка монтирования не найдена: ${mount_point}"
    fi
    
    if ! mountpoint -q "$mount_point"; then
        warn "Не смонтировано: ${mount_point}"
        if [[ -d "$mount_point" ]]; then
            if confirm_action "Удалить директорию ${mount_point}?"; then
                if [[ $DRY_RUN -eq 1 ]]; then
                    info "[DRY-RUN] Будет удалена: $mount_point"
                else
                    rm -rf "$mount_point"
                    info "Директория удалена: ${mount_point}"
                    check_success "Удаление директории"
                fi
            fi
        fi
        return 0
    fi
    
    info "Размонтирование: ${mount_point}"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] Будет выполнено: umount $mount_point"
        return 0
    fi
    
    if umount "$mount_point"; then
        info "Успешно размонтировано: ${mount_point}"
        check_success "Размонтирование ${mount_name}"
    else
        warn "Ошибка размонтирования. Попытка принудительного..."
        if umount -l "$mount_point" 2>/dev/null; then
            info "Принудительно размонтировано"
            check_success "Принудительное размонтирование"
        else
            error "Не удалось размонтировать ${mount_point}"
        fi
    fi
    
    # Проверка директории перед удалением
    if [[ -d "$mount_point" ]]; then
        if [[ -z "$(ls -A "$mount_point" 2>/dev/null)" ]]; then
            rmdir "$mount_point" 2>/dev/null && info "Директория удалена: ${mount_point}"
        else
            warn "Директория не пуста: ${mount_point}"
            ls -la "$mount_point"
            if confirm_action "Удалить директорию со всем содержимым?"; then
                rm -rf "$mount_point"
                info "Директория удалена: ${mount_point}"
                check_success "Удаление директории с содержимым"
            else
                warn "Директория сохранена: ${mount_point}"
            fi
        fi
    fi
}

# ─── Список смонтированных шар ───────────────────────────────────────────
list_mounts() {
    echo -e "${BLUE}=== Смонтированные CIFS шары ===${NC}"
    echo ""
    
    local count=0
    if mount | grep -q "type cifs"; then
        while IFS= read -r line; do
            echo -e "  ${GREEN}●${NC} $line"
            ((count++))
        done < <(mount | grep "type cifs")
    else
        echo -e "  ${YELLOW}Нет смонтированных CIFS шар${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}=== Записи из /etc/fstab (CIFS) ===${NC}"
    echo ""
    
    if [[ -f "$FSTAB" ]]; then
        local fstab_count=0
        while IFS= read -r line; do
            if echo "$line" | grep -q "^//.*cifs" && ! echo "$line" | grep -q "^#"; then
                echo -e "  ${GREEN}●${NC} $line"
                ((fstab_count++))
            fi
        done < "$FSTAB"
        
        if [[ $fstab_count -eq 0 ]]; then
            echo -e "  ${YELLOW}Нет активных записей CIFS в /etc/fstab${NC}"
        fi
    else
        echo -e "  ${RED}/etc/fstab не найден${NC}"
    fi
    
    echo ""
}

# ─── Монтирование всех шар из fstab ──────────────────────────────────────
mount_all_fstab() {
    info "Монтирование всех шар из /etc/fstab..."
    
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] Будет выполнено: mount -a -t cifs"
        return 0
    fi
    
    if mount -a -t cifs; then
        info "Все шары смонтированы"
        check_success "Монтирование всех шар из fstab"
    else
        error "Ошибка при монтировании некоторых шар. Проверьте логи: ${LOG_FILE}"
    fi
}

# ─── Удаление записи из fstab с резервным копированием ───────────────────
remove_from_fstab() {
    local mount_name="$1"
    local mount_point="${MOUNT_BASE}/${mount_name}/"
    
    if [[ ! -f "$FSTAB" ]]; then
        error "/etc/fstab не найден"
    fi
    
    if grep -q "${mount_point}" "$FSTAB"; then
        if [[ $DRY_RUN -eq 1 ]]; then
            info "[DRY-RUN] Будет удалена запись для ${mount_point} из fstab"
            return 0
        fi
        
        # Создаём резервную копию
        cp "$FSTAB" "${FSTAB}.backup.$(date +%Y%m%d_%H%M%S)"
        
        sed -i "\|${mount_point}|d" "$FSTAB"
        info "Запись удалена из /etc/fstab"
        check_success "Удаление записи из fstab"
    else
        warn "Запись не найдена в /etc/fstab"
    fi
}

# ─── Сохранение в конфиг-файл (без пароля) ───────────────────────────────
save_to_config() {
    local name="$1"
    local server="$2"
    local share="$3"
    local username="$4"
    local cred_file="$5"
    local domain="$6"
    local is_domain="$7"
    
    # Сохраняем только путь к cred-файлу, а не пароль
    cat >> "$CONFIG_FILE" <<EOF
[${name}]
server=${server}
share=${share}
username=${username}
cred_file=${cred_file}
domain=${domain}
is_domain=${is_domain}
created=$(date '+%Y-%m-%d %H:%M:%S')

EOF
    
    chmod 600 "$CONFIG_FILE"
    info "Конфигурация сохранена: ${CONFIG_FILE}"
    check_success "Сохранение конфигурации"
}

# ─── Загрузка из конфиг-файла ────────────────────────────────────────────
load_from_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "Конфиг-файл не найден: ${CONFIG_FILE}"
        return 0
    fi
    
    echo -e "${BLUE}=== Доступные пресеты ===${NC}"
    echo ""
    
    local sections=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[(.*)\]$ ]]; then
            sections+=("${BASH_REMATCH[1]}")
        fi
    done < "$CONFIG_FILE"
    
    if [[ ${#sections[@]} -eq 0 ]]; then
        warn "Нет сохранённых пресетов"
        return 0
    fi
    
    for i in "${!sections[@]}"; do
        echo "  $((i+1))) ${sections[$i]}"
    done
    echo ""
    
    local preset_num
    preset_num=$(read_from_terminal "Выберите пресет (номер): ")
    
    if [[ ! "$preset_num" =~ ^[0-9]+$ ]] || [[ $preset_num -lt 1 ]] || [[ $preset_num -gt ${#sections[@]} ]]; then
        error "Неверный номер"
    fi
    
    local preset_name="${sections[$((preset_num-1))]}"
    local in_section=0
    local server="" share="" username="" cred_file="" domain="" is_domain="0"
    
    while IFS= read -r line; do
        if [[ "$line" == "[${preset_name}]" ]]; then
            in_section=1
            continue
        fi
        
        if [[ $in_section -eq 1 ]]; then
            if [[ "$line" =~ ^\[.*\]$ ]]; then
                break
            fi
            
            local key=$(echo "$line" | cut -d'=' -f1)
            local value=$(echo "$line" | cut -d'=' -f2-)
            
            case "$key" in
                server)     server="$value" ;;
                share)      share="$value" ;;
                username)   username="$value" ;;
                cred_file)  cred_file="$value" ;;
                domain)     domain="$value" ;;
                is_domain)  is_domain="$value" ;;
            esac
        fi
    done < "$CONFIG_FILE"
    
    if [[ -z "$server" ]] || [[ -z "$share" ]]; then
        error "Не удалось загрузить пресет"
    fi
    
    info "Загружен пресет: ${preset_name}"
    
    # Проверяем существование cred-файла
    if [[ ! -f "$cred_file" ]]; then
        warn "Файл учётных данных не найден: ${cred_file}"
        if confirm_action "Создать новый?"; then
            local password
            password=$(read_from_terminal "Пароль для ${username}: ")
            cred_file=$(create_credentials_file "$username" "$password" "$domain")
        else
            return 1
        fi
    fi
    
    if confirm_action "Смонтировать?"; then
        mount_share "$server" "$share" "$preset_name" "$cred_file" "$is_domain" "1"
    fi
}

# ─── Интерактивный режим — добавление новой шары ─────────────────────────
interactive_add() {
    echo -e "${BLUE}=== Добавление новой шары ===${NC}"
    echo ""
    
    # Ввод с валидацией
    while true; do
        local server
        server=$(read_from_terminal "IP/имя сервера: ")
        validate_server "$server" && break
    done
    
    while true; do
        local share
        share=$(read_from_terminal "Имя шары: ")
        [[ -n "$share" ]] && break
        warn "Имя шары не может быть пустым"
    done
    
    while true; do
        local mount_name
        mount_name=$(read_from_terminal "Имя точки монтирования (будет в /mnt/): ")
        validate_mount_name "$mount_name" && break
    done
    
    while true; do
        local username
        username=$(read_from_terminal "Имя пользователя: ")
        [[ -n "$username" ]] && break
        warn "Имя пользователя не может быть пустым"
    done
    
    local password
    password=$(read_from_terminal "Пароль: ")
    
    local is_domain_answer
    is_domain_answer=$(read_from_terminal "Доменная шара? (y/n): ")
    local is_domain="0"
    local domain=""
    if [[ "$is_domain_answer" =~ ^[Yy]$ ]]; then
        is_domain="1"
        domain=$(read_from_terminal "Домен (необязательно, Enter для пропуска): ")
    fi
    
    # Проверка доступности шары
    if ! check_smb_share "$server" "$share" "$username" "$password"; then
        return 1
    fi
    
    local cred_file
    cred_file=$(create_credentials_file "$username" "$password" "$domain")
    
    local add_fstab_answer
    add_fstab_answer=$(read_from_terminal "Добавить в /etc/fstab? (y/n): ")
    local add_to_fstab="0"
    if [[ "$add_fstab_answer" =~ ^[Yy]$ ]]; then
        add_to_fstab="1"
    fi
    
    # Монтируем
    if mount_share "$server" "$share" "$mount_name" "$cred_file" "$is_domain" "$add_to_fstab"; then
        local save_config_answer
        save_config_answer=$(read_from_terminal "Сохранить в конфиг-файл? (y/n): ")
        if [[ "$save_config_answer" =~ ^[Yy]$ ]]; then
            save_to_config "$mount_name" "$server" "$share" "$username" "$cred_file" "$domain" "$is_domain"
        fi
    fi
}

# ─── Интерактивный режим — удаление шары ─────────────────────────────────
interactive_remove() {
    echo -e "${BLUE}=== Удаление шары ===${NC}"
    echo ""
    
    local mounts=()
    while IFS= read -r line; do
        if echo "$line" | grep -q "type cifs"; then
            local mp=$(echo "$line" | awk '{print $3}')
            local name=$(basename "$mp")
            mounts+=("$name")
        fi
    done < <(mount | grep cifs)
    
    if [[ ${#mounts[@]} -eq 0 ]]; then
        warn "Нет смонтированных шар"
        return 0
    fi
    
    echo "Смонтированные шары:"
    for i in "${!mounts[@]}"; do
        echo "  $((i+1))) ${mounts[$i]}"
    done
    echo ""
    
    local num
    num=$(read_from_terminal "Выберите для размонтирования (номер): ")
    
    if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#mounts[@]} ]]; then
        local selected="${mounts[$((num-1))]}"
        
        if confirm_action "Размонтировать '${selected}'?"; then
            unmount_share "$selected"
            
            if confirm_action "Удалить из /etc/fstab?"; then
                remove_from_fstab "$selected"
            fi
        fi
    else
        error "Неверный номер"
    fi
}

# ─── Показать информацию о системе ───────────────────────────────────────
show_info() {
    echo -e "${BLUE}=== Информация о системе ===${NC}"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo -e "  ОС: ${GREEN}${NAME} ${VERSION_ID}${NC}"
    fi
    
    echo -e "  Версия скрипта: ${GREEN}${SCRIPT_VERSION}${NC}"
    echo -e "  Лог-файл: ${YELLOW}${LOG_FILE}${NC}"
    echo -e "  Конфиг: ${YELLOW}${CONFIG_FILE}${NC}"
    echo -e "  Credentials dir: ${YELLOW}${CREDENTIALS_DIR}${NC}"
    
    # Проверка установленных пакетов
    echo -e "\n${BLUE}=== Установленные пакеты ===${NC}"
    for pkg in cifs-utils samba-client; do
        if rpm -q "$pkg" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${RED}✗${NC} $pkg"
        fi
    done
}

# ─── Главное меню ─────────────────────────────────────────────────────────
main_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║     Управление монтированием шар v${SCRIPT_VERSION}    ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Добавить и смонтировать новую шару"
        echo "  2) Загрузить из конфиг-файла"
        echo "  3) Размонтировать шару"
        echo "  4) Список смонтированных"
        echo "  5) Монтировать все из fstab"
        echo "  6) Очистить неиспользуемые cred-файлы"
        echo "  7) Информация о системе"
        echo "  8) Выход"
        echo ""
        
        local choice
        choice=$(read_from_terminal "Выбор: ")
        
        case $choice in
            1) interactive_add ;;
            2) load_from_config ;;
            3) interactive_remove ;;
            4) list_mounts ;;
            5) mount_all_fstab ;;
            6) clean_credentials ;;
            7) show_info ;;
            8) echo "Выход..."; exit 0 ;;
            *) warn "Неверный выбор" ;;
        esac
    done
}

# ─── Справка ──────────────────────────────────────────────────────────────
show_help() {
    cat <<EOF
Использование: $SCRIPT_NAME [опции]

Опции:
  --list, -l           Список смонтированных шар
  --add, -a            Добавить новую шару (интерактивно)
  --remove, -r         Размонтировать шару (интерактивно)
  --load               Загрузить пресет из конфига
  --mount-all          Монтировать все шары из fstab
  --clean-creds        Очистить неиспользуемые файлы учётных данных
  --dry-run            Показать команды без выполнения
  --quiet, -q          Минимум вывода (только ошибки)
  --debug              Режим отладки
  --info               Показать информацию о системе
  --help, -h           Эта справка

Без опций запускается интерактивное меню

Примеры:
  sudo $SCRIPT_NAME --add
  sudo $SCRIPT_NAME --dry-run --mount-all
  sudo $SCRIPT_NAME --clean-creds

Логирование: $LOG_FILE
EOF
}

# ─── Основная логика ─────────────────────────────────────────────────────
main() {
    # Обработка глобальных опций
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=1; shift ;;
            --quiet|-q) QUIET=1; shift ;;
            --debug) DEBUG=1; shift ;;
            *) break ;;
        esac
    done
    
    check_root
    init_directories
    check_dependencies
    
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --list|-l)          list_mounts ;;
            --add|-a)           interactive_add ;;
            --remove|-r)        interactive_remove ;;
            --load)             load_from_config ;;
            --mount-all)        mount_all_fstab ;;
            --clean-creds)      clean_credentials ;;
            --info)             show_info ;;
            --help|-h)          show_help ;;
            *)
                error "Неизвестная опция: $1. Используйте --help для справки"
                ;;
        esac
    else
        main_menu
    fi
}

# Запуск
main "$@"
