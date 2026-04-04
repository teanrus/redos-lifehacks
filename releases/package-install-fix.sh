#!/bin/bash
#
# Скрипт решения ошибок установки ПО для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/package-install-fix.sh | sudo bash
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
log_info "Решение ошибок установки ПО в РЕД ОС"
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

# Проверка места на диске
echo -e "${CYAN}Место на диске:${NC}"
df -h / /var 2>/dev/null | tail -n +2 | while read line; do
    FILESYSTEM=$(echo "$line" | awk '{print $1}')
    SIZE=$(echo "$line" | awk '{print $2}')
    USED=$(echo "$line" | awk '{print $3}')
    AVAIL=$(echo "$line" | awk '{print $4}')
    USEPCT=$(echo "$line" | awk '{print $5}')
    MOUNT=$(echo "$line" | awk '{print $6}')
    
    # Проверка критического уровня
    if [[ "$USEPCT" =~ ^([9][0-9]|100)%$ ]]; then
        echo -e "  ${RED}✗${NC} $MOUNT: ${RED}$AVAIL свободно ($USEPCT занято)${NC}"
    elif [[ "$USEPCT" =~ ^[8][0-9]%$ ]]; then
        echo -e "  ${YELLOW}⚠${NC} $MOUNT: ${YELLOW}$AVAIL свободно ($USEPCT занято)${NC}"
    else
        echo -e "  ${GREEN}✓${NC} $MOUNT: ${GREEN}$AVAIL свободно${NC}"
    fi
done
echo ""

# ============================================================================
# Проверка репозиториев
# ============================================================================
log_header
echo -e "${BLUE}Проверка репозиториев:${NC}"
log_header
echo ""

REPO_ISSUES=0

# Список репозиториев
echo -e "${CYAN}Список репозиториев:${NC}"
dnf repolist 2>/dev/null | tail -n +2 | while read line; do
    REPO_ID=$(echo "$line" | awk '{print $1}')
    REPO_NAME=$(echo "$line" | cut -d'/' -f2-)
    echo "  ${GREEN}✓${NC} $REPO_ID"
done
echo ""

# Проверка доступности репозиториев
echo -e "${CYAN}Проверка доступности:${NC}"

# Проверка кэша
if [ -d /var/cache/dnf ] && [ "$(ls -A /var/cache/dnf 2>/dev/null)" ]; then
    echo -e "  ${GREEN}✓${NC} Кэш DNF существует"
else
    echo -e "  ${YELLOW}⚠${NC} Кэш DNF пуст или отсутствует"
fi

# Проверка проблемных репозиториев
PROBLEM_REPOS=()
for repo in $(dnf repolist --all 2>/dev/null | tail -n +2 | awk '{print $1}'); do
    if ! dnf repolist --all 2>/dev/null | grep -q "$repo"; then
        PROBLEM_REPOS+=("$repo")
    fi
done

if [ ${#PROBLEM_REPOS[@]} -gt 0 ]; then
    echo -e "  ${RED}✗${NC} Проблемные репозитории: ${YELLOW}${PROBLEM_REPOS[*]}${NC}"
    REPO_ISSUES=1
else
    echo -e "  ${GREEN}✓${NC} Проблем с репозиториями не обнаружено"
fi
echo ""

# Предложение отключить проблемные репозитории
if [ $REPO_ISSUES -eq 1 ]; then
    if confirm_action "Отключить проблемные репозитории?"; then
        for repo in "${PROBLEM_REPOS[@]}"; do
            log_info "Отключение репозитория $repo..."
            dnf config-manager --set-disabled "$repo" 2>/dev/null || true
            check_success "Репозиторий $repo отключен"
        done
    fi
fi

# ============================================================================
# Проверка места на диске
# ============================================================================
log_header
echo -e "${BLUE}Проверка места на диске:${NC}"
log_header
echo ""

DISK_ISSUES=0

# Проверка /var
VAR_AVAIL=$(df /var 2>/dev/null | tail -1 | awk '{print $4}')
VAR_AVAIL_GB=$(echo "$VAR_AVAIL" | sed 's/[GTMK]//')
VAR_UNIT=$(echo "$VAR_AVAIL" | grep -oP '[GTMK]')

# Конвертация в ГБ для сравнения
case $VAR_UNIT in
    G) VAR_GB=$VAR_AVAIL_GB ;;
    M) VAR_GB=$(echo "scale=2; $VAR_AVAIL_GB / 1024" | bc) ;;
    T) VAR_GB=$(echo "scale=2; $VAR_AVAIL_GB * 1024" | bc) ;;
    K) VAR_GB=$(echo "scale=4; $VAR_AVAIL_GB / 1048576" | bc) ;;
    *) VAR_GB=0 ;;
esac

