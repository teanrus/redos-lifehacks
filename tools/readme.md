# Полезные инструменты

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные инструменты

### 🔄 [Проверка доступных обновлений](/tools/check-updates.md)
Обновления системы: скрипт redos-update-checker, команды DNF, обновления безопасности, работа с репозиториями, логирование, автоматизация через cron/systemd

### 💾 [Анализ использования дискового пространства](/tools/disk-usage.md)
Дисковое пространство: диагностика df, поиск больших файлов, анализ каталогов (du, ncdu), очистка кэша DNF, поиск дубликатов (fdupes, rdfind), мониторинг в реальном времени

### 🔍 [Сбор информации о системе РЕД ОС](/tools/redos-info.md)
Информация о системе: версия ОС, ядро, оборудование, диски, сеть, пакеты, сервисы, безопасность, сохранение отчёта в файл, интерактивный и неинтерактивный режимы

### 📊 [Проверка состояния системы](/tools/system-health.md)
Мониторинг системы: загрузка CPU, память, диски, сеть, запущенные процессы, статус сервисов, диагностика проблем

---

## 🚀 Быстрый запуск

Все инструменты можно запустить одной командой через `curl`:

```bash
# Проверка обновлений
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh | sudo bash

# Анализ дискового пространства
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-usage.sh | sudo bash

# Информация о системе
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-info.sh | sudo bash
```

> [!TIP]
> Скрипты требуют прав `root`. Возможно использование в других RPM-дистрибутивах (CentOS, Fedora, AlmaLinux).

