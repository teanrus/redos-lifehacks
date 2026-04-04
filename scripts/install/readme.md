# Скрипты установки программного обеспечения в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные скрипты

### 🏢 [Установка 1С:Предприятие](/scripts/install/install-1c.md)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)  
Платформа 1С: клиентская и серверная установка, компоненты КриптоПро, драйверы HASP, ярлыки в меню, автозапуск сервера, поддержка PostgreSQL

### 🔐 [Установка КриптоПро CSP](/scripts/install/install-cryptopro.md)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)  
КриптоПро CSP: зависимости, установка и настройка, поддержка Рутокен, лицензия, интеграция ГОСТ-шифрования с файловым менеджером

### 💬 [Установка мессенджеров](/scripts/install/install-messengers.md)
Корпоративные мессенджеры: Telegram, Среда, MAX, VK Messenger — выборочная установка, ярлыки в меню, автоматическая очистка временных файлов

### 🛡️ [Установка ViPNet Client](/scripts/install/install-vipnet.md)
ViPNet Client: VPN-соединение, автоматическое определение версии, настройка firewall, автозапуск сервиса, импорт конфигурации

---

## 🚀 Быстрый запуск

Все скрипты можно запустить одной командой через `curl`:

```bash
# 1С:Предприятие
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-1c.sh | sudo bash

# КриптоПро CSP
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-cryptopro.sh | sudo bash

# Мессенджеры
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh | sudo bash

# ViPNet Client
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh | sudo bash
```

> [!TIP]
> Все скрипты требуют прав `root` и предназначены для РЕД ОС 7.3. Возможно использование в других RPM-дистрибутивах (CentOS, Fedora, AlmaLinux).

