#!/bin/bash
##############################################################################
# redos-auto-update.sh — Автоматическое обновление РЕД ОС по расписанию
#
# Использование:
#   sudo ./redos-auto-update.sh [OPTIONS]
#
# Опции:
#   --setup          Интерактивная настройка расписания
#   --run            Немедленный запуск обновления
#   --status         Показать статус таймера и расписание
#   --disable        Отключить автоматическое обновление
#   --edit           Изменить текущее расписание
#   --help           Справка
#
# Зависимости: bash, coreutils, systemd, dnf
# Совместимость: РЕД ОС 7.x ✅, РЕД ОС 8.x ✅
##############################################################################

set -euo pipefail

# ─── Цвета ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ─── Константы ───────────────────────────────────────────────────────────
CONF_FILE="/etc/redos-auto-update.conf"
SERVICE_FILE="/etc/systemd/system/redos-auto-update.service"
TIMER_FILE="/etc/systemd/system/redos-auto-update.timer"
WRAPPER_SCRIPT="/usr/local/bin/redos-auto-update"
LOG_FILE="/var/log/redos-auto-update.log"
DEFAULT_START_TIME="12:30"
DEFAULT_END_TIME="14:00"
DEFAULT_MODE="security"
DEFAULT_PERIOD="daily"

# ─── Функции вывода ─────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_header()  { echo -e "\n${CYAN}══════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}══════════════════════════════════════════════════${NC}"; }

# ─── Проверка root ───────────────────────────────────────────────────────
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Скрипт требует прав root. Запустите: sudo $0"
        exit 1
    fi
}

# ─── Чтение из терминала ─────────────────────────────────────────────────
read_terminal() {
    local prompt="$1"
    local answer
    echo -e "$prompt" >&2
    read -r answer < /dev/tty 2>/dev/null || true
    echo "$answer"
}

confirm() {
    local message="$1"
    local answer
    answer=$(read_terminal "${YELLOW}$message (y/n)${NC}")
    [[ "$answer" =~ ^[YyДада]$ ]]
}

