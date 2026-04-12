#!/bin/bash
#
# Скрипт установки офисных пакетов для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-office.sh | sudo bash
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

# Проверка ОС
if [[ -f /etc/os-release ]]; then
    OS_ID=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    if [[ "$OS_ID" != "redos" ]]; then
        log_warn "Скрипт разработан для РЕД ОС, обнаружена: $OS_ID"
        log_warn "Продолжение работы возможно, но не гарантируется"
    fi
fi

log_header
log_info "Установка офисных пакетов в РЕД ОС"
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
echo ""

# Проверка установленных офисных пакетов
echo -e "${BLUE}Установленные офисные пакеты:${NC}"
LIBREOFFICE_VER=$(rpm -q libreoffice 2>/dev/null | head -1 || echo "не установлен")
R7_VER=$(rpm -q r7-office 2>/dev/null | head -1 || echo "не установлен")
MYOFFICE_VER=$(rpm -q myoffice-documents-desktop 2>/dev/null | head -1 || rpm -q myoffice 2>/dev/null | head -1 || echo "не установлен")

echo "  LibreOffice:  ${LIBREOFFICE_VER}"
echo "  Р7-Офис:      ${R7_VER}"
echo "  МойОфис:      ${MYOFFICE_VER}"
echo ""

# ============================================================================
# Настройка DNF
# ============================================================================
if confirm_action "Настроить DNF для быстрой загрузки пакетов?"; then
    log_info "Настройка DNF..."
    
    # Резервное копирование
    cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Добавление оптимизаций (если ещё не добавлены)
    if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
    fi
    if ! grep -q "fastestmirror" /etc/dnf/dnf.conf; then
        echo "fastestmirror=True" >> /etc/dnf/dnf.conf
    fi
    if ! grep -q "deltarpm" /etc/dnf/dnf.conf; then
        echo "deltarpm=True" >> /etc/dnf/dnf.conf
    fi
    
    check_success "Настройки DNF применены"
fi
echo ""

# ============================================================================
# Добавление репозиториев
# ============================================================================
log_header
echo -e "${BLUE}Добавление репозиториев:${NC}"
log_header
echo ""

# Репозиторий R7 Office
if confirm_action "Добавить репозиторий Р7-Офис?"; then
    if ! rpm -q r7-release &>/dev/null; then
        log_info "Установка репозитория R7 Office..."
        dnf install -y r7-release
        check_success "Репозиторий R7 Office установлен"
    else
        echo -e "${GREEN}✓ Репозиторий R7 Office уже установлен${NC}"
    fi
fi

# Информация о МойОфис
echo ""
echo -e "${CYAN}ℹ МойОфис устанавливается вручную через RPM-пакет${NC}"
echo -e "${CYAN}  Скачать можно с официального сайта: https://myoffice.ru/${NC}"
if confirm_action "Показать инструкцию по установке МойОфис?"; then
    echo ""
    echo -e "${BLUE}=== Инструкция по установке МойОфис ===${NC}"
    echo "1. Скачайте RPM-пакет с https://myoffice.ru/"
    echo "2. Установите командой:"
    echo -e "   ${YELLOW}sudo dnf install -y ./myoffice-documents-desktop*.rpm${NC}"
    echo ""
    echo "При ошибках зависимостей:"
    echo -e "   ${YELLOW}sudo dnf install -f ./myoffice-documents-desktop*.rpm${NC}"
    echo ""
    echo "Особенности МойОфис:"
    echo "  • Бесплатная версия для частных лиц"
    echo "  • Поддержка СКЗИ через КриптоПро CSP"
    echo "  • Сертификат ФСТЭК"
    echo "  • В реестре отечественного ПО"
    echo ""
fi

# Обновление кэша
if rpm -q r7-release &>/dev/null; then
    log_info "Обновление кэша репозиториев..."
    dnf makecache
    check_success "Кэш репозиториев обновлён"
