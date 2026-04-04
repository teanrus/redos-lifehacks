# Решение проблем с сетью в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

- [1. Диагностика подключения к сети](#1-диагностика-подключения-к-сети)
- [2. Сброс сетевых настроек](#2-сброс-сетевых-настроек)
- [3. Настройка DNS при проблемах с разрешением имён](#3-настройка-dns-при-проблемах-с-разрешением-имён)
- [4. Проверка сетевого интерфейса](#4-проверка-сетевого-интерфейса)
- [5. Перезапуск NetworkManager](#5-перезапуск-networkmanager)
- [6. Настройка статического IP](#6-настройка-статического-ip)
- [7. Диагностика Wi-Fi подключения](#7-диагностика-wi-fi-подключения)
- [8. Проблемы с прокси-сервером](#8-проблемы-с-прокси-сервером)
- [9. Проверка маршрутизации](#9-проверка-маршрутизации)
- [10. Блокировка брандмауэром](#10-блокировка-брандмауэром)
- [🤖 Автоматическая диагностика через скрипт](#-автоматическая-диагностика-через-скрипт)
---

## 🛠️ Лайфхаки по решению сетевых проблем

### 1. Диагностика подключения к сети

Быстрая проверка всех сетевых подключений:

```bash
# Проверка статуса всех соединений
nmcli connection show

# Проверка активных соединений
nmcli connection show --active

# Быстрая диагностика
ping -c 4 8.8.8.8
ping -c 4 google.com
```

| Команда | Описание |
|---------|----------|
| `nmcli connection show` | Показать все подключения |
| `nmcli connection show --active` | Только активные подключения |
| `ping 8.8.8.8` | Проверка физического подключения |
| `ping google.com` | Проверка работы DNS |

> **Зачем:** Быстрое определение проблемы: физическое подключение или DNS.

---

### 2. Сброс сетевых настроек

При проблемах с подключением сбросьте настройки сети:

```bash
# Остановить NetworkManager
sudo systemctl stop NetworkManager

# Удалить кэш подключений
sudo rm -rf /var/lib/NetworkManager/*

# Запустить NetworkManager
sudo systemctl start NetworkManager

# Перезагрузить сеть
sudo nmcli networking off && sudo nmcli networking on
```

> **Зачем:** Очистка кэша и пересоздание подключений решает 80% проблем.

---

### 3. Настройка DNS при проблемах с разрешением имён

Если сайты не открываются по имени, но пингуются по IP:

```bash
# Резервное копирование
sudo cp /etc/resolv.conf /etc/resolv.conf.backup

# Редактирование DNS
sudo nano /etc/resolv.conf

# Добавить надёжные DNS-серверы
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
```

**Постоянная настройка DNS через nmcli:**

```bash
# Получить имя подключения
nmcli connection show

# Установить DNS (замените "eth0" на ваше подключение)
sudo nmcli connection modify eth0 ipv4.dns "8.8.8.8 8.8.4.4"
sudo nmcli connection up eth0
```

| DNS-сервер | Владелец | Описание |
|------------|----------|----------|
| `8.8.8.8` | Google | Быстрый, надёжный |
| `8.8.4.4` | Google | Резервный Google DNS |
| `1.1.1.1` | Cloudflare | Самый быстрый в мире |
| `77.88.8.8` | Яндекс | Российский DNS |

> **Зачем:** Решение проблем с открытием сайтов по доменному имени.

---

### 4. Проверка сетевого интерфейса

Диагностика сетевого адаптера:

```bash
# Список всех интерфейсов
ip link show

# Статистика по интерфейсу (замените eth0)
ip -s link show eth0

# Проверка IP-адреса
ip addr show eth0

# Проверка драйвера
ethtool -i eth0

# Проверка кабеля
ethtool eth0 | grep -i link
```

**Вывод `ethtool eth0`:**

```
Settings for eth0:
Supported ports: [ TP ]
Supported link modes:   10baseT/Half 10baseT/Full 
100baseT/Half 100baseT/Full 
1000baseT/Full 
Speed: 1000Mb/s
Duplex: Full
Port: Twisted Pair
PHYAD: 1
Transceiver: internal
Auto-negotiation: on
MDI-X: off (auto)
Supports Wake-on: pumbg
Wake-on: g
Current message level: 0x00000007 (7)
   drv probe link
Link detected: yes
```

| Параметр | Описание |
|----------|----------|
| `Speed` | Скорость подключения |
| `Duplex` | Режим дуплекса (Full — хорошо) |
| `Link detected` | Физическое подключение |

> **Зачем:** Определение проблем на уровне драйвера или кабеля.

---

### 5. Перезапуск NetworkManager

Перезапуск службы управления сетью:

```bash
# Полная перезагрузка службы
sudo systemctl restart NetworkManager

# Проверка статуса
systemctl status NetworkManager

# Включение автозагрузки
sudo systemctl enable NetworkManager

# Перезагрузка только сети (без перезапуска службы)
nmcli networking off && nmcli networking on
```

**При зависании NetworkManager:**

```bash
# Принудительная остановка
sudo systemctl kill NetworkManager

# Запуск
sudo systemctl start NetworkManager

# Проверка логов
journalctl -u NetworkManager -n 50
```

> **Зачем:** Решение проблем с зависанием сетевого менеджера.

---

### 6. Настройка статического IP

Для серверов и стабильной работы сети:

```bash
# Получить имя подключения
nmcli connection show

# Настроить статический IP (замените параметры на свои)
sudo nmcli connection modify "Wired connection 1" \
ipv4.method manual \
ipv4.addresses 192.168.1.100/24 \
ipv4.gateway 192.168.1.1 \
ipv4.dns "8.8.8.8 1.1.1.1"

# Применить изменения
sudo nmcli connection up "Wired connection 1"
```

| Параметр | Описание | Пример |
|----------|----------|--------|
| `ipv4.addresses` | IP-адрес и маска | `192.168.1.100/24` |
| `ipv4.gateway` | Шлюз по умолчанию | `192.168.1.1` |
| `ipv4.dns` | DNS-серверы | `8.8.8.8 1.1.1.1` |

> **Зачем:** Стабильный IP для серверов, принтеров, сетевых ресурсов.

---

### 7. Диагностика Wi-Fi подключения

Проблемы с беспроводным подключением:

```bash
# Проверка Wi-Fi адаптера
nmcli device status

# Список доступных сетей
nmcli device wifi list

# Подключение к сети
nmcli device wifi connect "SSID" password "пароль"

# Проверка уровня сигнала
watch -n 1 'nmcli device wifi list | head -5'

# Забыть сеть
nmcli connection delete "SSID"
```

**Если Wi-Fi не работает:**

```bash
# Проверка блокировки RF
rfkill list all

# Разблокировать Wi-Fi
sudo rfkill unblock wifi

# Перезагрузка модуля ядра (замените iwlwifi на ваш)
sudo modprobe -r iwlwifi
sudo modprobe iwlwifi
```

| Команда | Описание |
|---------|----------|
| `rfkill list` | Проверка блокировок |
| `rfkill unblock wifi` | Снятие блокировки |
| `modprobe -r/iwlwifi` | Перезагрузка драйвера |

> **Зачем:** Решение проблем с подключением к Wi-Fi сетям.

---

### 8. Проблемы с прокси-сервером

Настройка и диагностика прокси:

```bash
# Проверка текущих настроек прокси
echo $http_proxy
echo $https_proxy

# Временная установка прокси
export http_proxy="http://proxy.example.com:8080"
export https_proxy="http://proxy.example.com:8080"

# Постоянная настройка (добавить в ~/.bashrc)
echo 'export http_proxy="http://proxy.example.com:8080"' >> ~/.bashrc
echo 'export https_proxy="http://proxy.example.com:8080"' >> ~/.bashrc
source ~/.bashrc

# Отключение прокси
unset http_proxy
unset https_proxy
```

**Настройка прокси для DNF:**

```bash
# Редактирование конфига DNF
sudo nano /etc/dnf/dnf.conf

# Добавить строки
proxy=http://proxy.example.com:8080
proxy_username=user
proxy_password=password
```

> **Зачем:** Работа в корпоративных сетях с прокси-сервером.

---

### 9. Проверка маршрутизации

Диагностика маршрутов сети:

```bash
# Таблица маршрутизации
ip route show

# Трассировка до узла
traceroute google.com

# Проверка шлюза
ip route | grep default

# Добавление статического маршрута
sudo ip route add 10.0.0.0/8 via 192.168.1.1
```

**Постоянное добавление маршрута:**

```bash
# Создать файл маршрута
sudo nano /etc/sysconfig/network-scripts/route-eth0

# Добавить маршрут
10.0.0.0/8 via 192.168.1.1 dev eth0

# Перезапустить сеть
sudo nmcli connection up eth0
```

> **Зачем:** Доступ к удалённым подсетям и VPN.

---

### 10. Блокировка брандмауэром

Проверка и настройка firewalld:

```bash
# Статус брандмауэра
sudo firewall-cmd --state

# Список разрешённых сервисов
sudo firewall-cmd --list-all

# Разрешить сервис (например, HTTP)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# Разрешить порт
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Временное отключение (для тестов)
sudo systemctl stop firewalld
```

**Диагностика блокировки:**

```bash
# Проверка логов
sudo journalctl -u firewalld -n 50

# Просмотр правил iptables
sudo iptables -L -n -v
```

| Команда | Описание |
|---------|----------|
| `firewall-cmd --state` | Статус брандмауэра |
| `--add-service=http` | Разрешить сервис |
| `--add-port=8080/tcp` | Разрешить порт |
| `systemctl stop firewalld` | Временно отключить |

> **Зачем:** Решение проблем с доступом к сервисам и портам.

---

## 🤖 Автоматическая диагностика через скрипт

Скрипт для автоматической диагностики сетевых проблем в **РЕД ОС**.

## 📋 Описание

Скрипт предоставляет интерактивный интерфейс для диагностики и решения сетевых проблем:

| № | Компонент | Описание |
|---|-----------|----------|
| 1 | **Информация о системе** | Версия ОС, ядро, сетевые адаптеры |
| 2 | **Проверка сетевых интерфейсов** | Статус, IP, драйверы |
| 3 | **Проверка DNS** | Разрешение имён, пинг |
| 4 | **Проверка маршрутизации** | Шлюзы, маршруты |
| 5 | **Проверка брандмауэра** | Статус, правила |
| 6 | **Итоговый отчёт** | Рекомендации по решению |

---

## 🚀 Быстрый старт

### Одной командой:

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/network-diagnostics.sh | sudo bash
```

### Или вручную:

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/network-diagnostics.sh

# Сделайте исполняемым
chmod +x network-diagnostics.sh

# Запустите от root
sudo ./network-diagnostics.sh
```

---

## 📖 Возможности

### ✅ Интерактивный режим
- Пошаговая диагностика всех компонентов
- Автоматическое определение проблем
- Рекомендации по решению
- Валидация прав root

### 🔧 Технические возможности

#### 1. Информация о системе
```
Информация о системе:
  Версия ОС:РЕД ОС 7.3 Муром
  Ядро: 6.1.0-100-generic
  Архитектура:  x86_64
  Хостнейм: workstation
```

#### 2. Проверка сетевых интерфейсов
```
Сетевые интерфейсы:
  ✓ eth0 (UP) - 192.168.1.100/24
  ✗ eth1 (DOWN) - нет подключения
  ✓ lo (UP) - 127.0.0.1

Драйверы:
  eth0: e1000e (Intel)
  wlan0: iwlwifi (Intel)
```

#### 3. Проверка DNS
```
DNS конфигурация:
  ✓ /etc/resolv.conf существует
  ✓ DNS: 8.8.8.8, 1.1.1.1

Разрешение имён:
  ✓ google.com resolves to 142.250.185.46
  ✓ ping google.com: 4 packets transmitted, 4 received
```

#### 4. Проверка маршрутизации
```
Маршрутизация:
  ✓ Шлюз по умолчанию: 192.168.1.1 via eth0
  ✓ Маршрутов: 5

Трассировка до 8.8.8.8:
  1  192.168.1.1  1.234 ms
  2  10.0.0.1 5.678 ms
  3  8.8.8.8  12.345 ms
```

#### 5. Проверка брандмауэра
```
Брандмауэр:
  Статус: active
  Сервисы: ssh, http, https
  Порты: 8080/tcp

⚠ Предупреждение: Порт 3306 (MySQL) заблокирован
```

#### 6. Итоговый отчёт
```
=== Результаты диагностики ===

✓ Сетевые интерфейсы: OK
✓ DNS: OK
✓ Маршрутизация: OK
⚠ Брандмауэр: Требуется настройка

Рекомендации:
  1. Разрешите порт 3306: firewall-cmd --add-port=3306/tcp
  2. Проверьте кабель для eth1
```

---

## 🖥️ Пример работы

```bash
========================================
Диагностика сетевых проблем в РЕД ОС
========================================

[INFO] Информация о системе:
========================================
  Версия ОС:РЕД ОС 7.3 Муром
  Ядро: 6.1.0-100-generic
  Архитектура:  x86_64
  Хостнейм: workstation

[INFO] Проверка сетевых интерфейсов:
========================================

Сетевые интерфейсы:
  ✓ eth0 (UP) - 192.168.1.100/24
  ✗ eth1 (DOWN) - нет подключения
  ✓ lo (UP) - 127.0.0.1

Драйверы:
  eth0: e1000e (Intel)
  wlan0: iwlwifi (Intel)

[INFO] Проверка DNS:
========================================

DNS конфигурация:
  ✓ /etc/resolv.conf существует
  ✓ DNS: 8.8.8.8, 1.1.1.1

Разрешение имён:
  ✓ google.com resolves to 142.250.185.46
  ✓ ping google.com: 4 packets transmitted, 4 received

[INFO] Проверка маршрутизации:
========================================

Маршрутизация:
  ✓ Шлюз по умолчанию: 192.168.1.1 via eth0
  ✓ Маршрутов: 5

[INFO] Проверка брандмауэра:
========================================

Брандмауэр:
  Статус: active
  Сервисы: ssh, http, https
  Порты: 8080/tcp

⚠ Предупреждение: Порт 3306 (MySQL) заблокирован

========================================
Результаты диагностики:
========================================

✓ Сетевые интерфейсы: OK
✓ DNS: OK
✓ Маршрутизация: OK
⚠ Брандмауэр: Требуется настройка

Рекомендации:
  1. Разрешите порт 3306: firewall-cmd --add-port=3306/tcp
  2. Проверьте кабель для eth1

Полезные команды:
  nmcli connection show  # показать подключения
  nmcli device wifi list # список Wi-Fi сетей
  firewall-cmd --list-all# правила брандмауэра
  ip route show  # таблица маршрутизации

[INFO] Готово!
```

---

## 📋 Требования

| Требование | Описание |
|------------|----------|
| **ОС** | РЕД ОС 7.x / 8.x (RHEL-совместимые) |
| **Права** | root (рекомендуется для полной диагностики) |
| **Зависимости** | `nmcli`, `ip`, `firewall-cmd`, `traceroute` |
| **Опционально** | Доступ в интернет (для проверки DNS) |

---

## 🔍 Проверка результатов

После диагностики используйте команды для решения проблем:

```bash
# Перезапуск сети
sudo nmcli networking off && sudo nmcli networking on

# Сброс DNS
sudo systemctl restart NetworkManager

# Проверка подключений
nmcli connection show --active

# Проверка брандмауэра
sudo firewall-cmd --list-all

# Трассировка
traceroute -n 8.8.8.8
```

---

## ⚠️ Важные замечания

1. **Права root**: Для полной диагностики требуются права суперпользователя.
2. **Брандмауэр**: Временное отключение только для тестов!
3. **DNS**: Используйте надёжные DNS-серверы (Google, Cloudflare, Яндекс).
4. **Wi-Fi**: Проверьте блокировку `rfkill` перед диагностикой.
5. **Кабель**: Физическое подключение проверяйте первым делом.
6. **Логи**: `journalctl -u NetworkManager` содержит детальную информацию.

---

## 📝 Полезные команды

| Команда | Описание |
|---------|----------|
| `nmcli connection show` | Показать все подключения |
| `nmcli device status` | Статус устройств |
| `ip addr show` | IP-адреса интерфейсов |
| `ip route show` | Таблица маршрутизации |
| `ping -c 4 8.8.8.8` | Проверка подключения |
| `traceroute google.com` | Трассировка маршрута |
| `firewall-cmd --list-all` | Правила брандмауэра |
| `rfkill list all` | Блокировки RF |
| `ethtool eth0` | Диагностика интерфейса |
| `journalctl -u NetworkManager` | Логи NetworkManager |

---

## 🔗 Полезные ссылки

| Ресурс | Описание |
|--------|----------|
| `https://redos.red-soft.ru/base/` | База знаний РЕД ОС |
| `https://access.redhat.com/documentation/ru-ru/red_hat_enterprise_linux/` | Документация RHEL (совместима) |
| `https://wiki.archlinux.org/title/NetworkManager` | Arch Wiki по NetworkManager |
| `https://firewalld.org/` | Официальная документация firewalld |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | любая |
| **Права** | root (для firewall-cmd, ethtool) |
| **Скрипт** | [`network-diagnostics.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/network-diagnostics.sh) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Скрипт использует стандартные утилиты (`nmcli`, `ethtool`, `firewall-cmd`). Совместим с обеими версиями.
