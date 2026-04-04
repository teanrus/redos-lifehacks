# 📊 Диагностика состояния системы в РЕД ОС

> Полное руководство по проверке всех компонентов системы: CPU, RAM, диски, сеть, сервисы, обновления, безопасность, температура, загрузка, пользователи, резервные копии. Включает автоматические скрипты и генерацию отчётов.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

---

## Оглавление

1. [Экспресс-диагностика (30 секунд)](#-экспресс-диагностика-30-секунд)
2. [Мониторинг CPU](#-мониторинг-cpu)
3. [Мониторинг RAM](#-мониторинг-ram)
4. [Мониторинг дисков](#-мониторинг-дисков)
5. [Мониторинг сети](#-мониторинг-сети)
6. [Проверка сервисов](#-проверка-сервисов)
7. [Проверка обновлений](#-проверка-обновлений)
8. [Проверка безопасности](#-проверка-безопасности)
9. [Мониторинг температуры](#-мониторинг-температуры)
10. [Анализ загрузки системы](#-анализ-загрузки-системы)
11. [Проверка пользователей и прав](#-проверка-пользователей-и-прав)
12. [Резервное копирование](#-резервное-копирование)
13. [Дашборд реального времени](#-дашборд-реального-времени)
14. [Автоматический скрипт system-health-check.sh](#-автоматический-скрипт-system-health-checksh)
15. [Генерация отчётов](#-генерация-отчётов)
16. [Планирование проверок](#-планирование-проверок)
17. [Интерпретация метрик](#-интерпретация-метрик)
18. [Требования и совместимость](#-требования-и-совместимость)

---

## Экспресс-диагностика (30 секунд)

Быстрая проверка ключевых параметров системы одной командой:

```bash
#!/bin/bash
echo "╔══════════════════════════════════════════════════════╗"
echo "║           ЭКСПРЕСС-ДИАГНОСТИКА СИСТЕМЫ              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# CPU Load
echo "📊 CPU Load (1m/5m/15m):"
uptime | awk -F'load average:' '{print $2}'
echo ""

# RAM
echo "🧠 RAM:"
free -h | grep -E "Mem|Swap"
echo ""

# Disk
echo "💾 Disk Usage:"
df -h --total 2>/dev/null | grep -E "Filesystem|/dev/|total" | head -5
echo ""

# Network
echo "🌐 Network Interfaces:"
ip -br addr show 2>/dev/null | grep -E "UP|UNKNOWN"
echo ""

# Failed Services
echo "❌ Failed Services:"
failed=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)
if [ "$failed" -gt 0 ]; then
    echo "   ⚠️  Найдено failed-сервисов: $failed"
    systemctl --failed --no-pager 2>/dev/null
else
    echo "   ✅ Все сервисы работают"
fi
echo ""

# Uptime
echo "⏱️  Uptime:"
uptime -p 2>/dev/null || uptime
echo ""

# Security Updates
echo "🔒 Pending Updates:"
pending=$(dnf check-update -q 2>/dev/null | wc -l)
echo "   Доступно обновлений: $pending"
```

> [!tip]
> Сохраните этот скрипт как `~/quick-check.sh`, сделайте исполняемым (`chmod +x`) и запускайте при любом подозрении на проблему.

---

## Мониторинг CPU

### Загрузка процессора

```bash
# Текущая загрузка (обновление каждую секунду)
top -d 1

# Среднее значение за 1, 5, 15 минут
cat /proc/loadavg

# Детальная информация
mpstat -P ALL 1 3
```

### Количество ядер и архитектура

```bash
# Количество ядер
nproc
lscpu | grep -E "CPU\(s\)|Thread|Core|Socket"

# Архитектура
uname -m
lscpu | grep -E "Architecture|Model name"

# Флаги процессора (виртуализация, AES и т.д.)
lscpu | grep -E "Virtualization|Flags"
cat /proc/cpuinfo | grep -E "model name|flags" | head -20
```

### Проверка троттлинга (thermal throttling)

```bash
# Проверка троттлинга через dmesg
dmesg | grep -i "throttl"

# Проверка частоты CPU
cat /proc/cpuinfo | grep "MHz" | head -4

# Мониторинг частоты в реальном времени
watch -n 1 'cat /proc/cpuinfo | grep "MHz"'

# Через cpufreq (если доступен)
cpupower frequency-info 2>/dev/null || echo "cpufreq не доступен"
```

### Интерпретация CPU Load

| Нагрузка (1 min) | 2 ядра | 4 ядра | 8 ядер | Статус |
|------------------|--------|--------|--------|--------|
| 0.0 -- 1.0 | 1.0 -- 2.0 | 1.0 -- 4.0 | 1.0 -- 8.0 | ✅ Норма |
| 1.0 -- 2.0 | 2.0 -- 4.0 | 4.0 -- 8.0 | 8.0 -- 16.0 | ⚠️ Предупреждение |
| > 2.0 | > 4.0 | > 8.0 | > 16.0 | 🔴 Критично |

### Troubleshooting CPU

| Проблема | Команда диагностики | Решение |
|----------|---------------------|---------|
| Высокая нагрузка | `top -o %CPU` | Найдите процесс-виновник, при необходимости `kill -15 PID` |
| Один ядро загружено на 100% | `mpstat -P ALL 1` | Однопоточное приложение, рассмотрите многопоточный аналог |
| Троттлинг | `dmesg \| grep throttl` | Очистите систему охлаждения, замените термопасту |
| Частота не повышается | `cpupower frequency-info` | Проверьте governor: `cpupower frequency-set -g performance` |

---

## Мониторинг RAM

### Текущее использование памяти

```bash
# Общая информация (человекочитаемый формат)
free -h

# Детальная информация из /proc
cat /proc/meminfo | head -30

# Постоянный мониторинг
watch -n 2 free -h
```

### Анализ по процессам

```bash
# Топ-10 процессов по потреблению RAM
ps aux --sort=-%mem | head -11

# Через smem (если установлен)
sudo dnf install -y smem
smem -s rss -r | head -20

# Суммарное использование по пользователям
ps aux | awk '{user[$1]+=$6} END {for (u in user) printf "%s: %.0f MB\n", u, user[u]/1024}' | sort -t: -k2 -rn
```

### Swap использование

```bash
# Статус swap
swapon --show

# Топ процессов использующих swap
for file in /proc/*/status ; do
    awk '/^VmSwap|Name|^Pid/{printf $2 " " $3}END{print ""}' $file 2>/dev/null
done | sort -k 3 -rn | head -10

# Swappiness (по умолчанию обычно 60)
cat /proc/sys/vm/swappiness

# Временное изменение
sudo sysctl vm.swappiness=10

# Постоянное изменение
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```

### Утечки памяти

```bash
# Мониторинг роста памяти процесса
watch -n 5 'ps aux --sort=-%mem | head -6'

# Проверка slab-аллокации (ядро)
sudo slabtop -s c

# Проверка fragmentation памяти
cat /proc/buddyinfo
```

### Интерпретация RAM

| Параметр | Норма | Предупреждение | Критично |
|----------|-------|----------------|----------|
| **Использование RAM** | < 70% | 70--90% | > 90% |
| **Swap Usage** | < 20% | 20--50% | > 50% |
| **Available RAM** | > 2 ГБ | 0.5--2 ГБ | < 0.5 ГБ |
| **Cached** | > 500 МБ | 100--500 МБ | < 100 МБ |

### Troubleshooting RAM

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| OOM Killer срабатывает | `dmesg \| grep -i oom` | Увеличьте RAM, ограничьте процессы через cgroups |
| Swap активно используется | `free -h`, `vmstat 1` | Уменьшите swappiness, добавьте RAM |
| Утечка памяти | `smem`, `valgrind` | Обновите/перезапустите проблемное приложение |
| Memory leak в ядре | `slabtop` | Обновите ядро: `sudo dnf update kernel` |

---

## Мониторинг дисков

### Использование дискового пространства

```bash
# Общая информация
df -h

# Подробная информация по конкретному диску
df -h /dev/sda1

# Топ-20 самых больших директорий
sudo du -ah / 2>/dev/null | sort -rh | head -20

# Топ больших файлов в home
find /home -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rn

# Inode usage
df -i
```

### SMART мониторинг дисков

```bash
# Установка smartmontools
sudo dnf install -y smartmontools

# Проверка SMART статуса
sudo smartctl -a /dev/sda

# Краткий статус здоровья
sudo smartctl -H /dev/sda

# Тест SMART (short/long)
sudo smartctl -t short /dev/sda
sudo smartctl -t long /dev/sda

# Просмотр результатов
sudo smartctl -l selftest /dev/sda

# Проверка NVMe
sudo nvme smart-log /dev/nvme0
```

### Ключевые SMART атрибуты

| Атрибут | Описание | Норма | Предупреждение | Критично |
|---------|----------|-------|----------------|----------|
| **Reallocated_Sector_Ct** | Переназначенные сектора | 0 | 1--10 | > 10 |
| **Current_Pending_Sector** | Нестабильные сектора | 0 | 1--5 | > 5 |
| **UDMA_CRC_Error_Count** | Ошибки кабеля/контроллера | 0 | 1--50 | > 50 |
| **Temperature_Celsius** | Температура диска | < 45°C | 45--55°C | > 55°C |
| **Power_On_Hours** | Часы работы | - | > 30 000 | > 50 000 |
| **Wear_Leveling_Count** | Износ SSD | > 50 | 20--50 | < 20 |
| **Media_Wearout_Indicator** | Износ SSD | > 10 | 5--10 | < 5 |

### Дисковый I/O

```bash
# Установка iotop
sudo dnf install -y iotop

# I/O в реальном времени
sudo iotop -o

# Статистика по устройствам
iostat -x 1 5

# Тест скорости чтения/записи
sudo hdparm -Tt /dev/sda

# FIO тест (производительность)
sudo dnf install -y fio
fio --name=randread --ioengine=libaio --direct=1 --bs=4k --size=1G --numjobs=4 --runtime=60 --group_reporting

# Проверка latency
ioping -c 10 /dev/sda
```

### Troubleshooting дисков

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| Место заканчивается | `df -h`, `du -sh /*` | Очистите логи: `sudo journalctl --vacuum-size=100M` |
| SMART предупреждения | `smartctl -a /dev/sda` | Запланируйте замену диска |
| Медленный I/O | `iostat -x 1`, `iotop` | Проверьте подключение, замените кабель |
| Inode исчерпаны | `df -i` | Найдите множество мелких файлов: `find / -xdev -type f \| cut -d/ -f2 \| sort \| uniq -c \| sort -rn` |
| Файловая система read-only | `dmesg \| grep -i error` | `sudo fsck /dev/sda1` (на размонтированном разделе) |

---

## Мониторинг сети

### Сетевые интерфейсы

```bash
# Все интерфейсы
ip addr show

# Кратко
ip -br addr show

# Статистика по интерфейсам
ip -s link

# Скорость и дуплекс
sudo ethtool eth0

# Таблица маршрутизации
ip route show

# DNS конфигурация
cat /etc/resolv.conf
```

### Активные соединения

```bash
# Все слушающие порты
sudo ss -tulnp

# Все установленные соединения
ss -tnp state established

# Статистика по состояниям TCP
ss -s

# Мониторинг в реальном времени
watch -n 2 'ss -s'
```

### DNS проверка

```bash
# Проверка DNS разрешения
dig ya.ru
nslookup ya.ru

# Проверка DNS сервера
dig @8.8.8.8 ya.ru

# Измерение DNS времени
time dig ya.ru > /dev/null
```

### Сетевая статистика и мониторинг

```bash
# Установка nload
sudo dnf install -y nload

# Мониторинг трафика
sudo nload eth0

# Статистика по пакетам
netstat -i

# Проверка потерь пакетов
ping -c 10 ya.ru | tail -3

# Трассировка маршрута
tracepath ya.ru
```

### Интерпретация сетевых метрик

| Метрика | Норма | Предупреждение | Критично |
|---------|-------|----------------|----------|
| **Packet Loss** | 0% | 1--5% | > 5% |
| **Latency** | < 50 мс | 50--200 мс | > 200 мс |
| **TCP Retransmits** | < 1% | 1--5% | > 5% |
| **DNS Response Time** | < 50 мс | 50--200 мс | > 200 мс |

### Troubleshooting сети

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| Нет подключения | `ip addr`, `ping 8.8.8.8` | Проверьте кабель, `nmcli device` |
| Медленная сеть | `ethtool eth0`, `mtr ya.ru` | Проверьте дуплекс/скорость |
| DNS не работает | `dig ya.ru`, `cat /etc/resolv.conf` | Проверьте `/etc/resolv.conf`, перезапустите NetworkManager |
| Порты не слушаются | `ss -tulnp`, `systemctl status service` | Проверьте сервис и firewall |

---

## Проверка сервисов

### Статус systemd сервисов

```bash
# Все активные сервисы
systemctl list-units --type=service --state=running

# Failed сервисы
systemctl --failed

# Статус конкретного сервиса
systemctl status nginx

# Включенные сервисы
systemctl list-unit-files --state=enabled

# Недавние запуски/остановки
journalctl -u nginx --since "1 hour ago"
```

### Детальный анализ сервиса

```bash
# Полная информация о сервисе
systemctl show nginx

# Дерево зависимостей
systemctl list-dependencies nginx

# Время запуска сервисов
systemd-analyze blame | head -20

# Критическая цепь загрузки
systemd-analyze critical-chain
```

### Troubleshooting сервисов

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| Сервис не запускается | `systemctl status service`, `journalctl -u service` | Исправьте конфигурацию, проверьте зависимости |
| Сервис падает | `journalctl -u service -p err`, `coredumpctl list` | Проверьте логи, права доступа, зависимости |
| Медленный запуск | `systemd-analyze blame` | Отключите ненужные сервисы, оптимизируйте зависимости |
| Сервис не включен в автозагрузку | `systemctl is-enabled service` | `sudo systemctl enable service` |

---

## Проверка обновлений

### Проверка доступных обновлений

```bash
# Список доступных обновлений
sudo dnf check-update

# Только security обновления
sudo dnf updateinfo list security

# Подробная информация о security обновлениях
sudo dnf updateinfo info security

# Статистика обновлений
sudo dnf updateinfo
```

### История обновлений

```bash
# История транзакций DNF
dnf history list | head -20

# Детали конкретной транзакции
dnf history info 15

# Откат транзакции
sudo dnf history undo 15
```

### Автоматические обновления

```bash
# Установка dnf-automatic
sudo dnf install -y dnf-automatic

# Настройка
sudo tee /etc/dnf/automatic.conf << 'EOF'
[commands]
upgrade_type = security
download_updates = yes
apply_updates = yes

[emitters]
emit_via = stdio

[command]
email_to = root@localhost
email_from = automatic@localhost

[base]
debuglevel = 1
EOF

# Включение таймера
sudo systemctl enable --now dnf-automatic.timer

# Проверка статуса
systemctl status dnf-automatic.timer
```

### Интерпретация обновлений

| Тип | Описание | Рекомендуемое действие |
|-----|----------|------------------------|
| **Security** | Уязвимости безопасности | Установить немедленно |
| **Bugfix** | Исправления ошибок | Установить в ближайшее время |
| **Enhancement** | Новые функции | Установить по плану |
| **Kernel** | Обновления ядра | Установить, перезагрузить |

---

## Проверка безопасности

### Firewall (firewalld)

```bash
# Статус firewall
sudo systemctl status firewalld

# Активные зоны
sudo firewall-cmd --get-active-zones

# Правила по умолчанию
sudo firewall-cmd --list-all

# Все открытые порты
sudo firewall-cmd --list-ports

# Все сервисы
sudo firewall-cmd --list-services
```

### SELinux

```bash
# Статус SELinux
getenforce

# Детальная информация
sestatus

# SELinux логи
sudo ausearch -m avc -ts recent

# Проверка политик
sealert -a /var/log/audit/audit.log 2>/dev/null

# Временное отключение (для диагностики)
sudo setenforce 0

# Постоянное (через /etc/selinux/config)
# SELINUX=enforcing | permissive | disabled
```

### Открытые порты

```bash
# Все слушающие порты
sudo ss -tulnp

# Проверка портов извне (установите nmap)
sudo nmap -sT -p- localhost

# Скан на конкретном IP
sudo nmap -sV -sC 192.168.1.100
```

### Проверка пользователей

```bash
# Все пользователи с login shell
grep -E ':/bin/(bash|sh|zsh)$' /etc/passwd

# Пользователи с UID 0 (root)
awk -F: '$3 == 0 {print $1}' /etc/passwd

# Последние входы
last -20

# Неудачные попытки входа
sudo lastb | head -20

# Пользователи без пароля
sudo awk -F: '($2 == "" ) {print $1}' /etc/shadow

# sudo пользователи
grep -E '^%wheel|sudo' /etc/group
```

### Интерпретация метрик безопасности

| Проверка | Норма | Предупреждение | Критично |
|----------|-------|----------------|----------|
| **Firewall** | Активен | Отключен | Отключен + открытые порты |
| **SELinux** | Enforcing | Permissive | Disabled |
| **Открытые порты** | Только нужные | Неизвестные порты | SSH/DB без ограничений |
| **Пользователи UID 0** | Только root | Дополнительные | > 2 root-пользователей |
| **Failed Logins** | < 5/час | 5--50/час | > 50/час |

---

## Мониторинг температуры

### Установка lm_sensors

```bash
# Установка
sudo dnf install -y lm_sensors

# Обнаружение сенсоров
sudo sensors-detect --auto

# Чтение температур
sensors
```

### CPU температура

```bash
# Через sensors
sensors | grep -i "core\|cpu\|temp"

# Прямое чтение из /sys
for zone in /sys/class/thermal/thermal_zone*; do
    echo "$(cat $zone/type): $(cat $zone/temp / 1000 2>/dev/null || cat $zone/temp) C"
done

# Мониторинг в реальном времени
watch -n 2 sensors
```

### GPU температура

```bash
# Intel GPU
cat /sys/class/drm/card*/device/hwmon/hwmon*/temp*_input 2>/dev/null

# AMD GPU
sensors | grep -i "edge\|gpu"

# NVIDIA GPU
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader
```

### HDD/SSD температура

```bash
# Через hddtemp
sudo dnf install -y hddtemp
sudo hddtemp /dev/sda

# Через smartctl
sudo smartctl -A /dev/sda | grep -i temperature
```

### Интерпретация температур

| Компонент | Норма | Предупреждение | Критично |
|-----------|-------|----------------|----------|
| **CPU** | < 65°C | 65--80°C | > 80°C |
| **GPU** | < 70°C | 70--85°C | > 85°C |
| **HDD** | < 45°C | 45--55°C | > 55°C |
| **SSD** | < 60°C | 60--70°C | > 70°C |
| **Системная** | < 40°C | 40--50°C | > 50°C |

---

## Анализ загрузки системы

### Время загрузки

```bash
# Общее время загрузки
systemd-analyze

# Время по сервисам
systemd-analyze blame | head -20

# Критическая цепь
systemd-analyze critical-chain

# График загрузки (создаёт SVG)
systemd-analyze plot > /tmp/boot-plot.svg

# Время загрузки ядра + initrd
systemd-analyze time
```

### Boot performance оптимизация

```bash
# Найти самые медленные сервисы
systemd-analyze blame | head -10

# Проверить отключаемые сервисы
systemctl list-unit-files --state=enabled | grep -E "cups|bluetooth|avahi"

# Отключить ненужный сервис
sudo systemctl disable --now cups

# Маскировка сервиса (полная блокировка)
sudo systemctl mask systemd-backlight
```

### История загрузок

```bash
# Записи о загрузках в журнале
journalctl --list-boots

# Логи конкретной загрузки
journalctl -b -1  # предыдущая загрузка
journalctl -b -2  # загрузка до предыдущей

# Время последней загрузки
last reboot | head -5
```

---

## Проверка пользователей и прав

### Активные пользователи

```bash
# Кто сейчас в системе
who
w

# Активные сессии
last | head -20

# sudo аудит
sudo journalctl _COMM=sudo | tail -20
```

### Права файлов

```bash
# SUID/SGID файлы
find / -perm -4000 -type f 2>/dev/null
find / -perm -2000 -type f 2>/dev/null

# Файлы с открытыми правами (world-writable)
find / -perm -o+w -type f 2>/dev/null | head -20

# Файлы без владельца
find / -nouser -o -nogroup 2>/dev/null | head -20
```

### SSH аудит

```bash
# Статус SSH
sudo systemctl status sshd

# Настройки SSH
sudo grep -E "^(PermitRoot|PasswordAuth|PubkeyAuth)" /etc/ssh/sshd_config

# Неудачные попытки SSH
sudo grep "Failed password" /var/log/secure | tail -20

# Успешные входы SSH
sudo grep "Accepted" /var/log/secure | tail -20
```

---

## Резервное копирование

### Проверка существующих бэкапов

```bash
# Проверить cron на наличие задач бэкапа
crontab -l 2>/dev/null
sudo crontab -l 2>/dev/null

# Проверить systemd timer для бэкапов
systemctl list-timers | grep -i backup

# Найти последние архивы
find / -name "*.tar.gz" -o -name "*.bak" -o -name "*.backup" 2>/dev/null | head -20
```

### Быстрый бэкап конфигурации

```bash
# Создание бэкапа конфигов
sudo tar czf /tmp/config-backup-$(date +%Y%m%d).tar.gz \
    /etc/ \
    /var/spool/cron/ \
    --exclude=/etc/mtab \
    2>/dev/null

# Бэкап списка пакетов
dnf list installed | awk '{print $1}' > /tmp/installed-packages-$(date +%Y%m%d).txt

# Бэкап cron
crontab -l > /tmp/cron-backup-$(date +%Y%m%d).txt 2>/dev/null
sudo crontab -l > /tmp/root-cron-backup-$(date +%Y%m%d).txt 2>/dev/null
```

### Бэкап с rsync

```bash
# Установка rsync
sudo dnf install -y rsync

# Инкрементальный бэкап
sudo rsync -avz --delete --link-dest=/backup/latest \
    /home/ /backup/home-$(date +%Y%m%d)/

# Исключения
sudo rsync -avz --exclude='.cache' --exclude='*.tmp' /home/ /backup/home/
```

---

## Дашборд реального времени

### Htop

```bash
# Установка
sudo dnf install -y htop

# Запуск
htop

# Полезные горячие клавиши:
# F6 -- сортировка (по CPU, MEM, TIME)
# F4 -- фильтрация по имени
# F5 -- дерево процессов
# t -- показать/скрыть дерево
# H -- показать/скрыть user threads
# M -- сортировка по памяти
# P -- сортировка по CPU
```

### Glances

```bash
# Установка
sudo dnf install -y glances

# Локальный запуск
glances

# Веб-интерфейс (доступ по http://IP:61208)
glances -w

# Серверный режим
glances -s

# Экспорт в InfluxDB
glances --export influxdb

# Краткий режим
glances --disable-plugin all --enable-plugin cpu,mem,diskio,network
```

### Tmux с несколькими панелями мониторинга

```bash
# Установка tmux
sudo dnf install -y tmux

# Создать сессию с мониторингом
tmux new-session -d -s monitoring
tmux split-window -h
tmux split-window -v
tmux split-window -v
tmux select-pane -t 0

# Запустить мониторинг в панелях
tmux send-keys -t 0 'htop' Enter
tmux send-keys -t 1 'sudo iotop -o' Enter
tmux send-keys -t 2 'sudo nload' Enter
tmux send-keys -t 3 'glances' Enter

# Подключиться
tmux attach -t monitoring
```

---

## Автоматический скрипт system-health-check.sh

Полный автоматический скрипт диагностики с цветным выводом и генерацией отчётов:

```bash
#!/bin/bash
##############################################################################
# system-health-check.sh -- Полная диагностика системы РЕД ОС
#
# Использование:
#   sudo ./system-health-check.sh [OPTIONS]
#
# Опции:
#   --quick        Экспресс-проверка (30 секунд)
#   --full         Полная проверка (5 минут)
#   --cpu          Только CPU
#   --ram          Только RAM
#   --disk         Только диски
#   --network      Только сеть
#   --services     Только сервисы
#   --security     Только безопасность
#   --temp         Только температура
#   --report FMT   Формат отчёта: txt, html, json (по умолчанию: txt)
#   --output DIR   Директория для отчёта (по умолчанию: ./reports/)
#   --quiet        Тихий режим (только предупреждения и ошибки)
#   --help         Справка
#
# Зависимости: bash, coreutils, systemd, dnf, procps
# Опционально: smartmontools, lm_sensors, hddtemp, ethtool, jq
##############################################################################

set -euo pipefail

# ─── Цвета ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ─── Настройки ───────────────────────────────────────────────────────────
REPORT_FORMAT="txt"
OUTPUT_DIR="./reports"
QUIET=false
CHECK_TYPE="full"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
HOSTNAME=$(hostname)
OS_INFO=$(cat /etc/redos-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)

# ─── Функции ─────────────────────────────────────────────────────────────
log_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_ok() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[OK]${NC}   $1"
    fi
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}  $1${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
    fi
}

# Проверка root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_warn "Для полной проверки необходим root. Некоторые данные могут быть недоступны."
    fi
}

# ─── Проверки ────────────────────────────────────────────────────────────

check_cpu() {
    log_header "CPU -- Процессор"

    local model
    model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    local cores
    cores=$(nproc)
    local load
    load=$(cat /proc/loadavg)
    local load_1m
    load_1m=$(echo "$load" | awk '{print $1}')
    local load_int=${load_1m%%.*}

    echo -e "  Модель:       ${WHITE}${model}${NC}"
    echo -e "  Ядра:         ${WHITE}${cores}${NC}"
    echo -e "  Load Average: ${WHITE}${load}${NC}"

    if [ "$load_int" -gt $((cores * 2)) ]; then
        log_error "Загрузка CPU критическая: ${load_1m} (при ${cores} ядрах)"
    elif [ "$load_int" -gt "$cores" ]; then
        log_warn "Загрузка CPU высокая: ${load_1m} (при ${cores} ядрах)"
    else
        log_ok "Загрузка CPU в норме: ${load_1m} (при ${cores} ядрах)"
    fi

    # Топ процессов по CPU
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "  ${WHITE}Топ-5 процессов по CPU:${NC}"
        ps aux --sort=-%cpu | awk 'NR<=6 {printf "    %-20s %5s%%  %s\n", $11, $3, $1}'
    fi

    # Троттлинг
    local throttle
    throttle=$(dmesg 2>/dev/null | grep -ic "throttl")
    if [ "$throttle" -gt 0 ]; then
        log_warn "Обнаружен thermal throttling ($throttle записей в dmesg)"
    else
        log_ok "Троттлинг не обнаружен"
    fi
}

check_ram() {
    log_header "RAM -- Оперативная память"

    local total_mb used_mb avail_mb swap_total_mb swap_used_mb
    total_mb=$(free -m | awk '/^Mem:/ {print $2}')
    used_mb=$(free -m | awk '/^Mem:/ {print $3}')
    avail_mb=$(free -m | awk '/^Mem:/ {print $7}')
    swap_total_mb=$(free -m | awk '/^Swap:/ {print $2}')
    swap_used_mb=$(free -m | awk '/^Swap:/ {print $3}')

    local usage_pct=0
    if [ "$total_mb" -gt 0 ]; then
        usage_pct=$((used_mb * 100 / total_mb))
    fi

    echo -e "  Всего:        ${WHITE}${total_mb} МБ${NC}"
    echo -e "  Использовано: ${WHITE}${used_mb} МБ (${usage_pct}%)${NC}"
    echo -e "  Доступно:     ${WHITE}${avail_mb} МБ${NC}"
    echo -e "  Swap:         ${WHITE}${swap_used_mb} МБ / ${swap_total_mb} МБ${NC}"

    if [ "$usage_pct" -gt 90 ]; then
        log_error "Использование RAM критическое: ${usage_pct}%"
    elif [ "$usage_pct" -gt 70 ]; then
        log_warn "Использование RAM высокое: ${usage_pct}%"
    else
        log_ok "Использование RAM в норме: ${usage_pct}%"
    fi

    # Swap
    if [ "$swap_total_mb" -gt 0 ] && [ "$swap_used_mb" -gt 0 ]; then
        local swap_pct=$((swap_used_mb * 100 / swap_total_mb))
        if [ "$swap_pct" -gt 50 ]; then
            log_warn "Swap активно используется: ${swap_pct}%"
        elif [ "$swap_pct" -gt 20 ]; then
            log_warn "Swap используется умеренно: ${swap_pct}%"
        else
            log_ok "Swap в норме: ${swap_pct}%"
        fi
    fi

    # OOM
    local oom_count
    oom_count=$(dmesg 2>/dev/null | grep -ic "oom\|out of memory")
    if [ "$oom_count" -gt 0 ]; then
        log_warn "OOM Killer срабатывал: ${oom_count} раз"
    fi

    # Топ процессов по RAM
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "  ${WHITE}Топ-5 процессов по RAM:${NC}"
        ps aux --sort=-%mem | awk 'NR<=6 {printf "    %-20s %5s%%  %s MB\n", $11, $4, $6/1024, $1}'
    fi
}

check_disk() {
    log_header "DISK -- Дисковое пространство"

    local has_warning=false

    # Проверка разделов
    while IFS= read -r line; do
        local usage pct mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')
        if [ "$usage" -gt 90 ]; then
            log_error "Раздел ${mount} заполнен на ${usage}%"
            has_warning=true
        elif [ "$usage" -gt 80 ]; then
            log_warn "Раздел ${mount} заполнен на ${usage}%"
            has_warning=true
        else
            log_ok "Раздел ${mount}: ${usage}% использовано"
        fi
    done < <(df -h --output=pcent,target 2>/dev/null | grep "^ *[0-9]" | grep -E "^|/dev/")

    if [ "$has_warning" = false ] && [ "$QUIET" = false ]; then
        echo ""
        df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E "Filesystem|/dev/"
    fi

    # Inodes
    if [ "$QUIET" = false ]; then
        echo ""
        log_info "Inode usage:"
        df -i 2>/dev/null | grep "^/dev/" | while read -r line; do
            local inode_pct
            inode_pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
            local mount_pt
            mount_pt=$(echo "$line" | awk '{print $6}')
            if [ "$inode_pct" -gt 80 ]; then
                log_warn "Inode на ${mount_pt}: ${inode_pct}%"
            else
                log_ok "Inode на ${mount_pt}: ${inode_pct}%"
            fi
        done
    fi

    # SMART (если доступен)
    if command -v smartctl &>/dev/null; then
        if [ "$QUIET" = false ]; then
            echo ""
            log_info "SMART статус:"
            for disk in /dev/sd[a-z] /dev/nvme[0-9]; do
                if [ -b "$disk" ]; then
                    local smart_status
                    smart_status=$(smartctl -H "$disk" 2>/dev/null | grep -i "result" | awk '{print $NF}')
                    if [ "$smart_status" = "PASSED" ]; then
                        log_ok "${disk}: SMART OK"
                    elif [ "$smart_status" = "FAILED!" ]; then
                        log_error "${disk}: SMART FAILED!"
                    else
                        log_warn "${disk}: SMART статус неизвестен"
                    fi
                fi
            done
        fi
    else
        log_info "smartctl не установлен: sudo dnf install smartmontools"
    fi
}

check_network() {
    log_header "NETWORK -- Сетевые интерфейсы"

    # Интерфейсы
    if [ "$QUIET" = false ]; then
        echo -e "  ${WHITE}Интерфейсы:${NC}"
        ip -br addr show 2>/dev/null | while read -r line; do
            local iface status
            iface=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2}')
            if [ "$status" = "UP" ] || [ "$status" = "UNKNOWN" ]; then
                log_ok "${iface}: ${status}"
            else
                log_warn "${iface}: ${status}"
            fi
        done
    fi

    # DNS
    local dns_servers
    dns_servers=$(grep -c "^nameserver" /etc/resolv.conf 2>/dev/null || echo 0)
    if [ "$dns_servers" -gt 0 ]; then
        log_ok "DNS серверов настроено: ${dns_servers}"
    else
        log_warn "DNS серверы не найдены в /etc/resolv.conf"
    fi

    # Соединения
    local established
    established=$(ss -tn state established 2>/dev/null | wc -l)
    local listening
    listening=$(ss -tln 2>/dev/null | tail -n +2 | wc -l)
    echo -e "  Установлено соединений: ${WHITE}${established}${NC}"
    echo -e "  Слушающих портов:       ${WHITE}${listening}${NC}"

    # Packet loss test
    local loss
    loss=$(ping -c 3 -W 2 8.8.8.8 2>/dev/null | grep "packet loss" | awk '{print $6}' | tr -d '%')
    if [ -n "$loss" ]; then
        if [ "$loss" -gt 5 ]; then
            log_warn "Потеря пакетов: ${loss}%"
        elif [ "$loss" -gt 0 ]; then
            log_warn "Небольшая потеря пакетов: ${loss}%"
        else
            log_ok "Потеря пакетов: ${loss}%"
        fi
    fi
}

check_services() {
    log_header "SERVICES -- Системные сервисы"

    local failed_count
    failed_count=$(systemctl --failed --no-legend 2>/dev/null | wc -l)

    if [ "$failed_count" -gt 0 ]; then
        log_error "Failed сервисов: ${failed_count}"
        if [ "$QUIET" = false ]; then
            systemctl --failed --no-pager 2>/dev/null | head -10
        fi
    else
        log_ok "Все сервисы работают (${failed_count} failed)"
    fi

    # Enabled сервисы
    local enabled_count
    enabled_count=$(systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | wc -l)
    echo -e "  Включено сервисов: ${WHITE}${enabled_count}${NC}"

    # Медленные сервисы
    if [ "$QUIET" = false ]; then
        echo ""
        log_info "Топ-5 медленных сервисов при загрузке:"
        systemd-analyze blame 2>/dev/null | head -5 | while read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    fi
}

check_updates() {
    log_header "UPDATES -- Доступные обновления"

    local update_count
    update_count=$(sudo dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)

    echo -e "  Доступно обновлений: ${WHITE}${update_count}${NC}"

    if [ "$update_count" -gt 10 ]; then
        log_warn "Много доступных обновлений: ${update_count}"
    elif [ "$update_count" -gt 0 ]; then
        log_info "Доступно обновлений: ${update_count}"
    else
        log_ok "Система обновлена"
    fi

    # Security обновления
    local security_count
    security_count=$(sudo dnf updateinfo list security 2>/dev/null | grep -c "^[A-Z]" || echo 0)
    if [ "$security_count" -gt 0 ]; then
        log_warn "Security обновлений: ${security_count}"
    else
        log_ok "Security обновлений нет"
    fi
}

check_security() {
    log_header "SECURITY -- Безопасность"

    # Firewall
    local fw_status
    fw_status=$(systemctl is-active firewalld 2>/dev/null || echo "inactive")
    if [ "$fw_status" = "active" ]; then
        log_ok "Firewall (firewalld): активен"
    else
        log_warn "Firewall (firewalld): не активен"
    fi

    # SELinux
    local selinux_status
    selinux_status=$(getenforce 2>/dev/null || echo "unknown")
    if [ "$selinux_status" = "Enforcing" ]; then
        log_ok "SELinux: Enforcing"
    elif [ "$selinux_status" = "Permissive" ]; then
        log_warn "SELinux: Permissive"
    else
        log_warn "SELinux: ${selinux_status}"
    fi

    # SSH
    local ssh_status
    ssh_status=$(systemctl is-active sshd 2>/dev/null || echo "inactive")
    if [ "$ssh_status" = "active" ]; then
        log_info "SSH: активен (проверьте настройки /etc/ssh/sshd_config)"
    fi

    # Пользователи с UID 0
    local root_users
    root_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd | wc -l)
    if [ "$root_users" -gt 1 ]; then
        log_warn "Несколько пользователей с UID 0: $(awk -F: '$3 == 0 {print $1}' /etc/passwd | tr '\n' ', ')"
    else
        log_ok "UID 0: только root"
    fi

    # SUID файлы (если root)
    if [ "$(id -u)" -eq 0 ] && [ "$QUIET" = false ]; then
        local suid_count
        suid_count=$(find / -perm -4000 -type f 2>/dev/null | wc -l)
        echo -e "  SUID файлов: ${WHITE}${suid_count}${NC}"
    fi
}

check_temp() {
    log_header "TEMPERATURE -- Температура"

    if command -v sensors &>/dev/null; then
        sensors 2>/dev/null | while IFS= read -r line; do
            if echo "$line" | grep -q "+"; then
                local temp
                temp=$(echo "$line" | grep -oP '\+[\d.]+' | head -1 | tr -d '+')
                if [ -n "$temp" ]; then
                    local temp_int=${temp%%.*}
                    if [ "$temp_int" -gt 80 ]; then
                        log_error "Температура: ${line}"
                    elif [ "$temp_int" -gt 65 ]; then
                        log_warn "Температура: ${line}"
                    else
                        log_ok "Температура: ${line}"
                    fi
                fi
            fi
        done
    else
        log_info "lm_sensors не установлен: sudo dnf install lm_sensors"
    fi

    # HDD температура
    if command -v hddtemp &>/dev/null; then
        for disk in /dev/sd[a-z]; do
            if [ -b "$disk" ]; then
                local hdd_temp
                hdd_temp=$(hddtemp "$disk" 2>/dev/null | awk '{print $NF}' | tr -d '°C')
                if [ -n "$hdd_temp" ] && [ "$hdd_temp" != "no sensor" ] && [ "$hdd_temp" != "S.M.A.R.T." ]; then
                    if [ "$hdd_temp" -gt 55 ]; then
                        log_warn "HDD ${disk}: ${hdd_temp}°C"
                    else
                        log_ok "HDD ${disk}: ${hdd_temp}°C"
                    fi
                fi
            fi
        done
    fi
}

check_boot() {
    log_header "BOOT -- Анализ загрузки"

    local boot_time
    boot_time=$(systemd-analyze 2>/dev/null | head -1)
    echo -e "  ${WHITE}${boot_time}${NC}"

    echo ""
    log_info "Топ-5 медленных сервисов:"
    systemd-analyze blame 2>/dev/null | head -5 | while read -r line; do
        echo -e "    ${WHITE}${line}${NC}"
    done
}

check_users() {
    log_header "USERS -- Пользователи"

    local login_users
    login_users=$(grep -cE ':/bin/(bash|sh|zsh)$' /etc/passwd)
    echo -e "  Пользователей с login shell: ${WHITE}${login_users}${NC}"

    if [ "$QUIET" = false ]; then
        echo ""
        log_info "Пользователи с login shell:"
        grep -E ':/bin/(bash|sh|zsh)$' /etc/passwd | cut -d: -f1 | while read -r user; do
            echo -e "    ${WHITE}${user}${NC}"
        done
    fi

    # Последние входы
    echo ""
    log_info "Последние входы:"
    last -5 2>/dev/null | head -5
}

check_backups() {
    log_header "BACKUPS -- Резервное копирование"

    # Cron backup tasks
    local cron_backups
    cron_backups=$(crontab -l 2>/dev/null | grep -c "backup\|rsync\|tar" || echo 0)
    echo -e "  Задач бэкапа в cron (user): ${WHITE}${cron_backups}${NC}"

    local root_cron_backups
    root_cron_backups=$(sudo crontab -l 2>/dev/null | grep -c "backup\|rsync\|tar" || echo 0)
    echo -e "  Задач бэкапа в cron (root): ${WHITE}${root_cron_backups}${NC}"

    if [ "$cron_backups" -eq 0 ] && [ "$root_cron_backups" -eq 0 ]; then
        log_warn "Задачи резервного копирования не найдены!"
    else
        log_ok "Задачи бэкапа найдены"
    fi
}

# ─── Генерация отчётов ──────────────────────────────────────────────────

generate_txt_report() {
    local report_file="${OUTPUT_DIR}/health-report-${TIMESTAMP}.txt"
    mkdir -p "$OUTPUT_DIR"

    {
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║         ОТЧЁТ О СОСТОЯНИИ СИСТЕМЫ                       ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "Хост:     $HOSTNAME"
        echo "ОС:       $OS_INFO"
        echo "Дата:     $(date)"
        echo "Uptime:   $(uptime -p 2>/dev/null || uptime)"
        echo "Ядро:     $(uname -r)"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "CPU"
        echo "══════════════════════════════════════════════════════════"
        lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|Core|Socket|MHz"
        echo ""
        echo "Load Average: $(cat /proc/loadavg)"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "RAM"
        echo "══════════════════════════════════════════════════════════"
        free -h
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "DISK"
        echo "══════════════════════════════════════════════════════════"
        df -h
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "NETWORK"
        echo "══════════════════════════════════════════════════════════"
        ip -br addr show
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "SERVICES"
        echo "══════════════════════════════════════════════════════════"
        echo "Failed:"
        systemctl --failed --no-pager 2>/dev/null || echo "  None"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "SECURITY"
        echo "══════════════════════════════════════════════════════════"
        echo "Firewall: $(systemctl is-active firewalld 2>/dev/null || echo 'N/A')"
        echo "SELinux:  $(getenforce 2>/dev/null || echo 'N/A')"
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "TOP PROCESSES (CPU)"
        echo "══════════════════════════════════════════════════════════"
        ps aux --sort=-%cpu | head -6
        echo ""
        echo "══════════════════════════════════════════════════════════"
        echo "TOP PROCESSES (RAM)"
        echo "══════════════════════════════════════════════════════════"
        ps aux --sort=-%mem | head -6
    } > "$report_file"

    echo ""
    log_ok "TXT отчёт сохранён: ${WHITE}${report_file}${NC}"
}

generate_html_report() {
    local report_file="${OUTPUT_DIR}/health-report-${TIMESTAMP}.html"
    mkdir -p "$OUTPUT_DIR"

    local cpu_model
    cpu_model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    local cpu_cores
    cpu_cores=$(nproc)
    local ram_total
    ram_total=$(free -h | awk '/^Mem:/ {print $2}')
    local ram_used
    ram_used=$(free -h | awk '/^Mem:/ {print $3}')
    local ram_pct
    ram_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

    cat > "$report_file" << HTMLEOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Отчёт о состоянии системы -- $HOSTNAME</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f7fa; color: #333; padding: 20px; }
        .container { max-width: 960px; margin: 0 auto; }
        h1 { text-align: center; color: #1a1a2e; margin-bottom: 10px; }
        .subtitle { text-align: center; color: #666; margin-bottom: 30px; }
        .card { background: #fff; border-radius: 12px; padding: 20px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .card h2 { color: #1a1a2e; margin-bottom: 15px; border-bottom: 2px solid #e0e0e0; padding-bottom: 8px; }
        .metric { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #f0f0f0; }
        .metric:last-child { border-bottom: none; }
        .metric-label { font-weight: 500; color: #555; }
        .metric-value { font-weight: 600; color: #1a1a2e; }
        .status-ok { color: #27ae60; }
        .status-warn { color: #f39c12; }
        .status-error { color: #e74c3c; }
        .progress { height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; margin-top: 4px; }
        .progress-fill { height: 100%; border-radius: 4px; transition: width 0.3s; }
        .progress-ok { background: #27ae60; }
        .progress-warn { background: #f39c12; }
        .progress-error { background: #e74c3c; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #e0e0e0; }
        th { background: #f8f9fa; font-weight: 600; color: #555; }
        .footer { text-align: center; color: #999; margin-top: 30px; font-size: 0.85em; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 4px; font-size: 0.8em; font-weight: 600; }
        .badge-ok { background: #d4edda; color: #155724; }
        .badge-warn { background: #fff3cd; color: #856404; }
        .badge-error { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Отчёт о состоянии системы</h1>
        <p class="subtitle">$HOSTNAME | $OS_INFO | $(date '+%d.%m.%Y %H:%M:%S')</p>

        <div class="card">
            <h2>🖥️ CPU</h2>
            <div class="metric">
                <span class="metric-label">Модель</span>
                <span class="metric-value">$cpu_model</span>
            </div>
            <div class="metric">
                <span class="metric-label">Ядра</span>
                <span class="metric-value">$cpu_cores</span>
            </div>
            <div class="metric">
                <span class="metric-label">Load Average</span>
                <span class="metric-value">$(cat /proc/loadavg | awk '{print $1, $2, $3}')</span>
            </div>
        </div>

        <div class="card">
            <h2>🧠 RAM</h2>
            <div class="metric">
                <span class="metric-label">Всего</span>
                <span class="metric-value">$ram_total</span>
            </div>
            <div class="metric">
                <span class="metric-label">Использовано</span>
                <span class="metric-value">$ram_used ($ram_pct%)</span>
            </div>
            <div class="progress"><div class="progress-fill $( [ "$ram_pct" -gt 90 ] && echo 'progress-error' || ( [ "$ram_pct" -gt 70 ] && echo 'progress-warn' || echo 'progress-ok' ) )" style="width: ${ram_pct}%"></div></div>
            <div class="metric" style="margin-top:10px">
                <span class="metric-label">Swap</span>
                <span class="metric-value">$(free -h | awk '/^Swap:/ {print $3 " / " $2}')</span>
            </div>
        </div>

        <div class="card">
            <h2>💾 Диски</h2>
            <table>
                <tr><th>Раздел</th><th>Размер</th><th>Использовано</th><th>Свободно</th><th>Исп.%</th></tr>
                $(df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep "^/dev/" | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5, $6}')
            </table>
        </div>

        <div class="card">
            <h2>🌐 Сеть</h2>
            <table>
                <tr><th>Интерфейс</th><th>Статус</th><th>IP</th></tr>
                $(ip -br addr show 2>/dev/null | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3}')
            </table>
        </div>

        <div class="card">
            <h2>🔒 Безопасность</h2>
            <div class="metric">
                <span class="metric-label">Firewall</span>
                <span class="metric-value"><span class="badge $( [ "$(systemctl is-active firewalld 2>/dev/null)" = "active" ] && echo 'badge-ok' || echo 'badge-error' )">$(systemctl is-active firewalld 2>/dev/null || echo 'N/A')</span></span>
            </div>
            <div class="metric">
                <span class="metric-label">SELinux</span>
                <span class="metric-value"><span class="badge $( [ "$(getenforce 2>/dev/null)" = "Enforcing" ] && echo 'badge-ok' || echo 'badge-warn' )">$(getenforce 2>/dev/null || echo 'N/A')</span></span>
            </div>
        </div>

        <div class="card">
            <h2>⚙️ Сервисы</h2>
            <div class="metric">
                <span class="metric-label">Failed</span>
                <span class="metric-value"><span class="badge $( [ "$(systemctl --failed --no-legend 2>/dev/null | wc -l)" = "0" ] && echo 'badge-ok' || echo 'badge-error' )">$(systemctl --failed --no-legend 2>/dev/null | wc -l)</span></span>
            </div>
            <div class="metric">
                <span class="metric-label">Enabled</span>
                <span class="metric-value">$(systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | wc -l)</span>
            </div>
        </div>

        <div class="card">
            <h2>⏱️ Система</h2>
            <div class="metric">
                <span class="metric-label">Uptime</span>
                <span class="metric-value">$(uptime -p 2>/dev/null || uptime)</span>
            </div>
            <div class="metric">
                <span class="metric-label">Ядро</span>
                <span class="metric-value">$(uname -r)</span>
            </div>
            <div class="metric">
                <span class="metric-label">Обновления</span>
                <span class="metric-value">$(sudo dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)</span>
            </div>
        </div>

        <div class="footer">
            Сгенерировано system-health-check.sh | $(date '+%d.%m.%Y %H:%M:%S') | $HOSTNAME
        </div>
    </div>
</body>
</html>
HTMLEOF

    echo ""
    log_ok "HTML отчёт сохранён: ${WHITE}${report_file}${NC}"
}

generate_json_report() {
    local report_file="${OUTPUT_DIR}/health-report-${TIMESTAMP}.json"
    mkdir -p "$OUTPUT_DIR"

    local ram_pct
    ram_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    local failed_services
    failed_services=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    local update_count
    update_count=$(sudo dnf check-update -q 2>/dev/null | grep -c "^[a-z]" || echo 0)

    cat > "$report_file" << JSONEOF
{
  "report": {
    "hostname": "$HOSTNAME",
    "os": "$OS_INFO",
    "kernel": "$(uname -r)",
    "timestamp": "$(date -Iseconds)",
    "uptime": "$(uptime -p 2>/dev/null || uptime)"
  },
  "cpu": {
    "model": "$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)",
    "cores": $(nproc),
    "load_avg_1m": $(cat /proc/loadavg | awk '{print $1}'),
    "load_avg_5m": $(cat /proc/loadavg | awk '{print $2}'),
    "load_avg_15m": $(cat /proc/loadavg | awk '{print $3}')
  },
  "memory": {
    "total_mb": $(free -m | awk '/^Mem:/ {print $2}'),
    "used_mb": $(free -m | awk '/^Mem:/ {print $3}'),
    "available_mb": $(free -m | awk '/^Mem:/ {print $7}'),
    "usage_pct": $ram_pct,
    "swap_total_mb": $(free -m | awk '/^Swap:/ {print $2}'),
    "swap_used_mb": $(free -m | awk '/^Swap:/ {print $3}')
  },
  "disk": {
    "filesystems": [
      $(df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep "^/dev/" | awk '{gsub(/%/,"",$5); printf "{\"device\":\"%s\",\"size\":\"%s\",\"used\":\"%s\",\"avail\":\"%s\",\"use_pct\":%s,\"mount\":\"%s\"},\n", $1, $2, $3, $4, $5, $6}' | sed '$ s/,$//')
    ]
  },
  "network": {
    "interfaces": [
      $(ip -br addr show 2>/dev/null | awk '{printf "{\"name\":\"%s\",\"status\":\"%s\",\"addr\":\"%s\"},\n", $1, $2, $3}' | sed '$ s/,$//')
    ],
    "established_connections": $(ss -tn state established 2>/dev/null | wc -l),
    "listening_ports": $(ss -tln 2>/dev/null | tail -n +2 | wc -l)
  },
  "services": {
    "failed": $failed_services,
    "enabled": $(systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | wc -l)
  },
  "security": {
    "firewall": "$(systemctl is-active firewalld 2>/dev/null || echo 'N/A')",
    "selinux": "$(getenforce 2>/dev/null || echo 'N/A')",
    "pending_updates": $update_count
  }
}
JSONEOF

    echo ""
    log_ok "JSON отчёт сохранён: ${WHITE}${report_file}${NC}"
}

# ─── Парсинг аргументов ─────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                CHECK_TYPE="quick"
                shift
                ;;
            --full)
                CHECK_TYPE="full"
                shift
                ;;
            --cpu|--ram|--disk|--network|--services|--security|--temp|--boot|--users|--backups)
                CHECK_TYPE="${1#--}"
                shift
                ;;
            --report)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --help|-h)
                echo "Использование: $0 [OPTIONS]"
                echo ""
                echo "Опции:"
                echo "  --quick        Экспресс-проверка (30 секунд)"
                echo "  --full         Полная проверка"
                echo "  --cpu          Только CPU"
                echo "  --ram          Только RAM"
                echo "  --disk         Только диски"
                echo "  --network      Только сеть"
                echo "  --services     Только сервисы"
                echo "  --security     Только безопасность"
                echo "  --temp         Только температура"
                echo "  --report FMT   Формат отчёта: txt, html, json"
                echo "  --output DIR   Директория для отчёта"
                echo "  --quiet        Тихий режим"
                echo "  --help         Справка"
                exit 0
                ;;
            *)
                log_error "Неизвестная опция: $1"
                exit 1
                ;;
        esac
    done
}

# ─── Main ────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    check_root

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         DIAGNOSTICS SYSTEM HEALTH CHECK               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Хост:   ${WHITE}${HOSTNAME}${NC}"
    echo -e "  ОС:     ${WHITE}${OS_INFO}${NC}"
    echo -e "  Ядро:   ${WHITE}$(uname -r)${NC}"
    echo -e "  Дата:   ${WHITE}$(date '+%d.%m.%Y %H:%M:%S')${NC}"
    echo -e "  Uptime: ${WHITE}$(uptime -p 2>/dev/null || uptime)${NC}"

    case $CHECK_TYPE in
        quick)
            check_cpu
            check_ram
            check_disk
            check_services
            ;;
        full)
            check_cpu
            check_ram
            check_disk
            check_network
            check_services
            check_updates
            check_security
            check_temp
            check_boot
            check_users
            check_backups
            ;;
        cpu)     check_cpu ;;
        ram)     check_ram ;;
        disk)    check_disk ;;
        network) check_network ;;
        services) check_services ;;
        security) check_security ;;
        temp)    check_temp ;;
        boot)    check_boot ;;
        users)   check_users ;;
        backups) check_backups ;;
    esac

    # Генерация отчёта
    if [ "$REPORT_FORMAT" != "none" ]; then
        log_header "ГЕНЕРАЦИЯ ОТЧЁТА"
        case $REPORT_FORMAT in
            txt)  generate_txt_report ;;
            html) generate_html_report ;;
            json) generate_json_report ;;
            *)    log_error "Неизвестный формат: $REPORT_FORMAT (допустимы: txt, html, json)" ;;
        esac
    fi

    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Проверка завершена!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
    echo ""
}

main "$@"
```

---

## Генерация отчётов

Скрипт `system-health-check.sh` поддерживает три формата отчётов:

### TXT отчёт

```bash
sudo ./system-health-check.sh --full --report txt --output /var/reports/
```

**Содержит:**
- Полную информацию о CPU, RAM, дисках, сети
- Статус сервисов и безопасности
- Топ процессов по CPU и RAM
- Челонечно-читаемый формат

### HTML отчёт

```bash
sudo ./system-health-check.sh --full --report html --output /var/reports/
```

**Содержит:**
- Красивый адаптивный дизайн
- Цветные индикаторы статусов (зелёный/жёлтый/красный)
- Прогресс-бары для использования ресурсов
- Таблицы для дисков и сети
- Готов к печати и отправке по почте

### JSON отчёт

```bash
sudo ./system-health-check.sh --full --report json --output /var/reports/
```

**Содержит:**
- Структурированные данные для автоматической обработки
- Совместим с системами мониторинга (Zabbix, Prometheus, Grafana)
- Удобно для парсинга через `jq`

```bash
# Пример: извлечь использование RAM
jq '.memory.usage_pct' /var/reports/health-report-*.json

# Пример: проверить failed сервисы
jq '.services.failed' /var/reports/health-report-*.json
```

---

## Планирование проверок

### Через cron

```bash
# Открыть crontab
crontab -e

# Ежедневная полная проверка в 08:00
0 8 * * * /opt/scripts/system-health-check.sh --full --report html --output /var/reports/health/ >> /var/log/health-check.log 2>&1

# Ежечасная экспресс-проверка
0 * * * * /opt/scripts/system-health-check.sh --quick --report json --output /var/reports/health/ >> /var/log/health-check-quick.log 2>&1

# Проверка каждые 5 минут (только предупреждения)
*/5 * * * * /opt/scripts/system-health-check.sh --full --quiet --report json --output /var/reports/health/ >> /var/log/health-check-monitor.log 2>&1
```

### Через systemd timer

```bash
# 1. Создать сервис
sudo tee /etc/systemd/system/system-health-check.service << 'EOF'
[Unit]
Description=System Health Check
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/scripts/system-health-check.sh --full --report html --report json --output /var/reports/health/
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 2. Создать таймер
sudo tee /etc/systemd/system/system-health-check.timer << 'EOF'
[Unit]
Description=Run System Health Check Daily

[Timer]
OnCalendar=*-*-* 08:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

# 3. Активировать
sudo systemctl daemon-reload
sudo systemctl enable --now system-health-check.timer

# 4. Проверить
systemctl status system-health-check.timer
systemctl list-timers | grep health
```

### Настройка уведомлений

```bash
# Уведомление при обнаружении проблем
sudo tee /etc/systemd/system/system-health-check-alert.service << 'EOF'
[Unit]
Description=System Health Check Alert

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/opt/scripts/system-health-check.sh --full --quiet --report json --output /var/reports/health/ | mail -s "Health Check Alert on %H" admin@example.com'

[Install]
WantedBy=multi-user.target
EOF
```

---

## Интерпретация метрик

### Сводная таблица метрик

| Метрика | ✅ Норма | ⚠️ Предупреждение | 🔴 Критично | Действие при критическом |
|---------|----------|-------------------|-------------|--------------------------|
| **CPU Load (1m)** | < ядер | = ядер | > 2x ядер | Найти процесс, kill/renice |
| **CPU Temp** | < 65°C | 65--80°C | > 80°C | Проверить охлаждение |
| **RAM Usage** | < 70% | 70--90% | > 90% | Найти утечку, добавить RAM |
| **Swap Usage** | < 20% | 20--50% | > 50% | Уменьшить swappiness |
| **Disk Usage** | < 80% | 80--90% | > 90% | Очистить место |
| **Disk I/O Wait** | < 10% | 10--25% | > 25% | Найти процесс с I/O |
| **Disk SMART** | PASSED | WARNINGS | FAILED! | Заменить диск |
| **Disk Temp** | < 45°C | 45--55°C | > 55°C | Улучшить охлаждение |
| **Packet Loss** | 0% | 1--5% | > 5% | Проверить сеть |
| **Latency** | < 50ms | 50--200ms | > 200ms | Проверить маршрут |
| **Failed Services** | 0 | 1--2 | > 2 | Изучить логи, починить |
| **Security Updates** | 0 | 1--5 | > 5 | Обновить систему |
| **Firewall** | Active | Inactive | Inactive + ports | Включить firewall |
| **SELinux** | Enforcing | Permissive | Disabled | Включить enforcing |
| **Failed Logins** | < 5/h | 5--50/h | > 50/h | Заблокировать IP |
| **Root Users (UID 0)** | 1 | 2 | > 2 | Удалить лишних |

### Матрица приоритетов

| Ситуация | Приоритет | Время реакции |
|----------|-----------|---------------|
| CPU > 2x ядер + Temp > 80°C | 🔴 P0 | Немедленно |
| RAM > 90% + Swap > 50% | 🔴 P0 | В течение 15 мин |
| Disk > 90% | 🔴 P0 | В течение 1 часа |
| SMART FAILED | 🔴 P0 | Немедленно (бэкап!) |
| Failed Services > 2 | ⚠️ P1 | В течение 4 часов |
| Security Updates > 5 | ⚠️ P1 | В течение 24 часов |
| RAM > 70% | ⚠️ P2 | В течение 1 дня |
| Disk > 80% | ⚠️ P2 | В течение 1 дня |
| Все метрики в норме | ✅ P3 | Плановая проверка |

---

## Справочник команд

### CPU

| Команда | Описание |
|---------|----------|
| `lscpu` | Информация о процессоре |
| `cat /proc/loadavg` | Средняя загрузка |
| `top -o %CPU` | Процессы по CPU |
| `mpstat -P ALL 1` | Загрузка по ядрам |
| `cpupower frequency-info` | Частота CPU |
| `dmesg \| grep throttl` | Проверка троттлинга |

### RAM

| Команда | Описание |
|---------|----------|
| `free -h` | Использование памяти |
| `ps aux --sort=-%mem` | Процессы по RAM |
| `cat /proc/meminfo` | Детальная информация |
| `vmstat 1` | Виртуальная память |
| `slabtop` | Slab-аллокация ядра |
| `dmesg \| grep -i oom` | OOM Killer записи |

### Disk

| Команда | Описание |
|---------|----------|
| `df -h` | Использование дисков |
| `du -sh /*` | Размер директорий |
| `smartctl -a /dev/sda` | SMART статус |
| `iostat -x 1` | I/O статистика |
| `iotop` | I/O по процессам |
| `hdparm -Tt /dev/sda` | Тест скорости |
| `df -i` | Использование inode |

### Network

| Команда | Описание |
|---------|----------|
| `ip addr show` | Сетевые интерфейсы |
| `ss -tulnp` | Слушающие порты |
| `ss -s` | Статистика соединений |
| `ping -c 10 host` | Проверка связи |
| `tracepath host` | Трассировка |
| `ethtool eth0` | Параметры интерфейса |
| `dig host` | DNS проверка |

### Services

| Команда | Описание |
|---------|----------|
| `systemctl --failed` | Failed сервисы |
| `systemctl status svc` | Статус сервиса |
| `systemd-analyze blame` | Время запуска |
| `journalctl -u svc` | Логи сервиса |
| `systemctl list-dependencies` | Зависимости |

---

## Troubleshooting

### Частые проблемы и решения

| Симптом | Возможная причина | Быстрое решение |
|---------|-------------------|-----------------|
| **Система тормозит** | Высокая загрузка CPU | `top`, `kill -15 PID`, `renice` |
| **Не хватает памяти** | Утечка RAM | `free -h`, перезапуск процесса, `sysctl vm.drop_caches=3` |
| **Место на диске** | Логи, кэш, старые файлы | `journalctl --vacuum-size=100M`, `dnf clean all` |
| **Сеть не работает** | Интерфейс down, DNS | `nmcli dev`, `systemctl restart NetworkManager` |
| **Сервис не стартует** | Ошибка конфига, порт занят | `journalctl -u service`, `ss -tlnp \| grep PORT` |
| **Не обновляется** | Репозиторий недоступен | `dnf clean all`, проверить `/etc/yum.repos.d/` |
| **Перегрев** | Пыль, термопаста, вентилятор | `sensors`, почистить, заменить термопасту |
| **SMART предупреждения** | Деградация диска | `smartctl -a`,备份数据, заменить диск |

---

## 🔗 Связанные документы

- [Анализ журналов systemd](log-analyzer.md) -- поиск причин проблем
- [Совместимость оборудования](hardware-compatibility.md) -- проверка аппаратной части
- [Настройка сети](../network/readme.md) -- сетевая конфигурация
- [Безопасность](../security/readme.md) -- защита системы

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Ядро** | 5.15+ (7.x), 6.1+ (8.x) |
| **Права** | Пользователь (базовые проверки), root (полные) |
| **Зависимости** | bash, coreutils, systemd, procps, dnf |
| **Опционально** | smartmontools, lm_sensors, hddtemp, ethtool, jq, htop, glances, fio |
| **Скрипт** | system-health-check.sh (bash 4.0+) |
| **Отчёты** | TXT, HTML, JSON |
| **Планировщик** | cron, systemd timer |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Для проверки SMART, температуры и сетевых интерфейсов требуются root-права.
> Некоторые опциональные пакеты могут быть недоступны в минимальной установке РЕД ОС.

---

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
