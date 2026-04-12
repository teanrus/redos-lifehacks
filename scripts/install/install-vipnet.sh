#!/bin/bash
# Установка ViPNet на РЕД ОС 7.3
# Версия: 1.0
# Описание: Установка ViPNet с выбором версии (Client или Client + Деловая почта)
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
WORK_DIR="/home/inst/vipnet"

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

# Функция настройки DNS для ViPNet (департамент образования)
setup_vipnet_dns() {
    echo -e "${GREEN}=== Настройка DNS для ViPNet (департамент образования) ===${NC}"
    
    if [ ! -f "/etc/vipnet.conf" ]; then
        echo -e "${RED}✗ Файл /etc/vipnet.conf не найден${NC}"
        echo -e "${YELLOW}ViPNet не установлен в системе. Настройка DNS невозможна.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Создание резервной копии /etc/vipnet.conf...${NC}"
    cp /etc/vipnet.conf /etc/vipnet.conf.backup.$(date +%Y%m%d_%H%M%S)
    check_success "Создание резервной копии ViPNet конфигурации"
    
    echo -e "${BLUE}Замена DNS-серверов на корпоративные (департамент образования)...${NC}"
    echo -e "${YELLOW}Старые DNS: 77.88.8.88,77.88.8.2${NC}"
    echo -e "${YELLOW}Новые DNS: 10.13.60.2,10.14.100.222${NC}"
    
    sed -i 's/77.88.8.88,77.88.8.2/10.13.60.2,10.14.100.222/' /etc/vipnet.conf
    check_success "Замена DNS-серверов"
    
    echo -e "${BLUE}Включение параметра iptables=off...${NC}"
    if grep -q ";iptables=off" /etc/vipnet.conf; then
        sed -i 's/;iptables=off/iptables=off/' /etc/vipnet.conf
        echo -e "${GREEN}✓ Параметр iptables=off раскомментирован${NC}"
    elif grep -q "iptables=off" /etc/vipnet.conf; then
        echo -e "${GREEN}✓ Параметр iptables=off уже активен${NC}"
    else
        echo "iptables=off" >> /etc/vipnet.conf
        echo -e "${GREEN}✓ Параметр iptables=off добавлен${NC}"
    fi
    
    echo -e "${GREEN}✓ Настройка DNS для ViPNet завершена${NC}"
    echo -e "${YELLOW}Для применения изменений перезапустите ViPNet: systemctl restart vipnet${NC}"
    
    return 0
}

# Функция установки ViPNet Client (без деловой почты)
install_vipnet_client() {
    echo -e "${GREEN}=== Установка ViPNet Client (без деловой почты) ===${NC}"
    
    # Проверка, не установлен ли уже ViPNet
    if rpm -q vipnetclient &>/dev/null; then
        echo -e "${YELLOW}ViPNet Client уже установлен${NC}"
        local installed_version=$(rpm -q vipnetclient 2>/dev/null)
        echo -e "${BLUE}Установленная версия: $installed_version${NC}"
        if confirm_action "Переустановить ViPNet Client?"; then
            echo -e "${BLUE}Удаление старой версии...${NC}"
            dnf remove -y vipnetclient
        else
            echo -e "${YELLOW}Пропускаем установку ViPNet Client${NC}"
            return 0
        fi
    fi
    
    # Скачивание ViPNet Client
    download_from_github "vipnetclient-gui_gost_ru_x86-64_4.15.0-26717.rpm" "$WORK_DIR" "$LATEST_TAG"
    
    if [ -f "$WORK_DIR/vipnetclient-gui_gost_ru_x86-64_4.15.0-26717.rpm" ]; then
        echo -e "${BLUE}Установка ViPNet Client...${NC}"
        dnf install -y "$WORK_DIR/vipnetclient-gui_gost_ru_x86-64_4.15.0-26717.rpm"
        check_success "Установка ViPNet Client"
        rm -f "$WORK_DIR/vipnetclient-gui_gost_ru_x86-64_4.15.0-26717.rpm"
        
        echo -e "${GREEN}✓ ViPNet Client успешно установлен${NC}"
        echo -e "${BLUE}Запуск: vipnet или через меню приложений${NC}"
    else
        echo -e "${RED}✗ Не удалось загрузить ViPNet Client${NC}"
        return 1
    fi
}

