# 📊 Диагностика состояния системы в РЕД ОС

> Полное руководство по проверке всех компонентов системы: CPU, RAM, диски, сеть, сервисы, обновления, безопасность, температура, загрузка, пользователи, резервные копии. Включает автоматические скрипты и генерацию отчётов.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

---

## Оглавление

1. [Экспресс-диагностика (30 секунд)](#экспресс-диагностика-30-секунд)
2. [Мониторинг CPU](#мониторинг-cpu)
3. [Мониторинг RAM](#мониторинг-ram)
4. [Мониторинг дисков](#мониторинг-дисков)
5. [Мониторинг сети](#мониторинг-сети)
6. [Проверка сервисов](#проверка-сервисов)
7. [Проверка обновлений](#проверка-обновлений)
8. [Проверка безопасности](#проверка-безопасности)
9. [Мониторинг температуры](#мониторинг-температуры)
10. [Анализ загрузки системы](#анализ-загрузки-системы)
11. [Проверка пользователей и прав](#проверка-пользователей-и-прав)
12. [Резервное копирование](#резервное-копирование)
13. [Дашборд реального времени](#дашборд-реального-времени)
14. [Автоматический скрипт system-health-check.sh](#автоматический-скрипт-system-health-checksh)
15. [Генерация отчётов](#генерация-отчётов)
16. [Планирование проверок](#планирование-проверок)
17. [Интерпретация метрик](#интерпретация-метрик)
18. [Требования и совместимость](#требования-и-совместимость)

---

## Экспресс-диагностика (30 секунд)

Быстрая проверка ключевых параметров системы одной командой:

```bash
# Вариант 1: Запуск напрямую из интернета (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/quick-check.sh | bash

# Вариант 2: Запуск через wget
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/quick-check.sh | bash

# Вариант 3: Скачивание и запуск локально
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/quick-check.sh -o quick-check.sh
chmod +x quick-check.sh
./quick-check.sh
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
# Вариант 1: Запуск напрямую из интернета (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-health-check.sh | sudo bash

# Вариант 2: Запуск через wget
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-health-check.sh | sudo bash

# Вариант 3: Скачивание и запуск локально
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/system-health-check.sh -o system-health-check.sh
chmod +x system-health-check.sh
sudo ./system-health-check.sh
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
- Человеко-читаемый формат

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
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x (может работать на других RPM-дистрибутивах: Fedora, RHEL, CentOS, Astra Linux, Alt Linux) |

> [!note]
> Для проверки SMART, температуры и сетевых интерфейсов требуются root-права.
> Некоторые опциональные пакеты могут быть недоступны в минимальной установке РЕД ОС.

---

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее
