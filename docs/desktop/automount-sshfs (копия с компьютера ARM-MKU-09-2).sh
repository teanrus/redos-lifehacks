#!/bin/bash
#
# Скрипт настройки автомонтирования SSHFS для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/automount-sshfs.sh | sudo bash
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
SSH_USER=""
SSH_HOST=""
SSH_PORT="22"
REMOTE_PATH=""
LOCAL_PATH=""
SSH_KEY_PATH=""
MOUNT_METHOD=""

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
# Сбор информации о подключении
# ============================================================================
log_header
log_info "Настройка автомонтирования SSHFS в РЕД ОС"
log_header
echo ""

log_step "Сбор информации о подключении"
echo ""

# Получение текущего пользователя
CURRENT_USER=$(whoami)
DEFAULT_LOCAL_PATH="/home/$CURRENT_USER/mnt/remote"

echo -e "${CYAN}Параметры SSH подключения:${NC}"
SSH_USER=$(read_from_terminal "  Пользователь SSH [${CURRENT_USER}]: " "$CURRENT_USER")
SSH_HOST=$(read_from_terminal "  Хост (IP или домен): " "")

if [ -z "$SSH_HOST" ]; then
    log_error "Хост не может быть пустым"
    exit 1
fi

SSH_PORT=$(read_from_terminal "  Порт SSH [22]: " "22")
REMOTE_PATH=$(read_from_terminal "  Удалённый путь [/home/$SSH_USER]: " "/home/$SSH_USER")
LOCAL_PATH=$(read_from_terminal "  Локальная точка монтирования [$DEFAULT_LOCAL_PATH]: " "$DEFAULT_LOCAL_PATH")

echo ""
echo -e "  ${GREEN}Параметры подключения:${NC}"
echo -e "    Хост: ${CYAN}$SSH_HOST${NC}"
echo -e "    Пользователь: ${CYAN}$SSH_USER${NC}"
echo -e "    Порт: ${CYAN}$SSH_PORT${NC}"
echo -e "    Удалённый путь: ${CYAN}$REMOTE_PATH${NC}"
echo -e "    Локальный путь: ${CYAN}$LOCAL_PATH${NC}"
echo ""

if ! confirm_action "Подтверждаете параметры подключения?"; then
    log_error "Настройка отменена пользователем"
    exit 1
fi

# ============================================================================
# Проверка и установка SSHFS
# ============================================================================
log_header
log_step "Проверка и установка SSHFS"
log_header
echo ""

if command -v sshfs &>/dev/null; then
    log_info "SSHFS уже установлен: $(sshfs --version | head -1)"
else
    log_info "SSHFS не найден"
    if confirm_action "Установить SSHFS?"; then
        log_info "Установка пакетов sshfs и fuse..."
        dnf install -y sshfs fuse
        check_success "SSHFS установлен"
    else
        log_error "Без SSHFS настройка невозможна"
        exit 1
    fi
fi

# Проверка модуля FUSE
if ! lsmod | grep -q fuse; then
    log_warn "Модуль FUSE не загружен"
    if confirm_action "Загрузить модуль FUSE?"; then
        modprobe fuse
        check_success "Модуль FUSE загружен"
    fi
fi

echo ""

# ============================================================================
# Настройка SSH-ключей
# ============================================================================
log_header
log_step "Настройка SSH-ключей"
log_header
echo ""

