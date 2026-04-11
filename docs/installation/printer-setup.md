# Настройка принтера через CUPS

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📖 Оглавление

1. [Установка и запуск CUPS](#-1-установка-и-запуск-cups)
2. [Веб-интерфейс управления](#-2-веб-интерфейс-управления)
3. [Добавление принтера через командную строку](#-3-добавление-принтера-через-командную-строку)
4. [Установка драйверов](#-4-установка-драйверов)
5. [Настройка сетевого принтера](#-5-настройка-сетевого-принтера)
6. [Диагностика и логи](#-6-диагностика-и-логи)
7. [Полезные команды](#-7-полезные-команды)

---

## 🛠️ 1. Установка и запуск CUPS

```bash
# Установка пакетов
sudo dnf install cups cups-client cups-filters

# Включение и запуск службы
sudo systemctl enable cups
sudo systemctl start cups

# Проверка статуса
systemctl status cups
```

> **Зачем:** CUPS (Common Unix Printing System) — стандартная система печати в Linux.

---

## 🌐 2. Веб-интерфейс управления

Откройте в браузере: `http://localhost:631`

### Разрешите доступ из сети (опционально):
```bash
sudo cupsctl --remote-any
sudo systemctl restart cups
```

> **Зачем:** Управление принтерами с других компьютеров в сети.

### Добавление пользователя в группу lpadmin:
```bash
sudo usermod -aG lpadmin $USER
```

> **Зачем:** Для доступа к веб-интерфейсу без ввода root-пароля.

---

## 🖨️ 3. Добавление принтера через командную строку

```bash
# Поиск доступных принтеров
lpinfo -v

# Добавление локального USB-принтера
sudo lpadmin -p HP_LaserJet -E -v usb://HP/LaserJet%20Pro%20M404?serial=PHCB123456 -m driverless

# Установка принтера по умолчанию
sudo lpoptions -d HP_LaserJet

# Проверка очереди
lpstat -p
```

> **Зачем:** Быстрая настройка без веб-интерфейса, удобно для скриптов.

---

## 📦 4. Установка драйверов

### Для популярных брендов:
```bash
# HP (HPLIP)
sudo dnf install hplip hplip-gui

# Canon
sudo dnf install canon-cups-drivers

# Epson
sudo dnf install epson-escpr-driver

# Brother
sudo dnf install brother-cups-drivers
```

### Универсальный драйвер (для новых принтеров):
```bash
# Driverless (IPP Everywhere, AirPrint)
sudo dnf install cups-filters
```

> **Зачем:** Driverless работает с большинством современных принтеров без проприетарных драйверов.

---

## 🌍 5. Настройка сетевого принтера

```bash
# Поиск сетевых принтеров
nmap -p 9100,631 192.168.1.0/24

# Добавление по IP
sudo lpadmin -p NetworkPrinter -E -v ipp://192.168.1.100/ipp/print -m driverless

# Добавление по протоколу AppSocket (порт 9100)
sudo lpadmin -p SocketPrinter -E -v socket://192.168.1.100:9100 -m driverless

# Проверка доступности
ping 192.168.1.100
```

> **Зачем:** Сетевые принтеры доступны всем пользователям в локальной сети.

---

## 🔍 6. Диагностика и логи

```bash
# Просмотр логов CUPS
sudo tail -f /var/log/cups/error_log

# Детальный лог (временно увеличьте уровень)
sudo cupsctl LogLevel=debug
sudo systemctl restart cups

# Проверка очереди печати
lpq

# Отмена всех заданий
cancel -a

# Тестовая страница
lp -d HP_LaserJet /usr/share/cups/data/default.pdf
```

> **Зачем:** Быстрое выявление проблем с печатью.

---

## ⚡ 7. Полезные команды

| Команда | Описание |
|---------|----------|
| `lpstat -t` | Полный статус системы печати |
| `lpoptions -l` | Параметры текущего принтера |
| `cancel <job-id>` | Отмена задания печати |
| `lpadmin -x <printer>` | Удаление принтера |
| `cupsdisable <printer>` | Временная остановка принтера |
| `cupsenable <printer>` | Включение принтера |
| `lpinfo -m` | Список доступных драйверов (PPD) |

---

## 🎯 Лайфхаки

### 🔹 Быстрый сброс очереди печати
```bash
cancel -a && sudo systemctl restart cups
```

### 🔹 Печать PDF из командной строки
```bash
lp -d <printer> document.pdf
```

### 🔹 Автоматическая установка принтера в скрипте
```bash
#!/bin/bash
PRINTER_NAME="Office_HP"
PRINTER_URI="usb://HP/LaserJet?serial=ABC123"
DRIVER="driverless"

sudo lpadmin -p $PRINTER_NAME -E -v $PRINTER_URI -m $DRIVER
sudo lpoptions -d $PRINTER_NAME
echo "Принтер настроен!"
```

### 🔹 Если принтер «завис»
```bash
# Очистка спулера
sudo rm -rf /var/spool/cups/*
sudo systemctl restart cups
```

### 🔹 Проверка поддержки driverless
```bash
ippfind
```
Если принтер найден — он поддерживает современный протокол IPP и работает без драйверов.

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Система печати** | CUPS, cups-filters |
| **Драйверы** | HPLIP, driverless (IPP), проприетарные |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x CUPS обычно установлен по умолчанию. Для принтеров без driverless-поддержки (старые модели) может потребоваться установка проприетарных PPD-файлов.

---

## 📘 Энциклопедия (Wiki)

Подробные пояснения принципов работы:

- [🖨️ Настройка принтера через CUPS](https://github.com/teanrus/redos-lifehacks/wiki/Printer-CUPS-Setup) — архитектура CUPS, фильтры, протоколы IPP/AppSocket/LPD, параметры `lpadmin`, диагностика и логи
