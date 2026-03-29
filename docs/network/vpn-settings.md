# Настройка корпоративного VPN в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📚 Лайфхаки по настройке корпоративного VPN

### 1. Быстрое подключение через nmcli

```bash
# Показать все VPN подключения
nmcli connection show --active | grep vpn

# Подключиться к VPN
nmcli connection up "CorpVPN"

# Отключиться от VPN
nmcli connection down "CorpVPN"

# Статус подключения
nmcli connection show "CorpVPN"
```

> **Зачем:** Быстрое управление VPN без графического интерфейса.

---

### 2. Проверка установленных пакетов перед настройкой

```bash
# Проверка OpenVPN
rpm -qa | grep -i openvpn

# Проверка WireGuard
rpm -qa | grep -i wireguard

# Проверка Cisco AnyConnect
ls -la /opt/cisco/anyconnect/ 2>/dev/null

# Проверка NetworkManager
systemctl status NetworkManager
```

> **Зачем:** Убедитесь, что необходимые пакеты установлены до начала настройки.

---

### 3. Установка недостающих пакетов

```bash
# OpenVPN
sudo dnf install -y openvpn network-manager-openvpn network-manager-openvpn-gnome

# WireGuard
sudo dnf install -y wireguard-tools

# Обновление NetworkManager
sudo dnf update -y NetworkManager
```

> **Зачем:** Все необходимые зависимости для работы VPN.

---

### 4. Создание OpenVPN подключения через nmcli

```bash
# Базовое подключение с паролем
nmcli connection add type openvpn con-name "CorpVPN" \
  ifname "*" \
  vpn.service-type "org.freedesktop.NetworkManager.openvpn" \
  vpn.data "gateway=vpn.company.com,connection-type=password" \
  vpn.user "username" \
  ipv4.method auto \
  ipv6.method ignore

# С сертификатами
nmcli connection modify "CorpVPN" \
  vpn.ca "/etc/openvpn/ca.crt" \
  vpn.cert "/etc/openvpn/client.crt" \
  vpn.key "/etc/openvpn/client.key"
```

> **Зачем:** Программное создание подключения без GUI.

---

### 5. Настройка WireGuard

```bash
# Генерация ключей
wg genkey | tee privatekey | wg pubkey > publickey

# Создание конфигурации /etc/wireguard/wg0.conf
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat privatekey)
Address = 10.0.0.2/24
DNS = 10.0.0.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn.company.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Применение настроек
chmod 600 /etc/wireguard/wg0.conf
wg-quick up wg0
```

> **Зачем:** Современный быстрый VPN с минимальными накладными расходами.

---

### 6. Автозапуск VPN при входе в систему

```bash
# Создание скрипта автозапуска
cat > /usr/local/bin/vpn-autostart.sh << 'EOF'
#!/bin/bash
sleep 10
nmcli connection up "CorpVPN" --ask 2>/dev/null || true
EOF

chmod +x /usr/local/bin/vpn-autostart.sh

# Добавление в автозагрузку пользователя
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/vpn.desktop << EOF
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/vpn-autostart.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=VPN Auto Connect
EOF
```

> **Зачем:** Автоматическое подключение к корпоративной сети при старте.

---

### 7. Настройка DNS для VPN

```bash
# Отключить автоматический DNS от VPN провайдера
nmcli connection modify "CorpVPN" ipv4.ignore-auto-dns yes

# Прописать корпоративные DNS
nmcli connection modify "CorpVPN" ipv4.dns "10.0.0.1 10.0.0.2"

# Проверка DNS
cat /etc/resolv.conf
nslookup internal.company.com
```

> **Зачем:** Корректное разрешение имён корпоративных ресурсов.

---

### 8. Split-tunneling (раздельное туннелирование)

```bash
# Только трафик к корпоративной сети через VPN
nmcli connection modify "CorpVPN" \
  ipv4.routes "192.168.0.0/24 10.0.0.1" \
  ipv4.route-metric 100 \
  ipv4.never-default yes

# Проверка маршрутов
ip route show
```

