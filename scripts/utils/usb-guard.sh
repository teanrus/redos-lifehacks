#!/bin/bash
##############################################################################
# usb-guard.sh — Управление блокировкой USB-накопителей
#
# Автор: pagrishaevich
# Версия: 2.1 (с улучшенной обработкой ввода)
#
# Описание:
#   Скрипт для управления блокировкой USB-накопителей на РЕД ОС.
#   Реализует два метода: UDISKS_IGNORE (запрет автомонтирования) и
#   authorized (полное отключение на уровне шины USB).
#   Поддерживает создание белого списка доверенных устройств.
#
# Использование:
#   sudo ./usb-guard.sh [ОПЦИИ]
#
# Опции:
#   -h, --help            Справка
#       --scan            Сканировать USB-устройства
#       --whitelist       Добавить устройство в белый список (UDISKS_IGNORE)
#       --whitelist-auth  Добавить устройство в белый список (authorized)
#       --block-all       Блокировать все USB-накопители (UDISKS_IGNORE)
#       --unblock         Разблокировать все USB-накопители
#       --show            Показать текущие правила и статус
#
# Зависимости: bash, udev (udevadm), coreutils, grep, sed, mktemp
# Опционально: lsusb / usbutils (автоопределение USB 3.0)
#
# Совместимость: РЕД ОС 7.x ✅, РЕД ОС 8.x ✅
##############################################################################

set -euo pipefail

# ─── Цвета ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Константы ────────────────────────────────────────────────────────────
UDEV_RULES_DIR="/etc/udev/rules.d"
UDEV_RULE_FILE="${UDEV_RULES_DIR}/99-usb.rules"
REMOVE_USB_SCRIPT="/usr/bin/remove_usb.sh"

# ─── Глобальные переменные для отсканированных устройств ──────────────────
declare -a SCANNED_DEVS=()
declare -a SCANNED_SERIALS=()
declare -a SCANNED_PRODUCTS=()
declare -a SCANNED_MAXPOWERS=()
SCAN_DONE=0

# ─── Вспомогательные функции для ввода/вывода ────────────────────────────

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

# Функция для безопасного выбора из списка
select_from_list() {
    local prompt="$1"
    local max_value="$2"
    local selection
    
    while true; do
        selection=$(read_from_terminal "$prompt")
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$max_value" ]; then
            echo "$selection"
            return 0
        else
            echo -e "${RED}Неверный ввод. Пожалуйста, выберите число от 1 до $max_value${NC}" >&2
        fi
    done
}

# ─── Функция для безопасного экранирования строк ──────────────────────────
escape_udev_string() {
    printf "%s" "$1" | sed 's/[\\"]/\\&/g'
}

# ─── Проверка прав root ──────────────────────────────────────────────────
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Ошибка: требуются права root${NC}"
        echo "Запустите: sudo $0"
        exit 1
    fi
}

# ─── Проверка зависимостей ───────────────────────────────────────────────
check_dependencies() {
    command -v udevadm &>/dev/null || {
        echo -e "${RED}Ошибка: udevadm не найден${NC}"
        exit 1
    }

    command -v mktemp &>/dev/null || {
        echo -e "${RED}Ошибка: mktemp не найден${NC}"
        exit 1
    }

    command -v sed &>/dev/null || {
        echo -e "${RED}Ошибка: sed не найден${NC}"
        exit 1
    }

    if ! command -v lsusb &>/dev/null; then
        echo -e "${YELLOW}Предупреждение: lsusb не найден (usbutils). USB 3.0 автоопределение будет пропущено${NC}"
    fi

    if [[ ! -d "$UDEV_RULES_DIR" ]]; then
        echo -e "${BLUE}Создание директории: ${UDEV_RULES_DIR}${NC}"
        mkdir -p "$UDEV_RULES_DIR"
        check_success "Создание директории $UDEV_RULES_DIR"
    fi
}

# ─── Проверка поддержки USB 3.0 ──────────────────────────────────────────
detect_usb3() {
    if lsmod | grep -q "^xhci_hcd"; then
        echo "1"
    else
        echo "0"
    fi
}

