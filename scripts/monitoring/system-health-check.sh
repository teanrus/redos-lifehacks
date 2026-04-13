#!/bin/bash
##############################################################################
# system-health-check.sh -- Полная диагностика системы РЕД ОС
#
# Использование:
#   sudo ./system-health-check.sh [OPTIONS]
#
# Опции:
#   --quick        Экспресс-проверка (30 секунд)
#   --full         Полная проверка (5 минут)
#   --cpu          Только CPU
#   --ram          Только RAM
#   --disk         Только диски
#   --network      Только сеть
#   --services     Только сервисы
#   --security     Только безопасность
#   --temp         Только температура
#   --report FMT   Формат отчёта: txt, html, json (по умолчанию: txt)
#   --output DIR   Директория для отчёта (по умолчанию: ./reports/)
#   --quiet        Тихий режим (только предупреждения и ошибки)
#   --help         Справка
#
# Зависимости: bash, coreutils, systemd, dnf, procps
# Опционально: smartmontools, lm_sensors, hddtemp, ethtool, jq
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
NC='\033[0m' # No Color

# ─── Настройки ───────────────────────────────────────────────────────────
REPORT_FORMAT="txt"
OUTPUT_DIR="./reports"
QUIET=false
CHECK_TYPE="full"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
HOSTNAME=$(hostname)
OS_INFO=$(cat /etc/redos-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)

# ─── Функции ─────────────────────────────────────────────────────────────
log_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_ok() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[OK]${NC}   $1"
    fi
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}  $1${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
    fi
}

# Проверка root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_warn "Для полной проверки необходим root. Некоторые данные могут быть недоступны."
    fi
}

# ─── Проверки ────────────────────────────────────────────────────────────

check_cpu() {
    log_header "CPU -- Процессор"

    local model
    model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    local cores
    cores=$(nproc)
    local load
    load=$(cat /proc/loadavg)
    local load_1m
    load_1m=$(echo "$load" | awk '{print $1}')
    local load_int=${load_1m%%.*}

    echo -e "  Модель:       ${WHITE}${model}${NC}"
    echo -e "  Ядра:         ${WHITE}${cores}${NC}"
    echo -e "  Load Average: ${WHITE}${load}${NC}"

    if [ "$load_int" -gt $((cores * 2)) ]; then
        log_error "Загрузка CPU критическая: ${load_1m} (при ${cores} ядрах)"
    elif [ "$load_int" -gt "$cores" ]; then
        log_warn "Загрузка CPU высокая: ${load_1m} (при ${cores} ядрах)"
    else
        log_ok "Загрузка CPU в норме: ${load_1m} (при ${cores} ядрах)"
    fi

    # Топ процессов по CPU
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "  ${WHITE}Топ-5 процессов по CPU:${NC}"
        ps aux --sort=-%cpu | awk 'NR<=6 {printf "    %-20s %5s%%  %s\n", $11, $3, $1}'
    fi

    # Троттлинг
    local throttle
    throttle=$(dmesg 2>/dev/null | grep -ic "throttl")
    if [ "$throttle" -gt 0 ]; then
        log_warn "Обнаружен thermal throttling ($throttle записей в dmesg)"
    else
        log_ok "Троттлинг не обнаружен"
    fi
}

