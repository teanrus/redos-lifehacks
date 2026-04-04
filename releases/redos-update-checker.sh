#!/bin/bash
#===============================================================================
# redos-update-checker.sh
# Универсальный скрипт проверки обновлений для РЕД ОС
# Версия: 1.0
#===============================================================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Логирование
LOG_FILE="/var/log/redos-update-checker.log"
REPORT_FILE="$HOME/redos-updates-report-$(date +%Y%m%d-%H%M%S).txt"

#-------------------------------------------------------------------------------
# Функции
#-------------------------------------------------------------------------------

print_header() {
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}  Проверка обновлений РЕД ОС${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${BLUE}Дата: $(date '+%d.%m.%Y %H:%M:%S')${NC}"
    echo -e "${BLUE}Пользователь: $(whoami)${NC}"
    echo -e "${BLUE}Хост: $(hostname)${NC}"
    echo ""
}

print_section() {
    echo -e "\n${YELLOW}--- $1 ---${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}⚠ Требуется запуск от root для некоторых операций${NC}"
        SUDO_CMD="sudo"
    else
        SUDO_CMD=""
    fi
}

check_os_version() {
    print_section "Информация о системе"
    if [ -f /etc/redos-release ]; then
        cat /etc/redos-release
    else
        echo "Версия РЕД ОС не определена"
    fi
    echo "Ядро: $(uname -r)"
    echo "Архитектура: $(uname -m)"
}

check_repos() {
    print_section "Активные репозитории"
    $SUDO_CMD dnf repolist enabled 2>/dev/null | head -20
}

refresh_cache() {
    print_section "Обновление кэша репозиториев"
    $SUDO_CMD dnf makecache 2>&1
}

check_updates() {
    print_section "Доступные обновления"
    $SUDO_CMD dnf check-update 2>&1 | head -50
    local status=$?
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓ Система актуальна${NC}"
        return 0
    elif [ $status -eq 100 ]; then
        echo -e "${YELLOW}⚠ Доступны обновления${NC}"
        return 1
    else
        echo -e "${RED}✗ Ошибка проверки обновлений${NC}"
        return 2
    fi
}

check_security_updates() {
    print_section "Обновления безопасности"
    $SUDO_CMD dnf updateinfo list security 2>&1 | head -20
}

check_kernel_updates() {
    print_section "Обновления ядра"
    $SUDO_CMD dnf list updates kernel* 2>&1 | grep -v "Available Packages" | head -10
}

count_updates() {
    print_section "Статистика"
    local total=$($SUDO_CMD dnf check-update 2>/dev/null | grep -c "^[a-zA-Z]")
    local security=$($SUDO_CMD dnf updateinfo list security 2>/dev/null | grep -c "security")
    echo -e "Всего обновлений: ${CYAN}$total${NC}"
    echo -e "Обновлений безопасности: ${RED}$security${NC}"
}

apply_updates() {
    print_section "Применение обновлений"
    read -p "Применить все обновления? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $SUDO_CMD dnf upgrade -y
    else
        echo "Пропущено"
    fi
}

export_report() {
    print_section "Экспорт отчёта"
    {
        echo "Отчёт о проверке обновлений РЕД ОС"
        echo "Дата: $(date)"
        echo "Хост: $(hostname)"
        echo ""
        echo "=== Доступные обновления ==="
        $SUDO_CMD dnf check-update 2>&1
        echo ""
        echo "=== Обновления безопасности ==="
        $SUDO_CMD dnf updateinfo list security 2>&1
    } > "$REPORT_FILE"
    echo -e "${GREEN}✓ Отчёт сохранён: $REPORT_FILE${NC}"
}

show_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  -h, --help      Показать эту справку"
    echo "  -i, --info      Только информация о системе"
    echo "  -c, --check     Только проверка обновлений"
    echo "  -s, --security  Только обновления безопасности"
    echo "  -k, --kernel    Только обновления ядра"
    echo "  -u, --update    Проверить и применить обновления"
    echo "  -r, --report    Экспорт отчёта в файл"
    echo "  -f, --full      Полная проверка (по умолчанию)"
    echo ""
    echo "Примеры:"
    echo "  $0 --check      Быстрая проверка обновлений"
    echo "  $0 --security   Проверка обновлений безопасности"
    echo "  $0 --update     Обновление системы"
}

#-------------------------------------------------------------------------------
# Основная логика
#-------------------------------------------------------------------------------

main() {
    print_header
    check_root

    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--info)
            check_os_version
            check_repos
            ;;
        -c|--check)
            check_os_version
            check_updates
            count_updates
            ;;
        -s|--security)
            check_security_updates
            ;;
        -k|--kernel)
            check_kernel_updates
            ;;
        -u|--update)
            check_os_version
            check_updates
            apply_updates
            ;;
        -r|--report)
            check_os_version
            check_updates
            check_security_updates
            export_report
            ;;
        -f|--full|*)
            check_os_version
            check_repos
            refresh_cache
            check_updates
            check_security_updates
            check_kernel_updates
            count_updates
            export_report
            ;;
    esac

    print_section "Завершено"
    echo -e "${CYAN}Время выполнения: $(date '+%H:%M:%S')${NC}"
}

main "$@"
