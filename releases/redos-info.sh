#!/bin/bash

# ============================================
# redos-info.sh - Сбор информации о системе РЕД ОС
# Версия: 1.1 (с поддержкой pipe-выполнения)
# ============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Определяем, выполняется ли скрипт через pipe (curl | bash)
if [ ! -t 0 ]; then
    # stdin не является терминалом -> неинтерактивный режим
    INTERACTIVE_MODE=false
    QUIET_MODE=true
else
    # Интерактивный режим
    INTERACTIVE_MODE=true
    QUIET_MODE=false
fi

# Глобальные переменные
OUTPUT_FILE=""
SHOW_SECTIONS="all"
REPORT_DIR="./reports"

# ============================================
# Функция для чтения ввода от пользователя
# ============================================
read_from_terminal() {
    local prompt="$1"
    local default_value="$2"
    local input
    
    # Если не интерактивный режим или stdin не терминал, возвращаем значение по умолчанию
    if [ "$INTERACTIVE_MODE" = false ] || [ ! -t 0 ]; then
        echo "$default_value"
        return 0
    fi
    
    # Формируем приглашение с подсказкой
    if [ -n "$default_value" ]; then
        echo -e "${CYAN}${prompt}${NC} [${default_value}]: " >&2
    else
        echo -e "${CYAN}${prompt}${NC}: " >&2
    fi
    
    # Читаем из /dev/tty напрямую, чтобы обойти перенаправление stdin
    read -r input < /dev/tty
    
    # Если ввод пустой, используем значение по умолчанию
    if [ -z "$input" ] && [ -n "$default_value" ]; then
        echo "$default_value"
    else
        echo "$input"
    fi
}

# ============================================
# Функция для подтверждения действия
# ============================================
confirm_action() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [ "$INTERACTIVE_MODE" = false ] || [ ! -t 0 ]; then
        [ "$default" = "y" ] && return 0 || return 1
    fi
    
    echo -e "${YELLOW}${prompt} (y/n) [${default}]: ${NC}" >&2
    
    # Читаем из /dev/tty напрямую
    read -r response < /dev/tty
    
    if [ -z "$response" ]; then
        response="$default"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]] && return 0 || return 1
}

# ============================================
# Функция для вывода заголовков
# ============================================
print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

# ============================================
# Функция для вывода информации
# ============================================
print_info() {
    local label="$1"
    local value="$2"
    
    echo -e "${GREEN}✓${NC} $label: ${YELLOW}$value${NC}"
}

# ============================================
# Функция для проверки наличия команды
# ============================================
check_command() {
    command -v "$1" &> /dev/null
}

# ============================================
# Функция для сбора информации об ОС
# ============================================
collect_os_info() {
    print_header "1. ОСНОВНАЯ ИНФОРМАЦИЯ О СИСТЕМЕ"
    
    # Версия РЕД ОС
    if [ -f /etc/redos-release ]; then
        OS_VERSION=$(cat /etc/redos-release)
        print_info "Версия РЕД ОС" "$OS_VERSION"
    elif [ -f /etc/os-release ]; then
        OS_VERSION=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
        print_info "Версия ОС" "$OS_VERSION"
    fi
    
    # Имя хоста
    HOSTNAME=$(hostname)
    print_info "Имя хоста" "$HOSTNAME"
    
    # Дата и время
    CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "unknown")
    print_info "Текущая дата/время" "$CURRENT_DATE"
    print_info "Часовой пояс" "$TIMEZONE"
    
    # Uptime
    if [ -f /proc/uptime ]; then
        UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
        UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo "0")
        print_info "Время работы" "$UPTIME ($UPTIME_SEC сек)"
    fi
    
    # Загрузка системы
    LOAD=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | xargs || echo "unknown")
    print_info "Средняя загрузка" "$LOAD"
    
    # Пользователи
    USERS_COUNT=$(who | wc -l)
    print_info "Активных пользователей" "$USERS_COUNT"
}

# ============================================
# Функция для сбора информации о ядре
# ============================================
collect_kernel_info() {
    print_header "2. ИНФОРМАЦИЯ О ЯДРЕ"
    
    # Версия ядра
    KERNEL=$(uname -r 2>/dev/null || echo "unknown")
    KERNEL_VERSION=$(uname -v 2>/dev/null || echo "unknown")
    ARCH=$(uname -m 2>/dev/null || echo "unknown")
    print_info "Версия ядра" "$KERNEL"
    print_info "Архитектура" "$ARCH"
    print_info "Версия ядра (детально)" "$KERNEL_VERSION"
    
    # Параметры загрузки ядра
    if [ -f /proc/cmdline ]; then
        CMDLINE=$(cat /proc/cmdline)
        print_info "Параметры загрузки" "$CMDLINE"
    fi
    
    # Загруженные модули ядра
    MODULES_COUNT=$(lsmod 2>/dev/null | wc -l)
    print_info "Загруженных модулей" "$((MODULES_COUNT - 1))"
    
    # Список загруженных модулей (только в интерактивном режиме)
    if [ "$INTERACTIVE_MODE" = true ] && [ -t 0 ]; then
        if confirm_action "Показать список загруженных модулей?" "n"; then
            echo -e "\n${GREEN}Загруженные модули:${NC}"
            lsmod | head -20 | column -t
            echo "..."
        fi
    fi
}