check_ram() {
    log_header "RAM -- Оперативная память"

    local total_mb used_mb avail_mb swap_total_mb swap_used_mb
    total_mb=$(free -m | awk '/^Mem:/ {print $2}')
    used_mb=$(free -m | awk '/^Mem:/ {print $3}')
    avail_mb=$(free -m | awk '/^Mem:/ {print $7}')
    swap_total_mb=$(free -m | awk '/^Swap:/ {print $2}')
    swap_used_mb=$(free -m | awk '/^Swap:/ {print $3}')

    local usage_pct=0
    if [ "$total_mb" -gt 0 ]; then
        usage_pct=$((used_mb * 100 / total_mb))
    fi

    echo -e "  Всего:        ${WHITE}${total_mb} МБ${NC}"
    echo -e "  Использовано: ${WHITE}${used_mb} МБ (${usage_pct}%)${NC}"
    echo -e "  Доступно:     ${WHITE}${avail_mb} МБ${NC}"
    echo -e "  Swap:         ${WHITE}${swap_used_mb} МБ / ${swap_total_mb} МБ${NC}"

    if [ "$usage_pct" -gt 90 ]; then
        log_error "Использование RAM критическое: ${usage_pct}%"
    elif [ "$usage_pct" -gt 70 ]; then
        log_warn "Использование RAM высокое: ${usage_pct}%"
    else
        log_ok "Использование RAM в норме: ${usage_pct}%"
    fi

    # Swap
    if [ "$swap_total_mb" -gt 0 ] && [ "$swap_used_mb" -gt 0 ]; then
        local swap_pct=$((swap_used_mb * 100 / swap_total_mb))
        if [ "$swap_pct" -gt 50 ]; then
            log_warn "Swap активно используется: ${swap_pct}%"
        elif [ "$swap_pct" -gt 20 ]; then
            log_warn "Swap используется умеренно: ${swap_pct}%"
        else
            log_ok "Swap в норме: ${swap_pct}%"
        fi
    fi

    # OOM
    local oom_count
    oom_count=$(dmesg 2>/dev/null | grep -ic "oom\|out of memory")
    if [ "$oom_count" -gt 0 ]; then
        log_warn "OOM Killer срабатывал: ${oom_count} раз"
    fi

    # Топ процессов по RAM
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "  ${WHITE}Топ-5 процессов по RAM:${NC}"
        ps aux --sort=-%mem | awk 'NR<=6 {printf "    %-20s %5s%%  %s MB\n", $11, $4, $6/1024, $1}'
    fi
}

check_disk() {
    log_header "DISK -- Дисковое пространство"

    local has_warning=false

    # Проверка разделов
    while IFS= read -r line; do
        local usage pct mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')
        if [ "$usage" -gt 90 ]; then
            log_error "Раздел ${mount} заполнен на ${usage}%"
            has_warning=true
        elif [ "$usage" -gt 80 ]; then
            log_warn "Раздел ${mount} заполнен на ${usage}%"
            has_warning=true
        else
            log_ok "Раздел ${mount}: ${usage}% использовано"
        fi
    done < <(df -h --output=pcent,target 2>/dev/null | grep "^ *[0-9]" | grep -E "^|/dev/")

    if [ "$has_warning" = false ] && [ "$QUIET" = false ]; then
        echo ""
        df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E "Filesystem|/dev/"
    fi

    # Inodes
    if [ "$QUIET" = false ]; then
        echo ""
        log_info "Inode usage:"
        df -i 2>/dev/null | grep "^/dev/" | while read -r line; do
            local inode_pct
            inode_pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
            local mount_pt
            mount_pt=$(echo "$line" | awk '{print $6}')
            if [ "$inode_pct" -gt 80 ]; then
                log_warn "Inode на ${mount_pt}: ${inode_pct}%"
            else
                log_ok "Inode на ${mount_pt}: ${inode_pct}%"
            fi
        done
    fi

    # SMART (если доступен)
    if command -v smartctl &>/dev/null; then
        if [ "$QUIET" = false ]; then
            echo ""
            log_info "SMART статус:"
            for disk in /dev/sd[a-z] /dev/nvme[0-9]; do
                if [ -b "$disk" ]; then
                    local smart_status
                    smart_status=$(smartctl -H "$disk" 2>/dev/null | grep -i "result" | awk '{print $NF}')
                    if [ "$smart_status" = "PASSED" ]; then
                        log_ok "${disk}: SMART OK"
                    elif [ "$smart_status" = "FAILED!" ]; then
                        log_error "${disk}: SMART FAILED!"
                    else
                        log_warn "${disk}: SMART статус неизвестен"
                    fi
                fi
            done
        fi
    else
        log_info "smartctl не установлен: sudo dnf install smartmontools"
    fi
}