fi
echo ""

# ============================================================================
# Установка офисных пакетов
# ============================================================================
log_header
echo -e "${BLUE}Установка офисных пакетов:${NC}"
log_header
echo ""

# LibreOffice (встроен в РЕД ОС)
if ! rpm -q libreoffice &>/dev/null; then
    if confirm_action "Установить LibreOffice (базовый пакет)?"; then
        log_info "Установка LibreOffice..."
        dnf install -y libreoffice
        check_success "LibreOffice установлен"
    fi
else
    echo -e "${GREEN}✓ LibreOffice уже установлен${NC}"
fi

# Р7-Офис
if ! rpm -q r7-office &>/dev/null; then
    if confirm_action "Установить Р7-Офис (коммерческий, требуется лицензия)?"; then
        log_info "Установка Р7-Офис..."
        dnf install -y r7-office
        check_success "Р7-Офис установлен"
        echo -e "${CYAN}  Запуск: Меню → Офис → Р7 Офис${NC}"
        echo -e "${CYAN}  Или: r7-office (из терминала)${NC}"
    fi
else
    echo -e "${GREEN}✓ Р7-Офис уже установлен${NC}"
fi

# МойОфис (проверка установки)
if ! rpm -q myoffice-documents-desktop &>/dev/null && ! rpm -q myoffice &>/dev/null; then
    echo ""
    if confirm_action "Установить МойОфис (бесплатно для частных лиц)?"; then
        echo -e "${YELLOW}Для установки МойОфис:"
        echo "1. Скачайте RPM-пакет с https://myoffice.ru/products/download/desktop/"
        echo "2. Запустите установку:"
        echo -e "   ${CYAN}sudo dnf install -y ./myoffice-documents-desktop*.rpm${NC}"
        echo ""
        echo -e "${CYAN}После установки запустите этот скрипт снова для проверки.${NC}"
    fi
else
    echo -e "${GREEN}✓ МойОфис уже установлен${NC}"
fi
echo ""

# ============================================================================
# Дополнительные утилиты
# ============================================================================
log_header
echo -e "${BLUE}Дополнительные утилиты для офиса:${NC}"
log_header
echo ""

EXTRA_PACKAGES=()

if confirm_action "Установить pavucontrol (управление звуком)?"; then
    EXTRA_PACKAGES+=("pavucontrol")
fi

if confirm_action "Установить pinta (простой графический редактор)?"; then
    EXTRA_PACKAGES+=("pinta")
fi

if confirm_action "Установить sshfs (работа с сетевыми файлами)?"; then
    EXTRA_PACKAGES+=("sshfs")
fi

if confirm_action "Установить утилиты для работы с PDF (pdfmod)?"; then
    EXTRA_PACKAGES+=("pdfmod")
fi