# ─── Чтение конфига ─────────────────────────────────────────────────────
read_config() {
    local key="$1"
    local default="$2"
    if [ -f "$CONF_FILE" ]; then
        local val
        val=$(grep "^${key}=" "$CONF_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [ -n "$val" ]; then
            echo "$val"
            return
        fi
    fi
    echo "$default"
}

# ─── Валидация времени ───────────────────────────────────────────────────
validate_time() {
    local time="$1"
    if [[ "$time" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        return 0
    else
        return 1
    fi
}

# ─── Конвертация времени в минуты ────────────────────────────────────────
time_to_minutes() {
    local time="$1"
    local hours="${time%%:*}"
    local mins="${time##*:}"
    # Убираем ведущие нули
    hours=$((10#$hours))
    mins=$((10#$mins))
    echo $((hours * 60 + mins))
}

# ─── Проверка, что текущее время в пределах окна ─────────────────────────
is_within_time_window() {
    local start_time="$1"
    local end_time="$2"

    local now=$(date +"%H:%M")
    local now_min=$(time_to_minutes "$now")
    local start_min=$(time_to_minutes "$start_time")
    local end_min=$(time_to_minutes "$end_time")

    if [ "$start_min" -le "$end_min" ]; then
        # Обычный диапазон (например 12:30–14:00)
        [ "$now_min" -ge "$start_min" ] && [ "$now_min" -le "$end_min" ]
    else
        # Переход через полночь (например 22:00–06:00)
        [ "$now_min" -ge "$start_min" ] || [ "$now_min" -le "$end_min" ]
    fi
}

# ─── Логирование ─────────────────────────────────────────────────────────
log_message() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# ─── Создание обёрточного скрипта ────────────────────────────────────────
create_wrapper_script() {
    local start_time="$1"
    local end_time="$2"
    local mode="$3"

    cat > "$WRAPPER_SCRIPT" << 'WRAPPER_EOF'
#!/bin/bash
##############################################################################
# redos-auto-update — Обёрточный скрипт для автоматического обновления
# Вызывается systemd timer
##############################################################################

LOG_FILE="/var/log/redos-auto-update.log"
CONF_FILE="/etc/redos-auto-update.conf"

log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Чтение конфига
read_config() {
    local key="$1"
    local default="$2"
    if [ -f "$CONF_FILE" ]; then
        local val
        val=$(grep "^${key}=" "$CONF_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [ -n "$val" ]; then
            echo "$val"
            return
        fi
    fi
    echo "$default"
}

time_to_minutes() {
    local time="$1"
    local hours="${time%%:*}"
    local mins="${time##*:}"
    hours=$((10#$hours))
    mins=$((10#$mins))
    echo $((hours * 60 + mins))
}

is_within_window() {
    local start_time="$1"
    local end_time="$2"
    local now=$(date +"%H:%M")
    local now_min=$(time_to_minutes "$now")
    local start_min=$(time_to_minutes "$start_time")
    local end_min=$(time_to_minutes "$end_time")

    if [ "$start_min" -le "$end_min" ]; then
        [ "$now_min" -ge "$start_min" ] && [ "$now_min" -le "$end_min" ]
    else
        [ "$now_min" -ge "$start_min" ] || [ "$now_min" -le "$end_min" ]
    fi
}

# ─── Основная логика ─────────────────────────────────────────────────
START_TIME=$(read_config "START_TIME" "12:30")
END_TIME=$(read_config "END_TIME" "14:00")
MODE=$(read_config "MODE" "security")

log "=========================================="
log "ЗАПУСК автоматического обновления"
log "Время: $(date)"
log "Окно: ${START_TIME} – ${END_TIME}"
log "Режим: ${MODE}"

# Проверка окна времени
if ! is_within_window "$START_TIME" "$END_TIME"; then
    log "ВНЕ временного окна (${START_TIME}–${END_TIME}). Пропуск."
    exit 0
fi

log "В пределах временного окна. Начало проверки..."

# Обновление кэша репозиториев
log "Обновление кэша репозиториев..."
dnf makecache 2>&1 | tail -5 >> "$LOG_FILE" 2>&1

# Проверка доступных обновлений
UPDATE_COUNT=$(dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)
log "Доступно обновлений: ${UPDATE_COUNT}"

if [ "$UPDATE_COUNT" -eq 0 ]; then
    log "Система актуальна. Обновлений нет."
    exit 0
fi

# Список обновлений
log "Доступные обновления:"
dnf check-update -q 2>/dev/null | grep "^[a-z]" >> "$LOG_FILE" 2>&1

case "$MODE" in
    check-only)
        log "Режим: только проверка. Обновления НЕ устанавливаются."
        ;;
    security)
        log "Режим: установка обновлений безопасности..."
        SECURITY_COUNT=$(dnf updateinfo list security 2>/dev/null | grep -c "^[A-Z]" || echo 0)
        if [ "$SECURITY_COUNT" -gt 0 ]; then
            log "Найдено ${SECURITY_COUNT} обновлений безопасности. Установка..."
            dnf upgrade --security -y >> "$LOG_FILE" 2>&1
            RESULT=$?
            if [ $RESULT -eq 0 ]; then
                log "Обновления безопасности установлены успешно."
            else
                log "ОШИБКА при установке обновлений безопасности (код: $RESULT)"
            fi
        else
            log "Обновлений безопасности не найдено."
        fi
        ;;
    full)
        log "Режим: полное обновление системы..."
        dnf upgrade -y >> "$LOG_FILE" 2>&1
        RESULT=$?
        if [ $RESULT -eq 0 ]; then
            log "Полное обновление завершено успешно."
        else
            log "ОШИБКА при полном обновении (код: $RESULT)"
        fi
        ;;
    *)
        log "Неизвестный режим: ${MODE}"
        exit 1
        ;;
esac

# Очистка кэша
dnf clean expire-cache >> "$LOG_FILE" 2>&1

log "Автоматическое обновление завершено."
log "=========================================="

# Отправка уведомления (если настроено)
# Канал: MAX Messenger (platform-api.max.ru)
NOTIFY_TEXT="🔔 РЕД ОС: обновление завершено ($(date '+%d.%m.%Y %H:%M'))
Режим: ${MODE}
Обновлений: ${UPDATE_COUNT}"

# MAX Messenger
MAX_BOT=$(read_config "MAX_BOT_TOKEN" "")
MAX_CHAT=$(read_config "MAX_CHAT_ID" "")
if [ -n "$MAX_BOT" ] && [ -n "$MAX_CHAT" ]; then
    curl -s -X POST "https://platform-api.max.ru/messages?chat_id=${MAX_CHAT}" \
        -H "Authorization: Bearer ${MAX_BOT}" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"${NOTIFY_TEXT}\"}" >> "$LOG_FILE" 2>&1
    log "Уведомление отправлено в MAX"
fi

exit 0
WRAPPER_EOF

    chmod +x "$WRAPPER_SCRIPT"
}

# ─── Создание systemd service ────────────────────────────────────────────
create_service_file() {
    cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=RED OS Automatic Update
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/redos-auto-update
Nice=19
IOSchedulingClass=best-effort
IOSchedulingPriority=7
TimeoutStopSec=3600

[Install]
WantedBy=multi-user.target
EOF
}

# ─── Создание systemd timer ──────────────────────────────────────────────
create_timer_file() {
    local period="$1"

    cat > "$TIMER_FILE" << EOF
[Unit]
Description=RED OS Automatic Update Timer
Requires=redos-auto-update.service

[Timer]
OnCalendar=${period}
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF
}

# ─── Настройка расписания (интерактивная) ────────────────────────────────
setup_schedule() {
    log_header "Настройка автоматического обновления"

    # Чтение текущих значений
    local current_start=$(read_config "START_TIME" "$DEFAULT_START_TIME")
    local current_end=$(read_config "END_TIME" "$DEFAULT_END_TIME")
    local current_mode=$(read_config "MODE" "$DEFAULT_MODE")
    local current_period=$(read_config "PERIOD" "$DEFAULT_PERIOD")

    echo ""
    echo -e "  ${WHITE}Текущие настройки:${NC}"
    echo -e "    Время начала:  ${CYAN}${current_start}${NC}"
    echo -e "    Время окончания: ${CYAN}${current_end}${NC}"
    echo -e "    Режим:          ${CYAN}${current_mode}${NC}"
    echo -e "    Период:         ${CYAN}${current_period}${NC}"
    echo ""

    # ── Время начала ──
    while true; do
        local input
        input=$(read_terminal "${BLUE}Время начала обновления [${current_start}]:${NC} ")
        if [ -z "$input" ]; then
            START_TIME="$current_start"
            break
        elif validate_time "$input"; then
            START_TIME="$input"
            break
        else
            log_error "Неверный формат времени. Используйте ЧЧ:ММ (например, 12:30)"
        fi
    done

    # ── Время окончания ──
    while true; do
        local input
        input=$(read_terminal "${BLUE}Время окончания обновления [${current_end}]:${NC} ")
        if [ -z "$input" ]; then
            END_TIME="$current_end"
            break
        elif validate_time "$input"; then
            END_TIME="$input"
            break
        else
            log_error "Неверный формат времени. Используйте ЧЧ:ММ (например, 14:00)"
        fi
    done

    # ── Режим обновления ──
    echo ""
    echo -e "  ${WHITE}Режим обновления:${NC}"
    echo -e "    1) ${CYAN}security${NC}  — только обновления безопасности (рекомендуется)"
    echo -e "    2) ${CYAN}full${NC}      — полное обновление всех пакетов"
    echo -e "    3) ${CYAN}check-only${NC} — только проверка без установки"
    echo ""

    while true; do
        local input
        input=$(read_terminal "${BLUE}Выберите режим [1-3] [${current_mode}]:${NC} ")
        if [ -z "$input" ]; then
            MODE="$current_mode"
            break
        fi
        case "$input" in
            1|"security") MODE="security"; break ;;
            2|"full")     MODE="full"; break ;;
            3|"check-only") MODE="check-only"; break ;;
            *) log_warn "Введите 1, 2, 3 или название режима" ;;
        esac
    done

    # ── Периодичность ──
    echo ""
    echo -e "  ${WHITE}Периодичность запуска:${NC}"
    echo -e "    1) ${CYAN}daily${NC}       — каждый день"
    echo -e "    2) ${CYAN}weekly${NC}      — раз в неделю (понедельник)"
    echo -e "    3) ${CYAN}mon..fri${NC}    — каждый будний день"
    echo -e "    4) ${CYAN}custom${NC}      — вручную указать дни"
    echo ""

    while true; do
        local input
        input=$(read_terminal "${BLUE}Выберите период [1-4] [${current_period}]:${NC} ")
        if [ -z "$input" ]; then
            PERIOD="$current_period"
            break
        fi
        case "$input" in
            1|"daily")    PERIOD="daily"; break ;;
            2|"weekly")   PERIOD="Mon *-*-* 12:30:00"; break ;;
            3|"mon..fri") PERIOD="Mon..Fri *-*-* ${START_TIME}:00"; break ;;
            4|"custom")
                echo ""
                echo -e "  ${WHITE}Дни недели (введите номера через пробел):${NC}"
                echo -e "    1) Пн  2) Вт  3) Ср  4) Чт  5) Пт  6) Сб  7) Вс"
                echo ""
                local days_input
                days_input=$(read_terminal "${BLUE}Дни:${NC} ")
                local days=""
                for d in $days_input; do
                    case "$d" in
                        1) days="${days}Mon," ;;
                        2) days="${days}Tue," ;;
                        3) days="${days}Wed," ;;
                        4) days="${days}Thu," ;;
                        5) days="${days}Fri," ;;
                        6) days="${days}Sat," ;;
                        7) days="${days}Sun," ;;
                    esac
                done
                days="${days%,}" # убираем последнюю запятую
                if [ -n "$days" ]; then
                    PERIOD="${days} *-*-* ${START_TIME}:00"
                else
                    PERIOD="daily"
                fi
                break
                ;;
            *) log_warn "Введите 1, 2, 3 или 4" ;;
        esac
    done

    # ── Уведомления ──
    echo ""
    if confirm "Настроить уведомления в MAX Messenger?"; then
        echo -e "  ${WHITE}Создайте бота на ${CYAN}dev.max.ru${WHITE}, получите токен.${NC}"
        echo -e "  ${WHITE}В MAX откройте чат с ботом, отправьте /start, узнайте chat_id.${NC}"
        echo ""
        MAX_BOT=$(read_terminal "${BLUE}MAX Bot Token:${NC} ")
        MAX_CHAT=$(read_terminal "${BLUE}MAX Chat ID:${NC} ")
    else
        MAX_BOT=""
        MAX_CHAT=""
    fi

    # ── Показ итоговой конфигурации ──
    echo ""
    log_header "Итоговая конфигурация"
    echo -e "  ${WHITE}Время:${NC}         ${GREEN}${START_TIME} — ${END_TIME}${NC}"
    echo -e "  ${WHITE}Режим:${NC}         ${GREEN}${MODE}${NC}"
    echo -e "  ${WHITE}Период:${NC}        ${GREEN}${PERIOD}${NC}"
    echo -e "  ${WHITE}Уведомления:${NC}   $(if [ -n "$MAX_BOT" ]; then echo -e "${GREEN}MAX Messenger${NC}"; else echo "отключены"; fi)"
    echo ""

    if ! confirm "Применить настройки?"; then
        log_info "Настройка отменена."
        return
    fi

    # ── Запись конфига ──
    log_info "Сохранение конфигурации..."
    cat > "$CONF_FILE" << EOFCONF
