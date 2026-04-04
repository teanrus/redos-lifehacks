#!/bin/bash
#
# setup-network-printer.sh - Настройка сетевого принтера Kyocera в РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup-network-printer.sh | sudo bash
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
        return 1
    fi
}

# Логирование
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${BLUE}========================================${NC}"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }

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
log_info "Настройка сетевого принтера Kyocera в РЕД ОС"
log_header
echo ""

# ============================================================================
# Проверка установленных пакетов
# ============================================================================
log_info "Проверка установленных пакетов..."

declare -A INSTALLED_PACKAGES

if command -v cupsd &> /dev/null; then
    INSTALLED_PACKAGES["CUPS"]="установлен"
else
    INSTALLED_PACKAGES["CUPS"]="не установлен"
fi

if command -v lp &> /dev/null; then
    INSTALLED_PACKAGES["CUPS-клиент"]="установлен"
else
    INSTALLED_PACKAGES["CUPS-клиент"]="не установлен"
fi

if command -v firewall-cmd &> /dev/null; then
    INSTALLED_PACKAGES["firewalld"]="установлен"
else
    INSTALLED_PACKAGES["firewalld"]="не установлен"
fi

if command -v system-config-printer &> /dev/null; then
    INSTALLED_PACKAGES["system-config-printer"]="установлен"
else
    INSTALLED_PACKAGES["system-config-printer"]="не установлен"
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

if ! command -v cupsd &> /dev/null; then
    MISSING_PACKAGES+=("cups cups-client")
fi

if ! command -v system-config-printer &> /dev/null; then
    MISSING_PACKAGES+=("system-config-printer")
fi

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    if confirm_action "Установить недостающие пакеты: ${MISSING_PACKAGES[*]}?"; then
        log_info "Установка пакетов..."
        dnf install -y "${MISSING_PACKAGES[@]}"
        check_success "Установка пакетов"
    else
        log_warn "Установка пакетов пропущена"
    fi
fi
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
    "Настройка CUPS для сетевого доступа"
    "Открытие портов в firewall"
    "Настройка общего доступа к принтеру"
    "Создание пользователя для печати"
    "Настройка клиента для подключения к сетевому принтеру"
    "Создание скрипта быстрого подключения принтера"
    "Проверка статуса печати"
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
PRINTER_NAME=""
PRINTER_IP=""

