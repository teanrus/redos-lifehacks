#!/bin/bash
#
# Скрипт подготовки загрузочной флешки с РЕД ОС для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-install.sh | sudo bash
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

# Глобальные переменные
USB_DEVICE=""
ISO_PATH=""
ISO_DOWNLOAD_PAGE="https://redos.red-soft.ru/product/downloads/"
ISO_FILENAME=""
ISO_EXPECTED_SHA256=""  # Укажите актуальную контрольную сумму с сайта
VENTOY_VERSION="1.0.99"
VENTOY_URL="https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VERSION}/ventoy-${VENTOY_VERSION}-linux.tar.gz"
CREATE_CONFIG="y"

# ============================================================================
# Вспомогательные функции
# ============================================================================

# Функция для безопасного чтения ввода из терминала
read_from_terminal() {
    local prompt=$1
    local default=$2
    local answer
    echo -e "$prompt" >&2
    read -r answer < /dev/tty 2>/dev/null || true
    if [ -z "$answer" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$answer"
    fi
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
        return 1
    fi
}

# Логирование
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${BLUE}========================================${NC}"; }
log_step() { echo -e "${CYAN}[ШАГ]${NC} $1"; }

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

# ============================================================================
# Главная функция
# ============================================================================
log_header
log_info "Подготовка загрузочной флешки с РЕД ОС"
log_header
echo ""

# ============================================================================
# Шаг 1: Поиск USB-накопителей
# ============================================================================
log_step "Поиск USB-накопителей"
echo ""

# Получение списка блочных устройств
echo -e "${CYAN}Найдены следующие устройства:${NC}"

# Исключаем виртуальные и loop устройства
DEVICES=$(lsblk -nd -o NAME,SIZE,MODEL,TYPE 2>/dev/null | grep -E "disk|usb" | grep -v "loop" | grep -v "sr0")

if [ -z "$DEVICES" ]; then
    log_error "USB-накопители не найдены"
    exit 1
fi

# Нумерация устройств
i=1
declare -A DEVICE_MAP

while IFS= read -r line; do
    DEV_NAME=$(echo "$line" | awk '{print $1}')
    DEV_SIZE=$(echo "$line" | awk '{print $2}')
    DEV_MODEL=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf $i" "; print ""}' | sed 's/ *$//')
    
    # Пропускаем системные диски (слишком большие)
    if [[ "$DEV_SIZE" =~ ^[0-9]+T ]]; then
        continue
    fi
    
    echo "  $i) /dev/$DEV_NAME - $DEV_SIZE ($DEV_MODEL)"
    DEVICE_MAP[$i]="/dev/$DEV_NAME"
    ((i++))
done <<< "$DEVICES"

echo ""

