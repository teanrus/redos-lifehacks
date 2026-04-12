#!/bin/bash
# Скрипт настройки времени на РЕД ОС
# Интерактивный выбор часового пояса (только РФ)
# Серверы времени: ВНИИФТРИ (официальные российские Stratum-1)

set -e

# Часовые пояса Российской Федерации
declare -a TZ_NAMES=(
    "Калининград (UTC+2)"
    "Москва (UTC+3)"
    "Самара (UTC+4)"
    "Екатеринбург (UTC+5)"
    "Омск (UTC+6)"
    "Красноярск (UTC+7)"
    "Иркутск (UTC+8)"
    "Якутск (UTC+9)"
    "Владивосток (UTC+10)"
    "Магадан (UTC+11)"
    "Камчатка (UTC+12)"
)

declare -a TZ_VALUES=(
    "Europe/Kaliningrad"
    "Europe/Moscow"
    "Europe/Samara"
    "Asia/Yekaterinburg"
    "Asia/Omsk"
    "Asia/Krasnoyarsk"
    "Asia/Irkutsk"
    "Asia/Yakutsk"
    "Asia/Vladivostok"
    "Asia/Magadan"
    "Asia/Kamchatka"
)

NTP_SERVERS="ntp1.vniiftri.ru ntp2.vniiftri.ru ntp21.vniiftri.ru"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Функция для проверки успешности выполнения
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 успешно выполнено${NC}"
    else
        echo -e "${RED}✗ Ошибка при выполнении: $1${NC}"
        exit 1
    fi
}

# Функция вывода заголовка
print_header() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}  Настройка времени на РЕД ОС${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
}

# Функция вывода ошибки
print_error() {
    echo -e "${RED}Ошибка: $1${NC}" >&2
}

# Функция вывода информации
print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Проверка прав root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "запустите скрипт от имени root (sudo)"
        echo "Пример: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/timedate.sh | sudo bash"
        exit 1
    fi
}

# ============================================
# Основные функции
# ============================================

# Меню выбора часового пояса
select_timezone() {
    echo -e "${BLUE}[1/6] Выбор часового пояса${NC}"
    echo ""
    echo "Доступные часовые пояса:"
    echo ""

    for i in "${!TZ_NAMES[@]}"; do
        echo "  $((i+1)). ${TZ_NAMES[$i]}"
    done

    echo ""

    local choice
    while true; do
        choice=$(read_from_terminal "Выберите номер часового пояса [2]: ")
        choice=${choice:-2}

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#TZ_NAMES[@]}" ]; then
            SELECTED_TZ=$choice
            break
        else
            print_error "Неверный выбор. Введите число от 1 до ${#TZ_NAMES[@]}"
        fi
    done

    echo ""
}

# Установка часового пояса
set_timezone() {
    local tz_index=$((SELECTED_TZ-1))
    local timezone="${TZ_VALUES[$tz_index]}"
    local tz_name="${TZ_NAMES[$tz_index]}"
    
    echo -e "${BLUE}[2/6] Установка часового пояса: ${tz_name}${NC}"
    timedatectl set-timezone "$timezone"
    check_success "Часовой пояс"
    echo ""
}

# Отключение NTP для ручной настройки
disable_ntp() {
    echo -e "${BLUE}[3/6] Отключение текущей синхронизации NTP...${NC}"
    timedatectl set-ntp false
    sleep 1
    check_success "Отключение NTP"
    echo ""
}

# Установка и настройка chrony
install_chrony() {
    echo -e "${BLUE}[4/6] Установка chrony...${NC}"
    dnf install -y chrony > /dev/null 2>&1
    check_success "Установка chrony"

    # Резервная копия конфигурации
    cp /etc/chrony.conf /etc/chrony.conf.backup.$(date +%Y%m%d_%H%M%S)
    check_success "Резервная копия /etc/chrony.conf"

    # Настройка серверов времени
    echo -e "${BLUE}[5/6] Настройка серверов времени...${NC}"
    cat > /etc/chrony.conf << EOF
# Серверы точного времени ВНИИФТРИ (Stratum-1, Россия)
$(echo "$NTP_SERVERS" | tr ' ' '\n' | sed 's/^/server /; s/$/ iburst maxsources 4/')

# Разрешить локальным клиентам синхронизироваться с этим сервером
#local stratum 10

# Записывать данные о частоте
driftfile /var/lib/chrony/drift

# Разрешить системным часам изменяться
makestep 1.0 3

# Включить ядро синхронизации
rtcsync

# Лог-файл
logdir /var/log/chrony
log measurements statistics tracking

# Ключи для команд
keyfile /etc/chrony.keys
EOF

    echo -e "${GREEN}✓ Серверы времени настроены:${NC}"
    echo "  - ntp1.vniiftri.ru (ВНИИФТРИ, основной)"
    echo "  - ntp2.vniiftri.ru (ВНИИФТРИ, резервный)"
    echo "  - ntp21.vniiftri.ru (ВНИИФТРИ, Сибирь)"
    echo ""
}

# Запуск и включение chronyd
start_chronyd() {
    echo -e "${BLUE}[6/6] Запуск службы chronyd...${NC}"
    systemctl enable chronyd
    systemctl restart chronyd
    check_success "Запуск chronyd"
    echo ""
}

# Ожидание синхронизации
wait_for_sync() {
    # Спрашиваем пользователя, ждать ли синхронизацию
    if ! confirm_action "Ожидать синхронизацию времени (до 30 секунд)?"; then
        print_info "Пропуск ожидания синхронизации"
        return
    fi
    
    echo "Ожидание синхронизации времени (до 30 секунд)..."
    for i in {1..6}; do
        sleep 5
        STATUS=$(chronyc tracking 2>/dev/null | grep "Leap status" | awk -F': ' '{print $2}' | xargs)
        if [ "$STATUS" = "Normal" ]; then
            echo -e "${GREEN}✓ Синхронизация выполнена!${NC}"
            return
        fi
        echo "  Попытка $i/6..."
    done
    
    print_info "Синхронизация не завершена. Проверьте статус позже командой: chronyc tracking"
}

# Вывод итоговой информации
print_status() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}  Итоговая информация${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
    echo "Текущее время:"
    date
    echo ""
    echo "Статус timedatectl:"
    timedatectl status
    echo ""
    echo "Статус синхронизации chrony:"
    chronyc tracking 2>/dev/null || echo "  (ожидание синхронизации...)"
    echo ""
    echo "Источники времени:"
    chronyc sources -v 2>/dev/null || echo "  (ожидание подключения к серверам...)"
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}  Настройка завершена!${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# ============================================
# Основная функция
# ============================================

main() {
    print_header
    check_root
    select_timezone
    set_timezone
    disable_ntp
    install_chrony
    start_chronyd
    
    # Включение NTP через timedatectl
    timedatectl set-ntp true
    
    wait_for_sync
    print_status
}

# Запуск
main