check_network() {
    log_header "NETWORK -- Сетевые интерфейсы"

    # Интерфейсы
    if [ "$QUIET" = false ]; then
        echo -e "  ${WHITE}Интерфейсы:${NC}"
        ip -br addr show 2>/dev/null | while read -r line; do
            local iface status
            iface=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2}')
            if [ "$status" = "UP" ] || [ "$status" = "UNKNOWN" ]; then
                log_ok "${iface}: ${status}"
            else
                log_warn "${iface}: ${status}"
            fi
        done
    fi

    # DNS
    local dns_servers
    dns_servers=$(grep -c "^nameserver" /etc/resolv.conf 2>/dev/null || echo 0)
    if [ "$dns_servers" -gt 0 ]; then
        log_ok "DNS серверов настроено: ${dns_servers}"
    else
        log_warn "DNS серверы не найдены в /etc/resolv.conf"
    fi

    # Соединения
    local established
    established=$(ss -tn state established 2>/dev/null | wc -l)
    local listening
    listening=$(ss -tln 2>/dev/null | tail -n +2 | wc -l)
    echo -e "  Установлено соединений: ${WHITE}${established}${NC}"
    echo -e "  Слушающих портов:       ${WHITE}${listening}${NC}"

    # Packet loss test
    local loss
    loss=$(ping -c 3 -W 2 8.8.8.8 2>/dev/null | grep "packet loss" | awk '{print $6}' | tr -d '%')
    if [ -n "$loss" ]; then
        if [ "$loss" -gt 5 ]; then
            log_warn "Потеря пакетов: ${loss}%"
        elif [ "$loss" -gt 0 ]; then
            log_warn "Небольшая потеря пакетов: ${loss}%"
        else
            log_ok "Потеря пакетов: ${loss}%"
        fi
    fi
}

check_services() {
    log_header "SERVICES -- Системные сервисы"

    local failed_count
    failed_count=$(systemctl --failed --no-legend 2>/dev/null | wc -l)

    if [ "$failed_count" -gt 0 ]; then
        log_error "Failed сервисов: ${failed_count}"
        if [ "$QUIET" = false ]; then
            systemctl --failed --no-pager 2>/dev/null | head -10
        fi
    else
        log_ok "Все сервисы работают (${failed_count} failed)"
    fi

    # Enabled сервисы
    local enabled_count
    enabled_count=$(systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | wc -l)
    echo -e "  Включено сервисов: ${WHITE}${enabled_count}${NC}"

    # Медленные сервисы
    if [ "$QUIET" = false ]; then
        echo ""
        log_info "Топ-5 медленных сервисов при загрузке:"
        systemd-analyze blame 2>/dev/null | head -5 | while read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    fi
}

check_updates() {
    log_header "UPDATES -- Доступные обновления"

    local update_count
    update_count=$(sudo dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)

    echo -e "  Доступно обновлений: ${WHITE}${update_count}${NC}"

    if [ "$update_count" -gt 10 ]; then
        log_warn "Много доступных обновлений: ${update_count}"
    elif [ "$update_count" -gt 0 ]; then
        log_info "Доступно обновлений: ${update_count}"
    else
        log_ok "Система обновлена"
    fi

    # Security обновления
    local security_count
    security_count=$(sudo dnf updateinfo list security 2>/dev/null | grep -c "^[A-Z]" || echo 0)
    if [ "$security_count" -gt 0 ]; then
        log_warn "Security обновлений: ${security_count}"
    else
        log_ok "Security обновлений нет"
    fi
}

check_security() {
    log_header "SECURITY -- Безопасность"

    # Firewall
    local fw_status
    fw_status=$(systemctl is-active firewalld 2>/dev/null || echo "inactive")
    if [ "$fw_status" = "active" ]; then
        log_ok "Firewall (firewalld): активен"
    else
        log_warn "Firewall (firewalld): не активен"
    fi

    # SELinux
    local selinux_status
    selinux_status=$(getenforce 2>/dev/null || echo "unknown")
    if [ "$selinux_status" = "Enforcing" ]; then
        log_ok "SELinux: Enforcing"
    elif [ "$selinux_status" = "Permissive" ]; then
        log_warn "SELinux: Permissive"
    else
        log_warn "SELinux: ${selinux_status}"
    fi

    # SSH
    local ssh_status
    ssh_status=$(systemctl is-active sshd 2>/dev/null || echo "inactive")
    if [ "$ssh_status" = "active" ]; then
        log_info "SSH: активен (проверьте настройки /etc/ssh/sshd_config)"
    fi

    # Пользователи с UID 0
    local root_users
    root_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd | wc -l)
    if [ "$root_users" -gt 1 ]; then
        log_warn "Несколько пользователей с UID 0: $(awk -F: '$3 == 0 {print $1}' /etc/passwd | tr '\n' ', ')"
    else
        log_ok "UID 0: только root"
    fi

    # SUID файлы (если root)
    if [ "$(id -u)" -eq 0 ] && [ "$QUIET" = false ]; then
        local suid_count
        suid_count=$(find / -perm -4000 -type f 2>/dev/null | wc -l)
        echo -e "  SUID файлов: ${WHITE}${suid_count}${NC}"
    fi
}