# Конфигурация автоматического обновления РЕД ОС
# Сгенерировано: $(date)

START_TIME="${START_TIME}"
END_TIME="${END_TIME}"
MODE="${MODE}"
PERIOD="${PERIOD}"

# MAX Messenger (platform-api.max.ru)
MAX_BOT_TOKEN="${MAX_BOT}"
MAX_CHAT_ID="${MAX_CHAT}"
EOFCONF

    chmod 600 "$CONF_FILE"
    log_ok "Конфиг сохранён: ${CONF_FILE}"

    # ── Создание файлов ──
    log_info "Создание systemd unit-файлов..."
    create_wrapper_script "$START_TIME" "$END_TIME" "$MODE"
    log_ok "Обёрточный скрипт: ${WRAPPER_SCRIPT}"

    create_service_file
    log_ok "Service файл: ${SERVICE_FILE}"

    create_timer_file "$PERIOD"
    log_ok "Timer файл: ${TIMER_FILE}"

    # ── Активация ──
    log_info "Активация systemd timer..."
    systemctl daemon-reload
    systemctl enable redos-auto-update.timer
    systemctl enable redos-auto-update.service
    systemctl restart redos-auto-update.timer

    log_ok "Таймер активирован и запущен!"
    echo ""
    log_info "Проверка статуса: sudo $0 --status"
    log_info "Журнал: tail -f $LOG_FILE"

    echo ""
    log_header "Готово!"
    echo -e "  ${GREEN}Автоматическое обновление настроено${NC}"
    echo -e "  ${WHITE}Ближайший запуск:${NC} $(systemctl list-timers redos-auto-update.timer --no-pager 2>/dev/null | tail -1 | awk '{print $1, $2, $3}')"
}

