# cleanup.sh Очистка системы от временных файлов, кэша, старых ядер

[![Version](https://img.shields.io/badge/version-1.0-green.svg)](https://github.com/teanrus/redos-lifehacks/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Что делает:**
- Очищает временные файлы (/tmp, /var/tmp)
- Очищает кэш DNF и системные журналы
- Удаляет старые логи
- Очищает кэш браузеров и мессенджеров
- Удаляет старые ядра (оставляет последние 2)
- Очищает корзину
- Удаляет старые бэкапы конфигов

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/cleanup.sh | sudo bash
```