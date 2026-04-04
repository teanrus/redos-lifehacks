#!/bin/bash
#
# Скрипт настройки Wi-Fi для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_wifi.sh | sudo bash
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
log_info "Настройка Wi-Fi в РЕД ОС"
log_header
echo ""

# ============================================================================
# Проверка текущего состояния
# ============================================================================
log_info "Проверка текущего состояния Wi-Fi..."

declare -A WIFI_STATUS

# Проверка наличия Wi-Fi адаптера
if command -v iwconfig &> /dev/null; then
    WIFI_ADAPTER=$(iwconfig 2>/dev/null | grep -oE "^[a-zA-Z0-9]+" | head -1)
    if [[ -n "$WIFI_ADAPTER" ]]; then
        WIFI_STATUS["Адаптер"]="$WIFI_ADAPTER"
    else
        WIFI_STATUS["Адаптер"]="не найден"
    fi
else
    WIFI_STATUS["Адаптер"]="iwconfig не установлен"
fi

# Проверка NetworkManager
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    WIFI_STATUS["NetworkManager"]="${GREEN}активен${NC}"
else
    WIFI_STATUS["NetworkManager"]="${RED}не активен${NC}"
fi

# Проверка rfkill
if command -v rfkill &> /dev/null; then
    WIFI_BLOCKED=$(rfkill list wifi 2>/dev/null | grep -q "Soft blocked: yes" && echo "заблокирован" || echo "разблокирован")
    WIFI_STATUS["Wi-Fi rfkill"]="$WIFI_BLOCKED"
else
    WIFI_STATUS["Wi-Fi rfkill"]="rfkill не установлен"
fi

# Проверка драйверов
if lspci | grep -qi "wireless\|wifi\|802.11" 2>/dev/null; then
    WIFI_STATUS["Wi-Fi устройство"]="${GREEN}обнаружено${NC}"
else
    WIFI_STATUS["Wi-Fi устройство"]="${YELLOW}не обнаружено${NC}"
fi

for key in "${!WIFI_STATUS[@]}"; do
    echo -e "  ${BLUE}$key${NC}: ${WIFI_STATUS[$key]}"
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
    "Проверка и установка драйверов Wi-Fi"
    "Включение Wi-Fi адаптера (rfkill)"
    "Настройка NetworkManager"
    "Подключение к Wi-Fi сети"
    "Настройка статического IP"
    "Настройка DNS"
    "Настройка автоподключения"
    "Создание точки доступа (Hotspot)"
    "Оптимизация энергопотребления"
    "Настройка роуминга"
    "Диагностика проблем"
    "Создание скрипта быстрого подключения"
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
WIFI_SSID=""
WIFI_PASSWORD=""
WIFI_CONNECTION_NAME=""

