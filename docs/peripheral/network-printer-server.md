# 🌐 Сервер печати для организации в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

Руководство по развёртыванию централизованного сервера печати на базе РЕД ОС. CUPS + Samba + Avahi, интеграция с Windows-клиентами, Active Directory, управление очередями, квоты, мониторинг.

---

## 📋 Оглавление

1. [Архитектура сервера печати](#архитектура-сервера-печати)
2. [Установка компонентов](#установка-компонентов)
3. [Настройка CUPS](#настройка-cups)
4. [Настройка Samba (общий доступ)](#настройка-samba-общий-доступ)
5. [Настройка Avahi (обнаружение)](#настройка-avahi-обнаружение)
6. [Интеграция с Windows-клиентами](#интеграция-с-windows-клиентами)
7. [Управление очередями печати](#управление-очередями-печати)
8. [Управление пользователями](#управление-пользователями)
9. [Квоты печати](#квоты-печати)
10. [Логирование и мониторинг](#логирование-и-мониторинг)
11. [Интеграция с Active Directory](#интеграция-с-active-directory)
12. [Групповые политики (GPO)](#групповые-политики-gpo)
13. [Резервное копирование конфигурации](#резервное-копирование-конфигурации)
14. [Автоматический скрипт настройки](#автоматический-скрипт-настройки)
15. [Справочник команд](#справочник-команд)
16. [Требования и совместимость](#требования-и-совместимость)

---

## Архитектура сервера печати

### Компоненты

```
┌─────────────────────────────────────────────────────────┐
│              Сервер печати (РЕД ОС)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │   CUPS   │  │  Samba   │  │  Avahi   │               │
│  │  :631    │  │  :445    │  │  :5353   │               │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘               │
│       │              │              │                     │
│  ┌────┴──────────────┴──────────────┴─────┐              │
│  │          Менеджер очередей              │              │
│  └────────────────────┬───────────────────┘              │
│                       │                                   │
│  ┌────────────────────┴───────────────────┐              │
│  │        Подключённые принтеры           │              │
│  │  USB │ Сетевые │ IPP │ SMB            │              │
│  └────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────┘
         │               │               │
    ┌────┴───┐     ┌─────┴────┐   ┌─────┴────┐
    │ Linux  │     │ Windows  │   │ macOS /  │
    │ клиент │     │ клиент   │   │ Mobile   │
    └────────┘     └──────────┘   └──────────┘
```

### Роль каждого компонента

| Компонент | Порт | Протокол | Назначение |
|-----------|------|----------|------------|
| **CUPS** | 631 | IPP/HTTPS | Основной сервер печати |
| **Samba** | 445 | SMB/CIFS | Общий доступ для Windows |
| **Avahi** | 5353 | mDNS/DNS-SD | Автоматическое обнаружение |
| **firewalld** | — | — | Фильтрация трафика |

---

## Установка компонентов

### Базовая установка

```bash
# Обновление системы
sudo dnf update -y

# Установка CUPS
sudo dnf install -y cups cups-client cups-filters

# Установка Samba
sudo dnf install -y samba samba-client samba-common

# Установка Avahi
sudo dnf install -y avahi avahi-tools

# Установка дополнительных утилит
sudo dnf install -y system-config-printer
sudo dnf install -y python3-cups
sudo dnf install -s poppler-utils

# Включение служб
sudo systemctl enable cups
sudo systemctl enable smb
sudo systemctl enable nmb
sudo systemctl enable avahi-daemon

# Запуск служб
sudo systemctl start cups
sudo systemctl start smb
sudo systemctl start nmb
sudo systemctl start avahi-daemon
```

### Настройка firewall

```bash
# CUPS
sudo firewall-cmd --permanent --add-service=ipp
sudo firewall-cmd --permanent --add-service=ipp-client

# Samba
sudo firewall-cmd --permanent --add-service=samba

# Avahi/mDNS
sudo firewall-cmd --permanent --add-service=mdns
sudo firewall-cmd --permanent --add-port=5353/udp

# Перезагрузка firewall
sudo firewall-cmd --reload

# Проверка
sudo firewall-cmd --list-all
```

---

## Настройка CUPS

### Базовая конфигурация cupsd.conf

```bash
sudo nano /etc/cups/cupsd.conf
```

```apache
# ============================================
# Базовая конфигурация сервера печати
# ============================================

# Слушать на всех интерфейсах
Port 631
Listen /run/cups/cups.sock

# Разрешить общий доступ к принтерам
Browsing On
BrowseLocalProtocols dnssd

# Настройки по умолчанию
DefaultAuthType Basic
WebInterface Yes

# ============================================
# Политика доступа
# ============================================

<Location />
    # Разрешить доступ из локальной сети
    Order allow,deny
    Allow @LOCAL
</Location>

<Location /admin>
    # Админ-панель — только с localhost и доверенных IP
    Order allow,deny
    Allow localhost
    Allow 192.168.1.0/24
</Location>

<Location /admin/conf>
    # Конфигурация — только localhost
    AuthType Default
    Require user @SYSTEM
    Order allow,deny
    Allow localhost
</Location>

# ============================================
# Параметры печати
# ============================================

# Сохранять задания после печати
PreserveJobHistory Yes
PreserveJobFiles Yes

# Максимальное время хранения (в секундах)
MaxJobHistoryTime 86400

# Логирование
LogLevel info
PageLogFormat
```

### Добавление принтеров на сервере

```bash
# USB-принтер
sudo lpadmin -p office-hp-laserjet -E \
    -v usb://HP/LaserJet%20Pro%20M404n \
    -m everywhere \
    -D "HP LaserJet Pro M404n (Кабинет 301)" \
    -L "Кабинет 301, 3 этаж"

# Сетевой принтер (IPP)
sudo lpadmin -p office-xerox -E \
    -v ipp://192.168.1.200/ipp/print \
    -m everywhere \
    -D "Xerox AltaLink C8130 (Коридор)" \
    -L "Коридор 2 этажа"

# Сетевой принтер (Socket)
sudo lpadmin -p office-brother -E \
    -v socket://192.168.1.120:9100 \
    -m everywhere \
    -D "Brother MFC-L2700DWR (Бухгалтерия)" \
    -L "Бухгалтерия, Кабинет 205"

# Установка принтера по умолчанию
sudo lpadmin -d office-hp-laserjet

# Проверка
lpstat -p -d
```

### Настройка классов принтеров

```bash
# Создание класса (группы) принтеров
sudo lpadmin -p office-hp-laserjet -c laser-printers
sudo lpadmin -p office-brother -c laser-printers
sudo lpadmin -p office-xerox -c color-printers

# Печать на любом принтере класса
lp -d laser-printers document.pdf

# Управление классами
sudo lpadmin -x -c class_name    # Удалить класс
```

### Параметры принтера по умолчанию

```bash
# Двусторонняя печать по умолчанию
sudo lpadmin -p office-hp-laserjet -o sides-default=two-sided-long-edge

# Чёрно-белая печать по умолчанию
sudo lpadmin -p office-hp-laserjet -o color-mode-default=monochrome

# Формат бумаги A4
sudo lpadmin -p office-hp-laserjet -o media-default=A4

# Качество печати
sudo lpadmin -p office-hp-laserjet -o print-quality-default=normal
```

---

## Настройка Samba (общий доступ)

### Конфигурация smb.conf

```bash
sudo nano /etc/samba/smb.conf
```

```ini
# ============================================
# Глобальные настройки
# ============================================
[global]
    # Имя сервера
    server string = Print Server РЕД ОС
    netbios name = PRINTSERVER

    # Рабочая группа
    workgroup = WORKGROUP

    # Безопасность
    security = user
    map to guest = Bad User

    # Логи
    log file = /var/log/samba/log.%m
    max log size = 1000

    # ============================================
    # Настройки печати
    # ============================================
    load printers = yes
    printing = cups
    printcap name = cups
    printcap cache time = 750

    # Использовать драйверы CUPS
    cups options = raw

    # Разрешить гостевой доступ для печати
    guest ok = no

# ============================================
# Общие принтеры
# ============================================
[printers]
    comment = Все принтеры
    path = /var/spool/samba
    printable = yes
    guest ok = no
    read only = yes
    create mask = 0700
    browseable = no

# ============================================
# Драйверы принтеров для Windows
# ============================================
[print$]
    comment = Драйверы принтеров
    path = /var/lib/samba/printers
    browseable = yes
    read only = no
    guest ok = no
    # Только администраторы могут загружать драйверы
    write list = root, @lpadmin
    create mask = 0664
    directory mask = 0775
```

### Настройка директорий Samba

```bash
# Создание директорий
sudo mkdir -p /var/spool/samba
sudo mkdir -p /var/lib/samba/printers

# Права
sudo chown -R root:lp /var/spool/samba
sudo chmod 1777 /var/spool/samba

sudo chown -R root:lpadmin /var/lib/samba/printers
sudo chmod 2775 /var/lib/samba/printers
```

### Пользователи Samba

```bash
# Добавить пользователя в Samba
sudo smbpasswd -a username
# Введите пароль

# Активировать пользователя
sudo smbpasswd -e username

# Удалить пользователя
sudo smbpasswd -x username

# Список пользователей
sudo pdbedit -L
```

### Перезапуск Samba

```bash
sudo systemctl restart smb
sudo systemctl restart nmb

# Проверка
sudo systemctl status smb
sudo systemctl status nmb

# Тест конфигурации
testparm
```

---

## Настройка Avahi (обнаружение)

### Конфигурация Avahi

```bash
sudo nano /etc/avahi/avahi-daemon.conf
```

```ini
[server]
host-name=printserver
use-ipv4=yes
use-ipv6=yes
allow-interfaces=eth0

[wide-area]
enable-wide-area=yes

[publish]
publish-addresses=yes
publish-hinfo=yes
publish-workstation=yes
publish-domain=yes
publish-dns-servers=192.168.1.1
publish-resolv-conf-dns-servers=yes

[reflector]
enable-reflector=no

[rlimits]
rlimit-as=
rlimit-core=0
rlimit-data=8388608
rlimit-fsize=0
rlimit-nofile=768
rlimit-stack=8388608
rlimit-nproc=3
```

### Перезапуск Avahi

```bash
sudo systemctl restart avahi-daemon
sudo systemctl status avahi-daemon

# Проверка обнаружения
avahi-browse -rt _ipp._tcp
avahi-browse -rt _printer._tcp

# Пример вывода:
# + eth0 IPv4 HP LaserJet Pro M404n @ printserver   Internet Printer     local
#   hostname = [printserver.local]
#   address = [192.168.1.10]
#   port = [631]
```

---

## Интеграция с Windows-клиентами

### Подключение принтера из Windows

#### Через «Добавить принтер»

1. **Панель управления → Устройства и принтеры → Добавить принтер**
2. Выбрать «Необходимый принтер отсутствует в списке»
3. Выбрать «Выбрать общий принтер по имени»
4. Ввести: `\\PRINTSERVER\printer_name`
5. Установить драйвер (Windows может загрузить автоматически)

#### Через командную строку Windows

```cmd
rem Подключение сетевого принтера
rundll32 printui.dll,PrintUIEntry /in /n \\PRINTSERVER\office-hp-laserjet

rem Установка принтера по умолчанию
rundll32 printui.dll,PrintUIEntry /y /n \\PRINTSERVER\office-hp-laserjet

rem Через PowerShell
Add-Printer -ConnectionName \\PRINTSERVER\office-hp-laserjet
```

#### Через Group Policy

См. раздел [Групповые политики (GPO)](#групповые-политики-gpo).

### Установка Windows-драйверов на сервер

```bash
# Установить Samba-утилиты для драйверов
sudo dnf install -y samba-winbind-clients

# Загрузить драйверы Windows через cupsaddsmb
sudo cupsaddsmb -H localhost -U root -a -v

# Или вручную скопировать драйверы
sudo mkdir -p /var/lib/samba/printers/W32X86/3
sudo mkdir -p /var/lib/samba/printers/x64/3

# Копирование PPD и DLL драйверов
sudo cp driver.ppd /var/lib/samba/printers/x64/3/
sudo cp driver.dll /var/lib/samba/printers/x64/3/
```

### Подключение Linux-клиента

```bash
# Автоматическое обнаружение (Avahi)
# Принтер появится в списке доступных автоматически

# Ручное подключение
sudo lpadmin -p remote-printer -E \
    -v ipp://printserver.local/printers/office-hp-laserjet \
    -m everywhere

# Или через CUPS веб-интерфейс
# http://printserver:631/printers/
```

---

## Управление очередями печати

### Просмотр и управление

```bash
# Все принтеры и их статус
lpstat -p -d

# Очередь конкретного принтера
lpq -P office-hp-laserjet

# Все задания
lpstat -o

# Подробная информация
lpstat -t

# Отмена задания
cancel job_id
lprm job_id

# Отмена всех заданий принтера
cancel -a office-hp-laserjet

# Приостановить принтер
cupsdisable office-hp-laserjet

# Возобновить печать
cupsenable office-hp-laserjet

# Отклонять новые задания
cupsreject office-hp-laserjet

# Разрешить новые задания
cupsaccept office-hp-laserjet
```

### Приоритеты очередей

```bash
# Печать с приоритетом (1-100, по умолчанию 50)
lp -p 80 -d office-hp-laserjet important.pdf

# Изменение приоритета существующего задания
lpmove old_job_id new_printer
```

### Управление через веб-интерфейс

```
http://printserver:631/printers/     — все принтеры
http://printserver:631/jobs/          — все задания
http://printserver:631/admin/         — администрирование
```

---

## Управление пользователями

### Создание пользователей для печати

```bash
# Создать пользователя для печати
sudo useradd -s /sbin/nologin -G lp,sys printuser1
sudo passwd printuser1

# Добавить существующего пользователя в группу печати
sudo usermod -aG lp,sys username

# Создать группу для печати
sudo groupadd printers-users
sudo usermod -aG printers-users username
```

### Ограничение доступа к принтерам

```bash
# Редактирование cupsd.conf
sudo nano /etc/cups/cupsd.conf
```

```apache
# Разрешить печать только определённым пользователям
<Location /printers/office-hp-laserjet>
    Order deny,allow
    Deny From All
    Allow From @LOCAL
    Require user @printers-users
    AuthType Default
</Location>

# Только для определённых IP
<Location /printers/office-xerox>
    Order deny,allow
    Deny From All
    Allow From 192.168.1.0/24
    Allow From 10.0.0.50
</Location>
```

### Сброс и перезагрузка

```bash
# После изменений конфигурации
sudo systemctl restart cups

# Проверка
lpstat -a
```

---

## Квоты печати

### Установка квот через PageLog

```bash
# Включение постраничного логирования
# cupsd.conf:
# PageLogFormat %p %u %j %T %P %C %{job-billing} %{job-originating-host-name}

# Скрипт подсчёта страниц
cat > /usr/local/bin/print-quota-check.sh << 'EOF'
#!/bin/bash
# print-quota-check.sh — Проверка квот печати

PAGE_LOG="/var/log/cups/page_log"
QUOTA_FILE="/etc/cups/print-quota.conf"
QUOTA_LIMIT=1000  # страниц в месяц

echo "=== Статистика печати ==="
echo ""

# Подсчёт по пользователям
echo "Пользователь | Страниц | Лимит | Статус"
echo "-------------|---------|-------|-------"

awk '{print $2}' "$PAGE_LOG" | sort | uniq -c | sort -rn | while read count user; do
    if [[ $count -ge $QUOTA_LIMIT ]]; then
        status="⚠️ ПРЕВЫШЕН"
    else
        remaining=$((QUOTA_LIMIT - count))
        status="OK ($remaining ост.)"
    fi
    printf "%-12s | %7d | %5d | %s\n" "$user" "$count" "$QUOTA_LIMIT" "$status"
done

echo ""
echo "Общий лимит: $QUOTA_LIMIT страниц/месяц"
EOF

chmod +x /usr/local/bin/print-quota-check.sh

# Проверка
/usr/local/bin/print-quota-check.sh
```

### Автоматическое ограничение

```bash
#!/bin/bash
# print-quota-enforce.sh — Автоматическое ограничение при превышении

PAGE_LOG="/var/log/cups/page_log"
QUOTA_LIMIT="${1:-1000}"

# Получить пользователей, превысивших лимит
awk '{print $2}' "$PAGE_LOG" | sort | uniq -c | sort -rn | while read count user; do
    if [[ $count -ge $QUOTA_LIMIT ]]; then
        echo "[$(date)] ПРЕВЫШЕНИЕ: $user — $count страниц" >> /var/log/print-quota.log

        # Отключить принтеры для пользователя
        for printer in $(lpstat -p | awk '{print $2}'); do
            # Удалить активные задания пользователя
            lpstat -o "$printer" 2>/dev/null | grep "$user" | awk '{print $2}' | xargs -r cancel
        done
    fi
done
```

### Настройка cron для автоматической проверки

```bash
# Ежедневная проверка
echo "0 8 * * * root /usr/local/bin/print-quota-check.sh >> /var/log/print-quota-daily.log" | \
    sudo tee /etc/cron.d/print-quota

# Ежемесячный сброс статистики
echo "0 0 1 * * root mv /var/log/cups/page_log /var/log/cups/page_log.$(date +\%Y\%m)" | \
    sudo tee -a /etc/cron.d/print-quota
```

---

## Логирование и мониторинг

### Основные логи

| Лог | Путь | Описание |
|-----|------|----------|
| CUPS error | `/var/log/cups/error_log` | Ошибки CUPS |
| CUPS access | `/var/log/cups/access_log` | Доступ к CUPS |
| CUPS page | `/var/log/cups/page_log` | Постраничный учёт |
| Samba | `/var/log/samba/log.%m` | Логи Samba |
| Avahi | `journalctl -u avahi-daemon` | Логи Avahi |

### Настройка логирования

```bash
# Увеличить уровень логирования CUPS
sudo cupsctl --debug-logging

# Отключить (после отладки)
sudo cupsctl --no-debug-logging
```

### Мониторинг через скрипт

```bash
#!/bin/bash
# print-monitor.sh — Мониторинг сервера печати

echo "=== Мониторинг сервера печати ==="
echo ""

# Службы
echo "── Службы ──"
for svc in cups smb nmb avahi-daemon; do
    status=$(systemctl is-active "$svc" 2>/dev/null)
    echo "  $svc: $status"
done

echo ""

# Принтеры
echo "── Принтеры ──"
lpstat -p | while read -r line; do
    status=$(echo "$line" | grep -oP '(idle|printing|disabled)')
    name=$(echo "$line" | awk '{print $2}')
    echo "  $name: $status"
done

echo ""

# Очередь
echo "── Очередь ──"
jobs=$(lpstat -o 2>/dev/null | wc -l)
echo "  Заданий в очереди: $jobs"

if [[ $jobs -gt 0 ]]; then
    lpstat -o
fi

echo ""

# Диск
echo "── Диск (/var/spool) ──"
du -sh /var/spool/cups 2>/dev/null | while read size path; do
    echo "  $path: $size"
done

echo ""

# Сетевые подключения
echo "── Сетевые подключения ──"
ss -tlnp | grep -E '631|445|5353'
```

### SNMP-мониторинг

```bash
# Установка SNMP-утилит
sudo dnf install -y net-snmp net-snmp-utils

# Проверка статуса принтера через SNMP
snmpwalk -v 2c -c public 192.168.1.100 \
    .1.3.6.1.2.1.43.11.1.1.9  # Уровень тонера

snmpwalk -v 2c -c public 192.168.1.100 \
    .1.3.6.1.2.1.43.10.2.1.4  # Счётчик страниц
```

---

## Интеграция с Active Directory

### Подготовка

```bash
# Установка необходимых пакетов
sudo dnf install -y realmd sssd oddjob oddjob-mkhomedir
sudo dnf install -y adcli samba-winbind samba-winbind-clients
sudo dnf install -y krb5-workstation

# Проверка обнаружения домена
realm discover example.com
```

### Ввод в домен

```bash
# Ввод в домен
sudo realm join --user=admin example.com

# Проверка
realm list

# Настройка SSSD
sudo nano /etc/sssd/sssd.conf
```

```ini
[sssd]
domains = example.com
config_file_version = 2
services = nss, pam

[domain/example.com]
ad_domain = example.com
krb5_realm = EXAMPLE.COM
realmd_tags = manages-system joined-with-adcli
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%u
access_provider = ad
```

### Настройка Samba с AD

```bash
sudo nano /etc/samba/smb.conf
```

```ini
[global]
    workgroup = EXAMPLE
    realm = EXAMPLE.COM
    security = ads
    encrypt passwords = yes

    # Интеграция с SSSD
    idmap config * : backend = tdb
    idmap config * : range = 10000-99999
    idmap config EXAMPLE : backend = ad
    idmap config EXAMPLE : range = 100000-999999

    # Настройки печати
    load printers = yes
    printing = cups
    printcap name = cups
    cups options = raw
```

### Разрешение группам AD печатать

```bash
# В cupsd.conf
<Location /printers>
    AuthType Basic
    Require user @AD-Print-Users
    Order allow,deny
    Allow from @LOCAL
</Location>

# Или через PAM
sudo nano /etc/pam.d/cups
# Добавить:
# auth    sufficient    pam_sss.so
# account sufficient    pam_sss.so
```

### Проверка интеграции

```bash
# Проверить пользователя AD
id user@example.com

# Проверить группу AD
getent group "AD-Print-Users"

# Проверить аутентификацию
su - user@example.com
```

---

## Групповые политики (GPO)

### Развёртывание принтеров через GPO

Создайте GPO в Active Directory для автоматического подключения принтеров:

#### PowerShell-скрипт для GPO (Startup Script)

```powershell
# deploy-printers.ps1
# Размещается в: Computer Configuration → Policies → Windows Settings → Scripts (Startup)

$PrintServer = "\\PRINTSERVER"

$Printers = @(
    "office-hp-laserjet"
    "office-xerox"
    "office-brother"
)

foreach ($printer in $Printers) {
    $printerPath = "$PrintServer\$printer"

    # Проверка, не подключён ли уже
    $existing = Get-Printer -Name $printerPath -ErrorAction SilentlyContinue

    if (-not $existing) {
        try {
            Add-Printer -ConnectionName $printerPath
            Write-Host "Подключён: $printerPath"
        } catch {
            Write-Host "Ошибка подключения: $printerPath — $_"
        }
    }
}

# Установка принтера по умолчанию
Set-Printer -Name "$PrintServer\office-hp-laserjet" -Shared $true
```

#### GPO через Preferences

1. **Group Policy Management → GPO → Edit**
2. **User Configuration → Preferences → Control Panel Settings → Printers**
3. **New → Shared Printer**
4. Указать `\\PRINTSERVER\printer_name`
5. Action: **Update**

### Скрипт удаления принтеров через GPO

```powershell
# remove-old-printers.ps1
# Размещается в: Computer Configuration → Policies → Windows Settings → Scripts (Startup)

$OldPrinters = @(
    "\\OLDSERVER\old-printer-1"
    "\\OLDSERVER\old-printer-2"
)

foreach ($printer in $OldPrinters) {
    try {
        Remove-Printer -Name $printer -ErrorAction Stop
        Write-Host "Удалён: $printer"
    } catch {
        Write-Host "Не найден: $printer"
    }
}
```

---

## Резервное копирование конфигурации

### Скрипт резервного копирования

```bash
#!/bin/bash
# backup-print-server.sh — Резервное копирование конфигурации сервера печати

set -euo pipefail

BACKUP_DIR="/backup/print-server"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

# Цвета
GREEN='\033[0;32m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

mkdir -p "$BACKUP_PATH"

# 1. Конфигурация CUPS
log_info "Резервное копирование CUPS..."
cp -r /etc/cups/ "$BACKUP_PATH/cups/"

# 2. PPD-файлы
log_info "Резервное копирование PPD..."
cp -r /etc/cups/ppd/ "$BACKUP_PATH/ppd/"

# 3. Конфигурация Samba
log_info "Резервное копирование Samba..."
cp /etc/samba/smb.conf "$BACKUP_PATH/smb.conf"

# 4. Конфигурация Avahi
log_info "Резервное копирование Avahi..."
cp -r /etc/avahi/ "$BACKUP_PATH/avahi/"

# 5. Firewall
log_info "Резервное копирование Firewall..."
sudo firewall-cmd --list-all > "$BACKUP_PATH/firewall.txt"

# 6. Список принтеров
log_info "Сохранение списка принтеров..."
lpstat -p -d > "$BACKUP_PATH/printers-list.txt"

# 7. Samba пользователи
log_info "Сохранение пользователей Samba..."
pdbedit -L > "$BACKUP_PATH/samba-users.txt"

# 8. Логи (последние)
log_info "Резервное копирование логов..."
mkdir -p "$BACKUP_PATH/logs"
cp /var/log/cups/page_log "$BACKUP_PATH/logs/" 2>/dev/null || true
cp /var/log/cups/error_log "$BACKUP_PATH/logs/" 2>/dev/null || true

# 9. Архивирование
log_info "Создание архива..."
tar -czf "$BACKUP_DIR/print-server-backup_$TIMESTAMP.tar.gz" \
    -C "$BACKUP_DIR" "backup_$TIMESTAMP"

# Очистка временных файлов
rm -rf "$BACKUP_PATH"

# Удаление старых бэкапов (старше 90 дней)
log_info "Очистка старых бэкапов..."
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +90 -delete

log_info "Бэкап сохранён: $BACKUP_DIR/print-server-backup_$TIMESTAMP.tar.gz"
ls -lh "$BACKUP_DIR/print-server-backup_$TIMESTAMP.tar.gz"
```

### Восстановление из резервной копии

```bash
#!/bin/bash
# restore-print-server.sh — Восстановление конфигурации

BACKUP_FILE="$1"

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Использование: $0 <backup-file.tar.gz>"
    exit 1
fi

echo "Восстановление из: $BACKUP_FILE"

# Остановка служб
systemctl stop cups
systemctl stop smb
systemctl stop nmb

# Распаковка
TEMP_DIR=$(mktemp -d)
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Восстановление CUPS
cp -r "$TEMP_DIR"/*/cups/ /etc/
cp -r "$TEMP_DIR"/*/ppd/ /etc/cups/ 2>/dev/null || true

# Восстановление Samba
cp "$TEMP_DIR"/*/smb.conf /etc/samba/

# Восстановление Avahi
cp -r "$TEMP_DIR"/*/avahi/ /etc/ 2>/dev/null || true

# Запуск служб
systemctl start cups
systemctl start smb
systemctl start nmb

echo "Восстановление завершено"

# Проверка
lpstat -p -d
testparm
```

### Настройка cron для автоматического бэкапа

```bash
# Ежедневный бэкап в 2:00
echo "0 2 * * * root /usr/local/bin/backup-print-server.sh" | \
    sudo tee /etc/cron.d/print-server-backup
```

---

## Автоматический скрипт настройки

### setup-print-server.sh

```bash
#!/bin/bash
# setup-print-server.sh — Автоматическая настройка сервера печати
# Использование: sudo bash setup-print-server.sh [--interactive]

set -euo pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INTERACTIVE=false
for arg in "$@"; do
    [[ "$arg" == "--interactive" ]] && INTERACTIVE=true
done

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $1"; }

# Проверка root
if [[ $EUID -ne 0 ]]; then
    log_error "Запустите с sudo"
    exit 1
fi

# Получение сетевого интерфейса
get_network() {
    local ip=$(hostname -I | awk '{print $1}')
    local subnet=$(echo "$ip" | cut -d. -f1-3).0/24
    echo "$subnet"
}

# Установка пакетов
install_packages() {
    log_step "Установка пакетов..."

    dnf install -y cups cups-client cups-filters
    dnf install -y samba samba-client
    dnf install -y avahi avahi-tools
    dnf install -y system-config-printer
    dnf install -y python3-cups
    dnf install -y firewalld

    log_info "Пакеты установлены"
}

# Настройка CUPS
setup_cups() {
    log_step "Настройка CUPS..."

    local subnet=$(get_network)

    # Резервное копирование
    cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.bak

    # Настройка
    cat > /etc/cups/cupsd.conf << EOF
# Сервер печати РЕД ОС — Автоконфигурация
Port 631
Listen /run/cups/cups.sock

Browsing On
BrowseLocalProtocols dnssd

DefaultAuthType Basic
WebInterface Yes

<Location />
    Order allow,deny
    Allow @LOCAL
    Allow $subnet
</Location>

<Location /admin>
    Order allow,deny
    Allow @LOCAL
</Location>

<Location /admin/conf>
    AuthType Default
    Require user @SYSTEM
    Order allow,deny
    Allow localhost
</Location>

PreserveJobHistory Yes
PreserveJobFiles Yes
LogLevel info
EOF

    systemctl enable --now cups
    log_info "CUPS настроен"
}

# Настройка Samba
setup_samba() {
    log_step "Настройка Samba..."

    cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

    cat > /etc/samba/smb.conf << EOF
[global]
    server string = Print Server РЕД ОС
    netbios name = $(hostname | tr 'a-z' 'A-Z' | cut -c1-15)
    workgroup = WORKGROUP
    security = user
    map to guest = Bad User
    load printers = yes
    printing = cups
    printcap name = cups
    cups options = raw
    guest ok = no
    log file = /var/log/samba/log.%m
    max log size = 1000

[printers]
    comment = Все принтеры
    path = /var/spool/samba
    printable = yes
    guest ok = no
    read only = yes
    create mask = 0700

[print\$]
    comment = Драйверы принтеров
    path = /var/lib/samba/printers
    browseable = yes
    read only = no
    guest ok = no
    write list = root, @lpadmin
EOF

    mkdir -p /var/spool/samba
    mkdir -p /var/lib/samba/printers
    chmod 1777 /var/spool/samba
    chmod 2775 /var/lib/samba/printers

    systemctl enable --now smb
    systemctl enable --now nmb
    log_info "Samba настроена"
}

# Настройка Avahi
setup_avahi() {
    log_step "Настройка Avahi..."

    systemctl enable --now avahi-daemon
    log_info "Avahi настроен"
}

# Настройка firewall
setup_firewall() {
    log_step "Настройка firewall..."

    firewall-cmd --permanent --add-service=ipp
    firewall-cmd --permanent --add-service=ipp-client
    firewall-cmd --permanent --add-service=samba
    firewall-cmd --permanent --add-service=mdns
    firewall-cmd --reload

    log_info "Firewall настроен"
}

# Финальная проверка
final_check() {
    echo ""
    log_info "=== Сервер печати настроен ==="
    echo ""
    echo "Службы:"
    for svc in cups smb nmb avahi-daemon; do
        status=$(systemctl is-active "$svc")
        echo "  ✅ $svc: $status"
    done
    echo ""
    echo "IP-адрес: $(hostname -I | awk '{print $1}')"
    echo "CUPS: http://$(hostname -I | awk '{print $1}'):631"
    echo "Samba: \\\\$(hostname | tr 'a-z' 'A-Z' | cut -c1-15)"
    echo ""
    echo "Добавьте принтеры через:"
    echo "  sudo lpadmin -p printer_name -E -v uri -m everywhere"
    echo "  или http://$(hostname -I | awk '{print $1}'):631/admin"
}

# Интерактивный режим
if [[ "$INTERACTIVE" == true ]]; then
    log_info "=== Интерактивная настройка сервера печати ==="
    read -p "Имя рабочей группы [WORKGROUP]: " workgroup
    workgroup="${workgroup:-WORKGROUP}"
fi

# Запуск
main() {
    log_info "=== Настройка сервера печати на РЕД ОС ==="
    install_packages
    setup_cups
    setup_samba
    setup_avahi
    setup_firewall
    final_check
}

main
```

Использование:

```bash
# Автоматическая настройка
sudo bash setup-print-server.sh

# Интерактивный режим
sudo bash setup-print-server.sh --interactive
```

---

## Справочник команд

### Управление CUPS

| Команда | Описание |
|---------|----------|
| `lpstat -p -d` | Список принтеров и принтер по умолчанию |
| `lpstat -t` | Полная информация |
| `lpstat -o` | Текущие задания |
| `lpq -P name` | Очередь принтера |
| `cancel -a` | Отменить все задания |
| `cupsdisable name` | Приостановить принтер |
| `cupsenable name` | Возобновить печать |
| `lpadmin -p name -E -v uri -m ppd` | Добавить принтер |
| `lpadmin -x name` | Удалить принтер |
| `lpadmin -d name` | Принтер по умолчанию |
| `lpadmin -p name -c class` | Добавить в класс |

### Управление Samba

| Команда | Описание |
|---------|----------|
| `testparm` | Проверить конфигурацию |
| `smbpasswd -a user` | Добавить пользователя |
| `pdbedit -L` | Список пользователей |
| `systemctl restart smb` | Перезапустить Samba |

### Мониторинг

| Команда | Описание |
|---------|----------|
| `lpinfo -v` | Список доступных устройств |
| `lpinfo -m` | Список доступных драйверов |
| `cupsctl` | Параметры CUPS |
| `avahi-browse -rt _ipp._tcp` | Обнаружение принтеров |
| `ss -tlnp \| grep 631` | Проверка порта CUPS |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **CUPS** | 2.4.x |
| **Samba** | 4.17.x+ |
| **Avahi** | 0.8+ |
| **Firewall** | firewalld |
| **AD-интеграция** | realmd + sssd |
| **Сеть** | Требуется для клиентского доступа |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> CUPS + Samba работают одинаково в обеих версиях. Samba может потребовать адаптации конфигов для 8.x.

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