# ─── Изменение расписания ────────────────────────────────────────────────
edit_schedule() {
    if [ ! -f "$CONF_FILE" ]; then
        log_warn "Конфигурация не найдена. Сначала запустите: sudo $0 --setup"
        exit 1
    fi
    setup_schedule
}

# ─── Немедленный запуск обновления ────────────────────────────────────────
run_update() {
    check_root

    if [ ! -f "$CONF_FILE" ]; then
        log_warn "Конфигурация не найдена. Запуск в режиме проверки..."
        START_TIME="00:00"
        END_TIME="23:59"
        MODE="security"
    else
        START_TIME=$(read_config "START_TIME" "$DEFAULT_START_TIME")
        END_TIME=$(read_config "END_TIME" "$DEFAULT_END_TIME")
        MODE=$(read_config "MODE" "$DEFAULT_MODE")
    fi

    log_header "Немедленное обновление"
    echo -e "  ${WHITE}Окно:${NC} ${START_TIME} – ${END_TIME}"
    echo -e "  ${WHITE}Режим:${NC} ${MODE}"
    echo ""

    if ! is_within_time_window "$START_TIME" "$END_TIME"; then
        log_warn "Текущее время вне настроенного окна (${START_TIME}–${END_TIME})"
        if ! confirm "Продолжить принудительно?"; then
            log_info "Отменено."
            exit 0
        fi
    fi

    # Запуск обёрточного скрипта напрямую
    if [ -x "$WRAPPER_SCRIPT" ]; then
        "$WRAPPER_SCRIPT"
    else
        # Fallback: встроенная логика
        log_info "Обёрточный скрипт не найден. Использование встроенной логики..."

        log_message "ЗАПУСК автоматического обновления (встроенный режим)"

        dnf makecache 2>&1 | tail -3

        UPDATE_COUNT=$(dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)
        log_info "Доступно обновлений: ${UPDATE_COUNT}"

        if [ "$UPDATE_COUNT" -eq 0 ]; then
            log_ok "Система актуальна."
            exit 0
        fi

        case "$MODE" in
            check-only)
                log_info "Режим проверки. Обновления:"
                dnf check-update -q 2>/dev/null | head -20
                ;;
            security)
                log_info "Установка обновлений безопасности..."
                dnf upgrade --security -y 2>&1 | tail -5
                ;;
            full)
                log_info "Полное обновление..."
                dnf upgrade -y 2>&1 | tail -5
                ;;
        esac

        log_ok "Обновление завершено."
        log_message "Обновление завершено (встроенный режим)"
    fi
}

