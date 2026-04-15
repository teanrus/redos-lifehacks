# usb-guard.sh — Управление блокировкой USB-накопителей

> 📋 **Описание:** Скрипт для управления блокировкой USB-накопителей на РЕД ОС. Реализует два метода: UDISKS_IGNORE (запрет автомонтирования) и authorized (полное отключение на уровне шины USB). Поддерживает создание белого списка доверенных устройств.
>
> 👤 **Автор:** pagrishaevich

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red?style=for-the-badge)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green?style=for-the-badge)](https://redos.red-soft.ru/)

---

## Методы блокировки

### UDISKS_IGNORE (рекомендуется)

Запрещает автомонтирование USB-накопителей через udev-правила. Устройство видно в системе, но автоматическое монтирование запрещено.

```bash
ENV{ID_USB_DRIVER}=="usb-storage",ENV{UDISKS_IGNORE}="1"
ENV{ID_USB_DRIVER}=="uas",ENV{UDISKS_IGNORE}="1"    # USB 3.0
```

### authorized (полная блокировка)

Полностью отключает устройство на уровне шины USB через запись в `/sys/bus/usb/devices/*/authorized`. Устройство невидимо для системы.

Скрипт создаёт `/usr/bin/remove_usb.sh`, который вызывается из udev-правила:

```bash
ACTION!="add", GOTO="dont_remove_usb"
ENV{ID_USB_DRIVER}!="usb-storage", GOTO="dont_remove_usb"
ATTRS{serial}=="...", GOTO="dont_remove_usb"
ENV{ID_USB_DRIVER}=="usb-storage", RUN+="/bin/sh -c '/usr/bin/remove_usb.sh $devpath'"
LABEL="dont_remove_usb"
```

---

## Требования и зависимости

| Зависимость | Обязательная | Описание |
|-------------|-------------|----------|
| bash | ✅ | Интерпретатор (4.0+) |
| udev (udevadm) | ✅ | Управление правилами udev |
| coreutils | ✅ | Базовые утилиты |
| grep | ✅ | Поиск в выводе и файлах |
| sed | ✅ | Редактирование файлов |
| mktemp | ✅ | Создание временных файлов |
| lsusb / usbutils | ❌ | Автоопределение USB 3.0 |

---

## Использование

**Запуск:**

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh -o usb-guard.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-guard.sh.sha256 -o usb-guard.sh.sha256
sha256sum -c usb-guard.sh.sha256
sudo bash usb-guard.sh
```

**Команды:**

```bash
# Запуск интерактивного меню
sudo ./usb-guard.sh

# Сканировать USB-устройства
sudo ./usb-guard.sh --scan

# Добавить устройство в белый список (UDISKS_IGNORE)
sudo ./usb-guard.sh --whitelist

# Добавить устройство в белый список (authorized)
sudo ./usb-guard.sh --whitelist-auth

# Блокировать все USB-накопители
sudo ./usb-guard.sh --block-all

# Разблокировать все USB-накопители
sudo ./usb-guard.sh --unblock

# Показать текущие правила и статус
sudo ./usb-guard.sh --show

# Показать справку
sudo ./usb-guard.sh --help
```

---

## Интерактивное меню

```
╔═══════════════════════════════════════════════════╗
║       Управление USB-накопителями (РЕД ОС 8)      ║
╚═══════════════════════════════════════════════════╝

  1) Сканировать USB-устройства
  2) Добавить устройство в белый список (UDISKS_IGNORE)
  3) Добавить устройство в белый список (authorized)
  4) Блокировать все USB (UDISKS_IGNORE)
  5) Разблокировать все USB
  6) Просмотреть текущие правила
  7) Выход
