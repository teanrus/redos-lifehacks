# Автоматическая установка корпоративных обоев рабочего стола

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![RED OS](https://img.shields.io/badge/RED%20OS-7.3%20%7C%208.x-b30000?style=for-the-badge)](https://redos.red-soft.ru/)
[![RHEL](https://img.shields.io/badge/RHEL-8%20%7C%209-ee0000?style=for-the-badge)](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux)
[![Fedora](https://img.shields.io/badge/Fedora-39%20%7C%2040-0B57A4?style=for-the-badge)](https://fedoraproject.org/)
[![CentOS](https://img.shields.io/badge/CentOS-Stream%208%20%7C%209-262477?style=for-the-badge)](https://www.centos.org/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

>Скрипт `docs/desktop/setup-wallpaper.sh` предназначен для автоматической установки корпоративных обоев рабочего стола из SMB-шары (сетевой папки Windows) в Linux-системах с последующей **блокировкой возможности изменения** обоев пользователями. Поддерживает основные графические окружения: MATE, GNOME, XFCE, KDE Plasma.
>
> **Важно:** Скрипт требует запуска с правами root (через `sudo`).

## Основные функции

1. **Монтирование SMB-шары** с корпоративными обоями.
2. **Копирование файла обоев** в системный каталог `/usr/share/wallpapers/`.
3. **Защита файла от изменений** (установка атрибута `chattr +i`).
4. **Автоматическое определение** графического окружения пользователя.
5. **Блокировка настроек обоев** через штатные механизмы lockdown для каждого DE.
6. **Создание автозапуска** для применения обоев при каждом входе пользователя.
7. **Настройка для всех существующих пользователей** системы.

---

## Настраиваемые параметры (в начале скрипта)

| Переменная    | Описание                                                                          | Пример                     |
| ------------- | --------------------------------------------------------------------------------- | -------------------------- |
| `SMB_SERVER`  | IP-адрес или имя SMB-сервера                                                      | `192.168.22.11`            |
| `SMB_SHARE`   | Имя сетевой папки (шары)                                                          | `Share`                    |
| `SMB_FOLDER`  | Каталог внутри шары                                                               | `backgrounds`              |
| `SMB_FILE`    | Имя файла обоев                                                                   | `corporate-wallpaper.jpg`  |
| `SMB_USER`    | Имя пользователя SMB                                                              | `user` или `domain\\user`  |
| `SMB_PASS`    | Пароль пользователя SMB                                                           | `passwd`                   |
| `DESKTOP_ENV` | Принудительное указание окружения (`AUTO`, `GNOME`, `KDE`, `XFCE`, `MATE`, `ALL`) | `AUTO`                     |

Параметры монтирования:

- `LOCAL_WALLPAPER_DIR` – `/usr/share/wallpapers`
- `LOCAL_WALLPAPER_FILE` – путь к итоговому файлу обоев
- `MOUNT_POINT` – временная точка монтирования (`/mnt/smb_temp`)

---

## Логика работы

### 1. Проверка окружения и зависимостей

- Скрипт проверяет, что запущен от `root`.
- Проверяет наличие обязательных команд: `mount`, `umount`, `cp`, `chmod`, `sed`, `awk`.
- Убеждается, что установлен пакет `cifs-utils` (для монтирования SMB). При отсутствии устанавливает через `dnf`.

### 2. Определение графического окружения (DE)

Скрипт последовательно пытается определить DE, если `DESKTOP_ENV` установлен в `AUTO` (или не задан). Используются методы:

- **Переменные окружения** (`XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION`, `GDMSESSION`).
- **loginctl** – анализ активных сессий.
- **Анализ процессов** – поиск `gnome-shell`, `plasmashell`, `mate-session`, `xfce4-session`.
- **Проверка установленных пакетов** (через `rpm`).

Результат нормализуется к одному из значений: `GNOME`, `KDE`, `MATE`, `XFCE`, `ALL`, `UNKNOWN`.

### 3. Монтирование SMB-шары

Создается временный каталог `/mnt/smb_temp`.  
Выполняется монтирование с использованием протокола **CIFS (версия 3.0)**.

Возможны три варианта аутентификации:

- С логином и паролем.
- Только с логином (без пароля).
- Гостевой доступ (`guest`).

### 4. Копирование файла обоев

Файл забирается по пути `${MOUNT_POINT}/${SMB_FOLDER}/${SMB_FILE}` и копируется в: `/usr/share/wallpapers/corporate-wallpaper.jpg`

Устанавливаются права: `644`, владелец `root:root`.  
Если доступна команда `chattr`, на файл накладывается запрет на изменение (`+i`).

### 5. Создание скрипта применения обоев

Создается универсальный скрипт `/usr/local/bin/apply-corporate-wallpaper.sh`, который:

- Определяет текущее DE пользователя (через переменные окружения).
- Выполняет применение обоев в зависимости от DE:
  - **KDE** – через `qdbus` и JavaScript-оценщик Plasma.
  - **GNOME** – через `gsettings` (устанавливает `picture-uri`, `picture-uri-dark`, `picture-options`).
  - **MATE** – через `gsettings` (ключи `org.mate.background`).
  - **XFCE** – через `xfconf-query` (устанавливает `last-image`, `image-path`, `image-style`).

Скрипт выполняется при старте сессии через **автозапуск**.

### 6. Настройка системного автозапуска

Создается `.desktop`-файл:

- `/etc/xdg/autostart/corporate-wallpaper.desktop`
- Копируется в `/etc/skel/.config/autostart/` (для новых пользователей).

При входе в систему автоматически запускается `apply-corporate-wallpaper.sh`.

### 7. Блокировка изменения обоев (lockdown)

В зависимости от обнаруженного (или заданного) DE применяются разные механизмы блокировки:

#### GNOME

- Создается профиль dconf (`/etc/dconf/profile/user`).
- Добавляется системная база `local`.
- Кладется схема `/etc/dconf/db/local.d/00-corporate-wallpaper` с фиксированными настройками.
- Блокируются ключи через `/etc/dconf/db/local.d/locks/corporate-wallpaper`.
- Выполняется `dconf update`.

#### MATE

- Аналогично GNOME, но с ключами `org.mate.background`.

#### XFCE

- Включается kiosk-режим: `/etc/xdg/xfce4/kiosk/kioskrc` запрещает `CustomizeBackdrop=NONE`.
- Создается предустановленный XML-конфиг `xfce4-desktop.xml` с фиксированным путем к обоям.

#### KDE Plasma

- Редактируется `/etc/xdg/kdeglobals` – добавляются секции:
  - `[KDE Action Restrictions]` – запрет изменения обоев через интерфейс.
  - `[Wallpaper]` – фиксированный путь к файлу.
- Создается профиль блокировки `/etc/kde-profile/locked-profile`.

### 8. Настройка для существующих пользователей

Скрипт перебирает все каталоги в `/home/*`, копирует в каждый `.config/autostart/corporate-wallpaper.desktop` и устанавливает корректного владельца.

---

## Результат выполнения

После успешного выполнения скрипта:

- Файл обоев защищен от удаления/изменения.
- Настройки обоев зафиксированы на уровне системы.
- Пользователь **не может сменить обои** через стандартные настройки DE.
- При каждом входе в систему обои принудительно устанавливаются (на случай обходных путей).
- Новые пользователи наследуют настройки.

---

## Пример запуска

### Автоматическое определение окружения

```bash
sudo ./setup-wallpaper.sh
```

Принудительная установка для GNOME

```bash
sudo DESKTOP_ENV=GNOME ./setup-wallpaper.sh
```

Установка для всех поддерживаемых DE

```bash
sudo DESKTOP_ENV=ALL ./setup-wallpaper.sh
```

Требования к системе

- ОС: Linux (проверялось на семействе Red Hat, но подойдет любой дистрибутив с cifs-utils, bash, mount).
- Пакеты: cifs-utils, dconf (для GNOME/MATE), xfconf (для XFCE), qdbus (для KDE).
- Сеть: Доступ к SMB-серверу по порту 445 (CIFS/SMB).
- Права: root.

Возможные ошибки и их обработка

| Ситуация                     | Действие скрипта                                                       |
| :--------------------------- | :--------------------------------------------------------------------- |
| Нет cifs-utils               | Устанавливает через dnf (только для RPM-based систем).                 |
| Файл обоев не найден в шаре  | Ошибка, скрипт завершается.                                            |
| Не удалось смонтировать шару | Ошибка монтирования, скрипт завершается.                               |
| chattr +i недоступен         | Выводит предупреждение, продолжает работу.                             |
| dconf не установлен          | Выводит предупреждение, но автозапуск остаётся.                        |
| Не удалось определить DE     | Применяет настройки для всех DE и использует универсальный автозапуск. |

>Примечания безопасности
>
>!!! **Пароль SMB хранится в открытом виде внутри скрипта**. Рекомендуется:
>
>- Использовать гостевой доступ (если возможно).
>- Либо вынести пароль в отдельный защищенный файл.
>
>Скрипт изменяет системные файлы и `dconf`. Рекомендуется тестирование в небоевой среде.
>
>Снятие блокировки выполняется вручную (см. раздел ниже).

## Снятие блокировки (откат изменений)

Для возврата возможности менять обои необходимо выполнить следующие действия:

### Снять защиту с файла обоев

```bash
sudo chattr -i /usr/share/wallpapers/corporate-wallpaper.jpg
```

### Удалить файл обоев (опционально)

```bash
sudo rm -f /usr/share/wallpapers/corporate-wallpaper.jpg
```

### Удалить скрипт автозапуска

```bash
sudo rm -f /usr/local/bin/apply-corporate-wallpaper.sh
```

### Удалить .desktop-файлы автозапуска

```bash
sudo rm -f /etc/xdg/autostart/corporate-wallpaper.desktop
sudo rm -f /etc/skel/.config/autostart/corporate-wallpaper.desktop

# Для существующих пользователей
for user_home in /home/*; do
    rm -f "${user_home}/.config/autostart/corporate-wallpaper.desktop"
done
```

### Откатить настройки GNOME/MATE (dconf)

```bash
sudo rm -f /etc/dconf/db/local.d/00-corporate-wallpaper
sudo rm -f /etc/dconf/db/local.d/01-corporate-wallpaper-mate
sudo rm -f /etc/dconf/db/local.d/locks/corporate-wallpaper
sudo rm -f /etc/dconf/db/local.d/locks/corporate-wallpaper-mate
sudo dconf update
```

### Откатить настройки XFCE

```bash
sudo rm -f /etc/xdg/xfce4/kiosk/kioskrc
sudo rm -f /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
```

### Откатить настройки KDE Plasma

```bash
# Восстановить оригинальный kdeglobals (если есть бэкап)
if [ -f /etc/xdg/kdeglobals.backup ]; then
    sudo cp /etc/xdg/kdeglobals.backup /etc/xdg/kdeglobals
fi

# Удалить профиль блокировки
sudo rm -f /etc/kde-profile/locked-profile
```

### Очистить временные файлы (опционально)

```bash
sudo rm -rf /mnt/smb_temp
```

>Отказ от ответственности
>
>Скрипт предоставляется "как есть". Автор не несет ответственности за возможные проблемы при использовании, включая потерю данных или некорректную работу системы. Рекомендуется создавать резервные копии важных конфигурационных файлов перед запуском.
<!--  -->

- Поддерживаемые DE: MATE, GNOME, XFCE, KDE Plasma
- Тестирование: Red Hat Enterprise Linux / Fedora / CentOS / РЕД ОС
