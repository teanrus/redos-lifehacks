# Вспомогательные скрипты для автоматизации в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные скрипты

### 🗑️ [Очистка системы](/scripts/utils/cleanup.md)

[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)  
Обслуживание системы: очистка временных файлов (/tmp, /var/tmp), кэш DNF, системные журналы, старые ядра (оставляет последние 2), кэш браузеров и мессенджеров, корзина, старые бэкапы конфигов

---

### 🚀 Быстрый запуск

```bash
# Очистка системы от временных файлов, кэша, старых ядер
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

> [!TIP]
> Скрипт требует прав `root`. Рекомендуется запускать периодически для поддержания системы в чистоте.

### 🔐 [Управление сохранёнными паролями сетевых ресурсов на РЕД ОС](/scripts/utils/smb-credentials-manager.md)

[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)
Скрипт автоматически сканирует все возможные хранилища учётных данных в системе, находит сохранённые пароли от сетевых ресурсов (SMB/CIFS) и предлагает удалить их в интерактивном режиме.

---

### 🚀 Быстрый запуск

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/smb-credentials-manager.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/smb-credentials-manager.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/smb-credentials-manager.sh -o smb-credentials-manager.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/smb-credentials-manager.sh.sha256 -o smb-credentials-manager.sh.sha256
sha256sum -c smb-credentials-manager.sh.sha256
sudo bash smb-credentials-manager.sh
```

> [!note]
> Скрипт требует прав `sudo` для доступа к системным файлам и кэшам служб.

### 🖥️ [Управление монтированием сетевых шар (CIFS/SMB)](/scripts/utils/mount-manager.md)

[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)
Скрипт для управления монтированием пользовательских директорий по протоколу CIFS/SMB. Поддерживает интерактивное меню, командные аргументы, сохранение пресетов и автоматическое добавление в fstab.

---

### 🚀 Быстрый запуск

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/mount-manager.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/mount-manager.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/mount-manager.sh -o mount-manager.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/mount-manager.sh.sha256 -o mount-manager.sh.sha256
sha256sum -c mount-manager.sh.sha256
sudo bash mount-manager.sh
```

> [!note]
> Скрипт требует прав `root` для монтирования файловых систем и записи в fstab.

### 📂 [Копирование файлов через rsync](/scripts/utils/rsync-copy.md)

[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)
Интерактивный скрипт для копирования файлов и папок по SSH: проверки пути, ping, SSH-доступа, создание удалённой папки, гибкая настройка параметров rsync (архивный режим, сжатие, прогресс, ускорение)

---

### 🚀 Быстрый запуск

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/rsync-copy.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/rsync-copy.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/rsync-copy.sh -o rsync-copy.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/rsync-copy.sh.sha256 -o rsync-copy.sh.sha256
sha256sum -c rsync-copy.sh.sha256
sudo bash rsync-copy.sh
```

Или:

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/rsync-copy.sh

# Сделайте исполняемым
chmod +x rsync-copy.sh

# Запустите от root
sudo ./rsync-copy.sh
```

> [!tip]
> Скрипт запускается на **исходной машине** (откуда копируются файлы). Утилиты `rsync` и `sshpass` устанавливаются автоматически при отсутствии.

### 🔒 [Управление блокировкой USB-накопителей](/scripts/utils/usb-guard.md)

[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)
Скрипт для управления блокировкой USB-накопителей на РЕД ОС. Реализует два метода: UDISKS_IGNORE (запрет автомонтирования) и authorized (полное отключение на уровне шины USB). Поддерживает создание белого списка доверенных устройств.

---

### 🚀 Быстрый запуск

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh -o usb-guard.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh.sha256 -o usb-guard.sh.sha256
sha256sum -c usb-guard.sh.sha256
sudo bash usb-guard.sh
```

> [!note]
> Скрипт требует прав `root` для управления udev-правилами и записи в sysfs.
