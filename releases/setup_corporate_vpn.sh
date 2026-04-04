#!/bin/bash
#
# Скрипт настройки корпоративного VPN для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_corporate_vpn.sh | sudo bash
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
log_info "Настройка корпоративного VPN в РЕД ОС"
log_header
echo ""

# ============================================================================
# Проверка установленных пакетов
# ============================================================================
log_info "Проверка установленных пакетов..."

declare -A INSTALLED_PACKAGES

if command -v nmcli &> /dev/null; then
    INSTALLED_PACKAGES["NetworkManager"]="установлен"
else
    INSTALLED_PACKAGES["NetworkManager"]="не установлен"
fi

if command -v openvpn &> /dev/null; then
    INSTALLED_PACKAGES["OpenVPN"]="установлен"
else
    INSTALLED_PACKAGES["OpenVPN"]="не установлен"
fi

if command -v wg &> /dev/null; then
    INSTALLED_PACKAGES["WireGuard"]="установлен"
else
    INSTALLED_PACKAGES["WireGuard"]="не установлен"
fi

if command -v anyconnect &> /dev/null || [[ -d /opt/cisco/anyconnect ]]; then
    INSTALLED_PACKAGES["Cisco AnyConnect"]="установлен"
else
    INSTALLED_PACKAGES["Cisco AnyConnect"]="не установлен"
fi

for pkg in "${!INSTALLED_PACKAGES[@]}"; do
    if [[ "${INSTALLED_PACKAGES[$pkg]}" == "установлен" ]]; then
        echo -e "  ${GREEN}✓${NC} $pkg"
    else
        echo -e "  ${RED}✗${NC} $pkg"
    fi
done
echo ""

# ============================================================================
# Предложение установить недостающие пакеты
# ============================================================================
MISSING_PACKAGES=()

if ! command -v nmcli &> /dev/null; then
    MISSING_PACKAGES+=("NetworkManager")
fi

echo -e "${BLUE}Выберите тип VPN для настройки:${NC}"
echo "  1) OpenVPN"
echo "  2) WireGuard"
echo "  3) Cisco AnyConnect"
echo "  4) Пропустить установку пакетов"
echo ""

VPN_TYPE_CHOICE=$(read_from_terminal "${YELLOW}Ваш выбор (1-4):${NC}")

case $VPN_TYPE_CHOICE in
    1)
        if [[ "${INSTALLED_PACKAGES["OpenVPN"]}" == "не установлен" ]]; then
            if confirm_action "Установить OpenVPN?"; then
                dnf install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
                check_success "Установка OpenVPN"
            fi
        fi
        ;;
    2)
        if [[ "${INSTALLED_PACKAGES["WireGuard"]}" == "не установлен" ]]; then
            if confirm_action "Установить WireGuard?"; then
                dnf install -y wireguard-tools
                check_success "Установка WireGuard"
            fi
        fi
        ;;
    3)
        log_warn "Cisco AnyConnect требует ручной установки .rpm пакета"
        log_warn "Скачайте пакет с официального сайта Cisco"
        ;;
esac
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
    "Настройка OpenVPN подключения"
    "Настройка WireGuard подключения"
    "Настройка автозапуска VPN"
    "Настройка DNS для VPN"
    "Настройка split-tunneling"
    "Настройка брандмауэра (firewalld)"
    "Создание скрипта быстрого подключения"
    "Настройка логирования VPN"
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
VPN_CONNECTION_NAME=""

