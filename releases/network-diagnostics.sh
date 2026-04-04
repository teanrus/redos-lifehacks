#!/bin/bash
#
# Скрипт диагностики сетевых проблем для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/network-diagnostics.sh | sudo bash
# GitHub: https://github.com/teanrus/redos-lifehacks
#

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
        echo -e "${GREEN}✓ $1${NC}" >&2
    else
        echo -e "${RED}✗ Ошибка: $1${NC}" >&2
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

# Проверка ОС
if [[ -f /etc/os-release ]]; then
    OS_ID=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    if [[ "$OS_ID" != "redos" ]]; then
        log_warn "Скрипт разработан для РЕД ОС, обнаружена: $OS_ID"
        log_warn "Продолжение работы возможно, но не гарантируется"
    fi
fi

log_header
log_info "Диагностика сетевых проблем в РЕД ОС"
log_header
echo ""

# ============================================================================
# Информация о системе
# ============================================================================
log_header
echo -e "${BLUE}Информация о системе:${NC}"
log_header

if [ -f /etc/redos-release ]; then
    echo -e "  Версия ОС: ${CYAN}$(cat /etc/redos-release)${NC}"
fi
echo -e "  Ядро: ${CYAN}$(uname -r)${NC}"
echo -e "  Архитектура: ${CYAN}$(uname -m)${NC}"
echo -e "  Хостнейм: ${CYAN}$(hostname)${NC}"
echo ""

# ============================================================================
# Проверка сетевых интерфейсов
# ============================================================================
log_header
echo -e "${BLUE}Проверка сетевых интерфейсов:${NC}"
log_header
echo ""

# Список интерфейсов
echo -e "${CYAN}Сетевые интерфейсы:${NC}"

# Получение списка интерфейсов
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}')

for iface in $INTERFACES; do
    # Пропуск loopback
    if [[ "$iface" == "lo" ]]; then
        continue
    fi
    
    # Статус интерфейса
    if ip link show "$iface" 2>/dev/null | grep -q "state UP"; then
        STATUS="${GREEN}UP${NC}"
    else
        STATUS="${RED}DOWN${NC}"
    fi
    
    # IP адрес
    IP_ADDR=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ -n "$IP_ADDR" ]; then
        echo -e "  $STATUS $iface - ${CYAN}$IP_ADDR${NC}"
    else
        echo -e "  $STATUS $iface - ${YELLOW}нет IP${NC}"
    fi
done
echo ""

# Информация о драйверах
echo -e "${CYAN}Драйверы:${NC}"
for iface in $INTERFACES; do
    if [[ "$iface" == "lo" ]]; then
        continue
    fi
    
    # Получение информации о драйвере
    DRIVER=$(ethtool -i "$iface" 2>/dev/null | grep "driver:" | awk '{print $2}')
    if [ -n "$DRIVER" ]; then
        echo "  $iface: $DRIVER"
    else
        # Для Wi-Fi адаптеров
        DRIVER=$(lspci -k 2>/dev/null | grep -A 3 -i network | grep -i "kernel driver" | awk -F': ' '{print $2}')
        if [ -n "$DRIVER" ]; then
            echo "  $iface: $DRIVER (wireless)"
        else
            echo "  $iface: ${YELLOW}не определён${NC}"
        fi
    fi
done
echo ""

# ============================================================================
# Проверка DNS
# ============================================================================
log_header
echo -e "${BLUE}Проверка DNS:${NC}"
log_header
echo ""

DNS_ISSUES=0

# Проверка /etc/resolv.conf
if [ -f /etc/resolv.conf ]; then
    echo -e "${GREEN}✓${NC} /etc/resolv.conf существует"
    
    # Получение DNS серверов
    DNS_SERVERS=$(grep -E "^nameserver" /etc/resolv.conf | awk '{print $2}')
    if [ -n "$DNS_SERVERS" ]; then
        echo -e "  DNS серверы: ${CYAN}$(echo $DNS_SERVERS | tr '\n' ' ')${NC}"
    else
        echo -e "  ${YELLOW}⚠ DNS серверы не настроены${NC}"
        DNS_ISSUES=1
    fi
else
    echo -e "${RED}✗${NC} /etc/resolv.conf не найден"
    DNS_ISSUES=1
fi
echo ""

# Проверка разрешения имён
echo -e "${CYAN}Разрешение имён:${NC}"

# Проверка ping до IP
if ping -c 2 -W 2 8.8.8.8 &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} ping 8.8.8.8: OK"
else
    echo -e "  ${RED}✗${NC} ping 8.8.8.8: ${YELLOW}недоступен${NC}"
fi

# Проверка разрешения доменного имени
if ping -c 2 -W 2 google.com &>/dev/null; then
    GOOGLE_IP=$(ping -c 1 google.com 2>/dev/null | head -1 | grep -oP '\(\K[^)]+')
    echo -e "  ${GREEN}✓${NC} google.com resolves to ${CYAN}$GOOGLE_IP${NC}"
