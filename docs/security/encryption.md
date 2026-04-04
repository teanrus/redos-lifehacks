# 🔐 Шифрование домашней папки в Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

>Шифрование домашней директории — один из лучших способов защитить личные данные при потере или краже устройства. Вот несколько лайфхаков по настройке и использованию различных методов шифрования.
---
## 📋 Содержание
1. [Выбор метода шифрования](#1-выбор-метода-шифрования)
2. [LUKS/dm-crypt — полное шифрование раздела](#2-luksdm-crypt--полное-шифрование-раздела)
3. [fscrypt — современное встроенное шифрование](#3-fscrypt--современное-встроенное-шифрование)
4. [gocryptfs — простое шифрование папок](#4-gocryptfs--простое-шифрование-папок)
5. [Автоматическое монтирование при входе (PAM)](#5-автоматическое-монтирование-при-входе-pam)
6. [Шифрование отдельных папок с Plasma Vault](#6-шифрование-отдельных-папок-с-plasma-vault)
7. [Скрипт настройки](#7-скрипт-настройки)
---
## 1. Выбор метода шифрования
В современном Linux есть несколько подходов к шифрованию. Вот их сравнение:
| Метод         | Уровень        | Преимущества                                 | Недостатки                                      | Производительность        |
| :------------ | :------------- | :------------------------------------------- | :---------------------------------------------- | :------------------------ |
| LUKS/dm-crypt | Весь раздел    | Максимальная защита, шифрование метаданных   | Требует отдельного раздела, пароль при загрузке | ⭐⭐⭐⭐⭐ (3-10% потерь) |
| fscrypt       | Каталог        | Встроен в ядро, высокая производительность   | Только ext4/f2fs, метаданные не шифруются       | ⭐⭐⭐⭐⭐ (<5% потерь)   |
| gocryptfs     | Каталог (FUSE) | Прост в использовании, скрывает имена файлов | Зависит от FUSE, накладные расходы              | ⭐⭐⭐⭐ (20-35% потерь)  |
| CryFS         | Каталог (FUSE) | Скрывает структуру каталогов                 | Низкая скорость записи                          | ⭐⭐⭐ (80 МБ/с запись)   |
| eCryptfs      | Каталог        | Старый стандарт Ubuntu                       | ⚠️ НЕ ПОДДЕРЖИВАЕТСЯ                          | ⭐⭐⭐ (15-40% потерь)    |
>⚠️ **Важно:**  
>eCryptfs больше не поддерживается разработчиками ядра и обсуждается его полное удаление . Используйте современные альтернативы.
---
## 2. LUKS/dm-crypt — полное шифрование раздела
Создание зашифрованного раздела для /home
```bash
# 1. Перейти в однопользовательский режим (закрыть все сессии пользователя)
sudo telinit 1
# 2. Размонтировать /home
sudo umount /home
# 3. Убить процессы, использующие /home
sudo fuser -mvk /home
# 4. Заполнить раздел случайными данными (ВАЖНО! Без этого данные могут быть восстановлены)
sudo shred -v --iterations=1 /dev/sdaX  # замените на ваш раздел
# 5. Инициализировать LUKS (рекомендуемые параметры)
sudo cryptsetup --verbose --verify-passphrase --cipher aes-xts-plain64 --key-size 512 luksFormat /dev/sdaX
# 6. Открыть зашифрованный раздел
sudo cryptsetup luksOpen /dev/sdaX home
# 7. Создать файловую систему
sudo mkfs.ext4 /dev/mapper/home
# 8. Смонтировать
sudo mount /dev/mapper/home /home
# 9. Восстановить SELinux контексты (если включен)
sudo restorecon -v -R /home
```
Настройка автоматического открытия при загрузке  
Добавьте в `/etc/crypttab`:
```bash
# /etc/crypttab
home /dev/sdaX none
```
Добавьте в `/etc/fstab`:
```bash
# /etc/fstab
/dev/mapper/home /home ext4 defaults,noatime 1 2
```
**Лайфхак: ключевой файл для автоматической разблокировки**
```bash
# Создать ключевой файл (256 бит)
sudo dd if=/dev/urandom of=/root/home.key bs=4096 count=1
# Добавить ключ в LUKS
sudo cryptsetup luksAddKey /dev/sdaX /root/home.key
# Настроить /etc/crypttab
echo "home /dev/sdaX /root/home.key" | sudo tee -a /etc/crypttab
```
---
## 3. fscrypt — современное встроенное шифрование
Установка и настройка
```bash
# Установка
sudo dnf install fscrypt
# Инициализация fscrypt
sudo fscrypt setup
# Создание защищенной директории
sudo mkdir -p /home/user/Private
sudo fscrypt encrypt /home/user/Private
```
**Лайфхак: шифрование существующей папки**
```bash
# Создать временную папку для переноса данных
mkdir ~/temp_private
cp -r ~/Secret ~/temp_private/
# Очистить исходную папку
rm -rf ~/Secret/*
# Зашифровать папку
sudo fscrypt encrypt ~/Secret --user=username
# Вернуть данные обратно
cp -r ~/temp_private/* ~/Secret/
```
Настройка автоматической разблокировки при входе
```bash
# Установить пароль, совпадающий с логином
fscrypt lock ~/Secret
fscrypt unlock ~/Secret --user=username
# Настроить PAM для автоматической разблокировки
sudo nano /etc/pam.d/system-login
```
```bash
# Добавить в конец файла
session optional pam_fscrypt.so
```
---
## 4. gocryptfs — простое шифрование папок
Установка и базовое использование
```bash
# Установка
sudo dnf install gocryptfs
# Инициализация зашифрованной папки (создает папку .gocryptfs)
gocryptfs -init ~/Encrypted
# При запросе: введите пароль
# Создание папки для монтирования
mkdir ~/Private
# Монтирование
gocryptfs ~/Encrypted ~/Private
# Введите пароль
```
**Лайфхак: `reverse mode` (шифрование существующих файлов)**
```bash
# Reverse mode — файлы остаются на месте, но шифруются "на лету"
mkdir ~/Encrypted-View
gocryptfs -reverse ~/Documents ~/Encrypted-View
# Теперь в ~/Encrypted-View вы видите зашифрованные имена файлов
# Идеально для облачных бэкапов
```
Автоматическое монтирование  
Добавьте в `~/.bashrc`:
```bash
# Автоматическое монтирование при входе в shell
if [ ! -d ~/Private ]; then
    mkdir -p ~/Private
fi

if [ ! -f ~/.gocryptfs.mounted ]; then
    gocryptfs ~/Encrypted ~/Private
    touch ~/.gocryptfs.mounted
fi
```
---
## 5. Автоматическое монтирование при входе (PAM)
Настройка PAM для LUKS с одинаковым паролем  
Создайте скрипт `/etc/pam_cryptsetup.sh` :
```bash
#!/bin/sh
# /etc/pam_cryptsetup.sh
CRYPT_USER="username"
PARTITION="/dev/sdaX"
NAME="home-$CRYPT_USER"
if [ "$PAM_USER" = "$CRYPT_USER" ] && ! [ -e "/dev/mapper/$NAME" ]; then
    echo "$PAM_AUTHTOK" | /usr/bin/cryptsetup open "$PARTITION" "$NAME"
fi
```
```bash
sudo chmod +x /etc/pam_cryptsetup.sh
```
Добавьте в `/etc/pam.d/system-login`:
```bash
auth       include    system-auth
auth       optional   pam_exec.so expose_authtok /etc/pam_cryptsetup.sh
```
Настройка `systemd` для автоматической монтировки  
Создайте `/etc/systemd/system/home-username.mount`:
```bash
[Unit]
Requires=user@1000.service
Before=user@1000.service
[Mount]
Where=/home/username
What=/dev/mapper/home-username
Type=ext4
Options=defaults,noatime
[Install]
RequiredBy=user@1000.service
```
Включите:
```bash
sudo systemctl enable home-username.mount
```
---
## 6. Шифрование отдельных папок с Plasma Vault
Для пользователей KDE Plasma есть удобный инструмент Plasma Vault, который поддерживает gocryptfs и CryFS :
```bash
# Установка
sudo dnf install plasma-vault
# Использование через GUI:
# Системные настройки -> Рабочий стол -> Vaults
# Создать новый хранилище, выбрать gocryptfs
```
---
## 7. Скрипт настройки
```bash
#!/bin/bash
# home-encrypt-setup.sh - Быстрая настройка шифрования домашней папки
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
echo -e "${GREEN}=== Настройка шифрования домашней папки ===${NC}"
# Выбор метода
echo -e "\n${YELLOW}Выберите метод шифрования:${NC}"
echo "  1) LUKS/dm-crypt (весь раздел /home) — максимальная защита"
echo "  2) fscrypt (отдельная папка) — высокая производительность"
echo "  3) gocryptfs (отдельная папка) — простота и совместимость"
read -p "Выберите (1-3): " method
case $method in
    1)
        echo -e "\n${YELLOW}LUKS шифрование раздела /home${NC}"
        read -p "Введите раздел для шифрования (например, /dev/sda5): " partition
        # Проверка, что раздел не смонтирован
        if mount | grep -q "$partition"; then
            echo -e "${RED}Раздел смонтирован. Размонтируйте его вручную.${NC}"
            exit 1
        fi
        echo "Заполнение раздела случайными данными (может занять много времени)..."
        sudo shred -v --iterations=1 "$partition"
        echo "Инициализация LUKS..."
        sudo cryptsetup --verbose --cipher aes-xts-plain64 --key-size 512 luksFormat "$partition"
        echo "Открытие раздела..."
        sudo cryptsetup luksOpen "$partition" home
        echo "Создание файловой системы..."
        sudo mkfs.ext4 /dev/mapper/home
        echo "Монтирование..."
        sudo mount /dev/mapper/home /home
        echo "Настройка автозагрузки..."
        echo "home $partition none" | sudo tee -a /etc/crypttab
        echo "/dev/mapper/home /home ext4 defaults,noatime 1 2" | sudo tee -a /etc/fstab
        echo -e "${GREEN}✓ LUKS настройка завершена${NC}"
        ;;
    2)
        echo -e "\n${YELLOW}fscrypt настройка${NC}"
        read -p "Введите путь для зашифрованной папки (например, /home/username/Private): " folder
        sudo dnf install fscrypt -y
        sudo fscrypt setup
        sudo mkdir -p "$folder"
        sudo fscrypt encrypt "$folder"
        echo -e "${GREEN}✓ fscrypt настройка завершена${NC}"
        echo "Для монтирования: fscrypt unlock $folder"
        ;;
    3)
        echo -e "\n${YELLOW}gocryptfs настройка${NC}"
        read -p "Введите путь для хранилища (например, /home/username/Encrypted): " store
        read -p "Введите путь для монтирования (например, /home/username/Private): " mount
        sudo dnf install gocryptfs -y
        mkdir -p "$store" "$mount"
        gocryptfs -init "$store"
        echo "Добавьте в ~/.bashrc:"
        echo "gocryptfs $store $mount"
        
        echo -e "${GREEN}✓ gocryptfs настройка завершена${NC}"
        ;;
    *)
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
        ;;
esac
echo -e "\n${GREEN}=== Настройка завершена ===${NC}"
echo "Не забудьте сохранить пароли в надежном месте!"
```
---
## 🎯 Чек-лист
| Действие         | Команда                              | Эффект                       |
| :--------------- | :----------------------------------- | :--------------------------- |
| ✅ Выбрать метод | из таблицы выше                      | Соответствие потребностям    |
| ✅ Для LUKS      | sudo cryptsetup luksFormat /dev/sdaX | Шифрование раздела           |
| ✅ Для fscrypt   | sudo fscrypt encrypt ~/Private       | Шифрование папки             |
| ✅ Для gocryptfs | gocryptfs -init ~/Encrypted          | Создание хранилища           |
| ✅ Настроить PAM | добавить pam_exec                    | Автоматическая разблокировка |
| ✅ Сделать бэкап | сохранить ключи                      | Восстановление данных        |
## 💡 Бонусные советы
1. Резервное копирование ключей LUKS
```bash
# Сохранить заголовок LUKS (критически важно!)
sudo cryptsetup luksHeaderBackup /dev/sdaX --header-backup-file luks-header.backup
# Восстановление
sudo cryptsetup luksHeaderRestore /dev/sdaX --header-backup-file luks-header.backup
```
2. Добавление дополнительного пароля
```bash
# Добавить новый пароль к LUKS
sudo cryptsetup luksAddKey /dev/sdaX
```
3. Проверка статуса LUKS
```bash
sudo cryptsetup luksDump /dev/sdaX
```
4. Использование TPM для автоматической разблокировки (при наличии)
```bash
# Установка поддержки TPM
sudo dnf install clevis clevis-luks
# Привязка LUKS к TPM
sudo clevis luks bind -d /dev/sdaX tpm2 '{"pcr_ids":"7"}'
```
>**⚠️ Важные предостережения**  
>- Всегда делайте бэкап ключей и паролей — потеря пароля = потеря всех данных
>- eCryptfs не поддерживается — не используйте его для новых установок 
>- LUKS шифрует только при выключенном ПК — при работе данные расшифрованы 
>- Тестируйте восстановление — убедитесь, что можете расшифровать данные из бэкапа
>- Для SSD с TRIM — используйте discard осторожно, так как это может снизить безопасность
---
**Эти лайфхаки помогут вам настроить надежное шифрование домашней папки. Выберите метод в зависимости от ваших потребностей: LUKS для максимальной защиты, fscrypt для производительности, gocryptfs для простоты и гибкости.**

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Шифрование** | LUKS/dm-crypt, fscrypt, gocryptfs |
| **Пакеты** | `cryptsetup`, `fscrypt`, `gocryptfs` |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x fscrypt поддерживает только ext4 и f2fs. Для LUKS2 используйте `cryptsetup 2.x`. gocryptfs требует FUSE, который доступен в стандартных репозиториях.