if [ ${#EXTRA_PACKAGES[@]} -gt 0 ]; then
    log_info "Установка дополнительных утилит: ${EXTRA_PACKAGES[*]}..."
    dnf install -y "${EXTRA_PACKAGES[@]}"
    check_success "Дополнительные утилиты установлены"
else
    echo -e "${YELLOW}Установка дополнительных утилит пропущена${NC}"
fi
echo ""

# ============================================================================
# Настройка офисных пакетов по умолчанию
# ============================================================================
log_header
echo -e "${BLUE}Настройка пакетов по умолчанию:${NC}"
log_header
echo ""

# Определение доступных офисных пакетов
OFFICE_PACKAGES=()
rpm -q libreoffice &>/dev/null && OFFICE_PACKAGES+=("LibreOffice")
rpm -q r7-office &>/dev/null && OFFICE_PACKAGES+=("Р7-Офис")
rpm -q myoffice-documents-desktop &>/dev/null && OFFICE_PACKAGES+=("МойОфис")
rpm -q myoffice &>/dev/null && OFFICE_PACKAGES+=("МойОфис")

if [ ${#OFFICE_PACKAGES[@]} -gt 1 ]; then
    echo -e "${CYAN}Обнаружено офисных пакетов: ${OFFICE_PACKAGES[*]}${NC}"
    echo ""
    echo "Выберите пакет по умолчанию для документов:"
    echo "  1) LibreOffice"
    echo "  2) Р7-Офис"
    echo "  3) МойОфис"
    echo "  4) Пропустить настройку"
    echo ""

    DEFAULT_CHOICE=$(read_from_terminal "${YELLOW}Ваш выбор (1-4):${NC}")

    case $DEFAULT_CHOICE in
        1)
            xdg-mime default libreoffice-writer.desktop application/vnd.oasis.opendocument.text
            xdg-mime default libreoffice-writer.desktop application/msword
            xdg-mime default libreoffice-calc.desktop application/vnd.oasis.opendocument.spreadsheet
            xdg-mime default libreoffice-calc.desktop application/vnd.ms-excel
            echo -e "${GREEN}✓ LibreOffice установлен по умолчанию${NC}"
            ;;
        2)
            xdg-mime default r7-office-writer.desktop application/vnd.oasis.opendocument.text
            xdg-mime default r7-office-writer.desktop application/msword
            xdg-mime default r7-office-calc.desktop application/vnd.oasis.opendocument.spreadsheet
            xdg-mime default r7-office-calc.desktop application/vnd.ms-excel
            echo -e "${GREEN}✓ Р7-Офис установлен по умолчанию${NC}"
            ;;
        3)
            xdg-mime default myoffice-writer.desktop application/vnd.oasis.opendocument.text
            xdg-mime default myoffice-writer.desktop application/msword
            xdg-mime default myoffice-calc.desktop application/vnd.oasis.opendocument.spreadsheet
            xdg-mime default myoffice-calc.desktop application/vnd.ms-excel
            echo -e "${GREEN}✓ МойОфис установлен по умолчанию${NC}"
            ;;
        *)
            echo -e "${YELLOW}Настройка пропущена${NC}"
            ;;
    esac
fi
echo ""

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Установка офисных пакетов завершена!"
log_header
echo ""

echo -e "${GREEN}Установленные пакеты:${NC}"
rpm -q libreoffice 2>/dev/null && echo "  ✓ LibreOffice"
rpm -q r7-office 2>/dev/null && echo "  ✓ Р7-Офис"
rpm -q myoffice-documents-desktop 2>/dev/null && echo "  ✓ МойОфис"
rpm -q myoffice 2>/dev/null && echo "  ✓ МойОфис"

echo ""
echo -e "${GREEN}Установленные утилиты:${NC}"
rpm -q pavucontrol 2>/dev/null && echo "  ✓ pavucontrol"
rpm -q pinta 2>/dev/null && echo "  ✓ pinta"
rpm -q sshfs 2>/dev/null && echo "  ✓ sshfs"
rpm -q pdfmod 2>/dev/null && echo "  ✓ pdfmod"

echo ""
echo -e "${BLUE}Полезные команды:${NC}"
echo "  r7-office              # запуск Р7-Офис"
echo "  lowriter               # запуск LibreOffice Writer"
echo "  localc                 # запуск LibreOffice Calc"
echo "  myoffice-writer        # запуск МойОфис Документы"
echo ""

echo -e "${BLUE}Проверка установленных пакетов:${NC}"
echo "  rpm -qa | grep -E 'libreoffice|r7-office|myoffice'  # список офисных пакетов"
echo "  dnf repolist                                          # список репозиториев"
echo ""

echo -e "${YELLOW}Рекомендации:${NC}"
echo "  • Для активации Р7-Офис поместите лицензию в /etc/r7-office/license/"
echo "  • Для работы с криптографией в МойОфис установите КриптоПро CSP"
echo "  • Проверьте настройки по умолчанию: xdg-mime query default application/msword"
echo ""

log_info "Готово!"
