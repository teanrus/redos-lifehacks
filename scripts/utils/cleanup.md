# Очистка системы от временных файлов, кэша, старых ядер

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

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
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh -o cleanup.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh.sha256 -o cleanup.sh.sha256
sha256sum -c cleanup.sh.sha256
sudo bash cleanup.sh
```

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 |
| **Права** | root (sudo) |
| **Скрипт** | [`cleanup.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x (может работать на других RPM-дистрибутивах: Fedora, RHEL, CentOS, Astra Linux, Alt Linux) |

> [!note]
> Скрипт использует стандартные команды (dnf, journalctl, rm).
> `grub2-mkconfig` вызывается после удаления старых ядер — на UEFI путь может отличаться.
> Команды совместимы с обеими версиями РЕД ОС.
