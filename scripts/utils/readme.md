# Вспомогательные скрипты для автоматизации в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![RED OS](https://img.shields.io/badge/RED%20OS-7.3%20%7C%208.x-b30000?style=for-the-badge)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Доступные скрипты

### 🗑️ [Очистка системы](/scripts/utils/cleanup.md)

Обслуживание системы: очистка временных файлов (/tmp, /var/tmp), кэш DNF, системные журналы, старые ядра (оставляет последние 2), кэш браузеров и мессенджеров, корзина, старые бэкапы конфигов

```bash
# Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh -o cleanup.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh.sha256 -o cleanup.sh.sha256
sha256sum -c cleanup.sh.sha256
sudo bash cleanup.sh
```

> [!TIP]
> Скрипт требует прав `root`. Рекомендуется запускать периодически для поддержания системы в чистоте.

### 🔄 [Миграция пользователя в РЕД ОС](/scripts/utils/user-migration.md)

Создание нового пользователя и перенос данных старой учётной записи: домашний каталог, профили браузеров, SSH-ключи, проверка свободного места, выбор копирования или перемещения, очистка GNOME Keyring у нового пользователя.

```bash
# Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/user-migration.sh -o user-migration.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/user-migration.sh.sha256 -o user-migration.sh.sha256
sha256sum -c user-migration.sh.sha256
sudo bash user-migration.sh
```

> [!warning]
> Перед миграцией убедитесь, что старый пользователь вышел из системы и закрыл браузеры.

### 💾 [REDOS BACKUP v2.4](/scripts/utils/redos-backup.md)

Утилита резервного копирования пользовательских данных с интерактивным режимом и CLI: XDG-каталоги или полный HOME, выбор пользователя и каталога назначения через параметры, автоматический поиск накопителя, проверка свободного места, безопасные исключения, обработка символических ссылок и спецфайлов, прогресс-бар с процентами и логирование.

```bash
# Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-backup-v2.4.sh -o redos-backup-v2.4.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-backup-v2.4.sh.sha256 -o redos-backup-v2.4.sh.sha256
sha256sum -c redos-backup-v2.4.sh.sha256
sudo bash redos-backup-v2.4.sh

# CLI-пример: XDG-данные пользователя без интерактивных вопросов
sudo bash redos-backup-v2.4.sh --user eduadmin --mode data --dest /mnt/backup/eduadmin --yes

# Только проверка размера и свободного места
sudo bash redos-backup-v2.4.sh --user eduadmin --mode data --dest /mnt/backup/eduadmin --check
```

> [!tip]
> Перед запуском подключите и смонтируйте накопитель для бэкапа. Без параметров скрипт запускает интерактивный мастер, а с параметрами работает как CLI.

### 🔐 [Управление сохранёнными паролями сетевых ресурсов на РЕД ОС](/scripts/utils/smb-credentials-manager.md)

Скрипт автоматически сканирует все возможные хранилища учётных данных в системе, находит сохранённые пароли от сетевых ресурсов (SMB/CIFS) и предлагает удалить их в интерактивном режиме.

```bash
# Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/smb-credentials-manager.sh -o smb-credentials-manager.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/smb-credentials-manager.sh.sha256 -o smb-credentials-manager.sh.sha256
sha256sum -c smb-credentials-manager.sh.sha256
sudo bash smb-credentials-manager.sh
```

> [!note]
> Скрипт требует прав `sudo` для доступа к системным файлам и кэшам служб.

### 🖥️ [Управление монтированием сетевых шар (CIFS/SMB)](/scripts/utils/mount-manager.md)

Скрипт для управления монтированием пользовательских директорий по протоколу CIFS/SMB. Поддерживает интерактивное меню, командные аргументы, сохранение пресетов и автоматическое добавление в fstab.

```bash
# Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/mount-manager.sh -o mount-manager.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/mount-manager.sh.sha256 -o mount-manager.sh.sha256
sha256sum -c mount-manager.sh.sha256
sudo bash mount-manager.sh
```

> [!note]
> Скрипт требует прав `root` для монтирования файловых систем и записи в fstab.

### 📂 [Копирование файлов через rsync](/scripts/utils/rsync-copy.md)

Интерактивный скрипт для копирования файлов и папок по SSH: проверки пути, ping, SSH-доступа, создание удалённой папки, гибкая настройка параметров rsync (архивный режим, сжатие, прогресс, ускорение)

```bash
# Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/rsync-copy.sh -o rsync-copy.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/rsync-copy.sh.sha256 -o rsync-copy.sh.sha256
sha256sum -c rsync-copy.sh.sha256
sudo bash rsync-copy.sh
```

> [!tip]
> Скрипт запускается на **исходной машине** (откуда копируются файлы). Утилиты `rsync` и `sshpass` устанавливаются автоматически при отсутствии.

### 🔒 [Управление блокировкой USB-накопителей](/scripts/utils/usb-guard.md)

Скрипт для управления блокировкой USB-накопителей на РЕД ОС. Реализует два метода: UDISKS_IGNORE (запрет автомонтирования) и authorized (полное отключение на уровне шины USB). Поддерживает создание белого списка доверенных устройств.

```bash
# Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh -o usb-guard.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh.sha256 -o usb-guard.sh.sha256
sha256sum -c usb-guard.sh.sha256
sudo bash usb-guard.sh
```

> [!note]
> Скрипт требует прав `root` для управления udev-правилами и записи в sysfs.
