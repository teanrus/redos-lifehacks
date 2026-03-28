# 🚀 Оптимизация работы с SSD в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

📋 Содержание
1. Проверка и настройка TRIM
2. Оптимизация монтирования (fstab)
3. Настройка планировщика ввода-вывода
4. Управление swap на SSD
5. Оптимизация журналирования
6. Настройка кэширования и temp
7. Мониторинг здоровья SSD
8. Быстрая диагностика одним скриптом
---
## 1. Проверка и настройка TRIM
Проверка поддержки `TRIM`
```bash
# Проверить, поддерживает ли SSD TRIM
sudo hdparm -I /dev/nvme0n1 | grep -i "TRIM supported"
# Для SATA SSD
sudo hdparm -I /dev/sda | grep -i "TRIM supported"

# Проверить текущий статус TRIM
sudo systemctl status fstrim.timer
```
Включение автоматического `TRIM`
```bash
# Включить и запустить таймер TRIM (еженедельная очистка)
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Проверить расписание
sudo systemctl list-timers | grep fstrim

# Ручной запуск TRIM
sudo fstrim -av
```
Настройка `TRIM` для `LVM` и `LUKS`
```bash
# Для LVM в /etc/lvm/lvm.conf
issue_discards = 1

# Для LUKS в /etc/crypttab (добавить опцию discard)
# Пример: cryptroot UUID=xxx none luks,discard

# После изменений обновить initramfs
sudo dracut --force --regenerate-all
```
---
