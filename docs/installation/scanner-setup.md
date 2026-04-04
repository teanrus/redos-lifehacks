# Подключение сканера в операционной системе РЕД ОС 7+

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## Лайфхаки по подключению и настройке сканера

### 1. Проверка обнаружения сканера

```bash
# Список обнаруженных сканеров
scanimage -L

# Подробная информация о SANE
sane-find-scanner

# Проверка прав доступа к USB-устройству
ls -l /dev/bus/usb/
```

> **Совет:** Если `scanimage -L` не находит сканер, попробуйте `sane-find-scanner` — он работает на более низком уровне и может обнаружить устройство даже без драйверов.

---

### 2. Установка SANE и базовых утилит

```bash
# Установка SANE и зависимостей
sudo dnf install sane-backends sane-frontends xsane simple-scan

# Проверка версии SANE
scanimage -V

# Перезапуск службы (если используется saned)
sudo systemctl restart saned.socket
```

> **Совет:** `simple-scan` — лёгкий и удобный сканер для повседневного использования. `xsane` — продвинутый инструмент с множеством настроек.

---

### 3. Настройка прав доступа для пользователя

```bash
# Добавление пользователя в группу scanner
sudo usermod -aG scanner $USER

# Для USB-сканеров — добавление в группу lp
sudo usermod -aG lp $USER

# Проверка групп
groups $USER
```

> **Совет:** После добавления в группу нужно выйти из системы и зайти заново (или перезагрузиться).

---

### 4. Настройка udev-правил для USB-сканера

Если сканер определяется только через `sudo`:

```bash
# Создание правила udev
sudo tee /etc/udev/rules.d/55-libsane.rules << 'EOF'
# Epson
ATTRS{idVendor}=="04b8", ENV{libsane_matched}="yes"
# Canon
ATTRS{idVendor}=="04a9", ENV{libsane_matched}="yes"
# HP
ATTRS{idVendor}=="03f0", ENV{libsane_matched}="yes"
# Brother
ATTRS{idVendor}=="04f9", ENV{libsane_matched}="yes"
# Fujitsu
ATTRS{idVendor}=="04c5", ENV{libsane_matched}="yes"
# Samsung
ATTRS{idVendor}=="04e8", ENV{libsane_matched}="yes"

# Разрешить доступ пользователю
ENV{libsane_matched}=="yes", TAG+="uaccess", TAG+="udev-acl"
EOF

# Перезагрузка правил udev
sudo udevadm control --reload-rules
sudo udevadm trigger
```

> **Совет:** Узнайте ID производителя через `lsusb` и добавьте своё правило, если сканер не из списка выше.

---

### 5. Сканирование через командную строку

```bash
# Базовое сканирование в PNG
scanimage --format=png > scan.png

# Сканирование с указанием разрешения
scanimage --format=png --resolution 300 > scan_300dpi.png

# Сканирование в PDF (через ImageMagick)
scanimage --format=tiff > scan.tiff
convert scan.tiff scan.pdf

# Сканирование нескольких страниц
scanimage --format=tiff --batch=page_%03d.tiff --source "ADF"
```

> **Совет:** `--source "ADF"` использует автоподатчик документов (если есть). Для планшетного сканера используйте `--source "Flatbed"`.

---

### 6. Настройка Simple Scan (графический интерфейс)

```bash
# Запуск
simple-scan

# Или через меню:
# Приложения → Графика → Простое сканирование
```

**Основные возможности:**
- Сканирование в PDF, JPEG, PNG
- Выбор разрешения (150, 300, 600 dpi)
- Черно-белый, оттенки серого, цветной режим
- Обрезка и поворот страниц
- Сканирование с автоподатчика

> **Совет:** Для документов достаточно 150–200 dpi. Для фотографий — 300–600 dpi.

---

### 7. Настройка XSane (продвинутый режим)

```bash
# Запуск
xsane

# Или через меню:
# Приложения → Графика → XSane
```

**Возможности XSane:**
- Точная настройка яркости, контраста, гаммы
- Предварительный просмотр области сканирования
- Пакетное сканирование
- Удаление пыли и царапин (для поддерживаемых сканеров)
- Сохранение в различных форматах (PDF, TIFF, JPEG, PNG)
- Отправка скана по email, факсу, OCR

> **Совет:** Включите «Сохранить настройки по умолчанию» после первой настройки — не придётся настраивать каждый раз.

---

### 8. Сетевое сканирование

#### Настройка сервера (ПК с подключённым сканером):

