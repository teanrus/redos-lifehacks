#!/bin/bash
#
# Скрипт настройки прокси-сервера для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_proxy.sh | sudo bash
# GitHub: https://github.com/teanrus/redos-lifehacks
#

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Вспомогательные функции
# ============================================================================

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
        echo -e "${GREEN}✓ $1 успешно выполнено${NC}" >&2
    else
        echo -e "${RED}✗ Ошибка при выполнении: $1${NC}" >&2
        exit 1
    fi
}

# Логирование
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${BLUE}========================================${NC}"; }

# ============================================================================
# Проверка прав root
# ============================================================================
if [[ $EUID -ne 0 ]]; then
    log_error "Скрипт должен выполняться от имени root"
    exit 1
fi

# Проверка ОС (опционально - предупреждение если не РЕД ОС)
if [[ -f /etc/os-release ]]; then
    OS_ID=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    if [[ "$OS_ID" != "redos" ]]; then
        log_warn "Скрипт разработан для РЕД ОС, обнаружена: $OS_ID"
        log_warn "Продолжение работы возможно, но не гарантируется"
    fi
fi

log_header
log_info "Настройка прокси-сервера в РЕД ОС"
log_header
echo ""

# ============================================================================
# Проверка текущей конфигурации
# ============================================================================
log_info "Проверка текущей конфигурации прокси..."

declare -A CURRENT_PROXY
CURRENT_PROXY["http_proxy"]="${http_proxy:-не установлен}"
CURRENT_PROXY["https_proxy"]="${https_proxy:-не установлен}"
CURRENT_PROXY["ftp_proxy"]="${ftp_proxy:-не установлен}"
CURRENT_PROXY["no_proxy"]="${no_proxy:-не установлен}"

for var in "${!CURRENT_PROXY[@]}"; do
    echo -e "  ${BLUE}$var${NC}=${CURRENT_PROXY[$var]}"
done
echo ""

# ============================================================================
# Меню выбора действий
# ============================================================================
echo -e "${BLUE}Выберите действия для выполнения:${NC}"
echo ""

# Массивы для хранения пунктов меню и флагов
declare -a MENU_ITEMS
declare -A MENU_ENABLED

MENU_ITEMS=(
    "Настройка системного прокси (для всех пользователей)"
    "Настройка прокси для текущего пользователя"
    "Настройка прокси для APT/DNF"
    "Настройка прокси для Git"
    "Настройка прокси для wget/curl"
    "Настройка прокси для Docker"
    "Настройка прокси для Snap"
    "Настройка исключений (no_proxy)"
    "Создание скрипта быстрого переключения прокси"
    "Настройка прокси с авторизацией"
    "Проверка работы прокси"
)

# По умолчанию все пункты включены
for i in "${!MENU_ITEMS[@]}"; do
    MENU_ENABLED[$i]=1
done

# Вывод меню
for i in "${!MENU_ITEMS[@]}"; do
    if [[ ${MENU_ENABLED[$i]} -eq 1 ]]; then
        echo -e "  [$((i + 1))] ✓ ${MENU_ITEMS[$i]}"
    else
        echo -e "  [$((i + 1))] ✗ ${MENU_ITEMS[$i]}"
    fi
done
echo "  [0] → Перейти к выполнению"
echo ""