# Определение домашнего каталога пользователя
if [ "$CURRENT_USER" = "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$CURRENT_USER"
fi

SSH_KEY_PATH="$HOME_DIR/.ssh/id_rsa_sshfs"

# Проверка существующих ключей
if [ -f "$SSH_KEY_PATH" ]; then
    log_info "SSH-ключ уже существует: $SSH_KEY_PATH"
    if ! confirm_action "Использовать существующий ключ?"; then
        log_info "Генерация нового ключа..."
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "sshfs-mount-$SSH_HOST"
        check_success "SSH-ключ сгенерирован"
    fi
else
    log_info "SSH-ключ не найден"
    if confirm_action "Сгенерировать новый SSH-ключ для SSHFS?"; then
        mkdir -p "$HOME_DIR/.ssh"
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "sshfs-mount-$SSH_HOST"
        check_success "SSH-ключ сгенерирован"
        
        # Установка правильных прав
        chmod 700 "$HOME_DIR/.ssh"
        chmod 600 "$SSH_KEY_PATH"
        chown -R "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.ssh"
        check_success "Права на SSH-ключ установлены"
    else
        log_warn "Без SSH-ключей автоматическое монтирование не будет работать"
    fi
fi

# Копирование ключа на сервер
if [ -f "$SSH_KEY_PATH" ]; then
    echo ""
    if confirm_action "Скопировать SSH-ключ на сервер ($SSH_USER@$SSH_HOST)?"; then
        log_info "Копирование ключа на сервер..."
        ssh-copy-id -i "$SSH_KEY_PATH" -p "$SSH_PORT" "$SSH_USER@$SSH_HOST"
        check_success "SSH-ключ скопирован на сервер"
        
        # Проверка подключения
        log_info "Проверка подключения..."
        if ssh -i "$SSH_KEY_PATH" -p "$SSH_PORT" -o BatchMode=yes "$SSH_USER@$SSH_HOST" "echo OK" &>/dev/null; then
            log_info "Подключение успешно"
        else
            log_warn "Подключение не удалось, проверьте настройки сервера"
        fi
    fi
fi

echo ""

# ============================================================================
# Выбор метода автомонтирования
# ============================================================================
log_header
log_step "Выбор метода автомонтирования"
log_header
echo ""

echo -e "${CYAN}Доступные методы:${NC}"
echo "  1) /etc/fstab - классический способ"
echo "  2) systemd - современный способ с контролем состояния"
echo "  3) Автозагрузка пользователя - монтирование при входе в сессию"
echo "  4) Пропустить автомонтирование"
echo ""

MOUNT_METHOD=$(read_from_terminal "  Выберите метод [1-4]: " "1")

case $MOUNT_METHOD in
    1)
        # ============================================================================
        # Метод 1: /etc/fstab
        # ============================================================================
        log_info "Настройка автомонтирования через /etc/fstab"
        echo ""

        # Создание точки монтирования
        mkdir -p "$LOCAL_PATH"
        chown "$CURRENT_USER:$CURRENT_USER" "$LOCAL_PATH"
        check_success "Точка монтирования создана: $LOCAL_PATH"

        # Проверка /etc/fuse.conf
        if ! grep -q "user_allow_other" /etc/fuse.conf 2>/dev/null; then
            if confirm_action "Разрешить allow_other в /etc/fuse.conf?"; then
                echo "user_allow_other" >> /etc/fuse.conf
                check_success "user_allow_other добавлен в /etc/fuse.conf"
            fi
        fi

        # Добавление записи в fstab
        FSTAB_ENTRY="$SSH_USER@$SSH_HOST:$REMOTE_PATH $LOCAL_PATH fuse.sshfs _netdev,auto,user,identityfile=$SSH_KEY_PATH,uid=$CURRENT_USER,gid=$CURRENT_USER 0 0"
        
        echo ""
        echo -e "${CYAN}Запись для добавления в /etc/fstab:${NC}"
        echo "  $FSTAB_ENTRY"
        echo ""

        if confirm_action "Добавить эту запись в /etc/fstab?"; then
            echo "$FSTAB_ENTRY" >> /etc/fstab
            check_success "Запись добавлена в /etc/fstab"

            # Тестовое монтирование
            echo ""
            if confirm_action "Выполнить тестовое монтирование?"; then
                mount -a
                if mount | grep -q "$LOCAL_PATH"; then
                    log_info "Монтирование выполнено успешно"
                else
                    log_warn "Монтирование не удалось, проверьте настройки"
                fi
            fi
        fi
        ;;

    2)
        # ============================================================================
        # Метод 2: systemd
        # ============================================================================
        log_info "Настройка автомонтирования через systemd"
        echo ""

        # Создание точки монтирования
        mkdir -p "$LOCAL_PATH"
        chown "$CURRENT_USER:$CURRENT_USER" "$LOCAL_PATH"
        check_success "Точка монтирования создана: $LOCAL_PATH"

        # Преобразование пути в формат systemd
        SYSTEMD_NAME=$(echo "$LOCAL_PATH" | sed 's|^/||' | sed 's|/|-|g')
        SYSTEMD_UNIT="/etc/systemd/system/${SYSTEMD_NAME}.mount"

        # Создание юнит-файла
        cat > "$SYSTEMD_UNIT" << EOF
[Unit]
Description=SSHFS mount for $SSH_USER@$SSH_HOST:$REMOTE_PATH
After=network-online.target
Wants=network-online.target

[Mount]
What=$SSH_USER@$SSH_HOST:$REMOTE_PATH
Where=$LOCAL_PATH
Type=fuse.sshfs
Options=_netdev,auto,identityfile=$SSH_KEY_PATH,uid=$CURRENT_USER,gid=$CURRENT_USER,reconnect,ServerAliveInterval=15

[Install]
WantedBy=multi-user.target
EOF

        check_success "Юнит-файл создан: $SYSTEMD_UNIT"

        # Включение службы
        echo ""
        if confirm_action "Включить и запустить службу монтирования?"; then
            systemctl daemon-reload
            systemctl enable "${SYSTEMD_NAME}.mount"
            systemctl start "${SYSTEMD_NAME}.mount"
            check_success "Служба монтирования запущена"

            # Проверка статуса
            echo ""
            log_info "Статус службы:"
            systemctl status "${SYSTEMD_NAME}.mount" --no-pager | head -10
        fi
        ;;

    3)
        # ============================================================================
        # Метод 3: Автозагрузка пользователя
        # ============================================================================
        log_info "Настройка монтирования при входе пользователя"
        echo ""

        # Создание директорий
        AUTOSTART_DIR="$HOME_DIR/.config/autostart"
        AUTOSTART_SCRIPTS_DIR="$HOME_DIR/.config/autostart-scripts"
        mkdir -p "$AUTOSTART_DIR" "$AUTOSTART_SCRIPTS_DIR"

        # Создание скрипта монтирования
        MOUNT_SCRIPT="$AUTOSTART_SCRIPTS_DIR/mount-sshfs.sh"
        cat > "$MOUNT_SCRIPT" << EOF