if [ ${#DEVICE_MAP[@]} -eq 0 ]; then
    log_error "Подходящие USB-накопители не найдены"
    exit 1
fi

# Выбор устройства
DEVICE_NUM=$(read_from_terminal "  Выберите устройство [1-$((i-1))]: " "1")

if [ -z "${DEVICE_MAP[$DEVICE_NUM]}" ]; then
    log_error "Неверный номер устройства"
    exit 1
fi

USB_DEVICE="${DEVICE_MAP[$DEVICE_NUM]}"

# Получение информации о выбранном устройстве
USB_INFO=$(lsblk -nd -o SIZE,MODEL "$USB_DEVICE" 2>/dev/null)
echo ""
echo -e "  ${GREEN}Выбрано:${NC} $USB_DEVICE - $USB_INFO"
echo -e "  ${RED}⚠️ Все данные будут удалены!${NC}"
echo ""

if ! confirm_action "Продолжить?"; then
    log_error "Операция отменена пользователем"
    exit 1
fi

# ============================================================================
# Шаг 2: Проверка ISO-образа
# ============================================================================
log_step "Проверка ISO-образа"
echo ""

# Поиск ISO-образа в текущей директории и в Загрузках
ISO_FILENAME="REDOS-7.3.1-1.7.3-x86_64.iso"
ISO_PATH="./$ISO_FILENAME"

if [ ! -f "$ISO_PATH" ]; then
    ISO_PATH="$HOME/Загрузки/$ISO_FILENAME"
fi

if [ ! -f "$ISO_PATH" ]; then
    ISO_PATH="$HOME/Downloads/$ISO_FILENAME"
fi

# Проверка наличия ISO
if [ -f "$ISO_PATH" ]; then
    log_info "ISO-образ найден: $ISO_PATH"
    
    # Проверка контрольной суммы
    log_info "Проверка контрольной суммы..."
    ISO_SHA256=$(sha256sum "$ISO_PATH" | awk '{print $1}')
    log_info "SHA256: $ISO_SHA256"
    
    # Если указана ожидаемая сумма — проверить
    if [ -n "$ISO_EXPECTED_SHA256" ] && [ "$ISO_EXPECTED_SHA256" != "" ]; then
        if [ "$ISO_SHA256" = "$ISO_EXPECTED_SHA256" ]; then
            log_info "✓ Контрольная сумма совпадает"
        else
            log_warn "Контрольная сумма не совпадает!"
            log_warn "Ожидалось: $ISO_EXPECTED_SHA256"
            if ! confirm_action "Продолжить с этим ISO?"; then
                exit 1
            fi
        fi
    else
        log_warn "Сверьте сумму с данными на сайте: $ISO_DOWNLOAD_PAGE"
    fi
else
    log_info "ISO-образ не найден"
    echo ""
    echo -e "${YELLOW}Скачайте ISO-образ с официального сайта:${NC}"
    echo -e "  ${CYAN}$ISO_DOWNLOAD_PAGE${NC}"
    echo ""
    echo -e "${YELLOW}Порядок действий:${NC}"
    echo "  1. Откройте ссылку выше в браузере"
    echo "  2. Выберите версию: РЕД ОС 7.3"
    echo "  3. Скачайте ISO-образ"
    echo "  4. Скопируйте файл в эту папку или укажите полный путь"
    echo ""
    
    ISO_PATH=$(read_from_terminal "  Полный путь к ISO-образу: " "")
    
    if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
        log_error "ISO-образ не найден по указанному пути"
        exit 1
    fi
    
    ISO_FILENAME=$(basename "$ISO_PATH")
    log_info "ISO-образ выбран: $ISO_FILENAME"
    
    # Проверка контрольной суммы
    log_info "Проверка контрольной суммы..."
    ISO_SHA256=$(sha256sum "$ISO_PATH" | awk '{print $1}')
    log_info "SHA256: $ISO_SHA256"
    log_warn "Сверьте сумму с данными на сайте: $ISO_DOWNLOAD_PAGE"
fi

# Проверка размера ISO (должен быть >2GB)
ISO_SIZE=$(stat -c%s "$ISO_PATH" 2>/dev/null || echo "0")
if [ "$ISO_SIZE" -lt 2147483648 ]; then
    log_warn "Размер ISO меньше 2GB — возможен повреждённый образ"
fi

echo ""

# ============================================================================
# Шаг 3: Установка Ventoy
# ============================================================================
log_step "Установка Ventoy"
echo ""

VENTOY_DIR="./ventoy-${VENTOY_VERSION}"

# Проверка наличия Ventoy
if [ ! -d "$VENTOY_DIR" ]; then
    log_info "Загрузка Ventoy..."
    
    VENTOY_ARCHIVE="ventoy-${VENTOY_VERSION}-linux.tar.gz"
    
    if command -v wget &>/dev/null; then
        wget -q --show-progress "$VENTOY_URL" -O "$VENTOY_ARCHIVE"
    elif command -v curl &>/dev/null; then
        curl -sL "$VENTOY_URL" -o "$VENTOY_ARCHIVE"
    else
        log_error "wget или curl не установлены"
        exit 1
    fi
    
    check_success "Ventoy загружен"
    
    log_info "Распаковка Ventoy..."
    tar -xzf "$VENTOY_ARCHIVE"
    check_success "Ventoy распакован"
fi

# Установка Ventoy на флешку
log_info "Установка Ventoy на $USB_DEVICE..."

# Размонтирование устройства
umount "${USB_DEVICE}"* 2>/dev/null || true

# Установка Ventoy
cd "$VENTOY_DIR"
echo "y" | sudo ./Ventoy2Disk.sh -i "$USB_DEVICE" 2>&1 | while read line; do
    echo "  $line"
done

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log_info "✓ Ventoy установлен успешно"
else
    log_error "Ошибка установки Ventoy"
    exit 1
fi

cd ..

echo ""

# ============================================================================
# Шаг 4: Копирование ISO-образа
# ============================================================================
log_step "Копирование ISO-образа"
echo ""

# Монтирование флешки
MOUNT_POINT="/mnt/ventoy_$$"
mkdir -p "$MOUNT_POINT"

# Поиск раздела Ventoy (обычно второй раздел)
VENTOY_PARTITION="${USB_DEVICE}2"

# Попытка монтирования
for partition in "${USB_DEVICE}1" "${USB_DEVICE}2" "${USB_DEVICE}"; do
    if mount "$partition" "$MOUNT_POINT" 2>/dev/null; then
        VENTOY_PARTITION="$partition"
        break
    fi
done

check_success "Флешка смонтирована в $MOUNT_POINT"

# Копирование ISO
log_info "Копирование ISO-образа на флешку..."
cp -v "$ISO_FILENAME" "$MOUNT_POINT/"
check_success "ISO-образ скопирован"

# Размонтирование
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"
check_success "Флешка размонтирована"

echo ""

# ============================================================================
# Шаг 5: Настройка конфигурации
# ============================================================================
log_step "Настройка конфигурации"
echo ""

if confirm_action "Создать ventoy.json с кастомным меню?"; then
    # Повторное монтирование для записи конфигурации
    mkdir -p "$MOUNT_POINT"
    mount "$VENTOY_PARTITION" "$MOUNT_POINT" 2>/dev/null || {
        log_warn "Не удалось смонтировать флешку для записи конфигурации"
        CREATE_CONFIG="n"
    }
    
    if [ "$CREATE_CONFIG" = "y" ]; then
        # Создание директории config
        mkdir -p "$MOUNT_POINT/ventoy/config"
        
        # Создание ventoy.json
        cat > "$MOUNT_POINT/ventoy/config/ventoy.json" << EOF
{
    "theme": {
        "display_mode": "GUI",
        "resolution": "1920x1080",
        "theme": {
            "title": "Мультизагрузочная флешка - РЕД ОС",
            "footnote": "На основе Ventoy | github.com/teanrus/redos-lifehacks",
            "colors": {
                "normal": "light-gray/blue",
                "selected": "white/red",
                "border": "blue"
            }
        }
    },
    "menu_alias": {
        "REDOS-7.3.1-1.7.3-x86_64.iso": "РЕД ОС 7.3 (Основная)"
    },
    "persistent": {
        "REDOS-7.3.1-1.7.3-x86_64.iso": []
    }
}
EOF
        
        check_success "ventoy.json создан"
        
        # Размонтирование
        umount "$MOUNT_POINT"
        rmdir "$MOUNT_POINT"
    fi
else
    log_info "Настройка конфигурации пропущена"
fi

echo ""

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Подготовка завершена!"
log_header
echo ""

# Получение итоговой информации
USB_FINAL_INFO=$(lsblk -nd -o SIZE,MODEL "$USB_DEVICE" 2>/dev/null)

echo -e "${GREEN}Параметры флешки:${NC}"
echo "  Устройство: ${CYAN}$USB_DEVICE${NC}"
echo "  Информация: ${CYAN}$USB_FINAL_INFO${NC}"
echo "  ISO-образ: ${CYAN}$ISO_FILENAME${NC}"
if [ "$CREATE_CONFIG" = "y" ]; then
    echo "  Конфигурация: ${CYAN}ventoy.json создан${NC}"
fi
echo ""

echo -e "${GREEN}Дальнейшие действия:${NC}"
echo "  1. Извлеките флешку безопасно:"
echo "     ${CYAN}sudo eject $USB_DEVICE${NC}"
echo ""
echo "  2. Перезагрузите компьютер:"
echo "     ${CYAN}sudo reboot${NC}"
echo ""
echo "  3. Выберите загрузку с USB в Boot Menu:"
echo "     ${CYAN}F12 / F11 / F9 / Esc${NC} (зависит от производителя)"
echo ""

echo -e "${BLUE}Полезные команды:${NC}"
echo "  lsblk                    # проверить устройства"
echo "  ventoy/Ventoy2Disk.sh -l # список устройств Ventoy"
echo "  ventoy/Ventoy2Disk.sh -i /dev/sdX  # переустановить Ventoy"
echo ""

echo -e "${YELLOW}Горячие клавиши Ventoy:${NC}"
echo "  F1 — справка"
echo "  F2 — настройки темы"
echo "  F3 — классическое меню"
echo "  F4 — Secure Boot support"
echo "  F5 — Refresh ISO list"
echo "  F6 — Reload GRUB2"
echo ""

echo -e "${YELLOW}Скачать РЕД ОС:${NC}"
echo "  $ISO_DOWNLOAD_PAGE"
echo ""

log_info "Готово!"
