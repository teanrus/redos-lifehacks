# 🐧 Лайф-хаки по настройке рабочей станции на базе операционной системы РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.ru/)
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

## 🚀 Быстрый старт

### Клонирование репозитория

```bash
git clone https://github.com/teanrus/redos-lifehacks.git
cd redos-lifehacks
```

## Основные скрипты
| Скрипт                                | Назначение                                            |
| :------------------------------------ | :---------------------------------------------------- |
| scripts/setup/base-setup.sh           | Базовая настройка системы (SELinux, DNF, репозитории) |
| scripts/install/install-cryptopro.sh  | Установка КриптоПро CSP                               |
| scripts/install/install-vipnet.sh     | Установка ViPNet (с выбором версии)                   |
| scripts/install/install-1c.sh         | Установка 1С:Предприятие                              |
| scripts/install/install-messengers.sh | Установка мессенджеров (Telegram, Viber, СРЕДА)       |
| scripts/utils/cleanup.sh              | Очистка системы от временных файлов                   |

## 📂 Структура репозитория

```text
redos-lifehacks/
├── scripts/              # Готовые скрипты для автоматизации
│   ├── setup/            # Скрипты настройки системы
│   ├── install/          # Скрипты установки ПО
│   └── utils/            # Вспомогательные скрипты
│
├── configs/              # Готовые конфигурационные файлы
│   ├── dnf/              # Настройки DNF
│   ├── selinux/          # Настройки SELinux
│   ├── network/          # Сетевые настройки
│   └── desktop/          # Настройки рабочего стола
│
├── docs/                 # Подробная документация
│   ├── installation/     # Установка ОС
│   ├── troubleshooting/  # Решение проблем
│   ├── optimization/     # Оптимизация
│   └── security/         # Безопасность
│
├── examples/             # Примеры использования
└── tools/                # Полезные инструменты
```
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
- [Настройка DNF для быстрой загрузки](/docs/optimization/dnf-tuning.md)
- [Оптимизация работы с SSD](/docs/optimization/ssd-optimization.md)
- [Настройка часовых поясов и времени](/docs/installation/timezone-setup.md)
### 🔒 Безопасность
- [Настройка Firewall (firewalld)](/docs/security/firewall-setup.md)
- [Настройка аудита действий пользователей](/docs/security/audit-setup.md)
- [Шифрование домашней папки](/docs/security/encryption.md)
- [Настройка сложных паролей](/docs/security/password-policy.md)
### 🌐 Сеть и интернет
- [Настройка статического IP](/docs/network/static-ip.md)
- [Подключение к корпоративному VPN](/docs/network/vpn-settings.md)
- [Настройка прокси-сервера](/docs/network/proxy-setup.md)
- [Wi-Fi настройки для ноутбуков](/docs/network/wifi-setup.md)
### 📦 Установка ПО
- [Установка КриптоПро CSP](/scripts/install/install-cryptopro.sh)
- [Установка ViPNet](/scripts/install/install-vipnet.sh)
- [Установка 1С:Предприятие](/scripts/install/install-1c.sh)
- [Установка мессенджеров](/scripts/install/install-messengers.sh)
- [Установка офисных пакетов](/docs/installation/office-setup.md)
### 🛠️ Решение проблем
- [Проблемы с сетью](/docs/troubleshooting/network-issues.md)
- [Ошибки при установке ПО](/docs/troubleshooting/software-issues.md)
- [Проблемы со звуком](/docs/troubleshooting/audio-issues.md)
- [Проблемы с графикой](/docs/troubleshooting/graphics-issues.md)
### ⚡ Оптимизация
- [Ускорение загрузки системы](/docs/optimization/boot-speed.md)
- [Оптимизация потребления памяти](/docs/optimization/memory-tuning.md)
- [Настройка swap](/docs/optimization/swap-tuning.md)
- [Очистка системы от мусора](/scripts/utils/cleanup.sh)

---

## 🛠️ Использование скриптов
Запуск отдельного скрипта
```bash
# Скачать скрипт
wget https://raw.githubusercontent.com/teanrus/redos-lifehacks/main/scripts/install/install-cryptopro.sh
# Сделать исполняемым
chmod +x install-cryptopro.sh
# Запустить
sudo ./install-cryptopro.sh
```
Запуск через curl (для быстрых скриптов)
```bash
curl -sL https://raw.githubusercontent.com/teanrus/redos-lifehacks/main/scripts/setup/base-setup.sh | sudo bash
```

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

| Инструмент       | Назначение                                       |
| :--------------- | :----------------------------------------------- |
| redos-info.sh    | Сбор информации о системе (версия, ядро, пакеты) |
| check-updates.sh | Проверка доступных обновлений                    |
| disk-usage.sh    | Анализ использования дискового пространства      |
| system-health.sh | Проверка состояния системы                       |

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

## ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](/img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](/github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее! 