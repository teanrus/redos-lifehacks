# Автомонтирование SSHFS папок при входе (операционная система РЕД ОС)

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📖 Оглавление

1. [Установка SSHFS](#-1-установка-sshfs)
2. [Базовое монтирование](#-2-базовое-монтирование)
3. [Автомонтирование](#-3-автомонтирование-через-etcfstab)
4. [Аутентификация по SSH-ключам](#-6-аутентификация-по-ssh-ключам)
5. [Диагностика и проблемы](#-7-диагностика-и-проблемы)
6. [Автоматическая настройка скриптом](#-9-автоматическая-настройка-скриптом)
7. [Лайфхаки](#-лайфхаки)

---

## 🛠️ 1. Установка SSHFS

```bash
# Установка пакетов
sudo dnf install sshfs fuse

# Проверка версии
sshfs --version
```

>[!TIP]
>SSHFS позволяет монтировать удалённые директории через SSH как локальные файловые системы.

---

## 📁 2. Базовое монтирование

```bash
# Создание точки монтирования
mkdir -p ~/mnt/remote

# Монтирование удалённой папки
sshfs user@192.168.1.100:/remote/path ~/mnt/remote

# Монтирование с указанием порта
sshfs -p 2222 user@192.168.1.100:/remote/path ~/mnt/remote

# Размонтирование
fusermount -u ~/mnt/remote
# или
umount ~/mnt/remote
```

> [!TIP]
> Быстрый доступ к файлам на удалённом сервере без копирования.

---

## 📋 3. Автомонтирование через /etc/fstab

```bash
# Создание точки монтирования
sudo mkdir -p /mnt/sshfs/remote

# Добавление записи в /etc/fstab
echo 'user@192.168.1.100:/remote/path /mnt/sshfs/remote fuse.sshfs _netdev,auto,user,identityfile=/home/user/.ssh/id_rsa,allow_other 0 0' | sudo tee -a /etc/fstab

# Монтирование всех записей из fstab
sudo mount -a
```

> [!TIP]
> Автоматическое монтирование при загрузке системы.

### Параметры монтирования

| Параметр | Описание |
| -------- | -------- |
| `_netdev` | Указывает, что это сетевое устройство |
| `auto` | Монтировать при `mount -a` |
| `user` | Разрешить обычному пользователю монтировать |
| `identityfile` | Путь к SSH-ключу |
| `allow_other` | Разрешить доступ другим пользователям (требует `user_allow_other` в `/etc/fuse.conf`) |

---

## ⚙️ 4. Автомонтирование через systemd

```bash
# Создание юнит-файла
sudo tee /etc/systemd/system/sshfs-remote.mount << 'EOF'
[Unit]
Description=SSHFS mount for remote server
After=network-online.target
Wants=network-online.target

[Mount]
What=user@192.168.1.100:/remote/path
Where=/mnt/sshfs/remote
Type=fuse.sshfs
Options=_netdev,auto,identityfile=/home/user/.ssh/id_rsa,allow_other

[Install]
WantedBy=multi-user.target
EOF

# Включение и запуск
sudo systemctl enable sshfs-remote.mount
sudo systemctl start sshfs-remote.mount

# Проверка статуса
systemctl status sshfs-remote.mount
```

> [!TIP]
> Надёжный способ автоматического монтирования с контролем состояния через systemd.

---

## 👤 5. Монтирование при входе пользователя

```bash
# Создание скрипта автозапуска
mkdir -p ~/.config/autostart-scripts

tee ~/.config/autostart-scripts/mount-sshfs.sh << 'EOF'
#!/bin/bash
sleep 10
mkdir -p ~/mnt/remote
sshfs user@192.168.1.100:/remote/path ~/mnt/remote
EOF

chmod +x ~/.config/autostart-scripts/mount-sshfs.sh

# Добавление в автозагрузку (для KDE/GNOME)
mkdir -p ~/.config/autostart

tee ~/.config/autostart/sshfs-mount.desktop << 'EOF'
[Desktop Entry]
Type=Application
Exec=/home/user/.config/autostart-scripts/mount-sshfs.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=SSHFS Mount
Comment=Mount SSHFS at login
EOF
```

> [!TIP]
> Монтирование только после входа конкретного пользователя, а не при загрузке системы.

---

## 🔑 6. Аутентификация по SSH-ключам

```bash
# Генерация ключа (если нет)
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_sshfs -C "sshfs-mount"

# Копирование ключа на сервер
ssh-copy-id -i ~/.ssh/id_rsa_sshfs.pub user@192.168.1.100

# Проверка подключения
ssh -i ~/.ssh/id_rsa_sshfs user@192.168.1.100

# Монтирование с ключом
sshfs -o identityfile=~/.ssh/id_rsa_sshfs user@192.168.1.100:/remote/path ~/mnt/remote
```

> [!TIP]
> Безопасная аутентификация без ввода пароля, необходимо для автоматического монтирования.

### Настройка SSH-агента

```bash
# Добавление ключа в агент
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa_sshfs

# Для постоянного добавления добавьте в ~/.bash_profile:
if [ -z "$SSH_AUTH_SOCK" ]; then
    SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
    export SSH_AUTH_SOCK
fi
```

---

## 🔍 7. Диагностика и проблемы

```bash
# Проверка монтирования
mount | grep sshfs
df -h | grep sshfs

# Просмотр логов
journalctl -u sshfs-remote.mount -f

# Тестирование подключения
ssh -v user@192.168.1.100

# Проверка FUSE
lsmod | grep fuse

# Если монтирование не работает:
# 1. Проверьте /etc/fuse.conf
cat /etc/fuse.conf

# 2. Разрешите allow_other (если нужно)
echo "user_allow_other" | sudo tee -a /etc/fuse.conf

# 3. Перезапустите службу
sudo systemctl daemon-reload
sudo systemctl restart sshfs-remote.mount
```

> [!TIP]
> Быстрое выявление и устранение проблем с монтированием.

### Частые ошибки

| Ошибка | Решение |
| ------ | ------- |
| `Permission denied` | Проверьте права на SSH-ключ (chmod 600) |
| `Connection refused` | Проверьте доступность сервера и порт SSH |
| `fuse: device not found` | Установите `fuse` и загрузите модуль `modprobe fuse` |
| `mount: wrong fs type` | Проверьте установку пакета `sshfs` |

---

## ⚡ 8. Полезные команды

| Команда | Описание |
| ------- | -------- |
| `sshfs host:/path /mnt/point` | Смонтировать удалённую папку |
| `fusermount -u /mnt/point` | Размонтировать SSHFS |
| `mount | grep sshfs` | Показать смонтированные SSHFS |
| `sshfs -o ssh_command=ssh user@host:/path /mnt` | Монтирование с опциями SSH |
| `sshfs -o reconnect host:/path /mnt` | Автоматическое переподключение |
| `sshfs -o cache_timeout=300 host:/path /mnt` | Кэширование на 5 минут |

---

## 🎯 Лайфхаки

### 🔹 Быстрое монтирование с кэшированием

```bash
sshfs -o cache_timeout=600,reconnect,ServerAliveInterval=15 \
    user@192.168.1.100:/remote/path ~/mnt/remote
```

> [!TIP]
> Ускоряет работу с файлами и поддерживает соединение активным.

### 🔹 Монтирование нескольких папок одним скриптом

```bash
#!/bin/bash
SERVER="user@192.168.1.100"
KEY="~/.ssh/id_rsa"

declare -a MOUNTS=(
    "/home/user/docs:~/mnt/docs"
    "/home/user/projects:~/mnt/projects"
    "/var/shared:~/mnt/shared"
)

for mount_pair in "${MOUNTS[@]}"; do
    remote=$(echo $mount_pair | cut -d: -f1)
    local=$(echo $mount_pair | cut -d: -f2)
    mkdir -p $local
    sshfs -o identityfile=$KEY,reconnect $SERVER$remote $local
    echo "Смонтировано: $local"
done
```

### Проверка доступности перед монтированием

```bash
#!/bin/bash
SERVER="192.168.1.100"
USER="user"

if ping -c 1 -W 2 $SERVER &>/dev/null; then
    sshfs $USER@$SERVER:/remote/path ~/mnt/remote
    echo "✓ Успешно"
else
    echo "✗ Сервер недоступен"
    exit 1
fi
```

### Автоматическое размонтирование при бездействии

```bash
# Размонтирование после 5 минут бездействия
sshfs -o idle=300 user@192.168.1.100:/remote/path ~/mnt/remote
```

> [!TIP]
> Экономия ресурсов, соединение закрывается автоматически.

### Монтирование с сжатием данных

```bash
sshfs -o compression=yes user@192.168.1.100:/remote/path ~/mnt/remote
```

> [!TIP]
> Уменьшает трафик при работе через медленные каналы связи.

### Безопасное размонтирование при завершении сессии

```bash
# Добавьте в ~/.bash_logout
fusermount -u ~/mnt/remote 2>/dev/null || true
```

### Проверка состояния всех SSHFS монтирований

```bash
for mount_point in $(mount | grep sshfs | awk '{print $3}'); do
    if [ -d "$mount_point" ]; then
        echo -e "\033[0;32m✓\033[0m $mount_point - доступен"
    else
        echo -e "\033[0;31m✗\033[0m $mount_point - недоступен"
    fi
done
```

---

## 🤖 9. Автоматическая настройка скриптом

Для автоматической настройки автомонтирования SSHFS используйте скрипт `automount-sshfs.sh`.

### 📥 Запуск скрипта

```bash
# Скачать и выполнить скрипт
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/automount-sshfs.sh | sudo bash

# Или скачать и запустить вручную
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/automount-sshfs.sh
chmod +x automount-sshfs.sh
sudo ./automount-sshfs.sh
```

> [!IMPORTANT]
> Скрипт требует прав root и предназначен для РЕД ОС. Возможно использование в других дистрибутивах на основе RPM (CentOS, Fedora, AlmaLinux).

### 🔧 Описание работы

Скрипт выполняет следующие действия:

1. **Сбор информации о подключении**
   - Запрашивает пользователя SSH
   - Запрашивает хост (IP или домен)
   - Запрашивает порт SSH (по умолчанию 22)
   - Запрашивает удалённый и локальный пути

2. **Проверка и установка SSHFS**
   - Проверяет наличие установленного SSHFS
   - При необходимости устанавливает пакеты `sshfs` и `fuse`
   - Проверяет и загружает модуль FUSE

3. **Настройка SSH-ключей**
   - Генерирует новый ключ `id_rsa_sshfs` (если нет)
   - Копирует публичный ключ на сервер через `ssh-copy-id`
   - Проверяет подключение к серверу

4. **Выбор метода автомонтирования**
   - `/etc/fstab` — классический способ
   - `systemd` — современный способ с контролем состояния
   - Автозагрузка пользователя — монтирование при входе в сессию

5. **Дополнительные опции**
   - Проверка доступности сервера (ping)
   - Проверка SSH-порта
   - Вывод полезных команд для управления

### 📋 Примеры работы

#### Пример 1: Настройка через systemd

```bash
========================================
[INFO] Настройка автомонтирования SSHFS в РЕД ОС
========================================

[ШАГ] Сбор информации о подключении

Параметры SSH подключения:
  Пользователь SSH [teanr]: teanr
  Хост (IP или домен): 192.168.1.100
  Порт SSH [22]: 22
  Удалённый путь [/home/teanr]: /home/teanr/data
  Локальная точка монтирования [/home/teanr/mnt/remote]: /home/teanr/mnt/remote

  Параметры подключения:
    Хост: 192.168.1.100
    Пользователь: teanr
    Порт: 22
    Удалённый путь: /home/teanr/data
    Локальный путь: /home/teanr/mnt/remote

Подтверждаете параметры подключения? (y/n): y
```

#### Пример 2: Генерация SSH-ключа

```bash
========================================
[ШАГ] Настройка SSH-ключей
========================================

[INFO] SSH-ключ не найден
Сгенерировать новый SSH-ключ для SSHFS? (y/n): y

Generating public/private ed25519 key pair.
✓ SSH-ключ сгенерирован
✓ Права на SSH-ключ установлены

Скопировать SSH-ключ на сервер (teanr@192.168.1.100)? (y/n): y

[INFO] Копирование ключа на сервер...
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/teanr/.ssh/id_rsa_sshfs.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key, and to discard any existing keys
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
✓ SSH-ключ скопирован на сервер
```

#### Пример 3: Выбор метода монтирования

```bash
========================================
[ШАГ] Выбор метода автомонтирования
========================================

Доступные методы:
  1) /etc/fstab - классический способ
  2) systemd - современный способ с контролем состояния
  3) Автозагрузка пользователя - монтирование при входе в сессию
  4) Пропустить автомонтирование

  Выберите метод [1-4]: 2

[INFO] Настройка автомонтирования через systemd

✓ Точка монтирования создана: /home/teanr/mnt/remote
✓ Юнит-файл создан: /etc/systemd/system/home-teanr-mnt-remote.mount

Включить и запустить службу монтирования? (y/n): y

✓ Служба монтирования запущена

[INFO] Статус службы:
● home-teanr-mnt-remote.mount - SSHFS mount for teanr@192.168.1.100:/home/teanr/data
     Loaded: loaded (/etc/systemd/system/home-teanr-mnt-remote.mount; enabled)
     Active: active (mounted) since Tue 2026-03-31 10:00:00 MSK
```

### 📤 Результаты работы скрипта

После завершения скрипт выводит:

```bash
========================================
[INFO] Настройка завершена!
========================================

Параметры подключения:
  Хост: 192.168.1.100
  Пользователь: teanr
  Порт: 22
  Удалённый путь: /home/teanr/data
  Локальный путь: /home/teanr/mnt/remote
  SSH-ключ: /home/teanr/.ssh/id_rsa_sshfs

Полезные команды:
  mount | grep sshfs              # проверить смонтированные SSHFS
  fusermount -u /home/teanr/mnt/remote       # размонтировать
  sshfs teanr@192.168.1.100:/home/teanr/data /home/teanr/mnt/remote  # смонтировать вручную
  journalctl -u home-teanr-mnt-remote.mount -f  # логи systemd (если используется)

Для управления службой используйте:
  systemctl status home-teanr-mnt-remote.mount
  systemctl restart home-teanr-mnt-remote.mount

[INFO] Готово!
```

### ⚙️ Параметры скрипта

| Параметр | Описание |
| -------- | -------- |
| `SSH_USER` | Пользователь для подключения по SSH |
| `SSH_HOST` | Хост (IP-адрес или доменное имя) |
| `SSH_PORT` | Порт SSH (по умолчанию 22) |
| `REMOTE_PATH` | Путь к удалённой директории |
| `LOCAL_PATH` | Локальная точка монтирования |
| `SSH_KEY_PATH` | Путь к SSH-ключу для аутентификации |

> [!NOTE]
> Все параметры задаются интерактивно в ходе выполнения скрипта. Каждое действие требует подтверждения пользователя.

### 🔍 Диагностика

Если скрипт не работает:

```bash
# Проверка логов
journalctl -xe | grep sshfs

# Проверка установленного SSHFS
rpm -qa | grep sshfs

# Проверка модуля FUSE
lsmod | grep fuse

# Проверка SSH-подключения
ssh -i ~/.ssh/id_rsa_sshfs user@host
```

---

## 🔗 Ссылки

- [Официальная документация SSHFS](https://github.com/libfuse/sshfs)
- [FUSE Documentation](https://libfuse.github.io/)
- [RED OS База знаний](https://redos.red-soft.ru/base/)

---

## 📋 Требования и совместимость

| Параметр | Значение |
| -------- | -------- |
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | любая |
| **Права** | root (установка sshfs), пользователь (монтирование) |
| **Скрипт** | [`automount-sshfs.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/automount-sshfs.sh) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x может потребоваться `fuse3` вместо `fuse`.
> Скрипт поддерживает три метода: fstab, systemd, автозагрузка.
