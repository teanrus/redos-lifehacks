# Настройка Wi-Fi в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📚 Лайфхаки по настройке Wi-Fi для ноутбуков

### 📖 Оглавление

| № | Раздел | Описание |
|---|--------|----------|
| 1 | [Проверка Wi-Fi адаптера](#1-проверка-wi-fi-адаптера) | Диагностика оборудования |
| 2 | [Включение Wi-Fi (rfkill)](#2-включение-wi-fi-rfkill) | Снятие блокировки адаптера |
| 3 | [Установка драйверов](#3-установка-драйверов) | Драйверы для разных чипсетов |
| 4 | [NetworkManager](#4-networkmanager) | Управление через NetworkManager |
| 5 | [Подключение к сети](#5-подключение-к-wi-fi-сети) | Базовое подключение |
| 6 | [Статический IP](#6-настройка-статического-ip) | Ручная настройка IP |
| 7 | [Настройка DNS](#7-настройка-dns) | DNS серверы |
| 8 | [Автоподключение](#8-настройка-автоподключения) | Автоматическое подключение |
| 9 | [Точка доступа](#9-создание-точки-доступы-hotspot) | Режим точки доступа |
| 10 | [Энергопотребление](#10-оптимизация-энергопотребления) | Настройки питания |
| 11 | [Роуминг](#11-настройка-роуминга) | Параметры роуминга |
| 12 | [Диагностика](#12-диагностика-проблем) | Решение проблем |
| 13 | [Скрипт подключения](#13-скрипт-быстрого-подключения) | Быстрое подключение |
| 14 | [Полезные команды](#14-полезные-команды-nmcli) | Справочник команд |

---

### 1. Проверка Wi-Fi адаптера

```bash
# Проверка наличия Wi-Fi устройства
lspci | grep -i "wireless\|network"
lsusb | grep -i "wifi\|wireless"

# Проверка интерфейсов
ip link show
iwconfig

# Информация о Wi-Fi адаптере
lspci -vv -s $(lspci | grep -i wireless | cut -d' ' -f1)
```

> **Зачем:** Определение модели адаптера для установки правильных драйверов.

---

### 2. Включение Wi-Fi (rfkill)

```bash
# Проверка блокировки
rfkill list all
rfkill list wifi

# Снятие блокировки
rfkill unblock all
rfkill unblock wifi

# Проверка состояния
rfkill list

# Включение через NetworkManager
nmcli radio wifi on
nmcli radio wifi off

# Статус
nmcli radio all
```

> **Зачем:** Снятие программной блокировки Wi-Fi адаптера (часто бывает после установки ОС).

---

### 3. Установка драйверов

```bash
# Intel WiFi
sudo dnf install -y iwlwifi-firmware
sudo modprobe -r iwlwifi && sudo modprobe iwlwifi

# Realtek WiFi
sudo dnf install -y rtl8188fu-firmware rtl8192eu-firmware rtl8723de-firmware

# Atheros/Qualcomm
sudo dnf install -y ath10k-firmware

# Broadcom
sudo dnf install -y broadcom-wl broadcom-wl-kmod
sudo modprobe -r wl && sudo modprobe wl

# Проверка загруженных модулей
lsmod | grep -i "wifi\|wl\|iwl\|ath\|rtl"

# Информация о драйвере
ethtool -i wlan0
```

> **Зачем:** Установка микрокода и драйверов для конкретной модели Wi-Fi адаптера.

---

### 4. NetworkManager

```bash
# Проверка статуса
systemctl status NetworkManager
systemctl is-active NetworkManager

# Запуск и автозагрузка
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
sudo systemctl restart NetworkManager

# Включение Wi-Fi
nmcli radio wifi on

# Разрешения
nmcli general permissions

# Настройки NetworkManager
ls -la /etc/NetworkManager/conf.d/
```

> **Зачем:** NetworkManager — основной инструмент управления сетью в РЕД ОС.

---

### 5. Подключение к Wi-Fi сети

```bash
# Сканирование сетей
nmcli device wifi rescan
nmcli device wifi list

# Подключение к сети с паролем
nmcli device wifi connect "MyWiFi" password "mypassword"

# Подключение к открытой сети
nmcli device wifi connect "OpenWiFi"

# Подключение с указанием имени подключения
nmcli device wifi connect "MyWiFi" password "mypassword" name "HomeWiFi"

# Скрытая сеть
nmcli connection add type wifi con-name "HiddenWiFi" \
  ifname wlan0 ssid "HiddenSSID" \
  wifi.hidden true \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.psk "password"
```

> **Зачем:** Базовое подключение к беспроводной сети.

---

### 6. Настройка статического IP

```bash
# Настройка статического IP
nmcli connection modify "HomeWiFi" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8 8.8.4.4"

# Применение настроек
nmcli connection down "HomeWiFi"
nmcli connection up "HomeWiFi"

# Проверка
ip addr show wlan0
ip route show

# Возврат к DHCP
nmcli connection modify "HomeWiFi" ipv4.method auto
```

> **Зачем:** Фиксированный IP-адрес для доступа к сетевым ресурсам по постоянному адресу.

---

### 7. Настройка DNS

```bash
# Настройка DNS серверов
nmcli connection modify "HomeWiFi" \
  ipv4.ignore-auto-dns yes \
  ipv4.dns "8.8.8.8 1.1.1.1"

# IPv6 DNS
nmcli connection modify "HomeWiFi" \
  ipv6.ignore-auto-dns yes \
  ipv6.dns "2001:4860:4860::8888"

# Проверка
cat /etc/resolv.conf
nmcli connection show "HomeWiFi" | grep dns

# Сброс на автоматические DNS
nmcli connection modify "HomeWiFi" ipv4.ignore-auto-dns no
```

> **Зачем:** Использование альтернативных DNS для ускорения разрешения имён или обхода блокировок.

---

### 8. Настройка автоподключения

```bash
# Включение автоподключения
nmcli connection modify "HomeWiFi" connection.autoconnect yes

# Приоритет автоподключения (чем выше, тем приоритетнее)
nmcli connection modify "HomeWiFi" connection.autoconnect-priority 100

# Отключение автоподключения
nmcli connection modify "HomeWiFi" connection.autoconnect no

# Проверка настроек
nmcli connection show "HomeWiFi" | grep autoconnect
```

> **Зачем:** Автоматическое подключение к известным сетям при появлении в зоне доступа.

---

### 9. Создание точки доступа (Hotspot)

```bash
# Создание точки доступа
nmcli connection add type wifi ifname wlan0 con-name "MyHotspot" autoconnect yes \
  ssid "MyHotspot" \
  wifi.band bg \
  wifi.mode ap

# Настройка безопасности
nmcli connection modify "MyHotspot" \
  802-11-wireless-security.key-mgmt wpa-psk \
  802-11-wireless-security.psk "password123" \
  ipv4.method shared

# Запуск точки доступа
nmcli connection up "MyHotspot"

# Остановка
nmcli connection down "MyHotspot"

# Точка доступа 5 GHz
nmcli connection add type wifi ifname wlan0 con-name "MyHotspot5G" autoconnect yes \
  ssid "MyHotspot5G" \
  wifi.band a \
  wifi.mode ap
```

> **Зачем:** Раздача интернета с ноутбука на другие устройства.

---

### 10. Оптимизация энергопотребления

```bash
# Проверка текущего статуса
iwconfig wlan0 | grep -i power
iw dev wlan0 get power_save

# Отключение энергосбережения (лучшая производительность)
sudo nmcli connection modify "HomeWiFi" wifi.powersave 2

# Включение энергосбережения (экономия батареи)
sudo nmcli connection modify "HomeWiFi" wifi.powersave 3

# Глобальная настройка
sudo cat > /etc/NetworkManager/conf.d/wifi-powersave.conf << EOF
[connection]
wifi.powersave = 2
EOF

sudo systemctl restart NetworkManager

# Проверка
cat /etc/NetworkManager/conf.d/wifi-powersave.conf
```

> **Зачем:** Баланс между временем работы от батареи и производительностью Wi-Fi.

---

### 11. Настройка роуминга

```bash
# Настройка агрессивности роуминга (1-5)
sudo cat > /etc/NetworkManager/conf.d/wifi-roaming.conf << EOF
[connection]
wifi.roaming-aggressiveness=3
EOF

sudo systemctl restart NetworkManager

# Значения:
# 1 - наименее агрессивный (редко переключается)
# 5 - наиболее агрессивный (часто ищет лучшую точку)

# Проверка
cat /etc/NetworkManager/conf.d/wifi-roaming.conf
```

> **Зачем:** Оптимизация переключения между точками доступа в больших сетях.

---

### 12. Диагностика проблем

```bash
# Статус NetworkManager
systemctl status NetworkManager
journalctl -u NetworkManager -f

# Статус Wi-Fi
nmcli device status
nmcli device show wlan0

# Проверка блокировки
rfkill list all

# Сканирование сетей
nmcli device wifi list --rescan yes

# Проверка подключения
ping -c 4 8.8.8.8
ping -c 4 google.com

# Проверка DNS
nslookup google.com
dig google.com

# Информация о подключении
nmcli connection show --active
nmcli -p connection show "HomeWiFi"

# Перезапуск сети
sudo systemctl restart NetworkManager
```

> **Зачем:** Быстрое выявление причин проблем с подключением.

---

### 13. Скрипт быстрого подключения

```bash
# Создание скрипта
sudo cat > /usr/local/bin/wifi-connect.sh << 'EOF'
#!/bin/bash
case "$1" in
    connect|c)
        nmcli device wifi connect "$2" password "$3"
        ;;
    disconnect|d)
        nmcli connection down "$2"
        ;;
    scan|s)
        nmcli device wifi list
        ;;
    status|st)
        nmcli device status | grep -i wifi
        ;;
    on)
        nmcli radio wifi on
        ;;
    off)
        nmcli radio wifi off
        ;;
    *)
        echo "Использование: wifi-connect.sh {connect|disconnect|scan|status|on|off}"
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/wifi-connect.sh

# Использование
wifi-connect.sh scan
wifi-connect.sh connect MyWiFi password123
wifi-connect.sh status
```

> **Зачем:** Быстрое управление Wi-Fi без ввода длинных команд.

---

### 14. Полезные команды nmcli

```bash
# Общая информация
nmcli general status
nmcli general permissions

# Устройства
nmcli device status
nmcli device show
nmcli device show wlan0

# Подключения
nmcli connection show
nmcli connection show --active
nmcli connection show "HomeWiFi"

# Wi-Fi
nmcli device wifi list
nmcli device wifi rescan
nmcli device wifi connect "SSID" password "pass"

# Радио
nmcli radio all
nmcli radio wifi on/off

# Управление подключениями
nmcli connection up "HomeWiFi"
nmcli connection down "HomeWiFi"
nmcli connection delete "HomeWiFi"

# Статистика
nmcli -f GENERAL connection show "HomeWiFi"
```

> **Зачем:** Полный справочник команд для управления Wi-Fi через терминал.

---

## 🤖 Автоматическая настройка через скрипт

Скрипт для автоматической настройки Wi-Fi в операционной системе **РЕД ОС**.

## 📋 Описание

Скрипт предоставляет интерактивный интерфейс для настройки Wi-Fi:

| № | Компонент | Описание |
|---|-----------|----------|
| 1 | **Проверка драйверов** | Анализ и установка драйверов Wi-Fi |
| 2 | **Включение адаптера** | Снятие блокировки через rfkill |
| 3 | **NetworkManager** | Настройка службы управления сетью |
| 4 | **Подключение к сети** | Подключение к Wi-Fi сети |
| 5 | **Статический IP** | Ручная настройка IP-адреса |
| 6 | **DNS** | Настройка DNS серверов |
| 7 | **Автоподключение** | Автоматическое подключение к сети |
| 8 | **Точка доступа** | Создание Wi-Fi hotspot |
| 9 | **Энергопотребление** | Оптимизация питания адаптера |
| 10 | **Роуминг** | Настройка переключения между точками |
| 11 | **Диагностика** | Проверка и решение проблем |
| 12 | **Скрипт подключения** | Утилита wifi-connect.sh |

---

## 🚀 Быстрый старт

### Одной командой:

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_wifi.sh | sudo bash
```

### Или вручную:

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_wifi.sh

# Сделайте исполняемым
chmod +x setup_wifi.sh

# Запустите от root
sudo ./setup_wifi.sh
```

---

## 📖 Возможности

### ✅ Интерактивный режим
- Проверка текущего состояния Wi-Fi
- Определение модели адаптера
- Пошаговое подтверждение каждого действия
- Валидация вводимых параметров

### 🔧 Технические возможности

#### 1. Проверка и установка драйверов
| Чипсет | Пакет |
|--------|-------|
| Intel | `iwlwifi-firmware` |
| Realtek | `rtl8188fu-firmware`, `rtl8192eu-firmware` |
| Atheros | `ath10k-firmware` |
| Broadcom | `broadcom-wl`, `broadcom-wl-kmod` |

#### 2. Включение Wi-Fi (rfkill)
```bash
# Снятие всех блокировок
rfkill unblock all

# Только Wi-Fi
rfkill unblock wifi

# Проверка статуса
rfkill list wifi
```

#### 3. Настройка NetworkManager
```bash
# Запуск службы
systemctl enable NetworkManager
systemctl start NetworkManager

# Включение Wi-Fi
nmcli radio wifi on
```

#### 4. Подключение к Wi-Fi сети
```bash
# Сканирование
nmcli device wifi list

# Подключение
nmcli device wifi connect "SSID" password "password"
```

#### 5. Статический IP
```ini
# Пример конфигурации
IP: 192.168.1.100/24
Шлюз: 192.168.1.1
DNS: 8.8.8.8 1.1.1.1
```

#### 6. Настройка DNS
```bash
# Ручные DNS
nmcli connection modify "HomeWiFi" ipv4.dns "8.8.8.8 1.1.1.1"

# Автоматические DNS
nmcli connection modify "HomeWiFi" ipv4.ignore-auto-dns no
```

#### 7. Автоподключение
```bash
# Включение
nmcli connection modify "HomeWiFi" connection.autoconnect yes

# Приоритет
nmcli connection modify "HomeWiFi" connection.autoconnect-priority 100
```

#### 8. Точка доступа (Hotspot)
```bash
# Создание
nmcli connection add type wifi ifname wlan0 con-name "Hotspot" \
  ssid "MyHotspot" wifi.mode ap

# Настройка безопасности
nmcli connection modify "Hotspot" \
  802-11-wireless-security.key-mgmt wpa-psk \
  802-11-wireless-security.psk "password"
```

#### 9. Энергопотребление
| Значение | Режим |
|----------|-------|
| 2 | Отключено (производительность) |
| 3 | Включено (экономия) |

#### 10. Роуминг
| Уровень | Описание |
|---------|----------|
| 1 | Наименее агрессивный |
| 3 | По умолчанию |
| 5 | Наиболее агрессивный |

#### 11. Диагностика
```bash
# Команды диагностики
systemctl status NetworkManager
journalctl -u NetworkManager -f
nmcli device status
rfkill list wifi
```

#### 12. Скрипт быстрого подключения
```bash
# Использование
wifi-connect.sh connect MyWiFi password123
wifi-connect.sh scan
wifi-connect.sh status
wifi-connect.sh on/off
```

---

## 🖥️ Пример работы

```bash
========================================
Настройка Wi-Fi в РЕД ОС
========================================

[INFO] Проверка текущего состояния Wi-Fi...
  Адаптер: wlan0
  NetworkManager: активен
  Wi-Fi rfkill: разблокирован
  Wi-Fi устройство: обнаружено

========================================
Выберите действия для выполнения:
========================================
  [1] ✓ Проверка и установка драйверов Wi-Fi
  [2] ✓ Включение Wi-Fi адаптера (rfkill)
  [3] ✓ Настройка NetworkManager
  [4] ✓ Подключение к Wi-Fi сети
  [5] ✓ Настройка статического IP
  [6] ✓ Настройка DNS
  [7] ✓ Настройка автоподключения
  [8] ✓ Создание точки доступа (Hotspot)
  [9] ✓ Оптимизация энергопотребления
  [10] ✓ Настройка роуминга
  [11] ✓ Диагностика проблем
  [12] ✓ Создание скрипта быстрого подключения
  [0] → Перейти к выполнению

Введите номер пункта для переключения (0 для продолжения): 0

========================================
1. Проверка и установка драйверов Wi-Fi
========================================
Проверить и установить драйверы Wi-Fi? (y/n): y

Определение модели Wi-Fi адаптера...
  Найдено устройство: Intel Corporation Wi-Fi 6 AX200
  Чипсет: Intel
Установить драйверы Intel WiFi? (y/n): y
✓ Драйверы Intel установлены

========================================
4. Подключение к Wi-Fi сети
========================================
Подключиться к Wi-Fi сети? (y/n): y

Сканирование доступных сетей...
Доступные сети:
  SSID               MODE   CHAN  RATE     SIGNAL  BARS  SECURITY
  MyWiFi             Infra  6    130 Мбит/с  -45   ▂▄▋_  WPA2
  NeighborWiFi       Infra  11   130 Мбит/с  -67   ▂▄__  WPA2

Введите SSID сети (имя): MyWiFi
Введите пароль (если сеть открытая, нажмите Enter): ********
✓ Подключение к MyWiFi успешно

========================================
12. Создание скрипта быстрого подключения
========================================
Создать скрипт быстрого подключения к Wi-Fi? (y/n): y
✓ Скрипт создан: /usr/local/bin/wifi-connect.sh

Использование:
  wifi-connect.sh connect <SSID> [пароль]  # подключиться
  wifi-connect.sh scan                     # сканировать сети
  wifi-connect.sh status                   # проверить статус

========================================
Настройка Wi-Fi завершена!
========================================

Результаты выполнения:
  Проверка и установка драйверов Wi-Fi         ✓ Выполнено
  Включение Wi-Fi адаптера (rfkill)            ✓ Выполнено
  Настройка NetworkManager                     ✓ Выполнено
  Подключение к Wi-Fi сети                     ✓ Выполнено
  Настройка статического IP                    ✗ Пропущено
  Настройка DNS                                ✓ Выполнено
  Настройка автоподключения                    ✓ Выполнено
  Создание точки доступа (Hotspot)             ✗ Пропущено
  Оптимизация энергопотребления                ✓ Выполнено
  Настройка роуминга                           ✗ Пропущено
  Диагностика проблем                          ✓ Выполнено
  Создание скрипта быстрого подключения        ✓ Выполнено

Полезные команды:
  nmcli device wifi list           # список сетей
  nmcli device wifi connect <SSID> password <PASS>  # подключиться
  nmcli connection show --active   # активные подключения
  nmcli radio wifi on/off          # вкл/выкл Wi-Fi
  wifi-connect.sh status           # быстрый статус

✓ Скрипт быстрого подключения доступен: /usr/local/bin/wifi-connect.sh
```

---

## 📋 Требования

| Требование | Описание |
|------------|----------|
| **ОС** | РЕД ОС 7.x / 8.x (другие RHEL-совместимые с осторожностью) |
| **Права** | root (обязательно) |
| **Зависимости** | `NetworkManager` (nmcli), `rfkill` |
| **Опционально** | `iwconfig`, `lspci`, `lsusb` |

---

## 🔍 Проверка результатов

После выполнения скрипта используйте следующие команды для проверки:

```bash
# Статус подключения
nmcli connection show --active

# Статус устройства
nmcli device status

# Информация о подключении
nmcli connection show "HomeWiFi"

# Проверка IP
ip addr show wlan0
ip route show

# Проверка DNS
cat /etc/resolv.conf
nslookup google.com

# Проверка сигнала
watch -n 1 nmcli device wifi list

# Логи
journalctl -u NetworkManager -f

# Статус Wi-Fi
wifi-connect.sh status
```

---

## ⚠️ Важные замечания

1. **Драйверы**: Убедитесь, что установлены правильные драйверы для вашей модели адаптера.
2. **rfkill**: Если Wi-Fi не работает, проверьте блокировку через `rfkill list`.
3. **NetworkManager**: Перезапустите службу после изменений: `systemctl restart NetworkManager`.
4. **Энергосбережение**: Отключите для лучшей производительности, включите для экономии батареи.
5. **Роуминг**: Настройте агрессивность для частого переключения между точками доступа.
6. **Безопасность**: Используйте WPA2/WPA3 для защиты точки доступа.

---

## 📝 Переменные окружения и файлы

| Файл/Параметр | Описание |
|---------------|----------|
| `/etc/NetworkManager/conf.d/` | Конфигурация NetworkManager |
| `/etc/NetworkManager/conf.d/wifi-powersave.conf` | Настройки энергопотребления |
| `/etc/NetworkManager/conf.d/wifi-roaming.conf` | Настройки роуминга |
| `/etc/resolv.conf` | DNS серверы |
| `/usr/local/bin/wifi-connect.sh` | Скрипт быстрого подключения |
| `nmcli connection` | Управление подключениями |
| `rfkill` | Управление радиомодулями |

---

## 🔗 Ссылки

- [NetworkManager Documentation](https://networkmanager.dev/docs/api/latest/)
- [nmcli Reference](https://man.archlinux.org/man/nmcli.1)
- [Linux Wireless Documentation](https://wireless.wiki.kernel.org/)
- [РЕД ОС официальная документация](https://redos.red-soft.ru/documentation)

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | любая |
| **Права** | root (sudo) |
| **Скрипт** | [`setup_wifi.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_wifi.sh) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Названия firmware-пакетов могут отличаться в РЕД ОС 8.x.
> Скрипт автоматически определяет тип Wi-Fi адаптера.
