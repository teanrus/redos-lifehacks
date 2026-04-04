#!/bin/bash
# Установка 1С:Предприятие на РЕД ОС 7.3
# Версия: 1.0
# Описание: Установка платформы 1С:Предприятие версии 8.3.24.1691
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
WORK_DIR="/home/inst/1c"

# Версия 1С
ONEC_VERSION="8.3.24.1691"
ONEC_DIR="lin_8_3_24_1691"

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

# Функция проверки наличия установленной 1С
check_1c_installed() {
    if [ -d "/opt/1cv8" ]; then
        echo -e "${YELLOW}Обнаружена установленная 1С:Предприятие${NC}"
        if [ -f "/opt/1cv8/version" ]; then
            local installed_version=$(cat /opt/1cv8/version 2>/dev/null)
            echo -e "${BLUE}Установленная версия: $installed_version${NC}"
        fi
        return 0
    fi
    return 1
}

# Функция удаления старой версии 1С
remove_old_1c() {
    echo -e "${BLUE}Удаление старой версии 1С...${NC}"
    
    # Останавливаем службы 1С
    systemctl stop srv1cv83 2>/dev/null
    systemctl stop ragent 2>/dev/null
    
    # Удаляем пакеты 1С
    dnf remove -y 1c-enterprise* 2>/dev/null
    
    # Удаляем директории
    rm -rf /opt/1cv8 2>/dev/null
    rm -rf /home/*/.1cv8 2>/dev/null
    
    echo -e "${GREEN}✓ Старая версия 1С удалена${NC}"
}

# Функция установки зависимостей для 1С
install_1c_dependencies() {
    echo -e "${GREEN}=== Установка зависимостей для 1С ===${NC}"
    
    local dependencies=(
        "glibc"
        "libX11"
        "libXext"
        "libXrender"
        "libXft"
        "libXScrnSaver"
        "fontconfig"
        "libpng12"
        "libjpeg-turbo"
        "freetype"
        "zlib"
    )
    
    for dep in "${dependencies[@]}"; do
        dnf install -y "$dep" 2>/dev/null || true
    done
    
    echo -e "${GREEN}✓ Зависимости установлены${NC}"
}

# Функция установки шрифтов для 1С
install_1c_fonts() {
    echo -e "${GREEN}=== Установка шрифтов для 1С ===${NC}"
    
    # Создание директории для шрифтов
    mkdir -p /usr/share/fonts/1c
    
    # Копирование шрифтов (если есть в архиве)
    if [ -d "$WORK_DIR/$ONEC_DIR/fonts" ]; then
        cp -r "$WORK_DIR/$ONEC_DIR/fonts/"* /usr/share/fonts/1c/ 2>/dev/null
    fi
    
    # Обновление кэша шрифтов
    fc-cache -fv
    
    echo -e "${GREEN}✓ Шрифты для 1С установлены${NC}"
}

# Функция установки 1С
install_1c() {
    echo -e "${GREEN}=== Установка 1С:Предприятие $ONEC_VERSION ===${NC}"
    
    cd "$WORK_DIR" || exit 1
    
    # Скачивание архива
    download_from_github "1c.tar.gz" "$WORK_DIR" "$LATEST_TAG"
    
    if [ -f "$WORK_DIR/1c.tar.gz" ]; then
        echo -e "${BLUE}Распаковка архива...${NC}"
        tar -xzf 1c.tar.gz
        rm -f 1c.tar.gz
        
        if [ -d "$ONEC_DIR" ]; then
            cd "$ONEC_DIR"
            
            # Установка прав на выполнение
            chmod +x setup-full-${ONEC_VERSION}-x86_64.run
            chmod +x fix.sh
            
            # Установка зависимостей
            install_1c_dependencies
            
            # Установка шрифтов
            install_1c_fonts
            
            # Запуск установщика
            echo -e "${BLUE}Запуск установщика 1С...${NC}"
            echo -e "${YELLOW}Следуйте инструкциям графического установщика${NC}"
            ./setup-full-${ONEC_VERSION}-x86_64.run
            
            # Применение фиксов
            echo -e "${BLUE}Применение фиксов для корректной работы...${NC}"
            ./fix.sh
            
            cd "$WORK_DIR"
            rm -rf "$ONEC_DIR"
            
            echo -e "${GREEN}✓ 1С:Предприятие успешно установлена${NC}"
        else
            echo -e "${RED}✗ Папка $ONEC_DIR не найдена в архиве${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Не удалось загрузить 1c.tar.gz${NC}"
        return 1
    fi
}

# Функция настройки 1С после установки
configure_1c() {
    echo -e "${GREEN}=== Настройка 1С:Предприятие ===${NC}"
    
    # Создание директории для баз
    mkdir -p /home/1c-bases
    chmod 755 /home/1c-bases
    
    # Настройка переменных окружения
    if [ -f /etc/profile.d/1c.sh ]; then
        echo -e "${YELLOW}Файл /etc/profile.d/1c.sh уже существует${NC}"
    else
        cat > /etc/profile.d/1c.sh << 'EOF'
#!/bin/bash
# Переменные окружения для 1С:Предприятие
export PATH=$PATH:/opt/1cv8/x86_64
EOF
        chmod +x /etc/profile.d/1c.sh
        echo -e "${GREEN}✓ Создан файл окружения /etc/profile.d/1c.sh${NC}"
    fi
    
    # Настройка службы сервера 1С (опционально)
    if confirm_action "Настроить службу сервера 1С (для работы в клиент-серверном режиме)?"; then
        if [ -f "/opt/1cv8/x86_64/ragent" ]; then
            cat > /etc/systemd/system/1c-server.service << 'EOF'
[Unit]
Description=1C:Enterprise Server
After=network.target

[Service]
Type=forking
User=usr1cv8
Group=grp1cv8
ExecStart=/opt/1cv8/x86_64/ragent -daemon
ExecStop=/opt/1cv8/x86_64/ragent -stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
            
            # Создание пользователя и группы
            groupadd -r grp1cv8 2>/dev/null
            useradd -r -g grp1cv8 -d /home/usr1cv8 -s /sbin/nologin usr1cv8 2>/dev/null
            
            systemctl daemon-reload
            systemctl enable 1c-server
            systemctl start 1c-server
            
            echo -e "${GREEN}✓ Служба сервера 1С настроена${NC}"
        else
            echo -e "${YELLOW}Серверная версия 1С не установлена, настройка службы пропущена${NC}"
        fi
    fi
    
    # Создание ярлыка на рабочем столе
    if [ -n "$SUDO_USER" ]; then
        local desktop_dir="/home/$SUDO_USER/Рабочий стол"
        if [ ! -d "$desktop_dir" ]; then
            desktop_dir="/home/$SUDO_USER/Desktop"
        fi
        
        if [ -d "$desktop_dir" ]; then
            cat > "$desktop_dir/1c.desktop" << 'EOF'
[Desktop Entry]
Name=1С:Предприятие
Comment=1C:Enterprise
Exec=/opt/1cv8/x86_64/1cv8
Icon=/opt/1cv8/x86_64/1c.png
Terminal=false
Type=Application
Categories=Office;Finance;
EOF
            chmod +x "$desktop_dir/1c.desktop"
            chown "$SUDO_USER:$SUDO_USER" "$desktop_dir/1c.desktop"
            echo -e "${GREEN}✓ Создан ярлык на рабочем столе${NC}"
        fi
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
echo -e "${GREEN}    Установка 1С:Предприятие    ${NC}"
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
    echo -e "${RED}Ошибка: 1С:Предприятие доступна только для x86_64 архитектуры${NC}"
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

if check_1c_installed; then
    if confirm_action "Удалить существующую версию 1С перед установкой?"; then
        remove_old_1c
    else
        echo -e "${YELLOW}Установка отменена пользователем${NC}"
        exit 0
    fi
fi

echo ""

# === 4. СОЗДАНИЕ РАБОЧЕЙ ДИРЕКТОРИИ ===
echo -e "${GREEN}=== 4. Подготовка рабочей директории ===${NC}"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1
check_success "Создание рабочей директории $WORK_DIR"

echo ""

# === 5. УСТАНОВКА 1С ===
echo -e "${GREEN}=== 5. Установка 1С:Предприятие ===${NC}"

if confirm_action "Установить 1С:Предприятие?"; then
    install_1c
else
    echo -e "${YELLOW}Пропускаем установку 1С${NC}"
    exit 0
fi

echo ""

# === 6. НАСТРОЙКА 1С ===
echo -e "${GREEN}=== 6. Настройка 1С:Предприятие ===${NC}"

if confirm_action "Выполнить дополнительную настройку 1С (ярлык, окружение)?"; then
    configure_1c
else
    echo -e "${YELLOW}Пропускаем дополнительную настройку${NC}"
fi

echo ""

# === 7. ОЧИСТКА ===
echo -e "${GREEN}=== 7. Очистка временных файлов ===${NC}"

if confirm_action "Удалить временные файлы установки?"; then
    cd /
    rm -rf "$WORK_DIR"
    echo -e "${GREEN}✓ Временные файлы удалены${NC}"
else
    echo -e "${YELLOW}Временные файлы сохранены в $WORK_DIR${NC}"
fi

echo ""

# === 8. ИТОГИ ===
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Установка 1С:Предприятие завершена!    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Время завершения: $(date)${NC}"
echo -e "${BLUE}Использованная версия: $LATEST_TAG${NC}"
echo ""

echo -e "${GREEN}Статус установки:${NC}"
[ -d "/opt/1cv8" ] && echo "  ✓ 1С:Предприятие установлена в /opt/1cv8"
[ -d "/home/1c-bases" ] && echo "  ✓ Директория для баз: /home/1c-bases"
[ -f "/etc/profile.d/1c.sh" ] && echo "  ✓ Переменные окружения: /etc/profile.d/1c.sh"
[ -f "/etc/systemd/system/1c-server.service" ] && echo "  ✓ Служба сервера 1С: активна"

echo ""
echo -e "${GREEN}Полезные команды:${NC}"
echo -e "  ${BLUE}• Запуск 1С:${NC} 1cv8"
echo -e "  ${BLUE}• Директория установки:${NC} /opt/1cv8"
echo -e "  ${BLUE}• Директория для баз:${NC} /home/1c-bases"
echo -e "  ${BLUE}• Статус службы:${NC} systemctl status 1c-server"

echo ""
echo -e "${YELLOW}Рекомендации:${NC}"
echo -e "  ${YELLOW}• После установки перезагрузите систему для применения всех настроек${NC}"
echo -e "  ${YELLOW}• Для работы 1С в клиент-серверном режиме запустите службу: systemctl start 1c-server${NC}"
echo -e "  ${YELLOW}• Создайте первую базу данных через конфигуратор 1С${NC}"

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