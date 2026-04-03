# 🐧 Лайф-хаки по настройке рабочей станции на базе операционной системы РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Коллекция проверенных решений, скриптов и настроек для комфортной работы в РЕД ОС**

---

## 📖 О чем этот репозиторий

Этот репозиторий содержит собранные и систематизированные лайфхаки, скрипты и конфигурации для настройки рабочей станции на базе **РЕД ОС 7.3**. Здесь вы найдете решения для:

- 🚀 **Быстрой настройки** системы после установки
- 🔧 **Установки и настройки** популярного корпоративного ПО
- 🛡️ **Оптимизации безопасности** и производительности
- 🐛 **Решение типовых проблем** и ошибок
- 📚 **Документацию** с пошаговыми инструкциями

---

## 📂 Структура репозитория

### 📚 [docs](/docs/readme.md) — Подробная документация
Руководства и лайфхаки по настройке РЕД ОС

- 🖥️ [desktop](/docs/desktop/readme.md) — окружение рабочего стола: SSHFS, автодополнение, конфигурация среды, многомониторная конфигурация
- 📦 [installation](/docs/installation/readme.md) — установка ОС: первые шаги, офисные пакеты, принтеры CUPS, сканеры, время, установка с USB
- 🌐 [network](/docs/network/readme.md) — сеть и интернет: прокси, статический IP, VPN, Wi-Fi
- ⚡ [optimization](/docs/optimization/readme.md) — оптимизация: ускорение загрузки, DNF, SSD, память, swap
- 🔒 [security](/docs/security/readme.md) — безопасность: аудит, шифрование, firewall, политики паролей
- 🔧 [troubleshooting](/docs/troubleshooting/readme.md) — решение проблем: звук, графика, сеть, принтеры, миграция

### 💡 [examples](/examples/readme.md) — Примеры использования
Готовые сценарии: автомонтирование SSHFS, многомониторная конфигурация, принтеры CUPS, сканеры

### 🤖 [scripts](/scripts/readme.md) — Готовые скрипты для автоматизации
Автоматизация настройки и установки ПО

- ⚙️ [setup](/scripts/setup/readme.md) — базовая настройка системы
- 📦 [install](/scripts/install/readme.md) — установка ПО (1С, КриптоПро, мессенджеры, ViPNet)
- 🧹 [utils](/scripts/utils/readme.md) — вспомогательные скрипты (очистка системы)

### 🛠️ [tools](/tools/readme.md) — Полезные инструменты
Диагностика и мониторинг: проверка обновлений, анализ диска, информация о системе, состояние системы

##  Состав релиза

### 🏗️ [redos-setup](https://github.com/teanrus/redos-setup)
Автоматизированный скрипт настройки АРМ РЕД ОС 7.3: базовая система (Р7-Офис, Яндекс.Браузер, ядро), мессенджеры (MAX, Среда, Telegram, VK Messenger), криптография (КриптоПро, Рутокен), ViPNet VPN, 1С:Предприятие

### ⚙️ [base-setup](scripts/setup/base-setup.md)
Базовая настройка системы: отключение SELinux, оптимизация DNF, репозитории (Р7-Офис, MAX, Яндекс), установка ПО, часовой пояс, SSH, firewall, оптимизация для SSD

### 🔐 [install-cryptopro](scripts/install/install-cryptopro.md)
КриптоПро CSP: зависимости, установка и настройка, поддержка Рутокен, лицензия, интеграция ГОСТ-шифрования с файловым менеджером

### 💬 [install-messengers](scripts/install/install-messengers.md)
Корпоративные мессенджеры: Telegram, Среда, MAX, VK Messenger — выборочная установка, ярлыки в меню, автоматическая очистка временных файлов

### 🛡️ [install-vipnet](scripts/install/install-vipnet.md)
ViPNet Client: VPN-соединение, автоматическое определение версии, настройка firewall, автозапуск сервиса, импорт конфигурации

### 🏢 [install-1c](scripts/install/install-1c.md)
Платформа 1С: клиентская и серверная установка, компоненты КриптоПро, драйверы HASP, ярлыки в меню, автозапуск сервера, поддержка PostgreSQL

### 🗑️ [cleanup](scripts/utils/cleanup.md)
Обслуживание системы: временные файлы, кэш DNF, системные журналы, старые ядра, кэш браузеров и мессенджеров, корзина, старые бэкапы конфигов

## 🔥 Популярные лайфхаки

1. Ускорение DNF в 10 раз

    ```bash
    echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
    ```

2. Отключение SELinux (для совместимости с некоторым ПО)

    ```bash
    sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    ```

3. Монтирование удаленной папки через SSH

    ```bash
    sshfs user@server:/remote/path /local/mount/point
    ```

4. Быстрая установка всех обновлений

    ```bash
    sudo dnf update -y
    ```

5. Настройка TRIM для SSD

    ```bash
    sudo systemctl enable --now fstrim.timer
    ```

> [!tip]
> **Как внести свой вклад**.
>
>- Форкните репозиторий
>- Создайте ветку (git checkout -b feature/new-lifehack)
>- Добавьте свой лайфхак в соответствующую категорию
>- Зафиксируйте изменения (git commit -m 'Add: новый лайфхак')
>- Отправьте пулл-реквест
<!-- -->
>[!important]
> **Требования к контенту**
>
>- Подробное описание проблемы и решения
>- Пошаговые инструкции
>- Команды с пояснениями
>- Проверка работоспособности на РЕД ОС 7.3

---

## ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее
