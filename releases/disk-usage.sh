#!/bin/bash
#
# Скрипт анализа использования дискового пространства для РЕД ОС
# Версия: 1.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-usage.sh | sudo bash
# GitHub: https://github.com/teanrus/redos-lifehacks
#

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

# Логирование
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${BLUE}========================================${NC}"; }
log_section() { echo -e "${CYAN}----------------------------------------${NC}"; }

# ============================================================================
# Проверка прав root
# ============================================================================
if [[ $EUID -ne 0 ]]; then
    log_error "Скрипт должен выполняться от имени root"
    exit 1
fi

# Проверка ОС (опционально - предупреждение если не РЕД ОС)
if [[ -f /etc/os-release ]]; then
    OS_ID=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    if [[ "$OS_ID" != "redos" ]]; then
        log_warn "Скрипт разработан для РЕД ОС, обнаружена: $OS_ID"
        log_warn "Продолжение работы возможно, но не гарантируется"
    fi
fi

log_header
log_info "Анализ использования дискового пространства в РЕД ОС"
log_header
echo ""

# ============================================================================
# Меню выбора действий
# ============================================================================
echo -e "${BLUE}Выберите действия для выполнения:${NC}"
echo ""

# Массивы для хранения пунктов меню и флагов
declare -a MENU_ITEMS
declare -A MENU_ENABLED

MENU_ITEMS=(
    "Быстрая диагностика (df)"
    "Поиск больших файлов (>1ГБ)"
    "Топ-10 самых больших файлов"
    "Анализ занятия каталогов (du)"
    "Очистка кэша пакетного менеджера (DNF)"
    "Очистка системных журналов"
    "Поиск дубликатов файлов"
    "Проверка удалённых, но занятых файлов"
    "Полный отчёт по дисковому пространству"
)

# По умолчанию все пункты включены
for i in "${!MENU_ITEMS[@]}"; do
    MENU_ENABLED[$i]=1
done

# Вывод меню
for i in "${!MENU_ITEMS[@]}"; do
    if [[ ${MENU_ENABLED[$i]} -eq 1 ]]; then
        echo -e "  [$((i + 1))] ✓ ${MENU_ITEMS[$i]}"
    else
        echo -e "  [$((i + 1))] ✗ ${MENU_ITEMS[$i]}"
    fi
done
echo "  [0] → Перейти к выполнению"
echo ""