# ─── Сканирование USB-накопителей ────────────────────────────────────────
scan_usb_devices() {
    SCANNED_DEVS=()
    SCANNED_SERIALS=()
    SCANNED_PRODUCTS=()
    SCANNED_MAXPOWERS=()
    SCAN_DONE=0

    echo -e "${BLUE}=== Сканирование USB-накопителей ===${NC}"
    echo ""

    local devices=()
    while IFS= read -r line; do
        local dev
        dev=$(echo "$line" | awk '{print $NF}')
        local devname
        devname=$(basename "$dev")
        if [[ "$devname" =~ ^sd[a-z]+$ ]]; then
            devices+=("$devname")
        fi
    done < <(find /dev -maxdepth 1 -type b -name 'sd*' -print 2>/dev/null || true)

    if [[ ${#devices[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}USB-накопители не обнаружены${NC}"
        echo ""
        echo -e "${YELLOW}Подключите USB-накопитель и попробуйте снова${NC}"
        echo ""
        return 0
    fi

    for i in "${!devices[@]}"; do
        local dev="${devices[$i]}"
        SCANNED_DEVS+=("$dev")

        echo -e "  ${GREEN}$((i+1))) ${dev}${NC}"

        local serial product maxpower vendor idVendor idProduct

        serial=$(udevadm info -a -p "/sys/block/${dev}" 2>/dev/null | grep -m1 "ATTRS{serial}" | sed 's/.*ATTRS{serial}=="\([^"]*\)".*/\1/')
        product=$(udevadm info -a -p "/sys/block/${dev}" 2>/dev/null | grep -m1 "ATTRS{product}" | sed 's/.*ATTRS{product}=="\([^"]*\)".*/\1/')
        maxpower=$(udevadm info -a -p "/sys/block/${dev}" 2>/dev/null | grep -m1 "ATTRS{bMaxPower}" | sed 's/.*ATTRS{bMaxPower}=="\([^"]*\)".*/\1/')
        vendor=$(udevadm info -a -p "/sys/block/${dev}" 2>/dev/null | grep -m1 "ATTRS{vendor}" | sed 's/.*ATTRS{vendor}=="\([^"]*\)".*/\1/')
        idVendor=$(udevadm info -a -p "/sys/block/${dev}" 2>/dev/null | grep -m1 "ATTRS{idVendor}" | sed 's/.*ATTRS{idVendor}=="\([^"]*\)".*/\1/')
        idProduct=$(udevadm info -a -p "/sys/block/${dev}" 2>/dev/null | grep -m1 "ATTRS{idProduct}" | sed 's/.*ATTRS{idProduct}=="\([^"]*\)".*/\1/')

        SCANNED_SERIALS+=("${serial:-}")
        SCANNED_PRODUCTS+=("${product:-}")
        SCANNED_MAXPOWERS+=("${maxpower:-}")

        echo -e "      Serial:    ${serial:-(не определён)}"
        echo -e "      Product:   ${product:-(не определён)}"
        echo -e "      MaxPower:  ${maxpower:-(не определён)}"
        [[ -n "$vendor" ]] && echo -e "      Vendor:    ${vendor}"
        [[ -n "$idVendor" ]] && echo -e "      idVendor:  ${idVendor}"
        [[ -n "$idProduct" ]] && echo -e "      idProduct: ${idProduct}"
        echo ""
    done

    SCAN_DONE=1
    echo -e "${GREEN}Сканирование завершено. Найдено устройств: ${#devices[@]}${NC}"
    echo ""
}

# ─── Создание скрипта remove_usb.sh ──────────────────────────────────────
create_remove_script() {
    if [[ -f "$REMOVE_USB_SCRIPT" ]]; then
        return 0
    fi

    cat > "$REMOVE_USB_SCRIPT" <<'SCRIPT'
#!/bin/bash
# Безопасная версия скрипта для деавторизации USB-устройств
devpath="$1"

# Извлекаем только безопасные символы (цифры, дефисы, точки)
if [[ "$devpath" =~ usb[0-9]+/[0-9]+-[0-9]+(\.[0-9]+)? ]]; then
    bus_num="${BASH_REMATCH[0]}"
    # Дополнительная валидация: только разрешённые символы
    if [[ "$bus_num" =~ ^[a-zA-Z0-9/.-]+$ ]]; then
        echo 0 > "/sys/bus/usb/devices/${bus_num}/authorized" 2>/dev/null || true
    fi
fi
SCRIPT

    chmod +x "$REMOVE_USB_SCRIPT"
    check_success "Создание скрипта $REMOVE_USB_SCRIPT"
}

# ─── Генерация правила UDISKS_IGNORE — блокировка всех ───────────────────
generate_block_all_udisks() {
    local usb3
    usb3=$(detect_usb3)

    echo 'ENV{ID_USB_DRIVER}=="usb-storage",ENV{UDISKS_IGNORE}="1"'
    if [[ "$usb3" == "1" ]]; then
        echo 'ENV{ID_USB_DRIVER}=="uas",ENV{UDISKS_IGNORE}="1"'
    fi
}

# ─── Генерация правила UDISKS_IGNORE — белый список ──────────────────────
generate_whitelist_udisks() {
    local usb3
    usb3=$(detect_usb3)
    local serial="$1"
    local product="$2"
    local maxpower="$3"

    echo 'ENV{ID_USB_DRIVER}=="usb-storage",ENV{UDISKS_IGNORE}="1"'
    if [[ "$usb3" == "1" ]]; then
        echo 'ENV{ID_USB_DRIVER}=="uas",ENV{UDISKS_IGNORE}="1"'
    fi

    if [[ -n "$serial" ]]; then
        local safe_serial
        safe_serial=$(escape_udev_string "$serial")
        echo "ATTRS{serial}==\"${safe_serial}\",ENV{UDISKS_IGNORE}=\"0\""
    fi
    if [[ -n "$product" ]]; then
        local safe_product
        safe_product=$(escape_udev_string "$product")
        echo "ATTRS{product}==\"${safe_product}\",ENV{UDISKS_IGNORE}=\"0\""
    fi
    if [[ -n "$maxpower" ]]; then
        local safe_maxpower
        safe_maxpower=$(escape_udev_string "$maxpower")
        echo "ATTRS{bMaxPower}==\"${safe_maxpower}\",ENV{UDISKS_IGNORE}=\"0\""
    fi
}

# ─── Генерация правила authorized — белый список ─────────────────────────
generate_whitelist_authorized() {
    local serial="$1"
    local product="$2"

    echo 'ACTION!="add", GOTO="dont_remove_usb"'
    echo 'ENV{ID_USB_DRIVER}!="usb-storage", GOTO="dont_remove_usb"'

    if [[ -n "$product" ]]; then
        local safe_product
        safe_product=$(escape_udev_string "$product")
        echo "ATTRS{product}==\"${safe_product}\", GOTO=\"dont_remove_usb\""
    fi
    if [[ -n "$serial" ]]; then
        local safe_serial
        safe_serial=$(escape_udev_string "$serial")
        echo "ATTRS{serial}==\"${safe_serial}\", GOTO=\"dont_remove_usb\""
    fi

    echo 'ENV{ID_USB_DRIVER}=="usb-storage", RUN+="/bin/sh -c '"'"'/usr/bin/remove_usb.sh $devpath'"'"'"'
    echo 'LABEL="dont_remove_usb"'
}

# ─── Применить правила udev ──────────────────────────────────────────────
apply_rules() {
    echo -e "${BLUE}Применение правил udev...${NC}"
    udevadm control --reload-rules
    check_success "Перезагрузка правил udev"
    
    udevadm trigger --subsystem-match=usb --subsystem-match=block 2>/dev/null || true
    echo -e "${GREEN}✓ Правила применены${NC}"
    echo -e "${YELLOW}Рекомендуется переподключить USB-устройства${NC}"
}

# ─── Блокировка всех USB (UDISKS_IGNORE) ─────────────────────────────────
block_all_usb() {
    echo -e "${BLUE}=== Блокировка всех USB-накопителей (UDISKS_IGNORE) ===${NC}"
    echo ""

    local usb3
    usb3=$(detect_usb3)
    if [[ "$usb3" == "1" ]]; then
        echo -e "  ${GREEN}USB 3.0 обнаружен${NC}"
    else
        echo -e "  ${YELLOW}USB 3.0 не обнаружен${NC}"
    fi
    echo ""

    if [[ -f "$UDEV_RULE_FILE" ]]; then
        local backup
        backup="${UDEV_RULE_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$UDEV_RULE_FILE" "$backup"
        echo -e "${YELLOW}Текущие правила сохранены: ${backup}${NC}"
    fi

    generate_block_all_udisks > "$UDEV_RULE_FILE"
    check_success "Запись правил в $UDEV_RULE_FILE"
    
    echo ""
    echo -e "${BLUE}Содержимое:${NC}"
    while IFS= read -r line; do
        echo -e "  ${CYAN}${line}${NC}"
    done < "$UDEV_RULE_FILE"
    echo ""

    apply_rules
}

# ─── Белый список (UDISKS_IGNORE) ────────────────────────────────────────
whitelist_udisks() {
    echo -e "${BLUE}=== Создание белого списка (UDISKS_IGNORE) ===${NC}"
    echo ""

    if [[ $SCAN_DONE -eq 0 || ${#SCANNED_DEVS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}Сначала выполните сканирование устройств (пункт 1 в меню)${NC}"
        echo ""
        if confirm_action "Просканировать сейчас?"; then
            scan_usb_devices
        else
            echo -e "${RED}Белый список невозможен без сканирования устройств${NC}"
            return 1
        fi
    fi

    if [[ ${#SCANNED_DEVS[@]} -eq 0 ]]; then
        echo -e "${RED}Нет отсканированных устройств${NC}"
        return 0
    fi

    echo -e "${BLUE}Отсканированные устройства:${NC}"
    echo ""
    for i in "${!SCANNED_DEVS[@]}"; do
        echo -e "  ${GREEN}$((i+1))) ${SCANNED_DEVS[$i]}${NC}"
        [[ -n "${SCANNED_SERIALS[$i]}" ]] && echo -e "      Serial:   ${SCANNED_SERIALS[$i]}"
        [[ -n "${SCANNED_PRODUCTS[$i]}" ]] && echo -e "      Product:  ${SCANNED_PRODUCTS[$i]}"
        [[ -n "${SCANNED_MAXPOWERS[$i]}" ]] && echo -e "      MaxPower: ${SCANNED_MAXPOWERS[$i]}"
        echo ""
    done

    dev_num=$(select_from_list "Выберите номер устройства для добавления в белый список: " "${#SCANNED_DEVS[@]}")
    local idx=$((dev_num-1))
    local serial="${SCANNED_SERIALS[$idx]}"
    local product="${SCANNED_PRODUCTS[$idx]}"
    local maxpower="${SCANNED_MAXPOWERS[$idx]}"

    echo ""
    echo -e "${BLUE}Выбранные атрибуты:${NC}"
    [[ -n "$serial" ]] && echo -e "  Serial:    ${serial}"
    [[ -n "$product" ]] && echo -e "  Product:   ${product}"
    [[ -n "$maxpower" ]] && echo -e "  MaxPower:  ${maxpower}"
    echo ""

    echo -e "${BLUE}Какие атрибуты использовать для белого списка?${NC}"
    echo "  1) Serial (наиболее надёжный)"
    echo "  2) Product"
    echo "  3) Serial + Product"
    echo "  4) Все три атрибута"
    echo "  5) Ввести вручную"
    echo ""
    
    attr_choice=$(select_from_list "Выбор: " 5)

    case "$attr_choice" in
        1) product=""; maxpower="" ;;
        2) serial=""; maxpower="" ;;
        3) maxpower="" ;;
        4) ;;
        5)
            serial=$(read_from_terminal "Serial (Enter для пропуска): ")
            product=$(read_from_terminal "Product (Enter для пропуска): ")
            maxpower=$(read_from_terminal "MaxPower (Enter для пропуска): ")
            ;;
    esac

    echo ""
    echo -e "${BLUE}Итоговые параметры белого списка:${NC}"
    [[ -n "$serial" ]] && echo -e "  Serial:   ${serial}"
    [[ -n "$product" ]] && echo -e "  Product:  ${product}"
    [[ -n "$maxpower" ]] && echo -e "  MaxPower: ${maxpower}"
    echo ""

    if [[ -f "$UDEV_RULE_FILE" ]]; then
        echo -e "${BLUE}Текущие правила:${NC}"
        while IFS= read -r line; do
            echo -e "  ${CYAN}${line}${NC}"
        done < "$UDEV_RULE_FILE"
        echo ""

        if confirm_action "Добавить к существующим правилам?"; then
            if [[ -n "$serial" ]]; then
                local safe_serial
                safe_serial=$(escape_udev_string "$serial")
                if ! grep -Fq "ATTRS{serial}==\"${safe_serial}\"" "$UDEV_RULE_FILE" 2>/dev/null; then
                    echo "ATTRS{serial}==\"${safe_serial}\",ENV{UDISKS_IGNORE}=\"0\"" >> "$UDEV_RULE_FILE"
                    echo -e "${GREEN}✓ Правило добавлено: serial=${serial}${NC}"
                else
                    echo -e "${YELLOW}Такое правило уже есть${NC}"
                fi
            fi
            if [[ -n "$product" ]]; then
                local safe_product
                safe_product=$(escape_udev_string "$product")
                if ! grep -Fq "ATTRS{product}==\"${safe_product}\"" "$UDEV_RULE_FILE" 2>/dev/null; then
                    echo "ATTRS{product}==\"${safe_product}\",ENV{UDISKS_IGNORE}=\"0\"" >> "$UDEV_RULE_FILE"
                    echo -e "${GREEN}✓ Правило добавлено: product=${product}${NC}"
                else
                    echo -e "${YELLOW}Такое правило уже есть${NC}"
                fi
            fi
            if [[ -n "$maxpower" ]]; then
                local safe_maxpower
                safe_maxpower=$(escape_udev_string "$maxpower")
                if ! grep -Fq "ATTRS{bMaxPower}==\"${safe_maxpower}\"" "$UDEV_RULE_FILE" 2>/dev/null; then
                    echo "ATTRS{bMaxPower}==\"${safe_maxpower}\",ENV{UDISKS_IGNORE}=\"0\"" >> "$UDEV_RULE_FILE"
                    echo -e "${GREEN}✓ Правило добавлено: bMaxPower=${maxpower}${NC}"
                else
                    echo -e "${YELLOW}Такое правило уже есть${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}Создаём новые правила (старые будут сохранены в бэкап)${NC}"
            local backup
            backup="${UDEV_RULE_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
            cp "$UDEV_RULE_FILE" "$backup"
            generate_whitelist_udisks "$serial" "$product" "$maxpower" > "$UDEV_RULE_FILE"
            check_success "Запись новых правил в $UDEV_RULE_FILE"
        fi
    else
        generate_whitelist_udisks "$serial" "$product" "$maxpower" > "$UDEV_RULE_FILE"
        check_success "Запись правил в $UDEV_RULE_FILE"
    fi

    echo ""
    echo -e "${BLUE}Содержимое:${NC}"
    while IFS= read -r line; do
        echo -e "  ${CYAN}${line}${NC}"
    done < "$UDEV_RULE_FILE"
    echo ""

    apply_rules
}

# ─── Белый список (authorized) ───────────────────────────────────────────
whitelist_authorized() {
    echo -e "${BLUE}=== Создание белого списка (authorized) ===${NC}"
    echo ""

    create_remove_script

    if [[ $SCAN_DONE -eq 0 || ${#SCANNED_DEVS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}Сначала выполните сканирование устройств (пункт 1 в меню)${NC}"
        echo ""
        if confirm_action "Просканировать сейчас?"; then
            scan_usb_devices
        else
            echo -e "${RED}Белый список невозможен без сканирования устройств${NC}"
            return 1
        fi
    fi

    if [[ ${#SCANNED_DEVS[@]} -eq 0 ]]; then
        echo -e "${RED}Нет отсканированных устройств${NC}"
        return 0
    fi

    echo -e "${BLUE}Отсканированные устройства:${NC}"
    echo ""
    for i in "${!SCANNED_DEVS[@]}"; do
        echo -e "  ${GREEN}$((i+1))) ${SCANNED_DEVS[$i]}${NC}"
        [[ -n "${SCANNED_SERIALS[$i]}" ]] && echo -e "      Serial:   ${SCANNED_SERIALS[$i]}"
        [[ -n "${SCANNED_PRODUCTS[$i]}" ]] && echo -e "      Product:  ${SCANNED_PRODUCTS[$i]}"
        echo ""
    done

    dev_num=$(select_from_list "Выберите номер устройства для добавления в белый список: " "${#SCANNED_DEVS[@]}")
    local idx=$((dev_num-1))
    local serial="${SCANNED_SERIALS[$idx]}"
    local product="${SCANNED_PRODUCTS[$idx]}"

    echo ""
    echo -e "${BLUE}Выбранные атрибуты:${NC}"
    [[ -n "$serial" ]] && echo -e "  Serial:  ${serial}"
    [[ -n "$product" ]] && echo -e "  Product: ${product}"
    echo ""

    echo -e "${BLUE}Какие атрибуты использовать?${NC}"
    echo "  1) Serial (наиболее надёжный)"
    echo "  2) Product"
    echo "  3) Оба"
    echo "  4) Ввести вручную"
    echo ""
    
    attr_choice=$(select_from_list "Выбор: " 4)

    case "$attr_choice" in
        1) product="" ;;
        2) serial="" ;;
        3) ;;
        4)
            serial=$(read_from_terminal "Serial: ")
            product=$(read_from_terminal "Product: ")
            ;;
    esac

    echo ""
    echo -e "${BLUE}Итоговые параметры:${NC}"
    [[ -n "$serial" ]] && echo -e "  Serial:  ${serial}"
    [[ -n "$product" ]] && echo -e "  Product: ${product}"
    echo ""

    if [[ -f "$UDEV_RULE_FILE" ]]; then
        if confirm_action "Перезаписать правила?"; then
            generate_whitelist_authorized "$serial" "$product" > "$UDEV_RULE_FILE"
            check_success "Запись правил в $UDEV_RULE_FILE"
        else
            local tmp_file
            tmp_file=$(mktemp) || { echo -e "${RED}Ошибка создания временного файла${NC}"; return 1; }
            trap 'rm -f "$tmp_file"' EXIT
            
            while IFS= read -r line; do
                if echo "$line" | grep -qE '^[^#]*RUN\+=".*remove_usb.*"'; then
                    if [[ -n "$serial" ]]; then
                        local safe_serial
                        safe_serial=$(escape_udev_string "$serial")
                        if ! grep -Fq "ATTRS{serial}==\"${safe_serial}\"" "$UDEV_RULE_FILE" 2>/dev/null; then
                            echo "ATTRS{serial}==\"${safe_serial}\", GOTO=\"dont_remove_usb\"" >> "$tmp_file"
                        fi
                    fi
                    if [[ -n "$product" ]]; then
                        local safe_product
                        safe_product=$(escape_udev_string "$product")
                        if ! grep -Fq "ATTRS{product}==\"${safe_product}\"" "$UDEV_RULE_FILE" 2>/dev/null; then
                            echo "ATTRS{product}==\"${safe_product}\", GOTO=\"dont_remove_usb\"" >> "$tmp_file"
                        fi
                    fi
                fi
                echo "$line" >> "$tmp_file"
            done < "$UDEV_RULE_FILE"
            
            cp "$tmp_file" "$UDEV_RULE_FILE"
            trap - EXIT
            rm -f "$tmp_file"
            echo -e "${GREEN}✓ Правила добавлены к существующим${NC}"
        fi
    else
        generate_whitelist_authorized "$serial" "$product" > "$UDEV_RULE_FILE"
        check_success "Запись правил в $UDEV_RULE_FILE"
    fi

    echo ""
    echo -e "${BLUE}Содержимое:${NC}"
    while IFS= read -r line; do
        echo -e "  ${CYAN}${line}${NC}"
    done < "$UDEV_RULE_FILE"
    echo ""

    apply_rules
}

# ─── Разблокировка всех USB ──────────────────────────────────────────────
unblock_all_usb() {
    echo -e "${BLUE}=== Разблокировка всех USB-накопителей ===${NC}"
    echo ""

    if [[ ! -f "$UDEV_RULE_FILE" ]]; then
        echo -e "${YELLOW}Файл правил не найден: ${UDEV_RULE_FILE}${NC}"
        echo -e "${YELLOW}Возможно, USB уже разблокированы${NC}"
        return 0
    fi

    local backup
    backup="${UDEV_RULE_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$UDEV_RULE_FILE" "$backup"
    echo -e "${YELLOW}Правила сохранены в бэкап: ${backup}${NC}"

    if confirm_action "Удалить файл правил и разблокировать все USB?"; then
        rm -f "$UDEV_RULE_FILE"
        echo -e "${GREEN}✓ Файл правил удалён: ${UDEV_RULE_FILE}${NC}"

        if [[ -f "$REMOVE_USB_SCRIPT" ]]; then
            rm -f "$REMOVE_USB_SCRIPT"
            echo -e "${GREEN}✓ Скрипт удалён: ${REMOVE_USB_SCRIPT}${NC}"
        fi

        apply_rules

        echo -e "${BLUE}Восстановление authorized для подключённых устройств...${NC}"
        for dev in /sys/bus/usb/devices/*/authorized; do
            if [[ -f "$dev" ]]; then
                echo 1 > "$dev" 2>/dev/null || true
            fi
        done
        echo -e "${GREEN}✓ Все USB-накопители разблокированы${NC}"
    else
        echo -e "${YELLOW}Отменено${NC}"
    fi
}

# ─── Просмотр текущих правил ─────────────────────────────────────────────
show_rules() {
    echo -e "${BLUE}=== Текущие правила USB ===${NC}"
    echo ""

    if [[ -f "$UDEV_RULE_FILE" ]]; then
        echo -e "  ${GREEN}●${NC} ${UDEV_RULE_FILE}"
        echo ""
        while IFS= read -r line; do
            echo -e "  ${CYAN}${line}${NC}"
        done < "$UDEV_RULE_FILE"
    else
        echo -e "  ${YELLOW}Файл правил не найден — USB-накопители не заблокированы${NC}"
    fi

    echo ""

    if [[ -f "$REMOVE_USB_SCRIPT" ]]; then
        echo -e "  ${GREEN}●${NC} ${REMOVE_USB_SCRIPT}"
    fi

    echo ""
    echo -e "${BLUE}Статус подключённых USB-устройств:${NC}"
    echo ""
    for dev in /sys/bus/usb/devices/*/authorized; do
        if [[ -f "$dev" ]]; then
            local status
            status=$(cat "$dev" 2>/dev/null)
            local devname
            devname=$(basename "$(dirname "$dev")")
            if [[ "$status" == "1" ]]; then
                echo -e "  ${GREEN}●${NC} ${devname}: authorized=${status} (разрешено)"
            elif [[ "$status" == "0" ]]; then
                echo -e "  ${RED}●${NC} ${devname}: authorized=${status} (заблокировано)"
            fi
        fi
    done
    echo ""
}

# ─── Главное меню ─────────────────────────────────────────────────────────
main_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║       Управление USB-накопителями (РЕД ОС 8)      ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Сканировать USB-устройства"
        echo "  2) Добавить устройство в белый список (UDISKS_IGNORE)"
        echo "  3) Добавить устройство в белый список (authorized)"
        echo "  4) Блокировать все USB (UDISKS_IGNORE)"
        echo "  5) Разблокировать все USB"
        echo "  6) Просмотреть текущие правила"
        echo "  7) Выход"
        echo ""
        
        choice=$(select_from_list "Выбор: " 7)

        case $choice in
            1) scan_usb_devices ;;
            2) whitelist_udisks ;;
            3) whitelist_authorized ;;
            4) block_all_usb ;;
            5) unblock_all_usb ;;
            6) show_rules ;;
            7) echo "Выход..."; exit 0 ;;
        esac
    done
}

