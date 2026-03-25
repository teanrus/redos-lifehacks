#!/bin/bash
# Скрипт очистки системы от временных файлов
# Версия: 1.0
# Описание: Безопасная очистка временных файлов, кэша, логов и неиспользуемых пакетов

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Функция для показа размера директории
show_size() {
    local dir=$1
    if [ -d "$dir" ]; then
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo -e "${BLUE}  Размер: $size${NC}"
    fi
}

# Функция безопасного удаления
safe_remove() {
    local path=$1
    if [ -e "$path" ]; then
        rm -rf "$path" 2>/dev/null
        echo -e "${GREEN}✓ Удалено: $path${NC}"
    fi
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Этот скрипт должен запускаться с правами root${NC}"
   echo -e "${YELLOW}Запустите: sudo $0${NC}"
   exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Очистка системы от временных файлов    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Дата запуска: $(date)${NC}"
echo ""

# === ОПРЕДЕЛЕНИЕ ДОМАШНЕЙ ДИРЕКТОРИИ ===
if [ -n "$SUDO_USER" ]; then
    HOME_DIR=$(eval echo ~$SUDO_USER)
else
    HOME_DIR=$HOME
fi

echo -e "${GREEN}=== 1. Анализ дискового пространства ===${NC}"
echo -e "${BLUE}До очистки:${NC}"
df -h /

echo ""
echo -e "${GREEN}=== 2. Очистка временных файлов ===${NC}"

# 2.1. Временные файлы в /tmp
if confirm_action "Очистить /tmp (временные файлы)?"; then
    echo -e "${BLUE}Очистка /tmp...${NC}"
    show_size "/tmp"
    find /tmp -type f -atime +1 -delete 2>/dev/null
    find /tmp -type d -empty -delete 2>/dev/null
    echo -e "${GREEN}✓ /tmp очищена${NC}"
fi

# 2.2. Временные файлы в /var/tmp
if confirm_action "Очистить /var/tmp (постоянные временные файлы)?"; then
    echo -e "${BLUE}Очистка /var/tmp...${NC}"
    show_size "/var/tmp"
    find /var/tmp -type f -atime +7 -delete 2>/dev/null
    find /var/tmp -type d -empty -delete 2>/dev/null
    echo -e "${GREEN}✓ /var/tmp очищена${NC}"
fi

echo ""
echo -e "${GREEN}=== 3. Очистка системного кэша ===${NC}"

# 3.1. Кэш DNF
if confirm_action "Очистить кэш DNF (пакеты, метаданные)?"; then
    echo -e "${BLUE}Очистка кэша DNF...${NC}"
    show_size "/var/cache/dnf"
    dnf clean all
    echo -e "${GREEN}✓ Кэш DNF очищен${NC}"
fi

# 3.2. Кэш журналов (journald)
if confirm_action "Очистить старые системные журналы (journalctl)?"; then
    echo -e "${BLUE}Очистка журналов...${NC}"
    journalctl --vacuum-time=7d
    echo -e "${GREEN}✓ Журналы старше 7 дней удалены${NC}"
fi

echo ""
echo -e "${GREEN}=== 4. Очистка логов ===${NC}"

# 4.1. Старые логи
if confirm_action "Очистить старые логи (/var/log/*.log.*)?"; then
    echo -e "${BLUE}Очистка старых логов...${NC}"
    find /var/log -name "*.log.*" -type f -mtime +30 -delete 2>/dev/null
    find /var/log -name "*.gz" -type f -mtime +30 -delete 2>/dev/null
    echo -e "${GREEN}✓ Старые логи удалены${NC}"
fi

# 4.2. Очистка пустых логов
if confirm_action "Очистить пустые лог-файлы?"; then
    echo -e "${BLUE}Очистка пустых логов...${NC}"
    find /var/log -name "*.log" -type f -empty -delete 2>/dev/null
    echo -e "${GREEN}✓ Пустые логи удалены${NC}"
fi

echo ""
echo -e "${GREEN}=== 5. Очистка пользовательских временных файлов ===${NC}"

# 5.1. Кэш браузеров
if confirm_action "Очистить кэш браузеров (Яндекс.Браузер, Chromium)?"; then
    echo -e "${BLUE}Очистка кэша браузеров...${NC}"
    
    # Яндекс.Браузер
    if [ -d "$HOME_DIR/.cache/yandex" ]; then
        show_size "$HOME_DIR/.cache/yandex"
        safe_remove "$HOME_DIR/.cache/yandex/*"
    fi
    
    # Chromium
    if [ -d "$HOME_DIR/.cache/chromium" ]; then
        show_size "$HOME_DIR/.cache/chromium"
        safe_remove "$HOME_DIR/.cache/chromium/*"
    fi
    
    echo -e "${GREEN}✓ Кэш браузеров очищен${NC}"
fi

# 5.2. Кэш мессенджеров
if confirm_action "Очистить кэш мессенджеров (Telegram, Viber)?"; then
    echo -e "${BLUE}Очистка кэша мессенджеров...${NC}"
    
    # Telegram
    if [ -d "$HOME_DIR/.local/share/TelegramDesktop" ]; then
        show_size "$HOME_DIR/.local/share/TelegramDesktop/tdata"
        safe_remove "$HOME_DIR/.local/share/TelegramDesktop/tdata/cache"
        safe_remove "$HOME_DIR/.local/share/TelegramDesktop/tdata/media_cache"
    fi
    
    # Viber
    if [ -d "$HOME_DIR/.ViberPC" ]; then
        show_size "$HOME_DIR/.ViberPC"
        safe_remove "$HOME_DIR/.ViberPC/cache"
    fi
    
    echo -e "${GREEN}✓ Кэш мессенджеров очищен${NC}"
fi

# 5.3. Временные файлы в домашней директории
if confirm_action "Очистить временные файлы в домашней директории (~/.cache, ~/.thumbnails)?"; then
    echo -e "${BLUE}Очистка временных файлов пользователя...${NC}"
    
    # Кэш пользователя
    if [ -d "$HOME_DIR/.cache" ]; then
        show_size "$HOME_DIR/.cache"
        safe_remove "$HOME_DIR/.cache/*"
    fi
    
    # Миниатюры
    if [ -d "$HOME_DIR/.thumbnails" ]; then
        show_size "$HOME_DIR/.thumbnails"
        safe_remove "$HOME_DIR/.thumbnails/*"
    fi
    
    echo -e "${GREEN}✓ Временные файлы пользователя очищены${NC}"
fi

echo ""
echo -e "${GREEN}=== 6. Удаление неиспользуемых пакетов ===${NC}"

# 6.1. Удаление старых ядер
if confirm_action "Удалить старые ядра (оставить последние 2)?"; then
    echo -e "${BLUE}Удаление старых ядер...${NC}"
    
    # Получаем текущее ядро
    current_kernel=$(uname -r)
    
    # Получаем список всех установленных ядер
    installed_kernels=$(rpm -q kernel | sort -V)
    
    # Счетчик удаленных
    removed=0
    
    for kernel in $installed_kernels; do
        kernel_version=$(echo $kernel | sed 's/kernel-//')
        if [[ "$kernel_version" != "$current_kernel" ]]; then
            # Пропускаем последние 2 ядра (не считая текущее)
            if [ $removed -lt 2 ]; then
                removed=$((removed + 1))
                continue
            fi
            echo -e "${YELLOW}Удаление: $kernel${NC}"
            dnf remove -y "$kernel"
        fi
    done
    
    echo -e "${GREEN}✓ Старые ядра удалены${NC}"
fi

# 6.2. Удаление неиспользуемых пакетов
if confirm_action "Удалить неиспользуемые пакеты (dnf autoremove)?"; then
    echo -e "${BLUE}Удаление неиспользуемых пакетов...${NC}"
    dnf autoremove -y
    echo -e "${GREEN}✓ Неиспользуемые пакеты удалены${NC}"
fi

# 6.3. Очистка кэша пакетов
if confirm_action "Очистить кэш пакетов (/var/cache/PackageKit)?"; then
    echo -e "${BLUE}Очистка кэша PackageKit...${NC}"
    show_size "/var/cache/PackageKit"
    safe_remove "/var/cache/PackageKit/*"
    echo -e "${GREEN}✓ Кэш PackageKit очищен${NC}"
fi

echo ""
echo -e "${GREEN}=== 7. Очистка корзины ===${NC}"

# 7.1. Корзина пользователя
if confirm_action "Очистить корзину пользователя?"; then
    echo -e "${BLUE}Очистка корзины...${NC}"
    if [ -d "$HOME_DIR/.local/share/Trash" ]; then
        show_size "$HOME_DIR/.local/share/Trash"
        safe_remove "$HOME_DIR/.local/share/Trash/*"
    fi
    echo -e "${GREEN}✓ Корзина очищена${NC}"
fi

echo ""
echo -e "${GREEN}=== 8. Очистка старых бэкапов ===${NC}"

# 8.1. Старые бэкапы конфигов
if confirm_action "Удалить старые бэкапы конфигов (старше 90 дней)?"; then
    echo -e "${BLUE}Удаление старых бэкапов...${NC}"
    find /etc -name "*.backup*" -type f -mtime +90 -delete 2>/dev/null
    find /etc -name "*.old" -type f -mtime +90 -delete 2>/dev/null
    find /etc -name "*.bak" -type f -mtime +90 -delete 2>/dev/null
    echo -e "${GREEN}✓ Старые бэкапы удалены${NC}"
fi

echo ""
echo -e "${GREEN}=== 9. Результаты очистки ===${NC}"
echo -e "${BLUE}После очистки:${NC}"
df -h /

echo ""
echo -e "${GREEN}=== 10. Дополнительные рекомендации ===${NC}"
echo -e "${YELLOW}Для дальнейшей оптимизации рекомендуется:${NC}"
echo -e "  • Перезагрузить систему для полного применения изменений"
echo -e "  • Проверить свободное место: ${BLUE}df -h${NC}"
echo -e "  • Проверить использование диска: ${BLUE}du -sh /* 2>/dev/null | sort -h${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Очистка завершена!    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Время завершения: $(date)${NC}"

# Запрос на перезагрузку
echo ""
if confirm_action "Перезагрузить систему сейчас?"; then
    echo -e "${BLUE}Перезагрузка через 5 секунд...${NC}"
    sleep 5
    sync
    reboot
else
    echo -e "${GREEN}Перезагрузка отменена.${NC}"
    echo -e "${YELLOW}Рекомендуется перезагрузить систему для полного применения изменений.${NC}"
fi