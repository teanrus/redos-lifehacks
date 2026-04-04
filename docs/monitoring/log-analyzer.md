# 📝 Анализ журналов systemd в РЕД ОС

> Полное руководство по работе с systemd journal (journalctl): фильтрация по времени, сервисам, приоритетам; анализ загрузок, проверка здоровья сервисов, генерация статистики и отчётов. Включает автоматический скрипт `log-analyzer.sh`.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

---

## Оглавление

1. [Основы journalctl](#-основы-journalctl)
2. [Фильтрация по времени](#-фильтрация-по-времени)
3. [Фильтрация по сервисам](#-фильтрация-по-сервисам)
4. [Фильтрация по приоритетам](#-фильтрация-по-приоритетам)
5. [Поиск ошибок и предупреждений](#-поиск-ошибок-и-предупреждений)
6. [Анализ загрузок](#-анализ-загрузок)
7. [Проверка здоровья сервисов](#-проверка-здоровья-сервисов)
8. [Статистика и отчёты](#-статистика-и-отчёты)
9. [Экспорт журналов](#-экспорт-журналов)
10. [Ротация и управление размером](#-ротация-и-управление-размером)
11. [Автоматический скрипт log-analyzer.sh](#-автоматический-скрипт-log-analyzersh)
12. [Мониторинг в реальном времени](#-мониторинг-в-реальном-времени)
13. [Таблица распространённых ошибок](#-таблица-распространённых-ошибок)
14. [Справочник команд](#-справочник-команд)
15. [Требования и совместимость](#-требования-и-совместимость)

---

## Основы journalctl

### Что такое systemd journal

systemd journal -- это централизованная система логирования, которая собирает сообщения от:
- Системных сервисов (systemd units)
- Ядра Linux (dmesg)
- Приложений, пишущих в syslog/stderr
- Аудита безопасности (auditd)

Журналы хранятся в бинарном формате в `/var/log/journal/` (постоянное хранение) или `/run/log/journal/` (временное).

### Включение постоянного хранения

```bash
# Проверить текущий статус
journalctl --disk-usage

# Создать директорию для постоянного хранения
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald

# Проверить
journalctl --disk-usage
```

### Базовые команды

```bash
# Все логи (с постраничным выводом)
journalctl

# Последние 50 записей
journalctl -n 50

# Без постраничного вывода
journalctl --no-pager

# Все логи с текущей загрузки
journalctl -b

# Логи ядра (аналог dmesg)
journalctl -k

# Логи конкретного процесса
journalctl _PID=1234

# По UID пользователя
journalctl _UID=1000
```

### Формат вывода

```bash
# Краткий формат (по умолчанию)
journalctl -o short

# Детальный формат
journalctl -o verbose

# JSON формат (для парсинга)
journalctl -o json | head -5

# JSON-pretty
journalctl -o json-pretty | head -30

# Формат cat (только сообщение)
journalctl -o cat

# Формат export (для передачи)
journalctl -o export
```

---

## Фильтрация по времени

### Абсолютное время

```bash
# С конкретного времени
journalctl --since "2024-01-15 10:00:00"

# До конкретного времени
journalctl --until "2024-01-15 12:00:00"

# Диапазон
journalctl --since "2024-01-15 10:00:00" --until "2024-01-15 12:00:00"

# Вчерашний день
journalctl --since yesterday --until today

# Конкретная дата
journalctl --since "2024-01-15" --until "2024-01-16"
```

### Относительное время

```bash
# За последний час
journalctl --since "1 hour ago"

# За последние 30 минут
journalctl --since "30 min ago"

# За последние 2 часа
journalctl --since "2 hours ago"

# За последний день
journalctl --since "1 day ago"

# За последнюю неделю
journalctl --since "7 days ago"

# За последние 15 минут (для отладки)
journalctl --since "15 min ago"
```

### Комбинирование с другими фильтрами

```bash
# Ошибки nginx за последний час
journalctl -u nginx --since "1 hour ago" -p err

# Все логи ядра за сегодня
journalctl -k --since today

# Логи SSH за конкретный период
journalctl -u sshd --since "2024-01-15 08:00" --until "2024-01-15 18:00"
```

### Практические примеры временных фильтров

| Сценарий | Команда |
|----------|---------|
| Что случилось утром? | `journalctl --since "08:00" --until "12:00"` |
| Проблемы после обновления | `journalctl --since "2 hours ago"` |
| Вчерашние ошибки | `journalctl --since yesterday --until today -p err` |
| Проблемы в выходные | `journalctl --since "Saturday" --until "Monday"` |
| Ночные события | `journalctl --since "00:00" --until "06:00"` |

---

## Фильтрация по сервисам

### По юниту (сервису)

```bash
# Все логи конкретного сервиса
journalctl -u nginx

# Логи нескольких сервисов
journalctl -u nginx -u php-fpm

# Исключить сервис
journalctl -u !NetworkManager

# Все юниты с определённым префиксом
journalctl -u "docker*"
```

### По типу юнита

```bash
# Только сервисы (service units)
journalctl _SYSTEMD_UNIT=sshd.service

# Только сокеты
journalctl _SYSTEMD_UNIT=sshd.socket

# По slice
journalctl _SYSTEMD_SLICE=system.slice
```

### Популярные сервисы и их логи

```bash
# SSH
journalctl -u sshd --since today

# Nginx
journalctl -u nginx --since today

# PostgreSQL
journalctl -u postgresql --since today

# NetworkManager
journalctl -u NetworkManager --since today

# DNF (обновления)
journalctl _COMM=dnf

# Cron
journalctl -u crond --since today

# Docker
journalctl -u docker --since today

# Firewall
journalctl -u firewalld --since today
```

### Поиск по исполняемому файлу

```bash
# Логи конкретного исполняемого файла
journalctl /usr/sbin/sshd

# По имени процесса
journalctl _COMM=sshd

# По полному пути
journalctl _EXE=/usr/sbin/sshd
```

---

## Фильтрация по приоритетам

### Уровни приоритета

| Приоритет | Уровень | Описание | Значение |
|-----------|---------|----------|----------|
| **emerg** | 0 | Система неработоспособна | Критично |
| **alert** | 1 | Немедленные действия | Критично |
| **crit** | 2 | Критические условия | Критично |
| **err** | 3 | Ошибки | Важно |
| **warning** | 4 | Предупреждения | Внимание |
| **notice** | 5 | Нормальные, но значимые | Информация |
| **info** | 6 | Информационные | Информация |
| **debug** | 7 | Отладочные | Отладка |

### Фильтрация

```bash
# Только ошибки и выше (err, crit, alert, emerg)
journalctl -p err

# Только критические (crit, alert, emerg)
journalctl -p crit

# Только предупреждения и выше
journalctl -p warning

# Конкретный уровень
journalctl -p err --since "1 hour ago"

# Только info
journalctl -p info..info
```

### Практические примеры

```bash
# Все ошибки за сегодня
journalctl -p err --since today

# Критические ошибки за неделю
journalctl -p crit --since "7 days ago"

# Ошибки конкретного сервиса
journalctl -u nginx -p err --since today

# Emergency сообщения
journalctl -p emerg
```

---

## Поиск ошибок и предупреждений

### Быстрый поиск

```bash
# Все ошибки
journalctl -p err --no-pager

# Ошибки за последний час
journalctl -p err --since "1 hour ago"

# Поиск по ключевому слову
journalctl | grep -i "error"

# Поиск нескольких паттернов
journalctl | grep -iE "error|fail|critical"

# Исключить шумные сообщения
journalctl | grep -i "error" | grep -v "rate limit"
```

### Расширенный поиск с grep

```bash
# OOM Killer события
journalctl | grep -i "out of memory"

# Segmentation fault
journalctl | grep -i "segfault"

# Disk errors
journalctl | grep -iE "I/O error|disk error|ATA error"

# Network errors
journalctl | grep -iE "link down|carrier lost|dhcp"

# Authentication failures
journalctl | grep -iE "authentication failure|failed password|invalid user"

# Service crashes
journalctl | grep -iE "core dump|crashed|killed"

# Permission denied
journalctl | grep -i "permission denied"
```

### Поиск с контекстом

```bash
# 10 строк до и после ошибки
journalctl | grep -B 10 -A 10 -i "error"

# Только строки после ошибки
journalctl | grep -A 20 -i "fatal"

# Подсчёт ошибок по типу
journalctl --since today | grep -oiE "error [^:]+:" | sort | uniq -c | sort -rn
```

### Поиск failed процессов

```bash
# Все failed процессы
journalctl | grep -E "Failed to|failed at"

# Failed старт сервисов
journalctl | grep "Failed to start"

# Timeout при запуске
journalctl | grep "timed out"

# Dependency failures
journalctl | grep "dependency"
```

---

## Анализ загрузок

### Список загрузок

```bash
# Все записи о загрузках
journalctl --list-boots

# Форматированный вывод
journalctl --list-boots | awk '{printf "Boot: %+4s  ID: %-32s  Начало: %s %s  Конец: %s %s\n", $1, $2, $3, $4, $6, $7}'
```

### Логи конкретной загрузки

```bash
# Текущая загрузка
journalctl -b 0

# Предыдущая загрузка
journalctl -b -1

# Две загрузки назад
journalctl -b -2

# По boot ID
journalctl -b abc123def456
```

### Анализ проблем при загрузке

```bash
# Ошибки при загрузке
journalctl -b -p err

# Медленные сервисы
systemd-analyze blame

# Критическая цепь
systemd-analyze critical-chain

# Ошибки ядра при загрузке
journalctl -b -k | grep -iE "error|fail|warn"

# Failed сервисы при загрузке
journalctl -b | grep "Failed to start"

# Время загрузки ядра
journalctl -b -k | head -5
```

### Сравнение загрузок

```bash
# Время текущей загрузки
systemd-analyze

# Сравнение с предыдущей (если данные доступны)
echo "=== Текущая загрузка ==="
systemd-analyze blame | head -5
echo ""
echo "=== Предыдущая загрузка (ошибки) ==="
journalctl -b -1 -p err | head -20
```

---

## Проверка здоровья сервисов

### Базовая проверка

```bash
# Статус + последние логи
systemctl status nginx

# Полные логи сервиса за сегодня
journalctl -u nginx --since today

# Только ошибки сервиса
journalctl -u nginx -p err --since today

# Частота перезапусков
journalctl -u nginx | grep -c "Started\|Stopping\|Starting"
```

### Полная проверка сервиса

```bash
check_service_health() {
    local service=$1
    echo "════════════════════════════════════════"
    echo "  Проверка сервиса: $service"
    echo "════════════════════════════════════════"

    # Статус
    echo ""
    echo "📊 Статус:"
    systemctl is-active "$service" 2>/dev/null || echo "  Не найден"
    systemctl is-enabled "$service" 2>/dev/null || echo "  Не включен"

    # Uptime
    echo ""
    echo "⏱️  Время работы:"
    systemctl show "$service" --property=ActiveEnterTimestamp 2>/dev/null

    # Перезапуски за сегодня
    echo ""
    echo "🔄 Перезапуски (сегодня):"
    local restarts
    restarts=$(journalctl -u "$service" --since today 2>/dev/null | grep -c "Started\|Stopping" || echo 0)
    echo "  Перезапусков: $restarts"

    # Ошибки за сегодня
    echo ""
    echo "❌ Ошибки (сегодня):"
    local errors
    errors=$(journalctl -u "$service" -p err --since today 2>/dev/null | wc -l)
    echo "  Ошибок: $errors"

    if [ "$errors" -gt 0 ]; then
        echo ""
        echo "Последние 5 ошибок:"
        journalctl -u "$service" -p err --since today 2>/dev/null | tail -5
    fi

    # Предупреждения
    echo ""
    echo "⚠️  Предупреждения (сегодня):"
    local warns
    warns=$(journalctl -u "$service" -p warning --since today 2>/dev/null | wc -l)
    echo "  Предупреждений: $warns"
}

# Использование
check_service_health nginx
check_service_health sshd
check_service_health postgresql
```

### Мониторинг рестартов

```bash
# Сервисы которые часто перезапускаются
for unit in $(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}'); do
    count=$(journalctl -u "$unit" --since "1 hour ago" 2>/dev/null | grep -c "Started\|Restarting" || echo 0)
    if [ "$count" -gt 2 ]; then
        echo "$unit: $count рестартов за час"
    fi
done

# Crash loop обнаружение
journalctl --since "1 hour ago" | grep -E "start request repeated too quickly|Failed with result" | head -10
```

---

## Статистика и отчёты

### Общая статистика

```bash
# Объём журналов
journalctl --disk-usage

# Количество записей
journalctl --no-pager | wc -l

# Записей за сегодня
journalctl --since today --no-pager | wc -l

# Записей за последний час
journalctl --since "1 hour ago" --no-pager | wc -l
```

### Статистика по источникам

```bash
# Топ-10 сервисов по количеству записей
journalctl --since today --no-pager | \
    grep -oP '_SYSTEMD_UNIT=\K[^ ]+' 2>/dev/null | \
    sort | uniq -c | sort -rn | head -10

# Топ-10 процессов по записям
journalctl --since today --no-pager | \
    awk '/^[A-Z]/ {print $5}' | \
    sort | uniq -c | sort -rn | head -10

# Распределение по приоритетам
echo "Распределение по приоритетам (сегодня):"
for level in emerg alert crit err warning notice info debug; do
    count=$(journalctl -p "$level" --since today --no-pager 2>/dev/null | wc -l)
    printf "  %-10s %d\n" "$level" "$count"
done
```

### Отчёт о событиях за день

```bash
generate_daily_report() {
    local date_str=${1:-$(date +%Y-%m-%d)}

    echo "╔══════════════════════════════════════════════╗"
    echo "║     ДНЕВНОЙ ОТЧЁТ: $date_str               ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    echo "📊 Общая статистика:"
    local total
    total=$(journalctl --since "$date_str" --until "$date_str 23:59:59" --no-pager 2>/dev/null | wc -l)
    echo "  Всего записей: $total"

    echo ""
    echo "❌ Ошибки:"
    local errors
    errors=$(journalctl -p err --since "$date_str" --until "$date_str 23:59:59" --no-pager 2>/dev/null | wc -l)
    echo "  Ошибок: $errors"

    echo ""
    echo "🔒 Аутентификация:"
    local auth_fail
    auth_fail=$(journalctl --since "$date_str" --until "$date_str 23:59:59" 2>/dev/null | grep -c "Failed password\|authentication failure" || echo 0)
    echo "  Неудачных попыток: $auth_fail"

    echo ""
    echo "🔄 Перезапуски сервисов:"
    journalctl --since "$date_str" --until "$date_str 23:59:59" 2>/dev/null | \
        grep "Started\|Stopping" | \
        grep -oP '\S+\.service' | \
        sort | uniq -c | sort -rn | head -10

    echo ""
    echo "💾 Дисковые события:"
    journalctl -p err --since "$date_str" --until "$date_str 23:59:59" 2>/dev/null | \
        grep -iE "disk|I/O|storage|ext4|xfs" | head -5
}

# Запуск
generate_daily_report
generate_daily_report "2024-01-15"
```

---

## Экспорт журналов

### Экспорт в файл

```bash
# В текстовый файл
journalctl --since today > /tmp/journal-today.txt

# В сжатый файл
journalctl --since today | gzip > /tmp/journal-today.txt.gz

# Конкретный сервис
journalctl -u nginx --since today > /tmp/nginx-today.log

# Только ошибки
journalctl -p err --since "7 days ago" > /tmp/errors-week.log
```

### Экспорт в JSON

```bash
# JSON для парсинга
journalctl --since today -o json > /tmp/journal-today.json

# JSON-pretty для чтения
journalctl --since today -o json-pretty > /tmp/journal-today-pretty.json

# JSON с jq фильтрацией
journalctl -o json --since "1 hour ago" | jq 'select(.PRIORITY == "3")' > /tmp/errors.json

# JSON статистика
journalctl -o json --since today | jq -r '._SYSTEMD_UNIT // empty' | sort | uniq -c | sort -rn | head -10
```

### Сжатие и архивирование

```bash
# Сжатие журналов за период
journalctl --since "2024-01-01" --until "2024-01-31" | gzip > /var/log/archive/journal-jan-2024.gz

# Проверка сжатого файла
zcat /var/log/archive/journal-jan-2024.gz | head -20

# Поиск в сжатом архиве
zgrep -i "error" /var/log/archive/journal-jan-2024.gz | head -10

# Архивация всех журналов
sudo tar czf /tmp/journal-backup-$(date +%Y%m%d).tar.gz /var/log/journal/
```

### Экспорт на удалённый сервер

```bash
# Отправка на syslog-сервер
# Настроить /etc/systemd/journald.conf:
# ForwardToSyslog=yes
# ForwardToWall=no

# Экспорт и отправка по SSH
journalctl --since today | ssh user@logserver "cat > /var/log/remote/$(hostname)-$(date +%Y%m%d).log"

# Отправка через rsyslog
# Настроить /etc/rsyslog.conf:
# *.* @@logserver:514
```

---

## Ротация и управление размером

### Проверка текущего размера

```bash
# Общий размер журналов
journalctl --disk-usage

# Детальный размер
sudo du -sh /var/log/journal/

# По поддиректориям
sudo du -sh /var/log/journal/*/
```

### Настройка journald.conf

```bash
# Открыть конфигурацию
sudo nano /etc/systemd/journald.conf

# Рекомендуемые настройки
# [Journal]
# Storage=persistent           # persistent | volatile | auto | none
# SystemMaxUse=500M            # Максимальный размер всех журналов
# SystemKeepFree=1G            # Мин. свободного места
# SystemMaxFileSize=50M        # Максимальный размер одного файла
# MaxRetentionSec=1month       # Максимальное хранение
# MaxFileSec=1day              # Ротация по времени
# ForwardToSyslog=no           # Дублирование в syslog
# Compress=yes                 # Сжатие (по умолчанию: yes)
# Seal=yes                     # FSS шифрование
```

### Очистка журналов

```bash
# Ограничить по размеру (оставить 100М)
sudo journalctl --vacuum-size=100M

# Ограничить по времени (оставить 2 дня)
sudo journalctl --vacuum-time=2d

# Оставить только 5 файлов
sudo journalctl --vacuum-files=5

# Очистить всё (не рекомендуется!)
sudo journalctl --rotate
sudo journalctl --vacuum-size=1M
```

### Автоматическая ротация

```bash
# Создать скрипт ротации
sudo tee /etc/cron.daily/journal-vacuum << 'EOF'
#!/bin/bash
# Ежедневная ротация журналов
/usr/bin/journalctl --vacuum-size=200M
/usr/bin/journalctl --vacuum-time=7d
EOF

sudo chmod +x /etc/cron.daily/journal-vacuum
```

### Мониторинг размера

```bash
# Проверка размера с предупреждением
check_journal_size() {
    local size_mb
    size_mb=$(journalctl --disk-usage | awk '{print $NF}' | sed 's/M//')

    if [ "$size_mb" -gt 1000 ]; then
        echo "⚠️  Размер журналов: ${size_mb}МБ (превышает 1ГБ!)"
    elif [ "$size_mb" -gt 500 ]; then
        echo "⚠️  Размер журналов: ${size_mb}МБ"
    else
        echo "✅  Размер журналов: ${size_mb}МБ"
    fi
}

check_journal_size
```

---

## Автоматический скрипт log-analyzer.sh

Полный автоматический скрипт анализа журналов с цветным выводом:

```bash
#!/bin/bash
##############################################################################
# log-analyzer.sh -- Анализ журналов systemd journal (РЕД ОС)
#
# Использование:
#   ./log-analyzer.sh [OPTIONS]
#
# Опции:
#   --today          Логи за сегодня (по умолчанию)
#   --since TIME     Логи с указанного времени (например: "1 hour ago")
#   --since DATE     Логи с даты (например: "2024-01-15")
#   --boot N         Логи загрузки N (0 = текущая, -1 = предыдущая)
#   --unit SERVICE   Логи конкретного сервиса
#   --priority LVL   Минимальный приоритет (emerg..debug)
#   --errors         Только ошибки (эквивалент --priority err)
#   --stats          Статистика журналов
#   --report FMT     Формат отчёта: txt, json
#   --output DIR     Директория для отчёта
#   --follow         Режим реального времени
#   --quick          Быстрая проверка (ошибки за 1 час)
#   --full           Полный анализ
#   --help           Справка
#
# Зависимости: bash, systemd (journalctl), coreutils
# Опционально: jq, gzip
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

# ─── Настройки по умолчанию ──────────────────────────────────────────────
SINCE_FLAG="--since today"
BOOT_FLAG=""
UNIT_FILTER=""
PRIORITY_FILTER=""
REPORT_FORMAT="none"
OUTPUT_DIR="./reports"
FOLLOW_MODE=false
QUICK_MODE=false
FULL_MODE=false
SHOW_STATS=false

# ─── Функции ─────────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}      $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1"; }
log_header()  {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
}

# ─── Парсинг аргументов ─────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --today)
                SINCE_FLAG="--since today"
                shift
                ;;
            --since)
                if [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    SINCE_FLAG="--since \"$2\" --until \"$2 23:59:59\""
                else
                    SINCE_FLAG="--since \"$2\""
                fi
                shift 2
                ;;
            --boot)
                BOOT_FLAG="-b $2"
                SINCE_FLAG=""
                shift 2
                ;;
            --unit|-u)
                UNIT_FILTER="-u $2"
                shift 2
                ;;
            --priority|-p)
                PRIORITY_FILTER="-p $2"
                shift 2
                ;;
            --errors|-e)
                PRIORITY_FILTER="-p err"
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
            --follow|-f)
                FOLLOW_MODE=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                SINCE_FLAG="--since \"1 hour ago\""
                PRIORITY_FILTER="-p err"
                shift
                ;;
            --full)
                FULL_MODE=true
                shift
                ;;
            --stats)
                SHOW_STATS=true
                shift
                ;;
            --help|-h)
                echo "Использование: $0 [OPTIONS]"
                echo ""
                echo "Опции:"
                echo "  --today          Логи за сегодня"
                echo "  --since TIME     Логи с указанного времени"
                echo "  --since DATE     Логи с даты (YYYY-MM-DD)"
                echo "  --boot N         Логи загрузки N"
                echo "  --unit SERVICE   Логи сервиса"
                echo "  --priority LVL   Минимальный приоритет"
                echo "  --errors         Только ошибки"
                echo "  --report FMT     Формат: txt, json"
                echo "  --output DIR     Директория отчёта"
                echo "  --follow         Реальное время"
                echo "  --quick          Быстрая проверка"
                echo "  --full           Полный анализ"
                echo "  --stats          Статистика"
                echo "  --help           Справка"
                exit 0
                ;;
            *)
                log_error "Неизвестная опция: $1"
                exit 1
                ;;
        esac
    done
}

# ─── Функции анализа ─────────────────────────────────────────────────────

show_stats() {
    log_header "СТАТИСТИКА ЖУРНАЛОВ"

    # Размер
    local disk_usage
    disk_usage=$(journalctl --disk-usage 2>/dev/null)
    echo -e "  Размер журналов: ${WHITE}${disk_usage}${NC}"

    # Общее количество записей
    local total_count
    total_count=$(eval journalctl $SINCE_FLAG $BOOT_FLAG $UNIT_FILTER --no-pager 2>/dev/null | wc -l)
    echo -e "  Записей:         ${WHITE}${total_count}${NC}"

    # По приоритетам
    echo ""
    echo -e "  ${WHITE}Распределение по приоритетам:${NC}"
    for level in emerg alert crit err warning notice info debug; do
        local count
        count=$(eval journalctl $SINCE_FLAG $BOOT_FLAG $UNIT_FILTER -p "$level" --no-pager 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            printf "    %-10s %d\n" "$level" "$count"
        fi
    done

    # По сервисам
    echo ""
    echo -e "  ${WHITE}Топ-10 сервисов по записям:${NC}"
    eval journalctl $SINCE_FLAG $BOOT_FILTER --no-pager 2>/dev/null | \
        grep -oP '_SYSTEMD_UNIT=\K\S+\.service' 2>/dev/null | \
        sort | uniq -c | sort -rn | head -10 | while read -r count unit; do
            printf "    %5d  %s\n" "$count" "$unit"
        done

    # По процессам
    echo ""
    echo -e "  ${WHITE}Топ-10 процессов по записям:${NC}"
    eval journalctl $SINCE_FLAG $BOOT_FLAG --no-pager 2>/dev/null | \
        awk '/^[A-Z]/ {print $5}' | \
        sort | uniq -c | sort -rn | head -10 | while read -r count proc; do
            printf "    %5d  %s\n" "$count" "$proc"
        done
}

show_errors() {
    log_header "ОШИБКИ"

    local error_cmd="journalctl $SINCE_FLAG $BOOT_FLAG $UNIT_FILTER -p err --no-pager"
    local error_count
    error_count=$(eval $error_cmd 2>/dev/null | wc -l)

    echo -e "  Найдено ошибок: ${WHITE}${error_count}${NC}"

    if [ "$error_count" -gt 0 ]; then
        echo ""
        eval $error_cmd 2>/dev/null | head -50
        if [ "$error_count" -gt 50 ]; then
            echo ""
            echo -e "  ... и ещё $((error_count - 50)) записей"
        fi
    else
        log_ok "Ошибок не обнаружено"
    fi
}

show_warnings() {
    log_header "ПРЕДУПРЕЖДЕНИЯ"

    local warn_cmd="journalctl $SINCE_FLAG $BOOT_FLAG $UNIT_FILTER -p warning --no-pager"
    local warn_count
    warn_count=$(eval $warn_cmd 2>/dev/null | wc -l)

    echo -e "  Найдено предупреждений: ${WHITE}${warn_count}${NC}"

    if [ "$warn_count" -gt 0 ]; then
        echo ""
        eval $warn_cmd 2>/dev/null | head -30
        if [ "$warn_count" -gt 30 ]; then
            echo ""
            echo -e "  ... и ещё $((warn_count - 30)) записей"
        fi
    else
        log_ok "Предупреждений не обнаружено"
    fi
}

show_auth() {
    log_header "АУТЕНТИФИКАЦИЯ И БЕЗОПАСНОСТЬ"

    local auth_cmd="journalctl $SINCE_FLAG --no-pager"

    # Failed logins
    local failed_logins
    failed_logins=$(eval $auth_cmd 2>/dev/null | grep -c "Failed password\|authentication failure" || echo 0)
    echo -e "  Неудачных попыток входа: ${WHITE}${failed_logins}${NC}"

    if [ "$failed_logins" -gt 0 ]; then
        echo ""
        echo -e "  ${WHITE}Последние неудачные попытки:${NC}"
        eval $auth_cmd 2>/dev/null | grep "Failed password\|authentication failure" | tail -10
    fi

    # Successful SSH logins
    echo ""
    local ssh_logins
    ssh_logins=$(eval $auth_cmd 2>/dev/null | grep -c "Accepted publickey\|Accepted password" || echo 0)
    echo -e "  Успешных SSH входов: ${WHITE}${ssh_logins}${NC}"

    if [ "$ssh_logins" -gt 0 ]; then
        echo ""
        echo -e "  ${WHITE}Последние успешные входы:${NC}"
        eval $auth_cmd 2>/dev/null | grep "Accepted" | tail -5
    fi

    # Sudo usage
    echo ""
    local sudo_count
    sudo_count=$(eval $auth_cmd 2>/dev/null | grep -c "sudo:" || echo 0)
    echo -e "  Sudo операций: ${WHITE}${sudo_count}${NC}"
}

show_service_health() {
    log_header "ЗДОРОВЬЕ СЕРВИСОВ"

    # Failed сервисы
    local failed
    failed=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    echo -e "  Failed сервисов: ${WHITE}${failed}${NC}"

    if [ "$failed" -gt 0 ]; then
        echo ""
        echo -e "  ${WHITE}Failed сервисы и их логи:${NC}"
        systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' | while read -r unit; do
            echo ""
            echo -e "  ${YELLOW}─── $unit ───${NC}"
            journalctl -u "$unit" --since "1 hour ago" -p err --no-pager 2>/dev/null | tail -5
        done
    else
        log_ok "Все сервисы работают"
    fi

    # Crash loops
    echo ""
    echo -e "  ${WHITE}Поиск crash loop (за последний час):${NC}"
    local crash_loops
    crash_loops=$(journalctl --since "1 hour ago" --no-pager 2>/dev/null | grep -c "start request repeated too quickly\|Failed with result" || echo 0)
    echo -e "  Crash loop событий: ${WHITE}${crash_loops}${NC}"

    if [ "$crash_loops" -gt 0 ]; then
        echo ""
        journalctl --since "1 hour ago" --no-pager 2>/dev/null | \
            grep "start request repeated too quickly\|Failed with result" | tail -10
    fi

    # Частые рестарты
    echo ""
    echo -e "  ${WHITE}Сервисы с частыми рестартами (за 1 час):${NC}"
    for unit in $(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | awk '{print $1}'); do
        local restarts
        restarts=$(journalctl -u "$unit" --since "1 hour ago" 2>/dev/null | grep -c "Started\|Restarting" || echo 0)
        if [ "$restarts" -gt 2 ]; then
            echo -e "    ${YELLOW}${unit}: ${restarts} рестартов${NC}"
        fi
    done
}

show_kernel() {
    log_header "ЯДРО (dmesg)"

    local kern_cmd="journalctl -k $SINCE_FLAG --no-pager"

    # Ошибки ядра
    local kern_errors
    kern_errors=$(eval $kern_cmd 2>/dev/null | grep -ci "error\|fail\|bug" || echo 0)
    echo -e "  Ошибок ядра: ${WHITE}${kern_errors}${NC}"

    if [ "$kern_errors" -gt 0 ]; then
        echo ""
        echo -e "  ${WHITE}Последние ошибки ядра:${NC}"
        eval $kern_cmd 2>/dev/null | grep -iE "error|fail|bug" | tail -10
    fi

    # OOM Killer
    echo ""
    local oom_count
    oom_count=$(eval $kern_cmd 2>/dev/null | grep -ic "out of memory\|oom-killer" || echo 0)
    echo -e "  OOM Killer срабатываний: ${WHITE}${oom_count}${NC}"

    if [ "$oom_count" -gt 0 ]; then
        echo ""
        eval $kern_cmd 2>/dev/null | grep -iE "out of memory|oom-killer" | tail -5
    fi

    # Disk errors
    echo ""
    local disk_errors
    disk_errors=$(eval $kern_cmd 2>/dev/null | grep -ic "I/O error\|ata.*error\|blk_update_request" || echo 0)
    echo -e "  Ошибок дисков: ${WHITE}${disk_errors}${NC}"

    if [ "$disk_errors" -gt 0 ]; then
        echo ""
        eval $kern_cmd 2>/dev/null | grep -iE "I/O error|ata.*error|blk_update_request" | tail -5
    fi
}

show_custom_logs() {
    log_header "ЖУРНАЛЫ"

    local log_cmd="journalctl $SINCE_FLAG $BOOT_FLAG $UNIT_FILTER $PRIORITY_FILTER --no-pager"

    local total
    total=$(eval $log_cmd 2>/dev/null | wc -l)
    echo -e "  Всего записей: ${WHITE}${total}${NC}"

    if [ "$total" -gt 0 ]; then
        echo ""
        eval $log_cmd 2>/dev/null | tail -100
        if [ "$total" -gt 100 ]; then
            echo ""
            echo -e "  ... (показаны последние 100 из $total записей)"
        fi
    fi
}

# ─── Генерация отчётов ──────────────────────────────────────────────────

generate_txt_report() {
    local report_file="${OUTPUT_DIR}/log-analysis-$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p "$OUTPUT_DIR"

    {
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║         ОТЧЁТ АНАЛИЗА ЖУРНАЛОВ                         ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "Хост:     $(hostname)"
        echo "Дата:     $(date)"
        echo "Период:   ${SINCE_FLAG:-all}"
        echo ""

        echo "══════════════════════════════════════════════════════════"
        echo "СТАТИСТИКА"
        echo "══════════════════════════════════════════════════════════"
        journalctl --disk-usage 2>/dev/null
        echo ""

        echo "══════════════════════════════════════════════════════════"
        echo "ОШИБКИ"
        echo "══════════════════════════════════════════════════════════"
        eval journalctl $SINCE_FLAG $BOOT_FLAG $UNIT_FILTER -p err --no-pager 2>/dev/null | head -100
        echo ""

        echo "══════════════════════════════════════════════════════════"
        echo "АУТЕНТИФИКАЦИЯ"
        echo "══════════════════════════════════════════════════════════"
        eval journalctl $SINCE_FLAG --no-pager 2>/dev/null | grep "Failed password\|Accepted\|sudo:" | tail -50
        echo ""

        echo "══════════════════════════════════════════════════════════"
        echo "FAILED СЕРВИСЫ"
        echo "══════════════════════════════════════════════════════════"
        systemctl --failed --no-pager 2>/dev/null
    } > "$report_file"

    echo ""
    echo -e "${GREEN}[OK]${NC} TXT отчёт: ${WHITE}${report_file}${NC}"
}

generate_json_report() {
    local report_file="${OUTPUT_DIR}/log-analysis-$(date +%Y%m%d_%H%M%S).json"
    mkdir -p "$OUTPUT_DIR"

    local total_errors
    total_errors=$(eval journalctl $SINCE_FLAG $BOOT_FLAG -p err --no-pager 2>/dev/null | wc -l)
    local total_warnings
    total_warnings=$(eval journalctl $SINCE_FLAG $BOOT_FLAG -p warning --no-pager 2>/dev/null | wc -l)
    local total_auth_fail
    total_auth_fail=$(eval journalctl $SINCE_FLAG --no-pager 2>/dev/null | grep -c "Failed password\|authentication failure" || echo 0)

    cat > "$report_file" << JSONEOF
{
  "report": {
    "hostname": "$(hostname)",
    "timestamp": "$(date -Iseconds)",
    "period": "${SINCE_FLAG:-all}"
  },
  "statistics": {
    "journal_size": "$(journalctl --disk-usage 2>/dev/null | awk '{print $2 $3}')",
    "total_entries": $(eval journalctl $SINCE_FLAG $BOOT_FLAG --no-pager 2>/dev/null | wc -l),
    "errors": $total_errors,
    "warnings": $total_warnings,
    "auth_failures": $total_auth_fail
  },
  "failed_services": [
    $(systemctl --failed --no-legend 2>/dev/null | awk '{printf "{\"unit\":\"%s\",\"description\":\"%s\"},\n", $1, substr($0, index($0,$2))}' | sed '$ s/,$//')
  ],
  "top_services_by_errors": [
    $(journalctl $SINCE_FLAG -p err -o json 2>/dev/null | jq -r '._SYSTEMD_UNIT // empty' 2>/dev/null | sort | uniq -c | sort -rn | head -10 | awk '{printf "{\"unit\":\"%s\",\"errors\":%d},\n", $2, $1}' | sed '$ s/,$//')
  ]
}
JSONEOF

    echo ""
    echo -e "${GREEN}[OK]${NC} JSON отчёт: ${WHITE}${report_file}${NC}"
}

# ─── Режим реального времени ─────────────────────────────────────────────

follow_mode() {
    log_header "МОНИТОРИНГ В РЕАЛЬНОМ ВРЕМЕНИ"
    echo -e "  ${YELLOW}Нажмите Ctrl+C для остановки${NC}"
    echo ""

    if [ -n "$UNIT_FILTER" ]; then
        journalctl $UNIT_FILTER -f
    elif [ -n "$PRIORITY_FILTER" ]; then
        journalctl $PRIORITY_FILTER -f
    else
        journalctl -f
    fi
}

# ─── Quick mode ──────────────────────────────────────────────────────────

quick_check() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         БЫСТРАЯ ПРОВЕРКА ЖУРНАЛОВ                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Ошибки за последний час
    local errors_1h
    errors_1h=$(journalctl --since "1 hour ago" -p err --no-pager 2>/dev/null | wc -l)
    echo -e "  ❌ Ошибки (1 час):  ${WHITE}${errors_1h}${NC}"

    # Failed сервисы
    local failed
    failed=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    echo -e "  ❌ Failed сервисы:  ${WHITE}${failed}${NC}"

    # OOM
    local oom
    oom=$(journalctl --since "1 hour ago" -k 2>/dev/null | grep -ic "oom\|out of memory" || echo 0)
    echo -e "  💀 OOM (1 час):     ${WHITE}${oom}${NC}"

    # Auth failures
    local auth_fail
    auth_fail=$(journalctl --since "1 hour ago" 2>/dev/null | grep -c "Failed password" || echo 0)
    echo -e "  🔐 Failed login:    ${WHITE}${auth_fail}${NC}"

    echo ""
    if [ "$errors_1h" -eq 0 ] && [ "$failed" -eq 0 ] && [ "$oom" -eq 0 ]; then
        log_ok "Критических проблем не обнаружено"
    else
        log_warn "Обнаружены проблемы -- запустите --full для детального анализа"
    fi
}

# ─── Full mode ───────────────────────────────────────────────────────────

full_analysis() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         ПОЛНЫЙ АНАЛИЗ ЖУРНАЛОВ                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Хост:   ${WHITE}$(hostname)${NC}"
    echo -e "  Дата:   ${WHITE}$(date '+%d.%m.%Y %H:%M:%S')${NC}"
    echo -e "  Период: ${WHITE}${SINCE_FLAG:-все}${NC}"

    show_stats
    show_errors
    show_warnings
    show_auth
    show_service_health
    show_kernel
    show_custom_logs
}

# ─── Main ────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    if [ "$FOLLOW_MODE" = true ]; then
        follow_mode
    elif [ "$QUICK_MODE" = true ]; then
        quick_check
    elif [ "$FULL_MODE" = true ] || [ "$SHOW_STATS" = true ]; then
        if [ "$FULL_MODE" = true ]; then
            full_analysis
        fi
        if [ "$SHOW_STATS" = true ]; then
            show_stats
        fi
    elif [ -n "$PRIORITY_FILTER" ] || [ -n "$UNIT_FILTER" ] || [ -n "$BOOT_FLAG" ]; then
        show_custom_logs
    else
        # По умолчанию: показать ошибки за сегодня
        show_errors
    fi

    # Генерация отчёта
    if [ "$REPORT_FORMAT" != "none" ]; then
        log_header "ГЕНЕРАЦИЯ ОТЧЁТА"
        case $REPORT_FORMAT in
            txt)  generate_txt_report ;;
            json) generate_json_report ;;
            *)    log_error "Неизвестный формат: $REPORT_FORMAT (txt, json)" ;;
        esac
    fi
}

main "$@"
```

---

## Мониторинг в реальном времени

### Базовый мониторинг

```bash
# Все новые записи в реальном времени
journalctl -f

# Только ошибки в реальном времени
journalctl -f -p err

# Конкретный сервис в реальном времени
journalctl -u nginx -f

# Несколько сервисов
journalctl -u nginx -u php-fpm -f

# Только ядро
journalctl -k -f
```

### Мониторинг с фильтрацией

```bash
# Только определённые сообщения
journalctl -f | grep -i --line-buffered "error"

# Исключить шумные сообщения
journalctl -f | grep -v --line-buffered "rate limit"

# Несколько паттернов
journalctl -f | grep -iE --line-buffered "error|fail|critical|panic"
```

### Мониторинг с уведомлением

```bash
# Уведомление при ошибке
journalctl -f -p err | while read -r line; do
    notify-send "System Error" "$line" 2>/dev/null
    echo "$(date): $line" >> /var/log/error-alerts.log
done

# Отправка на email
journalctl -f -p err | while read -r line; do
    echo "$line" | mail -s "ERROR on $(hostname)" admin@example.com
done
```

### tmux панель мониторинга

```bash
# Создать сессию
tmux new-session -d -s logs
tmux split-window -v
tmux split-window -v
tmux select-pane -t 0

# Панели мониторинга
tmux send-keys -t 0 'journalctl -f -p err' Enter
tmux send-keys -t 1 'journalctl -u nginx -f' Enter
tmux send-keys -t 2 'journalctl -f | grep -i --line-buffered "fail\|error\|critical"' Enter

# Подключиться
tmux attach -t logs
```

---

## Таблица распространённых ошибок

### Системные ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| **Failed to start...** | Сервис не может запуститься | `journalctl -u service -p err`, проверить конфиг |
| **start request repeated too quickly** | Crash loop, сервис падает | Исправить причину падения, `systemctl reset-failed` |
| **Job timed out** | Сервис не отвечает в течение TimeoutStartSec | Увеличить таймаут: `systemctl edit service`, `TimeoutStartSec=120` |
| **Dependency failed** | Зависимый сервис не работает | Проверить зависимости: `systemctl list-dependencies` |
| **Cannot assign requested address** | Порт уже занят | `ss -tlnp \| grep PORT`, остановить конфликтующий сервис |

### Ошибки памяти

| Ошибка | Причина | Решение |
|--------|---------|---------|
| **Out of memory** | Нехватка RAM | Добавить RAM, ограничить процессы, cgroups |
| **Cannot allocate memory** | Нехватка памяти для процесса | Увеличить RAM, закрыть лишние процессы |
| **segfault at...** | Сегфолт в приложении | Обновить приложение, сообщить разработчикам |

### Ошибки дисков

| Ошибка | Причина | Решение |
|--------|---------|---------|
| **I/O error** | Проблема с диском/кабелем | Проверить SMART, заменить кабель/диск |
| **EXT4-fs error** | Повреждение файловой системы | `fsck` на размонтированном разделе |
| **No space left on device** | Диск заполнен | `df -h`, `du -sh /*`, очистить место |
| **Read-only file system** | Файловая система повреждена | `dmesg`, `fsck`, проверить диск |

### Сетевые ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| **Network is unreachable** | Нет маршрута | `ip route`, проверить шлюз |
| **Connection refused** | Сервис не слушает порт | `ss -tlnp`, запустить сервис |
| **Connection timed out** | Хост/файрвол блокирует | Проверить firewall, маршрут |
| **DNS resolution failed** | DNS не работает | `dig`, проверить `/etc/resolv.conf` |
| **link is not ready** | Интерфейс не поднят | `ip link set dev eth0 up` |

### Ошибки аутентификации

| Ошибка | Причина | Решение |
|--------|---------|---------|
| **Failed password for...** | Неверный пароль | Проверить учётные данные |
| **Invalid user...** | Несуществующий пользователь | Проверить username, возможно атака |
| **Authentication failure** | Ошибка аутентификации | Проверить PAM, тени |
| **Maximum login attempts** | Превышены попытки | Подождать, проверить fail2ban |

### SELinux ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| **AVC denied** | SELinux блокирует доступ | `ausearch -m avc`, `audit2allow` |
| **Permission denied** (при верных правах) | SELinux context | `ls -Z`, `restorecon`, `semanage` |

---

## Справочник команд

### Основные команды journalctl

| Команда | Описание |
|---------|----------|
| `journalctl` | Все логи с постраничным выводом |
| `journalctl -n 50` | Последние 50 записей |
| `journalctl -f` | Реальное время (tail -f) |
| `journalctl -b` | Логи текущей загрузки |
| `journalctl -b -1` | Логи предыдущей загрузки |
| `journalctl -k` | Логи ядра (dmesg) |
| `journalctl --disk-usage` | Размер журналов |
| `journalctl --list-boots` | Список загрузок |
| `journalctl --rotate` | Принудительная ротация |
| `journalctl --vacuum-size=100M` | Ограничить размер |
| `journalctl --vacuum-time=7d` | Ограничить по времени |

### Фильтры

| Флаг | Описание | Пример |
|------|----------|--------|
| `-u SERVICE` | По юниту | `journalctl -u nginx` |
| `-p LEVEL` | По приоритету | `journalctl -p err` |
| `--since TIME` | С времени | `--since "1 hour ago"` |
| `--until TIME` | До времени | `--until "2024-01-15"` |
| `-b [N]` | По загрузке | `journalctl -b -1` |
| `_PID=N` | По PID | `journalctl _PID=1234` |
| `_UID=N` | По UID | `journalctl _UID=1000` |
| `_COMM=NAME` | По процессу | `journalctl _COMM=sshd` |
| `_EXE=PATH` | По исполняемому | `journalctl _EXE=/usr/sbin/sshd` |

### Форматы вывода

| Формат | Флаг | Когда использовать |
|--------|------|-------------------|
| **short** | `-o short` | Чтение человеком (по умолчанию) |
| **cat** | `-o cat` | Только текст сообщения |
| **json** | `-o json` | Парсинг скриптами |
| **json-pretty** | `-o json-pretty` | Чтение JSON человеком |
| **verbose** | `-o verbose` | Полная информация для отладки |
| **export** | `-o export` | Передача/архивирование |

---

## Troubleshooting журналов

### Проблемы с журналами

| Проблема | Причина | Решение |
|----------|---------|---------|
| **No journal files found** | Журналы не сохраняются | `sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald` |
| **Журналы слишком большие** | Не настроена ротация | `sudo journalctl --vacuum-size=500M` |
| **Не удаётся прочитать** | Нет прав | `sudo journalctl` или добавить в группу `systemd-journal` |
| **Пропущены записи** | Buffer переполнен | Увеличить `RateLimitIntervalSec` в `journald.conf` |
| **Журналы не сохраняются после ребута** | Storage=volatile | Изменить на `Storage=persistent` |
| **Коррупция журналов** | Повреждение файлов | Удалить повреждённые файлы в `/var/log/journal/` |

---

## 🔗 Связанные документы

- [Диагностика состояния системы](system-health-check.md) -- общий мониторинг
- [Совместимость оборудования](hardware-compatibility.md) -- проверка аппаратной части
- [Безопасность](../security/readme.md) -- аудит безопасности
- [Управление сервисами](../systemd/readme.md) -- systemd справочник

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Ядро** | 5.15+ (7.x), 6.1+ (8.x) |
| **Система инициализации** | systemd 239+ |
| **Права** | Пользователь (свои логи), root (все логи) |
| **Зависимости** | bash, systemd (journalctl), coreutils, grep |
| **Опционально** | jq (JSON-обработка), gzip (сжатие), notify-send (уведомления) |
| **Скрипт** | log-analyzer.sh (bash 4.0+) |
| **Отчёты** | TXT, JSON |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Для доступа ко всем журналам необходим root или членство в группе `systemd-journal`.
> В РЕД ОС 7.x journald по умолчанию может использовать `Storage=auto` -- рекомендуется установить `Storage=persistent`.

---

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
