# 🖨️ Универсальная настройка принтеров в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

Полное руководство по подключению и настройке принтеров всех основных производителей в РЕД ОС. Охватывает HP, Canon, Epson, Brother, Xerox, Samsung, Pantum — через CUPS с использованием фирменных и универсальных драйверов.

---

## 📋 Оглавление

1. [Архитектура печати CUPS](#архитектура-печати-cups)
2. [Установка и базовая настройка CUPS](#установка-и-базовая-настройка-cups)
3. [Веб-интерфейс CUPS](#веб-интерфейс-cups)
4. [Принтеры HP (HPLIP)](#принтеры-hp-hplip)
5. [Принтеры Canon (UFRII/ScanGear)](#принтеры-canon-ufriiscangear)
6. [Принтеры Epson (ESC/P-R)](#принтеры-epson-escp-r)
7. [Принтеры Brother](#принтеры-brother)
8. [Принтеры Xerox](#принтеры-xerox)
9. [Принтеры Samsung](#принтеры-samsung)
10. [Принтеры Pantum](#принтеры-pantum)
11. [Сетевая печать](#сетевая-печать)
12. [Универсальные драйверы](#универсальные-драйверы)
13. [Диагностика и устранение проблем](#диагностика-и-устранение-проблем)
14. [Автоматический скрипт установки](#автоматический-скрипт-установки)
15. [Справочник команд](#справочник-команд)
16. [Требования и совместимость](#требования-и-совместимость)

---

## Архитектура печати CUPS

**CUPS** (Common UNIX Printing System) — стандартная система печати в Linux, используемая в РЕД ОС.

### Компоненты CUPS

```
┌─────────────────────────────────────────────┐
│           Приложение (LibreOffice и др.)     │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│              cups-filters                    │
│     (фильтры: PDF → PCL/PostScript)         │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│         Драйвер принтера (PPD)              │
│  Gutenprint / Foomatic / фирменный          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│         Бэкенд CUPS (usb/ipp/socket)        │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│              Принтер                         │
└─────────────────────────────────────────────┘
```

### Основные пакеты

| Пакет | Назначение |
|-------|-----------|
| `cups` | Основной сервер печати |
| `cups-client` | Клиентские утилиты (lp, lpr, lpstat) |
| `cups-filters` | Фильтры для преобразования форматов |
| `cups-ppdc` | Компилятор PPD-файлов |
| `system-config-printer` | Графический инструмент настройки |
| `python3-cups` | Python-библиотека для работы с CUPS |

---

## Установка и базовая настройка CUPS

### 1. Установка пакетов

```bash
# Установка основной системы печати
sudo dnf install -y cups cups-client cups-filters system-config-printer

# Включение и запуск службы
sudo systemctl enable cups
sudo systemctl start cups

# Проверка статуса
systemctl status cups
```

### 2. Настройка прав доступа

По умолчанию CUPS доступен только с localhost. Для сетевого доступа:

```bash
# Редактирование конфигурации
sudo nano /etc/cups/cupsd.conf
```

Основные директивы:

```apache
# Прослушивать все интерфейсы (для сетевого сервера)
Listen 0.0.0.0:631
Listen [::]:631

# Или только локальный порт (по умолчанию)
Listen localhost:631

# Разрешить доступ из локальной сети
<Location />
    Order allow,deny
    Allow @LOCAL
</Location>

<Location /admin>
    Order allow,deny
    Allow @LOCAL
</Location>
```

После изменений перезапустите службу:

```bash
sudo systemctl restart cups
```

### 3. Открытие порта в firewall

```bash
# Для firewalld
sudo firewall-cmd --permanent --add-service=ipp
sudo firewall-cmd --permanent --add-service=ipp-client
sudo firewall-cmd --permanent --add-port=631/tcp
sudo firewall-cmd --reload

# Проверка
sudo firewall-cmd --list-all
```

---

## Веб-интерфейс CUPS

CUPS предоставляет удобный веб-интерфейс для управления принтерами.

### Доступ

```
http://localhost:631           — основной интерфейс
http://localhost:631/admin     — административная панель
http://localhost:631/printers  — список принтеров
http://localhost:631/jobs      — очередь заданий
```

### Основные операции через веб-интерфейс

1. **Добавление принтера**: `Administration → Add Printer`
2. **Настройка общего доступа**: `Administration → Share printers connected to this system`
3. **Управление заданиями**: `Jobs → Show completed jobs / Show all jobs`
4. **Настройка параметров**: `Printers → Select printer → Administration → Set Default Options`

### Аутентификация

Для доступа к админ-панели используется учётная запись пользователя с правами `root` или входящего в группу `sys`:

```bash
# Добавить пользователя в группу sys
sudo usermod -aG sys username
```

---

## Принтеры HP (HPLIP)

### Поддерживаемые модели

| Серия | Примеры моделей | Драйвер | Примечание |
|-------|----------------|---------|------------|
| **LaserJet Pro** | M404n, M428fdw, M130fw | HPLIP / PCLm | Полная поддержка |
| **LaserJet Enterprise** | M507, M609, M631 | HPLIP / PostScript | Полная поддержка |
| **Color LaserJet** | Pro M454, MFP M479 | HPLIP / PCLm | Полная поддержка |
| **DeskJet** | 2700, 3700, 4100 | HPLIP | Полная поддержка |
| **OfficeJet** | Pro 8020, 9010, 9020 | HPLIP | Полная поддержка |
| **Neverstop Laser** | 1202w, 500x | HPLIP | Полная поддержка |

### Установка HPLIP

```bash
# Установка HPLIP из репозитория
sudo dnf install -y hplip hplip-gui

# Установка зависимостей
sudo dnf install -y python3-dbus python3-gobject python3-pyqt5
sudo dnf install -y sane-backends-drivers-scanners
```

### Настройка принтера HP

#### Автоматическая установка (рекомендуется)

```bash
# Запустить мастер настройки
hp-setup

# Мастер в интерактивном режиме:
# 1. Обнаружит принтер (USB или сеть)
# 2. Загрузит необходимый плагин
# 3. Установит и настроит принтер

# Установка сетевого принтера по IP
hp-setup -i 192.168.1.100

# Установка USB-принтера
hp-setup -i -x
```

#### Ручная настройка через CUPS

```bash
# 1. Найти URI принтера
hp-makeuri 192.168.1.100

# 2. Добавить принтер в CUPS
sudo lpadmin -p hp-laserjet -v hp:/net/HP_LaserJet_Pro_M404n?ip=192.168.1.100 -E

# 3. Установить PPD
sudo lpadmin -p hp-laserjet -m everywhere

# 4. Сделать принтером по умолчанию
lpoptions -d hp-laserjet
```

### Установка проприетарного плагина

Некоторые модели HP требуют проприетарный плагин:

```bash
# Проверка необходимости плагина
hp-check -t

# Установка плагина
hp-plugin -i

# Следуйте инструкциям мастера для загрузки плагина
```

### Управление картриджами и диагностика

```bash
# Проверка уровня чернил/тонера
hp-levels

# Проверка состояния принтера
hp-info

# Диагностика
hp-doctor

# Проверка качества печати (тестовая страница)
hp-testpage
```

### Таблица совместимости HP

| Модель | USB | Сеть | Сканирование | Драйвер |
|--------|-----|------|-------------|---------|
| LaserJet Pro M404n | ✅ | ✅ | ❌ | HPLIP |
| LaserJet Pro M428fdw | ✅ | ✅ | ✅ | HPLIP |
| LaserJet Pro M130fw | ✅ | ✅ | ✅ | HPLIP |
| Color LaserJet M454dn | ✅ | ✅ | ❌ | HPLIP |
| Color LaserJet MFP M479fdw | ✅ | ✅ | ✅ | HPLIP |
| DeskJet 2720 | ✅ | ✅ | ✅ | HPLIP |
| OfficeJet Pro 8020 | ✅ | ✅ | ✅ | HPLIP |
| OfficeJet Pro 9010 | ✅ | ✅ | ✅ | HPLIP |
| Neverstop Laser 1202w | ✅ | ✅ | ❌ | HPLIP |
| LaserJet M107a | ⚠️ | ❌ | ✅ | ump + Gutenprint |

> [!warning]
> **HP LaserJet M107a / M132 серии** — используют GDI-архитектуру и требуют специальный драйвер `foo2zjs` или `splix`. Поддержка может быть ограничена.

---

## Принтеры Canon (UFRII/ScanGear)

### Архитектура драйверов Canon

| Драйвер | Тип | Модели |
|---------|-----|--------|
| **UFRII LT** | Лазерные | imageCLASS/LBP серии |
| **UFRII** | Лазерные | imageCLASS/LBP серии (старшие) |
| **LIPSLX** | Лазерные | Satera серии |
| **CNUPSBJ** | Струйные | PIXMA серии |
| **ScanGear** | Сканеры | МФУ серии |

### Установка драйвера Canon UFRII

```bash
# Скачивание драйвера с официального сайта
# https://www.canon.ru/support/

# Распаковка архива
tar -xzf Linux_UFRII_PrinterDriver_V*.tar.gz
cd Linux_UFRII_PrinterDriver_V*/RPM

# Установка RPM-пакетов
sudo dnf install -y cndrvcups-ufr2-*.rpm
sudo dnf install -y cndrvcups-ufr2-uk-*.rpm

# Перезапуск CUPS
sudo systemctl restart cups
```

### Установка драйвера Canon для струйных принтеров

```bash
# Распаковка архива
tar -xzf cnijfilter2-*.tar.gz
cd cnijfilter2-*/

# Запуск установщика
sudo ./install.sh

# Или ручная установка RPM
cd RPM/
sudo dnf install -y *.rpm
```

### Настройка через CUPS

```bash
# Поиск доступных PPD Canon
lpinfo -m | grep -i canon

# Добавление принтера
sudo lpadmin -p canon-mf644 -E -v usb://Canon/MF644Cdw%20Series \
    -m CANON_MF644C.ppd

# Сетевой принтер
sudo lpadmin -p canon-mf644-net -E \
    -v socket://192.168.1.50:9100 \
    -m CANON_MF644C.ppd

# Проверка
lpstat -p canon-mf644
```

### Таблица совместимости Canon

| Модель | Тип | Драйвер | Примечание |
|--------|-----|---------|------------|
| imageCLASS MF269dw | Лазерный МФУ | UFRII | Полная поддержка |
| imageCLASS MF264dw | Лазерный МФУ | UFRII | Полная поддержка |
| imageCLASS MF450dw | Лазерный МФУ | UFRII | Полная поддержка |
| imageCLASS MF644Cdw | Лазерный МФУ | UFRII | Полная поддержка |
| i-SENSYS LBP223dw | Лазерный | UFRII LT | Полная поддержка |
| i-SENSYS LBP6030 | Лазерный | CAPT | Требуется CAPT драйвер |
| PIXMA G3420 | Струйный | CNUPSBJ | Полная поддержка |
| PIXMA TS3340 | Струйный | CNUPSBJ | Полная поддержка |
| PIXMA G2411 | Струйный | CNUPSBJ | Полная поддержка |
| MAXIFY GX4040 | Струйный | CNUPSBJ | Полная поддержка |

> [!note]
> **Принтеры Canon с драйвером CAPT** (LBP6030, LBP2900) требуют отдельного драйвера `cndrvcups-capt`, который может быть недоступен в репозиториях РЕД ОС. Скачайте с сайта Canon.

---

## Принтеры Epson (ESC/P-R)

### Архитектура драйверов Epson

| Драйвер | Тип | Описание |
|---------|-----|----------|
| **ESC/P-R** | Универсальный | Современный универсальный драйвер |
| **Epson Inkjet** | Фирменный | Для конкретных моделей струйных |
| **Epson Avasys** | Фирменный | Старые модели (через Avasys.jp) |
| **Gutenprint** | Универсальный | Через стандартный CUPS |

### Установка универсального драйвера ESC/P-R

```bash
# Установка из репозитория
sudo dnf install -y epson-inkjet-printer-escpr

# Для новых моделей (ESC/P-R 2)
sudo dnf install -y epson-inkjet-printer-escpr2
```

### Установка фирменного драйвера

```bash
# Скачивание с https://download.ebz.epson.net/dsc/search/01/search/
# Выбор RPM-пакета

# Установка
sudo dnf install -y epson-inkjet-printer-202401w-1.0.0-1lsb3.2.x86_64.rpm

# Перезапуск CUPS
sudo systemctl restart cups
```

### Настройка

```bash
# Поиск PPD Epson
lpinfo -m | grep -i epson

# Добавление USB-принтера
sudo lpadmin -p epson-l3250 -E \
    -v usb://EPSON/L3250%20Series \
    -m epson-escpr-l3250.ppd

# Сетевой принтер
sudo lpadmin -p epson-l3250-net -E \
    -v socket://192.168.1.75:9100 \
    -m epson-escpr-l3250.ppd
```

### Таблица совместимости Epson

| Модель | Тип | Драйвер | Примечание |
|--------|-----|---------|------------|
| EcoTank L3250 | Струйный МФУ | ESC/P-R | Полная поддержка |
| EcoTank L3150 | Струйный МФУ | ESC/P-R | Полная поддержка |
| EcoTank L805 | Струйный | ESC/P-R | Полная поддержка |
| WorkForce WF-2860 | Струйный МФУ | ESC/P-R | Полная поддержка |
| WorkForce WF-7830 | Струйный МФУ | ESC/P-R | Полная поддержка |
| AcuLaser M400DN | Лазерный | ESC/P-R | Полная поддержка |
| AcuLaser C3800N | Лазерный | ESC/P-R | Полная поддержка |
| WF-C5790 | Струйный МФУ | ESC/P-R | Полная поддержка |
| XP-6100 | Струйный МФУ | ESC/P-R | Полная поддержка |
| XP-7100 | Струйный МФУ | ESC/P-R | Полная поддержка |

---

## Принтеры Brother

### Особенности драйверов Brother

Brother предоставляет официальные RPM-пакеты для Linux, что упрощает установку в РЕД ОС.

### Установка драйвера

```bash
# 1. Скачивание драйвера
# https://support.brother.com/g/b/downloadlist.aspx
# → Выберите модель → Linux (rpm)

# Доступные типы драйверов:
# - LPR driver (печать)
# - CUPSwrapper driver (обёртка для CUPS)
# Оба нужны для полной функциональности

# 2. Установка LPR-драйвера
sudo dnf install -y brother-mfc-l2700dwr-lpr-*.rpm

# 3. Установка CUPSwrapper-драйвера
sudo dnf install -y brother-mfc-l2700dwr-cupswrapper-*.rpm
```

### Ручная установка через скрипт

```bash
# Brother часто предоставляет скрипт установки
# Распакуйте архив и запустите:
sudo bash linux-brprinter-installer-*.gsi

# Скрипт запросит:
# 1. Название модели (например: mfc-l2700dwr)
# 2. Тип подключения (USB/IP)
# 3. IP-адрес (для сетевого)
```

### Настройка через CUPS

```bash
# Поиск PPD Brother
lpinfo -m | grep -i brother

# Добавление принтера
sudo lpadmin -p brother-mfc-l2700 -E \
    -v usb://Brother/MFC-L2700DW%20series \
    -m Brother/MFC-L2700DW.ppd

# Сетевой
sudo lpadmin -p brother-mfc-l2700-net -E \
    -v socket://192.168.1.120:9100 \
    -m Brother/MFC-L2700DW.ppd
```

### Исправление типичных проблем Brother

```bash
# Если принтер не определяется, проверьте симлинк
ls -l /var/spool/lpd/

# Создание директории при необходимости
sudo mkdir -p /var/spool/lpd/ brother_mfc_l2700dwr

# Исправление прав
sudo chown -R lp:lp /var/spool/lpd/

# Для 64-битных систем может потребоваться 32-битная библиотека
sudo dnf install -y glibc.i686
```

### Таблица совместимости Brother

| Модель | Тип | Драйвер | Примечание |
|--------|-----|---------|------------|
| MFC-L2700DWR | Лазерный МФУ | Brother | Полная поддержка |
| MFC-L2750DW | Лазерный МФУ | Brother | Полная поддержка |
| DCP-L2520DWR | Лазерный МФУ | Brother | Полная поддержка |
| HL-L2300DR | Лазерный | Brother | Полная поддержка |
| HL-L2360DNR | Лазерный | Brother | Полная поддержка |
| DCP-T420W | Струйный МФУ | Brother | Полная поддержка |
| DCP-T520W | Струйный МФУ | Brother | Полная поддержка |
| MFC-T4500DW | Струйный МФУ | Brother | Полная поддержка |
| HL-L5000D | Лазерный | Brother | Полная поддержка |
| MFC-L8900CDW | Лазерный МФУ | Brother | Полная поддержка |

---

## Принтеры Xerox

### Особенности

Принтеры Xerox используют различные драйверы в зависимости от серии:

| Серия | Драйвер | Примечание |
|-------|---------|------------|
| **WorkCentre** | PostScript / PCL | Большинство поддерживаются |
| **AltaLink** | PostScript | Полная поддержка |
| **VersaLink** | PostScript / XGA | Полная поддержка |
| **B-серия** | PCL6 | Частичная поддержка |

### Установка

```bash
# Xerox часто работает с универсальными драйверами
# Попытка автоматического определения
sudo lpadmin -p xerox-b210 -E \
    -v usb://Xerox/B210 \
    -m everywhere

# Если не работает — используйте PPD из пакета
# Скачайте с https://www.support.xerox.com/

# Установка Xerox Linux драйвера
sudo dnf install -y xerox-phaser-6510-*.rpm
sudo systemctl restart cups
```

### Настройка через PPD

```bash
# Поиск PPD
lpinfo -m | grep -i xerox

# Добавление принтера с PPD
sudo lpadmin -p xerox-wc3345 -E \
    -v socket://192.168.1.200:9100 \
    -m Xerox/Xerox_WorkCentre_3345.ppd

# Для принтеров с PostScript используйте generic PPD
sudo lpadmin -p xerox-ps -E \
    -v socket://192.168.1.200:9100 \
    -m postscript.ppd
```

### Таблица совместимости Xerox

| Модель | Тип | Драйвер | Примечание |
|--------|-----|---------|------------|
| B210 | Лазерный | PCL / everywhere | Полная поддержка |
| B215 | Лазерный МФУ | PCL / everywhere | Полная поддержка |
| B225 | Лазерный МФУ | PCL | Полная поддержка |
| C235 | Цветной лазерный МФУ | PostScript | Полная поддержка |
| C325 | Цветной лазерный МФУ | PostScript | Полная поддержка |
| WorkCentre 3345 | Лазерный МФУ | PCL6 | Полная поддержка |
| WorkCentre 3315 | Лазерный МФУ | PCL6 | Полная поддержка |
| AltaLink C8130 | Цветной МФУ | PostScript | Полная поддержка |
| VersaLink C405 | Цветной МФУ | PostScript | Полная поддержка |
| Phaser 6510 | Цветной лазерный | Фирменный | Полная поддержка |

---

## Принтеры Samsung

### Особенности

Линейка принтеров Samsung была приобретена **HP в 2017 году**. Современные принтеры Samsung поддерживаются через:

1. **Samsung Unified Linux Driver (ULD)** — устаревший, но рабочий
2. **HPLIP** — для новых моделей, перемаркированных как HP
3. **Системный драйвер** — через `m2300w` или `splix`

### Установка Samsung ULD

```bash
# Скачивание Samsung ULD
# https://www.bPrinter.com/drivers/samsung-uld

# Распаковка
tar -xzf uld-linux_v*.tar.gz
cd uld/

# Установка
sudo ./install.sh

# Скрипт установит:
# - CUPS-фильтры
# - PPD-файлы
# - Утилиты конфигурации
```

### Установка через splix (GDI-принтеры)

```bash
# Установка пакета splix для GDI-принтеров Samsung/Xerox
sudo dnf install -y splix

# Поиск PPD
lpinfo -m | grep -i samsung

# Добавление принтера
sudo lpadmin -p samsung-m2020 -E \
    -v usb://Samsung/M2020 \
    -m samsung/M2020.ppd
```

### Таблица совместимости Samsung

| Модель | Тип | Драйвер | Примечание |
|--------|-----|---------|------------|
| M2020W | Лазерный | splix | Полная поддержка |
| M2070FW | Лазерный МФУ | ULD / splix | Полная поддержка |
| M2675F | Лазерный МФУ | ULD | Полная поддержка |
| M2875FD | Лазерный МФУ | ULD | Полная поддержка |
| M4580FX | Лазерный МФУ | ULD | Полная поддержка |
| C430W | Цветной лазерный | ULD | Полная поддержка |
| C480FW | Цветной лазерный МФУ | ULD | Полная поддержка |
| SCX-3405 | Лазерный МФУ | splix | Полная поддержка |
| ProXpress M4070FR | Лазерный МФУ | ULD | Полная поддержка |

---

## Принтеры Pantum

### Особенности

Pantum предоставляет официальные Linux-драйверы в формате RPM/DEB.

### Установка

```bash
# Скачивание драйвера
# https://www.pantum.ru/support/download/

# Распаковка
tar -xzf Pantum_Linux_PrinterDriver_V*.tar.gz
cd Pantum_Linux_PrinterDriver_V*/

# Установка
sudo bash install.sh

# Скрипт автоматически:
# - Определит подключённый принтер
# - Установит драйвер
# - Настроит CUPS
```

### Ручная настройка

```bash
# Установка RPM напрямую
sudo dnf install -y pantum-p2500w-*.rpm

# Перезапуск CUPS
sudo systemctl restart cups

# Поиск PPD
lpinfo -m | grep -i pantum

# Добавление принтера
sudo lpadmin -p pantum-p2500 -E \
    -v usb://Pantum/P2500W \
    -m pantum/p2500.ppd
```

### Таблица совместимости Pantum

| Модель | Тип | Драйвер | Примечание |
|--------|-----|---------|------------|
| P2500W | Лазерный | Pantum | Полная поддержка |
| P2500 | Лазерный | Pantum | Полная поддержка |
| P3300DN | Лазерный | Pantum | Полная поддержка |
| P3300DW | Лазерный | Pantum | Полная поддержка |
| M6500W | Лазерный МФУ | Pantum | Полная поддержка |
| M6500WNW | Лазерный МФУ | Pantum | Полная поддержка |
| M7100DW | Лазерный МФУ | Pantum | Полная поддержка |
| M7109FDW | Лазерный МФУ | Pantum | Полная поддержка |
| M7160DW | Лазерный МФУ | Pantum | Полная поддержка |
| BP5100DN | Лазерный | Pantum | Полная поддержка |

---

## Сетевая печать

### Протоколы сетевой печати

| Протокол | Порт | Описание | Примечание |
|----------|------|----------|------------|
| **IPP** | 631 | Internet Printing Protocol | Современный, рекомендуемый |
| **IPP Everywhere** | 631 | Бездрйверовая печать | Не требует PPD |
| **Socket (JetDirect)** | 9100 | Прямое TCP-подключение | Широко поддерживается |
| **LPD** | 515 | Line Printer Daemon | Устаревший |
| **SMB** | 445 | Windows-совместимый | Для Windows-серверов |
| **Bonjour/AirPrint** | 5353 | Apple-обнаружение | Через Avahi |

### Подключение по IPP

```bash
# Автоматическое обнаружение (IPP Everywhere)
sudo lpadmin -p office-ipp -E \
    -v ipp://192.168.1.100/ipp/print \
    -m everywhere

# С явным указанием PPD
sudo lpadmin -p office-ipp -E \
    -v ipp://192.168.1.100/ipp/print \
    -m drv:///sample.drv/generic.ppd
```

### Подключение через Socket (JetDirect)

```bash
# Наиболее универсальный метод для сетевых принтеров
sudo lpadmin -p office-socket -E \
    -v socket://192.168.1.100:9100 \
    -m everywhere

# С указанием PPD
sudo lpadmin -p office-socket -E \
    -v socket://192.168.1.100:9100 \
    -m drv:///hpcups.drv/hp-laserjet_4.ppd
```

### Подключение к Windows-серверу печати (SMB)

```bash
# Установка Samba-клиента
sudo dnf install -y samba-client cups-backend-smb

# Подключение к сетевому принтеру
sudo lpadmin -p office-smb -E \
    -v smb://username:password@server/printer_share_name \
    -m everywhere

# Без пароля в URL (безопаснее)
sudo lpadmin -p office-smb -E \
    -v smb://server/printer_share_name \
    -m everywhere
# Система запросит учётные данные при печати
```

### Автоматическое обнаружение (mDNS/DNS-SD)

```bash
# Установка Avahi
sudo dnf install -y avahi avahi-tools

# Поиск принтеров в сети
avahi-browse -rt _ipp._tcp
avahi-browse -rt _printer._tcp

# Альтернатива через lpinfo
lpinfo -v | grep -i network
```

---

## Универсальные драйверы

### Gutenprint

Набор драйверов для 2700+ моделей принтеров (Epson, Canon, HP, Lexmark и др.):

```bash
# Установка
sudo dnf install -y gutenprint gutenprint-cups

# Поиск PPD
lpinfo -m | grep -i gutenprint

# Пример использования
sudo lpadmin -p epson-stylus -E \
    -v usb://EPSON/Stylus \
    -m gutenprint.5.3://epson-stylus-photo/expert
```

### Foomatic

Фреймворк для генерации PPD из базы данных OpenPrinting:

```bash
# Установка
sudo dnf install -y foomatic foomatic-db foomatic-db-ppd

# Поиск драйвера
foomatic-searchprinter "HP LaserJet"

# Использование
lpinfo -m | grep -i foomatic
```

### Generic PPD

Встроенные универсальные драйверы CUPS:

```bash
# Посмотреть доступные generic-драйверы
lpinfo -m | grep generic

# Generic PostScript (для принтеров с поддержкой PS)
sudo lpadmin -p generic-ps -E \
    -v socket://192.168.1.100:9100 \
    -m postscript.ppd

# Generic PCL (для принтеров с поддержкой PCL)
sudo lpadmin -p generic-pcl -E \
    -v socket://192.168.1.100:9100 \
    -m drv:///sample.drv/laserjet.ppd

# Generic PDF
sudo lpadmin -p generic-pdf -E \
    -v socket://192.168.1.100:9100 \
    -m drv:///sample.drv/generic.ppd
```

### Driverless (IPP Everywhere / AirPrint)

```bash
# Проверка поддержки driverless
driverless

# Добавление driverless-принтера
sudo lpadmin -p office-driverless -E \
    -v "$(driverless | head -1)" \
    -m everywhere
```

---

## Диагностика и устранение проблем

### Основные команды диагностики

```bash
# Проверить статус CUPS
systemctl status cups

# Просмотр очереди печати
lpstat -t

# Посмотреть все принтеры
lpstat -p -d

# Проверить доступные драйверы
lpinfo -m

# Проверить доступные устройства
lpinfo -v

# Проверить статус конкретного принтера
lpstat -p printer_name

# Проверить очередь заданий
lpq -P printer_name

# Посмотреть логи CUPS
tail -f /var/log/cups/error_log
tail -f /var/log/cups/access_log
tail -f /var/log/cups/page_log

# Подробный режим логирования (для отладки)
sudo cupsctl --debug-logging
# После диагностики отключить:
sudo cupsctl --no-debug-logging
```

### Типичные проблемы и решения

| Проблема | Причина | Решение |
|----------|---------|---------|
| Принтер не определяется | USB-кабель / питание | Проверить кабель, `lsusb`, перезапустить |
| Задание зависает в очереди | Неправильный драйвер | Установить правильный PPD |
| Печатаются иероглифы | Неправильный язык (PCL/PS) | Выбрать корректный драйвер |
| «Filter failed» в статусе | Проблемы с фильтрами | Проверить `error_log`, переустановить `cups-filters` |
| Доступ запрещён | Права CUPS | Добавить пользователя в `lp`, проверить `cupsd.conf` |
| Сетевой принтер не найден | Firewall / сеть | Проверить `ping`, `nmap`, firewall |
| Медленная печать | Сложный PPD / сеть | Упростить PPD, проверить сеть |
| Двусторонняя печать не работает | PPD не поддерживает | Обновить PPD, использовать `everywhere` |

### Решение «Filter failed»

```bash
# 1. Включить подробное логирование
sudo cupsctl --debug-logging

# 2. Отправить тестовую страницу
lp -d printer_name /etc/hostname

# 3. Проверить лог
tail -100 /var/log/cups/error_log

# 4. Типичные решения:
# - Переустановить cups-filters
sudo dnf reinstall -y cups-filters

# - Проверить права PPD
sudo chmod 644 /etc/cups/ppd/*.ppd

# - Проверить зависимости фильтра
ldd /usr/lib/cups/filter/*

# 5. Отключить подробное логирование
sudo cupsctl --no-debug-logging
```

### Решение проблем с USB-подключением

```bash
# 1. Проверить обнаружение принтера
lsusb | grep -iE 'printer|hp|canon|epson|brother|xerox|samsung|pantum'

# 2. Проверить права устройства
ls -l /dev/usb/lp*

# 3. Добавить пользователя в группу lp
sudo usermod -aG lp username

# 4. Проверить udev-правила
ls -l /etc/udev/rules.d/*usb*

# 5. Перезапустить udev
sudo udevadm control --reload-rules
sudo udevadm trigger

# 6. Проверить dmesg
dmesg | tail -20 | grep -i usb
```

### Решение проблем с сетевым принтером

```bash
# 1. Проверить доступность принтера
ping 192.168.1.100

# 2. Проверить открытые порты
nmap -p 631,9100,515 192.168.1.100

# 3. Проверить IPP-сервис
curl -I http://192.168.1.100:631/

# 4. Проверить Socket-подключение
echo -e "\000\000\000\x04" | nc -w 2 192.168.1.100 9100

# 5. Проверить mDNS
avahi-browse -rt _ipp._tcp

# 6. Проверить SMB (для Windows-принтеров)
smbclient -L //server -U username
```

---

## Автоматический скрипт установки

### printer-setup.sh

```bash
#!/bin/bash
# printer-setup.sh — Автоматическая установка и настройка принтера
# Использование: sudo bash printer-setup.sh [имя_принтера] [IP_или_USB_URI]

set -euo pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PRINTER_NAME="${1:-auto}"
PRINTER_URI="${2:-auto}"

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
    log_error "Скрипт требует прав root. Запустите с sudo."
    exit 1
fi

# Проверка и установка CUPS
check_cups() {
    if ! systemctl is-active --quiet cups; then
        log_info "Установка CUPS..."
        dnf install -y cups cups-client cups-filters
        systemctl enable --now cups
    fi
    log_info "CUPS работает (версия: $(cupsd --version 2>&1 | head -1))"
}

# Определение типа принтера
detect_printer() {
    log_info "Поиск принтеров..."

    # USB-принтеры
    local usb_printers=$(lpinfo -v 2>/dev/null | grep '^direct usb://' || true)
    if [[ -n "$usb_printers" ]]; then
        log_info "Найдены USB-принтеры:"
        echo "$usb_printers"
    fi

    # Сетевые принтеры (mDNS)
    local network_printers=$(lpinfo -v 2>/dev/null | grep '^direct network://' || true)
    if [[ -n "$network_printers" ]]; then
        log_info "Найдены сетевые принтеры:"
        echo "$network_printers"
    fi

    # Driverless
    local driverless_printers=$(driverless 2>/dev/null || true)
    if [[ -n "$driverless_printers" ]]; then
        log_info "Найдены driverless-принтеры:"
        echo "$driverless_printers"
    fi
}

# Установка принтера HP
setup_hp() {
    log_info "Настройка принтера HP..."

    if ! command -v hp-setup &>/dev/null; then
        log_info "Установка HPLIP..."
        dnf install -y hplip hplip-gui
    fi

    if [[ "$PRINTER_URI" == "auto" ]]; then
        log_info "Запуск hp-setup в интерактивном режиме..."
        hp-setup -i
    else
        hp-setup -i "$PRINTER_URI"
    fi
}

# Установка универсального принтера
setup_generic() {
    local name="$1"
    local uri="$2"

    log_info "Добавление принтера '$name'..."

    # Пробуем IPP Everywhere / driverless
    if lpinfo -m | grep -q "everywhere"; then
        sudo lpadmin -p "$name" -E -v "$uri" -m everywhere
        log_info "Принтер добавлен через IPP Everywhere"
    else
        # Пробуем generic PPD
        local ppd=$(lpinfo -m 2>/dev/null | grep -i generic | head -1 | awk '{print $1}')
        if [[ -n "$ppd" ]]; then
            sudo lpadmin -p "$name" -E -v "$uri" -m "$ppd"
            log_info "Принтер добавлен с generic PPD"
        else
            log_error "Не удалось найти подходящий драйвер"
            return 1
        fi
    fi

    # Тестовая страница
    log_info "Печать тестовой страницы..."
    lp -d "$name" /etc/hostname
    log_info "Проверьте принтер"
}

# Основная функция
main() {
    log_info "=== Настройка принтера в РЕД ОС ==="

    check_cups

    if [[ "$PRINTER_NAME" == "auto" ]]; then
        detect_printer
        echo ""
        read -p "Введите имя для нового принтера: " PRINTER_NAME
        read -p "Введите URI принтера (или оставьте пустым для auto): " PRINTER_URI
    fi

    # Определение производителя по URI
    if [[ "$PRINTER_URI" == "auto" ]]; then
        detect_printer
        read -p "Введите URI принтера: " PRINTER_URI
    fi

    if echo "$PRINTER_URI" | grep -qi 'hp\|hewlett'; then
        setup_hp
    else
        setup_generic "$PRINTER_NAME" "$PRINTER_URI"
    fi

    log_info "=== Настройка завершена ==="
    lpstat -t
}

main "$@"
```

### Установка и использование

```bash
# Сделать скрипт исполняемым
chmod +x printer-setup.sh

# Интерактивный режим
sudo bash printer-setup.sh

# С указанием имени и URI
sudo bash printer-setup.sh office-laserjet socket://192.168.1.100:9100

# Для HP-принтера
sudo bash printer-setup.sh hp-office hp:/net/HP_OfficeJet_Pro_9010
```

---

## Справочник команд

| Команда | Описание | Пример |
|---------|----------|--------|
| `lpstat -t` | Полная информация о CUPS | `lpstat -t` |
| `lpstat -p -d` | Список принтеров и принтер по умолчанию | `lpstat -p -d` |
| `lpq` | Просмотр очереди | `lpq -P printer_name` |
| `lprm` | Удалить задание из очереди | `lprm 42` |
| `lp` | Печать файла | `lp -d printer file.pdf` |
| `lpr` | Печать (альтернатива lp) | `lpr -P printer file.pdf` |
| `lpadmin` | Администрирование принтеров | `lpadmin -p name -E -v uri -m ppd` |
| `lpinfo -v` | Список доступных устройств | `lpinfo -v` |
| `lpinfo -m` | Список доступных драйверов | `lpinfo -m \| grep hp` |
| `cancel` | Отменить задание | `cancel printer_name` |
| `lpoptions` | Настройки принтера | `lpoptions -d printer_name` |
| `cupsctl` | Настройка CUPS | `cupsctl --debug-logging` |
| `hp-setup` | Мастер настройки HP | `hp-setup -i` |
| `hp-check` | Диагностика HP | `hp-check -t` |
| `driverless` | Driverless-принтеры | `driverless` |
| `system-config-printer` | Графический интерфейс | `system-config-printer` |

### Параметры печати

| Параметр | Флаг | Описание | Пример |
|----------|------|----------|--------|
| Принтер | `-d printer` | Выбор принтера | `lp -d office-laser file.pdf` |
| Копии | `-n N` | Количество копий | `lp -n 3 file.pdf` |
| Двусторонняя | `-o sides=two-sided-long-edge` | Двусторонняя печать | `lp -o sides=two-sided-long-edge file.pdf` |
| Ориентация | `-o landscape` | Альбомная ориентация | `lp -o landscape file.pdf` |
| Качество | `-o print-quality=N` | 3=черновик, 4=обычное, 5=высокое | `lp -o print-quality=3 file.pdf` |
| Размер бумаги | `-o media=A4` | Формат бумаги | `lp -o media=A4 file.pdf` |
| Цвет/ЧБ | `-o color-mode=monochrome` | Чёрно-белая печать | `lp -o color-mode=monochrome file.pdf` |
| Масштаб | `-o fit-to-page` | Вписать в страницу | `lp -o fit-to-page file.pdf` |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **CUPS** | 2.4.x |
| **HPLIP** | 3.23.x+ |
| **Права** | root (для установки), пользователь (для печати) |
| **Сеть** | Требуется для сетевых принтеров и загрузки драйверов |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> CUPS и большинство драйверов работают одинаково. В РЕД ОС 8.x улучшена поддержка IPP Everywhere.

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