else
    echo -e "  ${RED}✗${NC} google.com: ${YELLOW}не разрешается${NC}"
    DNS_ISSUES=1
fi
echo ""

# Предложение исправить DNS
if [ $DNS_ISSUES -eq 1 ]; then
    if confirm_action "Настроить DNS автоматически (Google DNS + Cloudflare)?"; then
        log_info "Настройка DNS..."
        
        # Резервное копирование
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Добавление DNS
        cat > /etc/resolv.conf << EOF
# DNS настройки (автоматически network-diagnostics.sh)
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF
        
        check_success "DNS настроены"
        
        # Проверка после настройки
        if ping -c 2 -W 2 google.com &>/dev/null; then
            GOOGLE_IP=$(ping -c 1 google.com 2>/dev/null | head -1 | grep -oP '\(\K[^)]+')
            echo -e "  ${GREEN}✓${NC} google.com теперь разрешается: ${CYAN}$GOOGLE_IP${NC}"
        fi
    fi
fi

# ============================================================================
# Проверка маршрутизации
# ============================================================================
log_header
echo -e "${BLUE}Проверка маршрутизации:${NC}"
log_header
echo ""

# Шлюз по умолчанию
DEFAULT_GATEWAY=$(ip route | grep default | awk '{print $3}')
if [ -n "$DEFAULT_GATEWAY" ]; then
    echo -e "  ${GREEN}✓${NC} Шлюз по умолчанию: ${CYAN}$DEFAULT_GATEWAY${NC}"
else
    echo -e "  ${RED}✗${NC} Шлюз по умолчанию: ${YELLOW}не настроен${NC}"
fi

# Количество маршрутов
ROUTE_COUNT=$(ip route | wc -l)
echo -e "  Маршрутов: ${CYAN}$ROUTE_COUNT${NC}"
echo ""

# Трассировка до 8.8.8.8
if [ -n "$DEFAULT_GATEWAY" ]; then
    echo -e "${CYAN}Трассировка до 8.8.8.8:${NC}"
    if command -v traceroute &>/dev/null; then
        traceroute -n -m 3 -w 1 8.8.8.8 2>/dev/null | head -5 | while read line; do
            echo "    $line"
        done
    else
        # Если traceroute нет, используем tracepath
        if command -v tracepath &>/dev/null; then
            tracepath -n -m 3 8.8.8.8 2>/dev/null | head -5 | while read line; do
                echo "    $line"
            done
        else
            echo "    ${YELLOW}traceroute/tracepath не установлен${NC}"
        fi
    fi
    echo ""
fi

# ============================================================================
# Проверка брандмауэра
# ============================================================================
log_header
echo -e "${BLUE}Проверка брандмауэра:${NC}"
log_header
echo ""

FIREWALL_ISSUES=0

# Проверка firewalld
if systemctl is-active firewalld &>/dev/null; then
    echo -e "  Статус: ${GREEN}active${NC}"
    
    # Список сервисов
    SERVICES=$(firewall-cmd --list-services 2>/dev/null | tr ' ' ', ')
    if [ -n "$SERVICES" ]; then
        echo -e "  Сервисы: ${CYAN}$SERVICES${NC}"
    fi
    
    # Список портов
    PORTS=$(firewall-cmd --list-ports 2>/dev/null | tr ' ' ', ')
    if [ -n "$PORTS" ]; then
        echo -e "  Порты: ${CYAN}$PORTS${NC}"
    fi
else
    echo -e "  Статус: ${YELLOW}не активен${NC}"
fi
echo ""

# Проверка распространённых портов
echo -e "${CYAN}Проверка распространённых портов:${NC}"

for port in 22 80 443 3306; do
    if firewall-cmd --query-port=$port/tcp 2>/dev/null | grep -q yes; then
        echo -e "  ${GREEN}✓${NC} Порт $port/tcp открыт"
    else
        echo -e "  ${YELLOW}⚠${NC} Порт $port/tcp закрыт"
        if [ $port -eq 3306 ]; then
            FIREWALL_ISSUES=1
        fi
    fi
done
echo ""

# Предложение открыть порт 3306
if [ $FIREWALL_ISSUES -eq 1 ]; then
    if confirm_action "Открыть порт 3306 (MySQL)?"; then
        log_info "Открытие порта 3306..."
        firewall-cmd --permanent --add-port=3306/tcp
        firewall-cmd --reload
        check_success "Порт 3306 открыт"
    fi
fi

# ============================================================================
# Проверка NetworkManager
# ============================================================================
log_header
echo -e "${BLUE}Проверка NetworkManager:${NC}"
log_header
echo ""

if systemctl is-active NetworkManager &>/dev/null; then
    echo -e "  Статус: ${GREEN}active${NC}"
else
    echo -e "  Статус: ${RED}не активен${NC}"
    if confirm_action "Запустить NetworkManager?"; then
        log_info "Запуск NetworkManager..."
        systemctl start NetworkManager
        check_success "NetworkManager запущен"
    fi