```

---

## Командные аргументы

| Аргумент | Описание |
|----------|----------|
| `--scan` | Сканировать USB-устройства |
| `--whitelist` | Добавить устройство в белый список (UDISKS_IGNORE) |
| `--whitelist-auth` | Добавить устройство в белый список (authorized) |
| `--block-all` | Блокировать все USB-накопители (UDISKS_IGNORE) |
| `--unblock` | Разблокировать все USB-накопители |
| `--show` | Показать текущие правила и статус |
| `--help`, `-h` | Показать справку |

---

## Конфигурация и файлы

| Файл | Описание |
|------|----------|
| `/etc/udev/rules.d/99-usb.rules` | Правила блокировки USB |
| `/usr/bin/remove_usb.sh` | Скрипт блокировки (метод authorized) |

### Атрибуты идентификации устройств

| Атрибут | Надёжность | Описание |
|---------|-----------|----------|
| Serial | ★★★★★ | Уникален для каждого устройства |
| Product | ★★★ | Одинаков для устройств одной модели |
| bMaxPower | ★★ | Дополнительный атрибут |

---

## Порядок работы

### Сценарий: Разрешить только конкретные USB-флешки

1. **Сканировать устройства** (`--scan` или пункт 1)

   Подключить доверенные флешки и выполнить сканирование. Скрипт соберёт атрибуты каждого устройства.

2. **Добавить в белый список** (`--whitelist` или `--whitelist-auth`)

   Выбрать доверенные устройства из списка. Рекомендуется использовать атрибут `Serial` как наиболее надёжный идентификатор.

3. **Заблокировать остальные** (`--block-all` — опционально)

   Если нужно применить блокировку немедленно.

### Сравнение методов

| Характеристика | UDISKS_IGNORE | authorized |
|----------------|---------------|------------|
| **Видимость устройства** | Видно в системе | Полностью скрыто |
| **Возможность ручного монтирования** | Да | Нет |
| **Уровень блокировки** | Мягкий | Строгий |
| **Дополнительные файлы** | Не требует | Требует `remove_usb.sh` |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **Ядро** | 5.15+ (7.x), 6.1+ (8.x); `authorized` — ядро 2.6.32+ |
| **Система инициализации** | systemd 239+, udev 170+ |
| **Права** | root (все операции: udev-правила, sysfs) |
| **Зависимости** | bash 4.0+, udev (udevadm), coreutils, grep, sed, mktemp |
| **Опционально** | lsusb / usbutils (автоопределение USB 3.0) |
| **Скрипт** | usb-guard.sh (bash 4.0+) |
| **Файлы** | `/etc/udev/rules.d/99-usb.rules`, `/usr/bin/remove_usb.sh` |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x (может работать на других дистрибутивах с systemd/udev: Fedora, RHEL, CentOS, Ubuntu, Debian, Astra Linux, Alt Linux, openSUSE, Arch) |

> [!note]
> Для работы с udev-правилами и записи в `/sys/bus/usb/devices/*/authorized` необходимы права root.
> В РЕД ОС 7.x версия udev может быть старее, но синтаксис `ENV{}`, `ATTRS{}`, `RUN+=` поддерживается.
> Метод `authorized` может не работать в виртуальных машинах (VMware, VirtualBox) для виртуальных USB-контроллеров — в этом случае используйте метод `UDISKS_IGNORE`.

### Совместимость дистрибутивов

| Дистрибутив | Версия | Статус | Пакет usbutils | Примечание |
|-------------|--------|--------|----------------|------------|
| РЕД ОС 8 | Все | ✅ | dnf install usbutils | Целевая платформа |
| РЕД ОС 7.3 | 7.x | ✅ | dnf install usbutils | older udev, но совместим |
| Astra Linux SE | 1.7+ | ✅ | apt install usbutils | — |
| Ubuntu | 20.04+ | ✅ | apt install usbutils | — |
| Debian | 11+ | ✅ | apt install usbutils | — |
| CentOS / RHEL | 8+ | ✅ | dnf install usbutils | — |
| CentOS / RHEL | 7 | ✅ | yum install usbutils | older systemd/udev |
| Fedora | 33+ | ✅ | dnf install usbutils | — |
| Arch Linux | Текущий | ✅ | pacman -S usbutils | — |
| openSUSE | 15+ | ✅ | zypper install usbutils | — |
| ALT Linux | 10+ | ✅ | apt-get install usbutils | — |

### Известные ограничения

- **Виртуальные машины:** файл `authorized` может отсутствовать для виртуальных USB-контроллеров (VMware, VirtualBox). Метод `UDISKS_IGNORE` работает штатно.
- **Контейнеры (LXC/Docker):** скрипт требует запуска на хост-системе — доступ к `/sys/bus/usb/devices/` и `udevadm` в контейнере ограничен.
- **Системы без systemd:** в Devuan, Alpine и аналогичных может потребоваться ручной перезапуск udev: `service udev restart`.

---

## Особенности

- Автоматическое определение USB 3.0 и добавление соответствующих правил
- Поддержка добавления правил к существующим без перезаписи
- Проверка дубликатов при добавлении новых правил
- Визуальная индикация статуса каждого устройства
- Возможность выбора между мягким и строгим методом блокировки
- Гибкая настройка атрибутов идентификации
- Система бэкапов для безопасного изменения правил
