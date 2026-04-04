#!/bin/bash
# Установка КриптоПро CSP на РЕД ОС 7.3
# Версия: 1.5
# Описание: Установка КриптоПро CSP, драйверов Рутокен и дополнительных компонентов
#           Автоматически использует последнюю версию из репозитория

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === КОНФИГУРАЦИЯ ===
GITHUB_USER="teanrus"
GITHUB_REPO="redos-setup"

# Рабочая директория
WORK_DIR="/home/inst/cryptopro"

# Функция для запроса подтверждения
confirm_action() {
    local message=$1
    local answer
    echo -e "${YELLOW}$message (y/n)${NC}"
    read -r answer
    if [[ $answer =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Функция для безопасного чтения ввода из терминала
read_from_terminal() {
    local prompt=$1
    local answer
    echo -e "$prompt" >&2
    read -r answer < /dev/tty 2>/dev/null || true
    echo "$answer"
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

# Функция проверки наличия установленного КриптоПро
check_cryptopro_installed() {
    # Проверяем различные возможные названия пакетов
    local packages=(
        "crypto-pro"
        "cprocsp"
        "cprocsp-csp"
        "cprocsp-rdr-rutoken"
        "lsb-cprocsp-base"
    )
    
    for pkg in "${packages[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            local installed_version=$(rpm -q "$pkg")
            echo -e "${YELLOW}Обнаружен установленный пакет: $installed_version${NC}"
            return 0
        fi
    done
    
    # Проверяем наличие исполняемых файлов
    if command -v cryptcp &> /dev/null; then
        local version=$(cryptcp -version 2>/dev/null | head -1)
        echo -e "${YELLOW}Обнаружен КриптоПро CSP: $version${NC}"
        return 0
    fi
    
    return 1
}

# Функция получения последней версии релиза (возвращает только тег)
get_latest_tag() {
    local user=$1
    local repo=$2
    
    echo -e "${BLUE}Получение информации о последнем релизе...${NC}" >&2
    
    # Получаем данные о последнем релизе через GitHub API
    local api_url="https://api.github.com/repos/$user/$repo/releases/latest"
    local latest_tag=$(curl -s "$api_url" | grep '"tag_name"' | head -1 | cut -d '"' -f 4)
    
    if [ -z "$latest_tag" ]; then
        echo -e "${RED}✗ Не удалось получить последнюю версию${NC}" >&2
        return 1
    fi
    
    echo -e "${GREEN}✓ Найдена последняя версия: $latest_tag${NC}" >&2
    echo "$latest_tag"
    return 0
}

# Функция скачивания с GitHub
download_from_github() {
    local file_name=$1
    local dest_dir=$2
    local tag=$3
    
    local url="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/download/$tag/$file_name"
    
    echo -e "${BLUE}Загрузка $file_name (версия: $tag)...${NC}"
    echo -e "${BLUE}URL: $url${NC}"
    
    if ! curl -s --head -f "$url" > /dev/null 2>&1; then
        echo -e "${RED}✗ Файл $file_name не найден в релизе $tag${NC}"
        return 1
    fi
    
    if wget --progress=bar:force -O "$dest_dir/$file_name" "$url" 2>&1; then
        echo -e "${GREEN}✓ $file_name успешно загружен${NC}"
        return 0
    else
        echo -e "${RED}✗ Ошибка загрузки $file_name${NC}"
        return 1
    fi
}

# Функция удаления старой версии КриптоПро
remove_old_cryptopro() {
    echo -e "${BLUE}Удаление старой версии КриптоПро...${NC}"
    
    # Список пакетов для удаления
    local packages=(
        "crypto-pro"
        "cprocsp*"
        "lsb-cprocsp*"
    )
    
    for pkg in "${packages[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            dnf remove -y "$pkg"
        fi
    done
    
    # Удаляем конфигурационные файлы
    rm -rf /etc/cprocsp 2>/dev/null
    rm -rf /opt/cprocsp 2>/dev/null
    
    check_success "Удаление старой версии"
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Этот скрипт должен запускаться с правами root${NC}"
   echo -e "${YELLOW}Запустите: sudo $0${NC}"
   exit 1
fi

# Проверка, что /dev/tty доступен
if [ ! -e /dev/tty ]; then
    echo -e "${RED}Ошибка: /dev/tty не доступен. Запустите скрипт в интерактивном терминале.${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Установка КриптоПро CSP    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Дата запуска: $(date)${NC}"
echo ""

# === 1. ПОЛУЧЕНИЕ ПОСЛЕДНЕЙ ВЕРСИИ ===
echo -e "${GREEN}=== 1. Поиск последней версии в репозитории ===${NC}"

LATEST_TAG=$(get_latest_tag "$GITHUB_USER" "$GITHUB_REPO")
GET_TAG_RESULT=$?

if [ $GET_TAG_RESULT -ne 0 ] || [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}Не удалось определить последнюю версию. Укажите версию вручную.${NC}"
    echo -e "${YELLOW}Введите тег версии (например: v2.7):${NC}"
    read -r LATEST_TAG < /dev/tty
    if [ -z "$LATEST_TAG" ]; then
        echo -e "${RED}Версия не указана. Установка отменена.${NC}"
        exit 1
    fi
fi

echo ""

# === 2. ПРОВЕРКА СИСТЕМЫ ===
echo -e "${GREEN}=== 2. Проверка системы ===${NC}"

if [ -f /etc/redos-release ]; then
    echo -e "${BLUE}Версия ОС: $(cat /etc/redos-release)${NC}"
else
    echo -e "${YELLOW}Внимание: не удалось определить версию ОС${NC}"
fi

echo -e "${BLUE}Архитектура: $(uname -m)${NC}"
echo -e "${BLUE}Ядро: $(uname -r)${NC}"

# Проверка архитектуры
if [[ $(uname -m) != "x86_64" ]]; then
    echo -e "${RED}Ошибка: КриптоПро CSP доступен только для x86_64 архитектуры${NC}"
    exit 1
fi

# Проверка наличия необходимых команд
for cmd in wget curl tar; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Устанавливаю $cmd...${NC}"
        dnf install -y $cmd
        check_success "Установка $cmd"
    fi
done

echo ""

# === 3. ПРОВЕРКА НАЛИЧИЯ УСТАНОВЛЕННОЙ ВЕРСИИ ===
echo -e "${GREEN}=== 3. Проверка наличия установленной версии ===${NC}"

if check_cryptopro_installed; then
    echo -e "${YELLOW}Обнаружена установленная версия КриптоПро${NC}"
    if confirm_action "Удалить существующую версию перед установкой?"; then
        remove_old_cryptopro
    else
        echo -e "${YELLOW}Установка будет продолжена поверх существующей версии${NC}"
        echo -e "${YELLOW}Внимание: это может привести к конфликтам!${NC}"
    fi
else
    echo -e "${GREEN}КриптоПро не обнаружен, будет выполнена чистая установка${NC}"
fi

echo ""

# === 4. УСТАНОВКА ЗАВИСИМОСТЕЙ ===
echo -e "${GREEN}=== 4. Установка зависимостей ===${NC}"

DEPENDENCIES="ifd-rutokens token-manager gostcryptogui caja-gostcryptogui pcsc-lite pcsc-lite-ccid"

echo -e "${BLUE}Установка пакетов: $DEPENDENCIES${NC}"
dnf install -y $DEPENDENCIES
check_success "Установка зависимостей"

# Включение службы PC/SC для работы с токенами
systemctl enable --now pcscd
check_success "Включение службы PC/SC"

echo ""

# === 5. СОЗДАНИЕ РАБОЧЕЙ ДИРЕКТОРИИ ===
echo -e "${GREEN}=== 5. Подготовка рабочей директории ===${NC}"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1
check_success "Создание рабочей директории $WORK_DIR"

echo ""

# === 6. ЗАГРУЗКА И УСТАНОВКА КРИПТОПРО ===
echo -e "${GREEN}=== 6. Загрузка и установка КриптоПро CSP ===${NC}"

echo -e "${BLUE}Загрузка КриптоПро из репозитория redos-setup...${NC}"
download_from_github "kriptopror4.tar.gz" "$WORK_DIR" "$LATEST_TAG"

if [ -f "$WORK_DIR/kriptopror4.tar.gz" ]; then
    echo -e "${BLUE}Распаковка архива...${NC}"
    tar -xzf kriptopror4.tar.gz
    rm -f kriptopror4.tar.gz
    
    # Проверяем структуру: внутри архива есть папка kriptopror4
    if [ -d "kriptopror4" ]; then
        echo -e "${BLUE}Найдена папка kriptopror4, переходим в нее...${NC}"
        cd kriptopror4
        INSTALL_DIR="$WORK_DIR/kriptopror4"
    elif [ -d "R4" ]; then
        echo -e "${BLUE}Найдена папка R4, переходим в нее...${NC}"
        cd R4
        INSTALL_DIR="$WORK_DIR/R4"
    elif [ -d "cprocsp" ]; then
        echo -e "${BLUE}Найдена папка cprocsp, переходим в нее...${NC}"
        cd cprocsp
        INSTALL_DIR="$WORK_DIR/cprocsp"
    else
        # Если папка не найдена, возможно файлы сразу в корне
        INSTALL_DIR="$WORK_DIR"
    fi
    
    echo -e "${BLUE}Текущая директория: $(pwd)${NC}"
    
    # Установка КриптоПро
    if [ -f "install_gui.sh" ]; then
        echo -e "${BLUE}Найден графический установщик install_gui.sh${NC}"
        
        # Проверка наличия X-сервера
        if [ -n "$DISPLAY" ] || [ -f /tmp/.X11-unix/X0 ]; then
            echo -e "${BLUE}Графическая среда обнаружена, запускаем графический установщик...${NC}"
            chmod +x install_gui.sh
            ./install_gui.sh
            check_success "Установка КриптоПро (графический режим)"
        else
            echo -e "${YELLOW}Графическая среда не обнаружена.${NC}"
            if [ -f "install.sh" ]; then
                echo -e "${BLUE}Запуск текстового установщика...${NC}"
                chmod +x install.sh
                ./install.sh
                check_success "Установка КриптоПро (текстовый режим)"
            else
                echo -e "${RED}Не найден установщик КриптоПро${NC}"
                exit 1
            fi
        fi
    elif [ -f "install.sh" ]; then
        echo -e "${BLUE}Запуск текстового установщика install.sh...${NC}"
        chmod +x install.sh
        ./install.sh
        check_success "Установка КриптоПро"
    elif ls *.rpm 1> /dev/null 2>&1; then
        echo -e "${BLUE}Установка RPM-пакетов...${NC}"
        dnf install -y *.rpm
        check_success "Установка КриптоПро из RPM-пакетов"
    else
        echo -e "${RED}Не найдены установочные файлы КриптоПро${NC}"
        echo -e "${RED}Содержимое директории:$(ls -la)${NC}"
        exit 1
    fi
else
    echo -e "${RED}Не удалось загрузить КриптоПро из репозитория${NC}"
    exit 1
fi

echo ""

# === 7. ПРОВЕРКА УСТАНОВКИ ===
echo -e "${GREEN}=== 7. Проверка установки ===${NC}"

if command -v cryptcp &> /dev/null; then
    echo -e "${GREEN}✓ КриптоПро CSP успешно установлен${NC}"
    echo -e "${BLUE}Версия: $(cryptcp -version 2>/dev/null | head -1)${NC}"
else
    echo -e "${YELLOW}Команда cryptcp не найдена. Проверьте установку вручную.${NC}"
fi

if command -v csptest &> /dev/null; then
    echo -e "${GREEN}✓ csptest доступен${NC}"
else
    echo -e "${YELLOW}csptest не найден${NC}"
fi

if systemctl is-active pcscd &>/dev/null; then
    echo -e "${GREEN}✓ Служба PC/SC активна${NC}"
else
    echo -e "${YELLOW}Служба PC/SC не активна${NC}"
fi

echo ""

# === 8. НАСТРОЙКА РУТОКЕН ===
echo -e "${GREEN}=== 8. Настройка Рутокен ===${NC}"

if confirm_action "Выполнить настройку для работы с Рутокен?"; then
    # Добавление пользователя в группу pcscd
    if [ -n "$SUDO_USER" ]; then
        usermod -a -G pcscd "$SUDO_USER"
        echo -e "${GREEN}✓ Пользователь $SUDO_USER добавлен в группу pcscd${NC}"
    fi
    
    # Проверка подключения токена
    echo -e "${BLUE}Проверка подключенных токенов...${NC}"
    if command -v rutoken-control &> /dev/null; then
        rutoken-control -l
    elif command -v pcsc_scan &> /dev/null; then
        pcsc_scan -n
    else
        echo -e "${YELLOW}Утилиты для проверки токенов не найдены${NC}"
        echo -e "${YELLOW}Установите pcsc-tools для диагностики: dnf install pcsc-tools${NC}"
    fi
fi

echo ""

# === 9. ЛИЦЕНЗИРОВАНИЕ ===
echo -e "${GREEN}=== 9. Лицензирование КриптоПро ===${NC}"

if confirm_action "Установить лицензию КриптоПро?"; then
    echo -e "${YELLOW}Введите серийный номер лицензии:${NC}"
    read -r serial_number < /dev/tty
    
    if [ -n "$serial_number" ]; then
        if command -v cryptcp &> /dev/null; then
            cryptcp -license -set "$serial_number"
            check_success "Установка лицензии"
        else
            echo -e "${RED}КриптоПро не установлен корректно${NC}"
        fi
    else
        echo -e "${YELLOW}Серийный номер не введен, лицензирование пропущено${NC}"
    fi
fi

echo ""

# === 10. НАСТРОЙКА ГОСТ-ШИФРОВАНИЯ ===
echo -e "${GREEN}=== 10. Настройка ГОСТ-шифрования ===${NC}"

if confirm_action "Настроить интеграцию ГОСТ-шифрования с файловым менеджером?"; then
    if command -v caja &> /dev/null; then
        echo -e "${BLUE}Настройка Caja...${NC}"
        if [ -n "$SUDO_USER" ]; then
            mkdir -p "/home/$SUDO_USER/.local/share/caja/extensions/"
            if [ -f /usr/lib64/caja/extensions/libcaja-gostcryptogui.so ]; then
                ln -sf /usr/lib64/caja/extensions/libcaja-gostcryptogui.so "/home/$SUDO_USER/.local/share/caja/extensions/"
                echo -e "${GREEN}✓ Интеграция с Caja настроена${NC}"
            fi
        fi
    fi
fi

echo ""

# === 11. ОЧИСТКА ===
echo -e "${GREEN}=== 11. Очистка временных файлов ===${NC}"

if confirm_action "Удалить временные файлы установки?"; then
    cd /
    rm -rf "$WORK_DIR"
    echo -e "${GREEN}✓ Временные файлы удалены${NC}"
else
    echo -e "${YELLOW}Временные файлы сохранены в $WORK_DIR${NC}"
fi

echo ""

# === 12. ИТОГИ ===
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Установка КриптоПро завершена!    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Время завершения: $(date)${NC}"
echo -e "${BLUE}Использованная версия: $LATEST_TAG${NC}"
echo ""

echo -e "${GREEN}Статус установки:${NC}"
command -v cryptcp &>/dev/null && echo "  ✓ КриптоПро CSP: установлен"
command -v csptest &>/dev/null && echo "  ✓ csptest: доступен"
systemctl is-active pcscd &>/dev/null && echo "  ✓ PC/SC: активен"
echo ""

echo -e "${GREEN}Полезные команды:${NC}"
echo -e "  ${BLUE}• Просмотр лицензии:${NC} cryptcp -license -view"
echo -e "  ${BLUE}• Список контейнеров:${NC} csptest -keyset -enum_cont"
echo -e "  ${BLUE}• Проверка токенов:${NC} pcsc_scan -n"
echo -e "  ${BLUE}• Статус службы:${NC} systemctl status pcscd"

echo ""
echo -e "${YELLOW}Рекомендации:${NC}"
echo -e "  ${YELLOW}• После установки лицензии перезагрузите систему${NC}"
echo -e "  ${YELLOW}• Для работы с Рутокен убедитесь, что токен подключен${NC}"
echo -e "  ${YELLOW}• При проблемах с чтением токена перезапустите службу: systemctl restart pcscd${NC}"

# Запрос на перезагрузку
echo ""
if confirm_action "Перезагрузить систему сейчас?"; then
    echo -e "${BLUE}Перезагрузка через 5 секунд...${NC}"
    sleep 5
    sync
    reboot
else
    echo -e "${GREEN}Перезагрузка отменена.${NC}"
    echo -e "${YELLOW}Для корректной работы рекомендуется перезагрузить систему.${NC}"
fi