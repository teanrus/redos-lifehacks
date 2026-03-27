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

| Файл | Описание | Команда для запуска (последняя версия) |
|------|----------|----------------------------------------|
| `base-setup.sh` | Базовая настройка системы (SELinux, DNF, репозитории, обновление ядра) | `curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/base-setup.sh \| sudo bash` |
| `install-cryptopro.sh` | Установка КриптоПро CSP с автоматическим определением последней версии | `curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-cryptopro.sh \| sudo bash` |
| `install-messengers.sh` | Установка мессенджеров (Telegram, Среда, MAX, VK Messenger) | `curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh \| sudo bash` |
| `install-vipnet.sh` | Установка и настройка ViPNet Client для защищенного VPN-соединения | `curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh \| sudo bash` |
| `install-1c.sh` | Установка платформы 1С:Предприятие и дополнительных компонентов | `curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-1c.sh \| sudo bash` |
| `cleanup.sh` | Очистка системы от временных файлов, кэша, старых ядер | `curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh \| sudo bash` |

## 🔧 Подробное описание скриптов

<details>
<summary>base-setup.sh — Базовая настройка системы</summary>
  
**Что делает:**
- Отключает SELinux
- Настраивает DNF (параллельная загрузка, fastestmirror)
- Добавляет репозитории R7 Office, MAX Desktop, Яндекс.Браузер
- Устанавливает R7 Office, MAX, Яндекс.Браузер
- Устанавливает и обновляет ядро (redos-kernels6)
- Настраивает часовой пояс (Asia/Yekaterinburg, UTC+5)
- Настраивает SSH и firewall
- Оптимизирует систему (swappiness, TRIM для SSD)

**Запуск (последняя версия):**
```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/base-setup.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/base-setup.sh | sudo bash
```
</details>
<details>
<summary>install-cryptopro.sh — Установка КриптоПро CSP</summary>

**Что делает:**
- Устанавливает зависимости (ifd-rutokens, token-manager, pcsc-lite и др.)
- Загружает и устанавливает КриптоПро CSP
- Настраивает работу с Рутокен
- Предлагает установить лицензию
- Настраивает интеграцию ГОСТ-шифрования с файловым менеджером

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-cryptopro.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/install-cryptopro.sh | sudo bash
```
</details>
<details>
<summary>install-messengers.sh — Установка мессенджеров</summary>

**Что делает:**
- Установка Telegram:
  - Скачивает и распаковывает архив в /opt/telegram
  - Создает символическую ссылку /usr/bin/telegram
  - Создает ярлык в меню приложений
- Установка Среда:
  - Скачивает и устанавливает RPM-пакет
  - Создает ярлык в меню приложений
- Установка MAX:
  - Добавляет репозиторий MAX (при отсутствии)
  - Устанавливает через dnf install max
- Установка VK Messenger (опционально):
  - Скачивает и устанавливает RPM-пакет
  - Создает ярлык в меню приложений
- Каждый мессенджер устанавливается по отдельному запросу
- Проверка наличия установленной версии с предложением переустановки
- Автоматическая очистка временных файлов после установки

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/install-messengers.sh | sudo bash
```

**Пример диалога при запуске:**

```bash
=== 4. Выбор мессенджеров для установки ===
Будут установлены только выбранные мессенджеры

Установить мессенджер Telegram? (y/n): y
=== Установка Telegram ===
Получение информации о последнем релизе...
✓ Найдена последняя версия: v2.7
Загрузка tsetup.tar.xz...
✓ tsetup.tar.xz успешно загружен
Распаковка Telegram...
✓ Telegram успешно установлен

Установить корпоративный мессенджер Среда? (y/n): y
=== Установка Среда ===
Загрузка sreda.rpm...
✓ sreda.rpm успешно загружен
✓ Установка Среда успешно выполнено

Установить мессенджер MAX? (y/n): y
=== Установка MAX ===
✓ MAX успешно установлен

Установить мессенджер ВК (VK Messenger)? (y/n): n
Пропускаем установку VK Messenger
Установленные компоненты:

Telegram — универсальный мессенджер
Среда — корпоративный мессенджер для защищенного обмена сообщениями
MAX — корпоративный мессенджер MAX Desktop
VK Messenger — мессенджер от ВКонтакте (опционально)
```
**Полезные команды после установки:**

```bash
# Запуск мессенджеров
telegram      # Telegram
sreda         # Среда
max           # MAX
vk-messenger  # VK Messenger
```
</details>
<details>
<summary>install-vipnet.sh — Установка ViPNet Client</summary>

**Что делает:**
- Автоматически определяет последнюю версию ViPNet Client из репозитория
- Устанавливает необходимые зависимости (libpcap, iptables, python3 и др.)
- Загружает и устанавливает ViPNet Client (RPM-пакет)
- Настраивает сетевые интерфейсы для работы с VPN
- Добавляет правила firewall для корректной работы ViPNet
- Настраивает автозапуск сервиса ViPNet
- Создает ярлык в меню приложений
- Предлагает импортировать существующие конфигурации (пользователи, политики)
- Проверяет наличие установленной версии с предложением переустановки

