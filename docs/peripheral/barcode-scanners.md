# 📊 Сканеры штрих-кодов в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

Руководство по подключению и настройке сканеров штрих-кодов в РЕД ОС. Режимы HID/COM/OPOS, USB/Bluetooth, интеграция с 1С, генерация штрих-кодов, POS-интеграция.

---

## 📋 Оглавление

1. [Типы сканеров штрих-кодов](#типы-сканеров-штрих-кодов)
2. [Режимы работы](#режимы-работы)
3. [Подключение и настройка USB](#подключение-и-настройка-usb)
4. [Подключение и настройка Bluetooth](#подключение-и-настройка-bluetooth)
5. [Режим COM-порта](#режим-com-порта)
6. [Форматы штрих-кодов](#форматы-штрих-кодов)
7. [Производители и модели](#производители-и-модели)
8. [Интеграция с 1С](#интеграция-с-1с)
9. [Генерация штрих-кодов](#генерация-штрих-кодов)
10. [POS-интеграция](#pos-интеграция)
11. [Автоматический скрипт настройки](#автоматический-скрипт-настройки)
12. [Диагностика и устранение проблем](#диагностика-и-устранение-проблем)
13. [Справочник команд](#справочник-команд)
14. [Требования и совместимость](#требования-и-совместимость)

---

## Типы сканеров штрих-кодов

### По технологии сканирования

| Тип | Принцип | Преимущества | Недостатки |
|-----|---------|-------------|------------|
| **Лазерный** | Лазерный луч | Дальнобойный, надёжный | Только 1D, хрупкое зеркало |
| **LED (CCD)** | Светодиодная матрица | Дешёвый, прочный | Малая дальность |
| **2D (имиджер)** | Камера | 1D + 2D + QR | Дороже |
| **Omnidirectional** | Множество линий | Быстрое сканирование | Дорогой |

### По типу подключения

| Тип | Интерфейс | Преимущества | Недостатки |
|-----|-----------|-------------|------------|
| **USB** | HID / COM | Plug-and-Play | Ограничение по кабелю |
| **Bluetooth** | BT HID / SPP | Мобильность | Нужна зарядка |
| **RS-232** | COM-порт | Совместимость | Нужен переходник USB-RS232 |
| **Wi-Fi** | Сетевой | Дальность | Инфраструктура |

### По форм-фактору

| Тип | Описание | Применение |
|-----|----------|------------|
| **Ручной** | Держат в руке | Магазины, склады |
| **Настольный** | Стационарный | Кассы, конвейеры |
| **Беспроводной** | С базой/Bluetooth | Склад, логистика |
| **Терминал сбора данных (TSD)** | Компьютер + сканер | Складская инвентаризация |
| **Модуль** | Встраиваемый | Киоски, автоматы |

---

## Режимы работы

### HID (Human Interface Device)

**Режим по умолчанию.** Сканер эмулирует клавиатуру.

```
Сканер → USB → ОС → Клавиатурный ввод
```

**Характеристики:**
- Не требует драйверов
- Работает в любом текстовом поле
- Символы штрих-кода + Enter (по умолчанию)
- Поддержка русских символов зависит от раскладки

**Настройка:**
```bash
# HID-сканер работает сразу после подключения
# Проверка
lsusb | grep -iE 'honeywell|zebra|datalogic|mindeo|cipherlab'

# Сканер эмулирует клавиатуру — просто откройте текстовый редактор
# и отсканируйте штрих-код
```

**Настройка префикса/суффикса:**

Большинство сканеров настраиваются через сканирование специальных штрих-кодов из руководства:

| Настройка | Действие |
|-----------|----------|
| Factory Reset | Сброс к заводским настройкам |
| USB HID Keyboard | Режим клавиатуры |
| Add Enter Suffix | Добавить Enter после кода |
| Add Tab Suffix | Добавить Tab после кода |
| Set Russian Layout | Переключение на русскую раскладку |
| Code 128 Enable | Включение Code 128 |
| Code 39 Enable | Включение Code 39 |
| QR Enable | Включение QR-кодов |
| DataMatrix Enable | Включение DataMatrix |

### COM-порт (Virtual COM / SPP)

Эмуляция последовательного порта.

```
Сканер → USB → USB-CDC → /dev/ttyUSB* → Приложение
```

**Характеристики:**
- Требует настройки порта
- Позволяет получать данные без фокуса на поле ввода
- Подходит для фоновой работы

**Настройка:**

```bash
# Проверка обнаружения
lsusb
# Bus 001 Device 005: ID 0536:01c7 Hand Held Products

# Проверка USB-CDC устройства
dmesg | grep -i tty
# [  123.456] usb 1-1.2: cp210x converter now attached to ttyUSB0

# Установка драйвера (если требуется)
sudo dnf install -y usbserial
sudo modprobe usbserial

# Проверка устройства
ls -l /dev/ttyUSB*
# crw-rw---- 1 root dialout 188, 0 /dev/ttyUSB0

# Добавить пользователя в группу dialout
sudo usermod -aG dialout username

# Настройка порта
stty -F /dev/ttyUSB0 9600 cs8 -cstopb -parenb

# Чтение данных
cat /dev/ttyUSB0

# Чтение с таймаутом
timeout 10 cat /dev/ttyUSB0
```

### OPOS (OLE for POS)

Стандарт для POS-оборудования. В Linux поддерживается через **JavaPOS** или **POS for Linux**.

```
Приложение (1С, POS) → JavaPOS/POS for Linux → Сканер
```

**Характеристики:**
- Стандартизированный интерфейс для POS
- Поддержка в 1С через COM-соединение
- Обычно через COM-порт или USB с драйвером

---

## Подключение и настройка USB

### Автоматическое обнаружение

```bash
# Проверка USB-устройства
lsusb

# Подробная информация
lsusb -v -d <vendor_id>:<product_id>

# Просмотр событий USB
udevadm monitor --udev --property

# Информация о USB-устройстве
udevadm info -a -p $(udevadm info -q path -n /dev/bus/usb/001/005)
```

### Udev-правила для сканеров

```bash
# Создание правила для сканера
sudo nano /etc/udev/rules.d/99-barcode-scanner.rules
```

```udev
# Honeywell
SUBSYSTEM=="usb", ATTRS{idVendor}=="0c2e", MODE="0666", GROUP="users"

# Zebra / Symbol / Motorola
SUBSYSTEM=="usb", ATTRS{idVendor}=="05e0", MODE="0666", GROUP="users"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0536", MODE="0666", GROUP="users"

# Datalogic
SUBSYSTEM=="usb", ATTRS{idVendor}=="05f0", MODE="0666", GROUP="users"

# Mindeo
SUBSYSTEM=="usb", ATTRS{idVendor}=="1eab", MODE="0666", GROUP="users"

# CipherLab
SUBSYSTEM=="usb", ATTRS{idVendor}=="1659", MODE="0666", GROUP="users"

# Prolific USB-Serial (для COM-режима)
SUBSYSTEM=="usb", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", \
    MODE="0666", GROUP="dialout"

# CP210x (для COM-режима)
SUBSYSTEM=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", \
    MODE="0666", GROUP="dialout"
```

```bash
# Применение правил
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Проверка работы в HID-режиме

```bash
# Установите утилиту evtest
sudo dnf install -y evtest

# Найдите устройство сканера
evtest

# Выберите устройство и сканируйте штрих-код
# Вывод покажет символьные коды
```

---

## Подключение и настройка Bluetooth

### Подключение через Bluetooth

```bash
# Установка BlueZ
sudo dnf install -y bluez bluez-tools

# Включение Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Проверка адаптера
hciconfig -a

# Поиск устройств
bluetoothctl scan on

# Сканер должен быть в режиме Bluetooth-сопряжения
# (обычно сканирование специального штрих-кода из руководства)

# Сопряжение
bluetoothctl
[bluetooth]# pair AA:BB:CC:DD:EE:FF
[bluetooth]# trust AA:BB:CC:DD:EE:FF
[bluetooth]# connect AA:BB:CC:DD:EE:FF
[bluetooth]# quit

# Проверка подключения
bluetoothctl info AA:BB:CC:DD:EE:FF
```

### Настройка Bluetooth HID

```bash
# Для HID-режима сканер должен определить себя как клавиатуру
# После подключения он будет работать как обычная клавиатура

# Проверка через evdev
cat /dev/input/event*  # сканируйте штрих-код

# Для COM-режима через Bluetooth SPP:
sudo rfcomm bind /dev/rfcomm0 AA:BB:CC:DD:EE:FF 1

# Проверка
ls -l /dev/rfcomm0

# Чтение данных
cat /dev/rfcomm0
```

### Автоматическое переподключение

```bash
# Настройка автоподключения в Bluetooth
sudo nano /etc/bluetooth/main.conf
```

```ini
[Policy]
AutoEnable=true
ReconnectAttempts=7
ReconnectIntervals=1, 2, 4, 8, 16, 32, 64
```

---

## Режим COM-порта

### Настройка последовательного порта

```bash
# Проверка доступных портов
ls /dev/ttyUSB* /dev/ttyACM* /dev/ttyS*

# Настройка параметров порта
stty -F /dev/ttyUSB0 \
    9600 \
    cs8 \
    -cstopb \
    -parenb \
    -crtscts \
    raw

# Параметры:
# 9600     — скорость (baud rate)
# cs8      — 8 бит данных
# -cstopb  — 1 стоп-бит
# -parenb  — без чётности
# -crtscts — без аппаратного контроля
# raw      — сырой режим
```

### Скрипт чтения из COM-порта

```bash
#!/bin/bash
# barcode-reader.sh — Чтение штрих-кодов из COM-порта

PORT="${1:-/dev/ttyUSB0}"
BAUD="${2:-9600}"
LOG_FILE="${3:-/var/log/barcode-scans.log}"

# Настройка порта
stty -F "$PORT" "$BAUD" cs8 -cstopb -parenb raw

echo "=== Чтение штрих-кодов из $PORT ($BAUD бод) ==="
echo "Лог: $LOG_FILE"
echo "Нажмите Ctrl+C для остановки"
echo ""

# Чтение и логирование
while true; do
    barcode=$(timeout 5 cat "$PORT" 2>/dev/null | tr -d '\r')

    if [[ -n "$barcode" ]]; then
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $barcode"
        echo "[$timestamp] $barcode" >> "$LOG_FILE"

        # Здесь можно добавить обработку:
        # - Отправку в базу данных
        # - Проверку по каталогу
        # - Отправку в 1С
    fi
done
```

Использование:

```bash
# Чтение с параметрами по умолчанию
./barcode-reader.sh

# С указанием порта и скорости
./barcode-reader.sh /dev/ttyUSB0 115200 /home/user/scans.log
```

---

## Форматы штрих-кодов

### 1D (линейные) штрих-коды

| Формат | Тип | Длина | Применение |
|--------|-----|-------|------------|
| **EAN-13** | Числовой | 13 цифр | Розничная торговля (Европа) |
| **EAN-8** | Числовой | 8 цифр | Маленькие товары |
| **UPC-A** | Числовой | 12 цифр | Розничная торговля (США) |
| **UPC-E** | Числовой | 6 цифр | Компактный UPC |
| **Code 39** | Буквенно-числовой | Переменная | Промышленность, логистика |
| **Code 128** | Полный ASCII | Переменная | Логистика, этикетки |
| **Code 93** | Буквенно-числовой | Переменная | Улучшенный Code 39 |
| **ITF (Interleaved 2 of 5)** | Числовой | Переменная | Склад, коробки |
| **Codabar** | Числовой + спец. | Переменная | Библиотеки, медицина |
| **ISBN** | Числовой | 13 цифр | Книги |

### 2D штрих-коды

| Формат | Тип | Ёмкость | Применение |
|--------|-----|---------|------------|
| **QR Code** | Буквенно-числовой | до 4296 символов | Маркетинг, оплата, ссылки |
| **DataMatrix** | Буквенно-числовой | до 3116 цифр | Маркировка (Честный ЗНАК) |
| **PDF417** | Буквенно-числовой | до 2710 символов | Документы, билеты |
| **Aztec** | Буквенно-числовой | до 3832 цифр | Транспорт, билеты |
| **MaxiCode** | Буквенно-числовой | до 93 символов | UPS, логистика |

### Поддержка в сканерах

| Сканер | EAN-13 | Code 128 | Code 39 | QR | DataMatrix | PDF417 |
|--------|--------|----------|---------|----|-----------| ------|
| **Honeywell Voyager** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Zebra DS2208** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Datalogic QD2430** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Mindeo MD6600** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Honeywell 1900** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Zebra DS9308** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Бюджетные 1D** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

### Штрих-коды маркировки (Россия)

| Система | Формат | Описание |
|---------|--------|----------|
| **Честный ЗНАК** | DataMatrix | Обязательная маркировка товаров |
| **ЕГАИС** | Code 128 / PDF417 | Алкогольная продукция |
| **ФГИС «Меркурий»** | Code 128 | Ветеринарная сертификация |
| **Маркировка табака** | DataMatrix | Табачная продукция |
| **Маркировка обуви** | DataMatrix | Обувные товары |
| **Маркировка лекарств** | DataMatrix | Лекарственные препараты |
| **Маркировка шин** | DataMatrix | Шины и покрышки |
| **Маркировка фототехники** | DataMatrix | Фотовспышки и камеры |

---

## Производители и модели

### Honeywell

| Модель | Тип | Интерфейс | 1D/2D | Примечание |
|--------|-----|-----------|-------|------------|
| **Voyager 1250g** | Ручной | USB | 1D | Базовый лазерный |
| **Voyager 1400g** | Ручной | USB | 2D | Популярный 2D |
| **Voyager 1902g** | Беспроводной | BT+USB | 2D | Bluetooth |
| **Granit 1911i** | Промышленный | USB | 2D | Ударопрочный |
| **Granit XP 1991i** | Промышленный | BT+USB | 2D | IP65 |
| **Solaris 7600** | Настольный | USB | 1D/2D | Omnidirectional |

### Zebra (Motorola/Symbol)

| Модель | Тип | Интерфейс | 1D/2D | Примечание |
|--------|-----|-----------|-------|------------|
| **DS2208** | Ручной | USB | 2D | Популярный 2D |
| **DS2278** | Беспроводной | BT+USB | 2D | Bluetooth |
| **DS8178** | Беспроводной | BT+USB | 2D | Премиум |
| **DS9308** | Настольный | USB | 2D | Компактный |
| **LI4278** | Беспроводной | BT+USB | 1D | Только 1D |
| **DS3608** | Промышленный | USB | 2D | Ударопрочный |

### Datalogic

| Модель | Тип | Интерфейс | 1D/2D | Примечание |
|--------|-----|-----------|-------|------------|
| **QD2430** | Ручной | USB | 2D | Популярный |
| **QD2131** | Ручной | USB | 1D | Бюджетный |
| **PowerScan PM9500** | Ручной | USB/BT | 2D | Промышленный |
| **Gryphon GD4500** | Ручной | USB | 2D | Средний класс |
| **Magellan 8400** | Настольный | USB | 1D/2D | Omni |
| **Matrix 410N** | Стационарный | Ethernet | 2D | Конвейер |

### Mindeo

| Модель | Тип | Интерфейс | 1D/2D | Примечание |
|--------|-----|-----------|-------|------------|
| **MD6600** | Настольный | USB | 2D | Omni-directional |
| **CS1800** | Ручной | USB | 1D | Бюджетный |
| **MP8300** | Ручной | USB | 2D | Средний класс |
| **HT6600** | Ручной | USB | 2D | Компактный |

### Таблица совместимости с РЕД ОС

| Производитель | HID | COM | Bluetooth | 1С | Примечание |
|--------------|-----|-----|-----------|----|------------|
| **Honeywell** | ✅ | ✅ | ✅ | ✅ | Отличная поддержка |
| **Zebra** | ✅ | ✅ | ✅ | ✅ | Отличная поддержка |
| **Datalogic** | ✅ | ✅ | ✅ | ✅ | Отличная поддержка |
| **Mindeo** | ✅ | ✅ | ⚠️ | ✅ | Bluetooth может требовать настройки |
| **CipherLab** | ✅ | ✅ | ⚠️ | ✅ | Бюджетные модели |
| **Newland** | ✅ | ✅ | ⚠️ | ✅ | Бюджетные модели |

---

## Интеграция с 1С

### Подключение в 1С:Предприятие

#### Через HID-режим (рекомендуемый)

Сканер в HID-режиме работает как клавиатура — 1С получает данные автоматически:

```
1. Подключить сканер в USB
2. Открыть документ в 1С (Поступление товаров, Продажа)
3. Установить курсор в поле "Штрихкод"
4. Отсканировать — код появится автоматически
```

#### Через COM-порт (для специализированных задач)

```bsl
// Код на встроенном языке 1С

// Открытие COM-порта
Порт = Новый COMОбъект("MsCommLib.MsComm");
Порт.CommPort = 1;               // COM1
Порт.Settings = "9600,N,8,1";    // Настройки
Порт.InputLen = 0;
Порт.PortOpen = Истина;

// Чтение штрих-кода
ШтрихКод = Порт.Input;
Если ПустаяСтрока(ШтрихКод) Тогда
    Сообщить("Штрих-код не получен");
Иначе
    Сообщить("Получен штрих-код: " + СокрЛП(ШтрихКод));
КонецЕсли;

// Закрытие порта
Порт.PortOpen = Ложь;
```

#### Через внешнюю компоненту (Native API)

Для подключения через драйвер производителя:

```bsl
// Подключение через драйвер
ДрайверСканера = Новый COMОбъект("Scanner.Driver");
ДрайверСканера.OpenPort("COM1", 9600);
ШтрихКод = ДрайверСканера.ReadBarcode();
ДрайверСканера.ClosePort();
```

### Подключение в 1С:Розница

1. **Администрирование → Подключаемое оборудование**
2. **Добавить → Сканер штрихкодов**
3. Выбрать тип подключения:
   - **Клавиатура** (HID-режим) — автоматически
   - **COM-порт** — указать порт и скорость
4. **Тест устройства** — проверить сканирование

### Подключение в 1С:УТ

1. **НСИ и администрирование → Подключаемое оборудование**
2. **Сканеры штрихкодов → Создать**
3. Выбрать драйвер:
   - **Кладовщик** (для терминалов)
   - **1С:Сканер штрихкодов** (универсальный)
4. Настроить параметры подключения

### Настройка обработки штрих-кодов в 1С

```bsl
// Обработка сканирования штрих-кода
Процедура ОбработкаСканера(ШтрихКод)

    // Поиск товара по штрих-коду
    Запрос = Новый Запрос;
    Запрос.Текст = "
        |ВЫБРАТЬ
        |    Номенклатура.Ссылка КАК Номенклатура,
        |    Номенклатура.Наименование
        |ИЗ
        |    Справочник.Номенклатура КАК Номенклатура
        |ГДЕ
        |    Номенклатура.Штрихкод = &ШтрихКод
    ";
    Запрос.УстановитьПараметр("ШтрихКод", ШтрихКод);

    Результат = Запрос.Выполнить().Выбрать();
    Если Результат.Следующий() Тогда
        Сообщить("Найден: " + Результат.Наименование);
        // Добавить в документ
    Иначе
        Сообщить("Товар со штрих-кодом " + ШтрихКод + " не найден");
    КонецЕсли;

КонецПроцедуры
```

---

## Генерация штрих-кодов

### Python — библиотека `python-barcode`

```bash
# Установка
pip3 install python-barcode pillow

# Генерация EAN-13
python3 -c "
import barcode
from barcode.writer import ImageWriter

# EAN-13
ean = barcode.get('ean13', '5901234123457', writer=ImageWriter())
ean.save('ean13_barcode')

# Code 128
code128 = barcode.get('code128', 'HELLO-WORLD', writer=ImageWriter())
code128.save('code128_barcode')

# Code 39
code39 = barcode.get('code39', 'ABC123', writer=ImageWriter())
code39.save('code39_barcode')
"
```

### Python — генерация QR-кодов

```bash
# Установка
pip3 install qrcode pillow

# Генерация QR
python3 -c "
import qrcode

# Простой QR
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)
qr.add_data('https://example.com')
qr.make(fit=True)

img = qr.make_image(fill_color='black', back_color='white')
img.save('qr_code.png')

# DataMatrix (через pylibdmtx)
# pip3 install pylibdmtx
from pylibdmtx.wrapper import encode
from PIL import Image

data = b'Честный ЗНАК DataMatrix'
encoded = encode(data)
img = Image.frombytes('RGB', (encoded.width, encoded.height), encoded.pixels)
img.save('datamatrix.png')
"
```

### CLI — утилита `qrencode`

```bash
# Установка
sudo dnf install -y qrencode

# Генерация QR-кода
qrencode -o qr.png "https://example.com"

# С параметрами
qrencode -o qr_large.png \
    -s 10 \
    -m 4 \
    -l H \
    "https://example.com"

# Параметры:
# -s N    — размер точки (пиксели)
# -m N    — размер рамки (модули)
# -l L/M/H/Q — уровень коррекции ошибок

# Вывод в терминал
qrencode -t ANSI256 "Hello World"

# Генерация SVG
qrencode -o qr.svg -t SVG "https://example.com"
```

### CLI — утилита `bardecode` / `zint`

```bash
# Установка Zint (универсальный генератор)
sudo dnf install -y zint zint-qt

# Генерация различных штрих-кодов
zint -o ean13.png -b 13 -d "5901234123457"
zint -o code128.png -b 7 -d "HELLO-WORLD"
zint -o code39.png -b 2 -d "ABC123"
zint -o qr.png -b 58 -d "https://example.com"
zint -o datamatrix.png -b 71 -d "DataMatrix content"
zint -o pdf417.png -b 55 -d "PDF417 content"

# Параметры:
# -b N   — тип штрих-кода (13=EAN-13, 7=Code 128, 58=QR, 71=DataMatrix)
# -d     — данные
# -o     — выходной файл
# --scale=N — масштаб
# -i     — инвертировать цвета
```

### Python — пакетная генерация

```bash
#!/usr/bin/env python3
# generate-barcodes.py — Пакетная генерация штрих-кодов

import sys
import csv
import qrcode
import barcode
from barcode.writer import ImageWriter

def generate_qr(data, filename):
    """Генерация QR-кода"""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color='black', back_color='white')
    img.save(filename)
    print(f"QR: {filename}")

def generate_ean13(data, filename):
    """Генерация EAN-13"""
    ean = barcode.get('ean13', data, writer=ImageWriter())
    ean.save(filename)
    print(f"EAN-13: {filename}.png")

def generate_code128(data, filename):
    """Генерация Code 128"""
    code128 = barcode.get('code128', data, writer=ImageWriter())
    code128.save(filename)
    print(f"Code 128: {filename}.png")

def process_csv(csv_file, output_dir):
    """Обработка CSV-файла со штрих-кодами"""
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            code = row.get('barcode', '')
            btype = row.get('type', 'qr')

            if not code:
                continue

            if btype == 'qr':
                generate_qr(code, f"{output_dir}/qr_{code}.png")
            elif btype == 'ean13':
                generate_ean13(code, f"{output_dir}/ean_{code}")
            elif btype == 'code128':
                generate_code128(code, f"{output_dir}/c128_{code}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Использование: generate-barcodes.py <csv_file> [output_dir]")
        sys.exit(1)

    csv_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else './barcodes'

    import os
    os.makedirs(output_dir, exist_ok=True)
    process_csv(csv_file, output_dir)
```

CSV-файл для скрипта:

```csv
barcode,type
https://example.com,qr
5901234123457,ean13
PRODUCT-001,code128
```

---

## POS-интеграция

### Подключение к POS-системам

#### Структура POS-системы

```
┌─────────────────────────────────────────────┐
│          POS-приложение                      │
│  (1С:Розница, Frontol, АТОЛ и др.)          │
└──────────────────┬──────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    ▼              ▼              ▼
┌───────┐   ┌───────────┐  ┌────────┐
│Сканер │   │  Кассовый  │  │Дисплей │
│  ШК   │   │  аппарат   │  │покуп.  │
└───────┘   └───────────┘  └────────┘
```

### Интеграция с АТОЛ

```bash
# АТОЛ предоставляет драйверы для Linux
# Скачивание с https://www.atol.ru/support/

# Установка драйвера ККТ
sudo dnf install -y atol-drivers-*.rpm

# Проверка устройства
lsusb | grep atol

# Тест подключения
/usr/local/atol/bin/test_driver
```

### Интеграция с Frontol

```bash
# Frontol — кассовое ПО
# Установка на РЕД ОС может потребовать Wine или нативную версию

# Проверка поддержки сканера
# Frontol поддерживает HID-сканеры автоматически
```

### Простая POS-система на Python

```python
#!/usr/bin/env python3
# simple-pos.py — Простая POS-система со сканером

import sys
import json
from datetime import datetime

# База товаров (в реальном мире — из базы данных)
PRODUCTS = {
    "4601234567890": {"name": "Молоко 1л", "price": 89.90},
    "4601234567891": {"name": "Хлеб белый", "price": 52.00},
    "4601234567892": {"name": "Сыр 200г", "price": 249.90},
    "4601234567893": {"name": "Чай 100пак", "price": 189.00},
}

class POSSystem:
    def __init__(self):
        self.cart = []
        self.total = 0.0

    def scan_barcode(self, barcode):
        """Обработка штрих-кода"""
        if barcode in PRODUCTS:
            product = PRODUCTS[barcode]
            self.cart.append({
                "barcode": barcode,
                "name": product["name"],
                "price": product["price"],
            })
            self.total += product["price"]
            print(f"✅ {product['name']}: {product['price']:.2f} ₽")
        else:
            print(f"❌ Товар со штрих-кодом {barcode} не найден")

    def print_receipt(self):
        """Печать чека"""
        print("\n" + "=" * 40)
        print("           КАССОВЫЙ ЧЕК")
        print(f"   Дата: {datetime.now().strftime('%d.%m.%Y %H:%M')}")
        print("=" * 40)

        for item in self.cart:
            print(f"  {item['name']:20s} {item['price']:>8.2f} ₽")

        print("-" * 40)
        print(f"  ИТОГО: {self.total:>26.2f} ₽")
        print("=" * 40 + "\n")

    def save_receipt(self, filename="receipt.json"):
        """Сохранение чека в файл"""
        receipt = {
            "date": datetime.now().isoformat(),
            "items": self.cart,
            "total": self.total,
        }
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(receipt, f, ensure_ascii=False, indent=2)
        print(f"Чек сохранён: {filename}")

def main():
    pos = POSSystem()
    print("=== POS-система ===")
    print("Вводите штрих-коды или 'print' для чека, 'quit' для выхода")
    print()

    while True:
        try:
            barcode = input("Штрих-код: ").strip()

            if barcode.lower() == 'quit':
                break
            elif barcode.lower() == 'print':
                pos.print_receipt()
                pos.save_receipt()
                pos = POSSystem()  # Сброс
            elif barcode:
                pos.scan_barcode(barcode)
                print(f"  Сумма: {pos.total:.2f} ₽")

        except KeyboardInterrupt:
            print("\n")
            pos.print_receipt()
            break
        except EOFError:
            break

if __name__ == '__main__':
    main()
```

---

## Автоматический скрипт настройки

### setup-barcode-scanner.sh

```bash
#!/bin/bash
# setup-barcode-scanner.sh — Автоматическая настройка сканера штрих-кодов

set -euo pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCANNER_MODE="${1:-hid}"  # hid, com, bluetooth

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $1"; }

# Проверка root
if [[ $EUID -ne 0 ]]; then
    log_error "Запустите с sudo"
    exit 1
fi

# Определение производителя
detect_brand() {
    log_info "Определение сканера..."

    local usb_info=$(lsusb 2>/dev/null || true)

    if echo "$usb_info" | grep -qi '0c2e\|honeywell'; then
        echo "honeywell"
    elif echo "$usb_info" | grep -qi '05e0\|0536\|zebra'; then
        echo "zebra"
    elif echo "$usb_info" | grep -qi '05f0\|datalogic'; then
        echo "datalogic"
    elif echo "$usb_info" | grep -qi '1eab\|mindeo'; then
        echo "mindeo"
    else
        echo "unknown"
    fi
}

# Создание udev-правил
create_udev_rules() {
    log_step "Создание udev-правил..."

    cat > /etc/udev/rules.d/99-barcode-scanner.rules << 'EOF'
# Honeywell
SUBSYSTEM=="usb", ATTRS{idVendor}=="0c2e", MODE="0666", GROUP="users"

# Zebra / Symbol
SUBSYSTEM=="usb", ATTRS{idVendor}=="05e0", MODE="0666", GROUP="users"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0536", MODE="0666", GROUP="users"

# Datalogic
SUBSYSTEM=="usb", ATTRS{idVendor}=="05f0", MODE="0666", GROUP="users"

# Mindeo
SUBSYSTEM=="usb", ATTRS{idVendor}=="1eab", MODE="0666", GROUP="users"

# USB-Serial (COM-режим)
SUBSYSTEM=="usb", ATTRS{idVendor}=="067b", MODE="0666", GROUP="dialout"
SUBSYSTEM=="usb", ATTRS{idVendor}=="10c4", MODE="0666", GROUP="dialout"
EOF

    sudo udevadm control --reload-rules
    sudo udevadm trigger
    log_info "udev-правила созданы"
}

# Настройка HID-режима
setup_hid() {
    log_step "Настройка HID-режима..."

    log_info "HID-режим не требует дополнительной настройки"
    log_info "Сканер будет работать как клавиатура"
    log_info "Проверьте: откройте текстовый редактор и отсканируйте штрих-код"
}

# Настройка COM-режима
setup_com() {
    local port="${1:-/dev/ttyUSB0}"
    local baud="${2:-9600}"

    log_step "Настройка COM-режима..."

    # Проверка порта
    if [[ ! -e "$port" ]]; then
        log_error "Порт $port не найден"
        log_info "Доступные порты:"
        ls /dev/ttyUSB* /dev/ttyACM* /dev/ttyS* 2>/dev/null || echo "  Нет доступных"
        return 1
    fi

    # Настройка
    stty -F "$port" "$baud" cs8 -cstopb -parenb raw
    log_info "Порт $port настроен на $baud бод"

    # Тест
    log_info "Тест чтения (5 секунд):"
    timeout 5 cat "$port" 2>/dev/null | tr -d '\r' || true
}

# Установка утилит
install_tools() {
    log_step "Установка утилит..."

    dnf install -y evtest
    dnf install -y qrencode
    dnf install -y zint 2>/dev/null || log_warn "Zint недоступен в репозитории"

    # Python-библиотеки
    if command -v pip3 &>/dev/null; then
        pip3 install --user python-barcode pillow qrcode 2>/dev/null || true
    fi

    log_info "Утилиты установлены"
}

# Итоговая информация
final_info() {
    local brand=$(detect_brand)

    echo ""
    log_info "=== Сканер штрих-кодов настроен ==="
    echo ""
    echo "Производитель: $brand"
    echo "Режим: $SCANNER_MODE"
    echo ""

    if [[ "$SCANNER_MODE" == "hid" ]]; then
        echo "HID-режим: сканер работает как клавиатура"
        echo "Проверка: откройте текстовый редактор и отсканируйте"
    elif [[ "$SCANNER_MODE" == "com" ]]; then
        echo "COM-режим: данные читаются из /dev/ttyUSB*"
        echo "Чтение: cat /dev/ttyUSB0"
    fi

    echo ""
    echo "Утилиты:"
    echo "  qrencode  — генерация QR-кодов"
    echo "  zint      — генерация всех типов штрих-кодов"
    echo "  evtest    — проверка HID-ввода"
}

# Основная функция
main() {
    log_info "=== Настройка сканера штрих-кодов ==="

    create_udev_rules
    install_tools

    case "$SCANNER_MODE" in
        hid)
            setup_hid
            ;;
        com)
            setup_com "${2:-/dev/ttyUSB0}" "${3:-9600}"
            ;;
        bluetooth)
            log_info "Bluetooth-режим: используйте bluetoothctl для сопряжения"
            log_info "После сопряжения сканер работает как HID или COM"
            ;;
        *)
            log_error "Неизвестный режим: $SCANNER_MODE"
            log_info "Доступные режимы: hid, com, bluetooth"
            exit 1
            ;;
    esac

    final_info
}

main "$@"
```

Использование:

```bash
# HID-режим (по умолчанию)
sudo bash setup-barcode-scanner.sh

# COM-режим
sudo bash setup-barcode-scanner.sh com /dev/ttyUSB0 9600

# Bluetooth
sudo bash setup-barcode-scanner.sh bluetooth
```

---

## Диагностика и устранение проблем

### Основные команды диагностики

```bash
# Проверка USB-подключения
lsusb
lsusb -v | grep -iE 'honeywell|zebra|datalogic|mindeo'

# Проверка событий USB
udevadm monitor --udev --property

# Проверка HID-ввода
sudo evtest

# Проверка COM-порта
ls -l /dev/ttyUSB* /dev/ttyACM*
dmesg | grep -i tty
stty -F /dev/ttyUSB0 -a

# Проверка Bluetooth
bluetoothctl
hciconfig -a

# Тест сканирования
# Откройте текстовый редактор и отсканируйте штрих-код
```

### Типичные проблемы и решения

| Проблема | Причина | Решение |
|----------|---------|---------|
| Сканер не определяется | USB-порт / кабель | Проверить `lsusb`, другой порт |
| Сканирует не те символы | Раскладка | Переключить на EN, настроить префикс |
| Нет Enter после кода | Настройка суффикса | Сканировать штрих-код «Add Enter Suffix» |
| Дублирование символов | Rate too fast | Настроить скорость в `xset` |
| COM-порт не работает | Драйвер | Установить `usbserial`, `cp210x` |
| Bluetooth не подключается | Режим сопряжения | Сканировать штрих-код сопряжения |
| 1С не видит сканер | Не тот режим | Использовать HID-режим для 1С |
| QR не сканируется | 1D-сканер | Нужен 2D-сканер (имиджер) |
| DataMatrix не читается | Отключен формат | Включить через штрих-код настройки |

### Решение проблем с HID-режимом

```bash
# 1. Проверка распознавания
lsusb
# Если сканер есть — переходим дальше

# 2. Проверка ввода
sudo evtest
# Выберите устройство сканера и отсканируйте

# 3. Если символы дублируются
xset r rate 200 30  # Задержка 200мс, повтор 30/с

# 4. Проверка раскладки
# Сканер обычно настроен на английскую раскладку
# Переключитесь на EN перед сканированием

# 5. Если сканер вводит «не те» символы
# Отсканируйте «Factory Reset» из руководства
# Затем «USB HID Keyboard»
# Затем «Add Enter Suffix»
```

### Решение проблем с COM-режимом

```bash
# 1. Проверка устройства
dmesg | grep -i usb
# Должно быть: "cp210x converter now attached to ttyUSB0"

# 2. Проверка прав
ls -l /dev/ttyUSB0
# Должно быть: crw-rw---- ... dialout

# 3. Добавить пользователя в группу
sudo usermod -aG dialout $USER

# 4. Настройка порта
stty -F /dev/ttyUSB0 9600 cs8 -cstopb -parenb raw

# 5. Тест чтения
cat /dev/ttyUSB0
# Отсканируйте штрих-код — данные появятся в терминале
```

---

## Справочник команд

| Команда | Описание | Пример |
|---------|----------|--------|
| `lsusb` | Список USB-устройств | `lsusb` |
| `evtest` | Тест HID-ввода | `sudo evtest` |
| `stty` | Настройка COM-порта | `stty -F /dev/ttyUSB0 9600` |
| `cat /dev/ttyUSB0` | Чтение из COM-порта | `cat /dev/ttyUSB0` |
| `qrencode` | Генерация QR | `qrencode -o qr.png "text"` |
| `zint` | Генерация ШК | `zint -o out.png -b 13 -d "590..."` |
| `bluetoothctl` | Управление BT | `bluetoothctl scan on` |
| `udevadm monitor` | Мониторинг udev | `udevadm monitor --udev` |

### Форматы Zint

| Код | Формат | Тип |
|-----|--------|-----|
| 1 | Code 11 | 1D |
| 2 | Code 39 | 1D |
| 5 | EAN 13 | 1D |
| 7 | Code 128 | 1D |
| 8 | UPC-A | 1D |
| 9 | Bookland (ISBN) | 1D |
| 13 | EAN 13 | 1D |
| 16 | ITF-14 | 1D |
| 34 | PDF417 | 2D |
| 55 | PDF417 | 2D |
| 57 | Micro PDF417 | 2D |
| 58 | QR Code | 2D |
| 69 | Micro QR | 2D |
| 71 | DataMatrix | 2D |
| 75 | Aztec | 2D |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **Ядро** | 5.15+ (USB HID, CDC-ACM) |
| **Bluetooth** | BlueZ 5.x |
| **Python** | 3.9+ (для генерации) |
| **1С** | 8.3.x (платформа Linux) |
| **Права** | root (установка), dialout (COM-режим) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> USB HID-сканеры работают без драйверов на обеих версиях. COM-порт требует настройки udev правил.

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
