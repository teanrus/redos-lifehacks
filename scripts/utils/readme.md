# Вспомогательные скрипты для автоматизации в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные скрипты

### 🗑️ [Очистка системы](/scripts/utils/cleanup.md)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)  
Обслуживание системы: очистка временных файлов (/tmp, /var/tmp), кэш DNF, системные журналы, старые ядра (оставляет последние 2), кэш браузеров и мессенджеров, корзина, старые бэкапы конфигов

---

## 🚀 Быстрый запуск

```bash
# Очистка системы от временных файлов, кэша, старых ядер
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash
```

> [!TIP]
> Скрипт требует прав `root`. Рекомендуется запускать периодически для поддержания системы в чистоте.