```bash
# Разрешить сканирование из сети
sudo tee -a /etc/sane.d/saned.conf << 'EOF'
# Разрешить сканирование из локальной сети
192.168.1.0/24
EOF

# Включить службу
sudo systemctl enable saned.socket
sudo systemctl start saned.socket

# Открыть порт в firewall
sudo firewall-cmd --permanent --add-port=6566/tcp
sudo firewall-cmd --reload
```

#### Настройка клиента (другой ПК в сети):

```bash
# Добавить адрес сервера
sudo tee -a /etc/sane.d/net.conf << 'EOF'
# Адрес сервера сканирования
192.168.1.100
EOF

# Проверка обнаружения
scanimage -L
```

> **Совет:** Сетевое сканирование работает через `saned` (порт 6566). Убедитесь, что firewall не блокирует соединение.

---

### 9. Установка драйверов для конкретных брендов

#### Epson:
```bash
# Установка драйверов Epson (Image Scan!)
sudo dnf install iscan iscan-plugin-esci isns

# Или скачать с сайта:
# https://download.ebz.epson.net/dsc/search/01/search/?OSC=LX
```

#### Canon:
```bash
# Установка драйверов Canon (ScanGear)
# Скачать с https://www.canon.ru/support/
sudo dnf install ./scangearmp2-*.rpm
```

#### Brother:
```bash
# Установка драйверов Brother
# Скачать с https://support.brother.com/g/b/downloadlist.aspx
sudo dnf install ./brscan5-*.rpm
sudo dnf install ./brscan-skey-*.rpm

# Проверка установки
brsaneconfig5 -q
```

#### HP:
```bash
# Установка HPLIP (включает поддержку сканеров HP)
sudo dnf install hplip hplip-gui

# Настройка
hp-setup
hp-scan
```

> **Совет:** Для большинства современных сканеров HP достаточно `hplip`. Для Epson и Brother может потребоваться установка проприетарных драйверов.

---

### 10. Сканирование в PDF с несколькими страницами

```bash
# Установка pdfsandwich
sudo dnf install pdfsandwich

# Сканирование нескольких страниц
scanimage --format=tiff --resolution 300 --batch=page_%03d.tiff

# Объединение в PDF
convert page_*.tiff output.pdf

# Или через pdfsandwich (с OCR)
pdfsandwich page_*.tiff -o output.pdf
```

> **Совет:** Для OCR (распознавания текста) установите `tesseract` и нужные языковые пакеты:
```bash
sudo dnf install tesseract tesseract-langpack-rus
```

---

### 11. Диагностика проблем

#### Сканер не определяется:
```bash
# Проверка USB-подключения
lsusb

# Проверка логов
dmesg | grep -i usb
journalctl -xe | grep sane

# Проверка прав доступа
ls -l /dev/bus/usb/
```

#### Ошибка «Device busy»:
```bash
# Проверка процессов, использующих сканер
lsof /dev/bus/usb/*/*

# Завершение зависших процессов
killall xsane simple-scan
```

#### Ошибка «Invalid argument»:
```bash
# Проверка конфигурации SANE
cat /etc/sane.d/dll.conf | grep -v "^#" | grep -v "^$"

# Отключение ненужных бэкендов
sudo nano /etc/sane.d/dll.conf
# Закомментируйте неиспользуемые драйверы символом #
```

#### Медленное сканирование:
```bash
# Уменьшение разрешения
scanimage --resolution 150

# Отключение предварительного просмотра
# В xsane: Настройки → Отключить предварительный просмотр
```

---

### 12. Полезные команды

| Команда | Описание |
|---------|----------|
| `scanimage -L` | Список обнаруженных сканеров |
| `sane-find-scanner` | Поиск сканеров на USB |
| `scanimage --format=png > scan.png` | Сканирование в PNG |
| `simple-scan` | Графический сканер |
| `xsane` | Продвинутый графический сканер |
| `hp-scan` | Сканирование через HPLIP |
| `brscan-skey` | Утилита сканирования Brother |
| `scanimage --help` | Список всех параметров сканирования |

---

## См. также

- [Настройка принтера через CUPS](/docs/installation/printer-setup.md)
- [Установка принтеров Kyocera](/docs/troubleshooting/printers-kyocera.md)

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Система сканирования** | SANE, simple-scan, xsane |
| **Подключение** | USB, сетевое (saned) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x SANE обычно установлен по умолчанию. Для сетевых сканеров убедитесь, что порт 6566/tcp открыт в firewalld.