# Обработка выбора пунктов меню
while true; do
    CHOICE=$(read_from_terminal "${YELLOW}Введите номер пункта для переключения (0 для продолжения):${NC}")

    if [[ "$CHOICE" == "0" ]]; then
        break
    fi

    if [[ "$CHOICE" -ge 1 && "$CHOICE" -le ${#MENU_ITEMS[@]} ]]; then
        IDX=$((CHOICE - 1))
        if [[ ${MENU_ENABLED[$IDX]} -eq 1 ]]; then
            MENU_ENABLED[$IDX]=0
            echo -e "  [$CHOICE] ✗ ${MENU_ITEMS[$IDX]}"
        else
            MENU_ENABLED[$IDX]=1
            echo -e "  [$CHOICE] ✓ ${MENU_ITEMS[$IDX]}"
        fi
    else
        echo -e "${RED}Неверный номер, попробуйте снова${NC}"
    fi
done
echo ""

# ============================================================================
# Выполнение выбранных действий
# ============================================================================

# Переменные для хранения результатов
declare -A RESULTS
PROXY_HOST=""
PROXY_PORT=""
PROXY_USER=""
PROXY_PASS=""

# ============================================================================
# 1. Настройка системного прокси (для всех пользователей)
# ============================================================================
if [[ ${MENU_ENABLED[0]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}1. Настройка системного прокси (для всех пользователей)${NC}"
    log_header

    if confirm_action "Настроить системный прокси для всех пользователей?"; then
        PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера (например, proxy.company.com):${NC}")
        PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера (например, 8080):${NC}")
        PROXY_PROTOCOL=$(read_from_terminal "${YELLOW}Протокол (http/https/socks5, по умолчанию http):${NC}")

        if [[ -z "$PROXY_PROTOCOL" ]]; then
            PROXY_PROTOCOL="http"
        fi

        PROXY_URL="$PROXY_PROTOCOL://$PROXY_HOST:$PROXY_PORT"

        # Создание файла конфигурации
        cat > "/etc/profile.d/proxy.sh" << EOF
# Системные настройки прокси для всех пользователей
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export no_proxy="localhost,127.0.0.1,.local"
EOF

        chmod +x "/etc/profile.d/proxy.sh"
        check_success "Системный прокси настроен"

        RESULTS[1]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[1]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 2. Настройка прокси для текущего пользователя
# ============================================================================
if [[ ${MENU_ENABLED[1]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}2. Настройка прокси для текущего пользователя${NC}"
    log_header

    if confirm_action "Настроить прокси для текущего пользователя?"; then
        CURRENT_USER=$(whoami)
        USER_HOME=$(eval echo ~$CURRENT_USER)

        PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера:${NC}")
        PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера:${NC}")
        PROXY_PROTOCOL=$(read_from_terminal "${YELLOW}Протокол (по умолчанию http):${NC}")

        if [[ -z "$PROXY_PROTOCOL" ]]; then
            PROXY_PROTOCOL="http"
        fi

        PROXY_URL="$PROXY_PROTOCOL://$PROXY_HOST:$PROXY_PORT"

        # Добавление в ~/.bashrc
        cat >> "$USER_HOME/.bashrc" << EOF

# Настройки прокси (добавлено $(date +%Y-%m-%d))
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export no_proxy="localhost,127.0.0.1,.local"
EOF

        # Добавление в ~/.bash_profile если существует
        if [[ -f "$USER_HOME/.bash_profile" ]]; then
            cat >> "$USER_HOME/.bash_profile" << EOF

# Настройки прокси (добавлено $(date +%Y-%m-%d))
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export no_proxy="localhost,127.0.0.1,.local"
EOF
        fi

        chown "$CURRENT_USER:$(id -gn $CURRENT_USER)" "$USER_HOME/.bashrc"
        [[ -f "$USER_HOME/.bash_profile" ]] && chown "$CURRENT_USER:$(id -gn $CURRENT_USER)" "$USER_HOME/.bash_profile"

        check_success "Прокси для пользователя настроен"
        RESULTS[2]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[2]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 3. Настройка прокси для APT/DNF
# ============================================================================
if [[ ${MENU_ENABLED[2]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}3. Настройка прокси для APT/DNF${NC}"
    log_header

    if confirm_action "Настроить прокси для пакетного менеджера?"; then
        PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера:${NC}")
        PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера:${NC}")

        PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

        # Проверка наличия dnf
        if command -v dnf &> /dev/null; then
            # Настройка для DNF
            cat > "/etc/dnf/proxy.conf" << EOF
[main]
proxy=$PROXY_URL
EOF
            check_success "Прокси для DNF настроен"
        fi

        # Проверка наличия apt
        if command -v apt &> /dev/null; then
            # Настройка для APT
            cat > "/etc/apt/apt.conf.d/proxy.conf" << EOF
Acquire::http::Proxy "$PROXY_URL";
Acquire::https::Proxy "$PROXY_URL";
EOF
            check_success "Прокси для APT настроен"
        fi

        RESULTS[3]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[3]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 4. Настройка прокси для Git
# ============================================================================
if [[ ${MENU_ENABLED[3]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}4. Настройка прокси для Git${NC}"
    log_header

    if confirm_action "Настроить прокси для Git?"; then
        PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера:${NC}")
        PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера:${NC}")

        PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

        # Настройка для всех пользователей
        git config --system http.proxy "$PROXY_URL" 2>/dev/null || \
        git config --global http.proxy "$PROXY_URL"

        check_success "Прокси для Git настроен"
        RESULTS[4]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[4]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 5. Настройка прокси для wget/curl
# ============================================================================
if [[ ${MENU_ENABLED[4]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}5. Настройка прокси для wget/curl${NC}"
    log_header

    if confirm_action "Настроить прокси для wget/curl?"; then
        PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера:${NC}")
        PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера:${NC}")

        PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

        # Настройка для wget
        if [[ -f "/etc/wgetrc" ]]; then
            sed -i "s/^#http_proxy/http_proxy/" /etc/wgetrc 2>/dev/null || true
            sed -i "s|^http_proxy.*|http_proxy = $PROXY_URL|" /etc/wgetrc 2>/dev/null || true
        fi

        # Настройка для curl
        cat > "/etc/curlrc" << EOF
# Настройки прокси для curl
proxy = "$PROXY_URL"
EOF

        check_success "Прокси для wget/curl настроен"
        RESULTS[5]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[5]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 6. Настройка прокси для Docker
# ============================================================================
if [[ ${MENU_ENABLED[5]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}6. Настройка прокси для Docker${NC}"
    log_header

    if confirm_action "Настроить прокси для Docker?"; then
        PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера:${NC}")
        PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера:${NC}")

        PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

        # Создание директории
        mkdir -p /etc/systemd/system/docker.service.d

        # Создание конфигурации systemd для Docker
        cat > "/etc/systemd/system/docker.service.d/http-proxy.conf" << EOF
[Service]
Environment="HTTP_PROXY=$PROXY_URL"
Environment="HTTPS_PROXY=$PROXY_URL"
Environment="NO_PROXY=localhost,127.0.0.1,.local"
EOF

        # Перезагрузка systemd и Docker
        systemctl daemon-reload 2>/dev/null || true
        systemctl restart docker 2>/dev/null || true

        check_success "Прокси для Docker настроен"
        RESULTS[6]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[6]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 7. Настройка прокси для Snap
# ============================================================================
if [[ ${MENU_ENABLED[6]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}7. Настройка прокси для Snap${NC}"
    log_header

    if command -v snap &> /dev/null; then
        if confirm_action "Настроить прокси для Snap?"; then
            PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера:${NC}")
            PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера:${NC}")

            PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

            # Настройка прокси для snap
            snap set system proxy.http="$PROXY_URL"
            snap set system proxy.https="$PROXY_URL"

            check_success "Прокси для Snap настроен"
            RESULTS[7]="✓ Выполнено"
        else
            echo -e "${YELLOW}→ Пропущено${NC}"
            RESULTS[7]="✗ Пропущено"
        fi
    else
        log_warn "Snap не установлен"
        RESULTS[7]="✗ Snap не найден"
    fi
    echo ""
fi

# ============================================================================
# 8. Настройка исключений (no_proxy)
# ============================================================================
if [[ ${MENU_ENABLED[7]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}8. Настройка исключений (no_proxy)${NC}"
    log_header

    if confirm_action "Настроить исключения для прокси (no_proxy)?"; then
        NO_PROXY_LIST=$(read_from_terminal "${YELLOW}Список исключений (через запятую, например: localhost,192.168.0.0/16,.company.local):${NC}")

        if [[ -z "$NO_PROXY_LIST" ]]; then
            NO_PROXY_LIST="localhost,127.0.0.1,.local"
        fi

        # Обновление системного файла
        if [[ -f "/etc/profile.d/proxy.sh" ]]; then
            sed -i "s/^export no_proxy.*/export no_proxy=\"$NO_PROXY_LIST\"/" /etc/profile.d/proxy.sh
        fi

        # Обновление для текущего пользователя
        CURRENT_USER=$(whoami)
        USER_HOME=$(eval echo ~$CURRENT_USER)
        
        if grep -q "export no_proxy" "$USER_HOME/.bashrc" 2>/dev/null; then
            sed -i "s/^export no_proxy.*/export no_proxy=\"$NO_PROXY_LIST\"/" "$USER_HOME/.bashrc"
        else
            echo "export no_proxy=\"$NO_PROXY_LIST\"" >> "$USER_HOME/.bashrc"
        fi

        check_success "Исключения настроены"
        RESULTS[8]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[8]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 9. Создание скрипта быстрого переключения прокси
# ============================================================================
if [[ ${MENU_ENABLED[8]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}9. Создание скрипта быстрого переключения прокси${NC}"
    log_header

    if confirm_action "Создать скрипт быстрого переключения прокси?"; then
        PROXY_TOGGLE_SCRIPT="/usr/local/bin/proxy-toggle.sh"

        cat > "$PROXY_TOGGLE_SCRIPT" << 'EOF'
#!/bin/bash
#
# Скрипт быстрого переключения прокси
#

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Конфигурация (изменить под себя)
PROXY_HOST="${PROXY_HOST:-proxy.company.com}"
PROXY_PORT="${PROXY_PORT:-8080}"
PROXY_PROTOCOL="${PROXY_PROTOCOL:-http}"

NO_PROXY="localhost,127.0.0.1,.local"

# Функция включения прокси
enable_proxy() {
    local PROXY_URL="$PROXY_PROTOCOL://$PROXY_HOST:$PROXY_PORT"
    
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export ftp_proxy="$PROXY_URL"
    export no_proxy="$NO_PROXY"
    
    echo -e "${GREEN}✓ Прокси ВКЛЮЧЕН${NC}"
    echo -e "  URL: $PROXY_URL"
    echo -e "  Исключения: $NO_PROXY"
}

# Функция выключения прокси
disable_proxy() {
    unset http_proxy https_proxy ftp_proxy
    
    echo -e "${YELLOW}✓ Прокси ВЫКЛЮЧЕН${NC}"
}

# Функция проверки статуса
check_status() {
    if [[ -n "$http_proxy" ]]; then
        echo -e "${GREEN}Прокси включен:${NC} $http_proxy"
    else
        echo -e "${YELLOW}Прокси выключен${NC}"
    fi
}

# Основная логика
case "${1:-status}" in
    on|enable)
        enable_proxy
        ;;
    off|disable)
        disable_proxy
        ;;
    status|check)
        check_status
        ;;
    config)
        echo -e "${BLUE}Текущая конфигурация:${NC}"
        echo "  PROXY_HOST=$PROXY_HOST"
        echo "  PROXY_PORT=$PROXY_PORT"
        echo "  PROXY_PROTOCOL=$PROXY_PROTOCOL"
        ;;
    *)
        echo -e "${BLUE}Использование:${NC}"
        echo "  proxy-toggle.sh on      # включить прокси"
        echo "  proxy-toggle.sh off     # выключить прокси"
        echo "  proxy-toggle.sh status  # проверить статус"
        echo "  proxy-toggle.sh config  # показать конфигурацию"
        echo ""
        echo -e "${YELLOW}Совет:${NC} Добавьте алиасы в ~/.bash_aliases:"
        echo "  alias proxy-on='proxy-toggle.sh on'"
        echo "  alias proxy-off='proxy-toggle.sh off'"
        echo "  alias proxy-status='proxy-toggle.sh status'"
        ;;
esac
EOF

        chmod +x "$PROXY_TOGGLE_SCRIPT"

        # Создание алиасов
        if [[ -f "/etc/bash_aliases" ]]; then
            cat >> "/etc/bash_aliases" << 'EOF'

# Алиасы для управления прокси
alias proxy-on='proxy-toggle.sh on'
alias proxy-off='proxy-toggle.sh off'
alias proxy-status='proxy-toggle.sh status'
EOF
        fi

        echo -e "${GREEN}✓ Скрипт создан: $PROXY_TOGGLE_SCRIPT${NC}"
        echo ""
        echo -e "${BLUE}Использование:${NC}"
        echo "  proxy-toggle.sh on      # включить прокси"
        echo "  proxy-toggle.sh off     # выключить прокси"
        echo "  proxy-toggle.sh status  # проверить статус"

        RESULTS[9]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[9]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 10. Настройка прокси с авторизацией
# ============================================================================
if [[ ${MENU_ENABLED[9]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}10. Настройка прокси с авторизацией${NC}"
    log_header

    if confirm_action "Настроить прокси с авторизацией?"; then
        PROXY_HOST=$(read_from_terminal "${YELLOW}Адрес прокси-сервера:${NC}")
        PROXY_PORT=$(read_from_terminal "${YELLOW}Порт прокси-сервера:${NC}")
        PROXY_USER=$(read_from_terminal "${YELLOW}Имя пользователя:${NC}")
        PROXY_PASS=$(read_from_terminal "${YELLOW}Пароль:${NC}")

        # Экранирование спецсимволов в пароле
        PROXY_PASS_ESCAPED=$(echo "$PROXY_PASS" | sed 's/@/%40/g; s/:/%3A/g')
        PROXY_USER_ESCAPED=$(echo "$PROXY_USER" | sed 's/@/%40/g; s/:/%3A/g')

        PROXY_URL="http://$PROXY_USER_ESCAPED:$PROXY_PASS_ESCAPED@$PROXY_HOST:$PROXY_PORT"

        # Создание файла с учётными данными
        PROXY_CREDS_FILE="/etc/proxy-credentials"
        cat > "$PROXY_CREDS_FILE" << EOF
# Учётные данные для прокси
# Внимание: файл должен быть защищён!
PROXY_USER="$PROXY_USER"
PROXY_PASS="$PROXY_PASS"
PROXY_HOST="$PROXY_HOST"
PROXY_PORT="$PROXY_PORT"
EOF

        chmod 600 "$PROXY_CREDS_FILE"
        chown root:root "$PROXY_CREDS_FILE"

        # Настройка для текущего пользователя
        CURRENT_USER=$(whoami)
        USER_HOME=$(eval echo ~$CURRENT_USER)

        cat >> "$USER_HOME/.bashrc" << EOF

# Прокси с авторизацией (добавлено $(date +%Y-%m-%d))
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export no_proxy="localhost,127.0.0.1,.local"
EOF

        check_success "Прокси с авторизацией настроен"
        echo -e "${YELLOW}⚠ Учётные данные сохранены в: $PROXY_CREDS_FILE${NC}"
        echo -e "${YELLOW}⚠ Установлены права 600 (только root)${NC}"

        RESULTS[10]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[10]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 11. Проверка работы прокси
# ============================================================================
if [[ ${MENU_ENABLED[10]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}11. Проверка работы прокси${NC}"
    log_header

    if confirm_action "Выполнить проверку работы прокси?"; then
        echo -e "${BLUE}Проверка переменных окружения:${NC}"
        env | grep -i proxy | sed 's/^/  /'
        echo ""

        echo -e "${BLUE}Проверка подключения через curl:${NC}"
        if command -v curl &> /dev/null; then
            if [[ -n "$http_proxy" ]]; then
                echo "  Тест подключения к example.com..."
                if curl -s --connect-timeout 5 http://example.com > /dev/null 2>&1; then
                    echo -e "  ${GREEN}✓ Подключение успешно${NC}"
                else
                    echo -e "  ${RED}✗ Ошибка подключения${NC}"
                fi

                echo "  Проверка IP-адреса..."
                curl -s --connect-timeout 5 ifconfig.me 2>/dev/null | sed 's/^/  Ваш IP: /' || echo "  Не удалось определить IP"
            else
                echo -e "  ${YELLOW}Прокси не настроен, проверка невозможна${NC}"
            fi
        else
            echo -e "  ${YELLOW}curl не установлен${NC}"
        fi
        echo ""

        echo -e "${BLUE}Проверка подключения через wget:${NC}"
        if command -v wget &> /dev/null; then
            if [[ -n "$http_proxy" ]]; then
                echo "  Тест подключения к example.com..."
                if wget -q --spider --timeout=5 http://example.com 2>/dev/null; then
                    echo -e "  ${GREEN}✓ Подключение успешно${NC}"
                else
                    echo -e "  ${RED}✗ Ошибка подключения${NC}"
                fi
            else
                echo -e "  ${YELLOW}Прокси не настроен, проверка невозможна${NC}"
            fi
        else
            echo -e "  ${YELLOW}wget не установлен${NC}"
        fi

        RESULTS[11]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[11]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Настройка прокси-сервера завершена!"
log_header
echo ""
echo -e "${BLUE}Результаты выполнения:${NC}"
echo ""

for i in "${!MENU_ITEMS[@]}"; do
    if [[ -n "${RESULTS[$i]}" ]]; then
        printf "  %-60s %s\n" "${MENU_ITEMS[$i]}" "${RESULTS[$i]}"
    fi
done

echo ""
echo -e "${BLUE}Полезные команды:${NC}"
echo "  env | grep -i proxy              # проверить переменные прокси"
echo "  proxy-toggle.sh on               # включить прокси"
echo "  proxy-toggle.sh off              # выключить прокси"
echo "  proxy-toggle.sh status           # статус прокси"
echo "  curl ifconfig.me                 # проверить IP"
echo ""

if [[ -f "/usr/local/bin/proxy-toggle.sh" ]]; then
    echo -e "${GREEN}✓ Скрипт переключения прокси доступен: /usr/local/bin/proxy-toggle.sh${NC}"
fi

if [[ -f "/etc/profile.d/proxy.sh" ]]; then
    echo -e "${GREEN}✓ Системный прокси настроен: /etc/profile.d/proxy.sh${NC}"
fi

echo ""
echo -e "${YELLOW}Для применения настроек выполните:${NC}"
echo "  source /etc/profile.d/proxy.sh   # для системного прокси"
echo "  source ~/.bashrc                 # для пользовательского прокси"
echo ""