# ============================================
# Функция для сбора информации об оборудовании
# ============================================
collect_hardware_info() {
    print_header "3. ИНФОРМАЦИЯ ОБ ОБОРУДОВАНИИ"
    
    # Процессор
    if [ -f /proc/cpuinfo ]; then
        CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
        CPU_CORES=$(grep -c "^processor" /proc/cpuinfo)
        CPU_VENDOR=$(grep "vendor_id" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
        print_info "Процессор" "$CPU_MODEL"
        print_info "Ядер/потоков" "$CPU_CORES"
        print_info "Производитель" "$CPU_VENDOR"
    fi
    
    # Оперативная память
    if [ -f /proc/meminfo ]; then
        MEM_TOTAL=$(grep "MemTotal" /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
        MEM_FREE=$(grep "MemAvailable" /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
        if command -v bc &> /dev/null; then
            MEM_USED=$(echo "$(grep "MemTotal" /proc/meminfo | awk '{print $2}') - $(grep "MemAvailable" /proc/meminfo | awk '{print $2}')" | bc 2>/dev/null | awk '{printf "%.2f GB", $1/1024/1024}')
        else
            MEM_USED="(требуется bc)"
        fi
        SWAP_TOTAL=$(grep "SwapTotal" /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')
        print_info "Оперативная память (всего)" "$MEM_TOTAL"
        print_info "Оперативная память (свободно)" "$MEM_FREE"
        print_info "Оперативная память (использовано)" "$MEM_USED"
        [ "$SWAP_TOTAL" != "0.00 GB" ] && print_info "Swap (всего)" "$SWAP_TOTAL"
    fi
}

# ============================================
# Функция для сбора информации о дисках
# ============================================
collect_disk_info() {
    print_header "4. ДИСКОВАЯ ПОДСИСТЕМА"
    
    # Список дисков
    echo -e "${GREEN}Диски и разделы:${NC}"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL 2>/dev/null | grep -v "loop" | head -20
    
    # Использование дискового пространства
    echo -e "\n${GREEN}Использование файловых систем:${NC}"
    df -hT 2>/dev/null | grep -v "tmpfs\|devtmpfs" | column -t
    
    # SMART статус (только в интерактивном режиме)
    if [ "$INTERACTIVE_MODE" = true ] && [ -t 0 ] && check_command smartctl; then
        if confirm_action "Проверить SMART статус дисков?" "n"; then
            echo -e "\n${GREEN}SMART статус дисков:${NC}"
            for disk in $(ls /dev/sd? 2>/dev/null | head -3); do
                if [ -e "$disk" ]; then
                    SMART_STATUS=$(sudo smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" | awk -F': ' '{print $2}')
                    if [ -n "$SMART_STATUS" ]; then
                        echo -e "  $disk: $SMART_STATUS"
                    fi
                fi
            done
        fi
    fi
}

# ============================================
# Функция для сбора сетевой информации
# ============================================
collect_network_info() {
    print_header "5. СЕТЕВАЯ ИНФОРМАЦИЯ"
    
    # Сетевые интерфейсы
    echo -e "${GREEN}Сетевые интерфейсы:${NC}"
    ip addr show 2>/dev/null | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1" | head -20
    
    # Маршрутизация
    echo -e "\n${GREEN}Маршруты по умолчанию:${NC}"
    ip route 2>/dev/null | grep default || echo "  Не настроено"
    
    # DNS серверы
    if [ -f /etc/resolv.conf ]; then
        DNS_SERVERS=$(grep "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}')
        if [ -n "$DNS_SERVERS" ]; then
            echo -e "\n${GREEN}DNS серверы:${NC}"
            echo "$DNS_SERVERS" | while read -r dns; do
                echo -e "  $dns"
            done
        fi
    fi
    
    # Открытые порты
    echo -e "\n${GREEN}Слушающие порты (TCP):${NC}"
    ss -tlnp 2>/dev/null | grep LISTEN | head -10
    
    # Проверка доступности интернета (только в интерактивном режиме)
    if [ "$INTERACTIVE_MODE" = true ] && [ -t 0 ]; then
        if confirm_action "Проверить доступность интернета?" "n"; then
            echo -e "\n${GREEN}Проверка подключения:${NC}"
            if ping -c 2 8.8.8.8 &>/dev/null; then
                print_info "Интернет" "Доступен"
            else
                echo -e "${RED}✗ Интернет: Недоступен${NC}"
            fi
        fi
    fi
}

# ============================================
# Функция для сбора информации о пакетах
# ============================================
collect_packages_info() {
    print_header "6. УСТАНОВЛЕННЫЕ ПАКЕТЫ"
    
    # Общее количество пакетов
    if check_command rpm; then
        PACKAGES_COUNT=$(rpm -qa 2>/dev/null | wc -l)
        print_info "Всего установлено пакетов" "$PACKAGES_COUNT"
    fi
    
    # Ключевые пакеты
    echo -e "\n${GREEN}Ключевые пакеты:${NC}"
    
    KEY_PACKAGES=(
        "kernel"
        "systemd"
        "dnf"
        "firewalld"
        "selinux-policy"
        "NetworkManager"
        "openssh-server"
        "cryptopro-csp"
        "1c-enterprise"
        "vipnet-client"
    )
    
    for pkg in "${KEY_PACKAGES[@]}"; do
        VERSION=$(rpm -qa 2>/dev/null | grep "^$pkg" | head -1)
        if [ -n "$VERSION" ]; then
            echo -e "  ${GREEN}✓${NC} $pkg: ${YELLOW}$VERSION${NC}"
        fi
    done
    
    # Список репозиториев
    if check_command dnf; then
        echo -e "\n${GREEN}Настроенные репозитории:${NC}"
        dnf repolist 2>/dev/null | grep -v "repo id" | head -10
    fi
}

# ============================================
# Функция для сбора информации о сервисах
# ============================================
collect_services_info() {
    print_header "7. ЗАПУЩЕННЫЕ СЕРВИСЫ"
    
    if check_command systemctl; then
        SERVICES_COUNT=$(systemctl list-units --type=service --state=running 2>/dev/null | grep -c "\.service")
        print_info "Всего запущенных сервисов" "$SERVICES_COUNT"
        
        echo -e "\n${GREEN}Критически важные сервисы:${NC}"
        CRITICAL_SERVICES=(
            "sshd"
            "NetworkManager"
            "firewalld"
            "auditd"
            "crond"
        )
        
        for svc in "${CRITICAL_SERVICES[@]}"; do
            STATUS=$(systemctl is-active "$svc" 2>/dev/null)
            if [ "$STATUS" == "active" ]; then
                echo -e "  ${GREEN}✓${NC} $svc: ${GREEN}$STATUS${NC}"
            elif [ "$STATUS" == "inactive" ]; then
                echo -e "  ${RED}✗${NC} $svc: ${RED}$STATUS${NC}"
            else
                echo -e "  ${YELLOW}?${NC} $svc: ${YELLOW}not installed${NC}"
            fi
        done
    fi
}

# ============================================
# Функция для сбора информации о безопасности
# ============================================
collect_security_info() {
    print_header "8. НАСТРОЙКИ БЕЗОПАСНОСТИ"
    
    # SELinux
    if check_command getenforce; then
        SELINUX_STATUS=$(getenforce 2>/dev/null)
        case "$SELINUX_STATUS" in
            "Enforcing")
                echo -e "  SELinux: ${GREEN}Enforcing${NC}"
                ;;
            "Permissive")
                echo -e "  SELinux: ${YELLOW}Permissive${NC}"
                ;;
            "Disabled")
                echo -e "  SELinux: ${RED}Disabled${NC}"
                ;;
            *)
                echo -e "  SELinux: ${YELLOW}Unknown${NC}"
                ;;
        esac
    fi
    
    # Firewall
    if check_command firewall-cmd; then
        FIREWALL_STATUS=$(systemctl is-active firewalld 2>/dev/null)
        if [ "$FIREWALL_STATUS" == "active" ]; then
            ZONE=$(firewall-cmd --get-default-zone 2>/dev/null)
            echo -e "  Firewall: ${GREEN}Active${NC} (зона: $ZONE)"
        else
            echo -e "  Firewall: ${RED}Inactive${NC}"
        fi
    fi
    
    # Последние входы
    echo -e "\n${GREEN}Последние успешные входы:${NC}"
    last -n 5 2>/dev/null | head -5
    
    # Неудачные попытки
    if check_command journalctl; then
        FAILED_LOGINS=$(journalctl _COMM=sshd 2>/dev/null | grep "Failed password" | wc -l)
        print_info "Неудачных попыток входа (за все время)" "$FAILED_LOGINS"
    fi
}

# ============================================
# Функция для сохранения отчета
# ============================================
save_report() {
    local filename="$1"
    local full_path="$REPORT_DIR/$filename"
    
    # Создаем директорию для отчетов
    mkdir -p "$REPORT_DIR"
    
    # Сохраняем отчет
    {
        echo "========================================="
        echo "RED OS System Information Report"
        echo "========================================="
        echo "Date: $(date)"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo "========================================="
        echo ""
        
        # Перенаправляем вывод всех функций в файл
        collect_os_info
        collect_kernel_info
        collect_hardware_info
        collect_disk_info
        collect_network_info
        collect_packages_info
        collect_services_info
        collect_security_info
        
    } > "$full_path" 2>&1
    
    echo "$full_path"
}

# ============================================
# Функция для отображения справки
# ============================================
show_help() {
    cat << EOF
${CYAN}RED OS System Information Tool${NC}
Version: 1.1

Использование:
    $0 [опции]

Опции:
    -h, --help          Показать эту справку
    -i, --interactive   Принудительно включить интерактивный режим
    -o, --output FILE   Сохранить отчет в файл
    -s, --section SECT  Показать только указанную секцию
    -d, --dir DIR       Директория для сохранения отчетов (по умолчанию: ./reports)
    
Примеры:
    $0                              # Автоопределение режима
    $0 -i                           # Принудительно интерактивный режим
    $0 -o report.txt                # Сохранить отчет
    $0 -s network                   # Только сетевая информация

EOF
}

# ============================================
# Главная функция
# ============================================
main() {
    local force_interactive=false
    
    # Парсинг аргументов командной строки
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--interactive)
                force_interactive=true
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -s|--section)
                SHOW_SECTIONS="$2"
                shift 2
                ;;
            -d|--dir)
                REPORT_DIR="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Неизвестная опция: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Определяем режим работы
    if [ "$force_interactive" = true ]; then
        INTERACTIVE_MODE=true
        QUIET_MODE=false
    elif [ ! -t 0 ]; then
        INTERACTIVE_MODE=false
        QUIET_MODE=true
    else
        INTERACTIVE_MODE=true
        QUIET_MODE=false
    fi
    
    # Заголовок
    if [ "$INTERACTIVE_MODE" = true ] && [ -t 0 ]; then
        clear
        echo -e "${CYAN}"
        echo "╔══════════════════════════════════════════╗"
        echo "║     RED OS System Information Tool       ║"
        echo "║         v1.1 by teanrus                  ║"
        echo "╚══════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${GREEN}Добро пожаловать!${NC}"
        echo -e "Скрипт соберет информацию о вашей системе.\n"
    fi
    
    # Сбор информации
    case "$SHOW_SECTIONS" in
        "os") collect_os_info ;;
        "kernel") collect_kernel_info ;;
        "hardware") collect_hardware_info ;;
        "disk") collect_disk_info ;;
        "network") collect_network_info ;;
        "packages") collect_packages_info ;;
        "services") collect_services_info ;;
        "security") collect_security_info ;;
        "all")
            collect_os_info
            collect_kernel_info
            collect_hardware_info
            collect_disk_info
            collect_network_info
            collect_packages_info
            collect_services_info
            collect_security_info
            ;;
        *)
            echo -e "${RED}Неизвестная секция: $SHOW_SECTIONS${NC}"
            exit 1
            ;;
    esac
    
    # Сохранение отчета
    if [ -n "$OUTPUT_FILE" ]; then
        REPORT_PATH=$(save_report "$OUTPUT_FILE")
        echo -e "\n${GREEN}✓ Отчет сохранен в: $REPORT_PATH${NC}"
    elif [ "$INTERACTIVE_MODE" = true ] && [ -t 0 ]; then
        if confirm_action "Сохранить отчет в файл?" "y"; then
            DEFAULT_NAME="redos-info-$(date +%Y%m%d-%H%M%S).txt"
            FILENAME=$(read_from_terminal "Введите имя файла" "$DEFAULT_NAME")
            REPORT_PATH=$(save_report "$FILENAME")
            echo -e "${GREEN}✓ Отчет сохранен в: $REPORT_PATH${NC}"
        fi
    fi
    
    # Завершение
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${GREEN}Сбор информации завершен!${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    # Если интерактивный режим, ждем нажатия клавиши
    if [ "$INTERACTIVE_MODE" = true ] && [ -t 0 ]; then
        echo -e "${YELLOW}Нажмите Enter для выхода...${NC}"
        read -r < /dev/tty
    fi
}

# ============================================
# Запуск главной функции
# ============================================
main "$@"