# ─── Показать статус ─────────────────────────────────────────────────────
show_status() {
    log_header "Статус автоматического обновления"

    if [ -f "$CONF_FILE" ]; then
        echo -e "  ${WHITE}Конфигурация:${NC}"
        echo -e "    Время:      $(read_config "START_TIME" "—") – $(read_config "END_TIME" "—")"
        echo -e "    Режим:      $(read_config "MODE" "—")"
        echo -e "    Период:     $(read_config "PERIOD" "—")"
        local mx=$(read_config "MAX_BOT_TOKEN" "")
        if [ -n "$mx" ]; then
            echo -e "    MAX:        ${GREEN}настроен${NC}"
        else
            echo -e "    Уведомления: отключены"
        fi
        echo ""
    else
        log_warn "Конфигурация не найдена"
        echo ""
    fi

    # Статус timer
    if systemctl is-active -q redos-auto-update.timer 2>/dev/null; then
        echo -e "  ${WHITE}Таймер:${NC} ${GREEN}активен${NC}"
        echo ""
        log_info "Ближайшие запуски:"
        systemctl list-timers redos-auto-update.timer --no-pager 2>/dev/null | head -5
    else
        echo -e "  ${WHITE}Таймер:${NC} ${RED}не активен${NC}"
    fi

    echo ""

    # Логи
    if [ -f "$LOG_FILE" ]; then
        log_info "Последние записи в журнале:"
        tail -15 "$LOG_FILE"
    else
        log_info "Журнал ещё не создан"
    fi

    echo ""
}