if (( $(echo "$VAR_GB < 1" | bc -l) )); then
    echo -e "  ${RED}✗${NC} /var: ${RED}Критически мало места (< 1 ГБ)${NC}"
    DISK_ISSUES=1
elif (( $(echo "$VAR_GB < 5" | bc -l) )); then
    echo -e "  ${YELLOW}⚠${NC} /var: ${YELLOW}Мало места (< 5 ГБ)${NC}"
    DISK_ISSUES=1
else
    echo -e "  ${GREEN}✓${NC} /var: ${GREEN}Достаточно места${NC}"
fi
echo ""

# Предложение очистки
if [ $DISK_ISSUES -eq 1 ]; then
    if confirm_action "Очистить кэш DNF и логи?"; then
        log_info "Очистка кэша DNF..."
        dnf clean all
        check_success "Кэш DNF очищен"
        
        log_info "Очистка кэша RPM..."
        rm -rf /var/cache/dnf/*
        check_success "Кэш RPM очищен"
        
        log_info "Очистка старых логов..."
        journalctl --vacuum-time=2d 2>/dev/null || true
        check_success "Логи очищены"
        
        # Удаление старых ядер
        if confirm_action "Удалить старые ядра (кроме текущего)?"; then
            log_info "Поиск старых ядер..."
            OLD_KERNELS=$(dnf repoquery --installonly --latest-limit=-1 -q 2>/dev/null)
            if [ -n "$OLD_KERNELS" ]; then
                dnf remove -y $OLD_KERNELS
                check_success "Старые ядра удалены"
            else
                echo -e "  ${GREEN}✓${NC} Старых ядер не найдено"
            fi
        fi
        
        # Удаление ненужных пакетов
        if confirm_action "Удалить ненужные зависимости (autoremove)?"; then
            log_info "Удаление ненужных пакетов..."
            dnf autoremove -y
            check_success "Ненужные пакеты удалены"
        fi
    fi
fi

# ============================================================================
# Проверка зависимостей
# ============================================================================
log_header
echo -e "${BLUE}Проверка зависимостей:${NC}"
log_header
echo ""

DEPENDENCY_ISSUES=0

# Проверка конфликтов
echo -e "${CYAN}Проверка конфликтов пакетов:${NC}"
if rpm --verify -a 2>/dev/null | grep -q "conflict"; then
    echo -e "  ${RED}✗${NC} Обнаружены конфликты пакетов"
    DEPENDENCY_ISSUES=1
else
    echo -e "  ${GREEN}✓${NC} Конфликтов не найдено"
fi

# Проверка неразрешённых зависимостей
echo ""
echo -e "${CYAN}Проверка неразрешённых зависимостей:${NC}"
if dnf check 2>/dev/null | grep -qi "error\|problem"; then
    echo -e "  ${RED}✗${NC} Обнаружены проблемы с зависимостями"
    DEPENDENCY_ISSUES=1
    dnf check 2>/dev/null | head -10 | while read line; do
        echo "    $line"
    done
else
    echo -e "  ${GREEN}✓${NC} Зависимости в порядке"
fi
echo ""

# Предложение решения проблем с зависимостями
if [ $DEPENDENCY_ISSUES -eq 1 ]; then
    if confirm_action "Попытаться автоматически исправить зависимости?"; then
        log_info "Исправление зависимостей..."
        dnf distro-sync -y
        check_success "Зависимости исправлены"
    fi
fi

# ============================================================================
# Очистка кэша и базы RPM
# ============================================================================
log_header
echo -e "${BLUE}Очистка кэша и базы RPM:${NC}"
log_header
echo ""

if confirm_action "Выполнить полную очистку и пересоздание базы RPM?"; then
    log_info "Очистка кэша DNF..."
    dnf clean all
    check_success "Кэш DNF очищен"
    
    log_info "Очистка кэша RPM..."
    rm -rf /var/cache/dnf/*
    check_success "Кэш RPM очищен"
    
    log_info "Удаление lock-файлов..."
    rm -f /var/lib/dnf/lock
    rm -f /var/lib/rpm/__db*
    check_success "Lock-файлы удалены"
    
    log_info "Пересоздание базы RPM..."
    rpm --rebuilddb
    check_success "База RPM пересоздана"
    
    log_info "Обновление кэша репозиториев..."
    dnf makecache
    check_success "Кэш репозиториев обновлён"
fi
echo ""

# ============================================================================
# Проверка транзакций DNF
# ============================================================================
log_header
echo -e "${BLUE}Проверка транзакций DNF:${NC}"
log_header
echo ""

# История транзакций
echo -e "${CYAN}Последние транзакции:${NC}"
dnf history list 2>/dev/null | head -10 | while read line; do
    echo "  $line"
done
echo ""

# Проверка незавершённых транзакций
echo -e "${CYAN}Проверка незавершённых транзакций:${NC}"
if dnf history list incomplete 2>/dev/null | tail -n +2 | grep -q .; then
    INCOMPLETE=$(dnf history list incomplete 2>/dev/null | tail -n +2 | head -1 | awk '{print $1}')
    if [ -n "$INCOMPLETE" ]; then
        echo -e "  ${YELLOW}⚠${NC} Найдена незавершённая транзакция #$INCOMPLETE"
        if confirm_action "Откатить незавершённую транзакцию?"; then
            log_info "Откат транзакции #$INCOMPLETE..."
            dnf history undo $INCOMPLETE -y
            check_success "Транзакция откатена"
        fi
    fi
else
    echo -e "  ${GREEN}✓${NC} Незавершённых транзакций нет"
fi
echo ""

# ============================================================================
# Проверка установленных пакетов
# ============================================================================
log_header
echo -e "${BLUE}Проверка установленных пакетов:${NC}"
log_header
echo ""

# Количество установленных пакетов
INSTALLED_COUNT=$(rpm -qa | wc -l)
echo -e "  Установлено пакетов: ${CYAN}$INSTALLED_COUNT${NC}"

# Проверка битых пакетов
echo ""
echo -e "${CYAN}Проверка целостности пакетов:${NC}"
BROKEN_PACKAGES=$(rpm --verify -a 2>/dev/null | grep -v "^c" | head -10)
if [ -n "$BROKEN_PACKAGES" ]; then
    echo -e "  ${YELLOW}⚠${NC} Обнаружены проблемы с файлами пакетов:"
    echo "$BROKEN_PACKAGES" | head -5 | while read line; do
        echo "    $line"
    done
    if confirm_action "Переустановить повреждённые пакеты?"; then
        log_info "Переустановка повреждённых пакетов..."
        rpm --verify -a 2>/dev/null | grep -v "^c" | awk '{print $NF}' | sort -u | head -5 | while read pkg; do
            dnf reinstall -y "$pkg" 2>/dev/null || true
        done
        check_success "Повреждённые пакеты переустановлены"
    fi
else
    echo -e "  ${GREEN}✓${NC} Проблем с целостностью пакетов не обнаружено"
fi
echo ""

# ============================================================================
# Проверка GPG ключей
# ============================================================================
log_header
echo -e "${BLUE}Проверка GPG ключей:${NC}"
log_header
echo ""

echo -e "${CYAN}Установленные GPG ключи:${NC}"
rpm -qa gpg-pubkey* 2>/dev/null | while read key; do
    KEY_INFO=$(rpm -qi "$key" 2>/dev/null | grep -E "^Summary|^Description" | head -1)
    echo "  ${GREEN}✓${NC} $key"
done
echo ""

# Импорт стандартных ключей РЕД ОС
if confirm_action "Импортировать стандартные ключи РЕД ОС?"; then
    log_info "Импорт ключей..."
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redos 2>/dev/null || true
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redos-release 2>/dev/null || true
    check_success "Ключи импортированы"
fi
echo ""

# ============================================================================
# Тестовая установка пакета
# ============================================================================
log_header
echo -e "${BLUE}Тестовая проверка установки:${NC}"
log_header
echo ""

if confirm_action "Выполнить тестовую установку пакета (htop)?"; then
    log_info "Тестовая установка htop..."
    dnf install -y htop
    check_success "htop установлен"
    
    # Проверка установки
    if rpm -q htop &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} htop: $(rpm -q htop)"
    fi
fi
echo ""

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Решение ошибок установки завершено!"
log_header
echo ""

echo -e "${GREEN}Результаты:${NC}"
echo "  Репозитории: $([ $REPO_ISSUES -eq 0 ] && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Исправлено${NC}")"
echo "  Место на диске: $([ $DISK_ISSUES -eq 0 ] && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Исправлено${NC}")"
echo "  Зависимости: $([ $DEPENDENCY_ISSUES -eq 0 ] && echo -e "${GREEN}OK${NC}" || echo -e "${YELLOW}Исправлено${NC}")"
echo ""

echo -e "${BLUE}Полезные команды:${NC}"
echo "  dnf clean all              # очистка кэша"
echo "  dnf autoremove             # удаление ненужного"
echo "  dnf history undo last      # откат транзакции"
echo "  rpm --rebuilddb            # пересоздание базы RPM"
echo "  dnf check                  # проверка зависимостей"
echo ""

echo -e "${YELLOW}Рекомендации:${NC}"
echo "  • Регулярно очищайте кэш: dnf clean all"
echo "  • Удаляйте ненужные пакеты: dnf autoremove"
echo "  • Следите за местом в /var"
echo "  • Перед серьёзными изменениями делайте резервную копию"
echo ""

log_info "Готово!"
