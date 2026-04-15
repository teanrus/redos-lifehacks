# Полезные инструменты

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные инструменты

### 🔄 [Проверка доступных обновлений](/tools/check-updates.md)
Обновления системы: скрипт redos-update-checker, команды DNF, обновления безопасности, работа с репозиториями, логирование, автоматизация через cron/systemd

### ⏰ [Автоматическое обновление по расписанию](/scripts/monitoring/redos-auto-update.md)
Автообновление системы: временное окно (12:30–14:00), режимы безопасности/полное/проверка, гибкое расписание, systemd timer, уведомления MAX Messenger

### 💾 [Анализ использования дискового пространства](/tools/disk-usage.md)
Дисковое пространство: диагностика df, поиск больших файлов, анализ каталогов (du, ncdu), очистка кэша DNF, поиск дубликатов (fdupes, rdfind), мониторинг в реальном времени

### 🔍 [Сбор информации о системе РЕД ОС](/tools/redos-info.md)
Информация о системе: версия ОС, ядро, оборудование, диски, сеть, пакеты, сервисы, безопасность, сохранение отчёта в файл, интерактивный и неинтерактивный режимы

### 📊 [Проверка состояния системы](/tools/system-health.md)
Мониторинг системы: загрузка CPU, память, диски, сеть, запущенные процессы, статус сервисов, диагностика проблем

---

## 🚀 Быстрый запуск

Все инструменты можно запустить одной командой через `curl` или `wget`:

### Проверка обновлений

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh -o redos-update-checker.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh.sha256 -o redos-update-checker.sh.sha256
sha256sum -c redos-update-checker.sh.sha256
sudo bash redos-update-checker.sh
```

### Анализ дискового пространства

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-usage.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-usage.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-usage.sh -o disk-usage.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-usage.sh.sha256 -o disk-usage.sh.sha256
sha256sum -c disk-usage.sh.sha256
sudo bash disk-usage.sh
```

### Информация о системе

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-info.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-info.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-info.sh -o redos-info.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-info.sh.sha256 -o redos-info.sh.sha256
sha256sum -c redos-info.sh.sha256
sudo bash redos-info.sh
```

> [!TIP]
> Скрипты требуют прав `root`. Возможно использование в других RPM-дистрибутивах (CentOS, Fedora, AlmaLinux).