# Обработка выбора пунктов меню
while true; do
    CHOICE=$(read_from_terminal "${YELLOW}Введите номер пункта для переключения (0 для продолжения):${NC}")

    if [[ "$CHOICE" == "0" ]]; then
        break
    fi

    if [[ "$CHOICE" -ge 1 && "$CHOICE" -le ${#MENU_ITEMS[@]} ]]; then
        IDX=$((CHOICE - 1))
        if [[ ${MENU_ENABLED[$IDX]} -eq 1 ]]; then
            MENU_ENABLED[$IDX]=0
            echo -e "  [$CHOICE] ✗ ${MENU_ITEMS[$IDX]}"
        else
            MENU_ENABLED[$IDX]=1
            echo -e "  [$CHOICE] ✓ ${MENU_ITEMS[$IDX]}"
        fi
    else
        echo -e "${RED}Неверный номер, попробуйте снова${NC}"
    fi
done
echo ""

# ============================================================================
# Выполнение выбранных действий
# ============================================================================

# Переменные для хранения результатов
declare -A RESULTS

# ============================================================================
# 1. Быстрая диагностика (df)
# ============================================================================
if [[ ${MENU_ENABLED[0]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}1. Быстрая диагностика (df)${NC}"
    log_header

    log_info "Общая информация о дисках:"
    echo ""
    df -h
    echo ""

    log_info "Типы файловых систем:"
    echo ""
    df -hT
    echo ""

    log_info "Использование inode:"
    echo ""
    df -i
    echo ""

    log_info "Сводка по корневому разделу:"
    echo ""
    df -h /
    echo ""

    RESULTS[1]="✓ Выполнено"
fi

# ============================================================================
# 2. Поиск больших файлов (>1ГБ)
# ============================================================================
if [[ ${MENU_ENABLED[1]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}2. Поиск больших файлов (>1ГБ)${NC}"
    log_header

    log_info "Поиск файлов размером более 1 ГБ..."
    echo ""
    
    FOUND_FILES=$(sudo find / -type f -size +1G -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}')
    
    if [[ -n "$FOUND_FILES" ]]; then
        echo "$FOUND_FILES"
    else
        echo -e "${GREEN}Файлы размером более 1 ГБ не найдены${NC}"
    fi
    echo ""

    RESULTS[2]="✓ Выполнено"
fi

# ============================================================================
# 3. Топ-10 самых больших файлов
# ============================================================================
if [[ ${MENU_ENABLED[2]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}3. Топ-10 самых больших файлов${NC}"
    log_header

    log_info "Сканирование системы (может занять несколько минут)..."
    echo ""
    
    sudo find / -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -10
    
    echo ""

    RESULTS[3]="✓ Выполнено"
fi

# ============================================================================
# 4. Анализ занятия каталогов (du)
# ============================================================================
if [[ ${MENU_ENABLED[3]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}4. Анализ занятия каталогов (du)${NC}"
    log_header

    log_info "Размер каталогов в корне:"
    echo ""
    du -sh /* 2>/dev/null | sort -rh
    echo ""

    log_info "Детализация домашнего каталога (/home):"
    echo ""
    du -h --max-depth=2 /home 2>/dev/null | sort -rh
    echo ""

    log_info "Детализация каталога /var:"
    echo ""
    du -h --max-depth=2 /var 2>/dev/null | sort -rh
    echo ""

    RESULTS[4]="✓ Выполнено"
fi

# ============================================================================
# 5. Очистка кэша пакетного менеджера (DNF)
# ============================================================================
if [[ ${MENU_ENABLED[4]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}5. Очистка кэша пакетного менеджера (DNF)${NC}"
    log_header

    # Проверка размера кэша
    log_info "Текущий размер кэша пакетов:"
    if [[ -d /var/cache/dnf ]]; then
        du -sh /var/cache/dnf 2>/dev/null || echo "Недоступно"
    fi
    echo ""

    if confirm_action "Очистить кэш пакетного менеджера?"; then
        # DNF (для РЕД ОС)
        if command -v dnf &> /dev/null; then
            log_info "Очистка кэша DNF..."
            dnf clean all 2>/dev/null || true
            dnf autoremove -y 2>/dev/null || true
            echo -e "${GREEN}Кэш DNF очищен${NC}"
        else
            log_warn "DNF не найден"
        fi

        RESULTS[5]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[5]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 6. Очистка системных журналов
# ============================================================================
if [[ ${MENU_ENABLED[5]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}6. Очистка системных журналов${NC}"
    log_header

    # Проверка текущего размера журналов
    log_info "Текущий размер журналов:"
    journalctl --disk-usage 2>/dev/null || echo "journalctl недоступен"
    echo ""

    if confirm_action "Удалить журналы старше 7 дней?"; then
        journalctl --vacuum-time=7d 2>/dev/null || true
        echo -e "${GREEN}Журналы старше 7 дней удалены${NC}"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
    fi

    echo ""

    if confirm_action "Ограничить размер журналов до 100МБ?"; then
        journalctl --vacuum-size=100M 2>/dev/null || true
        echo -e "${GREEN}Размер журналов ограничен до 100МБ${NC}"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
    fi

    echo ""

    # Проверка после очистки
    log_info "Размер журналов после очистки:"
    journalctl --disk-usage 2>/dev/null || echo "journalctl недоступен"
    echo ""

    RESULTS[6]="✓ Выполнено"
fi

# ============================================================================
# 7. Поиск дубликатов файлов
# ============================================================================
if [[ ${MENU_ENABLED[6]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}7. Поиск дубликатов файлов${NC}"
    log_header

    # Проверка наличия утилит
    if ! command -v fdupes &> /dev/null && ! command -v rdfind &> /dev/null; then
        log_warn "Утилиты fdupes и rdfind не установлены"
        log_info "Для установки выполните:"
        echo "  sudo dnf install fdupes rdfind"
        echo ""

        if confirm_action "Установить fdupes и rdfind?"; then
            if command -v dnf &> /dev/null; then
                dnf install -y fdupes rdfind 2>/dev/null || true
            fi
            echo -e "${GREEN}Утилиты установлены${NC}"
        else
            echo -e "${YELLOW}→ Пропущено${NC}"
            RESULTS[7]="✗ Пропущено"
            echo ""
            continue
        fi
    fi

    # Поиск дубликатов в /home
    log_info "Поиск дубликатов в /home..."
    echo ""

    if command -v fdupes &> /dev/null; then
        fdupes -r /home 2>/dev/null | head -50 || echo "Дубликаты не найдены или ошибка сканирования"
    elif command -v rdfind &> /dev/null; then
        rdfind -dryrun true /home 2>/dev/null | head -50 || echo "Дубликаты не найдены или ошибка сканирования"
    fi

    echo ""

    if confirm_action "Выполнить интерактивное удаление дубликатов?"; then
        TARGET_DIR=$(read_from_terminal "${YELLOW}Укажите каталог для очистки (по умолчанию /home):${NC}")
        if [[ -z "$TARGET_DIR" ]]; then
            TARGET_DIR="/home"
        fi

        if command -v fdupes &> /dev/null; then
            fdupes -r -d "$TARGET_DIR" 2>/dev/null || echo "Ошибка выполнения"
        elif command -v rdfind &> /dev/null; then
            rdfind -makesymlinks true "$TARGET_DIR" 2>/dev/null || echo "Ошибка выполнения"
        fi

        RESULTS[7]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено (только сканирование)${NC}"
        RESULTS[7]="~ Сканирование выполнено"
    fi
    echo ""
fi

# ============================================================================
# 8. Проверка удалённых, но занятых файлов
# ============================================================================
if [[ ${MENU_ENABLED[7]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}8. Проверка удалённых, но занятых файлов${NC}"
    log_header

    log_info "Файлы, удалённые, но всё ещё занимающие место:"
    echo ""

    DELETED_FILES=$(sudo lsof +L1 2>/dev/null)

    if [[ -n "$DELETED_FILES" ]]; then
        echo "$DELETED_FILES"
        echo ""

        if confirm_action "Перезапустить сервисы, удерживающие удалённые файлы?"; then
            # Поиск процессов, удерживающих файлы логов
            log_info "Поиск процессов, удерживающих файлы логов..."
            
            # Перезапуск сервисов
            for service in rsyslog systemd-journald; do
                if systemctl is-active --quiet "$service" 2>/dev/null; then
                    systemctl restart "$service" 2>/dev/null || true
                    echo -e "${GREEN}Сервис $service перезапущен${NC}"
                fi
            done

            # Отправка SIGHUP процессам
            if command -v pidof &> /dev/null; then
                kill -HUP $(pidof rsyslog) 2>/dev/null || true
                kill -HUP $(pidof systemd-journald) 2>/dev/null || true
            fi

            echo -e "${GREEN}Сигналы SIGHUP отправлены${NC}"
        fi

        RESULTS[8]="✓ Выполнено"
    else
        echo -e "${GREEN}Удалённые, но занятые файлы не найдены${NC}"
        RESULTS[8]="~ Файлы не найдены"
    fi
    echo ""
fi

# ============================================================================
# 9. Полный отчёт по дисковому пространству
# ============================================================================
if [[ ${MENU_ENABLED[8]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}9. Полный отчёт по дисковому пространству${NC}"
    log_header

    REPORT_FILE="/tmp/disk-usage-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "=========================================="
        echo "ОТЧЁТ ПО ДИСКОВОМУ ПРОСТРАНСТВУ"
        echo "Дата: $(date)"
        echo "Хост: $(hostname)"
        echo "=========================================="
        echo ""

        echo "=== Общая информация о дисках (df -h) ==="
        df -h
        echo ""

        echo "=== Типы файловых систем (df -hT) ==="
        df -hT
        echo ""

        echo "=== Использование inode (df -i) ==="
        df -i
        echo ""

        echo "=== Размер каталогов в корне ==="
        du -sh /* 2>/dev/null | sort -rh
        echo ""

        echo "=== Топ-20 самых больших файлов ==="
        sudo find / -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -20
        echo ""

        echo "=== Файлы размером более 1ГБ ==="
        sudo find / -type f -size +1G -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}'
        echo ""

        echo "=== Размер кэша пакетов ==="
        echo "DNF: $(du -sh /var/cache/dnf 2>/dev/null || echo 'недоступно')"
        echo ""

        echo "=== Размер системных журналов ==="
        journalctl --disk-usage 2>/dev/null || echo "journalctl недоступен"
        echo ""

        echo "=== Удалённые, но занятые файлы ==="
        sudo lsof +L1 2>/dev/null || echo "Не найдены"
        echo ""

        echo "=========================================="
        echo "Конец отчёта"
        echo "=========================================="
    } > "$REPORT_FILE"

    echo -e "${GREEN}Отчёт сохранён в: ${CYAN}$REPORT_FILE${NC}"
    echo ""

    if confirm_action "Показать отчёт в терминале?"; then
        cat "$REPORT_FILE"
    fi

    RESULTS[9]="✓ Выполнено"
fi

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Итоги выполнения"
log_header
echo ""

for key in "${!RESULTS[@]}"; do
    echo -e "  ${BLUE}$key.${NC} ${RESULTS[$key]}"
done
echo ""

log_info "Рекомендации:"
echo -e "  ${CYAN}•${NC} Регулярно очищайте кэш пакетного менеджера"
echo -e "  ${CYAN}•${NC} Удаляйте ненужные файлы и дубликаты"
echo -e "  ${CYAN}•${NC} Мониторьте размер системных журналов"
echo -e "  ${CYAN}•${NC} Используйте ${GREEN}ncdu${NC} для интерактивного анализа"
echo ""

log_info "Для установки дополнительных утилит:"
echo -e "  ${CYAN}sudo dnf install ncdu fdupes rdfind baobab filelight${NC}"
echo ""

log_info "Скрипт завершил работу"