# ============================================================================
# 1. Настройка CUPS для сетевого доступа
# ============================================================================
if [[ ${MENU_ENABLED[0]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}1. Настройка CUPS для сетевого доступа${NC}"
    log_header

    if confirm_action "Настроить CUPS для сетевого доступа?"; then
        # Резервное копирование конфигурации
        if [[ -f /etc/cups/cupsd.conf ]]; then
            cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.backup.$(date +%Y%m%d_%H%M%S)
            log_success "Создана резервная копия конфигурации"
        fi

        # Настройка cupsd.conf
        cat > /etc/cups/cupsd.conf << 'EOF'
# Файл конфигурации CUPS для сетевого доступа
# Обновлено скриптом setup-network-printer.sh

# Слушать все интерфейсы
Port 631
Listen /var/run/cups/cups.sock

# Показывать принтеры в локальной сети
Browsing On
BrowseLocalProtocols dnssd

# Доступ по умолчанию
DefaultAuthType Basic
WebInterface Yes

# Ограничить доступ к серверу
<Location />
  Order allow,deny
  Allow @LOCAL
</Location>

# Доступ к администрированию
<Location /admin>
  Order allow,deny
  Allow @LOCAL
  AuthType Default
  Require user @SYSTEM
</Location>

# Доступ к конфигурации
<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow @LOCAL
</Location>

# Настройки по умолчанию
MaxLogSize 0
LogLevel warn
EOF

        check_success "Конфигурация CUPS обновлена"

        # Перезапуск CUPS
        systemctl restart cups
        systemctl enable cups
        check_success "CUPS перезапущен"

        RESULTS[1]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[1]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 2. Открытие портов в firewall
# ============================================================================
if [[ ${MENU_ENABLED[1]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}2. Открытие портов в firewall${NC}"
    log_header

    if command -v firewall-cmd &> /dev/null; then
        if confirm_action "Открыть порты для печати в firewall?"; then
            # IPP (Internet Printing Protocol)
            firewall-cmd --permanent --add-service=ipp 2>/dev/null || true
            log_success "Добавлена служба IPP"

            # IPPS (IPP over HTTPS)
            firewall-cmd --permanent --add-service=ipps 2>/dev/null || true
            log_success "Добавлена служба IPPS"

            # Порт 9100 для AppSocket/HP Jetdirect
            firewall-cmd --permanent --add-port=9100/tcp 2>/dev/null || true
            log_success "Открыт порт 9100/tcp"

            # Порт 631 для CUPS
            firewall-cmd --permanent --add-port=631/tcp 2>/dev/null || true
            log_success "Открыт порт 631/tcp"

            # Применяем изменения
            firewall-cmd --reload 2>/dev/null || true
            check_success "Firewall перезагружен"

            RESULTS[2]="✓ Выполнено"
        else
            echo -e "${YELLOW}→ Пропущено${NC}"
            RESULTS[2]="✗ Пропущено"
        fi
    else
        log_warn "firewalld не установлен или не запущен"
        RESULTS[2]="✗ firewalld не найден"
    fi
    echo ""
fi

# ============================================================================
# 3. Настройка общего доступа к принтеру
# ============================================================================
if [[ ${MENU_ENABLED[2]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}3. Настройка общего доступа к принтеру${NC}"
    log_header

    if confirm_action "Настроить общий доступ к принтеру?"; then
        # Получить список принтеров
        PRINTER_LIST=$(lpstat -p 2>/dev/null | cut -d' ' -f2)

        if [[ -n "$PRINTER_LIST" ]]; then
            echo -e "${CYAN}Обнаружены принтеры:${NC}"
            echo "$PRINTER_LIST" | nl
            echo ""

            PRINTER_CHOICE=$(read_from_terminal "${YELLOW}Выберите номер принтера для общего доступа:${NC}")

            if [[ -n "$PRINTER_CHOICE" ]]; then
                PRINTER_NAME=$(echo "$PRINTER_LIST" | sed -n "${PRINTER_CHOICE}p")

                if [[ -n "$PRINTER_NAME" ]]; then
                    # Включить общий доступ к принтеру
                    cupsctl --share-printers 2>/dev/null || true
                    log_success "Общий доступ к принтерам включён"

                    # Установить принтер как общий
                    lpadmin -p "$PRINTER_NAME" -o printer-is-shared=true 2>/dev/null || true
                    check_success "Принтер '$PRINTER_NAME' настроен как общий"

                    # Принять задания на печать
                    cupsenable "$PRINTER_NAME" 2>/dev/null || true
                    cupsaccept "$PRINTER_NAME" 2>/dev/null || true
                    log_success "Принтер готов к печати"
                else
                    log_error "Принтер не выбран"
                fi
            else
                log_warn "Выбор принтера пропущен"
            fi
        else
            log_warn "Принтеры не найдены. Сначала установите драйвер и добавьте принтер."
            log_info "Инструкция: https://github.com/teanrus/redos-lifehacks/blob/main/printers-kyocera.md"
        fi

        RESULTS[3]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[3]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 4. Создание пользователя для печати
# ============================================================================
if [[ ${MENU_ENABLED[3]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}4. Создание пользователя для печати${NC}"
    log_header

    if confirm_action "Создать пользователя для сетевой печати?"; then
        PRINT_USER=$(read_from_terminal "${YELLOW}Имя пользователя (по умолчанию printer):${NC}")

        if [[ -z "$PRINT_USER" ]]; then
            PRINT_USER="printer"
        fi

        # Проверка существования пользователя
        if id "$PRINT_USER" &>/dev/null; then
            log_warn "Пользователь '$PRINT_USER' уже существует"
        else
            # Создание пользователя
            useradd -r -s /sbin/nologin "$PRINT_USER" 2>/dev/null || true
            check_success "Пользователь '$PRINT_USER' создан"
        fi

        # Добавление пользователя в группу lp
        usermod -aG lp "$PRINT_USER" 2>/dev/null || true
        log_success "Пользователь добавлен в группу lp"

        RESULTS[4]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[4]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 5. Настройка клиента для подключения к сетевому принтеру
# ============================================================================
if [[ ${MENU_ENABLED[4]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}5. Настройка клиента для подключения к сетевому принтеру${NC}"
    log_header

    if confirm_action "Настроить подключение к сетевому принтеру?"; then
        SERVER_IP=$(read_from_terminal "${YELLOW}IP-адрес сервера печати:${NC}")

        if [[ -n "$SERVER_IP" ]]; then
            PRINTER_NAME=$(read_from_terminal "${YELLOW}Имя принтера (по умолчанию Kyocera-FS-1125MFP):${NC}")

            if [[ -z "$PRINTER_NAME" ]]; then
                PRINTER_NAME="Kyocera-FS-1125MFP"
            fi

            # Выбор протокола
            echo -e "${BLUE}Выберите протокол подключения:${NC}"
            echo "  1) IPP (рекомендуется)"
            echo "  2) AppSocket/HP Jetdirect"
            echo "  3) LPD"
            echo ""

            PROTOCOL_CHOICE=$(read_from_terminal "${YELLOW}Ваш выбор (1-3):${NC}")

            case $PROTOCOL_CHOICE in
                1)
                    URI="ipp://$SERVER_IP:631/printers/$PRINTER_NAME"
                    ;;
                2)
                    URI="socket://$SERVER_IP:9100"
                    ;;
                3)
                    URI="lpd://$SERVER_IP/$PRINTER_NAME"
                    ;;
                *)
                    URI="ipp://$SERVER_IP:631/printers/$PRINTER_NAME"
                    ;;
            esac

            echo -e "${CYAN}URI принтера: $URI${NC}"

            # Добавление принтера
            lpadmin -p "Network-$PRINTER_NAME" -v "$URI" -E 2>/dev/null || true
            log_success "Сетевой принтер 'Network-$PRINTER_NAME' добавлен"

            # Выбор драйвера
            echo -e "${YELLOW}Для завершения настройки выберите драйвер в CUPS веб-интерфейсе:${NC}"
            echo -e "${CYAN}http://localhost:631${NC}"

            RESULTS[5]="✓ Выполнено"
        else
            log_warn "IP-адрес сервера не указан"
            RESULTS[5]="✗ Пропущено"
        fi
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[5]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 6. Создание скрипта быстрого подключения принтера
# ============================================================================
if [[ ${MENU_ENABLED[5]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}6. Создание скрипта быстрого подключения принтера${NC}"
    log_header

    if confirm_action "Создать скрипт проверки статуса печати?"; then
        PRINTER_STATUS_SCRIPT="/usr/local/bin/printer-status.sh"

        cat > "$PRINTER_STATUS_SCRIPT" << 'EOF'
#!/bin/bash
#
# Скрипт проверки статуса принтера
#

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Статус принтеров в системе${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Статус принтеров
echo -e "${YELLOW}=== Принтеры ===${NC}"
lpstat -p 2>/dev/null || echo "Принтеры не найдены"
echo ""

# Очереди печати
echo -e "${YELLOW}=== Очереди печати ===${NC}"
lpstat -o 2>/dev/null || echo "Очереди пустые"
echo ""

# Принтеры по умолчанию
echo -e "${YELLOW}=== Принтер по умолчанию ===${NC}"
lpstat -d 2>/dev/null || echo "Не установлен"
echo ""

# Статус CUPS
echo -e "${YELLOW}=== Статус службы CUPS ===${NC}"
systemctl is-active cups 2>/dev/null || echo "Служба не активна"
echo ""

# Сетевые принтеры
echo -e "${YELLOW}=== Сетевые принтеры ===${NC}"
lpstat -v 2>/dev/null | grep -E "(socket|ipp|lpd)" || echo "Сетевые принтеры не найдены"
echo ""
EOF

        chmod +x "$PRINTER_STATUS_SCRIPT"
        check_success "Скрипт создан: $PRINTER_STATUS_SCRIPT"

        RESULTS[6]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[6]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 7. Проверка статуса печати
# ============================================================================
if [[ ${MENU_ENABLED[6]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}7. Проверка статуса печати${NC}"
    log_header

    log_info "Текущий статус печати:"
    echo ""

    # Статус принтеров
    echo -e "${CYAN}Принтеры:${NC}"
    lpstat -p 2>/dev/null || echo "  Принтеры не найдены"
    echo ""

    # Очереди
    echo -e "${CYAN}Очереди печати:${NC}"
    lpstat -o 2>/dev/null || echo "  Очереди пустые"
    echo ""

    # Принтер по умолчанию
    echo -e "${CYAN}Принтер по умолчанию:${NC}"
    lpstat -d 2>/dev/null || echo "  Не установлен"
    echo ""

    # Статус CUPS
    echo -e "${CYAN}Служба CUPS:${NC}"
    systemctl is-active cups 2>/dev/null && echo "  Активна" || echo "  Не активна"
    echo ""

    RESULTS[7]="✓ Выполнено"
fi

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Настройка сетевого принтера завершена!"
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
echo "  lpstat -p              # список принтеров"
echo "  lpstat -o              # очереди печати"
echo "  lpstat -d              # принтер по умолчанию"
echo "  lp -d <принтер> <файл> # печать файла"
echo "  cancel <задание>       # отмена задания"
echo "  printer-status.sh      # проверка статуса"
echo ""

echo -e "${BLUE}Веб-интерфейс CUPS:${NC}"
echo -e "  ${CYAN}http://localhost:631${NC}"
echo ""

echo -e "${BLUE}Дополнительная информация:${NC}"
echo "  https://github.com/teanrus/redos-lifehacks/blob/main/printers-kyocera.md"
echo ""