fi

# Активные подключения
echo ""
echo -e "${CYAN}Активные подключения:${NC}"
nmcli connection show --active 2>/dev/null | head -10 | while read line; do
    echo "  $line"
done
echo ""

# ============================================================================
# Проверка Wi-Fi (если есть)
# ============================================================================
WIFI_ADAPTER=$(iwconfig 2>/dev/null | grep -v "no wireless" | head -1 || echo "")

if [ -n "$WIFI_ADAPTER" ]; then
    log_header
    echo -e "${BLUE}Проверка Wi-Fi:${NC}"
    log_header
    echo ""
    
    # Проверка блокировки
    RFKILL_STATUS=$(rfkill list wifi 2>/dev/null | grep -i "blocked" || echo "")
    if echo "$RFKILL_STATUS" | grep -q "yes"; then
        echo -e "  ${RED}✗${NC} Wi-Fi заблокирован (rfkill)"
        if confirm_action "Разблокировать Wi-Fi?"; then
            rfkill unblock wifi
            check_success "Wi-Fi разблокирован"
        fi
    else
        echo -e "  ${GREEN}✓${NC} Wi-Fi не заблокирован"
    fi
    
    # Список доступных сетей
    echo ""
    echo -e "${CYAN}Доступные сети:${NC}"
    if command -v nmcli &>/dev/null; then
        nmcli device wifi list 2>/dev/null | head -10 | while read line; do
            echo "  $line"
        done
    fi
    echo ""
fi

# ============================================================================
# Диагностика проблем
# ============================================================================
log_header
echo -e "${BLUE}Диагностика проблем:${NC}"
log_header
echo ""

ISSUES_FOUND=0

# Проверка физического подключения
for iface in $INTERFACES; do
    if [[ "$iface" == "lo" ]]; then
        continue
    fi
    
    if ip link show "$iface" 2>/dev/null | grep -q "state DOWN"; then
        # Проверка кабеля для Ethernet
        if ethtool "$iface" 2>/dev/null | grep -q "Link detected: no"; then
            echo -e "  ${RED}✗${NC} $iface: ${YELLOW}кабель не подключен${NC}"
            ISSUES_FOUND=1
        else
            echo -e "  ${RED}✗${NC} $iface: ${YELLOW}интерфейс выключен${NC}"
            ISSUES_FOUND=1
        fi
    fi
done

# Проверка DNS
if ! ping -c 1 -W 2 google.com &>/dev/null; then
    echo -e "  ${RED}✗${NC} DNS: ${YELLOW}не работает разрешение имён${NC}"
    ISSUES_FOUND=1
fi

# Проверка шлюза
if [ -z "$DEFAULT_GATEWAY" ]; then
    echo -e "  ${RED}✗${NC} Маршрутизация: ${YELLOW}нет шлюза по умолчанию${NC}"
    ISSUES_FOUND=1
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} Проблем не обнаружено"
fi
echo ""

# ============================================================================
# Рекомендации
# ============================================================================
if [ $ISSUES_FOUND -gt 0 ]; then
    log_header
    echo -e "${BLUE}Рекомендации:${NC}"
    log_header
    echo ""
    
    echo -e "${YELLOW}Полезные команды для решения проблем:${NC}"
    echo "  nmcli connection show          # показать подключения"
    echo "  nmcli device wifi list         # список Wi-Fi сетей"
    echo "  firewall-cmd --list-all        # правила брандмауэра"
    echo "  ip route show                  # таблица маршрутизации"
    echo "  journalctl -u NetworkManager   # логи NetworkManager"
    echo ""
    
    if confirm_action "Выполнить сброс сети?"; then
        log_info "Сброс сети..."
        nmcli networking off
        sleep 2
        nmcli networking on
        check_success "Сеть перезапущена"
    fi
fi

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Диагностика завершена!"
log_header
echo ""

echo -e "${GREEN}Результаты:${NC}"
echo "  Сетевые интерфейсы: $([ $ISSUES_FOUND -eq 0 ] && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Требует внимания${NC}")"
echo "  DNS: $(! ping -c 1 -W 2 google.com &>/dev/null && echo -e "${YELLOW}Требует внимания${NC}" || echo -e "${GREEN}OK${NC}")"
echo "  Маршрутизация: $([ -z "$DEFAULT_GATEWAY" ] && echo -e "${YELLOW}Требует внимания${NC}" || echo -e "${GREEN}OK${NC}")"
echo ""

echo -e "${BLUE}Полезные команды:${NC}"
echo "  nmcli connection show          # показать подключения"
echo "  nmcli device wifi list         # список Wi-Fi сетей"
echo "  firewall-cmd --list-all        # правила брандмауэра"
echo "  ip route show                  # таблица маршрутизации"
echo "  traceroute -n 8.8.8.8          # трассировка"
echo ""

log_info "Готово!"
