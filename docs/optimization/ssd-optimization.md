# 🚀 Оптимизация работы с SSD в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Содержание

1. [Проверка и настройка TRIM](#1-проверка-и-настройка-trim)
2. [Оптимизация монтирования (fstab)](#2-оптимизация-монтирования-fstab)
3. [Настройка планировщика ввода-вывода](#3-настройка-планировщика-ввода-вывода)
4. [Управление swap на SSD](#4-управление-swap-на-ssd)
5. [Оптимизация журналирования](#5-оптимизация-журналирования)
6. [Настройка кэширования и temp](#6-настройка-кэширования-и-temp)
7. [Мониторинг здоровья SSD](#7-мониторинг-здоровья-ssd)
8. [Быстрая диагностика одним скриптом](#8-быстрая-диагностика-одним-скриптом)


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
## 3. Настройка планировщика ввода-вывода
Проверка текущего планировщика
```bash
# Для каждого диска
cat /sys/block/sda/queue/scheduler
cat /sys/block/nvme0n1/queue/scheduler
```
Рекомендуемые планировщики
| Тип SSD    | Рекомендуемый планировщик |
| :--------- | :------------------------ |
| NVMe       | none (или noop)           |
| SATA SSD   | mq-deadline или kyber     |
| Старые SSD | deadline                  |
Настройка планировщика через `udev`  
Создайте правило `udev`:
```bash
sudo nano /etc/udev/rules.d/60-ssd-scheduler.rules

# Для NVMe дисков
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"

# Для SATA SSD (определяем по ротации)
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
```
Применить правило:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```
Оптимизация очереди
```bash
# Увеличить глубину очереди (для NVMe)
echo 1024 > /sys/block/nvme0n1/queue/nr_requests

# Оптимизация для NVMe
echo 0 > /sys/block/nvme0n1/queue/add_random
echo 2 > /sys/block/nvme0n1/queue/rq_affinity

# Сделать изменения постоянными через udev
```
---
## 4. Управление swap на SSD
Снижение использования swap
```bash
# Уменьшить swappiness (0-100, по умолчанию 60)
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Еще более агрессивно (для систем с большим количеством RAM)
echo "vm.swappiness=5" | sudo tee -a /etc/sysctl.conf

# Применить
sudo sysctl -p
```
Альтернатива swap на SSD
```bash
# Использовать zram вместо swap на SSD (компрессия в RAM)
sudo dnf install zram-generator

# Создать конфиг /etc/systemd/zram-generator.conf
cat << EOF | sudo tee /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

# Перезапустить сервис
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
```
Если swap все же нужен
```bash
# Уменьшить "старение" swap-файла
# Добавить в /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=10" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf
```
---
## 5. Оптимизация журналирования
Уменьшение записи на SSD
```bash
# Настройка rsyslog для снижения дисковых операций
sudo nano /etc/rsyslog.conf

# Добавить в начало файла
$RepeatedMsgReduction on
$IMUXSockRateLimitInterval 5
$IMUXSockRateLimitBurst 100
```
Настройка `journald`
```bash
sudo nano /etc/systemd/journald.conf
ini
[Journal]
# Ограничить размер журнала
SystemMaxUse=500M
RuntimeMaxUse=100M

# Компрессия для экономии места
Compress=yes

# Перенаправить журнал в RAM
Storage=auto

# Синхронизация с диском реже
SyncIntervalSec=10m

sudo systemctl restart systemd-journald
```
Использование tmpfs для временных файлов
```bash
# В /etc/fstab добавить
tmpfs /tmp tmpfs defaults,noexec,nosuid,size=2G 0 0
tmpfs /var/tmp tmpfs defaults,noexec,nosuid,size=1G 0 0
```
---
## 6. Настройка кэширования и temp
Настройка Firefox/Chromium для работы с SSD
```bash
# Перенаправить кэш браузера в RAM
mkdir -p /tmp/firefox-cache
chmod 700 /tmp/firefox-cache

# В Firefox: about:config -> browser.cache.disk.parent_directory = /tmp/firefox-cache
```
Настройка Docker (если используется)
```bash
# В /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "journald"
}
```
Оптимизация временных файлов
```bash
# Создать скрипт очистки temp-файлов
cat << 'EOF' | sudo tee /usr/local/bin/clean-temp.sh
#!/bin/bash
# Очистка старых файлов из /tmp (старше 10 дней)
find /tmp -type f -atime +10 -delete 2>/dev/null
find /tmp -type d -empty -delete 2>/dev/null

# Очистка кэша пользователей
for user in /home/*; do
    if [ -d "$user/.cache" ]; then
        find "$user/.cache" -type f -atime +30 -delete 2>/dev/null
    fi
done
EOF

sudo chmod +x /usr/local/bin/clean-temp.sh

# Добавить в cron (еженедельно)
echo "0 2 * * 0 /usr/local/bin/clean-temp.sh" | sudo crontab -
```
---
## 7. Мониторинг здоровья SSD
Установка `smartmontools`
```bash
sudo dnf install smartmontools -y
```
Проверка статуса SSD
```bash
# Общая информация о диске
sudo smartctl -i /dev/nvme0n1

# Показать SMART атрибуты
sudo smartctl -A /dev/nvme0n1

# Запустить короткий тест
sudo smartctl -t short /dev/nvme0n1

# Посмотреть результаты теста
sudo smartctl -l selftest /dev/nvme0n1

# Полная диагностика
sudo smartctl -x /dev/nvme0n1 | grep -E "Percentage|Data Units|Power|Temperature"
```
Ключевые параметры для NVMe
| Параметр           | Описание          | Норма            |
| :----------------- | :---------------- | :--------------- |
| Percentage Used    | Износ SSD         | < 10% для нового |
| Data Units Written | Записанные данные | Мониторить рост  |
| Power On Hours     | Время работы      | Мониторить       |
| Temperature        | Температура       | < 70°C           |
| Available Spare    | Резервные блоки   | > 50%            |
Включение мониторинга
```bash
# Включить демон мониторинга
sudo systemctl enable smartd
sudo systemctl start smartd

# Настроить уведомления /etc/smartd.conf
echo "DEVICESCAN -a -o on -S on -s (S/../.././02|L/../../7/03) -m root" | sudo tee /etc/smartd.conf
```
---
## 8. Быстрая диагностика одним скриптом
```bash
#!/bin/bash
# ssd-optimize.sh - Быстрая диагностика и оптимизация SSD

echo "=== SSD Diagnostic & Optimization ==="

# 1. Проверка типа диска
echo -e "\n1. Типы дисков:"
lsblk -d -o NAME,ROTA | grep -v "loop"

# 2. Статус TRIM
echo -e "\n2. TRIM статус:"
sudo systemctl status fstrim.timer --no-pager | grep -E "Active|Trigger"

# 3. Параметры монтирования
echo -e "\n3. Параметры монтирования:"
mount | grep -E "^/dev" | grep -v "tmpfs"

# 4. Планировщики ввода-вывода
echo -e "\n4. Текущие планировщики:"
for disk in /sys/block/sd* /sys/block/nvme*; do
    if [ -f "$disk/queue/scheduler" ]; then
        echo "$(basename $disk): $(cat $disk/queue/scheduler)"
    fi
done

# 5. Настройки swappiness
echo -e "\n5. Swappiness: $(cat /proc/sys/vm/swappiness)"

# 6. SMART статус
echo -e "\n6. SMART статус SSD:"
for disk in /dev/sd? /dev/nvme?n1; do
    if [ -e "$disk" ]; then
        echo -n "$disk: "
        sudo smartctl -H $disk 2>/dev/null | grep "SMART overall-health" | awk -F': ' '{print $2}'
    fi
done

# 7. Записанные данные (для NVMe)
echo -e "\n7. Записанные данные на NVMe:"
for disk in /dev/nvme?n1; do
    if [ -e "$disk" ]; then
        written=$(sudo nvme smart-log $disk 2>/dev/null | grep "data_units_written" | awk '{print $3}')
        if [ -n "$written" ]; then
            gb_written=$((written * 512 / 1024 / 1024 / 1024))
            echo "$disk: ~${gb_written} GB записано"
        fi
    fi
done

# 8. Рекомендации
echo -e "\n8. Рекомендации:"
if [ $(cat /proc/sys/vm/swappiness) -gt 20 ]; then
    echo "⚠️  Уменьшите swappiness: echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf"
fi
if ! systemctl is-enabled fstrim.timer &>/dev/null; then
    echo "⚠️  Включите TRIM: sudo systemctl enable --now fstrim.timer"
fi
```
---
## 🎯 Чек-лист оптимизации SSD
| Действие                       | Команда                                  | Приоритет |
| :----------------------------- | :--------------------------------------- | :-------- |
| ✅ Включить fstrim.timer       | sudo systemctl enable --now fstrim.timer | Высокий   |
| ✅ Добавить noatime в fstab    | sudo nano /etc/fstab                     | Высокий   |
| ✅ Настроить планировщик       | udev правило                             | Средний   |
| ✅ Уменьшить swappiness        | vm.swappiness=10                         | Средний   |
| ✅ Настроить journald          | sudo nano /etc/systemd/journald.conf     | Низкий    |
| ✅ Использовать tmpfs для /tmp | добавить в fstab                         | Низкий    |
| ✅ Включить мониторинг SMART   | sudo systemctl enable smartd             | Низкий    |
>⚠️ **Важные предостережения**
>- Всегда делайте резервную копию перед изменением fstab
>- Тестируйте параметры на тестовой системе перед применением на production
>- Мониторьте износ SSD регулярно, особенно после изменений
>- Не используйте discard в fstab на системах с LVM/LUKS без необходимости
>- Проверяйте логи после изменений: journalctl -xe | grep -i "ssd\|trim"

**Эти лайфхаки помогут продлить жизнь SSD, увеличить производительность системы и снизить нагрузку на диск в РЕД ОС 7.3.**

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Накопители** | SSD (SATA, NVMe) |
| **Утилиты** | `smartmontools`, `fstrim`, `hdparm`, `nvme-cli` |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x `fstrim.timer` обычно включён по умолчанию. Для NVMe-накопителей используйте `nvme-cli` вместо `hdparm` для мониторинга SMART.
