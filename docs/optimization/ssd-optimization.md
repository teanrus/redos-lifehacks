🚀 **Оптимизация работы с SSD в РЕД ОС**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

📋 **Содержание**

1. [Проверка и настройка TRIM](#проверка-и-настройка-trim)
2. [Оптимизация монтирования (fstab)](#оптимизация-монтирования-fstab)
3. [Настройка планировщика ввода-вывода](#настройка-планировщика-ввода-вывода)
4. [Управление swap на SSD](#управление-swap-на-ssd)
5. [Оптимизация журналирования](#оптимизация-журналирования)
6. [Настройка кэширования и temp](#настройка-кэширования-и-temp)
7. [Мониторинг здоровья SSD](#мониторинг-здоровья-ssd)
8. [Быстрая диагностика одним скриптом](#быстрая-диагностика-одним-скриптом)

---
# 1. Проверка и настройка TRIM
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
## 2. Оптимизация монтирования (fstab)
Оптимальные параметры для SSD  
Отредактируйте `/etc/fstab:`

```bash
sudo nano /etc/fstab
ini
# Пример для корневого раздела (ext4)
UUID=xxx-xxx-xxx / ext4 defaults,noatime,nodiratime,discard,errors=remount-ro 0 1

# Пример для домашнего раздела
UUID=yyy-yyy-yyy /home ext4 defaults,noatime,nodiratime,discard 0 2

# Пример для XFS (если используется)
UUID=zzz-zzz-zzz / xfs defaults,noatime,nodiscard 0 0
```
Параметры монтирования для SSD
| Параметр   | Описание                                     | Рекомендация             |
| :--------- | :------------------------------------------- | :----------------------- |
| noatime    | Не обновлять время доступа к файлам          | ✅ Всегда                |
| nodiratime | Не обновлять время доступа к каталогам       | ✅ Всегда                |
| discard    | Включает TRIM при удалении файлов            | ⚠️ Внимание (см. ниже) |
| relatime   | Обновлять время доступа только при изменении | ✅ Альтернатива noatime  |
| barrier=0  | Отключает барьеры (рискованно)               | ❌ Не рекомендуется      |

> ⚠️ **Важно про discard**
> 
> Параметр `discard` в `fstab` может снижать производительность на некоторых SSD из‑за частых операций TRIM в реальном времени.
> 
> **Рекомендация:** используйте периодический TRIM:
> ```bash
> sudo fstrim -v /
> ```
> Запланируйте выполнение через `cron` или `systemd timer`.


Применение изменений
```bash
# Проверить конфигурацию fstab
sudo mount -a

# Перемонтировать разделы с новыми параметрами
sudo mount -o remount /

# Проверить примененные параметры
mount | grep "^/dev"
```
---