check_temp() {
    log_header "TEMPERATURE -- Температура"

    if command -v sensors &>/dev/null; then
        sensors 2>/dev/null | while IFS= read -r line; do
            if echo "$line" | grep -q "+"; then
                local temp
                temp=$(echo "$line" | grep -oP '\+[\d.]+' | head -1 | tr -d '+')
                if [ -n "$temp" ]; then
                    local temp_int=${temp%%.*}
                    if [ "$temp_int" -gt 80 ]; then
                        log_error "Температура: ${line}"
                    elif [ "$temp_int" -gt 65 ]; then
                        log_warn "Температура: ${line}"
                    else
                        log_ok "Температура: ${line}"
                    fi
                fi
            fi
        done
    else
        log_info "lm_sensors не установлен: sudo dnf install lm_sensors"
    fi

    # HDD температура
    if command -v hddtemp &>/dev/null; then
        for disk in /dev/sd[a-z]; do
            if [ -b "$disk" ]; then
                local hdd_temp
                hdd_temp=$(hddtemp "$disk" 2>/dev/null | awk '{print $NF}' | tr -d '°C')
                if [ -n "$hdd_temp" ] && [ "$hdd_temp" != "no sensor" ] && [ "$hdd_temp" != "S.M.A.R.T." ]; then
                    if [ "$hdd_temp" -gt 55 ]; then
                        log_warn "HDD ${disk}: ${hdd_temp}°C"
                    else
                        log_ok "HDD ${disk}: ${hdd_temp}°C"
                    fi
                fi
            fi
        done
    fi
}

check_boot() {
    log_header "BOOT -- Анализ загрузки"

    local boot_time
    boot_time=$(systemd-analyze 2>/dev/null | head -1)
    echo -e "  ${WHITE}${boot_time}${NC}"

    echo ""
    log_info "Топ-5 медленных сервисов:"
    systemd-analyze blame 2>/dev/null | head -5 | while read -r line; do
        echo -e "    ${WHITE}${line}${NC}"
    done
}

check_users() {
    log_header "USERS -- Пользователи"

    local login_users
    login_users=$(grep -cE ':/bin/(bash|sh|zsh)$' /etc/passwd)
    echo -e "  Пользователей с login shell: ${WHITE}${login_users}${NC}"

    if [ "$QUIET" = false ]; then
        echo ""
        log_info "Пользователи с login shell:"
        grep -E ':/bin/(bash|sh|zsh)$' /etc/passwd | cut -d: -f1 | while read -r user; do
            echo -e "    ${WHITE}${user}${NC}"
        done
    fi

    # Последние входы
    echo ""
    log_info "Последние входы:"
    last -5 2>/dev/null | head -5
}

check_backups() {
    log_header "BACKUPS -- Резервное копирование"

    # Cron backup tasks
    local cron_backups
    cron_backups=$(crontab -l 2>/dev/null | grep -c "backup\|rsync\|tar" || echo 0)
    echo -e "  Задач бэкапа в cron (user): ${WHITE}${cron_backups}${NC}"

    local root_cron_backups
    root_cron_backups=$(sudo crontab -l 2>/dev/null | grep -c "backup\|rsync\|tar" || echo 0)
    echo -e "  Задач бэкапа в cron (root): ${WHITE}${root_cron_backups}${NC}"

    if [ "$cron_backups" -eq 0 ] && [ "$root_cron_backups" -eq 0 ]; then
        log_warn "Задачи резервного копирования не найдены!"
    else
        log_ok "Задачи бэкапа найдены"
    fi
}

# ─── Генерация отчётов ──────────────────────────────────────────────────