> **Зачем:** Одновременный доступ к интернету и корпоративной сети.

---

### 9. Настройка брандмауэра для VPN

```bash
# Открыть порты для OpenVPN
sudo firewall-cmd --permanent --add-service=openvpn
sudo firewall-cmd --permanent --add-port=1194/udp

# Открыть порты для WireGuard
sudo firewall-cmd --permanent --add-port=51820/udp

# Включить маскарадинг
sudo firewall-cmd --permanent --add-masquerade

# Применить изменения
sudo firewall-cmd --reload
```

> **Зачем:** Обеспечение прохождения VPN трафика через фаервол.

---

### 10. Диагностика проблем с VPN

```bash
# Логи NetworkManager
journalctl -u NetworkManager -f

# Логи OpenVPN
journalctl -u openvpn -f

# Проверка маршрутов
ip route show | grep -E "^(default|10\.|192\.168\.)"

# Проверка DNS
nslookup google.com
nslookup internal.company.com

# Проверка подключения
ping -c 3 10.0.0.1
```

> **Зачем:** Быстрое выявление причин проблем с подключением.

---

## 🤖 Автоматическая настройка через скрипт

Скрипт для автоматической настройки корпоративного VPN в операционной системе **РЕД ОС** (Red OS).

## 📋 Описание

Скрипт предоставляет интерактивный интерфейс для настройки VPN:

| № | Компонент | Описание |
|---|-----------|----------|
| 1 | **Проверка пакетов** | Анализ установленных VPN пакетов |
| 2 | **Установка зависимостей** | Установка недостающих пакетов |
| 3 | **Настройка OpenVPN** | Создание подключения через nmcli |
| 4 | **Настройка WireGuard** | Генерация конфигурации |
| 5 | **Автозапуск VPN** | Настройка автоматического подключения |
| 6 | **Настройка DNS** | Корректное разрешение имён |
| 7 | **Split-tunneling** | Раздельная маршрутизация |
| 8 | **Брандмауэр** | Правила firewalld для VPN |
| 9 | **Быстрое подключение** | Скрипты vpn-quick.sh / vpn-disconnect.sh |
| 10 | **Логирование** | Настройка логов VPN подключений |

---

## 🚀 Быстрый старт

### Одной командой:

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_corporate_vpn.sh | sudo bash
```

### Или вручную:

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_corporate_vpn.sh

# Сделайте исполняемым
chmod +x setup_corporate_vpn.sh

# Запустите от root
sudo ./setup_corporate_vpn.sh
```

---

## 📖 Возможности

### ✅ Интерактивный режим
- Проверка установленных пакетов
- Выбор типа VPN (OpenVPN / WireGuard / Cisco AnyConnect)
- Пошаговое подтверждение каждого действия
- Валидация вводимых параметров
- Автоматическое создание резервных конфигураций

### 🔧 Технические возможности

#### 1. Проверка установленных пакетов
```
Проверка установленных пакетов...
  ✓ NetworkManager
  ✗ OpenVPN
  ✗ WireGuard
  ✗ Cisco AnyConnect
```

#### 2. Установка недостающих пакетов
```bash
# Автоматическая установка через dnf
dnf install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
dnf install -y wireguard-tools
```

#### 3. Настройка OpenVPN
| Параметр | Описание |
|----------|----------|
| VPN сервер | Адрес сервера (vpn.company.com) |
| Название подключения | Имя в NetworkManager |
| Сертификаты | CA, клиентский сертификат, ключ |
| Аутентификация | Логин/пароль или сертификаты |

#### 4. Настройка WireGuard
```ini
[Interface]
PrivateKey = <приватный ключ>
Address = <IP в VPN сети>
DNS = <DNS серверы>

[Peer]
PublicKey = <публичный ключ сервера>
Endpoint = <сервер:порт>
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

#### 5. Автозапуск VPN
```bash
# Скрипт автозапуска
/usr/local/bin/vpn-connect.sh