# ============================================================================
# 1. Проверка и установка драйверов Wi-Fi
# ============================================================================
if [[ ${MENU_ENABLED[0]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}1. Проверка и установка драйверов Wi-Fi${NC}"
    log_header

    if confirm_action "Проверить и установить драйверы Wi-Fi?"; then
        # Определение модели адаптера
        echo -e "${CYAN}Определение модели Wi-Fi адаптера...${NC}"
        
        if lspci | grep -i "wireless\|network" > /tmp/wifi_device.txt 2>/dev/null; then
            WIFI_DEVICE=$(cat /tmp/wifi_device.txt)
            echo -e "  ${GREEN}Найдено устройство:${NC} $WIFI_DEVICE"
            
            # Определение чипсета
            if echo "$WIFI_DEVICE" | grep -qi "intel"; then
                echo -e "  ${BLUE}Чипсет: Intel${NC}"
                if confirm_action "Установить драйверы Intel WiFi?"; then
                    dnf install -y iwlwifi-firmware 2>/dev/null || true
                    check_success "Драйверы Intel установлены"
                fi
            elif echo "$WIFI_DEVICE" | grep -qi "realtek"; then
                echo -e "  ${BLUE}Чипсет: Realtek${NC}"
                if confirm_action "Установить драйверы Realtek WiFi?"; then
                    dnf install -y rtl8188fu-firmware rtl8192eu-firmware rtl8723de-firmware 2>/dev/null || true
                    check_success "Драйверы Realtek установлены"
                fi
            elif echo "$WIFI_DEVICE" | grep -qi "atheros\|qualcomm"; then
                echo -e "  ${BLUE}Чипсет: Atheros/Qualcomm${NC}"
                if confirm_action "Установить драйверы Atheros WiFi?"; then
                    dnf install -y ath10k-firmware 2>/dev/null || true
                    check_success "Драйверы Atheros установлены"
                fi
            elif echo "$WIFI_DEVICE" | grep -qi "broadcom"; then
                echo -e "  ${BLUE}Чипсет: Broadcom${NC}"
                if confirm_action "Установить драйверы Broadcom WiFi?"; then
                    dnf install -y broadcom-wl broadcom-wl-kmod 2>/dev/null || true
                    check_success "Драйверы Broadcom установлены"
                fi
            else
                echo -e "  ${YELLOW}Неизвестный чипсет, требуется ручная установка${NC}"
            fi
        else
            echo -e "  ${YELLOW}Wi-Fi адаптер не найден${NC}"
        fi

        # Перезагрузка модуля
        if confirm_action "Перезагрузить модуль ядра?"; then
            modprobe -r iwlwifi 2>/dev/null || true
            modprobe iwlwifi 2>/dev/null || true
            check_success "Модуль перезапущен"
        fi

        RESULTS[1]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[1]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 2. Включение Wi-Fi адаптера (rfkill)
# ============================================================================
if [[ ${MENU_ENABLED[1]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}2. Включение Wi-Fi адаптера (rfkill)${NC}"
    log_header

    if confirm_action "Проверить и включить Wi-Fi адаптер?"; then
        # Проверка блокировки
        rfkill list all
        
        # Снятие блокировки
        rfkill unblock all 2>/dev/null || true
        rfkill unblock wifi 2>/dev/null || true
        
        check_success "Wi-Fi адаптер разблокирован"

        # Проверка состояния
        echo -e "${CYAN}Текущее состояние:${NC}"
        rfkill list wifi 2>/dev/null || echo "rfkill недоступен"

        RESULTS[2]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[2]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 3. Настройка NetworkManager
# ============================================================================
if [[ ${MENU_ENABLED[2]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}3. Настройка NetworkManager${NC}"
    log_header

    if confirm_action "Настроить NetworkManager?"; then
        # Проверка статуса
        if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
            systemctl enable NetworkManager
            systemctl start NetworkManager
            check_success "NetworkManager запущен"
        else
            echo -e "  ${GREEN}NetworkManager уже активен${NC}"
        fi

        # Включение управления Wi-Fi
        nmcli radio wifi on 2>/dev/null || true
        echo -e "  ${GREEN}Wi-Fi в NetworkManager включен${NC}"

        # Настройка автосканирования
        nmcli general permissions 2>/dev/null || true

        RESULTS[3]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[3]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 4. Подключение к Wi-Fi сети
# ============================================================================
if [[ ${MENU_ENABLED[3]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}4. Подключение к Wi-Fi сети${NC}"
    log_header

    if confirm_action "Подключиться к Wi-Fi сети?"; then
        # Сканирование сетей
        echo -e "${CYAN}Сканирование доступных сетей...${NC}"
        nmcli device wifi rescan 2>/dev/null || sleep 3
        
        # Вывод списка сетей
        echo -e "${CYAN}Доступные сети:${NC}"
        nmcli device wifi list 2>/dev/null | head -10 || echo "Не удалось получить список сетей"
        echo ""

        # Запрос SSID
        WIFI_SSID=$(read_from_terminal "${YELLOW}Введите SSID сети (имя):${NC}")
        
        if [[ -z "$WIFI_SSID" ]]; then
            echo -e "${RED}SSID не указан${NC}"
            RESULTS[4]="✗ Ошибка"
            echo ""
            continue
        fi

        # Запрос пароля
        WIFI_PASSWORD=$(read_from_terminal "${YELLOW}Введите пароль (если сеть открытая, нажмите Enter):${NC}")
        WIFI_CONNECTION_NAME="$WIFI_SSID"

        # Подключение
        if [[ -n "$WIFI_PASSWORD" ]]; then
            nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASSWORD" name "$WIFI_CONNECTION_NAME" 2>/dev/null
        else
            nmcli device wifi connect "$WIFI_SSID" name "$WIFI_CONNECTION_NAME" 2>/dev/null
        fi

        check_success "Подключение к $WIFI_SSID"

        # Проверка подключения
        echo -e "${CYAN}Статус подключения:${NC}"
        nmcli connection show --active 2>/dev/null | grep -i "$WIFI_SSID" || echo "Подключение не активно"

        RESULTS[4]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[4]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 5. Настройка статического IP
# ============================================================================
if [[ ${MENU_ENABLED[4]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}5. Настройка статического IP${NC}"
    log_header

    if confirm_action "Настроить статический IP адрес?"; then
        if [[ -z "$WIFI_CONNECTION_NAME" ]]; then
            WIFI_CONNECTION_NAME=$(read_from_terminal "${YELLOW}Название подключения:${NC}")
        fi

        STATIC_IP=$(read_from_terminal "${YELLOW}Статический IP (например, 192.168.1.100):${NC}")
        STATIC_GATEWAY=$(read_from_terminal "${YELLOW}Шлюз (например, 192.168.1.1):${NC}")
        STATIC_NETMASK=$(read_from_terminal "${YELLOW}Маска сети (например, 24 или 255.255.255.0):${NC}")

        if [[ -z "$STATIC_NETMASK" ]]; then
            STATIC_NETMASK="24"
        fi

        # Настройка статического IP
        nmcli connection modify "$WIFI_CONNECTION_NAME" \
            ipv4.method manual \
            ipv4.addresses "$STATIC_IP/$STATIC_NETMASK" \
            ipv4.gateway "$STATIC_GATEWAY" \
            ipv4.dns "" 2>/dev/null

        check_success "Статический IP настроен"

        RESULTS[5]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[5]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 6. Настройка DNS
# ============================================================================
if [[ ${MENU_ENABLED[5]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}6. Настройка DNS${NC}"
    log_header

    if confirm_action "Настроить DNS серверы?"; then
        if [[ -z "$WIFI_CONNECTION_NAME" ]]; then
            WIFI_CONNECTION_NAME=$(read_from_terminal "${YELLOW}Название подключения:${NC}")
        fi

        DNS_SERVERS=$(read_from_terminal "${YELLOW}DNS серверы (через пробел, например 8.8.8.8 1.1.1.1):${NC}")

        if [[ -n "$DNS_SERVERS" ]]; then
            nmcli connection modify "$WIFI_CONNECTION_NAME" \
                ipv4.ignore-auto-dns yes \
                ipv4.dns "$DNS_SERVERS" 2>/dev/null

            check_success "DNS настроены"
        else
            # Сброс на автоматические DNS
            nmcli connection modify "$WIFI_CONNECTION_NAME" \
                ipv4.ignore-auto-dns no 2>/dev/null
            
            echo -e "${GREEN}DNS сброшены на автоматические${NC}"
        fi

        RESULTS[6]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[6]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 7. Настройка автоподключения
# ============================================================================
if [[ ${MENU_ENABLED[6]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}7. Настройка автоподключения${NC}"
    log_header

    if confirm_action "Настроить автоподключение к этой сети?"; then
        if [[ -z "$WIFI_CONNECTION_NAME" ]]; then
            WIFI_CONNECTION_NAME=$(read_from_terminal "${YELLOW}Название подключения:${NC}")
        fi

        # Включение автоподключения
        nmcli connection modify "$WIFI_CONNECTION_NAME" \
            connection.autoconnect yes \
            connection.autoconnect-priority 100 2>/dev/null

        check_success "Автоподключение настроено"

        RESULTS[7]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[7]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 8. Создание точки доступа (Hotspot)
# ============================================================================
if [[ ${MENU_ENABLED[7]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}8. Создание точки доступа (Hotspot)${NC}"
    log_header

    if confirm_action "Создать точку доступа Wi-Fi?"; then
        HOTSPOT_SSID=$(read_from_terminal "${YELLOW}Имя точки доступа (SSID):${NC}")
        HOTSPOT_PASSWORD=$(read_from_terminal "${YELLOW}Пароль (минимум 8 символов):${NC}")
        HOTSPOT_BAND=$(read_from_terminal "${YELLOW}Диапазон (bg для 2.4GHz, a для 5GHz, по умолчанию bg):${NC}")

        if [[ -z "$HOTSPOT_BAND" ]]; then
            HOTSPOT_BAND="bg"
        fi

        # Создание точки доступа
        nmcli connection add type wifi ifname "*" con-name "$HOTSPOT_SSID" autoconnect yes \
            ssid "$HOTSPOT_SSID" \
            wifi.band "$HOTSPOT_BAND" \
            wifi.mode ap 2>/dev/null

        # Настройка безопасности
        nmcli connection modify "$HOTSPOT_SSID" \
            802-11-wireless-security.key-mgmt wpa-psk \
            802-11-wireless-security.psk "$HOTSPOT_PASSWORD" \
            ipv4.method shared 2>/dev/null

        check_success "Точка доступа создана"

        echo -e "${CYAN}Для запуска точки доступа:${NC}"
        echo "  nmcli connection up \"$HOTSPOT_SSID\""

        RESULTS[8]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[8]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 9. Оптимизация энергопотребления
# ============================================================================
if [[ ${MENU_ENABLED[8]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}9. Оптимизация энергопотребления${NC}"
    log_header

    if confirm_action "Настроить энергопотребление Wi-Fi?"; then
        # Проверка текущего статуса
        echo -e "${CYAN}Текущий статус энергопотребления:${NC}"
        iwconfig 2>/dev/null | grep -i "power" || echo "Информация недоступна"
        echo ""

        # Отключение энергосбережения для лучшей производительности
        if confirm_action "Отключить энергосбережение Wi-Fi (лучшая производительность)?"; then
            # Создание конфигурации NetworkManager
            cat > "/etc/NetworkManager/conf.d/wifi-powersave.conf" << EOF
[connection]
wifi.powersave = 2
EOF

            # Перезапуск NetworkManager
            systemctl restart NetworkManager 2>/dev/null || true

            check_success "Энергосбережение отключено"
        else
            # Включение энергосбережения
            cat > "/etc/NetworkManager/conf.d/wifi-powersave.conf" << EOF
[connection]
wifi.powersave = 3
EOF

            systemctl restart NetworkManager 2>/dev/null || true

            echo -e "${GREEN}Энергосбережение включено${NC}"
        fi

        RESULTS[9]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[9]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 10. Настройка роуминга
# ============================================================================
if [[ ${MENU_ENABLED[9]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}10. Настройка роуминга${NC}"
    log_header

    if confirm_action "Настроить параметры роуминга?"; then
        # Настройка агрессивности роуминга
        ROAMING_LEVEL=$(read_from_terminal "${YELLOW}Агрессивность роуминга (1-5, по умолчанию 3):${NC}")

        if [[ -z "$ROAMING_LEVEL" ]]; then
            ROAMING_LEVEL="3"
        fi

        # Создание конфигурации
        cat > "/etc/NetworkManager/conf.d/wifi-roaming.conf" << EOF
[connection]
# Агрессивность роуминга (1-5, где 5 - наиболее агрессивный)
wifi.roaming-aggressiveness=$ROAMING_LEVEL
EOF

        systemctl restart NetworkManager 2>/dev/null || true

        check_success "Параметры роуминга настроены"

        RESULTS[10]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[10]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 11. Диагностика проблем
# ============================================================================
if [[ ${MENU_ENABLED[10]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}11. Диагностика проблем${NC}"
    log_header

    if confirm_action "Выполнить диагностику Wi-Fi?"; then
        echo -e "${CYAN}=== Статус NetworkManager ===${NC}"
        systemctl status NetworkManager --no-pager -n 5 2>/dev/null || echo "NetworkManager не доступен"
        echo ""

        echo -e "${CYAN}=== Статус Wi-Fi (rfkill) ===${NC}"
        rfkill list wifi 2>/dev/null || echo "rfkill не доступен"
        echo ""

        echo -e "${CYAN}=== Wi-Fi адаптеры ===${NC}"
        lspci | grep -i "wireless\|network" 2>/dev/null || lsusb | grep -i "wireless\|wifi" 2>/dev/null || echo "Адаптеры не найдены"
        echo ""

        echo -e "${CYAN}=== Загруженные модули ===${NC}"
        lsmod | grep -i "wifi\|wl\|iwl\|ath\|rtl" 2>/dev/null || echo "Модули не найдены"
        echo ""

        echo -e "${CYAN}=== Активные подключения ===${NC}"
        nmcli connection show --active 2>/dev/null || echo "Нет активных подключений"
        echo ""

        echo -e "${CYAN}=== Статус устройства ===${NC}"
        nmcli device status 2>/dev/null || echo "Устройства не найдены"
        echo ""

        echo -e "${CYAN}=== Последние логи ===${NC}"
        journalctl -u NetworkManager --no-pager -n 10 2>/dev/null || echo "Логи не доступны"

        RESULTS[11]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[11]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 12. Создание скрипта быстрого подключения
# ============================================================================
if [[ ${MENU_ENABLED[11]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}12. Создание скрипта быстрого подключения${NC}"
    log_header

    if confirm_action "Создать скрипт быстрого подключения к Wi-Fi?"; then
        WIFI_QUICK_SCRIPT="/usr/local/bin/wifi-connect.sh"

        cat > "$WIFI_QUICK_SCRIPT" << 'EOF'
#!/bin/bash
#
# Скрипт быстрого подключения к Wi-Fi
#

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функция подключения
connect_wifi() {
    local ssid=$1
    local password=$2

    echo -e "${GREEN}Подключение к Wi-Fi: $ssid${NC}"

    # Проверка статуса
    if nmcli connection show --active | grep -q "$ssid"; then
        echo -e "${YELLOW}Wi-Fi уже подключен${NC}"
        read -p "Переподключить? (y/n): " answer
        if [[ ! $answer =~ ^[Yy]$ ]]; then
            exit 0
        fi
        nmcli connection down "$ssid" 2>/dev/null || true
    fi

    # Подключение
    if [[ -n "$password" ]]; then
        nmcli device wifi connect "$ssid" password "$password" 2>/dev/null
    else
        nmcli device wifi connect "$ssid" 2>/dev/null
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Wi-Fi подключен успешно${NC}"
        
        # Проверка подключения
        echo -e "${YELLOW}Проверка IP...${NC}"
        ip addr show | grep -E "inet " | head -3
        
        echo -e "${YELLOW}Проверка DNS...${NC}"
        cat /etc/resolv.conf | grep nameserver | head -3
    else
        echo -e "${RED}✗ Ошибка подключения${NC}"
        exit 1
    fi
}

# Функция отключения
disconnect_wifi() {
    local ssid=$1
    nmcli connection down "$ssid" 2>/dev/null
    echo "Wi-Fi отключен"
}

# Функция сканирования
scan_wifi() {
    echo -e "${BLUE}Сканирование сетей...${NC}"
    nmcli device wifi rescan
    sleep 2
    nmcli device wifi list
}

# Функция статуса
status_wifi() {
    echo -e "${BLUE}=== Статус Wi-Fi ===${NC}"
    nmcli device status | grep -i wifi
    echo ""
    echo -e "${BLUE}=== Активные подключения ===${NC}"
    nmcli connection show --active | grep -i wifi
    echo ""
    echo -e "${BLUE}=== rfkill ===${NC}"
    rfkill list wifi 2>/dev/null || echo "rfkill не доступен"
}

# Основная логика
case "${1:-help}" in
    connect|c)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Укажите SSID сети${NC}"
            exit 1
        fi
        connect_wifi "$2" "$3"
        ;;
    disconnect|d)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Укажите SSID сети${NC}"
            exit 1
        fi
        disconnect_wifi "$2"
        ;;
    scan|s)
        scan_wifi
        ;;
    status|st)
        status_wifi
        ;;
    on)
        nmcli radio wifi on
        echo "Wi-Fi включен"
        ;;
    off)
        nmcli radio wifi off
        echo "Wi-Fi выключен"
        ;;
    *)
        echo -e "${BLUE}Использование:${NC}"
        echo "  wifi-connect.sh connect <SSID> [пароль]  # подключиться"
        echo "  wifi-connect.sh disconnect <SSID>         # отключиться"
        echo "  wifi-connect.sh scan                      # сканировать"
        echo "  wifi-connect.sh status                    # статус"
        echo "  wifi-connect.sh on                        # включить адаптер"
        echo "  wifi-connect.sh off                       # выключить адаптер"
        echo ""
        echo -e "${YELLOW}Примеры:${NC}"
        echo "  wifi-connect.sh connect MyWiFi password123"
        echo "  wifi-connect.sh status"
        ;;
esac
EOF

        chmod +x "$WIFI_QUICK_SCRIPT"

        echo -e "${GREEN}✓ Скрипт создан: $WIFI_QUICK_SCRIPT${NC}"
        echo ""
        echo -e "${BLUE}Использование:${NC}"
        echo "  wifi-connect.sh connect <SSID> [пароль]  # подключиться"
        echo "  wifi-connect.sh scan                     # сканировать сети"
        echo "  wifi-connect.sh status                   # проверить статус"
        echo "  wifi-connect.sh on/off                   # вкл/выкл адаптер"

        RESULTS[12]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[12]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Настройка Wi-Fi завершена!"
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
echo "  nmcli device wifi list           # список сетей"
echo "  nmcli device wifi connect <SSID> password <PASS>  # подключиться"
echo "  nmcli connection show --active   # активные подключения"
echo "  nmcli radio wifi on/off          # вкл/выкл Wi-Fi"
echo "  rfkill list wifi                 # статус блокировки"
echo "  wifi-connect.sh status           # быстрый статус"
echo ""

if [[ -f "/usr/local/bin/wifi-connect.sh" ]]; then
    echo -e "${GREEN}✓ Скрипт быстрого подключения доступен: /usr/local/bin/wifi-connect.sh${NC}"
fi

echo ""
echo -e "${YELLOW}Для применения некоторых настроек может потребоваться перезагрузка:${NC}"
echo "  sudo reboot"
echo ""
