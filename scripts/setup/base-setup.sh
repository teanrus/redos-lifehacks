#!/bin/bash
# Базовая настройка системы РЕД ОС 7.3
# Версия: 1.2
# Описание: Настройка SELinux, DNF, добавление репозиториев MAX и R7, установка ПО, обновление системы и ядра

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

# Функция для проверки успешности выполнения
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 успешно выполнено${NC}"
    else
        echo -e "${RED}✗ Ошибка при выполнении: $1${NC}"
        exit 1
    fi
}

# Функция для резервного копирования файлов
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${BLUE}✓ Создана резервная копия: $file.backup.$(date +%Y%m%d_%H%M%S)${NC}"
    fi
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Этот скрипт должен запускаться с правами root${NC}"
   echo -e "${YELLOW}Запустите: sudo $0${NC}"
   exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Базовая настройка РЕД ОС 7.3    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Дата запуска: $(date)${NC}"
echo ""

# === 1. ИНФОРМАЦИЯ О СИСТЕМЕ ===
echo -e "${GREEN}=== 1. Информация о системе ===${NC}"
if [ -f /etc/redos-release ]; then
    echo -e "${BLUE}Версия ОС: $(cat /etc/redos-release)${NC}"
fi
echo -e "${BLUE}Ядро: $(uname -r)${NC}"
echo -e "${BLUE}Архитектура: $(uname -m)${NC}"
echo ""

# === 2. НАСТРОЙКА SELINUX ===
echo -e "${GREEN}=== 2. Настройка SELinux ===${NC}"

if confirm_action "Отключить SELinux? (рекомендуется для совместимости с некоторым ПО)"; then
    backup_file "/etc/selinux/config"
    
    if grep -q "^SELINUX=enforcing" /etc/selinux/config; then
        sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
        echo -e "${GREEN}✓ SELinux отключен (требуется перезагрузка для применения)${NC}"
    elif grep -q "^SELINUX=permissive" /etc/selinux/config; then
        sed -i 's/^SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
        echo -e "${GREEN}✓ SELinux переведен в режим disabled${NC}"
    else
        echo -e "${YELLOW}SELinux уже отключен или настроен иначе${NC}"
    fi
    
    setenforce 0 2>/dev/null && echo -e "${GREEN}✓ SELinux временно отключен на текущую сессию${NC}"
else
    echo -e "${YELLOW}SELinux остается в текущем состоянии${NC}"
fi

echo ""

# === 3. НАСТРОЙКА DNF ===
echo -e "${GREEN}=== 3. Настройка DNF ===${NC}"

if confirm_action "Настроить DNF (параллельная загрузка, кэширование)?"; then
    backup_file "/etc/dnf/dnf.conf"
    
    if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
        echo -e "${GREEN}✓ Установлено max_parallel_downloads=10${NC}"
    fi
    
    if ! grep -q "fastestmirror" /etc/dnf/dnf.conf; then
        echo "fastestmirror=True" >> /etc/dnf/dnf.conf
        echo -e "${GREEN}✓ Включен fastestmirror${NC}"
    fi
    
    if ! grep -q "deltarpm" /etc/dnf/dnf.conf; then
        echo "deltarpm=True" >> /etc/dnf/dnf.conf
        echo -e "${GREEN}✓ Включен deltarpm${NC}"
    fi
    
    if ! grep -q "keepcache" /etc/dnf/dnf.conf; then
        echo "keepcache=False" >> /etc/dnf/dnf.conf
        echo -e "${GREEN}✓ Отключено кэширование пакетов${NC}"
    fi
    
    echo -e "${GREEN}✓ Настройки DNF применены${NC}"
else
    echo -e "${YELLOW}Настройка DNF пропущена${NC}"
fi

echo ""

# === 4. ДОБАВЛЕНИЕ РЕПОЗИТОРИЕВ ===
echo -e "${GREEN}=== 4. Добавление репозиториев ===${NC}"

# 4.1. Репозиторий R7 Office
if confirm_action "Добавить репозиторий R7 Office?"; then
    if ! rpm -q r7-release &>/dev/null; then
        dnf install -y r7-release
        check_success "Установка репозитория R7 Office"
    else
        echo -e "${GREEN}✓ Репозиторий R7 Office уже установлен${NC}"
    fi
fi

# 4.2. Репозиторий MAX
if confirm_action "Добавить репозиторий MAX Desktop?"; then
    if [ ! -f /etc/yum.repos.d/max.repo ]; then
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
        check_success "Установка репозитория MAX"
    else
        echo -e "${GREEN}✓ Репозиторий MAX уже установлен${NC}"
    fi
fi

