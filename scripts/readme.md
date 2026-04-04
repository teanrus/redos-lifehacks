# Готовые скрипты для автоматизации

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📁 Структура

├── [setup](/scripts/setup/readme.md) — Базовая настройка системы
├── [install](/scripts/install/readme.md) — Установка программного обеспечения
├── [utils](/scripts/utils/readme.md) — Вспомогательные скрипты
└── [monitoring](/scripts/monitoring/readme.md) — Мониторинг и диагностика

---

## 🔧 setup — Базовая настройка системы

### ⚙️ [Базовая настройка системы](/scripts/setup/base-setup.md)
Комплексная настройка новой системы: отключение SELinux, оптимизация DNF, добавление репозиториев (Р7-Офис, MAX, Яндекс), установка ПО, настройка часового пояса, SSH, firewall, оптимизация для SSD

---

## 📦 install — Установка программного обеспечения

### 🏢 [Установка 1С:Предприятие](/scripts/install/install-1c.md)
Платформа 1С: клиентская и серверная установка, компоненты КриптоПро, драйверы HASP, ярлыки в меню, автозапуск сервера, поддержка PostgreSQL

### 🔐 [Установка КриптоПро CSP](/scripts/install/install-cryptopro.md)
КриптоПро CSP: зависимости, установка и настройка, поддержка Рутокен, лицензия, интеграция ГОСТ-шифрования с файловым менеджером

### 💬 [Установка мессенджеров](/scripts/install/install-messengers.md)
Корпоративные мессенджеры: Telegram, Среда, MAX, VK Messenger — выборочная установка, ярлыки в меню, автоматическая очистка временных файлов

### 🛡️ [Установка ViPNet Client](/scripts/install/install-vipnet.md)
ViPNet Client: VPN-соединение, автоматическое определение версии, настройка firewall, автозапуск сервиса, импорт конфигурации

---

## 🧹 utils — Вспомогательные скрипты

### 🗑️ [Очистка системы](/scripts/utils/cleanup.md)
Обслуживание системы: временные файлы, кэш DNF, старые ядра, системные журналы, кэш браузеров, корзина, старые бэкапы конфигов

---

## 📊 monitoring — Мониторинг и диагностика

### 📈 [Проверка здоровья системы](/docs/monitoring/system-health-check.md)
Полная проверка: CPU, RAM, диск, службы, обновления, безопасность, температура. Отчёты в TXT/HTML/JSON

### 📝 [Анализ журналов systemd](/docs/monitoring/log-analyzer.md)
Автоматический анализ логов: ошибки, failed службы, безопасность, OOM Killer, ошибки диска

### 🔍 [Проверка совместимости оборудования](/docs/monitoring/hardware-compatibility.md)
Совместимость оборудования: процессор, видеокарта, сеть, звук, диски, USB, Wi-Fi, Bluetooth
