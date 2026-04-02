# Проблемы с графикой в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

- [1. Чёрный экран после загрузки системы](#1-чёрный-экран-после-загрузки-системы)
- [2. Низкое разрешение экрана](#2-низкое-разрешение-экрана)
- [3. Тормозит интерфейс GNOME/MATE](#3-тормозит-интерфейс-gnomemate)
- [4. Проблемы с драйверами NVIDIA](#4-проблемы-с-драйверами-nvidia)
- [5. Мерцание экрана на ноутбуках с Intel HD Graphics](#5-мерцание-экрана-на-ноутбуках-с-intel-hd-graphics)
- [6. Не работает аппаратное ускорение видео](#6-не-работает-аппаратное-ускорение-видео)
- [7. Артефакты в играх и 3D-приложениях](#7-артефакты-в-играх-и-3d-приложениях)
- [8. Не регулируется яркость экрана](#8-не-регулируется-яркость-экрана)
- [9. Проверка состояния графической подсистемы](#9-проверка-состояния-графической-подсистемы)
- [10. Быстрое восстановление после сбоя графики](#10-быстрое-восстановление-после-сбоя-графики)

---

## 🔧 Лайфхаки по решению проблем с графикой

### 1. Чёрный экран после загрузки системы

**Проблема:** После загрузки РЕД ОС отображается чёрный экран с курсором.

**Решение:**
```bash
# Переустановите драйверы Mesa
sudo dnf reinstall mesa-dri-drivers mesa-libGL mesa-libEGL

# Пересоздайте конфигурацию X11
sudo rm -rf /etc/X11/xorg.conf
sudo Xorg -configure
sudo mv /root/xorg.conf.new /etc/X11/xorg.conf
```

---

### 2. Низкое разрешение экрана

**Проблема:** Система не предлагает нужное разрешение экрана.

**Решение:**
```bash
# Узнайте имя подключения (например, HDMI-1 или DP-1)
xrandr

# Добавьте нужное разрешение (пример для 1920x1080)
cvt 1920 1080
# Скопируйте строку Modeline из вывода cvt

xrandr --newmode "1920x1080_60.00" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
xrandr --addmode <ваше_подключение> "1920x1080_60.00"
xrandr --output <ваше_подключение> --mode "1920x1080_60.00"
```

**Постоянное применение:** Добавьте команды в `~/.xprofile`

---

### 3. Тормозит интерфейс GNOME/MATE

**Проблема:** Интерфейс работает медленно, наблюдаются артефакты.

**Решение:**
```bash
# Отключите композитинг для старых видеокарт
gsettings set org.mate.Marco.general compositing-manager false

# Или переключитесь на более лёгкое окружение
sudo dnf groupinstall "Xfce"
```

---

### 4. Проблемы с драйверами NVIDIA

**Проблема:** Проприетарные драйверы NVIDIA не работают или конфликтуют с nouveau.

**Решение:**
```bash
# Заблокируйте драйвер nouveau
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf

# Пересоздайте initramfs
sudo dracut --force

# Установите драйверы NVIDIA из репозитория ELRepo
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo dnf install nvidia-driver nvidia-settings
```

---

### 5. Мерцание экрана на ноутбуках с Intel HD Graphics

**Проблема:** Экран мерцает при изменении яркости или частоты обновления.

**Решение:**
```bash
# Создайте конфигурационный файл для Intel
sudo tee /etc/X11/xorg.conf.d/20-intel.conf << EOF
Section "Device"
  Identifier "Intel Graphics"
  Driver "intel"
  Option "TearFree" "true"
  Option "DRI" "3"
EndSection
EOF

# Перезапустите графическую подсистему
sudo systemctl restart display-manager
```

---

### 6. Не работает аппаратное ускорение видео

**Проблема:** Видео воспроизводится с рывками, CPU загружен на 100%.

**Решение:**
```bash
# Установите кодеки и драйверы для аппаратного декодирования
sudo dnf install vaapi-intel-driver libva-utils vdpauinfo

# Проверьте поддержку VA-API
vainfo

# Для NVIDIA установите:
sudo dnf install nvidia-vdpau-driver vdpauinfo
```

---

### 7. Артефакты в играх и 3D-приложениях

**Проблема:** В играх появляются графические артефакты или текстуры отображаются некорректно.

**Решение:**
```bash
# Обновите Mesa до последней версии
sudo dnf update mesa-*

# Увеличьте видеопамять для интегрированных карт (в BIOS/UEFI)
# Или установите переменную окружения для игр:
export mesa_glthread=true
export __GL_YIELD="USLEEP"
```

---

### 8. Не регулируется яркость экрана

**Проблема:** Клавиши регулировки яркости не работают.

**Решение:**
```bash
# Добавьте параметр ядра для Intel
sudo tee -a /etc/default/grub << EOF
GRUB_CMDLINE_LINUX="acpi_backlight=vendor"
EOF

# Обновите GRUB
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo reboot
```

---

### 9. Проверка состояния графической подсистемы

**Полезные команды для диагностики:**

```bash
# Информация о видеокарте
lspci | grep -i vga

# Используемый драйвер
glxinfo | grep "OpenGL renderer"

# Статус драйверов Mesa
glxinfo | grep -i "mesa"

# Температура GPU (для дискретных карт)
nvidia-smi  # для NVIDIA
radeontop   # для AMD
intel_gpu_top # для Intel

# Проверка поддержки OpenGL
glxgears
```

---

### 10. Быстрое восстановление после сбоя графики

**Проблема:** Графический интерфейс завис и не реагирует.

**Решение:**
```bash
# Переключитесь в консоль: Ctrl+Alt+F2

# Перезапустите дисплей-менеджер
sudo systemctl restart gdm# для GNOME
sudo systemctl restart lightdm # для LightDM
sudo systemctl restart sddm# для KDE

# Или перезапустите графическую сессию без перезагрузки
sudo systemctl isolate multi-user.target
sudo systemctl isolate graphical.target
```

---

## 📝 Дополнительные ресурсы

- [Официальная документация РЕД ОС](https://redos.red-soft.ru/ru/download-documentation)
- [Форум поддержки](https://forum.redos.red-soft.ru/)
- [База знаний по Linux-графике](https://wiki.archlinux.org/title/Configuration_of_video_cards)

---

> 💡 **Совет:** Перед внесением изменений в графическую подсистему создайте точку восстановления или резервную копию важных файлов.