# 4.3. Репозиторий Яндекс.Браузера
if confirm_action "Добавить репозиторий Яндекс.Браузера?"; then
    if ! rpm -q yandex-browser-release &>/dev/null; then
        dnf install -y yandex-browser-release
        check_success "Установка репозитория Яндекс.Браузера"
    else
        echo -e "${GREEN}✓ Репозиторий Яндекс.Браузера уже установлен${NC}"
    fi
fi

# Обновление кэша после добавления репозиториев
if [ -f /etc/yum.repos.d/max.repo ] || rpm -q r7-release &>/dev/null || rpm -q yandex-browser-release &>/dev/null; then
    echo -e "${BLUE}Обновление кэша репозиториев...${NC}"
    dnf makecache
    check_success "Обновление кэша репозиториев"
fi

echo ""

# === 5. УСТАНОВКА ПРОГРАММ ===
echo -e "${GREEN}=== 5. Установка программ ===${NC}"

# 5.1. Установка R7 Office
if confirm_action "Установить R7 Office?"; then
    dnf install -y r7-office
    check_success "Установка R7 Office"
fi

# 5.2. Установка MAX Desktop
if confirm_action "Установить MAX Desktop?"; then
    dnf install -y max
    check_success "Установка MAX Desktop"
fi

# 5.3. Установка Яндекс.Браузера
if confirm_action "Установить Яндекс.Браузер?"; then
    dnf install -y yandex-browser-stable
    check_success "Установка Яндекс.Браузера"
fi

# 5.4. Установка дополнительных пакетов
if confirm_action "Установить дополнительные пакеты (pavucontrol, sshfs, pinta)?"; then
    dnf install -y pavucontrol sshfs pinta perl-Getopt-Long perl-File-Copy
    check_success "Установка дополнительных пакетов"
fi

echo ""

# === 6. ОБНОВЛЕНИЕ СИСТЕМЫ ===
echo -e "${GREEN}=== 6. Обновление системы ===${NC}"

if confirm_action "Обновить систему (dnf update)?"; then
    echo -e "${BLUE}Установка обновлений...${NC}"
    dnf update -y
    check_success "Обновление системы"
else
    echo -e "${YELLOW}Обновление системы пропущено${NC}"
fi

echo ""

# === 7. УСТАНОВКА ЯДРА ===
echo -e "${GREEN}=== 7. Установка и обновление ядра ===${NC}"

if confirm_action "Установить/обновить ядро redos-kernels6?"; then
    echo -e "${BLUE}Установка ядра...${NC}"
    dnf install -y redos-kernels6-release
    check_success "Установка ядра redos-kernels6"
    
    echo -e "${BLUE}Финальное обновление после установки ядра...${NC}"
    dnf update -y
    check_success "Финальное обновление"
    
    echo -e "${BLUE}Обновление конфигурации GRUB...${NC}"
    grub2-mkconfig -o /boot/grub2/grub.cfg
    check_success "Обновление GRUB"
else
    echo -e "${YELLOW}Установка ядра пропущена${NC}"
fi

echo ""

# === 8. УСТАНОВКА ПОЛЕЗНЫХ УТИЛИТ ===
echo -e "${GREEN}=== 8. Установка полезных утилит ===${NC}"

UTILS=()
if confirm_action "Установить сетевые утилиты (nmap, traceroute, net-tools, bind-utils)?"; then
    UTILS+=("nmap" "traceroute" "net-tools" "bind-utils")
fi

if confirm_action "Установить системные утилиты (htop, tree, lsof)?"; then
    UTILS+=("htop" "tree" "lsof")
fi

if confirm_action "Установить утилиты для работы с архивами (unzip, p7zip, p7zip-plugins)?"; then
    UTILS+=("unzip" "p7zip" "p7zip-plugins")
fi

if confirm_action "Установить утилиты для работы с дисками (ntfs-3g, exfat-utils)?"; then
    UTILS+=("ntfs-3g" "exfat-utils" "fuse-exfat")
fi

