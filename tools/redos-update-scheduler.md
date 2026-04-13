# Автоматическое обновление РЕД ОС по расписанию

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

> ⏰ **Описание:** Интерактивный скрипт для настройки автоматического обновления системы по расписанию с настраиваемым временным окном (например, с 12:30 до 14:00).

---

## Оглавление

- [Возможности](#возможности)
- [Быстрый старт](#быстрый-старт)
- [Интерактивная настройка](#интерактивная-настройка)
- [Команды скрипта](#команды-скрипта)
- [Режимы обновления](#режимы-обновления)
- [Структура файлов](#структура-файлов)
- [Логирование](#логирование)
- [Уведомления в Telegram](#уведомления-в-telegram)
- [Troubleshooting](#troubleshooting)

---

## Возможности

| Функция | Описание |
|---------|----------|
| ⏰ Временное окно | Обновление только в заданное время (например, 12:30–14:00) |
| 🔐 Режимы | Только проверка / безопасность / полное обновление |
| 📅 Гибкое расписание | Ежедневно / еженедельно / будни / произвольные дни |
| 📝 Логирование | Полный журнал в `/var/log/redos-auto-update.log` |
| 🔔 Telegram | Уведомления о завершении обновления |
| 🛡️ Безопасность | Проверка временного окна перед запуском |
| ⚙️ systemd timer | Надёжный планировщик с Persistent=true |

---

## Быстрый старт

### Одной командой:

```bash
# Скачивание и настройка
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-auto-update.sh -o redos-auto-update.sh
chmod +x redos-auto-update.sh
sudo ./redos-auto-update.sh --setup
```

### Или вручную:

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-auto-update.sh

# Сделайте исполняемым
chmod +x redos-auto-update.sh

# Запустите интерактивную настройку от root
sudo ./redos-auto-update.sh --setup
```

---

## Интерактивная настройка

Запустите скрипт с флагом `--setup`:

```bash
sudo ./redos-auto-update.sh --setup
```

Скрипт последовательно запросит:

### 1. Временное окно

```
Время начала обновления [12:30]: 12:30
Время окончания обновления [14:00]: 14:00
```

Формат: `ЧЧ:ММ` (24-часовой). Поддерживаются диапазоны через полночь (например, `22:00–06:00`).

### 2. Режим обновления

```
Режим обновления:
  1) security  — только обновления безопасности (рекомендуется)
  2) full      — полное обновление всех пакетов
  3) check-only — только проверка без установки

Выберите режим [1-3] [security]:
```

| Режим | Описание |
|-------|----------|
| `security` | Устанавливает только CVE-патчи и критические обновления |
| `full` | Обновляет все пакеты системы |
| `check-only` | Только проверяет и логирует, не устанавливает |

### 3. Периодичность

```
Периодичность запуска:
  1) daily       — каждый день
  2) weekly      — раз в неделю (понедельник)
  3) mon..fri    — каждый будний день
  4) custom      — вручную указать дни

Выберите период [1-4] [daily]:
```

Для `custom` укажите номера дней через пробел:
```
Дни: 1 3 5  # Понедельник, Среда, Пятница
```

### 4. Telegram уведомления (опционально)

```
Настроить уведомления в Telegram? (y/n): y
Telegram Bot Token: 123456:ABC-DEF...
Telegram Chat ID: -1001234567890
```

### 5. Подтверждение

Скрипт покажет итоговую конфигурацию и запросит подтверждение:

```
Итоговая конфигурация:
  Время:         12:30 — 14:00
  Режим:         security
  Период:        daily
  Telegram:      настроен

Применить настройки? (y/n): y
```

---

## Команды скрипта

```bash
sudo redos-auto-update [опция]
```

| Ключ | Описание | Пример |
|------|----------|--------|
| `--setup` | Интерактивная настройка расписания | `sudo redos-auto-update --setup` |
| `--run` | Немедленный запуск обновления | `sudo redos-auto-update --run` |
| `--status` | Показать статус таймера и логи | `sudo redos-auto-update --status` |
| `--disable` | Отключить автоматическое обновление | `sudo redos-auto-update --disable` |
| `--edit` | Изменить текущее расписание | `sudo redos-auto-update --edit` |
| `-h`, `--help` | Показать справку | `sudo redos-auto-update --help` |

### Примеры использования

```bash
# Первоначальная настройка
sudo ./redos-auto-update.sh --setup

# Проверить статус
sudo ./redos-auto-update.sh --status

# Запустить обновление вручную
sudo ./redos-auto-update.sh --run

# Изменить расписание
sudo ./redos-auto-update.sh --edit

# Отключить автообновление
sudo ./redos-auto-update.sh --disable
```

---

## Режимы обновления

### security (рекомендуется)

Устанавливает только обновления безопасности:

```bash
dnf upgrade --security -y
```

Минимальный риск, максимальная защита.

### full

Обновляет все пакеты:

```bash
dnf upgrade -y
```

Полная актуализация, но выше риск конфликтов.

### check-only

Только проверка и логирование:

```bash
dnf check-update
```

Ничего не устанавливает. Подходит для аудита.

---

## Структура файлов

После настройки создаются следующие файлы:

| Файл | Описание |
|------|----------|
| `/etc/redos-auto-update.conf` | Конфигурация (время, режим, период) |
| `/usr/local/bin/redos-auto-update` | Обёрточный скрипт запуска |
| `/etc/systemd/system/redos-auto-update.service` | Systemd service unit |
| `/etc/systemd/system/redos-auto-update.timer` | Systemd timer unit |
| `/var/log/redos-auto-update.log` | Журнал обновлений |

### Конфигурация `/etc/redos-auto-update.conf`

```ini
# Конфигурация автоматического обновления РЕД ОС
START_TIME="12:30"
END_TIME="14:00"
MODE="security"
PERIOD="daily"
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
```

> [!note]
> Файл защищён: `chmod 600` (чтение только root).

### Systemd timer

```ini
[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=300
```

`Persistent=true` — пропущенный запуск выполнится при следующей возможности.
`RandomizedDelaySec=300` — случайная задержка до 5 минут для избежания пиковых нагрузок.

---

## Логирование

Все операции записываются в `/var/log/redos-auto-update.log`:

```
[2026-04-13 12:30:05] ==========================================
[2026-04-13 12:30:05] ЗАПУСК автоматического обновления
[2026-04-13 12:30:05] Время: Mon Apr 13 12:30:05 MSK 2026
[2026-04-13 12:30:05] Окно: 12:30 – 14:00
[2026-04-13 12:30:05] Режим: security
[2026-04-13 12:30:05] В пределах временного окна. Начало проверки...
[2026-04-13 12:30:10] Обновление кэша репозиториев...
[2026-04-13 12:30:15] Доступно обновлений: 23
[2026-04-13 12:30:15] Найдено 5 обновлений безопасности. Установка...
[2026-04-13 12:32:40] Обновления безопасности установлены успешно.
[2026-04-13 12:32:45] Автоматическое обновление завершено.
[2026-04-13 12:32:45] ==========================================
```

### Просмотр логов

```bash
# Последние записи
tail -20 /var/log/redos-auto-update.log

# В реальном времени
tail -f /var/log/redos-auto-update.log

# Поиск ошибок
grep "ОШИБКА\|ERROR" /var/log/redos-auto-update.log

# Статистика через скрипт
sudo ./redos-auto-update.sh --status
```

---

## Уведомления в Telegram

### Настройка

1. Создайте бота через [@BotFather](https://t.me/BotFather)
2. Получите токен
3. Узнайте Chat ID (через [@userinfobot](https://t.me/userinfobot))
4. Перенастройте скрипт:

```bash
sudo ./redos-auto-update.sh --edit
```

### Пример уведомления

```
🔔 РЕД ОС: обновление завершено (13.04.2026 12:32)
Режим: security
Обновлений: 23
```

---

## Troubleshooting

### Таймер не запускается

```bash
# Проверка статуса
systemctl status redos-auto-update.timer

# Перезапуск
sudo systemctl restart redos-auto-update.timer

# Просмотр логов сервиса
journalctl -u redos-auto-update.service -n 20
```

### Обновление не происходит в заданное время

Проверьте временное окно в конфиге:

```bash
cat /etc/redos-auto-update.conf
```

Убедитесь, что текущее время попадает в диапазон `START_TIME`–`END_TIME`.

### Ручной запуск вне окна

```bash
sudo ./redos-auto-update.sh --run
# Скрипт спросит подтверждение при выходе за пределы окна
```

### Ошибка обновления репозитория

```bash
# Проверка репозиториев
sudo dnf repolist -v

# Очистка кэша
sudo dnf clean all
sudo dnf makecache
```

### Сброс настроек

```bash
sudo ./redos-auto-update.sh --disable
# Выберите "Удалить конфигурацию и логи"
```

### Изменение timer вручную

Отредактируйте timer:

```bash
sudo systemctl edit --full redos-auto-update.timer
sudo systemctl daemon-reload
sudo systemctl restart redos-auto-update.timer
```

---

## 🔧 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64, aarch64 |
| **Права** | root (для настройки и запуска) |
| **Скрипт** | [`redos-auto-update.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-auto-update.sh) |
| **Зависимости** | bash, coreutils, systemd, dnf |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

---

## 📚 Связанные документы

- [Проверка обновлений](check-updates.md) — ручная проверка и update checker
- [Очистка системы](../scripts/utils/cleanup.sh) — удаление временных файлов
- [Диагностика](../scripts/monitoring/system-health-check.sh) — полная проверка системы

---

> 💡 **Совет:** Рекомендуется режим `security` с периодом `daily` и окном `12:30–14:00` — система будет обновляться в обеденное время, устанавливая только критические патчи безопасности.
