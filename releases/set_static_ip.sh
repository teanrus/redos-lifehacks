#!/bin/bash
#
# Скрипт настройки статического IP-адреса для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/set_static_ip.sh | sudo bash
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

# Проверка связи с шлюзом
check_connectivity() {
    local gateway=$1
    if ping -c 2 -W 1 "$gateway" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Проверка прав root
# ============================================================================
if [[ $EUID -ne 0 ]]; then
    log_error "Скрипт должен выполняться от имени root"
    exit 1
fi

# Проверка наличия NetworkManager
if ! command -v nmcli &> /dev/null; then
    log_error "NetworkManager (nmcli) не найден. Установите пакет NetworkManager"
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
log_info "Настройка статического IP-адреса в РЕД ОС"
log_header
echo ""

# ============================================================================
# Получение списка сетевых подключений
# ============================================================================
declare -a CONNECTIONS_ARRAY
CONNECTIONS_ARRAY=($(nmcli -t -f NAME connection show))

echo -e "${BLUE}Обнаружены сетевые подключения:${NC}"
if [[ ${#CONNECTIONS_ARRAY[@]} -eq 0 ]]; then
    echo "  (нет активных подключений)"
else
    for i in "${!CONNECTIONS_ARRAY[@]}"; do
        # Получаем тип подключения и статус
        CONN_NAME="${CONNECTIONS_ARRAY[$i]}"
        CONN_TYPE=$(nmcli -t -f TYPE connection show "$CONN_NAME" 2>/dev/null | head -1)
        CONN_DEVICE=$(nmcli -t -f DEVICE connection show "$CONN_NAME" 2>/dev/null | head -1)
        
        if [[ "$CONN_DEVICE" != "--" ]]; then
            echo -e "  $((i + 1))) ${CYAN}$CONN_NAME${NC} (тип: $CONN_TYPE, устройство: $CONN_DEVICE)"
        else
            echo "  $((i + 1))) $CONN_NAME (тип: $CONN_TYPE, не активно)"
        fi
    done
fi
echo ""

# ============================================================================
# Выбор подключения для настройки
# ============================================================================
echo -e "${BLUE}Выберите подключение для настройки статического IP:${NC}"
echo "  0) Пропустить настройку"
echo ""

CONN_CHOICE=$(read_from_terminal "${YELLOW}Ваш выбор (0-${#CONNECTIONS_ARRAY[@]}):${NC}")

if [[ "$CONN_CHOICE" == "0" ]]; then
    log_info "Настройка отменена пользователем"
    exit 0
fi

if [[ "$CONN_CHOICE" -lt 1 || "$CONN_CHOICE" -gt ${#CONNECTIONS_ARRAY[@]} ]]; then
    log_error "Неверный номер подключения"
    exit 1
fi

TARGET_CONNECTION="${CONNECTIONS_ARRAY[$((CONN_CHOICE - 1))]}"
echo -e "${GREEN}→ Выбрано подключение: $TARGET_CONNECTION${NC}"
echo ""

# ============================================================================
# Получение текущих настроек сети
# ============================================================================
log_header
echo -e "${BLUE}Текущие настройки подключения:${NC}"
log_header

CURRENT_IP=$(nmcli -t -f IP4.ADDRESS connection show "$TARGET_CONNECTION" 2>/dev/null | head -1)
CURRENT_GW=$(nmcli -t -f IP4.GATEWAY connection show "$TARGET_CONNECTION" 2>/dev/null | head -1)
CURRENT_DNS=$(nmcli -t -f IP4.DNS connection show "$TARGET_CONNECTION" 2>/dev/null | head -1)
CURRENT_METHOD=$(nmcli -t -f IP4.METHOD connection show "$TARGET_CONNECTION" 2>/dev/null | head -1)

echo "  IP адрес:     ${CURRENT_IP:-не настроен}"
echo "  Шлюз:         ${CURRENT_GW:-не настроен}"
echo "  DNS серверы:  ${CURRENT_DNS:-не настроены}"
echo "  Метод:        ${CURRENT_METHOD:-неизвестно}"
echo ""

# Предложение создать резервную копию
if confirm_action "Создать резервную копию текущих настроек?"; then
    BACKUP_DIR="$HOME/network_backups"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/${TARGET_CONNECTION}.$(date +%Y%m%d_%H%M%S).backup"
    
    nmcli connection show "$TARGET_CONNECTION" > "$BACKUP_FILE"
    check_success "Резервная копия сохранена в $BACKUP_FILE"
fi
echo ""

# ============================================================================
# Ввод новых настроек
# ============================================================================
log_header
echo -e "${BLUE}Ввод новых настроек сети:${NC}"
log_header

# Автоматическое определение текущей подсети
if [[ -n "$CURRENT_IP" ]]; then
    CURRENT_SUBNET=$(echo "$CURRENT_IP" | cut -d'/' -f1 | sed 's/\.[0-9]*$/\.0/')
    echo -e "${CYAN}Подсказка: Текущая подсеть: ${CURRENT_SUBNET}0/24${NC}"
fi
echo ""

# Запрос IP адреса
while true; do
    STATIC_IP=$(read_from_terminal "${YELLOW}Введите статический IP адрес (например, 192.168.1.100):${NC}")
    
    # Проверка формата IP
    if [[ $STATIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        break
    else
        echo -e "${RED}Неверный формат IP адреса. Попробуйте снова.${NC}"
    fi
done

# Запрос маски подсети
echo ""
echo "Выберите маску подсети:"
echo "  1) 255.255.255.0 (/24) - до 254 хостов"
echo "  2) 255.255.0.0 (/16) - до 65534 хостов"
echo "  3) 255.0.0.0 (/8) - до 16777214 хостов"
echo "  4) Ввести свою маску"
echo ""

MASK_CHOICE=$(read_from_terminal "${YELLOW}Ваш выбор (1-4):${NC}")

case $MASK_CHOICE in
    1) CIDR_MASK="24" ;;
    2) CIDR_MASK="16" ;;
    3) CIDR_MASK="8" ;;
    4) 
        CIDR_MASK=$(read_from_terminal "${YELLOW}Введите CIDR маску (например, 24):${NC}")
        ;;
    *) 
        log_warn "Неверный выбор, используется маска по умолчанию /24"
        CIDR_MASK="24"
        ;;
esac

# Запрос шлюза
echo ""
DEFAULT_GW=$(echo "$STATIC_IP" | sed 's/\.[0-9]*$/\.1/')
GATEWAY=$(read_from_terminal "${YELLOW}Введите шлюз (по умолчанию $DEFAULT_GW):${NC}")
if [[ -z "$GATEWAY" ]]; then
    GATEWAY="$DEFAULT_GW"
fi

# Запрос DNS серверов
echo ""
echo -e "${CYAN}Популярные DNS серверы:${NC}"
echo "  1) Google DNS (8.8.8.8, 8.8.4.4)"
echo "  2) Cloudflare DNS (1.1.1.1, 1.0.0.1)"
echo "  3) Яндекс DNS (77.88.8.8, 77.88.8.1)"
echo "  4) Ввести свои DNS серверы"
echo ""

DNS_CHOICE=$(read_from_terminal "${YELLOW}Ваш выбор (1-4):${NC}")

case $DNS_CHOICE in
    1) DNS_SERVERS="8.8.8.8 8.8.4.4" ;;
    2) DNS_SERVERS="1.1.1.1 1.0.0.1" ;;
    3) DNS_SERVERS="77.88.8.8 77.88.8.1" ;;
    4) 
        DNS_SERVERS=$(read_from_terminal "${YELLOW}Введите DNS серверы (через пробел):${NC}")
        ;;
    *) 
        log_warn "Неверный выбор, используется Google DNS"
        DNS_SERVERS="8.8.8.8 8.8.4.4"
        ;;
