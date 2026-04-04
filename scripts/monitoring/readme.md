# Индекс скриптов мониторинга РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)

> Скрипты мониторинга системы для РЕД ОС — диагностика, отчёты и отслеживание состояния серверов и рабочих станций.

---

## Быстрый старт

### Мгновенная диагностика одной командой

```bash
# Общая диагностика системы
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-info.sh | sudo bash

# Проверка нагрузки на CPU и RAM
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cpu-mem-monitor.sh | bash

# Мониторинг дискового пространства
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-monitor.sh | bash

# Проверка сетевых подключений
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/net-monitor.sh | bash
```

---

## Доступные скрипты

| # | Скрипт | Описание | Документация |
|---|--------|----------|-------------|
| 1 | `system-info.sh` | Полная диагностика системы: ОС, ядро, CPU, RAM, диски, сеть | [docs/monitoring/system-info.md](../../docs/monitoring/system-info.md) |
| 2 | `cpu-mem-monitor.sh` | Мониторинг нагрузки на CPU и использование памяти в реальном времени | [docs/monitoring/cpu-mem-monitor.md](../../docs/monitoring/cpu-mem-monitor.md) |
| 3 | `disk-monitor.sh` | Отслеживание дискового пространства, SMART, inodes | [docs/monitoring/disk-monitor.md](../../docs/monitoring/disk-monitor.md) |
| 4 | `net-monitor.sh` | Проверка сетевых подключений, задержек, пропускной способности | [docs/monitoring/net-monitor.md](../../docs/monitoring/net-monitor.md) |

---

## Сводная таблица возможностей

| Функция | system-info | cpu-mem | disk-monitor | net-monitor |
|---------|:-----------:|:-------:|:------------:|:-----------:|
| Информация об ОС | ✅ | ❌ | ❌ | ❌ |
| Нагрузка CPU | ✅ | ✅ | ❌ | ❌ |
| Использование RAM | ✅ | ✅ | ❌ | ❌ |
| Дисковое пространство | ✅ | ❌ | ✅ | ❌ |
| SMART статус | ❌ | ❌ | ✅ | ❌ |
| Сетевые подключения | ✅ | ❌ | ❌ | ✅ |
| Тест задержки (ping) | ❌ | ❌ | ❌ | ✅ |
| Inodes | ❌ | ❌ | ✅ | ❌ |
| Топ процессов по CPU | ❌ | ✅ | ❌ | ❌ |
| Топ процессов по RAM | ❌ | ✅ | ❌ | ❌ |
| Режим реального времени | ❌ | ✅ | ❌ | ✅ |
| Права root | ✅ | ❌ | ❌ | ❌ |

---

## Инструкции по установке

### Запуск одной командой (без сохранения)

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/<имя_скрипта>.sh | sudo bash
```

### Запуск с сохранением

```bash
# Скачать скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/<имя_скрипта>.sh

# Сделать исполняемым
chmod +x <имя_скрипта>.sh

# Запустить
sudo ./<имя_скрипта>.sh
```

### Настройка cron для периодического мониторинга

```bash
# Открыть crontab
crontab -e

# Проверка каждые 5 минут (результат в лог)
*/5 * * * * /usr/local/bin/system-info.sh >> /var/log/system-info.log 2>&1

# Проверка дискового пространства каждый час
0 * * * * /usr/local/bin/disk-monitor.sh >> /var/log/disk-monitor.log 2>&1
```

---

## Примеры использования

### Ежедневный отчёт о состоянии системы

```bash
# Создать скрипт ежедневного отчёта
cat > /usr/local/bin/daily-report.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y-%m-%d_%H%M)
REPORT_DIR="/var/log/reports"
mkdir -p "$REPORT_DIR"

echo "=== Отчёт за $(date) ===" > "$REPORT_DIR/report-$DATE.txt"
system-info.sh >> "$REPORT_DIR/report-$DATE.txt" 2>&1
disk-monitor.sh >> "$REPORT_DIR/report-$DATE.txt" 2>&1

# Отправить отчёт по почте (опционально)
mail -s "System Report $DATE" admin@example.com < "$REPORT_DIR/report-$DATE.txt"
EOF

chmod +x /usr/local/bin/daily-report.sh

# Запуск каждый день в 9:00
echo "0 9 * * * /usr/local/bin/daily-report.sh" | crontab -
```

### Аварийное оповещение при заполнении диска

```bash
# Проверка заполненности корневого раздела
df / | awk 'NR==2 { if ($5+0 > 90) print "CRITICAL: Disk " $5 " full!" }'

# Добавить в cron (проверка каждые 10 минут)
echo "*/10 * * * * df / | awk 'NR==2 { if (\$5+0 > 90) print \"DISK CRITICAL: \" \$5 }' | mail -s 'Disk Alert' admin@example.com" | crontab -
```

---

## Зависимости

Все скрипты написаны на Bash и используют стандартные утилиты:

| Утилита | Пакет | Требуется |
|---------|-------|:---------:|
| `bash` | `bash` | Всегда |
| `awk` | `gawk` | Всегда |
| `free` | `procps-ng` | Всегда |
| `df` | `coreutils` | Всегда |
| `smartctl` | `smartmontools` | disk-monitor |
| `ping` | `iputils` | net-monitor |
| `top`/`htop` | `procps-ng`/`htop` | cpu-mem |

---

## Документация

Подробные инструкции по каждому скрипту доступны в разделе мониторинга:

- [Общая диагностика системы](../../docs/monitoring/system-info.md)
- [Мониторинг CPU и памяти](../../docs/monitoring/cpu-mem-monitor.md)
- [Мониторинг дисков](../../docs/monitoring/disk-monitor.md)
- [Мониторинг сети](../../docs/monitoring/net-monitor.md)

---

## Совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Оболочка** | Bash 4.4+ |
| **Права** | Зависят от скрипта (см. таблицу выше) |
| **Совместимость** | РЕД ОС 7.x, РЕД ОС 8.x |

> [!note]
> Скрипты также работают на других RHEL-совместимых дистрибутивах (CentOS, AlmaLinux, Rocky Linux). Для РЕД ОС 8.x рекомендуется Bash 5.0+.

---

## Лицензия

MIT — см. [LICENSE](/LICENSE)
