# Настройка многомониторной конфигурации в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## Лайфхаки по настройке нескольких мониторов

### 1. Определение подключённых мониторов

```bash
# Список всех видеовыходов и их статусов
xrandr

# Подробная информация о мониторах
xrandr --query

# Для Wayland (если используется)
wlr-randr
```

> **Совет:** Запомните названия выходов (HDMI-1, DP-1, eDP-1) — они понадобятся для настройки.

---

### 2. Базовая настройка двух мониторов

```bash
# Расширение рабочего стола (второй монитор справа)
xrandr --output HDMI-1 --auto --right-of eDP-1

# Клонирование (одинаковое изображение)
xrandr --output HDMI-1 --auto --same-as eDP-1

# Второй монитор слева
xrandr --output DP-1 --auto --left-of eDP-1

# Второй монитор сверху
xrandr --output DP-1 --auto --above eDP-1
```

> **Совет:** `--auto` автоматически выбирает оптимальное разрешение. Для конкретного разрешения используйте `--mode 1920x1080`.

---

### 3. Настройка разрешения и частоты обновления

```bash
# Установка конкретного разрешения
xrandr --output HDMI-1 --mode 1920x1080 --rate 60

# Проверка поддерживаемых режимов
xrandr --output HDMI-1 --verbose | grep -A 20 "Supported modes"

# Масштабирование (для 4K мониторов)
xrandr --output HDMI-1 --scale 2x2
```

> **Совет:** Для 4K мониторов используйте `--scale 2x2` или `--scale 1.5x1.5` для комфортной работы без изменения разрешения.

---

### 4. Настройка основного монитора

```bash
# Сделать монитор основным (для панелей, уведомлений)
xrandr --output HDMI-1 --primary

# Проверка текущего основного
xrandr --query | grep primary
```

> **Совет:** Основной монитор определяется по положению панели задач и системных уведомений.

---

### 5. Сохранение конфигурации

#### Через xprofile (для X11):
```bash
# Создайте файл ~/.xprofile
cat > ~/.xprofile << 'EOF'
#!/bin/bash
xrandr --output HDMI-1 --auto --right-of eDP-1 --primary
xrandr --output DP-1 --auto --right-of HDMI-1
EOF

chmod +x ~/.xprofile
```

#### Через autorandr (автоматическое определение):
```bash
# Установка autorandr
sudo dnf install autorandr

# Сохранение текущей конфигурации
autorandr --save home

# Сохранение другой конфигурации
autorandr --save office

# Автоматическое применение
autorandr --change
```

> **Совет:** `autorandr` автоматически определяет подключённые мониторы и применяет сохранённую конфигурацию.

---

### 6. Настройка HiDPI (масштабирование)

```bash
# Масштабирование для 4K монитора
xrandr --output HDMI-1 --scale 2x2 --mode 3840x2160

# Разное масштабирование для разных мониторов
xrandr --output eDP-1 --scale 1x1 --output HDMI-1 --scale 2x2

# Для GTK приложений
gsettings set org.gnome.desktop.interface scaling-factor 2

# Для Qt приложений
export QT_SCALE_FACTOR=2
```

> **Совет:** При смешанной конфигурации (обычный + HiDPI) используйте `--scale` для выравнивания размеров элементов.

---

### 7. Настройка ориентации монитора

```bash
# Поворот на 90 градусов (портретный режим)
xrandr --output DP-1 --rotate left

# Поворот на 180 градусов
xrandr --output DP-1 --rotate inverted

# Поворот на 270 градусов
xrandr --output DP-1 --rotate right

# Возврат к обычной ориентации
xrandr --output DP-1 --rotate normal
```

> **Совет:** Портретная ориентация удобна для чтения кода, документов и работы с терминалом.

---

### 8. Настройка положения с точностью до пикселя

```bash
# Точное позиционирование (x, y)
xrandr --output HDMI-1 --pos 1920x0
xrandr --output DP-1 --pos 3840x0

# Проверка текущих позиций
xrandr --query | grep -E "connected|primary"
```

> **Совет:** Используйте `--pos` для точного выравнивания мониторов с разным разрешением.

---

### 9. Решение типичных проблем

#### Монитор не определяется:
```bash
# Принудительное определение
xrandr --output HDMI-1 --auto

# Проверка кабелей и подключений
dmesg | grep -i drm

# Перезапуск X-сервера (осторожно!)
sudo systemctl restart display-manager
```

#### Мерцание экрана:
```bash
# Отключение энергосбережения для монитора
xrandr --output HDMI-1 --set "Broadcast RGB" "Full"

# Фиксация частоты обновления
xrandr --output HDMI-1 --mode 1920x1080 --rate 60
```

#### Неправильное разрешение:
```bash
# Создание пользовательского режима
cvt 2560 1440 60
xrandr --newmode "2560x1440_60.00" 312.25 2560 2752 3024 3488 1440 1443 1448 1493 -hsync +vsync
xrandr --addmode HDMI-1 "2560x1440_60.00"
xrandr --output HDMI-1 --mode "2560x1440_60.00"
```

---

### 10. Графическая настройка мониторов

#### Для MATE:
```bash
# Запуск настройки дисплеев
mate-display-properties

# Или через меню:
# Система → Параметры → Оборудование → Дисплеи
```

#### Для Cinnamon:
```bash
# Настройка дисплеев
cinnamon-settings display
```

#### Для GNOME:
```bash
# Настройка дисплеев
gnome-control-center display
```

> **Совет:** Графические инструменты удобны для быстрой настройки, но `xrandr` даёт больше контроля.

---

### 11. Автоматическое переключение конфигураций

Скрипт для автоматического определения и настройки мониторов:

```bash
#!/bin/bash
# auto-display.sh

# Проверка подключённых мониторов
if xrandr | grep -q "HDMI-1 connected"; then
    # Домашняя конфигурация
    xrandr --output eDP-1 --auto --primary
    xrandr --output HDMI-1 --auto --right-of eDP-1 --primary
elif xrandr | grep -q "DP-1 connected"; then
    # Офисная конфигурация
    xrandr --output eDP-1 --auto
    xrandr --output DP-1 --auto --right-of eDP-1 --primary
    xrandr --output HDMI-1 --auto --right-of DP-1
else
    # Только встроенный дисплей
    xrandr --output eDP-1 --auto --primary
fi
```

Добавьте в автозагрузку:
```bash
chmod +x ~/auto-display.sh
echo "~/auto-display.sh" >> ~/.xprofile
```

---

### 12. Полезные команды для мониторинга

```bash
# Информация о видеокарте
lspci | grep -i vga

# Загруженные драйверы
lsmod | grep -E "i915|amdgpu|nouveau|nvidia"

# Температура GPU
sensors

# Использование GPU
nvidia-smi  # для NVIDIA
intel_gpu_top  # для Intel
radeontop  # для AMD
```

> **Совет:** При проблемах с многомониторной конфигурацией проверьте драйверы и температуру GPU.

---

## См. также

- [Настройка рабочего окружения](/docs/desktop/environment-setup.md)
- [Автомонтирование SSHFS](/docs/desktop/automount-sshfs.md)

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Сервер** | X11 (xrandr), Wayland (wlr-randr) |
| **Утилиты** | `xrandr`, `autorandr`, `cvt` |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x с Wayland по умолчанию утилита `xrandr` может не работать — используйте `wlr-randr` или переключитесь на X11. `autorandr` автоматически определяет конфигурацию мониторов.
