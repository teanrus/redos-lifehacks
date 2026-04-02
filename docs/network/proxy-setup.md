# Настройка прокси-сервера в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📚 Лайфхаки по настройке прокси-сервера

### 📖 Оглавление

| № | Раздел | Описание |
|---|--------|----------|
| 1 | [Быстрая настройка через терминал](#1-быстрая-настройка-через-терминал-временный-прокси) | Временные настройки для сессии |
| 2 | [Проверка текущих настроек](#2-проверка-текущих-настроек-прокси) | Диагностика текущего состояния |
| 3 | [Глобальная настройка](#3-глобальная-настройка-для-всех-пользователей) | Системный прокси для всех |
| 4 | [Пользовательский прокси](#4-настройка-прокси-для-текущего-пользователя) | Персональные настройки |
| 5 | [Прокси для APT/DNF](#5-настройка-прокси-для-пакетного-менеджера) | Настройки для пакетного менеджера |
| 6 | [Прокси для Git](#6-настройка-прокси-для-git) | Работа с репозиториями |
| 7 | [Прокси для Docker](#7-настройка-прокси-для-docker) | Скачивание образов |
| 8 | [Прокси с авторизацией](#8-прокси-с-авторизацией) | Аутентификация на прокси |
| 9 | [Настройка исключений](#9-настройка-исключений-no_proxy) | Прямой доступ к ресурсам |
| 10 | [Скрипт переключения](#10-скрипт-быстрого-переключения-прокси) | Быстрое вкл/выкл прокси |
| 11 | [Проверка работы](#11-проверка-работы-прокси) | Тестирование подключения |
| 12 | [Прокси для Snap](#12-настройка-прокси-для-snap) | Snap-пакеты через прокси |
| 13 | [Прокси для wget/curl](#13-настройка-прокси-для-wget-и-curl) | Утилиты командной строки |
| 14 | [Временное отключение](#14-временное-отключение-прокси) | Обход прокси |

---

### 1. Быстрая настройка через терминал (временный прокси)

```bash
# Включение прокси
export http_proxy="http://proxy.company.com:8080"
export https_proxy="http://proxy.company.com:8080"
export ftp_proxy="http://proxy.company.com:8080"
export no_proxy="localhost,127.0.0.1,.local"

# Проверка
echo $http_proxy
curl ifconfig.me
```

> **Зачем:** Быстрое включение прокси для текущей сессии без постоянных изменений.

---

### 2. Проверка текущих настроек прокси

```bash
# Проверка переменных окружения
env | grep -i proxy

# Проверка конкретных переменных
echo $http_proxy
echo $https_proxy
echo $no_proxy

# Проверка настроек для конкретного приложения
git config --global http.proxy
cat /etc/apt/apt.conf.d/proxy.conf 2>/dev/null
```

> **Зачем:** Быстрая диагностика текущего состояния прокси-настроек.

---

### 3. Глобальная настройка для всех пользователей

```bash
# Создание системного файла конфигурации
sudo cat > /etc/profile.d/proxy.sh << EOF
export http_proxy="http://proxy.company.com:8080"
export https_proxy="http://proxy.company.com:8080"
export ftp_proxy="http://proxy.company.com:8080"
export no_proxy="localhost,127.0.0.1,.local"
EOF

sudo chmod +x /etc/profile.d/proxy.sh

# Применение без перезагрузки
source /etc/profile.d/proxy.sh
```

> **Зачем:** Файлы в `/etc/profile.d/` автоматически выполняются при входе в систему для всех пользователей.

---

### 4. Настройка прокси для текущего пользователя

```bash
# Добавление в ~/.bashrc
cat >> ~/.bashrc << EOF

# Настройки прокси
export http_proxy="http://proxy.company.com:8080"
export https_proxy="http://proxy.company.com:8080"
export no_proxy="localhost,127.0.0.1,.local"
EOF

# Применение
source ~/.bashrc
```

> **Зачем:** Персональные настройки, не затрагивающие других пользователей.

---

### 5. Настройка прокси для пакетного менеджера

```bash
# Для DNF (РЕД ОС 8.x)
sudo cat > /etc/dnf/proxy.conf << EOF
[main]
proxy=http://proxy.company.com:8080
EOF

# Для APT (РЕД ОС 7.x)
sudo cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "http://proxy.company.com:8080";
Acquire::https::Proxy "http://proxy.company.com:8080";
EOF
```

> **Зачем:** Отдельная настройка для загрузки пакетов через корпоративный прокси.

---

### 6. Настройка прокси для Git

```bash
# Глобальная настройка
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy http://proxy.company.com:8080

# Для конкретного репозитория
cd /path/to/repo
git config http.proxy http://proxy.company.com:8080

# Проверка
git config --global --get http.proxy

# Отключение
git config --global --unset http.proxy
```

> **Зачем:** Работа с GitHub, GitLab и другими репозиториями через корпоративный прокси.

---

### 7. Настройка прокси для Docker

```bash
# Создание директории для конфигурации
sudo mkdir -p /etc/systemd/system/docker.service.d

# Создание конфигурации
sudo cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://proxy.company.com:8080"
Environment="HTTPS_PROXY=http://proxy.company.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1,.local"
EOF

# Применение
sudo systemctl daemon-reload
sudo systemctl restart docker

# Проверка
docker info | grep -i proxy
```

> **Зачем:** Скачивание образов и отправка в реестры через корпоративный прокси.

---

### 8. Прокси с авторизацией

```bash
# Базовый формат
export http_proxy="http://username:password@proxy.company.com:8080"

# Экранирование спецсимволов в пароле
# @ → %40, : → %3A, # → %23
export http_proxy="http://user%40company.com:P%40ssw0rd%23123@proxy.company.com:8080"

# Для Git
git config --global http.proxy http://user%40company.com:P%40ssw0rd%23123@proxy.company.com:8080
```

> **Зачем:** Подключение к прокси-серверам с обязательной аутентификацией.

---

### 9. Настройка исключений (no_proxy)

```bash
# Исключение локальных адресов
export no_proxy="localhost,127.0.0.1,.local"

# Исключение корпоративных доменов
export no_proxy=".company.local,.internal,192.168.0.0/16,10.0.0.0/8"

# Полное исключение хостов
export no_proxy="localhost,127.0.0.1,git.company.com,nexus.company.local"
```

> **Зачем:** Прямой доступ к локальным и корпоративным ресурсам в обход прокси (ускоряет работу).

---

### 10. Скрипт быстрого переключения прокси

```bash
# Создание скрипта
sudo cat > /usr/local/bin/proxy-toggle.sh << 'EOF'
#!/bin/bash
PROXY_HOST="proxy.company.com"
PROXY_PORT="8080"

case "$1" in
    on)
        export http_proxy="http://$PROXY_HOST:$PROXY_PORT"
        export https_proxy="http://$PROXY_HOST:$PROXY_PORT"
        echo "Прокси ВКЛЮЧЕН"
        ;;
    off)
        unset http_proxy https_proxy
        echo "Прокси ВЫКЛЮЧЕН"
        ;;
    status)
        [[ -n "$http_proxy" ]] && echo "Включен: $http_proxy" || echo "Выключен"
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/proxy-toggle.sh

# Алиасы в ~/.bash_aliases
cat >> ~/.bash_aliases << EOF
alias proxy-on='proxy-toggle.sh on'
alias proxy-off='proxy-toggle.sh off'
alias proxy-status='proxy-toggle.sh status'
EOF

# Использование
proxy-on
proxy-off
proxy-status
```

> **Зачем:** Быстрое переключение между режимами работы с прокси и без.

---

### 11. Проверка работы прокси

```bash
# Проверка подключения
curl -I http://example.com
wget --spider http://example.com

# Проверка IP-адреса
curl ifconfig.me
curl ipinfo.io/ip

# Проверка с обходом прокси
curl --noproxy "*" ifconfig.me

# Диагностика
curl -v http://example.com 2>&1 | grep -i proxy
```

> **Зачем:** Верификация работоспособности прокси-настроек.

---

### 12. Настройка прокси для Snap

```bash
# Настройка
sudo snap set system proxy.http="http://proxy.company.com:8080"
sudo snap set system proxy.https="http://proxy.company.com:8080"

# Проверка
snap get system proxy

# Отключение
sudo snap set system proxy.http=""
sudo snap set system proxy.https=""
```

> **Зачем:** Установка snap-пакетов через корпоративный прокси.

---

### 13. Настройка прокси для wget и curl

```bash
# Для wget (~/.wgetrc)
cat > ~/.wgetrc << EOF
http_proxy = http://proxy.company.com:8080
https_proxy = http://proxy.company.com:8080
use_proxy = on
EOF

# Для curl (~/.curlrc)
cat > ~/.curlrc << EOF
proxy = "http://proxy.company.com:8080"
EOF
```

> **Зачем:** Постоянные настройки для утилит командной строки.

---

### 14. Временное отключение прокси

```bash
# Для одной команды
curl --noproxy "*" http://example.com
wget --no-proxy http://example.com

# Временное снятие переменных
unset http_proxy https_proxy ftp_proxy

# Отключение для конкретного домена
export no_proxy="example.com,.example.com"
```

> **Зачем:** Обход прокси для определённых ресурсов или команд.

---

## 🤖 Автоматическая настройка через скрипт

Скрипт для автоматической настройки прокси-сервера в операционной системе **РЕД ОС**.

## 📋 Описание

Скрипт предоставляет интерактивный интерфейс для настройки прокси:

| № | Компонент | Описание |
|---|-----------|----------|
| 1 | **Проверка конфигурации** | Анализ текущих настроек прокси |
| 2 | **Системный прокси** | Настройка для всех пользователей |
| 3 | **Пользовательский прокси** | Настройка для текущего пользователя |
| 4 | **APT/DNF прокси** | Настройка для пакетного менеджера |
| 5 | **Git прокси** | Настройка для Git |
| 6 | **wget/curl прокси** | Настройка для утилит |
| 7 | **Docker прокси** | Настройка для Docker |
| 8 | **Snap прокси** | Настройка для Snap |
| 9 | **no_proxy** | Настройка исключений |
| 10 | **Быстрое переключение** | Скрипт proxy-toggle.sh |
| 11 | **Прокси с авторизацией** | Настройка учётных данных |
| 12 | **Проверка работы** | Тестирование подключения |

---

## 🚀 Быстрый старт

### Одной командой:

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_proxy.sh | sudo bash
```

### Или вручную:

```bash
# Скачайте скрипт
wget https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_proxy.sh

# Сделайте исполняемым
chmod +x setup_proxy.sh

# Запустите от root
sudo ./setup_proxy.sh
```

---

## 📖 Возможности

### ✅ Интерактивный режим
- Проверка текущих настроек прокси
- Пошаговое подтверждение каждого действия
- Валидация вводимых параметров
- Автоматическое резервное копирование

### 🔧 Технические возможности

#### 1. Проверка текущей конфигурации
```
Проверка текущей конфигурации прокси...
  http_proxy=не установлен
  https_proxy=не установлен
  ftp_proxy=не установлен
  no_proxy=не установлен
```

#### 2. Системный прокси
| Файл | Описание |
|------|----------|
| `/etc/profile.d/proxy.sh` | Системные переменные окружения |
| Права | `chmod +x` для выполнения |

#### 3. Пользовательский прокси
```bash
# Добавляется в ~/.bashrc и ~/.bash_profile
export http_proxy="http://proxy.company.com:8080"
export https_proxy="http://proxy.company.com:8080"
export no_proxy="localhost,127.0.0.1,.local"
```

#### 4. Прокси для пакетного менеджера
```ini
# /etc/dnf/proxy.conf
[main]
proxy=http://proxy.company.com:8080

# /etc/apt/apt.conf.d/proxy.conf
Acquire::http::Proxy "http://proxy.company.com:8080";
Acquire::https::Proxy "http://proxy.company.com:8080";
```

#### 5. Прокси для Git
```bash
# Глобальная настройка
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy http://proxy.company.com:8080
```

#### 6. Прокси для Docker
```ini
# /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://proxy.company.com:8080"
Environment="HTTPS_PROXY=http://proxy.company.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1,.local"
```

#### 7. Прокси для Snap
```bash
snap set system proxy.http="http://proxy.company.com:8080"
snap set system proxy.https="http://proxy.company.com:8080"
```

#### 8. Настройка исключений (no_proxy)
| Исключение | Описание |
|------------|----------|
| `localhost` | Локальный хост |
| `127.0.0.1` | Loopback интерфейс |
| `.local` | Локальная зона |
| `192.168.0.0/16` | Частная сеть |
| `.company.local` | Корпоративный домен |

#### 9. Скрипт быстрого переключения
```bash
# Использование
proxy-toggle.sh on       # включить прокси
proxy-toggle.sh off      # выключить прокси
proxy-toggle.sh status   # проверить статус
proxy-toggle.sh config   # показать конфигурацию

# Алиасы
alias proxy-on='proxy-toggle.sh on'
alias proxy-off='proxy-toggle.sh off'
alias proxy-status='proxy-toggle.sh status'
```

#### 10. Прокси с авторизацией
```bash
# Формат URL
http://username:password@proxy.company.com:8080

# Экранирование спецсимволов
# @ → %40, : → %3A, # → %23
http://user%40company.com:P%40ssw0rd%23123@proxy.company.com:8080

# Файл учётных данных
/etc/proxy-credentials (права 600)
```

---

## 🖥️ Пример работы

```bash
========================================
Настройка прокси-сервера в РЕД ОС
========================================

[INFO] Проверка текущей конфигурации прокси...
  http_proxy=не установлен
  https_proxy=не установлен
  ftp_proxy=не установлен
  no_proxy=не установлен

========================================
Выберите действия для выполнения:
========================================
  [1] ✓ Настройка системного прокси (для всех пользователей)
  [2] ✓ Настройка прокси для текущего пользователя
  [3] ✓ Настройка прокси для APT/DNF
  [4] ✓ Настройка прокси для Git
  [5] ✓ Настройка прокси для wget/curl
  [6] ✓ Настройка прокси для Docker
  [7] ✓ Настройка прокси для Snap
  [8] ✓ Настройка исключений (no_proxy)
  [9] ✓ Создание скрипта быстрого переключения прокси
  [10] ✓ Настройка прокси с авторизацией
  [11] ✓ Проверка работы прокси
  [0] → Перейти к выполнению

Введите номер пункта для переключения (0 для продолжения): 0

========================================
1. Настройка системного прокси (для всех пользователей)
========================================
Настроить системный прокси для всех пользователей? (y/n): y

Адрес прокси-сервера (например, proxy.company.com): proxy.company.com
Порт прокси-сервера (например, 8080): 8080
Протокол (http/https/socks5, по умолчанию http): http
✓ Системный прокси настроен

========================================
3. Настройка прокси для APT/DNF
========================================
Настроить прокси для пакетного менеджера? (y/n): y

Адрес прокси-сервера: proxy.company.com
Порт прокси-сервера: 8080
✓ Прокси для DNF настроен

========================================
9. Создание скрипта быстрого переключения прокси
========================================
Создать скрипт быстрого переключения прокси? (y/n): y
✓ Скрипт создан: /usr/local/bin/proxy-toggle.sh

Использование:
  proxy-toggle.sh on      # включить прокси
  proxy-toggle.sh off     # выключить прокси
  proxy-toggle.sh status  # проверить статус

========================================
11. Проверка работы прокси
========================================
Выполнить проверку работы прокси? (y/n): y

Проверка переменных окружения:
  http_proxy=http://proxy.company.com:8080
  https_proxy=http://proxy.company.com:8080

Проверка подключения через curl:
  Тест подключения к example.com...
  ✓ Подключение успешно
  Проверка IP-адреса...
  Ваш IP: 203.0.113.45

========================================
Настройка прокси-сервера завершена!
========================================

Результаты выполнения:
  Настройка системного прокси                      ✓ Выполнено
  Настройка прокси для текущего пользователя       ✗ Пропущено
  Настройка прокси для APT/DNF                     ✓ Выполнено
  Настройка прокси для Git                         ✗ Пропущено
  Настройка прокси для wget/curl                   ✗ Пропущено
  Настройка прокси для Docker                      ✗ Пропущено
  Настройка прокси для Snap                        ✗ Пропущено
  Настройка исключений (no_proxy)                  ✓ Выполнено
  Создание скрипта быстрого переключения прокси    ✓ Выполнено
  Настройка прокси с авторизацией                  ✗ Пропущено
  Проверка работы прокси                           ✓ Выполнено

Полезные команды:
  env | grep -i proxy              # проверить переменные прокси
  proxy-toggle.sh on               # включить прокси
  proxy-toggle.sh off              # выключить прокси
  proxy-toggle.sh status           # статус прокси
  curl ifconfig.me                 # проверить IP

✓ Скрипт переключения прокси доступен: /usr/local/bin/proxy-toggle.sh
✓ Системный прокси настроен: /etc/profile.d/proxy.sh

Для применения настроек выполните:
  source /etc/profile.d/proxy.sh   # для системного прокси
  source ~/.bashrc                 # для пользовательского прокси
```

---

## 📋 Требования

| Требование | Описание |
|------------|----------|
| **ОС** | РЕД ОС 7.x / 8.x (другие RHEL-совместимые с осторожностью) |
| **Права** | root (обязательно) |
| **Зависимости** | `bash`, `curl` или `wget` |
| **Опционально** | `dnf`, `apt`, `git`, `docker`, `snap` |

---

## 🔍 Проверка результатов

После выполнения скрипта используйте следующие команды для проверки:

```bash
# Проверка переменных окружения
env | grep -i proxy
echo $http_proxy
echo $https_proxy

# Проверка подключения
curl -I http://example.com
wget --spider http://example.com

# Проверка IP
curl ifconfig.me
curl ipinfo.io/ip

# Проверка настроек Git
git config --global --get http.proxy

# Проверка настроек Docker
docker info | grep -i proxy

# Проверка настроек DNF
cat /etc/dnf/proxy.conf

# Проверка настроек APT
cat /etc/apt/apt.conf.d/proxy.conf

# Статус прокси
proxy-toggle.sh status
```

---

## ⚠️ Важные замечания

1. **Безопасность**: Не храните пароли в открытом виде. Используйте файл `/etc/proxy-credentials` с правами 600.
2. **Экранирование**: Экранируйте спецсимволы в пароле: `@` → `%40`, `:` → `%3A`, `#` → `%23`.
3. **no_proxy**: Настройте исключения для локальных и корпоративных ресурсов для ускорения работы.
4. **Docker**: После настройки требуется перезапуск службы Docker.
5. **Snap**: Настройки применяются только к новым snap-пакетам.
6. **Системный прокси**: Требует перезагрузки терминала или выполнения `source /etc/profile.d/proxy.sh`.

---

## 📝 Переменные окружения и файлы

| Файл/Параметр | Описание |
|---------------|----------|
| `http_proxy` | Переменная окружения для HTTP |
| `https_proxy` | Переменная окружения для HTTPS |
| `ftp_proxy` | Переменная окружения для FTP |
| `no_proxy` | Список исключений |
| `/etc/profile.d/proxy.sh` | Системные настройки прокси |
| `~/.bashrc` | Пользовательские настройки |
| `/etc/dnf/proxy.conf` | Настройки для DNF |
| `/etc/apt/apt.conf.d/proxy.conf` | Настройки для APT |
| `/etc/wgetrc` | Настройки для wget |
| `~/.curlrc` | Настройки для curl |
| `/etc/proxy-credentials` | Учётные данные (права 600) |
| `/usr/local/bin/proxy-toggle.sh` | Скрипт переключения |

---

## 🔗 Ссылки

- [NetworkManager Proxy Settings](https://networkmanager.dev/docs/api/latest/)
- [GNU Wget Manual](https://www.gnu.org/software/wget/manual/)
- [Curl Documentation](https://curl.se/docs/)
- [Docker Proxy Configuration](https://docs.docker.com/network/proxy/)
- [Git Config Documentation](https://git-scm.com/docs/git-config)
- [РЕД ОС официальная документация](https://redos.red-soft.ru/documentation)