generate_txt_report() {
    local report_file="${OUTPUT_DIR}/health-report-${TIMESTAMP}.txt"
    mkdir -p "$OUTPUT_DIR"

    {
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║         ОТЧЁТ О СОСТОЯНИИ СИСТЕМЫ                       ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "Хост:     $HOSTNAME"
        echo "ОС:       $OS_INFO"
        echo "Дата:     $(date)"
        echo "Uptime:   $(uptime -p 2>/dev/null || uptime)"
        echo "Ядро:     $(uname -r)"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "CPU"
        echo "══════════════════════════════════════════════════════════"
        lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|Core|Socket|MHz"
        echo ""
        echo "Load Average: $(cat /proc/loadavg)"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "RAM"
        echo "══════════════════════════════════════════════════════════"
        free -h
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "DISK"
        echo "══════════════════════════════════════════════════════════"
        df -h
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "NETWORK"
        echo "══════════════════════════════════════════════════════════"
        ip -br addr show
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "SERVICES"
        echo "══════════════════════════════════════════════════════════"
        echo "Failed:"
        systemctl --failed --no-pager 2>/dev/null || echo "  None"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "SECURITY"
        echo "══════════════════════════════════════════════════════════"
        echo "Firewall: $(systemctl is-active firewalld 2>/dev/null || echo 'N/A')"
        echo "SELinux:  $(getenforce 2>/dev/null || echo 'N/A')"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "TOP PROCESSES (CPU)"
        echo "══════════════════════════════════════════════════════════"
        ps aux --sort=-%cpu | head -6
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "TOP PROCESSES (RAM)"
        echo "══════════════════════════════════════════════════════════"
        ps aux --sort=-%mem | head -6
    } > "$report_file"

    echo ""
    log_ok "TXT отчёт сохранён: ${WHITE}${report_file}${NC}"
}

