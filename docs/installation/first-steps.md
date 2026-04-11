# Первые шаги после установки РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Bash](https://img.shields.io/badge/bash-5.0+-blue.svg)]()
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📖 Оглавление

1. [Обновление системы](#-1-обновление-системы)
2. [Настройка репозиториев](#-2-настройка-репозиториев)
3. [Установка кодеков и драйверов](#-3-установка-кодеков-и-драйверов)
4. [Настройка внешнего вида](#-4-настройка-внешнего-вида)
5. [Установка необходимого ПО](#-5-установка-необходимого-по)
6. [Настройка безопасности](#-6-настройка-безопасности)
7. [Оптимизация производительности](#-7-оптимизация-производительности)
8. [Лайфхаки](#-лайфхаки)

---

## 🔄 1. Обновление системы

```bash
# Обновить информацию о репозиториях
sudo dnf check-update

# Установить все доступные обновления
sudo dnf upgrade --refresh

# Очистить кэш после обновления
sudo dnf clean all
```

> [!TIP]
> Рекомендуется выполнять обновление сразу после установки системы и перед установкой нового ПО.

---

## 📦 2. Настройка репозиториев

```bash
# Проверить подключённые репозитории
dnf repolist

# Включить все репозитории
sudo dnf config-manager --set-enabled "*"

# Проверить доступные репозитории
dnf repolist --all
```

---

## 🎬 3. Установка кодеков и драйверов

### Мультимедиа кодеки

```bash
# Установка кодеков для воспроизведения видео и аудио
sudo dnf install ffmpeg gstreamer1-plugins-base gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free gstreamer1-plugins-ugly-free

# Кодеки для популярных форматов
sudo dnf install libdvdcss gstreamer1-plugin-openh264
```

### Драйверы устройств

```bash
# Драйверы для принтеров
sudo dnf install cups cups-filters

# Драйверы для сканеров
sudo dnf install sane-backends sane-backends-drivers-scanners

# Драйверы для Wi-Fi адаптеров
sudo dnf install linux-firmware

# Драйверы для видеокарт (открытые)
sudo dnf install mesa-dri-drivers mesa-vulkan-drivers
```

> [!NOTE]
> Для проприетарных драйверов NVIDIA может потребоваться подключение сторонних репозиториев.

---

## 🎨 4. Настройка внешнего вида

### Настройка панели задач

```
1. Правый клик на панели → Добавить на панель
2. Выберите нужные апплеты:
   - Переключатель окон
   - Показ рабочих столов
   - Монитор системы
   - Быстрый запуск
```

### Настройка шрифтов

```bash
# Установка дополнительных шрифтов
sudo dnf install google-noto-sans-fonts google-noto-sans-cjk-fonts \
    liberation-fonts dejavu-sans-fonts

# Улучшение рендеринга шрифтов
cat >> ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
    <edit name="lcdfilter" mode="assign"><const>default</const></edit>
  </match>
</fontconfig>
EOF
```

> [!TIP]
> После настройки шрифтов перезагрузите систему или выполните `fc-cache -fv`.

---

## 📚 5. Установка необходимого ПО

### Офисные приложения

**Р7-Офис**

```bash
# Добавить репозиторий для Р7-Офис
sudo dnf install -y r7-release
# Установить
sudo dnf install -y r7-office
```

**PDF-редактор**

```bash
sudo dnf install okular
```

**Сканер документов**

```bash
sudo dnf install simple-scan
```

> [!NOTE]
> Если Р7-Офис недоступен в репозитории, скачайте установщик с официального сайта: <https://r7-office.ru/download/>

#### 🤖 Автоматическая установка через скрипт

Скрипт для автоматической установки и настройки офисных пакетов в **РЕД ОС**.

📋 **Описание**

Скрипт предоставляет интерактивный интерфейс для выполнения следующих действий:

| № | Компонент | Описание |
|---|-----------|----------|
| 1 | **Информация о системе** | Отображение версии ОС и установленных пакетов |
| 2 | **Настройка DNF** | Оптимизация пакетного менеджера для быстрой загрузки |
| 3 | **Добавление репозиториев** | R7 Office |
| 4 | **Установка пакетов** | LibreOffice, Р7-Офис, МойОфис |
| 5 | **Настройка по умолчанию** | Выбор офисного пакета для открытия файлов |
| 6 | **Итоговый отчёт** | Список установленных пакетов и рекомендации |

🚀 **Быстрый старт**

***Одной командой:***

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-office.sh | sudo bash
```

***Или вручную:***

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-office.sh

# Сделайте исполняемым
chmod +x install-office.sh

# Запустите от root
sudo ./install-office.sh
```

### Браузеры

**Firefox**

```bash
sudo dnf install firefox
```

**Яндекс Браузер**

```bash
# Добавить репозиторий для Яндекс Браузера
sudo dnf install -y yandex-browser-release
# Установить
sudo dnf install yandex-browser-stable
```

**Chromium**

```bash
sudo dnf install chromium
```

### Графические редакторы

```bash
# GIMP
sudo dnf install gimp

# Inkscape (векторная графика)
sudo dnf install inkscape

# Pinta (лёгкий редактор)
sudo dnf install pinta

# Inkscape (векторная графика)
sudo dnf install inkscape

# Shotwell (фотографии)
sudo dnf install shotwell
```

### Мессенджеры

**Telegram** (установка из репозитория GitHub)

```bash
wget https://github.com/teanrus/redos-setup/releases/latest/download/tsetup.tar.xz
tar -xJf tsetup.tar.xz
sudo mkdir -p /opt/telegram
sudo cp -r Telegram/* /opt/telegram/
sudo ln -sf /opt/telegram/Telegram /usr/bin/telegram
sudo chmod +x /opt/telegram/Telegram
rm -rf Telegram tsetup.tar.xz
```

 **Среда** (корпоративный мессенджер)

```bash
wget https://github.com/teanrus/redos-setup/releases/latest/download/sreda.rpm
sudo dnf install -y sreda.rpm
rm -f sreda.rpm
```

**MAX** (национальный мессенджер)

```bash
# Добавить репозиторий
sudo tee /etc/yum.repos.d/max.repo >/dev/null <<'EOF'
[max]
name=MAX Desktop
baseurl=https://download.max.ru/linux/rpm/el/9/x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://download.max.ru/linux/rpm/public.asc
sslverify=1
metadata_expire=300
EOF
# Импортировать GPG-ключ
sudo rpm --import https://download.max.ru/linux/rpm/public.asc
# Установить
sudo dnf clean all
sudo dnf install max
```

**VK Messenger** (установка из репозитория GitHub)

```bash
wget https://github.com/teanrus/redos-setup/releases/latest/download/vk-messenger.rpm
sudo dnf install -y vk-messenger.rpm
rm -f vk-messenger.rpm
```

> [!NOTE]
> Все мессенджеры устанавливаются из официальных источников. Для корпоративного мессенджера "Среда" требуется корпоративный аккаунт.

---

### Установка мессенджеров готовым скриптом

```bash
# Скачать скрипт установки мессенджеров
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh

# Сделать исполняемым
chmod +x install-messengers.sh

# Запустить от имени root
sudo ./install-messengers.sh
```

**Скрипт устанавливает:**

- **Telegram** — популярный мессенджер
- **Среда** — корпоративный мессенджер
- **MAX** — национальный мессенджер
- **VK Messenger** — мессенджер ВКонтакте

> [!TIP]
> Скрипт автоматически скачает последние версии мессенджеров из репозитория GitHub и установит их с подтверждением каждого действия.

---

### Медиаплееры

```bash
# VLC
sudo dnf install vlc

# Audacious (аудио)
sudo dnf install audacious

# Celluloid (видео)
sudo dnf install celluloid
```

### Утилиты

```bash
# Архиваторы
sudo dnf install p7zip p7zip-plugins file-roller

# Редактор реестра (для продвинутых)
sudo dnf install gedit

# Терминал
sudo dnf install tilix

# Менеджер загрузок
sudo dnf install uget
```

> [!TIP]
> Устанавливайте только то ПО, которое действительно нужно — это уменьшит нагрузку на систему.

---

## 🔒 6. Настройка безопасности

### Настройка брандмауэра

```bash
# Проверка статуса
sudo systemctl status firewalld

# Включение брандмауэра
sudo systemctl enable firewalld
sudo systemctl start firewalld

# Разрешить SSH (если нужно)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# Просмотр правил
sudo firewall-cmd --list-all
```

### Настройка автоматических обновлений

```bash
# Установка пакета для автообновлений
sudo dnf install dnf-automatic

# Включение таймера
sudo systemctl enable --now dnf-automatic-install.timer

# Проверка статуса
sudo systemctl status dnf-automatic-install.timer
```

### Резервное копирование паролей

```bash
# Сохранить список установленных пакетов
dnf list installed > ~/backup-installed-packages.txt

# Сохранить настройки репозиториев
cp -r /etc/yum.repos.d/ ~/backup-repos/

# Сохранить список пользователей
cut -d: -f1 /etc/passwd > ~/backup-users.txt
```

> [!NOTE]
> Регулярно создавайте резервные копии важных данных и настроек.

---

## ⚡ 7. Оптимизация производительности

### Очистка системы

```bash
# Очистка кэша DNF
sudo dnf clean all

# Удаление ненужных зависимостей
sudo dnf autoremove

# Очистка старых ядер
sudo dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)

# Очистка журналов
sudo journalctl --vacuum-time=7d
```

### Настройка своп-файла

```bash
# Проверка текущего свопа
free -h
swapon --show

# Создание своп-файла (если нет раздела swap)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Добавление в fstab для постоянного подключения
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Отключение визуальных эффектов

```bash
# Отключить анимации в MATE
gsettings set org.mate.Marco.general reduced-resources true

# Отключить композитинг
gsettings set org.mate.Marco.general compositing-manager false
```

### Настройка энергопотребления (для ноутбуков)

```bash
# Установка утилит энергосбережения
sudo dnf install tlp tlp-rdw

# Включение TLP
sudo systemctl enable tlp
sudo systemctl start tlp

# Проверка статуса
sudo tlp-stat -s
```

> [!TIP]
> TLP автоматически оптимизирует энергопотребление — дополнительная настройка не требуется.

---

## 🎯 8. Лайфхаки

### Быстрая настройка системы одним скриптом

```bash
#!/bin/bash
# Сохраните как ~/setup.sh и выполните после установки

echo "Обновление системы..."
sudo dnf upgrade --refresh -y

echo "Настройка репозиториев..."
sudo dnf install -y r7-release
sudo dnf install -y yandex-browser-release

# Добавление репозитория MAX
cat > /tmp/max.repo << 'EOF'
[max]
name=MAX Desktop
baseurl=https://download.max.ru/linux/rpm/el/9/x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://download.max.ru/linux/rpm/public.asc
EOF
sudo cp /tmp/max.repo /etc/yum.repos.d/
sudo rpm --import https://download.max.ru/linux/rpm/public.asc

echo "Установка кодеков..."
sudo dnf install ffmpeg gstreamer1-plugins-base -y

echo "Установка Р7-Офис..."
sudo dnf install r7-office -y

echo "Установка Яндекс Браузера..."
sudo dnf install yandex-browser-stable -y

echo "Установка утилит..."
sudo dnf install vim git curl wget htop neofetch -y

echo "Очистка..."
sudo dnf clean all

echo "Готово! Перезагрузите систему."
```

> [!TIP]
> Создайте свой скрипт с набором нужных вам пакетов для быстрой настройки новых установок.

---

### Проверка установленных пакетов

```bash
# Количество установленных пакетов
dnf list installed | wc -l

# Последние установленные пакеты
rpm -qa --last | head -20

# Поиск пакета по имени
dnf list installed | grep -i "название"
```

> [!TIP]
> Сохраните список пакетов после настройки — пригодится при следующей установке.

---

### Быстрый доступ к настройкам

```bash
# Открыть настройки системы
mate-control-center

# Открыть настройки дисплея
mate-display-properties

# Открыть настройки клавиатуры
mate-keyboard-properties

# Открыть настройки мыши
mate-mouse-properties
```

> [!TIP]
> Добавьте ярлыки на панель для быстрого доступа к часто используемым настройкам.

---

### Создание точек восстановления

```bash
# Установка Timeshift
sudo dnf install timeshift

# Запуск
sudo timeshift-gtk

# Настройка расписания:
# - Ежедневные снимки: 5
# - Еженедельные: 3
# - Ежемесячные: 2
```

> [!TIP]
> Создавайте точку восстановления перед установкой крупного ПО или обновлением ядра.

---

### Настройка автозапуска программ

```bash
# Просмотр автозагрузки
ls ~/.config/autostart/
ls /etc/xdg/autostart/

# Отключить автозапуск программы
cp /etc/xdg/autostart/программа.desktop ~/.config/autostart/
echo "Hidden=true" >> ~/.config/autostart/программа.desktop

# Добавить свою программу в автозапуск
cat >> ~/.config/autostart/myapp.desktop << 'EOF'
[Desktop Entry]
Type=Application
Exec=/путь/к/программе
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Моя программа
EOF
```

> [!NOTE]
> Не отключайте системные службы — это может нарушить работу окружения.

---

### Мониторинг ресурсов в реальном времени

```bash
# Установка htop
sudo dnf install htop

# Запуск
htop

# Установка glances (более подробный мониторинг)
sudo dnf install glances
glances
```

> [!TIP]
> Добавьте `htop` в автозапуск терминала для постоянного мониторинга.

---

### Быстрая очистка места на диске

```bash
# Анализ занятого места
du -sh /* 2>/dev/null | sort -hr | head -10

# Поиск больших файлов
find ~ -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Очистка корзины
rm -rf ~/.local/share/Trash/*

# Очистка кэша пользователя
rm -rf ~/.cache/*
```

> [!WARNING]
> Будьте осторожны при удалении файлов — проверяйте, что именно удаляете.

---

### Настройка общего доступа к файлам

```bash
# Установка Samba
sudo dnf install samba samba-client

# Настройка общей папки
sudo mkdir -p /srv/samba/share
sudo chmod 777 /srv/samba/share

# Добавление в конфигурацию Samba
cat >> /etc/samba/smb.conf << 'EOF'

[share]
    path = /srv/samba/share
    browseable = yes
    writable = yes
    guest ok = yes
    read only = no
EOF

# Перезапуск службы
sudo systemctl restart smb
sudo systemctl enable smb
```

> [!NOTE]
> Для безопасного доступа настройте аутентификацию пользователей Samba.

---

### Настройка удалённого рабочего стола

```bash
# Установка xrdp
sudo dnf install xrdp

# Включение службы
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Открыть порт в брандмауэре
sudo firewall-cmd --permanent --add-port=3389/tcp
sudo firewall-cmd --reload

# Проверка статуса
sudo systemctl status xrdp
```

> [!TIP]
> Подключайтесь через RDP-клиент (Windows: mstsc, Linux: remmina).

---

### Резервное копирование настроек пользователя

```bash
# Создание архива с настройками
tar -czvf ~/backup-settings-$(date +%Y%m%d).tar.gz \
    ~/.config \
    ~/.mozilla \
    ~/.ssh \
    ~/.gnupg \
    ~/.bashrc \
    ~/.profile

# Восстановление настроек
tar -xzvf ~/backup-settings-DATE.tar.gz -C ~/
```

> [!TIP]
> Храните резервные копии на внешнем носителе или в облаке.

---

### Настройка горячих клавиш

```
Система → Настройки → Клавиатура → Комбинации клавиш

Полезные комбинации:
- Ctrl+Alt+T — терминал
- Alt+F2 — запустить программу
- Win+E — файловый менеджер
- Win+D — показать рабочий стол
- Alt+Tab — переключение окон
- Ctrl+Alt+Str — скриншот экрана
```

> [!TIP]
> Настройте комбинации под себя — это ускорит работу.

---

### Проверка состояния системы

```bash
# Информация о системе
neofetch

# Версия ядра
uname -r

# Загруженные модули
lsmod

# Статус служб
systemctl list-units --type=service --state=running

# Использование диска
df -h

# Использование памяти
free -h
```

> [!TIP]
> Добавьте `neofetch` в автозапуск терминала для быстрого просмотра информации о системе.

---

### Настройка ночного режима

```bash
# Включение Redshift (фильтр синего света)
sudo dnf install redshift redshift-gtk

# Автозапуск
cp /etc/xdg/autostart/redshift-gtk.desktop ~/.config/autostart/

# Настройка (опционально)
mkdir -p ~/.config/redshift
cat > ~/.config/redshift/redshift.conf << 'EOF'
[redshift]
temp-day=5700
temp-night=3500

[manual]
lat=55.75
lon=37.61
EOF
```

> [!TIP]
> Redshift автоматически регулирует цветовую температуру экрана в зависимости от времени суток.

---

### Быстрый доступ к часто используемым командам

```bash
# Добавить алиасы в ~/.bashrc
cat >> ~/.bashrc << 'EOF'

# Быстрые команды
alias update='sudo dnf upgrade --refresh -y'
alias install='sudo dnf install -y'
alias remove='sudo dnf remove -y'
alias search='dnf search'
alias clean='sudo dnf clean all'
alias h='history'
..='cd ..'
...='cd ../..'
EOF

# Применить изменения
source ~/.bashrc
```

> [!TIP]
> Создавайте собственные алиасы для команд, которые используете часто.

---

## 🔗 Ссылки

- [Официальный сайт РЕД ОС](https://redos.red-soft.ru/)
- [Документация РЕД ОС](https://redos.red-soft.ru/base/redos-7_3/)
- [Р7-Офис](https://r7-office.ru/)
- [MAX (национальный мессенджер)](https://max.ru/)
- [Яндекс Браузер](https://browser.yandex.ru/)
- [Telegram](https://telegram.org/)
- [VK Мессенджер](https://vk.com/)
- [Скрипт установки мессенджеров](https://github.com/teanrus/redos-lifehacks/blob/main/scripts/install/install-messengers.md)

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Права** | root (для установки пакетов и настройки системы) |
| **Интернет** | требуется для загрузки пакетов и обновлений |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x некоторые репозитории и пакеты могут отличаться. Рекомендуется проверить доступность репозиториев перед выполнением скриптов.

---

## 📘 Энциклопедия (Wiki)

Подробные пояснения принципов работы:

- [🔄 Первые шаги после установки](https://github.com/teanrus/redos-lifehacks/wiki/First-Steps) — как работает `dnf upgrade --refresh`, репозитории RPM, кодеки ffmpeg/GStreamer, firewalld, swap, TLP, рендеринг шрифтов