if [ ${#UTILS[@]} -gt 0 ]; then
    echo -e "${BLUE}Установка утилит: ${UTILS[*]}${NC}"
    dnf install -y "${UTILS[@]}"
    check_success "Установка дополнительных утилит"
else
    echo -e "${YELLOW}Установка утилит пропущена${NC}"
fi

echo ""

# === 9. НАСТРОЙКА ВРЕМЕНИ ===
echo -e "${GREEN}=== 9. Настройка времени ===${NC}"

if confirm_action "Настроить часовой пояс (Asia/Yekaterinburg, UTC+5)?"; then
    timedatectl set-timezone Asia/Yekaterinburg
    check_success "Настройка часового пояса"
    echo -e "${BLUE}Текущее время: $(date)${NC}"
fi

if confirm_action "Включить синхронизацию времени (chronyd)?"; then
    systemctl enable --now chronyd
    check_success "Включение синхронизации времени"
    chronyc sources -v
fi

echo ""

# === 10. НАСТРОЙКА SSH ===
echo -e "${GREEN}=== 10. Настройка SSH ===${NC}"

if confirm_action "Настроить SSH (отключить root-логин, разрешить ключи)?"; then
    backup_file "/etc/ssh/sshd_config"
    
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    systemctl restart sshd
    check_success "Настройка SSH"
fi

echo ""

# === 11. НАСТРОЙКА FIREWALL ===
echo -e "${GREEN}=== 11. Настройка Firewall ===${NC}"

if confirm_action "Настроить firewall (открыть SSH, закрыть остальное)?"; then
    systemctl enable --now firewalld
    
    firewall-cmd --permanent --zone=public --remove-service=ssh
    firewall-cmd --permanent --zone=public --add-service=ssh
    firewall-cmd --permanent --zone=public --set-target=DROP
    
    firewall-cmd --reload
    
    echo -e "${GREEN}✓ Firewall настроен${NC}"
    echo -e "${BLUE}Открытые порты:${NC}"
    firewall-cmd --list-services
fi

echo ""

# === 12. НАСТРОЙКА HOSTNAME ===
echo -e "${GREEN}=== 12. Настройка hostname ===${NC}"

if confirm_action "Установить имя компьютера?"; then
    echo -e "${YELLOW}Введите имя компьютера (например: workstation-01):${NC}"
    read -r new_hostname
    if [ -n "$new_hostname" ]; then
        hostnamectl set-hostname "$new_hostname"
        echo -e "${GREEN}✓ Имя компьютера установлено: $new_hostname${NC}"
    fi
fi

echo ""

# === 13. ОПТИМИЗАЦИЯ ===
echo -e "${GREEN}=== 13. Оптимизация системы ===${NC}"

if confirm_action "Настроить swappiness (использование swap, рекомендуется 10)?"; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    sysctl -p
    echo -e "${GREEN}✓ Swappiness установлен на 10${NC}"
fi

if confirm_action "Настроить I/O scheduler для SSD (если используется SSD)?"; then
    for disk in /sys/block/sd*/queue/scheduler; do
        echo "mq-deadline" > "$disk" 2>/dev/null
    done
    echo -e "${GREEN}✓ I/O scheduler настроен на mq-deadline${NC}"
fi

if confirm_action "Включить TRIM для SSD (fstrim.timer)?"; then
    systemctl enable --now fstrim.timer
    check_success "Включение TRIM"
fi

echo ""

# === 14. ИТОГИ ===
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Базовая настройка завершена!    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Время завершения: $(date)${NC}"
echo ""

echo -e "${GREEN}Статус системы:${NC}"
echo -e "  • SELinux: $(getenforce 2>/dev/null || echo 'disabled')"
echo -e "  • Firewall: $(systemctl is-active firewalld 2>/dev/null || echo 'inactive')"
echo -e "  • Синхронизация времени: $(systemctl is-active chronyd 2>/dev/null || echo 'inactive')"
echo -e "  • Hostname: $(hostname)"
echo -e "  • Часовой пояс: $(timedatectl | grep "Time zone" | awk '{print $3}')"

echo ""
echo -e "${GREEN}Установленные репозитории:${NC}"
dnf repolist 2>/dev/null | tail -n +2

echo ""
echo -e "${GREEN}Установленные программы:${NC}"
rpm -q r7-office 2>/dev/null && echo "  ✓ R7 Office"
rpm -q max 2>/dev/null && echo "  ✓ MAX Desktop"
rpm -q yandex-browser-stable 2>/dev/null && echo "  ✓ Яндекс.Браузер"
rpm -q kernel 2>/dev/null | tail -2 && echo "  ✓ Ядро"

echo ""
echo -e "${GREEN}Рекомендации:${NC}"
echo -e "  ${YELLOW}• Если SELinux был отключен, перезагрузите систему для применения изменений${NC}"
echo -e "  ${YELLOW}• Проверьте настройки firewall: firewall-cmd --list-all${NC}"
echo -e "  ${YELLOW}• Проверьте обновления системы: dnf check-update${NC}"
echo -e "  ${YELLOW}• После установки нового ядра убедитесь, что загрузка происходит с нужным ядром${NC}"

echo ""
if confirm_action "Перезагрузить систему сейчас?"; then
    echo -e "${BLUE}Перезагрузка через 5 секунд...${NC}"
    sleep 5
    sync
    reboot
else
    echo -e "${GREEN}Перезагрузка отменена.${NC}"
    echo -e "${YELLOW}Для применения всех изменений рекомендуется перезагрузить систему.${NC}"
fi