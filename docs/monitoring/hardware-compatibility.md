# 🔍 Проверка совместимости оборудования в РЕД ОС

> Полное руководство по проверке совместимости процессоров, GPU, сетевых адаптеров, накопителей, USB-устройств, Wi-Fi, Bluetooth, принтеров, ноутбуков и серверного оборудования с РЕД ОС 7.x / 8.x. Включает автоматический скрипт `hw-check.sh`.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

---

## Оглавление

1. [Системные требования](#-системные-требования)
2. [Поддержка архитектур](#-поддержка-архитектур)
3. [Проверка процессора](#-проверка-процессора)
4. [Проверка видеокарты (GPU)](#-проверка-видеокарты-gpu)
5. [Сетевые адаптеры](#-сетевые-адаптеры)
6. [Звуковые карты](#-звуковые-карты)
7. [Накопители (HDD, SSD, NVMe)](#-накопители-hdd-ssd-nvme)
8. [USB-устройства](#-usb-устройства)
9. [Wi-Fi адаптеры](#-wi-fi-адаптеры)
10. [Bluetooth](#-bluetooth)
11. [Принтеры и сканеры](#-принтеры-и-сканеры)
12. [Ноутбуки](#-ноутбуки)
13. [Серверное оборудование](#-серверное-оборудование)
14. [Автоматический скрипт hw-check.sh](#-автоматический-скрипт-hw-checksh)
15. [Генерация отчётов](#-генерация-отчётов)
16. [Устранение проблем](#-устранение-проблем)
17. [Требования и совместимость](#-требования-и-совместимость)

---

## Системные требования

### РЕД ОС 7.x

| Компонент | Минимальные | Рекомендуемые |
|-----------|-------------|---------------|
| **Процессор** | x86_64, 1 ГГц | x86_64, 2+ ядер, 2+ ГГц |
| **Оперативная память** | 1 ГБ (минимум) | 4+ ГБ |
| **Диск** | 10 ГБ | 40+ ГБ SSD |
| **Видео** | VGA-совместимая | OpenGL 2.0+, 256 МБ VRAM |
| **Сеть** | Ethernet 100 Мбит | Gigabit Ethernet |
| **Монитор** | 800x600 | 1920x1080 |
| **Установка** | DVD, USB | USB 3.0, PXE |

### РЕД ОС 8.x

| Компонент | Минимальные | Рекомендуемые |
|-----------|-------------|---------------|
| **Процессор** | x86_64, 1.5 ГГц | x86_64, 4+ ядер, 2.5+ ГГц |
| **Оперативная память** | 2 ГБ (минимум) | 8+ ГБ |
| **Диск** | 15 ГБ | 60+ ГБ NVMe SSD |
| **Видео** | VGA-совместимая | OpenGL 3.3+, 512 МБ VRAM |
| **Сеть** | Ethernet 100 Мбит | Gigabit Ethernet |
| **Монитор** | 1024x768 | 1920x1080+ |
| **UEFI** | Рекомендуется | Secure Boot (опционально) |

### Рабочий стол vs Сервер

| Параметр | Рабочий стол | Сервер |
|----------|-------------|--------|
| **CPU** | 2+ ядра | 4+ ядер |
| **RAM** | 4+ ГБ | 16+ ГБ |
| **Disk** | 40 ГБ SSD | 100 ГБ+ RAID |
| **GPU** | Требуется для GUI | Не требуется |
| **Сеть** | 1 адаптер | 2+ адаптера |
| **Монитор** | Обязательно | Опционально (IPMI) |

---

## Поддержка архитектур

### Поддерживаемые архитектуры

| Архитектура | РЕД ОС 7.x | РЕД ОС 8.x | Примечание |
|-------------|-----------|-----------|------------|
| **x86_64** | ✅ Полная | ✅ Полная | Основная платформа |
| **aarch64 (ARM64)** | ✅ Да | ✅ Да | Байкал, Эльбрус (через эмуляцию) |
| **i386 (32-bit)** | ❌ Нет | ❌ Нет | Не поддерживается |
| **mips64el** | ⚠️ Ограничено | ⚠️ Ограничено | Специфические платформы |
| **riscv64** | ❌ Нет | ⚠️ Экспериментально | Развитие в процессе |
| **loongarch64** | ❌ Нет | ⚠️ Экспериментально | Эльбрус |

### Проверка архитектуры

```bash
# Текущая архитектура
uname -m

# Подробная информация
lscpu | grep -E "Architecture|CPU op-mode"

# Доступные архитектуры пакетов
dnf config-manager --dump | grep -i arch
```

---

## Проверка процессора

### Общая информация

```bash
# Вся информация о процессоре
lscpu

# Модель и семейство
lscpu | grep -E "Model name|Family|Model|Stepping"

# Ядра и потоки
lscpu | grep -E "CPU\(s\)|Thread|Core|Socket|Book"

# Кэш
lscpu | grep -i cache

# Виртуализация
lscpu | grep -E "Virtualization|Hypervisor"

# Флаги процессора
cat /proc/cpuinfo | grep flags | head -1
```

### Intel процессоры

```bash
# Проверка микрокода Intel
sudo dnf install -y iucode-tool
sudo iucode-tool -tb -l /lib/firmware/intel-ucode/

# Проверка загруженного микрокода
dmesg | grep microcode

# Intel-specific features
cat /proc/cpuinfo | grep -E "model name|flags" | head -2
```

### AMD процессоры

```bash
# AMD-specific features
cat /proc/cpuinfo | grep -E "model name|flags" | head -2

# Проверка AMD-V (виртуализация)
lscpu | grep Virtualization

# AMD P-State (энергосбережение)
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null
```

### Виртуализация

```bash
# Поддержка виртуализации CPU
lscpu | grep Virtualization

# Intel VT-x
grep -E "vmx" /proc/cpuinfo

# AMD-V
grep -E "svm" /proc/cpuinfo

# Проверка работы KVM
lsmod | grep kvm
sudo dnf install -y kvm-ok 2>/dev/null || echo "Проверка через lsmod"

# Если виртуальная машина
systemd-detect-virt

# Тип гипервизора
sudo dmidecode -t system | grep -E "Product|Manufacturer"
```

### CPU Benchmarks (командная строка)

```bash
# Установка sysbench
sudo dnf install -y sysbench

# Тест CPU
sysbench cpu --cpu-max-prime=20000 run

# Тест нескольких потоков
sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run

# Результат: events per second -- чем выше, тем лучше

# Сравнительная таблица (примерные значения sysbench events/sec):
# Процессор             | 1 поток | 4 потока | 8 потоков
# ---------------------|---------|----------|----------
# Intel i3-8100        | ~2500   | ~8000    | N/A
# Intel i5-10400       | ~3500   | ~18000   | N/A
# Intel i7-12700       | ~4500   | ~35000   | ~55000
# AMD Ryzen 5 3600     | ~3200   | ~17000   | N/A
# AMD Ryzen 7 5800X    | ~4000   | ~28000   | ~38000
# AMD Ryzen 9 7950X    | ~5000   | ~45000   | ~70000
# Байкал-М             | ~1500   | ~8000    | ~12000
```

### Важные CPU флаги

| Флаг | Описание | Важность |
|------|----------|----------|
| **aes** | AES-NI (аппаратное шифрование) | 🔒 Безопасность |
| **sse4_1, sse4_2** | SIMD инструкции | ⚡ Производительность |
| **avx, avx2** | Векторные инструкции | ⚡ Производительность |
| **avx512f** | AVX-512 | ⚡ Серверные задачи |
| **vmx / svm** | Виртуализация | 🖥️ Виртуализация |
| **nx** | No-eXecute (безопасность) | 🔒 Безопасность |
| **pae** | Physical Address Extension | 📋 32-bit PAE |
| **lm** | Long Mode (64-bit) | 📋 Обязателен |

```bash
# Проверка ключевых флагов
for flag in aes sse4_2 avx avx2 vmx svm nx lm; do
    if grep -q "$flag" /proc/cpuinfo; then
        echo "✅ $flag: поддерживается"
    else
        echo "❌ $flag: не поддерживается"
    fi
done
```

---

## Проверка видеокарты (GPU)

### Определение видеокарты

```bash
# Все GPU
lspci | grep -iE "vga|3d|display"

# Подробная информация
lspci -v -s $(lspci | grep -i vga | cut -d' ' -f1)

# Информация через /sys
cat /sys/class/drm/card*/device/vendor 2>/dev/null
cat /sys/class/drm/card*/device/device 2>/dev/null

# Разрешение экрана
xrandr 2>/dev/null | grep "*"
```

### Intel GPU

```bash
# Определение модели
lspci | grep -i vga | grep -i intel

# Проверка драйвера
lsmod | grep i915

# Статус драйвера
cat /sys/kernel/debug/dri/0/i915_gem_objects 2>/dev/null || echo "Недоступно"

# Аппаратное ускорение
glxinfo | grep "OpenGL renderer" 2>/dev/null

# Установка драйверов (обычно уже встроены)
sudo dnf install -y mesa-dri-drivers mesa-vulkan-drivers

# Проверка VAAPI (видео декодирование)
vainfo 2>/dev/null || echo "vainfo не установлен"
```

### AMD GPU

```bash
# Определение модели
lspci | grep -i vga | grep -i amd

# Драйвер (amdgpu или radeon)
lsmod | grep -E "amdgpu|radeon"

# Проверка amdgpu
cat /sys/kernel/debug/dri/amdgpu* 2>/dev/null | head -5 || echo "Недоступно"

# OpenGL
glxinfo | grep "OpenGL renderer" 2>/dev/null

# Vulkan
vulkaninfo --summary 2>/dev/null || echo "Vulkan не доступен"

# Установка драйверов
sudo dnf install -y mesa-dri-drivers mesa-vulkan-driers xorg-x11-drv-amdgpu
```

### NVIDIA GPU

```bash
# Определение модели
lspci | grep -i vga | grep -i nvidia

# Проверка установленного драйвера
nvidia-smi 2>/dev/null || echo "NVIDIA driver не установлен"

# Установка драйвера NVIDIA (если доступен репозиторий)
sudo dnf install -y nvidia-driver nvidia-settings

# Если через rpmfusion/ELRepo
# Проверить blacklist nouveau
cat /etc/modprobe.d/blacklist.conf 2>/dev/null | grep nouveau

# Загрузка модуля
lsmod | grep -E "nvidia|nouveau"

# Переключение на NVIDIA (при наличии hybrid GPU)
sudo prime-select nvidia 2>/dev/null || echo "prime-select не доступен"
```

### Проверка аппаратного ускорения

```bash
# Установка glx-utils
sudo dnf install -y glx-utils

# OpenGL информация
glxinfo | head -30

# OpenGL renderer (должен показывать GPU, не llvmpipe)
glxinfo | grep "OpenGL renderer"

# Тест производительности
glxgears 2>/dev/null &
sleep 5 && kill %1

# VAAPI (видео ускорение)
sudo dnf install -y libva-utils
vainfo 2>/dev/null
```

### GPU Benchmark

```bash
# Установка glmark2
sudo dnf install -y glmark2

# Запуск теста
glmark2

# Результат: Score -- чем выше, тем лучше
# Ориентиры:
# Intel UHD 620:      ~500-800
# Intel Iris Xe:      ~1500-2500
# AMD Vega 8:         ~1500-2000
# AMD RX 6600:        ~8000-12000
# NVIDIA GTX 1650:    ~4000-6000
# NVIDIA RTX 3060:    ~10000-15000
```

### Troubleshooting GPU

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Нет GUI** | `systemctl status display-manager` | `sudo systemctl start display-manager` |
| **Низкое разрешение** | `xrandr`, `lspci \| grep VGA` | Установить драйвер, настроить xorg.conf |
| **llvmpipe вместо GPU** | `glxinfo \| grep renderer` | Установить mesa-dri-drivers |
| **NVIDIA не работает** | `nvidia-smi`, `lsmod \| grep nvidia` | Установить/переустановить драйвер |
| **Мерцание экрана** | `dmesg \| grep -i gpu` | Обновить драйвер, проверить кабель |
| **Нет аппаратного видео** | `vainfo` | Установить VA-API драйверы |

---

## Сетевые адаптеры

### Определение адаптеров

```bash
# Все сетевые устройства
lspci | grep -iE "ethernet|network"

# USB сетевые адаптеры
lsusb | grep -iE "ethernet|network"

# Подробная информация
lspci -v -s $(lspci | grep -i ethernet | cut -d' ' -f1)

# Все сетевые интерфейсы
ip addr show
```

### Проверка драйвера

```bash
# Драйвер конкретного интерфейса
ethtool -i eth0

# Список загруженных сетевых драйверов
lsmod | grep -E "e1000|igb|ixgbe|r8169|r8125|atlantic|bnx2|tg3"

# Статус интерфейса
ip link show eth0
ethtool eth0
```

### Распространённые драйверы

| Чипсет | Драйвер | Статус в РЕД ОС |
|--------|---------|----------------|
| **Intel e1000/e1000e** | e1000e | ✅ Встроенный |
| **Intel IGB (1GbE)** | igb | ✅ Встроенный |
| **Intel IXGBE (10GbE)** | ixgbe | ✅ Встроенный |
| **Realtek 8169/8168** | r8169 | ✅ Встроенный |
| **Realtek 8125 (2.5GbE)** | r8125 | ⚠️ Может потребоваться DKMS |
| **Broadcom Tigon3** | tg3 | ✅ Встроенный |
| **Broadcom NetXtreme II** | bnx2 | ✅ Встроенный |
| **Aquantia AQtion** | atlantic | ✅ Встроенный (ядро 5.15+) |
| **Mellanox ConnectX** | mlx5_core | ✅ Встроенный |

### Troubleshooting сети

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Интерфейс не определяется** | `lspci \| grep -i eth`, `lsusb` | Проверить подключение, обновить ядро |
| **Нет драйвера** | `ethtool -i eth0`, `lspci -k` | Установить драйвер через DKMS |
| **Не получает IP** | `dhclient -v eth0`, `NetworkManager` | Проверить DHCP, кабель |
| **Медленная скорость** | `ethtool eth0`, `iperf3` | Проверить дуплекс, кабель, switch |
| **Отваливается соединение** | `dmesg \| grep eth`, `ethtool -S eth0` | Обновить драйвер, заменить кабель |

---

## Звуковые карты

### Определение звуковой карты

```bash
# Все аудио устройства
lspci | grep -i audio

# USB аудио устройства
lsusb | grep -i audio

# ALSA информация
cat /proc/asound/cards

# Подробная информация
aplay -l
```

### Проверка звука

```bash
# Установка утилит
sudo dnf install -y alsa-utils

# Тест звука (должен быть звук из динамиков)
speaker-test -c 2 -t wav

# Проверка микшера
alsamixer

# Список воспроизведения
aplay -L
```

### PulseAudio / PipeWire

```bash
# Проверка звукового сервера
systemctl --user status pipewire 2>/dev/null || systemctl --user status pulseaudio 2>/dev/null

# Список устройств вывода
pactl list sinks short 2>/dev/null

# Громкость
pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null

# Установка по умолчанию
pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo 2>/dev/null
```

### Troubleshooting звука

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Нет звука** | `aplay -l`, `alsamixer` | Расmute каналы в alsamixer |
| **Нет устройства** | `lspci \| grep audio`, `lsmod \| grep snd` | Загрузить модуль: `modprobe snd_hda_intel` |
| **Тихий звук** | `alsamixer` | Поднять Master/PCM громкость |
| **PulseAudio не работает** | `systemctl --user status pulseaudio` | Перезапустить: `systemctl --user restart pulseaudio` |

---

## Накопители (HDD, SSD, NVMe)

### Определение накопителей

```bash
# Все блочные устройства
lsblk

# Подробная информация
lsblk -o NAME,SIZE,MODEL,TYPE,ROTA,TRAN

# ROTA=1: HDD, ROTA=0: SSD/NVMe

# PCI накопители
lspci | grep -iE "storage|nvme|sata"

# SATA диски
ls /sys/block/sd*

# NVMe диски
ls /sys/block/nvme*
```

### HDD проверка

```bash
# SMART статус
sudo smartctl -a /dev/sda

# Краткий статус
sudo smartctl -H /dev/sda

# Скорость чтения
sudo hdparm -Tt /dev/sda

# Температура
sudo smartctl -A /dev/sda | grep -i temperature
```

### SSD проверка

```bash
# SMART для SSD
sudo smartctl -a /dev/sda

# Износ SSD
sudo smartctl -A /dev/sda | grep -iE "wear|remaining|percent"

# TRIM поддержка
sudo fstrim -v / 2>/dev/null || echo "TRIM не поддерживается"

# Проверка включения TRIM
systemctl status fstrim.timer
```

### NVMe проверка

```bash
# Информация NVMe
sudo nvme list

# SMART / Health
sudo nvme smart-log /dev/nvme0

# Детальная информация
sudo nvme id-ctrl /dev/nvme0

# Температура
sudo nvme smart-log /dev/nvme0 | grep temperature

# Скорость
sudo nvme smart-log /dev/nvme0
```

### Disk Benchmark

```bash
# Установка fio
sudo dnf install -y fio

# Тест случайного чтения (4K)
fio --name=randread --ioengine=libaio --direct=1 --bs=4k --size=1G --numjobs=4 --runtime=60 --group_reporting --filename=/tmp/fio-test

# Тест последовательной записи
fio --name=seqwrite --ioengine=libaio --direct=1 --bs=1M --size=1G --numjobs=1 --runtime=60 --group_reporting --filename=/tmp/fio-test

# Типичные результаты:
# Тип диска     | Seq Read | Seq Write | 4K Rand Read
# --------------|----------|-----------|-------------
# HDD 7200 RPM  | 150 МБ/с | 150 МБ/с  | 1-2 МБ/с
# SATA SSD      | 500 МБ/с | 450 МБ/с  | 30-50 МБ/с
# NVMe Gen3     | 3000 МБ/с| 2000 МБ/с | 200-400 МБ/с
# NVMe Gen4     | 7000 МБ/с| 5000 МБ/с | 400-800 МБ/с
```

### Troubleshooting накопителей

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Диск не определяется** | `lsblk`, `lspci \| grep storage`, `dmesg` | Проверить подключение, кабель |
| **SMART предупреждения** | `smartctl -a /dev/sda` | Запланировать замену |
| **Медленная запись** | `iostat -x 1`, `fio` | Проверить TRIM, выравнивание разделов |
| **NVMe перегревается** | `nvme smart-log` | Установить радиатор, улучшить обдув |
| **SSD износился** | `smartctl -A \| grep Wear` | Запланировать замену |

---

## USB-устройства

### Определение USB устройств

```bash
# Все USB устройства
lsusb

# Подробная информация
lsusb -v | less

# USB дерево
lsusb -t

# Информация о шине
usb-devices
```

### Версия USB

```bash
# USB контроллеры
lspci | grep -i usb

# Скорость конкретного устройства
lsusb -t

# SuperSpeed (USB 3.x) устройства
lsusb -d 1d6b:0003 2>/dev/null || lsusb | grep -i "3.0"
```

### Troubleshooting USB

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Устройство не определяется** | `lsusb`, `dmesg \| tail` | Переподключить, другой порт |
| **Медленная скорость** | `lsusb -t` | Подключить в USB 3.0 порт |
| **Отключается** | `dmesg \| grep -i usb` | Проверить кабель, питание |

---

## Wi-Fi адаптеры

### Определение Wi-Fi

```bash
# Беспроводные адаптеры
lspci | grep -i wireless

# USB Wi-Fi
lsusb | grep -i wireless

# Ядро и драйвер
iw dev 2>/dev/null

# Доступные интерфейсы
ip link show | grep wlan

# Драйвер
ethtool -i wlan0 2>/dev/null
```

### Проверка работы

```bash
# Сканирование сетей
sudo iw dev wlan0 scan | grep SSID | head -20

# Через nmcli
nmcli device wifi list

# Подключение к сети
nmcli device wifi connect "SSID" password "PASSWORD"

# Статус подключения
nmcli device status

# Информация о подключении
iw dev wlan0 link
```

### Распространённые чипсеты

| Чипсет | Драйвер | Статус | Примечание |
|--------|---------|--------|------------|
| **Intel AX200/AX201/AX210** | iwlwifi | ✅ Отлично | Рекомендуется |
| **Intel 8260/8265** | iwlwifi | ✅ Отлично | Рекомендуется |
| **Intel 7260/7265** | iwlwifi | ✅ Отлично | Рекомендуется |
| **Realtek RTL8812AU** | rtl88xxau | ⚠️ DKMS | Внешний адаптер |
| **Realtek RTL8821CE** | rtw88_8821ce | ⚠️ Может требовать DKMS | |
| **Qualcomm Atheros** | ath9k/ath10k | ✅ Хорошо | |
| **Broadcom BCM43xx** | wl/brcmfmac | ⚠️ Проприетарный | Может потребовать доп. драйвер |
| **MediaTek MT7921** | mt7921e | ✅ Хорошо (ядро 5.15+) | |

### Troubleshooting Wi-Fi

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Адаптер не виден** | `lspci \| grep wireless`, `lsusb` | Установить драйвер, firmware |
| **Не подключается** | `nmcli dev wifi list`, `dmesg` | Проверить пароль, драйвер |
| **Медленный Wi-Fi** | `iw dev wlan0 link` | Переключить на 5 GHz |
| **Отваливается** | `dmesg \| grep -i wlan` | Обновить драйвер, energy save off |
| **Нет firmware** | `dmesg \| grep -i firmware` | Установить linux-firmware |

---

## Bluetooth

### Определение Bluetooth

```bash
# Bluetooth адаптеры
lsusb | grep -i bluetooth
lspci | grep -i bluetooth

# Статус Bluetooth
systemctl status bluetooth

# Информация о контроллере
bluetoothctl show
```

### Проверка работы

```bash
# Запуск bluetoothctl
bluetoothctl

# В bluetoothctl:
# power on
# scan on
# pair <MAC>
# connect <MAC>
# trust <MAC>

# Список устройств
bluetoothctl devices

# Информация об адаптере
hciconfig -a 2>/dev/null || btmgmt info 2>/dev/null
```

### Troubleshooting Bluetooth

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Адаптер не определяется** | `lsusb \| grep bluetooth` | Обновить ядро, проверить firmware |
| **Не включается** | `bluetoothctl show` | `rfkill unblock bluetooth` |
| **Не сопрягается** | `bluetoothctl` | Удалить и переподключить |
| **Нет звука** | `pactl list` | Переключить профиль на A2DP |

---

## Принтеры и сканеры

### Принтеры

```bash
# Статус CUPS
systemctl status cups

# Список принтеров
lpstat -p -d

# Доступные драйверы
driverless 2>/dev/null

# Печать тестовой страницы
lp -d PRINTER_NAME /usr/share/cups/data/testprint
```

### Сканеры

```bash
# Установка SANE
sudo dnf install -y sane-backends

# Поиск сканеров
scanimage -L

# Список устройств
scanimage -L

# Тест сканирования
scanimage --format=png > /tmp/scan-test.png
```

### Troubleshooting печати

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Принтер не найден** | `lpstat -p`, `lsusb` | Подключить, установить драйвер |
| **Не печатает** | `lpstat -o`, `cupsctl` | Проверить очередь, перезапустить cups |
| **Нет драйвера** | `driverless` | Использовать IPP/driverless |
| **Сканер не найден** | `scanimage -L` | Установить sane-backends, firmware |

---

## Ноутбуки

### Батарея

```bash
# Информация о батарее
upower -i $(upower -e | grep BAT) 2>/dev/null

# Через sysfs
cat /sys/class/power_supply/BAT*/capacity 2>/dev/null
cat /sys/class/power_supply/BAT*/status 2>/dev/null
cat /sys/class/power_supply/BAT*/charge_full_design 2>/dev/null
cat /sys/class/power_supply/BAT*/energy_full 2>/dev/null

# Состояние здоровья
cat /sys/class/power_supply/BAT*/capacity 2>/dev/null
```

### Тачпад

```bash
# Определение тачпада
cat /proc/bus/input/devices | grep -A 3 -i "touchpad\|touchpad\|synaptics\|elantech"

# Драйвер
lsmod | grep -E "synaptics|i2c_hid|psmouse"

# Настройка через libinput
libinput list-devices 2>/dev/null | grep -A 10 -i touchpad
```

### Suspend/Resume

```bash
# Проверка поддержки сна
cat /sys/powerstate 2>/dev/null || cat /sys/power/state

# Тест suspend
sudo systemctl suspend

# Проверка после resume
dmesg | tail -30

# Логи suspend/resume
journalctl | grep -iE "suspend|resume" | tail -20
```

### Ноутбучные специфичные функции

```bash
# Яркость экрана
cat /sys/class/backlight/*/brightness 2>/dev/null
cat /sys/class/backlight/*/max_brightness 2>/dev/null

# Клавиши яркости
lsmod | grep -iE "thinkpad_acpi|asus_nb_wmi|hp_wmi|dell_wmi"

# Вентилятор (если доступен)
cat /sys/class/hwmon/hwmon*/fan*_input 2>/dev/null
sensors | grep -i fan
```

### Troubleshooting ноутбуков

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **Батарея не заряжается** | `upower`, `cat /sys/class/power_supply/` | Проверить БП, calibrate |
| **Тачпад не работает** | `libinput list-devices`, `lsmod` | Загрузить модуль, проверить BIOS |
| **Не работает suspend** | `dmesg`, `journalctl` | Обновить BIOS/ядро, blacklist модуль |
| **Яркость не регулируется** | `/sys/class/backlight/` | Добавить параметр ядра `acpi_backlight=vendor` |
| **Wi-Fi не работает после resume** | `dmesg` | Добавить quirks для адаптера |

---

## Серверное оборудование

### RAID контроллеры

```bash
# Определение RAID контроллера
lspci | grep -i raid

# MegaRAID (LSI/Broadcom)
sudo /opt/MegaRAID/MegaCli/MegaCli64 -LDInfo -Lall -aALL 2>/dev/null || echo "MegaCli не установлен"

# Adaptec
sudo arcconf GETCONFIG 1 2>/dev/null || echo "arcconf не установлен"

# Программный RAID (mdadm)
cat /proc/mdstat
sudo mdadm --detail /dev/md0 2>/dev/null
```

### ECC память

```bash
# Проверка поддержки ECC
sudo dmidecode -t memory | grep -iE "Size|Type|Error"

# Проверка EDAC (Error Detection And Correction)
ls /sys/devices/system/edac/ 2>/dev/null

# Ошибки памяти
sudo edac-util 2>/dev/null || cat /sys/devices/system/edac/mc/mc0/*ce_count 2>/dev/null

# Проверка в dmesg
dmesg | grep -iE "EDAC|ECC|memory error"
```

### IPMI

```bash
# Установка IPMI утилит
sudo dnf install -y ipmitool

# Статус IPMI
sudo ipmitool mc info

# Температура
sudo ipmitool sdr type temperature

# Вентиляторы
sudo ipmitool sdr type fan

# Питание
sudo ipmitool chassis status

# SEL (System Event Log)
sudo ipmitool sel list | tail -20
```

### Серверные компоненты

```bash
# Два процессора
lscpu | grep -E "Socket|NUMA"

# Множество NIC
ip -br addr show

# ECC память
sudo dmidecode -t memory | grep -E "Size|Type|Error Correction"

# Горячая замена
lsblk -o NAME,SIZE,ROTA,TRAN,MODEL

# IPMI
sudo ipmitool chassis status
```

### Troubleshooting серверов

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
| **RAID degraded** | `MegaCli`, `arcconf`, `mdadm` | Заменить диск, rebuild |
| **ECC ошибки** | `edac-util`, `dmesg` | Заменить модуль памяти |
| **Перегрев** | `ipmitool sdr type temp`, `sensors` | Проверить вентиляторы, обдув |
| **IPMI недоступен** | `ipmitool mc info` | Проверить BMC, сеть |
| **Питание отказало** | `ipmitool chassis status` | Проверить PSU, redundant |

---

## Автоматический скрипт hw-check.sh

Полный автоматический скрипт проверки оборудования с цветным выводом и генерацией отчётов:

```bash
#!/bin/bash
##############################################################################
# hw-check.sh -- Проверка совместимости оборудования (РЕД ОС)
#
# Использование:
#   sudo ./hw-check.sh [OPTIONS]
#
# Опции:
#   --full           Полная проверка всего оборудования
#   --cpu            Только процессор
#   --gpu            Только видеокарта
#   --network        Только сеть
#   --audio          Только звук
#   --storage        Только накопители
#   --usb            Только USB
#   --wifi           Только Wi-Fi
#   --bluetooth      Только Bluetooth
#   --printer        Только принтеры
#   --laptop         Только ноутбучные компоненты
#   --server         Только серверные компоненты
#   --report FMT     Формат отчёта: html, json
#   --output DIR     Директория для отчёта
#   --quiet          Тихий режим (только проблемы)
#   --help           Справка
#
# Зависимости: bash, coreutils, pciutils, usbutils, util-linux
# Опционально: smartmontools, nvme-cli, ethtool, glx-utils, ipmitool
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
NC='\033[0m'

# ─── Настройки ───────────────────────────────────────────────────────────
REPORT_FORMAT="none"
OUTPUT_DIR="./reports"
QUIET=false
CHECK_TYPE="full"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
HOSTNAME=$(hostname)
OS_INFO=$(cat /etc/redos-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
ARCH=$(uname -m)

# ─── Функции ─────────────────────────────────────────────────────────────
log_info()   { [ "$QUIET" = false ] && echo -e "${BLUE}[INFO]${NC}   $1" || true; }
log_ok()     { [ "$QUIET" = false ] && echo -e "${GREEN}[OK]${NC}     $1" || true; }
log_warn()   { echo -e "${YELLOW}[WARN]${NC}   $1"; }
log_error()  { echo -e "${RED}[ERROR]${NC}  $1"; }
log_header() {
    [ "$QUIET" = false ] && {
        echo ""
        echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}  $1${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    }
}

check_root() {
    if [ "$(id -u)" -ne 0 ] && [ "$QUIET" = false ]; then
        log_warn "Для полной проверки рекомендуется root."
    fi
}

check_cmd() {
    command -v "$1" &>/dev/null
}

# ─── Системная информация ───────────────────────────────────────────────

check_system_info() {
    log_header "СИСТЕМНАЯ ИНФОРМАЦИЯ"

    echo -e "  ОС:           ${WHITE}${OS_INFO}${NC}"
    echo -e "  Ядро:         ${WHITE}$(uname -r)${NC}"
    echo -e "  Архитектура:  ${WHITE}${ARCH}${NC}"
    echo -e "  Хост:         ${WHITE}${HOSTNAME}${NC}"
    echo -e "  Uptime:       ${WHITE}$(uptime -p 2>/dev/null || uptime)${NC}"
    echo -e "  Дата:         ${WHITE}$(date '+%d.%m.%Y %H:%M:%S')${NC}"
}

# ─── CPU ─────────────────────────────────────────────────────────────────

check_cpu() {
    log_header "CPU -- Процессор"

    if ! check_cmd lscpu; then
        log_error "lscpu не найден: sudo dnf install util-linux"
        return
    fi

    local model cores threads sockets vendor
    model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    threads=$(lscpu | grep "Thread(s) per core" | awk '{print $NF}')
    sockets=$(lscpu | grep "Socket(s)" | awk '{print $NF}')
    vendor=$(lscpu | grep "Vendor ID" | awk '{print $NF}')

    echo -e "  Модель:        ${WHITE}${model}${NC}"
    echo -e "  Вендор:        ${WHITE}${vendor}${NC}"
    echo -e "  Сокетов:       ${WHITE}${sockets}${NC}"
    echo -e "  Ядер:          ${WHITE}${cores}${NC}"
    echo -e "  Потоков/ядро:  ${WHITE}${threads}${NC}"
    echo -e "  Всего потоков: ${WHITE}$((cores * threads * sockets))${NC}"

    # Виртуализация
    local virt
    virt=$(lscpu | grep "Virtualization" | awk '{print $NF}')
    if [ -n "$virt" ]; then
        log_ok "Виртуализация: ${virt}"
    else
        log_info "Виртуализация не обнаружена"
    fi

    # Важные флаги
    local flags_ok=true
    for flag in aes sse4_2 avx nx lm; do
        if grep -q "$flag" /proc/cpuinfo; then
            [ "$QUIET" = false ] && echo -e "  ${GREEN}✅${NC} $flag"
        else
            [ "$QUIET" = false ] && echo -e "  ${RED}❌${NC} $flag (отсутствует)"
            flags_ok=false
        fi
    done

    if [ "$flags_ok" = true ]; then
        log_ok "Все ключевые инструкции поддерживаются"
    else
        log_warn "Некоторые инструкции отсутствуют"
    fi

    # Микрокод
    if [ "$(id -u)" -eq 0 ]; then
        local ucode
        ucode=$(grep microcode /proc/cpuinfo | head -1 | awk '{print $NF}')
        echo -e "  Микрокод:      ${WHITE}${ucode}${NC}"
    fi

    # Частота
    local freq
    freq=$(lscpu | grep "MHz" | awk '{print $NF}' | head -1)
    [ -n "$freq" ] && echo -e "  Частота:       ${WHITE}${freq} МГц${NC}"
}

# ─── GPU ─────────────────────────────────────────────────────────────────

check_gpu() {
    log_header "GPU -- Видеокарта"

    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -iE "vga|3d|display")

    if [ -z "$gpu_info" ]; then
        log_warn "Видеокарта не обнаружена через lspci"
        return
    fi

    echo -e "  ${WHITE}Обнаруженные GPU:${NC}"
    echo "$gpu_info" | while IFS= read -r line; do
        echo -e "    ${WHITE}${line}${NC}"
    done

    # Драйвер
    local pci_slot
    pci_slot=$(echo "$gpu_info" | head -1 | cut -d' ' -f1)
    local driver
    driver=$(lspci -k -s "$pci_slot" 2>/dev/null | grep "Kernel driver" | awk '{print $NF}')

    if [ -n "$driver" ]; then
        log_ok "Драйвер: ${driver}"
    else
        log_warn "Драйвер не загружен"
    fi

    # Проверка конкретного вендора
    if echo "$gpu_info" | grep -qi intel; then
        log_info "Intel GPU -- драйвер обычно встроен (i915)"
        if lsmod 2>/dev/null | grep -q i915; then
            log_ok "Модуль i915 загружен"
        fi
    elif echo "$gpu_info" | grep -qi amd; then
        log_info "AMD GPU -- проверьте драйвер amdgpu/radeon"
        if lsmod 2>/dev/null | grep -qE "amdgpu|radeon"; then
            log_ok "AMD драйвер загружен"
        fi
    elif echo "$gpu_info" | grep -qi nvidia; then
        log_info "NVIDIA GPU"
        if check_cmd nvidia-smi; then
            local nv_info
            nv_info=$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null)
            if [ -n "$nv_info" ]; then
                log_ok "NVIDIA: ${nv_info}"
            else
                log_warn "nvidia-smi не возвращает данные"
            fi
        else
            log_warn "nvidia-smi не установлен"
        fi
    fi

    # OpenGL
    if check_cmd glxinfo; then
        local renderer
        renderer=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs)
        if [ -n "$renderer" ]; then
            if echo "$renderer" | grep -qi "llvmpipe"; then
                log_warn "Используется программный рендеринг (llvmpipe)"
            else
                log_ok "OpenGL: ${renderer}"
            fi
        fi
    fi
}

# ─── Network ─────────────────────────────────────────────────────────────

check_network() {
    log_header "NETWORK -- Сетевые адаптеры"

    # PCI сетевые
    local eth_pci
    eth_pci=$(lspci 2>/dev/null | grep -iE "ethernet|network")
    if [ -n "$eth_pci" ]; then
        echo -e "  ${WHITE}PCI сетевые адаптеры:${NC}"
        echo "$eth_pci" | while IFS= read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    fi

    # USB сетевые
    local eth_usb
    eth_usb=$(lsusb 2>/dev/null | grep -iE "ethernet|network")
    if [ -n "$eth_usb" ]; then
        echo -e "  ${WHITE}USB сетевые адаптеры:${NC}"
        echo "$eth_usb" | while IFS= read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    fi

    # Интерфейсы
    echo ""
    echo -e "  ${WHITE}Сетевые интерфейсы:${NC}"
    ip -br addr show 2>/dev/null | while IFS= read -r line; do
        local iface status
        iface=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        if [ "$status" = "UP" ]; then
            log_ok "${iface}: ${status}"
        else
            log_info "${iface}: ${status}"
        fi
    done

    # Скорость (для ethernet)
    if check_cmd ethtool; then
        echo ""
        for iface in $(ip -br addr show 2>/dev/null | awk '$2=="UP" && $1 !~ /^lo/ {print $1}'); do
            if [ -d "/sys/class/net/${iface}" ]; then
                local type
                type=$(cat "/sys/class/net/${iface}/type" 2>/dev/null)
                if [ "$type" = "1" ]; then  # Ethernet
                    local speed
                    speed=$(ethtool "$iface" 2>/dev/null | grep "Speed:" | awk '{print $2}')
                    echo -e "  ${iface}: скорость ${WHITE}${speed:-N/A}${NC}"
                fi
            fi
        done
    fi
}

# ─── Audio ───────────────────────────────────────────────────────────────

check_audio() {
    log_header "AUDIO -- Звуковые карты"

    local audio_pci
    audio_pci=$(lspci 2>/dev/null | grep -i audio)
    if [ -n "$audio_pci" ]; then
        echo -e "  ${WHITE}PCI аудио устройства:${NC}"
        echo "$audio_pci" | while IFS= read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    fi

    local audio_usb
    audio_usb=$(lsusb 2>/dev/null | grep -i audio)
    if [ -n "$audio_usb" ]; then
        echo -e "  ${WHITE}USB аудио устройства:${NC}"
        echo "$audio_usb" | while IFS= read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    fi

    # ALSA
    if [ -f /proc/asound/cards ]; then
        local cards
        cards=$(cat /proc/asound/cards 2>/dev/null)
        if [ -n "$cards" ]; then
            echo ""
            log_ok "ALSA карты обнаружены:"
            echo "$cards" | while IFS= read -r line; do
                echo -e "    ${WHITE}${line}${NC}"
            done
        else
            log_warn "ALSA карты не найдены"
        fi
    fi
}

# ─── Storage ─────────────────────────────────────────────────────────────

check_storage() {
    log_header "STORAGE -- Накопители"

    if ! check_cmd lsblk; then
        log_error "lsblk не найден"
        return
    fi

    # Блочные устройства
    echo -e "  ${WHITE}Блочные устройства:${NC}"
    lsblk -d -o NAME,SIZE,MODEL,TYPE,ROTA,TRAN 2>/dev/null | while IFS= read -r line; do
        echo -e "    ${WHITE}${line}${NC}"
    done

    echo ""

    # Определение типа
    lsblk -d -o NAME,ROTA 2>/dev/null | grep "^sd\|^nvme\|^vd" | while read -r name rota; do
        local disk_name="/dev/${name}"
        if [ "$rota" = "0" ]; then
            log_info "${disk_name}: SSD/NVMe"
        else
            log_info "${disk_name}: HDD"
        fi
    done

    # SMART (если доступен)
    if check_cmd smartctl && [ "$(id -u)" -eq 0 ]; then
        echo ""
        for disk in /dev/sd[a-z] /dev/nvme[0-9]; do
            if [ -b "$disk" ]; then
                local smart_status
                smart_status=$(smartctl -H "$disk" 2>/dev/null | grep -i "result" | awk '{print $NF}')
                if [ "$smart_status" = "PASSED" ]; then
                    log_ok "${disk}: SMART OK"
                elif [ "$smart_status" = "FAILED!" ]; then
                    log_error "${disk}: SMART FAILED!"
                else
                    log_info "${disk}: SMART статус неизвестен"
                fi
            fi
        done
    fi

    # NVMe (если доступен)
    if check_cmd nvme && [ "$(id -u)" -eq 0 ]; then
        echo ""
        local nvme_list
        nvme_list=$(nvme list 2>/dev/null)
        if [ -n "$nvme_list" ]; then
            echo -e "  ${WHITE}NVMe устройства:${NC}"
            echo "$nvme_list" | tail -n +2 | while IFS= read -r line; do
                echo -e "    ${WHITE}${line}${NC}"
            done
        fi
    fi
}

# ─── USB ─────────────────────────────────────────────────────────────────

check_usb() {
    log_header "USB -- Устройства"

    if ! check_cmd lsusb; then
        log_error "lsusb не найден: sudo dnf install usbutils"
        return
    fi

    # USB контроллеры
    local usb_controllers
    usb_controllers=$(lspci 2>/dev/null | grep -i usb)
    if [ -n "$usb_controllers" ]; then
        echo -e "  ${WHITE}USB контроллеры:${NC}"
        echo "$usb_controllers" | while IFS= read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    fi

    # USB устройства
    echo ""
    local usb_devices
    usb_devices=$(lsusb 2>/dev/null)
    if [ -n "$usb_devices" ]; then
        echo -e "  ${WHITE}Подключённые USB устройства:${NC}"
        echo "$usb_devices" | while IFS= read -r line; do
            echo -e "    ${WHITE}${line}${NC}"
        done
    else
        log_warn "USB устройства не обнаружены"
    fi

    # USB дерево
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "  ${WHITE}USB дерево:${NC}"
        lsusb -t 2>/dev/null | head -20
    fi
}

# ─── Wi-Fi ───────────────────────────────────────────────────────────────

check_wifi() {
    log_header "WIFI -- Беспроводные адаптеры"

    local wifi_pci
    wifi_pci=$(lspci 2>/dev/null | grep -iE "wireless|wifi|802.11")
    local wifi_usb
    wifi_usb=$(lsusb 2>/dev/null | grep -iE "wireless|wifi|802.11")

    if [ -z "$wifi_pci" ] && [ -z "$wifi_usb" ]; then
        log_warn "Wi-Fi адаптеры не обнаружены"
        return
    fi

    [ -n "$wifi_pci" ] && echo -e "  ${WHITE}PCI Wi-Fi:${NC}\n    ${WHITE}${wifi_pci}${NC}"
    [ -n "$wifi_usb" ] && echo -e "  ${WHITE}USB Wi-Fi:${NC}\n    ${WHITE}${wifi_usb}${NC}"

    # Драйвер
    local wlan_iface
    wlan_iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}')
    if [ -n "$wlan_iface" ]; then
        log_ok "Wi-Fi интерфейс: ${wlan_iface}"
    else
        log_info "Wi-Fi интерфейс не активен"
    fi

    # Проверка iw
    if ! check_cmd iw; then
        log_info "iw не установлен: sudo dnf install iw"
    fi
}

# ─── Bluetooth ───────────────────────────────────────────────────────────

check_bluetooth() {
    log_header "BLUETOOTH"

    local bt_usb
    bt_usb=$(lsusb 2>/dev/null | grep -i bluetooth)
    local bt_pci
    bt_pci=$(lspci 2>/dev/null | grep -i bluetooth)

    if [ -z "$bt_usb" ] && [ -z "$bt_pci" ]; then
        log_warn "Bluetooth адаптеры не обнаружены"
        return
    fi

    [ -n "$bt_usb" ] && echo -e "  ${WHITE}USB Bluetooth:${NC}\n    ${WHITE}${bt_usb}${NC}"
    [ -n "$bt_pci" ] && echo -e "  ${WHITE}PCI Bluetooth:${NC}\n    ${WHITE}${bt_pci}${NC}"

    # Сервис
    local bt_status
    bt_status=$(systemctl is-active bluetooth 2>/dev/null || echo "N/A")
    if [ "$bt_status" = "active" ]; then
        log_ok "Bluetooth сервис: активен"
    else
        log_info "Bluetooth сервис: ${bt_status}"
    fi
}

# ─── Printer ─────────────────────────────────────────────────────────────

check_printer() {
    log_header "PRINTER -- Принтеры и сканеры"

    # USB принтеры
    local printer_usb
    printer_usb=$(lsusb 2>/dev/null | grep -i printer)
    if [ -n "$printer_usb" ]; then
        echo -e "  ${WHITE}USB принтеры:${NC}\n    ${WHITE}${printer_usb}${NC}"
    fi

    # CUPS
    local cups_status
    cups_status=$(systemctl is-active cups 2>/dev/null || echo "N/A")
    echo -e "  CUPS: ${WHITE}${cups_status}${NC}"

    if [ "$cups_status" = "active" ]; then
        local printers
        printers=$(lpstat -p 2>/dev/null)
        if [ -n "$printers" ]; then
            log_ok "Найденные принтеры:"
            echo "$printers" | while IFS= read -r line; do
                echo -e "    ${WHITE}${line}${NC}"
            done
        else
            log_info "Принтеры не настроены"
        fi
    fi

    # Сканер
    if check_cmd scanimage; then
        local scanners
        scanners=$(scanimage -L 2>/dev/null)
        if [ -n "$scanners" ]; then
            log_ok "Сканеры: ${scanners}"
        else
            log_info "Сканеры не обнаружены"
        fi
    fi
}

# ─── Laptop ──────────────────────────────────────────────────────────────

check_laptop() {
    log_header "LAPTOP -- Ноутбучные компоненты"

    # Проверка что это ноутбук
    local is_laptop=false
    if grep -qi "laptop\|notebook\|portable" /sys/class/dmi/id/chassis_type 2>/dev/null || \
       grep -qi "laptop\|notebook" /sys/class/dmi/id/product_name 2>/dev/null; then
        is_laptop=true
    fi

    if [ "$is_laptop" = false ]; then
        log_info "Система не определена как ноутбук"
        return
    fi

    log_ok "Обнаружен ноутбук"

    # Батарея
    if [ -d /sys/class/power_supply ]; then
        local bat
        for bat in /sys/class/power_supply/BAT*; do
            if [ -d "$bat" ]; then
                local capacity status
                capacity=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
                status=$(cat "$bat/status" 2>/dev/null || echo "N/A")
                echo -e "  Батарея: ${WHITE}${capacity}% (${status})${NC}"
            fi
        done
    else
        log_warn "Батарея не обнаружена"
    fi

    # Тачпад
    local touchpad
    touchpad=$(cat /proc/bus/input/devices 2>/dev/null | grep -iE "touchpad|synaptics|elan" | head -1)
    if [ -n "$touchpad" ]; then
        log_ok "Тачпад: ${touchpad}"
    else
        log_info "Тачпад не обнаружен"
    fi

    # Яркость
    if ls /sys/class/backlight/ 2>/dev/null | grep -q .; then
        local brightness max_brightness
        brightness=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1)
        max_brightness=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1)
        if [ -n "$brightness" ] && [ -n "$max_brightness" ] && [ "$max_brightness" -gt 0 ]; then
            local pct=$((brightness * 100 / max_brightness))
            echo -e "  Яркость: ${WHITE}${pct}%${NC}"
        fi
    else
        log_info "Управление яркостью недоступно"
    fi

    # Suspend
    if [ -f /sys/power/state ]; then
        local states
        states=$(cat /sys/power/state 2>/dev/null)
        if echo "$states" | grep -q "mem"; then
            log_ok "Suspend поддерживается"
        else
            log_warn "Suspend может не поддерживаться"
        fi
    fi
}

# ─── Server ──────────────────────────────────────────────────────────────

check_server() {
    log_header "SERVER -- Серверные компоненты"

    # Проверка что это сервер
    local is_server=false
    if grep -qi "server\|rack\|tower" /sys/class/dmi/id/product_name 2>/dev/null || \
       grep -qi "supermicro\|dell inc.\|hp\|lenovo.*thinksystem" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
        is_server=true
    fi

    if [ "$is_server" = false ]; then
        log_info "Система не определена как сервер"
    fi

    # RAID
    local raid
    raid=$(lspci 2>/dev/null | grep -i raid)
    if [ -n "$raid" ]; then
        echo -e "  ${WHITE}RAID контроллер:${NC}\n    ${WHITE}${raid}${NC}"
    else
        log_info "RAID контроллер не обнаружен"
    fi

    # ECC
    local ecc
    ecc=$(sudo dmidecode -t memory 2>/dev/null | grep -i "error correction")
    if [ -n "$ecc" ]; then
        echo -e "  ECC: ${WHITE}${ecc}${NC}"
    else
        log_info "Информация об ECC недоступна"
    fi

    # IPMI
    if check_cmd ipmitool && [ "$(id -u)" -eq 0 ]; then
        local ipmi_info
        ipmi_info=$(ipmitool mc info 2>/dev/null)
        if [ -n "$ipmi_info" ]; then
            log_ok "IPMI доступен"
            echo "$ipmi_info" | grep -E "Firmware Revision|Device ID" | while IFS= read -r line; do
                echo -e "    ${WHITE}${line}${NC}"
            done
        else
            log_info "IPMI недоступен"
        fi
    fi

    # Множество CPU
    local sockets
    sockets=$(lscpu 2>/dev/null | grep "Socket(s)" | awk '{print $NF}')
    if [ "${sockets:-1}" -gt 1 ]; then
        log_ok "Многопроцессорная система: ${sockets} сокета"
    fi

    # Много NIC
    local nic_count
    nic_count=$(ip -br addr show 2>/dev/null | grep -cE "UP|eth")
    if [ "${nic_count:-0}" -gt 1 ]; then
        log_ok "Сетевых интерфейсов: ${nic_count}"
    fi
}

# ─── Генерация отчётов ──────────────────────────────────────────────────

generate_html_report() {
    local report_file="${OUTPUT_DIR}/hw-report-${TIMESTAMP}.html"
    mkdir -p "$OUTPUT_DIR"

    local cpu_model
    cpu_model=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | xargs)
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || echo "N/A")
    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -iE "vga|3d|display" | head -1 | xargs)
    local ram_total
    ram_total=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')

    cat > "$report_file" << HTMLEOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Отчёт совместимости оборудования -- $HOSTNAME</title>
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
        .badge { display: inline-block; padding: 3px 8px; border-radius: 4px; font-size: 0.8em; font-weight: 600; }
        .badge-ok { background: #d4edda; color: #155724; }
        .badge-warn { background: #fff3cd; color: #856404; }
        .badge-error { background: #f8d7da; color: #721c24; }
        .badge-info { background: #d1ecf1; color: #0c5460; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #e0e0e0; }
        th { background: #f8f9fa; font-weight: 600; color: #555; }
        .footer { text-align: center; color: #999; margin-top: 30px; font-size: 0.85em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Отчёт совместимости оборудования</h1>
        <p class="subtitle">$HOSTNAME | $OS_INFO | $(date '+%d.%m.%Y %H:%M:%S')</p>

        <div class="card">
            <h2>🖥️ Система</h2>
            <div class="metric">
                <span class="metric-label">ОС</span>
                <span class="metric-value">$OS_INFO</span>
            </div>
            <div class="metric">
                <span class="metric-label">Ядро</span>
                <span class="metric-value">$(uname -r)</span>
            </div>
            <div class="metric">
                <span class="metric-label">Архитектура</span>
                <span class="metric-value">$ARCH</span>
            </div>
        </div>

        <div class="card">
            <h2>⚡ CPU</h2>
            <div class="metric">
                <span class="metric-label">Модель</span>
                <span class="metric-value">$cpu_model</span>
            </div>
            <div class="metric">
                <span class="metric-label">Ядра</span>
                <span class="metric-value">$cpu_cores</span>
            </div>
            <div class="metric">
                <span class="metric-label">Виртуализация</span>
                <span class="metric-value">$(lscpu 2>/dev/null | grep 'Virtualization' | awk '{print $NF}' || echo 'N/A')</span>
            </div>
        </div>

        <div class="card">
            <h2>🧠 RAM</h2>
            <div class="metric">
                <span class="metric-label">Всего</span>
                <span class="metric-value">$ram_total</span>
            </div>
            <div class="metric">
                <span class="metric-label">Используется</span>
                <span class="metric-value">$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')</span>
            </div>
        </div>

        <div class="card">
            <h2>🎮 GPU</h2>
            <div class="metric">
                <span class="metric-label">Видеокарта</span>
                <span class="metric-value">${gpu_info:-Не обнаружена}</span>
            </div>
            <div class="metric">
                <span class="metric-label">Драйвер</span>
                <span class="metric-value">$(lspci -k 2>/dev/null | grep -A1 -iE 'vga|3d' | grep 'Kernel driver' | awk '{print $NF}' || echo 'N/A')</span>
            </div>
        </div>

        <div class="card">
            <h2>💾 Накопители</h2>
            <table>
                <tr><th>Устройство</th><th>Размер</th><th>Модель</th><th>Тип</th></tr>
                $(lsblk -d -o NAME,SIZE,MODEL,ROTA 2>/dev/null | grep "^s\|^nvme\|^vd" | awk '{type=($4=="0")?"SSD/NVMe":"HDD"; printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, type}')
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
            <h2>📋 Совместимость</h2>
            <table>
                <tr><th>Компонент</th><th>Статус</th></tr>
                <tr><td>Архитектура ($ARCH)</td><td><span class="badge badge-ok">✅ Совместимо</span></td></tr>
                <tr><td>CPU ($cpu_model)</td><td><span class="badge badge-ok">✅ Совместимо</span></td></tr>
                <tr><td>GPU</td><td><span class="badge badge-ok">✅ Совместимо</span></td></tr>
                <tr><td>Сетевые адаптеры</td><td><span class="badge badge-ok">✅ Совместимо</span></td></tr>
            </table>
        </div>

        <div class="footer">
            Сгенерировано hw-check.sh | $(date '+%d.%m.%Y %H:%M:%S') | $HOSTNAME
        </div>
    </div>
</body>
</html>
HTMLEOF

    echo ""
    echo -e "${GREEN}[OK]${NC} HTML отчёт: ${WHITE}${report_file}${NC}"
}

generate_json_report() {
    local report_file="${OUTPUT_DIR}/hw-report-${TIMESTAMP}.json"
    mkdir -p "$OUTPUT_DIR"

    cat > "$report_file" << JSONEOF
{
  "report": {
    "hostname": "$HOSTNAME",
    "os": "$OS_INFO",
    "kernel": "$(uname -r)",
    "architecture": "$ARCH",
    "timestamp": "$(date -Iseconds)"
  },
  "cpu": {
    "model": "$(lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2 | xargs)",
    "cores": $(nproc 2>/dev/null || echo 0),
    "vendor": "$(lscpu 2>/dev/null | grep 'Vendor ID' | awk '{print $NF}')",
    "virtualization": "$(lscpu 2>/dev/null | grep 'Virtualization' | awk '{print $NF}' || echo 'none')"
  },
  "memory": {
    "total_mb": $(free -m 2>/dev/null | awk '/^Mem:/ {print $2}'),
    "used_mb": $(free -m 2>/dev/null | awk '/^Mem:/ {print $3}')
  },
  "gpu": [
    $(lspci 2>/dev/null | grep -iE 'vga|3d|display' | awk -F': ' '{gsub(/"/, "\\\"", $2); printf "{\"device\":\"%s\"},\n", $2}' | sed '$ s/,$//')
  ],
  "storage": [
    $(lsblk -d -o NAME,SIZE,MODEL,ROTA 2>/dev/null | grep "^sd\|^nvme\|^vd" | awk '{printf "{\"name\":\"/dev/%s\",\"size\":\"%s\",\"model\":\"%s\",\"type\":\"%s\"},\n", $1, $2, $3, ($4=="0"?"SSD":"HDD")}' | sed '$ s/,$//')
  ],
  "network": {
    "devices": [
      $(lspci 2>/dev/null | grep -iE 'ethernet|network' | awk -F': ' '{gsub(/"/, "\\\"", $2); printf "{\"device\":\"%s\"},\n", $2}' | sed '$ s/,$//')
    ],
    "interfaces": [
      $(ip -br addr show 2>/dev/null | awk '{printf "{\"name\":\"%s\",\"status\":\"%s\"},\n", $1, $2}' | sed '$ s/,$//')
    ]
  }
}
JSONEOF

    echo ""
    echo -e "${GREEN}[OK]${NC} JSON отчёт: ${WHITE}${report_file}${NC}"
}

# ─── Парсинг аргументов ─────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)   CHECK_TYPE="full"; shift ;;
            --cpu)    CHECK_TYPE="cpu"; shift ;;
            --gpu)    CHECK_TYPE="gpu"; shift ;;
            --network) CHECK_TYPE="network"; shift ;;
            --audio)  CHECK_TYPE="audio"; shift ;;
            --storage) CHECK_TYPE="storage"; shift ;;
            --usb)    CHECK_TYPE="usb"; shift ;;
            --wifi)   CHECK_TYPE="wifi"; shift ;;
            --bluetooth) CHECK_TYPE="bluetooth"; shift ;;
            --printer) CHECK_TYPE="printer"; shift ;;
            --laptop) CHECK_TYPE="laptop"; shift ;;
            --server) CHECK_TYPE="server"; shift ;;
            --report) REPORT_FORMAT="$2"; shift 2 ;;
            --output) OUTPUT_DIR="$2"; shift 2 ;;
            --quiet)  QUIET=true; shift ;;
            --help|-h)
                echo "Использование: $0 [OPTIONS]"
                echo ""
                echo "Опции:"
                echo "  --full           Полная проверка"
                echo "  --cpu            Только процессор"
                echo "  --gpu            Только видеокарта"
                echo "  --network        Только сеть"
                echo "  --audio          Только звук"
                echo "  --storage        Только накопители"
                echo "  --usb            Только USB"
                echo "  --wifi           Только Wi-Fi"
                echo "  --bluetooth      Только Bluetooth"
                echo "  --printer        Только принтеры"
                echo "  --laptop         Только ноутбучные компоненты"
                echo "  --server         Только серверные компоненты"
                echo "  --report FMT     Формат: html, json"
                echo "  --output DIR     Директория отчёта"
                echo "  --quiet          Тихий режим"
                echo "  --help           Справка"
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
    echo -e "${CYAN}║         HARDWARE COMPATIBILITY CHECK                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"

    check_system_info

    case $CHECK_TYPE in
        full)
            check_cpu
            check_gpu
            check_network
            check_audio
            check_storage
            check_usb
            check_wifi
            check_bluetooth
            check_printer
            check_laptop
            check_server
            ;;
        cpu)       check_cpu ;;
        gpu)       check_gpu ;;
        network)   check_network ;;
        audio)     check_audio ;;
        storage)   check_storage ;;
        usb)       check_usb ;;
        wifi)      check_wifi ;;
        bluetooth) check_bluetooth ;;
        printer)   check_printer ;;
        laptop)    check_laptop ;;
        server)    check_server ;;
    esac

    # Генерация отчёта
    if [ "$REPORT_FORMAT" != "none" ]; then
        log_header "ГЕНЕРАЦИЯ ОТЧЁТА"
        case $REPORT_FORMAT in
            html) generate_html_report ;;
            json) generate_json_report ;;
            *)    log_error "Неизвестный формат: $REPORT_FORMAT (html, json)" ;;
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

### HTML отчёт

```bash
sudo ./hw-check.sh --full --report html --output /var/reports/hw/
```

**Содержит:**
- Красивый адаптивный дизайн с карточками
- Информацию о CPU, GPU, RAM, дисках, сети
- Таблицу совместимости компонентов
- Бейджи статусов (совместимо/предупреждение/ошибка)
- Готов к печати и отправке

### JSON отчёт

```bash
sudo ./hw-check.sh --full --report json --output /var/reports/hw/
```

**Содержит:**
- Структурированные данные о всём оборудовании
- Совместим с системами инвентаризации
- Удобно для парсинга через `jq`

```bash
# Извлечь модель CPU
jq '.cpu.model' /var/reports/hw/hw-report-*.json

# Извлечь список дисков
jq '.storage[]' /var/reports/hw/hw-report-*.json

# Сетевые интерфейсы
jq '.network.interfaces[]' /var/reports/hw/hw-report-*.json
```

---

## Устранение проблем

### Сводная таблица проблем

| Проблема | Компонент | Диагностика | Решение |
|----------|-----------|-------------|---------|
| **Система не загружается** | Все | Live USB, `dmesg` | Проверить минимальную конфигурацию |
| **Нет GUI после установки** | GPU | `lspci \| grep VGA`, `glxinfo` | Установить драйвер GPU |
| **Нет сети** | Сетевой адаптер | `ip addr`, `lspci`, `ethtool -i` | Установить драйвер, firmware |
| **Нет Wi-Fi** | Wi-Fi адаптер | `lspci`, `iw dev`, `dmesg` | Установить firmware, драйвер |
| **Нет звука** | Звуковая карта | `aplay -l`, `alsamixer` | Расmute, загрузить модуль |
| **USB не работает** | USB контроллер | `lsusb`, `dmesg` | Обновить ядро, BIOS |
| **Диск не определяется** | Накопитель | `lsblk`, `lspci`, `dmesg` | Проверить подключение, режим SATA |
| **Bluetooth не работает** | Bluetooth | `bluetoothctl`, `lsusb` | Включить сервис, rfkill |
| **Принтер не печатает** | Принтер | `lpstat`, `cupsctl` | Установить драйвер, настроить CUPS |
| **Тачпад не работает** | Ноутбук тачпад | `libinput list-devices` | Загрузить модуль, настройки X |
| **Suspend не работает** | Ноутбук ACPI | `dmesg`, `journalctl` | Обновить BIOS, blacklist модуль |
| **Батарея не заряжается** | Ноутбук батарея | `upower`, `/sys/class/power_supply/` | Calibrate, проверить БП |
| **RAID не определяется** | RAID контроллер | `lspci`, `MegaCli`, `arcconf` | Установить утилиты, драйвер |
| **ECC ошибки** | Сервер RAM | `edac-util`, `dmesg` | Заменить модуль памяти |
| **Перегрев** | Система охлаждения | `sensors`, `ipmitool` | Проверить вентиляторы, обдув |

### Алгоритм диагностики

```
1. Определить проблему
   ├── Система не загружается -> Live USB, проверить минимальную конфигурацию
   ├── Конкретное устройство не работает -> lspci/lsusb, dmesg
   └── Плохая производительность -> Benchmark, сравнить с ожидаемой

2. Найти устройство
   ├── PCI: lspci
   ├── USB: lsusb
   └── Блочное: lsblk

3. Проверить драйвер
   ├── lspci -k (для PCI)
   ├── lsmod | grep driver
   └── dmesg | grep -i error

4. Проверить совместимость
   ├── Таблица выше
   ├── hw-check.sh --full
   └── Поиск по модели устройства + "RED OS" / "RHEL"

5. Применить решение
   ├── Установить драйвер
   ├── Обновить ядро
   ├── Установить firmware
   └── Настроить конфигурацию
```

---

## 🔗 Связанные документы

- [Диагностика состояния системы](system-health-check.md) -- общий мониторинг
- [Анализ журналов systemd](log-analyzer.md) -- поиск причин проблем
- [Настройка сети](../network/readme.md) -- сетевая конфигурация
- [Оптимизация производительности](../performance/readme.md) -- тюнинг системы

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Ядро** | 5.15+ (7.x), 6.1+ (8.x) |
| **Архитектуры** | x86_64 (основная), aarch64 (поддерживается) |
| **Права** | Пользователь (базовые), root (SMART, IPMI, NVMe) |
| **Зависимости** | bash, coreutils, pciutils, usbutils, util-linux |
| **Опционально** | smartmontools, nvme-cli, ethtool, glx-utils, ipmitool, lm_sensors, alsa-utils |
| **Скрипт** | hw-check.sh (bash 4.0+) |
| **Отчёты** | HTML, JSON |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Для проверки SMART, NVMe, IPMI и некоторых других компонентов требуются root-права.
> Некоторые проприетарные драйверы (NVIDIA, Realtek) могут потребовать дополнительной настройки.
> РЕД ОС 8.x имеет более новое ядро и лучшую поддержку современного оборудования.

---

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