esac

# Запрос дополнительного IP (опционально)
echo ""
if confirm_action "Добавить дополнительный IP адрес на этот интерфейс?"; then
    ADDITIONAL_IP=$(read_from_terminal "${YELLOW}Введите дополнительный IP адрес:${NC}")
    if [[ $ADDITIONAL_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        USE_ADDITIONAL_IP=true
    else
        log_warn "Неверный формат, дополнительный IP не будет добавлен"
        USE_ADDITIONAL_IP=false
    fi
else
    USE_ADDITIONAL_IP=false
fi
echo ""

# ============================================================================
# Подтверждение настроек
# ============================================================================
log_header
echo -e "${BLUE}Подтверждение настроек:${NC}"
log_header
echo ""
echo "  Подключение:  $TARGET_CONNECTION"
echo "  IP адрес:     $STATIC_IP/$CIDR_MASK"
echo "  Шлюз:         $GATEWAY"
echo "  DNS серверы:  $DNS_SERVERS"
if [[ "$USE_ADDITIONAL_IP" == true ]]; then
    echo "  Доп. IP:      $ADDITIONAL_IP/$CIDR_MASK"
fi
echo ""

if ! confirm_action "Применить эти настройки?"; then
    log_info "Настройка отменена пользователем"
    exit 0
fi
echo ""

# ============================================================================
# Применение настроек
# ============================================================================
log_header
echo -e "${BLUE}Применение настроек сети:${NC}"
log_header
echo ""

# Отключаем подключение перед изменением
log_info "Отключение подключения..."
nmcli connection down "$TARGET_CONNECTION"
check_success "Подключение отключено"

# Применяем настройки статического IP
log_info "Применение настроек статического IP..."
nmcli connection modify "$TARGET_CONNECTION" \
    ipv4.addresses "$STATIC_IP/$CIDR_MASK" \
    ipv4.gateway "$GATEWAY" \
    ipv4.dns "$DNS_SERVERS" \
    ipv4.method manual

check_success "Настройки IP применены"

# Добавляем дополнительный IP если указан
if [[ "$USE_ADDITIONAL_IP" == true ]]; then
    log_info "Добавление дополнительного IP адреса..."
    nmcli connection modify "$TARGET_CONNECTION" \
        +ipv4.addresses "$ADDITIONAL_IP/$CIDR_MASK"
    check_success "Дополнительный IP добавлен"
fi

# Включаем подключение обратно
log_info "Включение подключения..."
nmcli connection up "$TARGET_CONNECTION"
check_success "Подключение включено"

echo ""

# ============================================================================
# Проверка подключения
# ============================================================================
log_header
echo -e "${BLUE}Проверка подключения:${NC}"
log_header
echo ""

# Ждём несколько секунд для применения настроек
sleep 3

# Проверка связи со шлюзом
log_info "Проверка связи со шлюзом ($GATEWAY)..."
if check_connectivity "$GATEWAY"; then
    echo -e "${GREEN}✓ Шлюз доступен${NC}"
else
    echo -e "${RED}✗ Шлюз недоступен${NC}"
    log_warn "Возможно, указаны неверные настройки сети"
fi

# Проверка DNS
log_info "Проверка работы DNS..."
if nslookup google.com &>/dev/null; then
    echo -e "${GREEN}✓ DNS работает${NC}"
else
    echo -e "${YELLOW}⚠ DNS может быть недоступен${NC}"
fi

# Проверка внешнего IP
log_info "Проверка нового IP адреса..."
NEW_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo "  Ваш новый IP: ${NEW_IP:-не определён}"
echo ""

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Настройка статического IP завершена!"
log_header
echo ""
echo -e "${GREEN}Итоговые настройки:${NC}"
echo ""
echo "  Подключение:  $TARGET_CONNECTION"
echo "  IP адрес:     $STATIC_IP/$CIDR_MASK"
echo "  Шлюз:         $GATEWAY"
echo "  DNS серверы:  $DNS_SERVERS"
if [[ "$USE_ADDITIONAL_IP" == true ]]; then
    echo "  Доп. IP:      $ADDITIONAL_IP/$CIDR_MASK"
fi
echo ""

echo -e "${BLUE}Полезные команды для проверки:${NC}"
echo "  ip addr show                     # показать все IP адреса"
echo "  ip route show                    # показать таблицу маршрутизации"
echo "  nmcli connection show            # показать все подключения"
echo "  nmcli device status              # статус устройств"
echo "  ping -c 4 8.8.8.8                # проверка связи"
echo "  nslookup google.com              # проверка DNS"
echo ""

echo -e "${YELLOW}Для возврата к DHCP выполните:${NC}"
echo "  nmcli connection modify \"$TARGET_CONNECTION\" ipv4.method auto"
echo "  nmcli connection down \"$TARGET_CONNECTION\" && nmcli connection up \"$TARGET_CONNECTION\""
echo ""

# Предложение сохранить скрипт для быстрого отката
if confirm_action "Сохранить скрипт для быстрого возврата к DHCP?"; then
    ROLLBACK_SCRIPT="$HOME/rollback_to_dhcp.sh"
    cat > "$ROLLBACK_SCRIPT" << EOF
#!/bin/bash
# Скрипт возврата к DHCP для подключения: $TARGET_CONNECTION
nmcli connection modify "$TARGET_CONNECTION" ipv4.method auto
nmcli connection down "$TARGET_CONNECTION" && nmcli connection up "$TARGET_CONNECTION"
echo "✓ Возврат к DHCP выполнен"
EOF
    chmod +x "$ROLLBACK_SCRIPT"
    echo -e "${GREEN}✓ Скрипт сохранён: $ROLLBACK_SCRIPT${NC}"
fi

echo ""
log_info "Готово!"