# ─── Отключение ──────────────────────────────────────────────────────────
disable_schedule() {
    log_header "Отключение автоматического обновления"

    if ! confirm "Отключить автоматическое обновление?"; then
        log_info "Отменено."
        return
    fi

    systemctl stop redos-auto-update.timer 2>/dev/null || true
    systemctl disable redos-auto-update.timer 2>/dev/null || true
    systemctl disable redos-auto-update.service 2>/dev/null || true
    systemctl daemon-reload

    log_ok "Таймер отключён"

    if confirm "Удалить конфигурацию и логи?"; then
        rm -f "$CONF_FILE" "$WRAPPER_SCRIPT" "$SERVICE_FILE" "$TIMER_FILE"
        rm -f "$LOG_FILE"
        systemctl daemon-reload
        log_ok "Все файлы удалены"
    fi
}

# ─── Справка ─────────────────────────────────────────────────────────────
show_help() {
    head -20 "$0" | tail -16 | sed 's/^# \?//'
    echo ""
    echo -e "  ${WHITE}Примеры:${NC}"
    echo -e "    sudo $0 --setup      # Интерактивная настройка"
    echo -e "    sudo $0 --run        # Немедленное обновление"
    echo -e "    sudo $0 --status     # Показать статус"
    echo -e "    sudo $0 --disable    # Отключить"
    echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    case "$1" in
        --setup)
            check_root
            setup_schedule
            ;;
        --run)
            check_root
            run_update
            ;;
        --status)
            show_status
            ;;
        --disable)
            check_root
            disable_schedule
            ;;
        --edit)
            check_root
            edit_schedule
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
