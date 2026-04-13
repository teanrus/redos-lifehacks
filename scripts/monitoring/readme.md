# Мониторинг и диагностика в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)

## 📋 Доступные скрипты

### ⏰ [Автоматическое обновление по расписанию](/scripts/monitoring/redos-auto-update.md)

Интерактивный скрипт для настройки автоматического обновления системы по расписанию с настраиваемым временным окном (например, 12:30–14:00). Режимы: только проверка / безопасность / полное обновление. Гибкое расписание: ежедневно / будни / произвольные дни. Уведомления в MAX Messenger.

---

### 🚀 Быстрый запуск

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-auto-update.sh | sudo bash -s -- --setup

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-auto-update.sh | sudo bash -s -- --setup

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-auto-update.sh -o redos-auto-update.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-auto-update.sh.sha256 -o redos-auto-update.sh.sha256
sha256sum -c redos-auto-update.sh.sha256
sudo bash redos-auto-update.sh --setup
```

### Команды

```bash
sudo ./redos-auto-update.sh --setup     # Интерактивная настройка
sudo ./redos-auto-update.sh --run       # Немедленное обновление
sudo ./redos-auto-update.sh --status    # Статус таймера и логи
sudo ./redos-auto-update.sh --edit      # Изменить расписание
sudo ./redos-auto-update.sh --disable   # Отключить автообновление
```

> [!TIP]
> Скрипт требует прав `root`. Использует systemd timer для надёжного планирования.

---

### 📈 [Проверка здоровья системы](/scripts/monitoring/system-health-check.md)

[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
Полная диагностика: CPU, RAM, диск, сеть, службы, обновления, безопасность, температура. Отчёты в TXT/HTML/JSON.

---

### 🚀 Быстрый запуск

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-health-check.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-health-check.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-health-check.sh -o system-health-check.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-health-check.sh.sha256 -o system-health-check.sh.sha256
sha256sum -c system-health-check.sh.sha256
sudo bash system-health-check.sh
```

### Команды

```bash
sudo ./system-health-check.sh --quick       # Экспресс-проверка (30 секунд)
sudo ./system-health-check.sh --full        # Полная проверка (5 минут)
sudo ./system-health-check.sh --report html # Отчёт в HTML
sudo ./system-health-check.sh --quiet       # Только предупреждения и ошибки
```

> [!NOTE]
> Для полной диагностики необходимы права `root`. Некоторые данные (SMART, SUID) доступны только от root.
