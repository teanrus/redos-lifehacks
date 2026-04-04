# Проверка доступных обновлений в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

> 📋 **Описание:** Руководство по проверке и установке обновлений в РЕД ОС с использованием встроенных утилит DNF и универсального скрипта `redos-update-checker`.

---

## Оглавление

- [Универсальный скрипт redos-update-checker](#универсальный-скрипт-redos-update-checker)
- [Базовые команды DNF](#базовые-команды-dnf)
- [Проверка конкретных пакетов](#проверка-конкретных-пакетов)
- [Работа с репозиториями](#работа-с-репозиториями)
- [Логирование и отчётность](#логирование-и-отчётность)
- [Автоматизация](#автоматизация)

---

## Универсальный скрипт redos-update-checker

### 🚀 Быстрый старт

#### Одной командой:

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh | sudo bash
```

#### Или вручную:

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh

# Сделайте исполняемым
chmod +x redos-update-checker.sh

# Запустите от root
sudo ./redos-update-checker.sh
```

#### Установка в систему:

```bash
# Скопировать в /usr/local/bin
sudo cp redos-update-checker.sh /usr/local/bin/redos-update-checker
sudo chmod +x /usr/local/bin/redos-update-checker

# Теперь доступен по имени
redos-update-checker --check
```

### 📋 Возможности скрипта

| Функция | Описание |
|---------|----------|
| 🖥️ Информация о системе | Версия РЕД ОС, ядро, архитектура |
| 📦 Проверка репозиториев | Список активных репозиториев |
| 🔄 Обновление кэша | Актуализация метаданных пакетов |
| 🔍 Проверка обновлений | Поиск доступных обновлений |
| 🔐 Обновления безопасности | Фильтрация по критическим обновлениям |
| 🐧 Обновления ядра | Отдельная проверка kernel-пакетов |
| 📊 Статистика | Подсчёт количества обновлений |
| 📝 Экспорт отчёта | Сохранение результатов в файл |

### 🎯 Ключи запуска

```bash
redos-update-checker [опция]
```

| Ключ | Описание | Пример |
|------|----------|--------|
| `-h`, `--help` | Показать справку | `redos-update-checker --help` |
| `-i`, `--info` | Информация о системе | `redos-update-checker --info` |
| `-c`, `--check` | Быстрая проверка | `redos-update-checker --check` |
| `-s`, `--security` | Только безопасность | `redos-update-checker --security` |
| `-k`, `--kernel` | Только ядро | `redos-update-checker --kernel` |
| `-u`, `--update` | Проверка + применение | `redos-update-checker --update` |
| `-r`, `--report` | Экспорт отчёта | `redos-update-checker --report` |
| `-f`, `--full` | Полная проверка | `redos-update-checker --full` |

### 📁 Примеры использования

```bash
# Ежедневная быстрая проверка
redos-update-checker --check

# Перед установкой обновлений — проверка безопасности
redos-update-checker --security

# Полная проверка с экспортом отчёта
sudo redos-update-checker --full

# Автоматическое обновление (без подтверждения)
sudo redos-update-checker --update
```

### 📄 Структура отчёта

При использовании ключей `--report` или `--full` скрипт создаёт файл:
```
$HOME/redos-updates-report-ГГГГММДД-ЧЧММСС.txt
```

Отчёт содержит:
- Дату и имя хоста
- Список доступных обновлений
- Обновления безопасности

---

## Базовые команды DNF

### Проверка обновлений

```bash
# Показать все доступные обновления
sudo dnf check-update

# Обновить все пакеты
sudo dnf upgrade

# Обновить с предварительной проверкой
sudo dnf check-update && sudo dnf upgrade
```

### Информация об обновлениях

```bash
# История транзакций DNF
dnf history

# Детали последней транзакции
dnf history info last

# Отменить последнюю транзакцию
sudo dnf history undo last
```

### Коды возврата `dnf check-update`

| Код | Значение |
|-----|----------|
| `0` | Система актуальна |
| `100` | Доступны обновления |
| `1` | Произошла ошибка |

---

## Проверка конкретных пакетов

### Поиск обновлений по пакету

```bash
# Конкретный пакет
sudo dnf list updates | grep <имя-пакета>

# Пример: проверка обновлений ядра
sudo dnf list updates | grep kernel

# Все версии пакета
dnf list --showduplicates <имя-пакета>
```

### Обновления безопасности

```bash
# Список обновлений безопасности
sudo dnf updateinfo list security

# Подробная информация об обновлениях безопасности
sudo dnf updateinfo info security

# Применить только обновления безопасности
sudo dnf upgrade --security
```

### Статистика обновлений

```bash
# Подсчитать количество доступных обновлений
sudo dnf check-update | grep -c "^[a-zA-Z]"

# Показать обновления по категориям
sudo dnf updateinfo list
```

---

## Работа с репозиториями

### Управление репозиториями

```bash
# Список активных репозиториев
dnf repolist enabled

# Список всех репозиториев (включая отключенные)
dnf repolist all

# Обновить метаданные репозиториев
sudo dnf makecache

# Очистить кэш DNF
sudo dnf clean all
```

### Отдельные репозитории

```bash
# Проверка обновлений из конкретного репозитория
sudo dnf check-update --enablerepo=<repo-name>

# Включить репозиторий
sudo dnf config-manager --set-enabled <repo-name>

# Отключить репозиторий
sudo dnf config-manager --set-disabled <repo-name>
```

### Диагностика репозиториев

```bash
# Проверить доступность репозиториев
sudo dnf repolist -v

# Информация о репозитории
sudo dnf repo-info <repo-name>
```

---

## Логирование и отчётность

### Просмотр логов

```bash
# История операций DNF
dnf history list

# Детальная информация о транзакции
dnf history info <ID>

# Логи в системном журнале
journalctl -u dnf
```

### Экспорт данных

```bash
# Экспорт списка обновлений в файл
sudo dnf check-update > ~/updates-$(date +%Y%m%d).txt 2>&1

# Экспорт с подробностями
{
    echo "Дата: $(date)"
    echo "Хост: $(hostname)"
    echo ""
    sudo dnf check-update
    echo ""
    sudo dnf updateinfo list security
} > ~/full-report-$(date +%Y%m%d).txt
```

### Формирование отчёта для аудита

```bash
# Полный отчёт для аудита
sudo dnf history list > ~/audit-history.txt
sudo dnf repolist enabled >> ~/audit-history.txt
sudo dnf check-update >> ~/audit-history.txt 2>&1
```

---

## Автоматизация

### Cron: ежедневная проверка

Создайте файл `/etc/cron.daily/redos-updates`:

```bash
#!/bin/bash
/usr/local/bin/redos-update-checker --report >> /var/log/redos-updates-cron.log 2>&1
```

Сделайте исполняемым:
```bash
sudo chmod +x /etc/cron.daily/redos-updates
```

### Cron: еженедельное обновление

Создайте файл `/etc/cron.weekly/redos-upgrade`:

```bash
#!/bin/bash
# Только обновления безопасности
sudo dnf upgrade --security -y
```

### Systemd-таймер для проверки обновлений

Создайте сервис `/etc/systemd/system/redos-update-checker.service`:

```ini
[Unit]
Description=RED OS Update Checker
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/redos-update-checker --report
```

Создайте таймер `/etc/systemd/system/redos-update-checker.timer`:

```ini
[Unit]
Description=Run update checker daily
Requires=redos-update-checker.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Активируйте таймер:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now redos-update-checker.timer
```

### Уведомления в Telegram (опционально)

Добавьте в скрипт отправку отчёта:

```bash
# После экспорта отчёта
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
    -d chat_id="<CHAT_ID>" \
    -d text="🔔 РЕД ОС: доступны обновления" \
    -d parse_mode="Markdown"
```

---

## 🔧 Troubleshooting

### Проблема: `dnf check-update` возвращает ошибку

**Решение:**
```bash
# Очистить кэш
sudo dnf clean all

# Пересоздать кэш
sudo dnf makecache

# Проверить репозитории
sudo dnf repolist -v
```

### Проблема: медленная проверка обновлений

**Решение:**
```bash
# Использовать только быстрые зеркала
sudo dnf install dnf-plugin-fastestmirror

# Включить fastestmirror
echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
```

### Проблема: недостаточно места для обновлений

**Решение:**
```bash
# Очистить старые ядра
sudo dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)

# Очистить кэш
sudo dnf clean all
```

---

## 📚 Дополнительные ресурсы

- [Официальная документация РЕД ОС](https://redos.red-soft.ru/wiki)
- [DNF Documentation](https://dnf.readthedocs.io/)
- [Репозиторий lifehacks](https://github.com/teanrus/redos-lifehacks)

---

> 💡 **Совет:** Регулярно проверяйте обновления безопасности с помощью `sudo dnf updateinfo list security` и применяйте их в первую очередь. Для автоматизации используйте скрипт `redos-update-checker`.

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | любая |
| **Права** | root (для check-update) |
| **Скрипт** | [`redos-update-checker.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Скрипт использует стандартные команды `dnf`, которые работают одинаково в обеих версиях.