# ─── Справка ──────────────────────────────────────────────────────────────
show_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --scan             Сканировать USB-устройства"
    echo "  --whitelist        Добавить устройство в белый список (UDISKS_IGNORE)"
    echo "  --whitelist-auth   Добавить устройство в белый список (authorized)"
    echo "  --block-all        Блокировать все USB-накопители (UDISKS_IGNORE)"
    echo "  --unblock          Разблокировать все USB-накопители"
    echo "  --show             Показать текущие правила и статус"
    echo "  --help, -h         Эта справка"
    echo ""
    echo "Без опций запускается интерактивное меню"
    echo ""
    echo "Методы:"
    echo "  UDISKS_IGNORE  — запрещает автомонтирование, устройство видно в системе"
    echo "  authorized     — полностью отключает устройство на уровне шины USB"
    echo ""
    echo "Файлы:"
    echo "  ${UDEV_RULE_FILE}   — правила udev"
    echo "  ${REMOVE_USB_SCRIPT} — скрипт блокировки (authorized метод)"
    echo ""
    echo "Порядок работы:"
    echo "  1. Сканировать устройства (пункт 1 / --scan)"
    echo "  2. Добавить нужное устройство в белый список (пункт 2 или 3)"
    echo "  3. При необходимости заблокировать все остальные (пункт 4)"
}

# ─── Основная логика ─────────────────────────────────────────────────────
main() {
    check_root
    check_dependencies

    if [[ $# -gt 0 ]]; then
        case "$1" in
            --scan)           scan_usb_devices ;;
            --whitelist)      whitelist_udisks ;;
            --whitelist-auth) whitelist_authorized ;;
            --block-all)      block_all_usb ;;
            --unblock)        unblock_all_usb ;;
            --show)           show_rules ;;
            --help|-h)        show_help ;;
            *)
                echo -e "${RED}Неизвестная опция: $1${NC}"
                echo "Используйте --help для справки"
                exit 1
                ;;
        esac
    else
        main_menu
    fi
}

main "$@"