# Функция установки ViPNet + Деловая почта (DP)
install_vipnet_dp() {
    echo -e "${GREEN}=== Установка ViPNet + Деловая почта (DP) ===${NC}"
    
    # Проверка, не установлен ли уже ViPNet
    if rpm -q vipnetclient &>/dev/null; then
        echo -e "${YELLOW}ViPNet уже установлен${NC}"
        if confirm_action "Удалить существующую версию перед установкой DP?"; then
            echo -e "${BLUE}Удаление старой версии...${NC}"
            dnf remove -y vipnetclient
        else
            echo -e "${YELLOW}Пропускаем установку ViPNet DP${NC}"
            return 0
        fi
    fi
    
    # Скачивание ViPNet DP
    download_from_github "VipNet-DP.tar.gz" "$WORK_DIR" "$LATEST_TAG"
    
    if [ -f "$WORK_DIR/VipNet-DP.tar.gz" ]; then
        cd "$WORK_DIR"
        
        echo -e "${BLUE}Распаковка архива...${NC}"
        tar -xzf VipNet-DP.tar.gz
        
        if [ -d "VipNet-DP" ]; then
            cd VipNet-DP
            
            echo -e "${BLUE}Установка пакетов ViPNet DP...${NC}"
            for rpm in *.rpm; do
                if [ -f "$rpm" ]; then
                    echo -e "${BLUE}Установка: $rpm${NC}"
                    dnf install -y "$rpm"
                fi
            done
            
            cd "$WORK_DIR"
            rm -rf VipNet-DP
            rm -f VipNet-DP.tar.gz
            
            check_success "Установка ViPNet + Деловая почта"
            
            echo -e "${GREEN}✓ ViPNet + Деловая почта успешно установлены${NC}"
            echo -e "${BLUE}Запуск: vipnet или через меню приложений${NC}"
        else
            echo -e "${RED}✗ Папка VipNet-DP не найдена в архиве${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Не удалось загрузить ViPNet-DP.tar.gz${NC}"
        return 1
    fi
}

# Функция выбора версии ViPNet
select_vipnet_version() {
    echo -e "${GREEN}=== Выбор версии ViPNet ===${NC}"
    echo "1. ViPNet Client (без деловой почты) — один RPM-пакет"
    echo "2. ViPNet + Деловая почта (DP) — два RPM-пакета в архиве"
    echo ""
    
    local choice=$(read_from_terminal "${YELLOW}Выберите вариант (1 или 2):${NC}")
    
    case $choice in
        1)
            install_vipnet_client
            ;;
        2)
            install_vipnet_dp
            ;;
        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите 1 или 2.${NC}"
            select_vipnet_version
            return 1
            ;;
    esac
    return 0
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
echo -e "${GREEN}    Установка ViPNet    ${NC}"
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

# Проверка архитектуры
if [[ $(uname -m) != "x86_64" ]]; then
    echo -e "${RED}Ошибка: ViPNet доступен только для x86_64 архитектуры${NC}"
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

# === 3. СОЗДАНИЕ РАБОЧЕЙ ДИРЕКТОРИИ ===
echo -e "${GREEN}=== 3. Подготовка рабочей директории ===${NC}"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1
check_success "Создание рабочей директории $WORK_DIR"

echo ""

# === 4. УСТАНОВКА VIPNET ===
echo -e "${GREEN}=== 4. Установка ViPNet ===${NC}"

if confirm_action "Установить ViPNet?"; then
    select_vipnet_version
else
    echo -e "${YELLOW}Пропускаем установку ViPNet${NC}"
fi

echo ""

# === 5. НАСТРОЙКА DNS ДЛЯ VIPNET ===
echo -e "${GREEN}=== 5. Настройка DNS для ViPNet ===${NC}"
echo -e "${YELLOW}Внимание! Замена DNS на корпоративные (10.13.60.2, 10.14.100.222)${NC}"
echo -e "${YELLOW}необходима ТОЛЬКО для работы в локальной сети департамента образования.${NC}"
echo -e "${YELLOW}Если вы работаете в другой сети или через интернет, оставьте DNS без изменений.${NC}"

if confirm_action "Заменить DNS на корпоративные?"; then
    setup_vipnet_dns
else
    echo -e "${YELLOW}Пропускаем настройку DNS. DNS-серверы остаются без изменений.${NC}"
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
echo -e "${GREEN}    Установка ViPNet завершена!    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Время завершения: $(date)${NC}"
echo -e "${BLUE}Использованная версия: $LATEST_TAG${NC}"
echo ""

echo -e "${GREEN}Статус установки:${NC}"
rpm -q vipnetclient &>/dev/null && echo "  ✓ ViPNet Client"
rpm -q vipnet-dp &>/dev/null && echo "  ✓ ViPNet + Деловая почта"
[ -f /etc/vipnet.conf ] && echo "  ✓ Конфигурация ViPNet: /etc/vipnet.conf"

echo ""
echo -e "${GREEN}Полезные команды:${NC}"
echo -e "  ${BLUE}• Запуск ViPNet:${NC} vipnet"
echo -e "  ${BLUE}• Статус службы:${NC} systemctl status vipnet"
echo -e "  ${BLUE}• Перезапуск службы:${NC} systemctl restart vipnet"
echo -e "  ${BLUE}• Просмотр конфигурации:${NC} cat /etc/vipnet.conf"

echo ""
echo -e "${YELLOW}Рекомендации:${NC}"
echo -e "  ${YELLOW}• После установки лицензии перезагрузите систему${NC}"
echo -e "  ${YELLOW}• Если изменили DNS, перезапустите ViPNet: systemctl restart vipnet${NC}"
echo -e "  ${YELLOW}• Для работы ViPNet может потребоваться настройка сетевых интерфейсов${NC}"

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