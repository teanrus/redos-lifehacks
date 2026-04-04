#!/bin/bash
# Установка мессенджеров на РЕД ОС 7.3
# Версия: 1.2
# Описание: Установка мессенджеров Telegram, СРЕДА, MAX, VK Messenger
# GitHub: https://github.com/teanrus/redos-lifehacks

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
WORK_DIR="/home/inst/messengers"

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

# Функция получения последней версии релиза
get_latest_tag() {
    local user=$1
    local repo=$2
    
    echo -e "${BLUE}Получение информации о последнем релизе...${NC}" >&2
    
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
    
    echo -e "${BLUE}Загрузка $file_name...${NC}"
    
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

# Функция установки Telegram
install_telegram() {
    echo -e "${GREEN}=== Установка Telegram ===${NC}"
    
    if command -v telegram &> /dev/null || [ -f "/opt/telegram/Telegram" ]; then
        echo -e "${YELLOW}Telegram уже установлен${NC}"
        if confirm_action "Переустановить Telegram?"; then
            echo -e "${BLUE}Удаление старой версии...${NC}"
            rm -rf /opt/telegram
            rm -f /usr/bin/telegram
            rm -f /usr/share/applications/telegram.desktop
        else
            echo -e "${YELLOW}Пропускаем установку Telegram${NC}"
            return 0
        fi
    fi
    
    download_from_github "tsetup.tar.xz" "$WORK_DIR" "$LATEST_TAG"
    
    if [ -f "$WORK_DIR/tsetup.tar.xz" ]; then
        cd "$WORK_DIR"
        
        echo -e "${BLUE}Распаковка Telegram...${NC}"
        tar -xJf tsetup.tar.xz
        
        mkdir -p /opt/telegram
        cp -r Telegram/* /opt/telegram/
        ln -sf /opt/telegram/Telegram /usr/bin/telegram
        chmod +x /opt/telegram/Telegram
        
        cat > /usr/share/applications/telegram.desktop << 'EOF'
[Desktop Entry]
Name=Telegram
Comment=Telegram Desktop
Exec=/opt/telegram/Telegram
Icon=/opt/telegram/telegram.png
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=Telegram
MimeType=x-scheme-handler/tg;
EOF
        
        chmod +x /usr/share/applications/telegram.desktop
        
        rm -rf Telegram
        rm -f tsetup.tar.xz
        
        echo -e "${GREEN}✓ Telegram успешно установлен${NC}"
        echo -e "${BLUE}Запуск: telegram или через меню приложений${NC}"
    else
        echo -e "${RED}✗ Не удалось загрузить Telegram${NC}"
        return 1
    fi
}

# Функция установки СРЕДА
install_sreda() {
    echo -e "${GREEN}=== Установка СРЕДА ===${NC}"
    
    if command -v sreda &> /dev/null; then
        echo -e "${YELLOW}СРЕДА уже установлена${NC}"
        local installed_version=$(rpm -q sreda 2>/dev/null)
        echo -e "${BLUE}Установленная версия: $installed_version${NC}"
        if confirm_action "Переустановить СРЕДА?"; then
            echo -e "${BLUE}Удаление старой версии...${NC}"
            dnf remove -y sreda
        else
            echo -e "${YELLOW}Пропускаем установку СРЕДА${NC}"
            return 0
        fi
    fi
    
    download_from_github "sreda.rpm" "$WORK_DIR" "$LATEST_TAG"
    
    if [ -f "$WORK_DIR/sreda.rpm" ]; then
        echo -e "${BLUE}Установка СРЕДА...${NC}"
        dnf install -y "$WORK_DIR/sreda.rpm"
        check_success "Установка СРЕДА"
        rm -f "$WORK_DIR/sreda.rpm"
        
        echo -e "${GREEN}✓ СРЕДА успешно установлена${NC}"
        echo -e "${BLUE}Запуск: sreda или через меню приложений${NC}"
    else
        echo -e "${RED}✗ Не удалось загрузить СРЕДА${NC}"
        return 1
    fi
}

# Функция установки MAX
install_max() {
    echo -e "${GREEN}=== Установка MAX ===${NC}"
    
    if command -v max &> /dev/null; then
        echo -e "${YELLOW}MAX уже установлен${NC}"
        local installed_version=$(rpm -q max 2>/dev/null)
        echo -e "${BLUE}Установленная версия: $installed_version${NC}"
        if confirm_action "Переустановить MAX?"; then
            echo -e "${BLUE}Удаление старой версии...${NC}"
            dnf remove -y max
        else
            echo -e "${YELLOW}Пропускаем установку MAX${NC}"
            return 0
        fi
    fi
    
    if [ ! -f /etc/yum.repos.d/max.repo ]; then
        echo -e "${BLUE}Добавление репозитория MAX...${NC}"
        cat > /etc/yum.repos.d/max.repo << 'EOF'
[max]
name=MAX Desktop
baseurl=https://download.max.ru/linux/rpm/el/9/x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://download.max.ru/linux/rpm/public.asc
sslverify=1
metadata_expire=300
EOF
        rpm --import https://download.max.ru/linux/rpm/public.asc
        dnf makecache
    fi
    
    echo -e "${BLUE}Установка MAX...${NC}"
    dnf install -y max
    check_success "Установка MAX"
    
    echo -e "${GREEN}✓ MAX успешно установлен${NC}"
    echo -e "${BLUE}Запуск: max или через меню приложений${NC}"
}

# Функция установки VK Messenger
install_vk_messenger() {
    echo -e "${GREEN}=== Установка VK Messenger ===${NC}"
    
    if command -v vk-messenger &> /dev/null; then
        echo -e "${YELLOW}VK Messenger уже установлен${NC}"
        local installed_version=$(rpm -q vk-messenger 2>/dev/null)
        echo -e "${BLUE}Установленная версия: $installed_version${NC}"
        if confirm_action "Переустановить VK Messenger?"; then
            echo -e "${BLUE}Удаление старой версии...${NC}"
            dnf remove -y vk-messenger
        else
            echo -e "${YELLOW}Пропускаем установку VK Messenger${NC}"
            return 0
        fi
    fi
    
    download_from_github "vk-messenger.rpm" "$WORK_DIR" "$LATEST_TAG"
    
    if [ -f "$WORK_DIR/vk-messenger.rpm" ]; then
        echo -e "${BLUE}Установка VK Messenger...${NC}"
        dnf install -y "$WORK_DIR/vk-messenger.rpm"
        check_success "Установка VK Messenger"
        rm -f "$WORK_DIR/vk-messenger.rpm"
        
        echo -e "${GREEN}✓ VK Messenger успешно установлен${NC}"
        echo -e "${BLUE}Запуск: vk-messenger или через меню приложений${NC}"
    else
        echo -e "${RED}✗ Не удалось загрузить VK Messenger${NC}"
        return 1
    fi
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
echo -e "${GREEN}    Установка мессенджеров    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Дата запуска: $(date)${NC}"
echo ""

# === 1. ПОЛУЧЕНИЕ ПОСЛЕДНЕЙ ВЕРСИИ ===
echo -e "${GREEN}=== 1. Поиск последней версии в репозитории ===${NC}"

LATEST_TAG=$(get_latest_tag "$GITHUB_USER" "$GITHUB_REPO")
GET_TAG_RESULT=$?

if [ $GET_TAG_RESULT -ne 0 ] || [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}Не удалось определить последнюю версию. Укажите версию вручную.${NC}"
    LATEST_TAG=$(read_from_terminal "${YELLOW}Введите тег версии (например: v2.7):${NC}")
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
fi

echo -e "${BLUE}Архитектура: $(uname -m)${NC}"
echo -e "${BLUE}Ядро: $(uname -r)${NC}"

# Проверка наличия необходимых команд
for cmd in wget curl tar; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Устанавливаю $cmd...${NC}"
        dnf install -y $cmd
        check_success "Установка $cmd"
    fi
done

echo ""

# === 3. СОЗДАНИЕ РАБОЧЕЙ ДИРЕКТОРИИ ===
echo -e "${GREEN}=== 3. Подготовка рабочей директории ===${NC}"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1
check_success "Создание рабочей директории $WORK_DIR"

echo ""

# === 4. ВЫБОР МЕССЕНДЖЕРОВ ДЛЯ УСТАНОВКИ ===
echo -e "${GREEN}=== 4. Выбор мессенджеров для установки ===${NC}"
echo -e "${YELLOW}Будут установлены только выбранные мессенджеры${NC}"
echo ""

# Telegram
if confirm_action "Установить мессенджер Telegram?"; then
    install_telegram
else
    echo -e "${YELLOW}Пропускаем установку Telegram${NC}"
fi

echo ""

# СРЕДА
if confirm_action "Установить корпоративный мессенджер СРЕДА?"; then
    install_sreda
else
    echo -e "${YELLOW}Пропускаем установку СРЕДА${NC}"
fi

echo ""

# MAX
if confirm_action "Установить мессенджер MAX?"; then
    install_max
else
    echo -e "${YELLOW}Пропускаем установку MAX${NC}"
fi

echo ""

# === 5. ДОПОЛНИТЕЛЬНЫЕ МЕССЕНДЖЕРЫ ===
echo -e "${GREEN}=== 5. Дополнительные мессенджеры ===${NC}"

# VK Messenger
if confirm_action "Установить мессенджер ВК (VK Messenger)?"; then
    install_vk_messenger
else
    echo -e "${YELLOW}Пропускаем установку VK Messenger${NC}"
fi

echo ""

# === 6. ОЧИСТКА ===
echo -e "${GREEN}=== 6. Очистка временных файлов ===${NC}"

if confirm_action "Удалить временные файлы установки?"; then
    cd /
    rm -rf "$WORK_DIR"
    echo -e "${GREEN}✓ Временные файлы удалены${NC}"
else
    echo -e "${YELLOW}Временные файлы сохранены в $WORK_DIR${NC}"
fi

echo ""

# === 7. ИТОГИ ===
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Установка мессенджеров завершена!    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Время завершения: $(date)${NC}"
echo -e "${BLUE}Использованная версия: $LATEST_TAG${NC}"
echo ""

echo -e "${GREEN}Установленные мессенджеры:${NC}"
command -v telegram &>/dev/null && echo "  ✓ Telegram"
[ -f /usr/share/applications/telegram.desktop ] && echo "  ✓ Telegram (ярлык)"
command -v sreda &>/dev/null && echo "  ✓ СРЕДА"
command -v max &>/dev/null && echo "  ✓ MAX"
command -v vk-messenger &>/dev/null && echo "  ✓ VK Messenger"

echo ""
echo -e "${GREEN}Полезные команды:${NC}"
echo -e "  ${BLUE}• Telegram:${NC} telegram"
echo -e "  ${BLUE}• СРЕДА:${NC} sreda"
echo -e "  ${BLUE}• MAX:${NC} max"
echo -e "  ${BLUE}• VK Messenger:${NC} vk-messenger"

echo ""
echo -e "${YELLOW}Рекомендации:${NC}"
echo -e "  ${YELLOW}• После установки запустите мессенджеры из меню приложений${NC}"
echo -e "  ${YELLOW}• Для Telegram может потребоваться вход через QR-код${NC}"
echo -e "  ${YELLOW}• Для работы СРЕДА требуется корпоративный аккаунт${NC}"
echo -e "  ${YELLOW}• MAX требует настройки подключения к серверу${NC}"