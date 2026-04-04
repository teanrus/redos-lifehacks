# Вспомогательные скрипты для автоматизации в операционной системе РЕД ОС 7+

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные скрипты

### 🗑️ [Очистка системы](/scripts/utils/cleanup.md)
Обслуживание системы: очистка временных файлов (/tmp, /var/tmp), кэш DNF, системные журналы, старые ядра (оставляет последние 2), кэш браузеров и мессенджеров, корзина, старые бэкапы конфигов

---

## 🚀 Быстрый запуск

```bash
# Очистка системы от временных файлов, кэша, старых ядер
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash
```

> [!TIP]
> Скрипт требует прав `root` и предназначен для РЕД ОС 7.3. Рекомендуется запускать периодически для поддержания системы в чистоте.
