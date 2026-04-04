# 📠 Настройка сканеров и МФУ в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

Полное руководство по подключению и настройке сканеров и МФУ в РЕД ОС. Архитектура SANE, USB и сетевое сканирование, OCR, пакетная обработка, автоматизация scan-to-PDF.

---

## 📋 Оглавление

1. [Архитектура сканирования SANE](#архитектура-сканирования-sane)
2. [Установка и базовая настройка](#установка-и-базовая-настройка)
3. [Приложения для сканирования](#приложения-для-сканирования)
4. [Сканеры HP](#сканеры-hp)
5. [Сканеры Canon](#сканеры-canon)
6. [Сканеры Epson](#сканеры-epson)
7. [Сканеры Brother](#сканеры-brother)
8. [Сканеры Fujitsu](#сканеры-fujitsu)
9. [Сетевое сканирование](#сетевое-сканирование)
10. [Пакетное сканирование](#пакетное-сканирование)
11. [OCR — распознавание текста](#ocr--распознавание-текста)
12. [Автоматизация scan-to-PDF](#автоматизация-scan-to-pdf)
13. [Диагностика и устранение проблем](#диагностика-и-устранение-проблем)
14. [Справочник команд](#справочник-команд)
15. [Требования и совместимость](#требования-и-совместимость)

---

## Архитектура сканирования SANE

**SANE** (Scanner Access Now Easy) — стандартный интерфейс для сканеров в Linux.

### Компоненты SANE

```
┌──────────────────────────────────────────────────┐
│           Приложение (Simple Scan, XSane)         │
└──────────────────┬───────────────────────────────┘
                   │ SANE API
                   ▼
┌──────────────────────────────────────────────────┐
│          SANE Frontend (libsane)                 │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│         SANE Backend (бэкенд устройства)          │
│  hpaio │ epson2 │ brother │ genesys │ ...       │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│         Интерфейс (USB / сеть / SCSI)            │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│              Сканер / МФУ                        │
└──────────────────────────────────────────────────┘
```

### Основные бэкенды SANE

| Бэкенд | Производитель | Тип | Документация |
|--------|--------------|-----|-------------|
| `hpaio` | HP | Универсальный | sane-hpaio |
| `epson2` | Epson | Универсальный | sane-epson2 |
| `brother4` | Brother | Фирменный | Brother Linux |
| `canon` | Canon | Универсальный | sane-canon |
| `canon_dr` | Canon DR | Серия DR | sane-canon_dr |
| `pixma` | Canon | Серия PIXMA | sane-pixma |
| `genesys` | Genesys Logic | USB-сканеры | sane-genesys |
| `plustek` | Plustek | USB-сканеры | sane-plustek |
| `fujitsu` | Fujitsu | Серия fi/ScanSnap | sane-fujitsu |
| `xerox_mfp` | Xerox | МФУ | sane-xerox_mfp |
| `net` | Все | Сетевые сканеры | sane-net |
| `snapscan` | AGFA | SnapScan | sane-snapscan |

### Режимы работы SANE

| Режим | Описание | Конфигурация |
|-------|----------|-------------|
| **Локальный** | Сканер подключён напрямую | `/etc/sane.d/dll.conf` |
| **Серверный** | Сканер расшарен по сети | `saned` демон |
| **Клиентский** | Подключение к удалённому сканеру | `net` бэкенд |

---

## Установка и базовая настройка

### Установка пакетов SANE

```bash
# Основные пакеты
sudo dnf install -y sane-backends sane-frontends

# Дополнительные бэкенды
sudo dnf install -y sane-backends-drivers-scanners

# Графические приложения
sudo dnf install -y simple-scan xsane

# Для сетевого сканирования
sudo dnf install -y sane-backends-daemon
```

### Проверка обнаружения сканера

```bash
# 1. Проверить USB-подключение
lsusb | grep -iE 'scan|hp|epson|canon|brother|fujitsu'

# 2. Проверить обнаружение SANE
scanimage -L

# 3. Проверить доступные бэкенды
scanimage -L -v

# 4. Тестовое сканирование
scanimage --test

# 5. Подробная информация
scanimage -A
```

### Настройка прав доступа

```bash
# Добавить пользователя в группу scanner
sudo usermod -aG scanner username

# Проверить udev-правила
ls -l /etc/udev/rules.d/*sane*

# Если правил нет — создать
sudo nano /etc/udev/rules.d/55-sane.rules
```

Содержимое `55-sane.rules` для типичных сканеров:

```udev
# HP
ATTRS{idVendor}=="03f0", MODE="0666", GROUP="scanner"

# Epson
ATTRS{idVendor}=="04b8", MODE="0666", GROUP="scanner"

# Canon
ATTRS{idVendor}=="04a9", MODE="0666", GROUP="scanner"

# Brother
ATTRS{idVendor}=="04f9", MODE="0666", GROUP="scanner"

# Fujitsu
ATTRS{idVendor}=="04c5", MODE="0666", GROUP="scanner"
```

Применить правила:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Конфигурация бэкендов

```bash
# Основной файл — список активных бэкендов
cat /etc/sane.d/dll.conf

# Активировать нужный бэкенд (раскомментировать строку)
sudo sed -i 's/^#hpaio/hpaio/' /etc/sane.d/dll.conf
sudo sed -i 's/^#epson2/epson2/' /etc/sane.d/dll.conf
sudo sed -i 's/^#brother4/brother4/' /etc/sane.d/dll.conf

# Настройка конкретного бэкенда
ls /etc/sane.d/*.conf
```

---

## Приложения для сканирования

### Simple Scan (Document Scanner)

Простое приложение для быстрого сканирования документов.

```bash
# Установка
sudo dnf install -y simple-scan

# Запуск
simple-scan

# Запуск в режиме отладки
simple-scan --debug
```

**Возможности:**
- Простое сканирование одной кнопкой
- Многостраничные документы
- Экспорт в PDF, PNG, JPEG
- Настройка разрешения (75–600 dpi)
- Цветной / градации серого / чёрно-белый режим
- Обрезка и поворот страниц

### XSane

Профессиональное приложение с расширенными настройками.

```bash
# Установка
sudo dnf install -y xsane

# Запуск
xsane

# Запуск для конкретного устройства
xsane hpaio:/net/HP_LaserJet_MFP
```

**Возможности:**
- Полный контроль параметров сканера
- Пакетное сканирование (ADF)
- Предпросмотр
- Коррекция яркости, контраста, гаммы
- Удаление фона, дескрининг
- Экспорт в множество форматов
- OCR через gOCR
- Сохранение настроек как пресетов

### NAPS2 (Not Another PDF Scanner 2)

Кроссплатформенное приложение с поддержкой SANE через TWAIN.

```bash
# Установка через Flatpak (если доступен)
flatpak install flathub com.naps2.NAPS2

# Или скачать AppImage с https://www.naps2.com/
chmod +x NAPS2-*.AppImage
./NAPS2-*.AppImage
```

**Возможности:**
- Интуитивный интерфейс
- Многостраничное сканирование
- OCR (Tesseract встроен)
- Профили сканирования
- Пакетная обработка
- Экспорт в PDF, PDF/A, TIFF, PNG

### Сравнение приложений

| Приложение | Простота | Функции | OCR | Пакетное | ADF | CLI |
|-----------|----------|---------|-----|----------|-----|-----|
| **Simple Scan** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ❌ | ✅ | ✅ | ❌ |
| **XSane** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⚠️ gOCR | ✅ | ✅ | ✅ |
| **NAPS2** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | ✅ | ✅ | ⚠️ |
| **scanimage** | ⭐ | ⭐⭐⭐ | ❌ | ✅ | ✅ | ✅ |
| **scanbd** | ⭐ | ⭐⭐⭐ | ❌ | ✅ | ✅ | ✅ |

---

## Сканеры HP

### Бэкенд hpaio

Сканеры HP поддерживаются через HPLIP и бэкенд `hpaio`.

```bash
# Установка
sudo dnf install -y hplip hplip-gui sane-backends

# Проверка
scanimage -L
# Пример вывода:
# device `hpaio:/net/HP_LaserJet_MFP_M428fdw?ip=192.168.1.100'
# is a Hewlett-Packard HP_LaserJet_MFP_M428fdw all-in-one
```

### Настройка сканера HP

```bash
# Проверка через hp-check
hp-check -t

# Настройка сканирования
hp-scan

# Тестовое сканирование
hp-scan -p  # сохранить в файл
```

### Таблица совместимости сканеров HP

| Модель | Тип | Бэкенд | USB | Сеть | ADF |
|--------|-----|--------|-----|------|-----|
| LaserJet Pro MFP M428fdw | МФУ | hpaio | ✅ | ✅ | ✅ |
| LaserJet Pro MFP M130fw | МФУ | hpaio | ✅ | ✅ | ✅ |
| LaserJet Pro MFP M479fdw | МФУ | hpaio | ✅ | ✅ | ✅ |
| OfficeJet Pro 9010 | МФУ | hpaio | ✅ | ✅ | ✅ |
| OfficeJet Pro 8020 | МФУ | hpaio | ✅ | ✅ | ✅ |
| DeskJet Plus 4100 | МФУ | hpaio | ✅ | ✅ | ✅ |
| Smart Tank Plus 580 | МФУ | hpaio | ✅ | ✅ | ✅ |
| ScanJet Pro 3000 | Сканер | hpaio | ✅ | ❌ | ✅ |
| ScanJet Pro 4500 | Сканер | hpaio | ✅ | ✅ | ✅ |
| Neverstop MFP 1202w | МФУ | hpaio | ✅ | ✅ | ❌ |

---

## Сканеры Canon

### Бэкенды SANE для Canon

| Бэкенд | Серия | Модели |
|--------|-------|--------|
| `pixma` | PIXMA | G-серия, TS-серия, MG-серия |
| `canon` | CanoScan | LiDE, 9000F |
| `canon_dr` | imageFORMULA | DR, DR-C, DR-M серии |
| `canon630u` | Старые USB | |

### Установка Canon ScanGear

Для сканеров, не поддерживаемых SANE, Canon предоставляет ScanGear:

```bash
# Скачивание ScanGear
# https://www.canon.ru/support/

# Распаковка
tar -xzf scangearmp2-*.tar.gz
cd scangearmp2-*/

# Установка
sudo ./install.sh

# Запуск
scangearmp2
```

### Таблица совместимости сканеров Canon

| Модель | Тип | Бэкенд | USB | Сеть | ADF |
|--------|-----|--------|-----|------|-----|
| imageFORMULA DR-C225 | Сканер | canon_dr | ✅ | ❌ | ✅ |
| imageFORMULA DR-M260 | Сканер | canon_dr | ✅ | ❌ | ✅ |
| imageFORMULA DR-S150 | Сканер | canon_dr | ✅ | ❌ | ✅ |
| CanoScan LiDE 300 | Сканер | pixma | ✅ | ❌ | ❌ |
| CanoScan LiDE 400 | Сканер | pixma | ✅ | ❌ | ❌ |
| CanoScan 9000F MkII | Сканер | pixma | ✅ | ❌ | ❌ |
| PIXMA G3420 | МФУ | pixma | ✅ | ✅ | ❌ |
| PIXMA TS3340 | МФУ | pixma | ✅ | ✅ | ❌ |
| MAXIFY GX4040 | МФУ | pixma | ✅ | ✅ | ✅ |
| imageFORMULA R40 | Сканер | canon_dr | ✅ | ❌ | ✅ |

---

## Сканеры Epson

### Бэкенд epson2

```bash
# Установка
sudo dnf install -y sane-backends sane-backends-drivers-scanners

# Проверка
scanimage -L
# Пример вывода:
# device `epson2:net:192.168.1.75'
# is a Epson PID onepc flatbed scanner
```

### Фирменный драйвер Epson

Для сканеров, не поддерживаемых стандартным бэкендом:

```bash
# Скачивание драйвера
# https://download.ebz.epson.net/dsc/search/01/search/

# Установка RPM
sudo dnf install -y iscan-*.rpm
sudo dnf install -y iscan-network-nt-*.rpm  # для сетевого

# Запуск
iscan
```

### Таблица совместимости сканеров Epson

| Модель | Тип | Бэкенд | USB | Сеть | ADF |
|--------|-----|--------|-----|------|-----|
| WorkForce DS-1660W | Сканер | epson2 / iscan | ✅ | ✅ | ✅ |
| WorkForce DS-310 | Сканер | epson2 | ✅ | ❌ | ✅ |
| WorkForce DS-530 | Сканер | epson2 | ✅ | ✅ | ✅ |
| WorkForce DS-780N | Сканер | epson2 | ✅ | ✅ | ✅ |
| Perfection V39 | Сканер | epson2 | ✅ | ❌ | ❌ |
| Perfection V600 | Сканер | epson2 | ✅ | ❌ | ❌ |
| EcoTank L3250 | МФУ | epson2 | ✅ | ✅ | ❌ |
| EcoTank L3150 | МФУ | epson2 | ✅ | ✅ | ❌ |
| WorkForce WF-2860 | МФУ | epson2 | ✅ | ✅ | ✅ |
| FastFoto FF-680W | Сканер | iscan | ✅ | ✅ | ✅ |

---

## Сканеры Brother

### Установка драйверов Brother

Brother предоставляет отдельные бинарные драйверы для сканеров.

```bash
# Скачивание драйвера сканера
# https://support.brother.com/g/b/downloadlist.aspx
# → Выберите модель → Linux (rpm) → Scanner driver

# Установка
sudo dnf install -y brscan5-*.rpm       # для новых моделей
# или
sudo dnf install -y brscan4-*.rpm       # для старых моделей
# или
sudo dnf install -y brscan3-*.rpm       # для старых моделей

# Для сетевого сканера
sudo dnf install -y brscan5-network-*.rpm

# Проверка
scanimage -L
# device `brother5:bus3;dev1' is a Brother DCP-L2550DW scanner

# Настройка сетевого сканера
brsaneconfig5 -a name=Brother-Scanner model=DCP-L2550DW ip=192.168.1.120

# Проверка подключения
brsaneconfig5 -q | grep Brother
```

### Таблица совместимости сканеров Brother

| Модель | Тип | Бэкенд | USB | Сеть | ADF |
|--------|-----|--------|-----|------|-----|
| DCP-L2500DWR | МФУ | brother4/5 | ✅ | ❌ | ❌ |
| DCP-L2520DWR | МФУ | brother4/5 | ✅ | ❌ | ❌ |
| DCP-T420W | МФУ | brother5 | ✅ | ✅ | ❌ |
| DCP-T520W | МФУ | brother5 | ✅ | ✅ | ❌ |
| MFC-L2700DWR | МФУ | brother4/5 | ✅ | ✅ | ✅ |
| MFC-L2750DW | МФУ | brother4/5 | ✅ | ✅ | ✅ |
| ADS-1700W | Сканер | brother5 | ✅ | ✅ | ✅ |
| ADS-2700W | Сканер | brother5 | ✅ | ✅ | ✅ |
| ADS-4700W | Сканер | brother5 | ✅ | ✅ | ✅ |
| MFC-T4500DW | МФУ | brother5 | ✅ | ✅ | ✅ |

---

## Сканеры Fujitsu

### Серия fi / ScanSnap

Сканеры Fujitsu поддерживаются бэкендом `fujitsu` в SANE.

```bash
# Проверка поддержки
scanimage -L
# device `fujitsu:fi-7160:usb1:002:004'
# is a FUJITSU fi-7160 scanner

# Для ScanSnap может потребоваться дополнительный драйвер
# Скачивание с https://www.fujitsu.com/global/support/products/computing/peripheral/scanners/drivers/
```

### ScanSnap в Linux

ScanSnap — проприетарное ПО, но сканеры работают через SANE:

| Модель | SANE | ScanSnap Home | Примечание |
|--------|------|---------------|------------|
| fi-7160 | ✅ | ❌ | Через SANE |
| fi-8170 | ✅ | ❌ | Через SANE |
| fi-8270 | ✅ | ❌ | Через SANE |
| ScanSnap iX1600 | ⚠️ | ❌ | Ограниченная поддержка |
| ScanSnap iX1500 | ⚠️ | ❌ | Ограниченная поддержка |
| ScanSnap S1300i | ✅ | ❌ | Через SANE |
| ScanSnap SV600 | ⚠️ | ❌ | Частичная поддержка |

---

## Сетевое сканирование

### Настройка сервера сканирования (saned)

На компьютере, к которому подключён сканер:

```bash
# Установка серверной части
sudo dnf install -y sane-backends-daemon

# Настройка доступа
sudo nano /etc/sane.d/saned.conf
```

Добавить подсети, которым разрешён доступ:

```
# /etc/sane.d/saned.conf
192.168.1.0/24
10.0.0.0/8
```

Настроить `saned` через systemd:

```bash
# Редактирование сокета
sudo nano /etc/systemd/system/saned.socket

# Запуск
sudo systemctl enable --now saned.socket
sudo systemctl enable --now saned@scanner.service

# Проверка
sudo systemctl status saned.socket
```

### Настройка клиента

На компьютере-клиенте:

```bash
# Активировать net-бэкенд
echo "net" | sudo tee -a /etc/sane.d/dll.conf

# Указать адрес сервера
echo "192.168.1.10" | sudo tee /etc/sane.d/net.conf

# Проверить обнаружение
scanimage -L
# device `net:192.168.1.10:brother5:bus3;dev1'
# is a Brother scanner over network

# Сканирование
scanimage --format=tiff > scan.tiff
```

### Сканирование через NIS/Avahi

```bash
# Установка Avahi для автоматического обнаружения
sudo dnf install -y avahi avahi-tools

# Обнаружение сканеров
avahi-browse -rt _uscan._tcp
avahi-browse -rt _scan._tcp
```

---

## Пакетное сканирование

### scanimage — командная строка

```bash
# Базовое сканирование
scanimage --format=png > scan.png

# Сканирование с параметрами
scanimage \
    --resolution 300 \
    --mode Color \
    --format=tiff \
    --page-width 210 \
    --page-height 297 \
    > scan.tiff

# Пакетное сканирование (ADF)
for i in $(seq 1 10); do
    scanimage --format=png --source "ADF" > page_$(printf "%02d" $i).png
    echo "Отсканирована страница $i"
done

# Сканирование в PDF (через ImageMagick)
scanimage --format=tiff --resolution 300 --source ADF > /tmp/scan.tiff
convert /tmp/scan.tiff output.pdf

# Сканирование с прогрессией в JPEG
scanimage \
    --resolution 300 \
    --mode Color \
    --format=jpeg \
    --jpeg-quality 90 \
    > document.jpg
```

### Доступные параметры сканера

```bash
# Показать все доступные параметры
scanimage -A

# Показать все опции
scanimage --help

# Пример вывода:
# All options specific to device `hpaio:/usb/...':
#   Scan mode:
#     --mode Color|Gray|Lineart [Color]
#       Select the scan mode
#     --resolution 75..600 (in steps of 1) [300]
#       Sets the resolution of the scanned image
#   Geometry:
#     -l 0..215.9mm [0]
#       Top-left x position of scan area
#     -t 0..297.18mm [0]
#       Top-left y position of scan area
#     -x 0..215.9mm [215.9]
#       Width of scan area
#     -y 0..297.18mm [297.18]
#       Height of scan area
```

### Пакетный скрипт scan-to-dir

```bash
#!/bin/bash
# scan-to-dir.sh — Пакетное сканирование в указанную директорию

OUTPUT_DIR="${1:-./scans}"
RESOLUTION="${2:-300}"
FORMAT="${3:-pdf}"
MODE="${4:-Color}"
SOURCE="${5:-Auto}"
PREFIX="${6:-scan}"

mkdir -p "$OUTPUT_DIR"

counter=1
while true; do
    filename=$(printf "%s_%03d.%s" "$PREFIX" "$counter" "$FORMAT")
    filepath="$OUTPUT_DIR/$filename"

    echo "[$counter] Сканирование в $filepath..."
    echo "    Разрешение: $RESOLUTION dpi, Режим: $MODE, Источник: $SOURCE"

    if [ "$FORMAT" = "pdf" ]; then
        scanimage \
            --resolution "$RESOLUTION" \
            --mode "$MODE" \
            --source "$SOURCE" \
            --format=tiff \
            > "${filepath}.tiff"

        # Конвертация TIFF в PDF
        if command -v img2pdf &>/dev/null; then
            img2pdf "${filepath}.tiff" -o "$filepath"
        elif command -v convert &>/dev/null; then
            convert "${filepath}.tiff" "$filepath"
        else
            echo "Установите img2pdf или ImageMagick для PDF-конвертации"
            mv "${filepath}.tiff" "$filepath"
        fi
        rm -f "${filepath}.tiff"
    else
        scanimage \
            --resolution "$RESOLUTION" \
            --mode "$MODE" \
            --source "$SOURCE" \
            --format="$FORMAT" \
            > "$filepath"
    fi

    echo "[$counter] Сохранено: $filepath"
    counter=$((counter + 1))

    read -p "Продолжить сканирование? (Y/n): " answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        break
    fi
done

echo "Отсканировано $((counter - 1)) страниц(ы) в $OUTPUT_DIR"
```

Использование:

```bash
# По умолчанию
./scan-to-dir.sh

# С параметрами
./scan-to-dir.sh /home/user/documents 300 pdf Color ADF document
```

---

## OCR — распознавание текста

### Tesseract OCR

```bash
# Установка
sudo dnf install -y tesseract tesseract-langpack-rus

# Доступные языки
tesseract --list-langs
# eng
# rus

# Распознавание изображения
tesseract scan.png output -l rus+eng

# Результат в output.txt
cat output.txt

# С указанием конфигурации
tesseract scan.png output \
    -l rus+eng \
    --psm 1 \
    -c preserve_interword_spaces=1
```

### Режимы сегментации (--psm)

| PSM | Режим | Описание |
|-----|-------|----------|
| 0 | OSD only | Только ориентация и обнаружение скрипта |
| 1 | Auto + OSD | Автоматическая с OSD |
| 3 | Fully auto | Полностью автоматический (по умолчанию) |
| 4 | Single column | Одна колонка текста |
| 5 | Single block | Один блок текста |
| 6 | Single line | Одна строка текста |
| 7 | Single word | Одно слово |
| 8 | Single word (circle) | Одно слово в круге |
| 9 | Single word (dot) | Одно слово в точке |
| 10 | Single character | Один символ |
| 11 | Sparse text | Редкий текст |
| 12 | Sparse text + OSD | Редкий текст с OSD |
| 13 | Raw line | Сырая строка |

### OCRmyPDF

OCRmyPDF добавляет текстовый слой к PDF-файлам со сканами:

```bash
# Установка
sudo dnf install -y ocrmypdf

# Базовое OCR
ocrmypdf input.pdf output.pdf

# OCR с русским языком
ocrmypdf -l rus+eng input.pdf output.pdf

# Оптимизация + OCR
ocrmypdf \
    -l rus+eng \
    --optimize 3 \
    --deskew \
    --clean \
    --output-type pdfa \
    input.pdf output.pdf

# Пакетная обработка
for f in *.pdf; do
    echo "Обработка: $f"
    ocrmypdf -l rus+eng --deskew "$f" "ocr_$f"
done
```

### Опции OCRmyPDF

| Опция | Описание |
|-------|----------|
| `-l LANG` | Язык распознавания (rus, eng, rus+eng) |
| `--deskew` | Исправление перекоса |
| `--clean` | Очистка изображения |
| `--optimize N` | Оптимизация PDF (0–3) |
| `--output-type pdfa` | Создание PDF/A |
| `--rotate-pages` | Автоповорот страниц |
| `--pages N-M` | Диапазон страниц |
| `--force-ocr` | Принудительный OCR |
| `--skip-text` | Пропустить страницы с текстом |
| `--redo-ocr` | Повторный OCR |

### Полный пайплайн: сканирование → OCR

```bash
#!/bin/bash
# scan-ocr.sh — Сканирование с автоматическим OCR

OUTPUT_DIR="${1:-./scans_ocr}"
mkdir -p "$OUTPUT_DIR"

echo "=== Сканирование с OCR ==="

# Шаг 1: Сканирование
echo "[1/3] Сканирование..."
scanimage \
    --resolution 300 \
    --mode Gray \
    --source ADF \
    --format=tiff \
    > "$OUTPUT_DIR/raw_scan.tiff"

# Шаг 2: Конвертация в PDF
echo "[2/3] Конвертация в PDF..."
img2pdf "$OUTPUT_DIR/raw_scan.tiff" \
    -o "$OUTPUT_DIR/scan.pdf" \
    --pagesize A4

# Шаг 3: OCR
echo "[3/3] Распознавание текста..."
ocrmypdf \
    -l rus+eng \
    --deskew \
    --optimize 2 \
    "$OUTPUT_DIR/scan.pdf" \
    "$OUTPUT_DIR/scan_ocr.pdf"

# Очистка
rm -f "$OUTPUT_DIR/raw_scan.tiff"

echo "Готово: $OUTPUT_DIR/scan_ocr.pdf"
```

---

## Автоматизация scan-to-PDF

### Полный скрипт автоматизации

```bash
#!/bin/bash
# scan-to-pdf.sh — Полный скрипт сканирования в PDF с OCR
# Использование: ./scan-to-pdf.sh [resolution] [mode] [source]

set -euo pipefail

RESOLUTION="${1:-300}"
MODE="${2:-Gray}"
SOURCE="${3:-Auto}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="$HOME/Документы/Сканы"
TEMP_DIR=$(mktemp -d)

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "${YELLOW}[STEP]${NC} $1"; }

# Проверка зависимостей
check_deps() {
    local deps=("scanimage" "img2pdf" "ocrmypdf")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Установите: $dep"
            exit 1
        fi
    done
}

# Сканирование одной страницы
scan_page() {
    local page_num=$1
    local tiff_file="$TEMP_DIR/page_$(printf '%03d' $page_num).tiff"

    log_info "Сканирование страницы $page_num..."

    scanimage \
        --resolution "$RESOLUTION" \
        --mode "$MODE" \
        --source "$SOURCE" \
        --format=tiff \
        > "$tiff_file"

    if [[ -s "$tiff_file" ]]; then
        log_info "Страница $page_num сохранена ($(du -h "$tiff_file" | cut -f1))"
        return 0
    else
        log_info "Страница $page_num пуста, пропуск"
        rm -f "$tiff_file"
        return 1
    fi
}

# Основная функция
main() {
    mkdir -p "$OUTPUT_DIR"
    check_deps

    log_info "=== Сканер → PDF с OCR ==="
    log_info "Разрешение: $RESOLUTION dpi"
    log_info "Режим: $MODE"
    log_info "Источник: $SOURCE"
    echo ""

    # Сканирование страниц
    page=0
    while true; do
        page=$((page + 1))
        if ! scan_page $page; then
            if [[ $page -gt 1 ]]; then
                page=$((page - 1))
            fi
            break
        fi

        read -p "Продолжить сканирование? (Enter=да, n=нет): " answer
        if [[ "$answer" == "n" ]]; then
            break
        fi
    done

    if [[ $page -eq 0 ]]; then
        log_info "Ни одна страница не отсканирована"
        exit 0
    fi

    # Конвертация в PDF
    log_step "Конвертация в PDF..."
    output_file="$OUTPUT_DIR/scan_${TIMESTAMP}.pdf"

    img2pdf \
        "$TEMP_DIR"/page_*.tiff \
        -o "$output_file" \
        --pagesize A4

    # OCR
    log_step "Распознавание текста..."
    ocrmypdf \
        -l rus+eng \
        --deskew \
        --optimize 2 \
        "$output_file" \
        "${output_file%.pdf}_ocr.pdf"

    # Очистка
    rm -rf "$TEMP_DIR"

    log_info "Готово: ${output_file%.pdf}_ocr.pdf"
    log_info "Всего страниц: $page"
    ls -lh "${output_file%.pdf}_ocr.pdf"
}

main
```

---

## Диагностика и устранение проблем

### Основные команды диагностики

```bash
# Проверить обнаружение сканера
scanimage -L

# Проверить доступные устройства
scanimage -L -v

# Проверить бэкенды
scanimage -L -d

# Тестовое сканирование
scanimage --test

# Проверить доступные опции
scanimage -A

# Проверить права устройства
ls -l /dev/bus/usb/*/*

# Проверить udev
udevadm info -a -n /dev/bus/usb/001/002

# Проверить журналы
journalctl -u saned
dmesg | grep -i usb
```

### Типичные проблемы и решения

| Проблема | Причина | Решение |
|----------|---------|---------|
| `scanimage: no SANE devices` | Бэкенд не активирован | Раскомментировать в `dll.conf` |
| `Permission denied` | Нет прав | Добавить в группу `scanner`, udev-правила |
| Сканер не определяется | USB-проблема | Проверить `lsusb`, кабель, питание |
| Сканирование зависает | Бэкенд/драйвер | Обновить SANE, проверить `scanimage -A` |
| Низкое качество | Разрешение | Увеличить `--resolution` |
| Сканер не в ADF | Источник | Указать `--source ADF` |
| Сетевой не найден | Firewall | Открыть порт 6566, проверить `saned.conf` |
| Цвета искажены | Калибровка | Запустить калибровку, проверить `--mode` |
| Дуплекс не работает | PPD/бэкенд | Обновить бэкенд, проверить `--source 'ADF Duplex'` |

### Решение «No SANE devices found»

```bash
# 1. Проверить подключение
lsusb | grep -iE 'scan|epson|hp|canon|brother'

# 2. Проверить активные бэкенды
cat /etc/sane.d/dll.conf | grep -v '^#' | grep -v '^$'

# 3. Проверить конкретный бэкенд
sudo SANE_DEBUG_HPAIO=255 scanimage -L 2>&1 | tail -20

# 4. Проверить права
sudo scanimage -L  # если работает — проблема в правах
sudo usermod -aG scanner $USER

# 5. Проверить udev-правила
ls -l /etc/udev/rules.d/*sane*
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Решение проблем с сетевым сканером

```bash
# 1. Проверить доступность сервера
ping saned-server

# 2. Проверить порт
nmap -p 6566 saned-server

# 3. Проверить saned.conf
cat /etc/sane.d/saned.conf

# 4. Проверить saned-демон
sudo systemctl status saned.socket
sudo systemctl status saned@scanner.service

# 5. Проверить клиента
cat /etc/sane.d/net.conf
# Должно содержать: saned-server

# 6. Тест клиента
SANE_DEBUG_NET=255 scanimage -L 2>&1 | tail -20
```

---

## Справочник команд

| Команда | Описание | Пример |
|---------|----------|--------|
| `scanimage -L` | Список сканеров | `scanimage -L` |
| `scanimage -A` | Доступные параметры | `scanimage -A` |
| `scanimage --test` | Тестовое сканирование | `scanimage --test` |
| `scanimage` | Сканирование | `scanimage --format=png > scan.png` |
| `simple-scan` | Простой интерфейс | `simple-scan` |
| `xsane` | Профессиональный интерфейс | `xsane` |
| `hp-scan` | Сканирование HP | `hp-scan -p` |
| `iscan` | Epson Image Scan | `iscan` |
| `scangearmp2` | Canon ScanGear | `scangearmp2` |
| `brsaneconfig5` | Настройка Brother | `brsaneconfig5 -a name=S model=M ip=X` |
| `ocrmypdf` | OCR для PDF | `ocrmypdf -l rus input.pdf out.pdf` |
| `tesseract` | OCR изображения | `tesseract img.png out -l rus` |
| `img2pdf` | Конвертация в PDF | `img2pdf img.tiff -o out.pdf` |
| `saned` | Сервер сканирования | `systemctl enable --now saned.socket` |
| `avahi-browse` | Обнаружение | `avahi-browse -rt _scan._tcp` |

### Параметры scanimage

| Параметр | Описание | Пример |
|----------|----------|--------|
| `--format=FORMAT` | Формат вывода | `--format=png` |
| `--resolution DPI` | Разрешение | `--resolution 300` |
| `--mode MODE` | Режим цвета | `--mode Color` |
| `--source SOURCE` | Источник | `--source ADF` |
| `-l/-t/-x/-y` | Область сканирования | `-x 210 -y 297` |
| `--brightness N` | Яркость | `--brightness 10` |
| `--contrast N` | Контраст | `--contrast 20` |
| `--page-width MM` | Ширина страницы | `--page-width 210` |
| `--page-height MM` | Высота страницы | `--page-height 297` |
| `--device DEVICE` | Устройство | `--device hpaio:/usb/...` |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **SANE** | 1.1.x+ |
| **Tesseract** | 5.x |
| **OCRmyPDF** | 14.x+ |
| **Права** | root (установка), scanner (сканирование) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> SANE работает одинаково в обеих версиях. В РЕД ОС 8.x могут быть обновлённые бэкенды.
> Для сетевого сканирования требуется открыть порт 6566.

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