# Desktop файл в автозагрузке
~/.config/autostart/vpn-autostart.desktop
```

#### 6. Настройка DNS
```bash
# Отключение автоматического DNS
nmcli connection modify "CorpVPN" ipv4.ignore-auto-dns yes

# Ручная настройка DNS
nmcli connection modify "CorpVPN" ipv4.dns "10.0.0.1 10.0.0.2"
```

#### 7. Split-tunneling
| Параметр | Описание |
|----------|----------|
| Корпоративная сеть | Сеть для маршрутизации через VPN |
| Шлюз | Опциональный шлюз для сети |
| never-default | Оставить основной трафик вне VPN |

#### 8. Брандмауэр (firewalld)
```bash
# Порты для OpenVPN
firewall-cmd --permanent --add-service=openvpn
firewall-cmd --permanent --add-port=1194/udp

# Порты для WireGuard
firewall-cmd --permanent --add-port=51820/udp

# Маскарадинг
firewall-cmd --permanent --add-masquerade
```

#### 9. Скрипты быстрого подключения
```bash
# Подключение
vpn-quick.sh [название_подключения]

# Отключение
vpn-disconnect.sh [название_подключения]

# Просмотр логов
vpn-logs.sh
```

#### 10. Логирование VPN
```bash
# Конфигурация rsyslog
/etc/rsyslog.d/vpn.conf

# Файлы логов
/var/log/vpn.log
/var/log/openvpn.log
```

---

## 🖥️ Пример работы

```bash
========================================
Настройка корпоративного VPN в РЕД ОС
========================================

[INFO] Проверка установленных пакетов...
  ✓ NetworkManager
  ✗ OpenVPN
  ✗ WireGuard
  ✗ Cisco AnyConnect

Выберите тип VPN для настройки:
  1) OpenVPN
  2) WireGuard
  3) Cisco AnyConnect
  4) Пропустить установку пакетов

Ваш выбор (1-4): 1

Установить OpenVPN? (y/n): y
✓ Установка OpenVPN успешно выполнено

========================================
Выберите действия для выполнения:
========================================
  [1] ✓ Настройка OpenVPN подключения
  [2] ✓ Настройка WireGuard подключения
  [3] ✓ Настройка автозапуска VPN
  [4] ✓ Настройка DNS для VPN
  [5] ✓ Настройка split-tunneling
  [6] ✓ Настройка брандмауэра (firewalld)
  [7] ✓ Создание скрипта быстрого подключения
  [8] ✓ Настройка логирования VPN
  [0] → Перейти к выполнению

Введите номер пункта для переключения (0 для продолжения): 0

========================================
1. Настройка OpenVPN подключения
========================================
Настроить OpenVPN подключение? (y/n): y

Адрес VPN сервера: vpn.company.com
Название подключения (по умолчанию CorpVPN): CorpVPN
✓ OpenVPN подключение создано

Использовать сертификаты (CA, клиент)? (y/n): y
Путь к CA сертификату: /etc/openvpn/ca.crt
Путь к клиентскому сертификату: /etc/openvpn/client.crt
Путь к приватному ключу: /etc/openvpn/client.key
✓ Сертификаты настроены

========================================
3. Настройка автозапуска VPN
========================================
Настроить автозапуск VPN при входе в систему? (y/n): y
✓ Автозапуск VPN настроен

========================================
4. Настройка DNS для VPN
========================================
Настроить DNS для VPN подключения? (y/n): y
Название VPN подключения: CorpVPN
DNS серверы (через пробел, например 10.0.0.1 10.0.0.2): 10.0.0.1 10.0.0.2
✓ DNS настроены

========================================
5. Настройка split-tunneling (раздельное туннелирование)
========================================
Настроить split-tunneling? (y/n): y
Название VPN подключения: CorpVPN
Корпоративная сеть (например, 192.168.0.0/24): 192.168.0.0/24
✓ Split-tunneling настроен

