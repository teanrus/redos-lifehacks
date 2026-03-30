# Решение проблем со звуком в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📚 Оглавление

- [1. Проверка состояния звука](#1-проверка-состояния-звука)
- [2. Звук полностью отсутствует](#2-звук-полностью-отсутствует)
- [3. Звук тихий или хриплый](#3-звук-тихий-или-хриплый)
- [4. Не работает микрофон](#4-не-работает-микрофон)
- [5. Переключение между устройствами вывода](#5-переключение-между-устройствами-вывода)
- [6. Проблемы с Bluetooth-гарнитурой](#6-проблемы-с-bluetooth-гарнитурой)
- [7. Звук работает только в одном приложении](#7-звук-работает-только-в-одном-приложении)
- [8. Треск и щелчки при воспроизведении](#8-треск-и-щелчки-при-воспроизведении)
- [9. Нет звука после обновления системы](#9-нет-звука-после-обновления-системы)
- [10. Настройка эквалайзера и эффектов](#10-настройка-эквалайзера-и-эффектов)
- [🤖 Автоматическая диагностика через скрипт](#-автоматическая-диагностика-через-скрипт)

---

## 🛠️ Лайфхаки по решению проблем со звуком

### 1. Проверка состояния звука

Быстрая диагностика звуковой системы:

```bash
# Проверка звуковых устройств
aplay -l

# Проверка устройств записи
arecord -l

# Статус звукового сервера
systemctl --user status pulseaudio

# Для PipeWire
systemctl --user status pipewire
systemctl --user status wireplumber

# Проверка уровней громкости
amixer sget Master

# Тестовое воспроизведение
speaker-test -c 2 -t wav
```

| Команда | Описание |
|---------|----------|
| `aplay -l` | Список воспроизводящих устройств |
| `arecord -l` | Список устройств записи |
| `amixer sget Master` | Уровень громкости |
| `speaker-test` | Тест динамиков |

> **Зачем:** Быстрое определение проблемы на начальном этапе.

---

### 2. Звук полностью отсутствует

Основные шаги для восстановления звука:

```bash
# Проверка, не заглушен ли звук
amixer sget Master | grep -i mute

# Включение звука (снять Mute)
amixer sset Master unmute

# Установка громкости на 80%
amixer sset Master 80%

# Перезапуск PulseAudio
systemctl --user restart pulseaudio

# Для PipeWire
systemctl --user restart pipewire
systemctl --user restart wireplumber
```

**Если не помогло:**

```bash
# Проверка выбора устройства вывода
pactl list short sinks

# Установка устройства по умолчанию
pactl set-default-sink alsa_output.pci-0000_00_1b.0.analog-stereo

# Сброс настроек PulseAudio
rm -rf ~/.config/pulse/*
systemctl --user restart pulseaudio
```

> **Зачем:** Решение 80% проблем со звуком.

---

### 3. Звук тихий или хриплый

Усиление и улучшение качества звука:

```bash
# Установка максимальной громкости
amixer sset Master 100%

# Проверка усиления (Boost)
amixer sget 'Auto-Mute Mode'

# Включение усиления микрофона
amixer sset 'Mic Boost' 3

# Для ноутбуков (проверка настроек)
alsamixer
# Нажмите F6 для выбора карты
# Увеличьте Master, PCM, Speaker
```

**Настройка через PulseAudio:**

```bash
# Запуск графического эквалайзера
pavucontrol

# Усиление через pactl (до 150%)
pactl set-sink-volume @DEFAULT_SINK@ 150%
```

**Устранение хрипов:**

```bash
# Уменьшение качества формата (для слабых систем)
nano /etc/pulse/daemon.conf

# Раскомментировать или добавить:
default-sample-format = s16le
default-sample-rate = 44100
alternate-sample-rate = 48000

# Перезапуск
systemctl --user restart pulseaudio
```

| Параметр | Описание |
|----------|----------|
| `Master` | Основная громкость |
| `PCM` | Громкость цифрового аудио |
| `Speaker` | Встроенные динамики |
| `Headphone` | Наушники |

> **Зачем:** Улучшение качества и громкости звука.

---

### 4. Не работает микрофон

Диагностика и настройка записи:

```bash
# Проверка устройств записи
arecord -l

# Проверка уровня микрофона
amixer sget Capture

# Включение микрофона
amixer sset Capture unmute

# Установка уровня записи
amixer sset Capture 80%

# Проверка работы микрофона
arecord -d 5 test.wav
aplay test.wav
```

**Настройка в PulseAudio:**

```bash
# Список источников записи
pactl list short sources

# Установка устройства по умолчанию
pactl set-default-source alsa_input.pci-0000_00_1b.0.analog-stereo

# Запуск панели управления
pavucontrol
# Вкладка "Input Devices" - выберите микрофон
```

**Если микрофон не виден:**

```bash
# Проверка модулей ядра
lsmod | grep snd

# Перезагрузка модуля (замените snd_hda_intel на ваш)
sudo modprobe -r snd_hda_intel
sudo modprobe snd_hda_intel

# Проверка настроек BIOS/UEFI
# Включите HD Audio Controller
```

> **Зачем:** Настройка записи звука и видеозвонков.

---

### 5. Переключение между устройствами вывода

Наушники, колонки, HDMI:

```bash
# Список устройств вывода
pactl list short sinks

# Пример вывода:
# 0	alsa_output.pci-0000_00_1b.0.analog-stereo	module-alsa-card.c	s16le 2ch 44100Hz
# 1	alsa_output.pci-0000_01_00.1.hdmi-stereo	module-alsa-card.c	s16le 2ch 44100Hz

# Переключение на наушники
pactl set-default-sink alsa_output.pci-0000_00_1b.0.analog-stereo

# Переключение на HDMI
pactl set-default-sink alsa_output.pci-0000_01_00.1.hdmi-stereo

# Перемещение всех потоков на новое устройство
for stream in $(pactl list short sink-inputs | cut -f1); do
pactl move-sink-input $stream @DEFAULT_SINK@
done
```

**Графическое переключение:**

```bash
# Установка pavucontrol
sudo dnf install pavucontrol

# Запуск
pavucontrol
# Вкладка "Output Devices" - выберите устройство
```

> **Зачем:** Быстрое переключение между колонками, наушниками, ТВ.

---

### 6. Проблемы с Bluetooth-гарнитурой

Подключение и настройка Bluetooth-наушников:

```bash
# Проверка статуса Bluetooth
systemctl status bluetooth

# Запуск службы
sudo systemctl start bluetooth
sudo systemctl enable bluetooth

# Поиск устройств
bluetoothctl
scan on

# Сопряжение
pair XX:XX:XX:XX:XX:XX

# Подключение
connect XX:XX:XX:XX:XX:XX

# Доверие устройству
trust XX:XX:XX:XX:XX:XX
```

**Если звук прерывается:**

```bash
# Редактирование конфига PulseAudio
sudo nano /etc/pulse/default.pa

# Добавить в конец:
load-module module-bluetooth-discover
load-module module-bluetooth-policy

# Перезапуск
systemctl --user restart pulseaudio
```

**Переключение на режим гарнитуры (HSP/HFP):**

```bash
# Проверка доступных профилей
pactl list cards | grep -A 20 "BlueZ"

# Переключение профиля
pactl set-card-profile bluez_card.XX_XX_XX_XX_XX_XX headset_head_unit
```

| Профиль | Описание | Качество |
|---------|----------|----------|
| `a2dp_sink` | Музыка (A2DP) | Высокое |
| `headset_head_unit` | Гарнитура (HSP/HFP) | Низкое (для звонков) |
| `off` | Отключено | - |

> **Зачем:** Работа с Bluetooth-наушниками и гарнитурами.

---

### 7. Звук работает только в одном приложении

Проблемы с микшированием звука:

```bash
# Проверка запущенных звуковых потоков
pactl list short sink-inputs

# Перезапуск PulseAudio
systemctl --user restart pulseaudio

# Проверка модулей
pactl list short modules

# Перезагрузка модуля микширования
pactl unload-module module-rescue-streams
pactl load-module module-rescue-streams
```

**Если проблема в ALSA:**

```bash
# Проверка настроек ALSA
cat /etc/asound.conf

# Временное переключение на ALSA напрямую
export AUDIODRIVER=alsa

# Запуск приложения
application
```

**Сброс настроек:**

```bash
# Удаление настроек PulseAudio
rm -rf ~/.config/pulse/*
rm -rf ~/.pulse/*

# Перезапуск
systemctl --user restart pulseaudio
```

> **Зачем:** Одновременная работа звука в браузере, плеере, играх.

---

### 8. Треск и щелчки при воспроизведении

Устранение артефактов звука:

```bash
# Увеличение буфера PulseAudio
nano /etc/pulse/daemon.conf

# Добавить или изменить:
default-fragments = 8
default-fragment-size-msec = 25
resample-method = soxr-vhq
enable-lfe-remixing = yes

# Перезапуск
systemctl --user restart pulseaudio
```

**Отключение энергосбережения:**

```bash
# Создание конфига
sudo nano /etc/modprobe.d/audio-powersave.conf

# Добавить:
options snd_hda_intel power_save=0
options snd_ac97_codec power_save=0

# Перезагрузка или перезагрузка модулей
sudo modprobe -r snd_hda_intel
sudo modprobe snd_hda_intel
```

**Проверка частоты дискретизации:**

```bash
# Установка фиксированной частоты
nano /etc/pulse/daemon.conf

# Раскомментировать:
default-sample-rate = 48000
alternate-sample-rate = 44100
```

> **Зачем:** Устранение треска, щелчков, прерываний звука.

---

### 9. Нет звука после обновления системы

Восстановление после обновления:

```bash
# Проверка установленных пакетов
rpm -qa | grep -E 'pulseaudio|pipewire|alsa'

# Переустановка звуковых пакетов
sudo dnf reinstall pulseaudio pulseaudio-utils alsa-lib

# Для PipeWire
sudo dnf reinstall pipewire pipewire-pulse wireplumber

# Пересоздание конфига ALSA
sudo alsactl init

# Сброс настроек пользователя
rm -rf ~/.config/pulse/*
systemctl --user restart pulseaudio
```

**Если обновился ядро:**

```bash
# Перезагрузка (для загрузки нового ядра)
sudo reboot

# Проверка модулей звука
lsmod | grep snd

# Принудительная загрузка модуля
sudo modprobe snd_hda_intel
```

> **Зачем:** Восстановление работы звука после обновлений.

---

### 10. Настройка эквалайзера и эффектов

Улучшение качества звука:

```bash
# Установка LSP плагинов
sudo dnf install lsp-plugins

# Установка pulseaudio-equalizer
sudo dnf install pulseaudio-equalizer

# Запуск эквалайзера
pulseaudio-equalizer-gtk

# Или через pavucontrol + ladspa
pavucontrol
```

**Настройка через LADSPA:**

```bash
# Установка плагинов
sudo dnf install swh-plugins capns-plugins

# Загрузка модуля
pactl load-module module-ladspa-sink \
sink_name=ladspa_output \
plugin=multiband_compressor \
label=mbeq_1197 \
control=0.2,0.4,0.6,0.8,1.0,1.2,1.4

# Установка как устройства по умолчанию
pactl set-default-sink ladspa_output
```

**Бас-буст (усиление низких частот):**

```bash
# Через amixer
amixer sset 'Bass' 80%

# Через PulseAudio
pactl load-module module-equalizer-sink
```

> **Зачем:** Настройка звука под личные предпочтения.

---

## 🤖 Автоматическая диагностика через скрипт

Скрипт для автоматической диагностики проблем со звуком в **РЕД ОС**.

## 📋 Описание

Скрипт предоставляет интерактивный интерфейс для диагностики и решения проблем со звуком:

| № | Компонент | Описание |
|---|-----------|----------|
| 1 | **Информация о системе** | Версия ОС, ядро, аудиоустройства |
| 2 | **Проверка звуковых устройств** | Список устройств, статус |
| 3 | **Проверка PulseAudio/PipeWire** | Статус служб |
| 4 | **Проверка уровней громкости** | Mute, уровни |
| 5 | **Перезапуск звуковой подсистемы** | Сброс и перезапуск |
| 6 | **Итоговый отчёт** | Рекомендации |

---

## 🚀 Быстрый старт

### Одной командой (неинтерактивный режим):

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/sound-diagnostics.sh | bash
```

### Или вручную (интерактивный режим):

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/sound-diagnostics.sh

# Сделайте исполняемым
chmod +x sound-diagnostics.sh

# Запустите
./sound-diagnostics.sh
```

---

## 📖 Возможности

### ✅ Интерактивный режим (запуск напрямую)
- Пошаговая диагностика всех компонентов
- Запрос подтверждения перед действиями
- Автоматическое включение заглушенных каналов
- Перезапуск звуковой подсистемы по запросу
- Тест динамиков

### ⚡ Неинтерактивный режим (запуск через curl | bash)
- Полная диагностика без остановки
- Вывод рекомендаций для ручного исправления
- Команды для копирования и выполнения

### 🔧 Технические возможности

#### 1. Информация о системе
```
Информация о системе:
  Версия ОС:РЕД ОС 7.3 Муром
  Ядро: 6.1.0-100-generic
  Архитектура:  x86_64

Звуковая карта:
  Intel Corporation: Device 1234
  Driver: snd_hda_intel
```

#### 2. Проверка звуковых устройств
```
Устройства воспроизведения:
  ✓ card 0: PCH [HDA Intel PCH], device 0: ALC269VC Analog

Устройства записи:
  ✓ card 0: PCH [HDA Intel PCH], device 0: ALC269VC Analog
```

#### 3. Проверка PulseAudio/PipeWire
```
Звуковой сервер:
  ✓ PulseAudio: running
  ✗ PipeWire: not installed

Модули: 45 загружено
```

#### 4. Проверка уровней громкости
```
Уровни громкости:
  ✓ Master: 85%
  ✗ Speaker: MUTE
  ✓ PCM: 100%

⚠ Предупреждение: Speaker заглушен!
```

#### 5. Перезапуск звуковой подсистемы
```
Перезапуск звуковой подсистемы:
  ✓ PulseAudio перезапущен
  ✓ Устройства пересканированы
```

#### 6. Итоговый отчёт
```
=== Результаты диагностики ===

✓ Звуковые устройства: OK
✓ PulseAudio: OK
⚠ Уровни громкости: Требуется настройка

Рекомендации:
  1. Включите Speaker: amixer sset Speaker unmute
  2. Проверьте выбор устройства вывода в pavucontrol
```

---

## 🖥️ Пример работы (интерактивный режим)

```bash
========================================
Диагностика проблем со звуком в РЕД ОС
========================================
Дата запуска: пн мар 30 12:00:00 MSK 2026

[INFO] Информация о системе:
========================================
  Версия ОС:РЕД ОС 7.3 Муром
  Ядро: 6.1.0-100-generic
  Архитектура:  x86_64

Звуковая карта:
  Intel Corporation: Device 1234
  Driver: snd_hda_intel

[INFO] Проверка звуковых устройств:
========================================

Устройства воспроизведения:
  ✓ card 0: PCH [HDA Intel PCH], device 0: ALC269VC Analog

Устройства записи:
  ✓ card 0: PCH [HDA Intel PCH], device 0: ALC269VC Analog

[INFO] Проверка PulseAudio/PipeWire:
========================================

Звуковой сервер:
  ✓ PulseAudio: running
  ✗ PipeWire: not installed

[INFO] Проверка уровней громкости:
========================================

Уровни громкости:
  ✓ Master: 85%
  ✗ Speaker: MUTE
  ✓ PCM: 100%

⚠ Предупреждение: Speaker заглушен!

Включить Speaker? (y/n): y
[INFO] Включение Speaker...
✓ Speaker включён

[INFO] Перезапуск звуковой подсистемы:
========================================

Перезапустить PulseAudio для применения настроек? (y/n): y
[INFO] Перезапуск PulseAudio...
✓ PulseAudio перезапущен

========================================
Результаты диагностики:
========================================

✓ Звуковые устройства: OK
✓ PulseAudio: OK
✓ Уровни громкости: Исправлено

Рекомендации:
  1. Проверьте выбор устройства вывода в pavucontrol
  2. Для настройки эквалайзера: pulseaudio-equalizer-gtk

Полезные команды:
  pavucontrol  # панель управления звуком
  alsamixer    # консольный микшер
  pulseaudio-equalizer-gtk # эквалайзер
  speaker-test -c 2 -t wav # тест динамиков

[INFO] Готово!
```

---

## 🖥️ Пример работы (неинтерактивный режим)

```bash
$ curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/sound-diagnostics.sh | bash

========================================
Диагностика проблем со звуком в РЕД ОС
========================================

[INFO] Информация о системе:
========================================
  Версия ОС:РЕД ОС 7.3 Муром
  Ядро: 6.1.0-100-generic
  Архитектура:  x86_64

...

[INFO] Проверка уровней громкости:
========================================

Уровни громкости:
  ✓ Master: 85%
  ✗ Speaker: MUTE
  ✓ PCM: 100%

⚠ Неинтерактивный режим: автоматическое исправление пропущено
Рекомендации:
  • Включите Speaker: amixer sset Speaker unmute

⚠ Неинтерактивный режим: перезапуск звуковой подсистемы пропущен
Для перезапуска выполните:
  systemctl --user restart pulseaudio

========================================
Результаты диагностики:
========================================
...
```

---

## 📋 Требования

| Требование | Описание |
|------------|----------|
| **ОС** | РЕД ОС 7.x / 8.x (RHEL-совместимые) |
| **Права** | Не требуются (базовая диагностика) |
| **Зависимости** | `pulseaudio`, `alsa-utils`, `pactl` |
| **Опционально** | `pavucontrol`, `pulseaudio-equalizer`, `lspci`, `lsusb` |

---

## 🔍 Проверка результатов

После диагностики:

```bash
# Проверка звука
speaker-test -c 2 -t wav

# Проверка устройств
pactl list short sinks

# Проверка микрофона
arecord -d 5 test.wav && aplay test.wav

# Графическая настройка
pavucontrol
```

---

## ⚠️ Важные замечания

1. **PulseAudio vs PipeWire**: РЕД ОС 8.x использует PipeWire по умолчанию.
2. **Права root**: Большинство команд не требуют root.
3. **Bluetooth**: Для работы Bluetooth-гарнитур нужен модуль `module-bluetooth-discover`.
4. **Энергосбережение**: Отключите для устранения треска.
5. **Настройки пользователя**: `~/.config/pulse/` хранит настройки.
6. **BIOS/UEFI**: Проверьте включение HD Audio Controller.
7. **Интерактивный режим**: При запуске через `curl | bash` скрипт работает в неинтерактивном режиме — не запрашивает подтверждение, а выводит рекомендации.
8. **Прямой запуск**: Для интерактивной диагностики запускайте скрипт напрямую: `./sound-diagnostics.sh`.

---

## 📝 Полезные команды

| Команда | Описание |
|---------|----------|
| `amixer sget Master` | Проверка громкости |
| `amixer sset Master 80%` | Установка громкости |
| `amixer sset Master unmute` | Включение звука |
| `pactl list short sinks` | Список устройств вывода |
| `pactl set-default-sink` | Установка устройства по умолчанию |
| `pavucontrol` | Графическая панель управления |
| `alsamixer` | Консольный микшер |
| `speaker-test -c 2 -t wav` | Тест стерео |
| `arecord -d 5 test.wav` | Запись с микрофона |
| `systemctl --user restart pulseaudio` | Перезапуск PulseAudio |

---

## 🔗 Полезные ссылки

| Ресурс | Описание |
|--------|----------|
| `https://redos.red-soft.ru/base/` | База знаний РЕД ОС |
| `https://www.freedesktop.org/wiki/Software/PulseAudio/` | Официальная документация PulseAudio |
| `https://pipewire.org/` | Официальный сайт PipeWire |
| `https://wiki.archlinux.org/title/PulseAudio` | Arch Wiki по PulseAudio |
| `https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture` | Arch Wiki по ALSA |
