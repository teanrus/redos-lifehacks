# Очистка системы от временных файлов, кэша, старых ядер

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Что делает:**
- Очищает временные файлы (/tmp, /var/tmp)
- Очищает кэш DNF и системные журналы
- Удаляет старые логи
- Очищает кэш браузеров и мессенджеров
- Удаляет старые ядра (оставляет последние 2)
- Очищает корзину
- Удаляет старые бэкапы конфигов

**Запуск:**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash
```

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 |
| **Права** | root (sudo) |
| **Скрипт** | [`cleanup.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Скрипт использует стандартные команды (dnf, journalctl, rm).
> `grub2-mkconfig` вызывается после удаления старых ядер — на UEFI путь может отличаться.
> Команды совместимы с обеими версиями РЕД ОС.
