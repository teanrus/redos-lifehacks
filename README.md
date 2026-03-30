# 🐧 Лайф-хаки по настройке рабочей станции на базе операционной системы РЕД ОС

[![Version](https://img.shields.io/badge/version-1.0-green.svg)](https://github.com/teanrus/redos-lifehacks/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Коллекция проверенных решений, скриптов и настроек для комфортной работы в РЕД ОС 7.3.**

---

## 📖 О чем этот репозиторий

Этот репозиторий содержит собранные и систематизированные лайфхаки, скрипты и конфигурации для настройки рабочей станции на базе **РЕД ОС 7.3**. Здесь вы найдете решения для:

- 🚀 **Быстрой настройки** системы после установки
- 🔧 **Установки и настройки** популярного корпоративного ПО
- 🛡️ **Оптимизации безопасности** и производительности
- 🐛 **Решение типовых проблем** и ошибок
- 📚 **Документацию** с пошаговыми инструкциями

---

### Клонирование репозитория

```bash
git clone https://github.com/teanrus/redos-lifehacks.git
cd redos-lifehacks
```

# 🚀 Базовый набор скриптов для настройки РЕД ОС 7.3

## 📋 Состав релиза

| Файл | Описание |
|------|----------|
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
- [Настройка Firewall (firewalld)](docs/security/firewall-setup.md)
- [Настройка аудита действий пользователей](docs/security/audit-setup.md)
- [Шифрование домашней папки](docs/security/encryption.md)
- [Настройка сложных паролей](docs/security/password-policy.md)
### 🌐 Сеть и интернет
- [Настройка статического IP](docs/network/static-ip.md)
- [Подключение к корпоративному VPN](docs/network/vpn-settings.md)
- [Настройка прокси-сервера](docs/network/proxy-setup.md)
- [Wi-Fi настройки для ноутбуков](docs/network/wifi-setup.md)
### 📦 Установка ПО
- [Установка КриптоПро CSP](scripts/install/install-cryptopro.md)
- [Установка ViPNet](scripts/install/install-vipnet.md)
- [Установка 1С:Предприятие](scripts/install/install-1c.md)
- [Установка мессенджеров](scripts/install/install-messengers.md)
- [Установка офисных пакетов](docs/installation/office-setup.md)
### 🛠️ Решение проблем
- [Проблемы с сетью](docs/troubleshooting/network-issues.md)
- [Ошибки при установке ПО](docs/troubleshooting/software-issues.md)
- [Проблемы со звуком](docs/troubleshooting/audio-issues.md)
- [Проблемы с графикой](docs/troubleshooting/graphics-issues.md)
- [Проблема с печатью из РЕД ОС (принтеры Kyocera)](docs/troubleshooting/printers-kyocera.md)
### ⚡ Оптимизация
- [Ускорение загрузки системы](docs/optimization/boot-speed.md)
- [Оптимизация потребления памяти](docs/optimization/memory-tuning.md)
- [Настройка swap](docs/optimization/swap-tuning.md)
- [Очистка системы от мусора](scripts/utils/cleanup.sh)

---

### 📖 Документация
Подробные инструкции с пошаговыми объяснениями находятся в папке docs/:
- [Установка РЕД ОС с флешки](docs/installation/usb-install.md)
- [Первые шаги после установки](docs/installation/first-steps.md)
- [Настройка рабочего окружения](docs/desktop/environment-setup.md)
- [Резервное копирование и восстановление](docs/backup/backup-strategies.md)

## 🎯 Примеры использования
В папке examples/ вы найдете готовые сценарии:
- [Автомонтирование сетевых папок при входе](examples/automount-sshfs.md)
- [Настройка принтера через CUPS](examples/printer-setup.md)
- [Подключение сканера](examples/scanner-setup.md)
- [Настройка многомониторной конфигурации](examples/multi-monitor.md)

## 3 🛠️ Полезные инструменты
В папке tools/ собраны утилиты для диагностики и мониторинга:

| Файл | Описание |
|------|----------|
| [redos-info.sh](tools/redos-info.md) | Сбор информации о системе (версия, ядро, пакеты) |
| [check-updates.sh](tools/check-updates.md) | Проверка доступных обновлений |
| [disk-usage.sh](tools/disk-usage.md) | Анализ использования дискового пространства |
| [system-health.sh](tools/system-health.md) | Проверка состояния системы |

>### 🤝 Как внести свой вклад
>- Форкните репозиторий
>- Создайте ветку (git checkout -b feature/new-lifehack)
>- Добавьте свой лайфхак в соответствующую категорию
>- Зафиксируйте изменения (git commit -m 'Add: новый лайфхак')
>- Отправьте пулл-реквест
>
>### Требования к контенту 
>- Подробное описание проблемы и решения
>- Пошаговые инструкции
>- Команды с пояснениями
>- Проверка работоспособности на РЕД ОС 7.3

## 📄 Лицензия
MIT License — свободное использование, копирование, модификация и распространение.

---

## ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее! 
