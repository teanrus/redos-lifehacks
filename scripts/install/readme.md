# Скрипты установки программного обеспечения в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные скрипты

### 💬 [Установка мессенджеров](/scripts/install/install-messengers.md)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)  
Корпоративные мессенджеры: Telegram, Среда, MAX, VK Messenger — выборочная установка, ярлыки в меню, автоматическая очистка временных файлов

### 🛡️ [Установка ViPNet Client](/scripts/install/install-vipnet.md)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)  
ViPNet Client: VPN-соединение, автоматическое определение версии, настройка firewall, автозапуск сервиса, импорт конфигурации

---

## 🚀 Быстрый запуск

Все скрипты можно запустить одной командой через `curl`:

```bash
# Мессенджеры
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh | sudo bash
# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh | sudo bash
# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh -o install-messengers.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh.sha256 -o install-messengers.sh.sha256
sha256sum -c install-messengers.sh.sha256
sudo bash install-messengers.sh

# ViPNet Client
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh | sudo bash
# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh | sudo bash
# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh -o install-vipnet.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh.sha256 -o install-vipnet.sh.sha256
sha256sum -c install-vipnet.sh.sha256
sudo bash install-vipnet.sh
```

> [!TIP]
> Все скрипты требуют прав `root`. Возможно использование в других RPM-дистрибутивах (CentOS, Fedora, AlmaLinux).