# ============================================================================
# 1. Настройка OpenVPN подключения
# ============================================================================
if [[ ${MENU_ENABLED[0]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}1. Настройка OpenVPN подключения${NC}"
    log_header

    if confirm_action "Настроить OpenVPN подключение?"; then
        # Запрос параметров подключения
        VPN_SERVER=$(read_from_terminal "${YELLOW}Адрес VPN сервера:${NC}")
        VPN_NAME=$(read_from_terminal "${YELLOW}Название подключения (по умолчанию CorpVPN):${NC}")
        
        if [[ -z "$VPN_NAME" ]]; then
            VPN_NAME="CorpVPN"
        fi
        VPN_CONNECTION_NAME="$VPN_NAME"

        # Создание подключения через nmcli
        nmcli connection add type openvpn con-name "$VPN_NAME" \
            ifname "*" \
            vpn.service-type "org.freedesktop.NetworkManager.openvpn" \
            vpn.data "gateway=$VPN_SERVER,connection-type=password" \
            ipv4.method auto \
            ipv6.method ignore 2>/dev/null

        check_success "OpenVPN подключение создано"

        # Запрос сертификатов (опционально)
        if confirm_action "Использовать сертификаты (CA, клиент)?"; then
            CA_CERT=$(read_from_terminal "${YELLOW}Путь к CA сертификату:${NC}")
            CLIENT_CERT=$(read_from_terminal "${YELLOW}Путь к клиентскому сертификату:${NC}")
            CLIENT_KEY=$(read_from_terminal "${YELLOW}Путь к приватному ключу:${NC}")

            nmcli connection modify "$VPN_NAME" \
                vpn.ca "$CA_CERT" \
                vpn.cert "$CLIENT_CERT" \
                vpn.key "$CLIENT_KEY" 2>/dev/null

            check_success "Сертификаты настроены"
        fi

        RESULTS[1]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[1]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 2. Настройка WireGuard подключения
# ============================================================================
if [[ ${MENU_ENABLED[1]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}2. Настройка WireGuard подключения${NC}"
    log_header

    if confirm_action "Настроить WireGuard подключение?"; then
        WG_DIR="/etc/wireguard"
        mkdir -p "$WG_DIR"

        # Запрос параметров
        WG_INTERFACE=$(read_from_terminal "${YELLOW}Имя интерфейса (по умолчанию wg0):${NC}")
        if [[ -z "$WG_INTERFACE" ]]; then
            WG_INTERFACE="wg0"
        fi

        WG_CONF="$WG_DIR/$WG_INTERFACE.conf"

        if [[ -f "$WG_CONF" ]]; then
            log_warn "Конфигурация уже существует"
            if ! confirm_action "Перезаписать существующую конфигурацию?"; then
                echo -e "${YELLOW}→ Пропущено${NC}"
                RESULTS[2]="✗ Пропущено"
                echo ""
                continue
            fi
        fi

        # Запрос параметров WireGuard
        WG_PRIVATE_KEY=$(read_from_terminal "${YELLOW}Приватный ключ (или оставьте пустым для генерации):${NC}")
        if [[ -z "$WG_PRIVATE_KEY" ]]; then
            WG_PRIVATE_KEY=$(wg genkey 2>/dev/null || echo "GENERATE_ME")
        fi

        WG_PUBLIC_KEY=$(read_from_terminal "${YELLOW}Публичный ключ сервера:${NC}")
        WG_SERVER_IP=$(read_from_terminal "${YELLOW}IP адрес сервера:${NC}")
        WG_SERVER_PORT=$(read_from_terminal "${YELLOW}Порт сервера (по умолчанию 51820):${NC}")
        if [[ -z "$WG_SERVER_PORT" ]]; then
            WG_SERVER_PORT="51820"
        fi
        WG_CLIENT_IP=$(read_from_terminal "${YELLOW}Ваш IP адрес в VPN сети (например, 10.0.0.2/24):${NC}")
        WG_DNS=$(read_from_terminal "${YELLOW}DNS серверы (через запятую, например 8.8.8.8,1.1.1.1):${NC}")

        # Создание конфигурации
        cat > "$WG_CONF" << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_CLIENT_IP
DNS = $WG_DNS

[Peer]
PublicKey = $WG_PUBLIC_KEY
Endpoint = $WG_SERVER_IP:$WG_SERVER_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

        chmod 600 "$WG_CONF"
        check_success "Конфигурация WireGuard создана"

        RESULTS[2]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[2]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 3. Настройка автозапуска VPN
# ============================================================================
if [[ ${MENU_ENABLED[2]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}3. Настройка автозапуска VPN${NC}"
    log_header

    if confirm_action "Настроить автозапуск VPN при входе в систему?"; then
        CURRENT_USER=$(whoami)
        USER_HOME=$(eval echo ~$CURRENT_USER)
        AUTOSTART_DIR="$USER_HOME/.config/autostart"

        mkdir -p "$AUTOSTART_DIR"

        # Создание desktop файла для автозапуска
        cat > "$AUTOSTART_DIR/vpn-autostart.desktop" << EOF
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/vpn-connect.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=VPN Auto Connect
Comment=Автоматическое подключение к корпоративному VPN
EOF

        # Создание скрипта подключения
        cat > "/usr/local/bin/vpn-connect.sh" << 'EOF'
#!/bin/bash
# Скрипт автозапуска VPN
sleep 10
nmcli connection up "CorpVPN" --ask 2>/dev/null || true
EOF

        chmod +x "/usr/local/bin/vpn-connect.sh"
        chmod +x "$AUTOSTART_DIR/vpn-autostart.desktop"

        check_success "Автозапуск VPN настроен"
        RESULTS[3]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[3]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 4. Настройка DNS для VPN
# ============================================================================
if [[ ${MENU_ENABLED[3]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}4. Настройка DNS для VPN${NC}"
    log_header

    if confirm_action "Настроить DNS для VPN подключения?"; then
        if [[ -z "$VPN_CONNECTION_NAME" ]]; then
            VPN_CONNECTION_NAME=$(read_from_terminal "${YELLOW}Название VPN подключения:${NC}")
        fi

        DNS_SERVERS=$(read_from_terminal "${YELLOW}DNS серверы (через пробел, например 10.0.0.1 10.0.0.2):${NC}")

        if [[ -n "$DNS_SERVERS" ]]; then
            nmcli connection modify "$VPN_CONNECTION_NAME" \
                ipv4.ignore-auto-dns yes \
                ipv4.dns "$DNS_SERVERS" 2>/dev/null

            check_success "DNS настроены"
        else
            log_warn "DNS серверы не указаны"
        fi

        RESULTS[4]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[4]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 5. Настройка split-tunneling
# ============================================================================
if [[ ${MENU_ENABLED[4]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}5. Настройка split-tunneling (раздельное туннелирование)${NC}"
    log_header

    if confirm_action "Настроить split-tunneling?"; then
        if [[ -z "$VPN_CONNECTION_NAME" ]]; then
            VPN_CONNECTION_NAME=$(read_from_terminal "${YELLOW}Название VPN подключения:${NC}")
        fi

        CORP_NETWORK=$(read_from_terminal "${YELLOW}Корпоративная сеть (например, 192.168.0.0/24):${NC}")
        CORP_GATEWAY=$(read_from_terminal "${YELLOW}Шлюз корпоративной сети (опционально):${NC}")

        if [[ -n "$CORP_NETWORK" ]]; then
            # Настройка маршрутов только для корпоративной сети
            nmcli connection modify "$VPN_CONNECTION_NAME" \
                ipv4.routes "$CORP_NETWORK ${CORP_GATEWAY:-}" \
                ipv4.route-metric 100 \
                ipv4.never-default yes 2>/dev/null

            check_success "Split-tunneling настроен"
            RESULTS[5]="✓ Выполнено"
        else
            log_warn "Корпоративная сеть не указана"
            RESULTS[5]="✗ Пропущено"
        fi
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[5]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 6. Настройка брандмауэра (firewalld)
# ============================================================================
if [[ ${MENU_ENABLED[5]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}6. Настройка брандмауэра (firewalld)${NC}"
    log_header

    if command -v firewall-cmd &> /dev/null; then
        if confirm_action "Добавить правила для VPN в firewalld?"; then
            # OpenVPN
            firewall-cmd --permanent --add-service=openvpn 2>/dev/null || true
            firewall-cmd --permanent --add-port=1194/udp 2>/dev/null || true

            # WireGuard
            firewall-cmd --permanent --add-port=51820/udp 2>/dev/null || true

            # Маскарадинг для VPN
            firewall-cmd --permanent --add-masquerade 2>/dev/null || true

            # Применяем изменения
            firewall-cmd --reload 2>/dev/null || true

            check_success "Правила firewalld добавлены"
            RESULTS[6]="✓ Выполнено"
        else
            echo -e "${YELLOW}→ Пропущено${NC}"
            RESULTS[6]="✗ Пропущено"
        fi
    else
        log_warn "firewalld не установлен или не запущен"
        RESULTS[6]="✗ firewalld не найден"
    fi
    echo ""
fi

# ============================================================================
# 7. Создание скрипта быстрого подключения
# ============================================================================
if [[ ${MENU_ENABLED[6]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}7. Создание скрипта быстрого подключения${NC}"
    log_header

    if confirm_action "Создать скрипт быстрого подключения к VPN?"; then
        VPN_QUICK_SCRIPT="/usr/local/bin/vpn-quick.sh"

        cat > "$VPN_QUICK_SCRIPT" << 'EOF'
#!/bin/bash
#
# Скрипт быстрого подключения к корпоративному VPN
#

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Название подключения (можно изменить)
VPN_NAME="${1:-CorpVPN}"

echo -e "${GREEN}Подключение к VPN: $VPN_NAME${NC}"

# Проверка статуса
if nmcli connection show --active | grep -q "$VPN_NAME"; then
    echo -e "${YELLOW}VPN уже подключен${NC}"
    read -p "Переподключить? (y/n): " answer
    if [[ ! $answer =~ ^[Yy]$ ]]; then
        exit 0
    fi
    nmcli connection down "$VPN_NAME" 2>/dev/null || true
fi

# Подключение
echo -e "${GREEN}Подключение...${NC}"
if nmcli connection up "$VPN_NAME" 2>/dev/null; then
    echo -e "${GREEN}✓ VPN подключен успешно${NC}"
    
    # Проверка подключения
    echo -e "${YELLOW}Проверка маршрутов...${NC}"
    ip route | grep -E "^(default|10\.|192\.168\.)" | head -5
    
    echo -e "${YELLOW}Проверка DNS...${NC}"
    cat /etc/resolv.conf | grep nameserver | head -3
else
    echo -e "${RED}✗ Ошибка подключения${NC}"
    exit 1
fi
EOF

        chmod +x "$VPN_QUICK_SCRIPT"

        # Скрипт отключения
        VPN_DISCONNECT_SCRIPT="/usr/local/bin/vpn-disconnect.sh"
        cat > "$VPN_DISCONNECT_SCRIPT" << 'EOF'
#!/bin/bash
# Скрипт отключения от VPN

VPN_NAME="${1:-CorpVPN}"
nmcli connection down "$VPN_NAME" 2>/dev/null
echo "VPN отключен"
EOF

        chmod +x "$VPN_DISCONNECT_SCRIPT"

        echo -e "${GREEN}✓ Скрипты созданы:${NC}"
        echo "  - vpn-quick.sh      # быстрое подключение"
        echo "  - vpn-disconnect.sh # отключение"
        echo ""
        echo -e "${BLUE}Использование:${NC}"
        echo "  vpn-quick.sh [название_подключения]"
        echo "  vpn-disconnect.sh [название_подключения]"

        RESULTS[7]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[7]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 8. Настройка логирования VPN
# ============================================================================
if [[ ${MENU_ENABLED[7]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}8. Настройка логирования VPN${NC}"
    log_header

    if confirm_action "Настроить логирование VPN подключений?"; then
        # Создание конфигурации rsyslog для VPN
        RSYSLOG_VPN="/etc/rsyslog.d/vpn.conf"

        cat > "$RSYSLOG_VPN" << 'EOF'
# Логирование VPN подключений
:programname, isequal, "nmcli" /var/log/vpn.log
:programname, isequal, "openvpn" /var/log/openvpn.log
& stop
EOF

        # Создание файла лога
        touch /var/log/vpn.log
        chmod 640 /var/log/vpn.log
        chown root:adm /var/log/vpn.log

        # Перезапуск rsyslog
        systemctl restart rsyslog 2>/dev/null || true

        # Создание скрипта просмотра логов
        VPN_LOG_SCRIPT="/usr/local/bin/vpn-logs.sh"
        cat > "$VPN_LOG_SCRIPT" << 'EOF'
#!/bin/bash
# Просмотр логов VPN

echo "=== Последние записи VPN логов ==="
tail -50 /var/log/vpn.log 2>/dev/null || journalctl -u NetworkManager -n 50

echo ""
echo "=== Active VPN connections ==="
nmcli connection show --active | grep -i vpn || echo "Нет активных VPN подключений"
EOF

        chmod +x "$VPN_LOG_SCRIPT"

        echo -e "${GREEN}✓ Логирование настроено${NC}"
        echo "  Логи: /var/log/vpn.log"
        echo "  Просмотр: vpn-logs.sh"

        RESULTS[8]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[8]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Настройка корпоративного VPN завершена!"
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
echo "  nmcli connection show              # список подключений"
echo "  nmcli connection up CorpVPN        # подключить VPN"
echo "  nmcli connection down CorpVPN      # отключить VPN"
echo "  vpn-quick.sh                       # быстрое подключение"
echo "  vpn-logs.sh                        # просмотр логов"
echo "  journalctl -u NetworkManager -f    # логи NetworkManager"
echo ""

if [[ -f "/usr/local/bin/vpn-quick.sh" ]]; then
    echo -e "${GREEN}✓ Скрипт быстрого подключения доступен: /usr/local/bin/vpn-quick.sh${NC}"
fi

echo ""