generate_html_report() {
    local report_file="${OUTPUT_DIR}/health-report-${TIMESTAMP}.html"
    mkdir -p "$OUTPUT_DIR"

    local cpu_model
    cpu_model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    local cpu_cores
    cpu_cores=$(nproc)
    local ram_total
    ram_total=$(free -h | awk '/^Mem:/ {print $2}')
    local ram_used
    ram_used=$(free -h | awk '/^Mem:/ {print $3}')
    local ram_pct
    ram_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

    cat > "$report_file" << HTMLEOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Отчёт о состоянии системы -- $HOSTNAME</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f7fa; color: #333; padding: 20px; }
        .container { max-width: 960px; margin: 0 auto; }
        h1 { text-align: center; color: #1a1a2e; margin-bottom: 10px; }
        .subtitle { text-align: center; color: #666; margin-bottom: 30px; }
        .card { background: #fff; border-radius: 12px; padding: 20px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .card h2 { color: #1a1a2e; margin-bottom: 15px; border-bottom: 2px solid #e0e0e0; padding-bottom: 8px; }
        .metric { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #f0f0f0; }
        .metric:last-child { border-bottom: none; }
        .metric-label { font-weight: 500; color: #555; }
        .metric-value { font-weight: 600; color: #1a1a2e; }
        .status-ok { color: #27ae60; }
        .status-warn { color: #f39c12; }
        .status-error { color: #e74c3c; }
        .progress { height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; margin-top: 4px; }
        .progress-fill { height: 100%; border-radius: 4px; transition: width 0.3s; }
        .progress-ok { background: #27ae60; }
        .progress-warn { background: #f39c12; }
        .progress-error { background: #e74c3c; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #e0e0e0; }
        th { background: #f8f9fa; font-weight: 600; color: #555; }
        .footer { text-align: center; color: #999; margin-top: 30px; font-size: 0.85em; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 4px; font-size: 0.8em; font-weight: 600; }
        .badge-ok { background: #d4edda; color: #155724; }
        .badge-warn { background: #fff3cd; color: #856404; }
        .badge-error { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Отчёт о состоянии системы</h1>
        <p class="subtitle">$HOSTNAME | $OS_INFO | $(date '+%d.%m.%Y %H:%M:%S')</p>

        <div class="card">
            <h2>🖥️ CPU</h2>
            <div class="metric">
                <span class="metric-label">Модель</span>
                <span class="metric-value">$cpu_model</span>
            </div>
            <div class="metric">
                <span class="metric-label">Ядра</span>
                <span class="metric-value">$cpu_cores</span>
            </div>
            <div class="metric">
                <span class="metric-label">Load Average</span>
                <span class="metric-value">$(cat /proc/loadavg | awk '{print $1, $2, $3}')</span>
            </div>
        </div>

        <div class="card">
            <h2>🧠 RAM</h2>
            <div class="metric">
                <span class="metric-label">Всего</span>
                <span class="metric-value">$ram_total</span>
            </div>
            <div class="metric">
                <span class="metric-label">Использовано</span>
                <span class="metric-value">$ram_used ($ram_pct%)</span>
            </div>
            <div class="progress"><div class="progress-fill $( [ "$ram_pct" -gt 90 ] && echo 'progress-error' || ( [ "$ram_pct" -gt 70 ] && echo 'progress-warn' || echo 'progress-ok' ) )" style="width: ${ram_pct}%"></div></div>
            <div class="metric" style="margin-top:10px">
                <span class="metric-label">Swap</span>
                <span class="metric-value">$(free -h | awk '/^Swap:/ {print $3 " / " $2}')</span>
            </div>
        </div>

        <div class="card">
            <h2>💾 Диски</h2>
            <table>
                <tr><th>Раздел</th><th>Размер</th><th>Использовано</th><th>Свободно</th><th>Исп.%</th></tr>
                $(df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep "^/dev/" | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5, $6}')
            </table>
        </div>

        <div class="card">
            <h2>🌐 Сеть</h2>
            <table>
                <tr><th>Интерфейс</th><th>Статус</th><th>IP</th></tr>
                $(ip -br addr show 2>/dev/null | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3}')
            </table>
        </div>

        <div class="card">
            <h2>🔒 Безопасность</h2>
            <div class="metric">
                <span class="metric-label">Firewall</span>
                <span class="metric-value"><span class="badge $( [ "$(systemctl is-active firewalld 2>/dev/null)" = "active" ] && echo 'badge-ok' || echo 'badge-error' )">$(systemctl is-active firewalld 2>/dev/null || echo 'N/A')</span></span>
            </div>
            <div class="metric">
                <span class="metric-label">SELinux</span>
                <span class="metric-value"><span class="badge $( [ "$(getenforce 2>/dev/null)" = "Enforcing" ] && echo 'badge-ok' || echo 'badge-warn' )">$(getenforce 2>/dev/null || echo 'N/A')</span></span>
            </div>
        </div>

        <div class="card">
            <h2>⚙️ Сервисы</h2>
            <div class="metric">
                <span class="metric-label">Failed</span>
                <span class="metric-value"><span class="badge $( [ "$(systemctl --failed --no-legend 2>/dev/null | wc -l)" = "0" ] && echo 'badge-ok' || echo 'badge-error' )">$(systemctl --failed --no-legend 2>/dev/null | wc -l)</span></span>
            </div>
            <div class="metric">
                <span class="metric-label">Enabled</span>
                <span class="metric-value">$(systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | wc -l)</span>
            </div>
        </div>

        <div class="card">
            <h2>⏱️ Система</h2>
            <div class="metric">
                <span class="metric-label">Uptime</span>
                <span class="metric-value">$(uptime -p 2>/dev/null || uptime)</span>
            </div>
            <div class="metric">
                <span class="metric-label">Ядро</span>
                <span class="metric-value">$(uname -r)</span>
            </div>
            <div class="metric">
                <span class="metric-label">Обновления</span>
                <span class="metric-value">$(sudo dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)</span>
            </div>
        </div>

        <div class="footer">
            Сгенерировано system-health-check.sh | $(date '+%d.%m.%Y %H:%M:%S') | $HOSTNAME
        </div>
    </div>
</body>
</html>
HTMLEOF

    echo ""
    log_ok "HTML отчёт сохранён: ${WHITE}${report_file}${NC}"
}

generate_json_report() {
    local report_file="${OUTPUT_DIR}/health-report-${TIMESTAMP}.json"
    mkdir -p "$OUTPUT_DIR"

    local ram_pct
    ram_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    local failed_services
    failed_services=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    local update_count
    update_count=$(sudo dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)

    cat > "$report_file" << JSONEOF
{
  "report": {
    "hostname": "$HOSTNAME",
    "os": "$OS_INFO",
    "kernel": "$(uname -r)",
    "timestamp": "$(date -Iseconds)",
    "uptime": "$(uptime -p 2>/dev/null || uptime)"
  },
  "cpu": {
    "model": "$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)",
    "cores": $(nproc),
    "load_avg_1m": $(cat /proc/loadavg | awk '{print $1}'),
    "load_avg_5m": $(cat /proc/loadavg | awk '{print $2}'),
    "load_avg_15m": $(cat /proc/loadavg | awk '{print $3}')
  },
  "memory": {
    "total_mb": $(free -m | awk '/^Mem:/ {print $2}'),
    "used_mb": $(free -m | awk '/^Mem:/ {print $3}'),
    "available_mb": $(free -m | awk '/^Mem:/ {print $7}'),
    "usage_pct": $ram_pct,
    "swap_total_mb": $(free -m | awk '/^Swap:/ {print $2}'),
    "swap_used_mb": $(free -m | awk '/^Swap:/ {print $3}')
  },
  "disk": {
    "filesystems": [
      $(df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep "^/dev/" | awk '{gsub(/%/,"",$5); printf "{\"device\":\"%s\",\"size\":\"%s\",\"used\":\"%s\",\"avail\":\"%s\",\"use_pct\":%s,\"mount\":\"%s\"},\n", $1, $2, $3, $4, $5, $6}' | sed '$ s/,$//')
    ]
  },
  "network": {
    "interfaces": [
      $(ip -br addr show 2>/dev/null | awk '{printf "{\"name\":\"%s\",\"status\":\"%s\",\"addr\":\"%s\"},\n", $1, $2, $3}' | sed '$ s/,$//')
    ],
    "established_connections": $(ss -tn state established 2>/dev/null | wc -l),
    "listening_ports": $(ss -tln 2>/dev/null | tail -n +2 | wc -l)
  },
  "services": {
    "failed": $failed_services,
    "enabled": $(systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | wc -l)
  },
  "security": {
    "firewall": "$(systemctl is-active firewalld 2>/dev/null || echo 'N/A')",
    "selinux": "$(getenforce 2>/dev/null || echo 'N/A')",
    "pending_updates": $update_count
  }
}
JSONEOF

    echo ""
    log_ok "JSON отчёт сохранён: ${WHITE}${report_file}${NC}"
}

# ─── Парсинг аргументов ─────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                CHECK_TYPE="quick"
                shift
                ;;
            --full)
                CHECK_TYPE="full"
                shift
                ;;
            --cpu|--ram|--disk|--network|--services|--security|--temp|--boot|--users|--backups)
                CHECK_TYPE="${1#--}"
                shift
                ;;
            --report)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --help|-h)
                echo "Использование: $0 [OPTIONS]"
                echo ""
                echo "Опции:"
                echo "  --quick        Экспресс-проверка (30 секунд)"
                echo "  --full         Полная проверка"
                echo "  --cpu          Только CPU"
                echo "  --ram          Только RAM"
                echo "  --disk         Только диски"
                echo "  --network      Только сеть"
                echo "  --services     Только сервисы"
                echo "  --security     Только безопасность"
                echo "  --temp         Только температура"
                echo "  --report FMT   Формат отчёта: txt, html, json"
                echo "  --output DIR   Директория для отчёта"
                echo "  --quiet        Тихий режим"
                echo "  --help         Справка"
                exit 0
                ;;
            *)
                log_error "Неизвестная опция: $1"
                exit 1
                ;;
        esac
    done
}

# ─── Main ────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    check_root

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         DIAGNOSTICS SYSTEM HEALTH CHECK               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Хост:   ${WHITE}${HOSTNAME}${NC}"
    echo -e "  ОС:     ${WHITE}${OS_INFO}${NC}"
    echo -e "  Ядро:   ${WHITE}$(uname -r)${NC}"
    echo -e "  Дата:   ${WHITE}$(date '+%d.%m.%Y %H:%M:%S')${NC}"
    echo -e "  Uptime: ${WHITE}$(uptime -p 2>/dev/null || uptime)${NC}"

    case $CHECK_TYPE in
        quick)
            check_cpu
            check_ram
            check_disk
            check_services
            ;;
        full)
            check_cpu
            check_ram
            check_disk
            check_network
            check_services
            check_updates
            check_security
            check_temp
            check_boot
            check_users
            check_backups
            ;;
        cpu)     check_cpu ;;
        ram)     check_ram ;;
        disk)    check_disk ;;
        network) check_network ;;
        services) check_services ;;
        security) check_security ;;
        temp)    check_temp ;;
        boot)    check_boot ;;
        users)   check_users ;;
        backups) check_backups ;;
    esac

    # Генерация отчёта
    if [ "$REPORT_FORMAT" != "none" ]; then
        log_header "ГЕНЕРАЦИЯ ОТЧЁТА"
        case $REPORT_FORMAT in
            txt)  generate_txt_report ;;
            html) generate_html_report ;;
            json) generate_json_report ;;
            *)    log_error "Неизвестный формат: $REPORT_FORMAT (допустимы: txt, html, json)" ;;
        esac
    fi

    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Проверка завершена!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
    echo ""
}

main "$@"
