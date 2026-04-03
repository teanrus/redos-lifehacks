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

├── [docs](/docs/readme.md) Подробная документация  
│   ├── [desktop](/docs/desktop/readme.md) Окружение рабочего стола  
│   ├── [installation](/docs/installation/readme.md) Установка ОС  
│   ├── [network](/docs/network/readme.md) Сеть и интернет  
│   ├── [optimization](/docs/optimization/readme.md) Оптимизация  
│   ├── [security](/docs/security/readme.md) Безопасность  
│   └── [troubleshooting](/docs/troubleshooting/readme.md) Решение проблем  
│  
├── [examples](/examples/readme.md) Примеры использования  
│  
├── [scripts](/scripts/readme.md) Готовые скрипты для автоматизации  
│   ├── [setup](/scripts/setup/readme.md) Скрипты настройки системы  
│   ├── [install](/scripts/install/readme.md) Скрипты установки ПО  
│   └── [utils](/scripts/utils/readme.md) Вспомогательные скрипты  
│  
└── [tools](/tools/readme.md) Полезные инструменты  

## 🚀 Базовый набор скриптов для настройки РЕД ОС 7.3

## 📋 Состав релиза

| Файл | Описание |
| ---- | -------- |
| [redos-setup](https://github.com/teanrus/redos-setup) | Автоматизированный скрипт настройки АРМ РЕД ОС 7.3. Выполняет выборочную установку ПО: базовая система (R7 Office, Яндекс.Браузер, ядро), мессенджеры (MAX, Среда, Telegram, VK Messenger), криптография (КриптоПро, Рутокен), ViPNet VPN, 1С:Предприятие. |
| [base-setup](scripts/setup/base-setup.md) | Базовая настройка системы (SELinux, DNF, репозитории, обновление ядра) |
| [install-cryptopro](scripts/install/install-cryptopro.md) | Установка КриптоПро CSP с автоматическим определением последней версии |
| [install-messengers](scripts/install/install-messengers.md) | Установка мессенджеров (Telegram, Среда, MAX, VK Messenger) |
| [install-vipnet](scripts/install/install-vipnet.md) | Установка и настройка ViPNet Client для защищенного VPN-соединения |
| [install-1c](scripts/install/install-1c.md) | Установка платформы 1С:Предприятие и дополнительных компонентов |
| [cleanup](scripts/utils/cleanup.md) | Очистка системы от временных файлов, кэша, старых ядер |

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

## 📚 Категории лайфхаков

### 🖥️ Системные настройки

- [Настройка DNF для быстрой загрузки](docs/optimization/dnf-tuning.md)
- [Оптимизация работы с SSD](docs/optimization/ssd-optimization.md)
- [Настройка автодополнения в терминале](docs/desktop/bash-completion.md)
- [Настройка часовых поясов и времени](docs/installation/timezone-setup.md)

### 🔒 Безопасность

- [Настройка Firewall (firewalld)](security/firewall-setup.md)
- [Настройка аудита действий пользователей](security/audit-setup.md)
- [Шифрование домашней папки](security/encryption.md)
- [Настройка сложных паролей](security/password-policy.md)

### 🌐 Сеть и интернет

- [Настройка статического IP](network/static-ip.md)
- [Подключение к корпоративному VPN](network/vpn-settings.md)
- [Настройка прокси-сервера](network/proxy-setup.md)
- [Wi-Fi настройки для ноутбуков](network/wifi-setup.md)

### 📦 Установка ПО

- [Установка КриптоПро CSP](install/install-cryptopro.md)
- [Установка ViPNet](install/install-vipnet.md)
- [Установка 1С:Предприятие](install/install-1c.md)
- [Установка мессенджеров](install/install-messengers.md)
- [Установка офисных пакетов](docs/installation/office-setup.md)

### 🛠️ Решение проблем

- [Проблемы с сетью](troubleshooting/network-issues.md)
- [Ошибки при установке ПО](troubleshooting/software-issues.md)
- [Проблемы со звуком](troubleshooting/audio-issues.md)
- [Проблемы с графикой](troubleshooting/graphics-issues.md)
- [Проблема с печатью из РЕД ОС (принтеры Kyocera)](troubleshooting/printers-kyocera.md)

### ⚡ Оптимизация

- [Ускорение загрузки системы](docs/optimization/boot-speed.md)
- [Оптимизация потребления памяти](docs/optimization/memory-tuning.md)
- [Настройка swap](docs/optimization/swap-tuning.md)
- [Очистка системы от мусора](scripts/utils/cleanup.md)

---

### 📖 Документация

Подробные инструкции с пошаговыми объяснениями находятся в папке docs/:

- [Установка РЕД ОС с флешки](docs/installation/usb-install.md)
- [Первые шаги после установки](docs/installation/first-steps.md)
- [Настройка рабочего окружения](docs/desktop/environment-setup.md)
- [Резервное копирование и восстановление](docs/troubleshooting/backup-strategies.md)

## 🎯 Примеры использования

В папке examples/ вы найдете готовые сценарии:

- [Автомонтирование сетевых папок при входе](examples/automount-sshfs.md)
- [Настройка принтера через CUPS](examples/printer-setup.md)
- [Подключение сканера](examples/scanner-setup.md)
- [Настройка многомониторной конфигурации](examples/multi-monitor.md)

## 3 🛠️ Полезные инструменты

В папке tools/ собраны утилиты для диагностики и мониторинга:

| Файл | Описание |
| ---- | -------- |
| [redos-info.sh](tools/redos-info.md) | Сбор информации о системе (версия, ядро, пакеты) |
| [check-updates.sh](tools/check-updates.md) | Проверка доступных обновлений |
| [disk-usage.sh](tools/disk-usage.md) | Анализ использования дискового пространства |
| [system-health.sh](tools/system-health.md) | Проверка состояния системы |

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