========================================
7. Создание скрипта быстрого подключения
========================================
Создать скрипт быстрого подключения к VPN? (y/n): y
✓ Скрипты созданы:
  - vpn-quick.sh      # быстрое подключение
  - vpn-disconnect.sh # отключение

Использование:
  vpn-quick.sh [название_подключения]
  vpn-disconnect.sh [название_подключения]

========================================
Настройка корпоративного VPN завершена!
========================================

Результаты выполнения:
  Настройка OpenVPN подключения                    ✓ Выполнено
  Настройка WireGuard подключения                  ✗ Пропущено
  Настройка автозапуска VPN                        ✓ Выполнено
  Настройка DNS для VPN                            ✓ Выполнено
  Настройка split-tunneling                        ✓ Выполнено
  Настройка брандмауэра (firewalld)                ✓ Выполнено
  Создание скрипта быстрого подключения            ✓ Выполнено
  Настройка логирования VPN                        ✓ Выполнено

Полезные команды:
  nmcli connection show              # список подключений
  nmcli connection up CorpVPN        # подключить VPN
  nmcli connection down CorpVPN      # отключить VPN
  vpn-quick.sh                       # быстрое подключение
  vpn-logs.sh                        # просмотр логов
  journalctl -u NetworkManager -f    # логи NetworkManager

✓ Скрипт быстрого подключения доступен: /usr/local/bin/vpn-quick.sh
```

---

## 📋 Требования

| Требование | Описание |
|------------|----------|
| **ОС** | РЕД ОС 7.x / 8.x (другие RHEL-совместимые с осторожностью) |
| **Права** | root (обязательно) |
| **Зависимости** | `NetworkManager` (nmcli) |
| **Опционально** | `openvpn`, `wireguard-tools`, `firewalld`, `rsyslog` |

---

## 🔍 Проверка результатов

После выполнения скрипта используйте следующие команды для проверки:

```bash
# Показать все подключения
nmcli connection show

# Показать активные подключения
nmcli connection show --active

# Подключиться к VPN
nmcli connection up "CorpVPN"

# Отключиться от VPN
nmcli connection down "CorpVPN"

# Проверка маршрутов
ip route show

# Проверка DNS
cat /etc/resolv.conf
nslookup google.com

# Логи NetworkManager
journalctl -u NetworkManager -f

# Логи VPN
tail -f /var/log/vpn.log

# Статус WireGuard (если используется)
wg show
```

---

## ⚠️ Важные замечания

1. **Безопасность**: Храните сертификаты и ключи в защищённой директории с правами 600.
2. **Резервное копирование**: Перед изменением настроек сохраните текущую конфигурацию.
3. **Split-tunneling**: Используйте для одновременного доступа в интернет и корпоративную сеть.
4. **DNS**: Убедитесь, что корпоративные DNS серверы доступны через VPN.
5. **Firewall**: Откройте необходимые порты для прохождения VPN трафика.
6. **Автозапуск**: Требует настройки брелока паролей (seahorse) для автоматического ввода учётных данных.

---

## 📝 Переменные окружения и файлы

| Файл/Параметр | Описание |
|---------------|----------|
| `/etc/NetworkManager/system-connections/` | Директория с конфигурацией подключений |
| `/etc/wireguard/` | Директория с конфигурацией WireGuard |
| `/etc/openvpn/` | Директория с конфигурацией OpenVPN |
| `/etc/pam.d/system-auth` | Конфигурация PAM для аутентификации |
| `/var/log/vpn.log` | Лог файл VPN подключений |
| `/usr/local/bin/vpn-quick.sh` | Скрипт быстрого подключения |
| `/usr/local/bin/vpn-disconnect.sh` | Скрипт отключения |
| `/usr/local/bin/vpn-logs.sh` | Скрипт просмотра логов |
| `nmcli connection` | Управление подключениями |

---

## 🔗 Ссылки

- [Официальная документация NetworkManager](https://networkmanager.dev/docs/api/latest/)
- [OpenVPN документация](https://openvpn.net/community-resources/)
- [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
- [РЕД ОС официальная документация](https://redos.red-soft.ru/documentation)