#!/bin/bash
# Скрипт автомонтирования SSHFS
# Создан: $(date)

sleep 10

# Создание точки монтирования
mkdir -p $LOCAL_PATH

# Монтирование с опциями
sshfs -o identityfile=$SSH_KEY_PATH,reconnect,ServerAliveInterval=15,cache_timeout=300 \\
    $SSH_USER@$SSH_HOST:$REMOTE_PATH $LOCAL_PATH

echo "SSHFS: смонтировано $SSH_USER@$SSH_HOST:$REMOTE_PATH -> $LOCAL_PATH"
EOF

        chmod +x "$MOUNT_SCRIPT"
        chown "$CURRENT_USER:$CURRENT_USER" "$MOUNT_SCRIPT" "$AUTOSTART_DIR" "$AUTOSTART_SCRIPTS_DIR"
        check_success "Скрипт монтирования создан: $MOUNT_SCRIPT"

        # Создание .desktop файла
        DESKTOP_FILE="$AUTOSTART_DIR/sshfs-mount.desktop"
        cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Exec=$MOUNT_SCRIPT
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=SSHFS Mount
Comment=Автоматическое монтирование SSHFS при входе
EOF

        chown "$CURRENT_USER:$CURRENT_USER" "$DESKTOP_FILE"
        check_success "Файл автозагрузки создан: $DESKTOP_FILE"

        # Добавление размонтирования при выходе
        BASH_LOGOUT="$HOME_DIR/.bash_logout"
        if ! grep -q "fusermount.*$LOCAL_PATH" "$BASH_LOGOUT" 2>/dev/null; then
            echo ""
            if confirm_action "Добавить размонтирование при выходе из сессии?"; then
                echo "" >> "$BASH_LOGOUT"
                echo "# Размонтирование SSHFS" >> "$BASH_LOGOUT"
                echo "fusermount -u $LOCAL_PATH 2>/dev/null || true" >> "$BASH_LOGOUT"
                check_success "Размонтирование добавлено в ~/.bash_logout"
            fi
        fi
        ;;

    4)
        log_info "Автомонтирование пропущено"
        ;;

    *)
        log_error "Неверный выбор метода"
        exit 1
        ;;
esac

echo ""

# ============================================================================
# Дополнительные опции
# ============================================================================
log_header
log_step "Дополнительные опции"
log_header
echo ""

# Проверка доступности сервера
if confirm_action "Проверить доступность сервера перед завершением?"; then
    log_info "Проверка доступности $SSH_HOST..."
    if ping -c 2 -W 2 "$SSH_HOST" &>/dev/null; then
        log_info "Сервер доступен"
    else
        log_warn "Сервер не отвечает на ping (возможно, ICMP заблокирован)"
    fi

    # Проверка SSH порта
    log_info "Проверка SSH порта $SSH_PORT..."
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$SSH_HOST/$SSH_PORT" 2>/dev/null; then
        log_info "SSH порт $SSH_PORT открыт"
    else
        log_warn "SSH порт $SSH_PORT недоступен"
    fi
fi

echo ""

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Настройка завершена!"
log_header
echo ""

echo -e "${GREEN}Параметры подключения:${NC}"
echo "  Хост: ${CYAN}$SSH_HOST${NC}"
echo "  Пользователь: ${CYAN}$SSH_USER${NC}"
echo "  Порт: ${CYAN}$SSH_PORT${NC}"
echo "  Удалённый путь: ${CYAN}$REMOTE_PATH${NC}"
echo "  Локальный путь: ${CYAN}$LOCAL_PATH${NC}"
echo "  SSH-ключ: ${CYAN}$SSH_KEY_PATH${NC}"
echo ""

echo -e "${GREEN}Полезные команды:${NC}"
echo "  mount | grep sshfs              # проверить смонтированные SSHFS"
echo "  fusermount -u $LOCAL_PATH       # размонтировать"
echo "  sshfs $SSH_USER@$SSH_HOST:$REMOTE_PATH $LOCAL_PATH  # смонтировать вручную"
echo "  journalctl -u ${SYSTEMD_NAME}.mount -f  # логи systemd (если используется)"
echo ""

if [ "$MOUNT_METHOD" = "1" ]; then
    echo -e "${YELLOW}Для применения изменений в fstab выполните:${NC}"
    echo "  sudo mount -a"
    echo ""
elif [ "$MOUNT_METHOD" = "2" ]; then
    echo -e "${YELLOW}Для управления службой используйте:${NC}"
    echo "  systemctl status ${SYSTEMD_NAME}.mount"
    echo "  systemctl restart ${SYSTEMD_NAME}.mount"
    echo ""
elif [ "$MOUNT_METHOD" = "3" ]; then
    echo -e "${YELLOW}Монтирование произойдёт при следующем входе в сессию${NC}"
    echo "Для проверки выполните скрипт вручную:"
    echo "  $MOUNT_SCRIPT"
    echo ""
fi

log_info "Готово!"
