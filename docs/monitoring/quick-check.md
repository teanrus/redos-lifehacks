# quick-check.sh — Экспресс-диагностика системы

> 📋 **Описание:** Быстрая проверка CPU, RAM, диска, сети и сервисов для мгновенной оценки состояния системы.

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)

## Оглавление

1. [Назначение](#назначение)
2. [Использование](#использование)
3. [Выводимые метрики](#выводимые-метрики)
4. [Зависимости](#зависимости)
5. [Примеры](#примеры)

---

## Назначение

Скрипт `quick-check.sh` предназначен для **быстрой экспресс-диагностики** системы. Он собирает ключевые метрики и выводит их в читаемом формате:

- Загрузка CPU (load average)
- Использование оперативной памяти и swap
- Занятое дисковое пространство
- Сетевые интерфейсы и IP-адреса
- Статус системных сервисов (failed-юниты)
- Время работы системы (uptime)
- Количество доступных обновлений безопасности

Скрипт **не требует прав root** и может запускаться любым пользователем.

---

## Использование

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/quick-check.sh | bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/quick-check.sh | bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/quick-check.sh -o quick-check.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/quick-check.sh.sha256 -o quick-check.sh.sha256
sha256sum -c quick-check.sh.sha256
bash quick-check.sh
```

> [!tip]
> Скрипт не требует `sudo` и может запускаться обычным пользователем для быстрой проверки состояния.

---

## Выводимые метрики

| Метрика | Команда | Описание |
|---------|---------|----------|
| **CPU Load** | `uptime` | Средняя загрузка за 1, 5, 15 минут |
| **RAM** | `free -h` | Использование памяти и swap в человеко-читаемом формате |
| **Disk Usage** | `df -h` | Занятое пространство на разделах `/dev/*` |
| **Network** | `ip -br addr` | Активные интерфейсы и их IP-адреса |
| **Failed Services** | `systemctl --failed` | Количество неработающих сервисов |
| **Uptime** | `uptime -p` | Время работы системы с последнего запуска |
| **Pending Updates** | `dnf check-update` | Количество доступных обновлений |

---

## Зависимости

| Зависимость | Назначение |
|-------------|------------|
| `bash` | Оболочка выполнения |
| `coreutils` | Базовые утилиты (grep, awk, wc) |
| `systemctl` | Проверка статус сервисов |
| `dnf` | Проверка обновлений |
| `ip` | Информация о сетевых интерфейсах |
| `free` | Информация о памяти |
| `df` | Информация о дисках |

---

## Примеры

### Вывод скрипта

```
╔══════════════════════════════════════════════════════╗
║           ЭКСПРЕСС-ДИАГНОСТИКА СИСТЕМЫ              ║
╚══════════════════════════════════════════════════════╝

📊 CPU Load (1m/5m/15m):
 0.15, 0.10, 0.05

🧠 RAM:
              total        used        free      shared  buff/cache   available
Mem:          7.7Gi       2.1Gi       3.5Gi       312Mi       2.1Gi       5.2Gi
Swap:         2.0Gi          0B       2.0Gi

💾 Disk Usage:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       100G   35G   65G  35% /
/dev/sda1       512M   50M  462M  10% /boot
total           101G   35G   65G  35% -

🌐 Network Interfaces:
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             192.168.1.100/24

❌ Failed Services:
   ✅ Все сервисы работают

⏱️  Uptime:
   up 3 days, 2 hours, 15 minutes

🔒 Pending Updates:
   Доступно обновлений: 12
```

### Типичные сценарии

| Сценарий | Команда |
|----------|---------|
| Быстрая проверка после загрузки | `./quick-check.sh` |
| Проверка перед обновлением | `./quick-check.sh \| grep -A1 "Pending"` |
| Мониторинг failed-сервисов | `./quick-check.sh \| grep -A3 "Failed"` |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **Права** | пользователь (без sudo) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

---

## Ссылки

- [Скрипт](../../docs/monitoring/quick-check.sh)
- [Release](https://github.com/teanrus/redos-lifehacks/releases/download/v2.0/quick-check.sh)
- [system-health-check.md](system-health-check.md) — полная диагностика системы
