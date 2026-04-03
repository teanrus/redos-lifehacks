# Скрипты базовой настройки системы в операционной системе РЕД ОС 7+

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные скрипты

### ⚙️ [Базовая настройка системы](/scripts/setup/base-setup.md)
Комплексная настройка новой системы: отключение SELinux, оптимизация DNF (параллельная загрузка, fastestmirror), добавление репозиториев (Р7-Офис, MAX, Яндекс.Браузер), установка ПО, настройка часового пояса, SSH и firewall, оптимизация для SSD (swappiness, TRIM)

---

## 🚀 Быстрый запуск

```bash
# Базовая настройка системы
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/base-setup.sh | sudo bash
```

> [!TIP]
> Скрипт требует прав `root` и предназначен для РЕД ОС 7.3.
> Возможно использование в других RPM-дистрибутивах (CentOS, Fedora, AlmaLinux).
> Рекомендуется запускать сразу после установки системы.