**Особенности:**
- Поддержка как 32-битных, так и 64-битных версий
- Автоматическое определение архитектуры системы
- Совместимость с РЕД ОС 7.3 из коробки

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/install-vipnet.sh | sudo bash
```

**Пример диалога при запуске:**

```bash
=== Установка ViPNet Client ===
Определение архитектуры системы...
✓ Обнаружена архитектура: x86_64
Поиск последней версии ViPNet Client...
✓ Найдена версия: 4.2.0-1234
Загрузка viрnet-client-4.2.0-1234.x86_64.rpm...
✓ Загрузка завершена
Установка зависимостей...
✓ Зависимости установлены
Установка ViPNet Client...
✓ ViPNet Client успешно установлен
Настройка firewall...
✓ Правила firewall добавлены
Настройка автозапуска...
✓ Сервис ViPNet добавлен в автозапуск

Желаете импортировать конфигурацию пользователя? (y/n): y
Укажите путь к файлу конфигурации (например, /home/user/viрnet.conf): /home/user/viрnet.conf
✓ Конфигурация импортирована

Установка завершена!
```

**Полезные команды после установки:**

```bash
# Запуск ViPNet Client
vipnet-client

# Управление сервисом
systemctl start vipnet    # Запуск сервиса
systemctl stop vipnet     # Остановка сервиса
systemctl status vipnet   # Проверка статуса

# Просмотр логов
journalctl -u vipnet -f   # Логи в реальном времени
```
</details>
<details>
<summary>install-1c.sh — Установка платформы 1С:Предприятие</summary>

**Что делает:**
- Устанавливает необходимые зависимости (libxslt, libXScrnSaver, fontconfig, freetype и др.)
- Загружает и устанавливает серверную и клиентскую части 1С:Предприятие
- Настраивает сервер 1С (если выбран серверный режим)
- Устанавливает дополнительные компоненты:
  - Интерфейс на русском языке
  - Компоненты для работы с КриптоПро (ГОСТ-шифрование)
  - Драйверы защиты HASP (при необходимости)
  - Компоненты для работы с веб-расширениями
- Создает ярлыки в меню приложений (толстый клиент, тонкий клиент, конфигуратор)
- Настраивает автозапуск сервера 1С (для серверной установки)
- Проверяет наличие установленной версии с предложением обновления

**Режимы установки:**
- Клиентская установка — только клиентская часть (толстый/тонкий клиент)
- Серверная установка — полная установка с сервером 1С
- Выборочная установка — возможность выбрать конкретные компоненты

**Особенности:**
- Поддержка 32-битных и 64-битных версий
- Автоматическая настройка рабочих каталогов
- Оптимизация производительности для РЕД ОС
- Совместимость с различными СУБД (PostgreSQL, MS SQL Server через ODBC)

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-1c.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/install-1c.sh | sudo bash
```

**Пример диалога при запуске:**

```bash
=== Установка платформы 1С:Предприятие ===
Определение архитектуры системы...
✓ Обнаружена архитектура: x86_64

Выберите тип установки:
1) Только клиентская часть
2) Полная (клиент + сервер)
3) Выборочная установка компонентов
Введите номер (1-3): 1

Поиск последней версии 1С:Предприятие...
✓ Найдена версия: 8.3.23.2045
Загрузка 1c-enterprise-client-8.3.23.2045.x86_64.rpm...
✓ Загрузка завершена
Установка зависимостей...
✓ Зависимости установлены
Установка клиентской части 1С...
✓ Клиентская часть успешно установлена

Установить компоненты для работы с КриптоПро? (y/n): y
✓ Компоненты КриптоПро установлены

Установить драйверы HASP для работы с ключами защиты? (y/n): n
Пропускаем установку HASP

Установка завершена!
Созданы ярлыки в меню "Офис":
- 1С:Предприятие (толстый клиент)
- 1С:Предприятие (тонкий клиент)
- Конфигуратор 1С
```

**Полезные команды после установки:**

```bash
# Запуск клиента 1С (толстый клиент)
1cv8

# Запуск конфигуратора
1cv8 CONFIG

# Запуск тонкого клиента
1cv8 THIN

# Для серверной установки:
systemctl start srv1cv83    # Запуск сервера 1С
systemctl stop srv1cv83     # Остановка сервера
systemctl status srv1cv83   # Проверка статуса

# Просмотр версии платформы
/opt/1cv8/x86_64/8.3.23.2045/1cv8 --version
```
</details>
<details>
<summary>cleanup.sh — Очистка системы</summary>

**Что делает:**
- Очищает временные файлы (/tmp, /var/tmp)
- Очищает кэш DNF и системные журналы
- Удаляет старые логи
- Очищает кэш браузеров и мессенджеров
- Удаляет старые ядра (оставляет последние 2)
- Очищает корзину
- Удаляет старые бэкапы конфигов

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/cleanup.sh | sudo bash
```
</details>

---

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
- [Установка КриптоПро CSP](scripts/install/install-cryptopro.sh)
- [Установка ViPNet](scripts/install/install-vipnet.sh)
- [Установка 1С:Предприятие](scripts/install/install-1c.sh)
- [Установка мессенджеров](scripts/install/install-messengers.sh)
- [Установка офисных пакетов](docs/installation/office-setup.md)
### 🛠️ Решение проблем
- [Проблемы с сетью](docs/troubleshooting/network-issues.md)
- [Ошибки при установке ПО](docs/troubleshooting/software-issues.md)
- [Проблемы со звуком](docs/troubleshooting/audio-issues.md)
- [Проблемы с графикой](docs/troubleshooting/graphics-issues.md)
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

## ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее! 