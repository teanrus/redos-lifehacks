# 🕐 Настройка времени и часовых поясов на РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

> Правильная настройка времени критически важна для корректной работы системы, логов, cron-задач и сетевых сервисов. Данное руководство описывает автоматическую и ручную настройку времени в РЕД ОС с использованием российских серверов синхронизации.

---

## 📋 Содержание

1. [Автоматическая настройка (скрипт)](#1-автоматическая-настройка-скрипт)
2. [Ручная настройка времени](#2-ручная-настройка-времени)
3. [Серверы времени России](#3-серверы-времени-россии)
4. [Работа с аппаратными часами (RTC)](#4-работа-с-аппаратными-часами-rtc)
5. [Множественные часовые пояса](#5-множественные-часовые-пояса)
6. [Диагностика проблем](#6-диагностика-проблем)
7. [Чек-лист и советы](#7-чек-лист-и-советы)

---

## 1. Автоматическая настройка (скрипт)

> Скрипт `timedate.sh` автоматически устанавливает часовой пояс и настраивает синхронизацию через chrony с российскими серверами ВНИИФТРИ.

### Быстрый запуск

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/timedate.sh | sudo bash
```

### Что делает скрипт

Скрипт выполняет **6 шагов** настройки:

| Шаг | Действие | Описание |
|-----|----------|----------|
| 1/6 | Выбор часового пояса | Интерактивное меню из 11 российских поясов |
| 2/6 | Установка пояса | `timedatectl set-timezone` |
| 3/6 | Отключение NTP | Временное отключение для перенастройки |
| 4/6 | Установка chrony | Установка пакета и настройка серверов ВНИИФТРИ |
| 5/6 | Запуск chronyd | Включение службы и добавление в автозагрузку |
| 6/6 | Синхронизация | Опциональное ожидание синхронизации (до 30 сек) |

### Доступные часовые пояса

| № | Пояс | UTC |
|---|------|-----|
| 1 | Калининград | UTC+2 |
| 2 | Москва | UTC+3 |
| 3 | Самара | UTC+4 |
| 4 | Екатеринбург | UTC+5 |
| 5 | Омск | UTC+6 |
| 6 | Красноярск | UTC+7 |
| 7 | Иркутск | UTC+8 |
| 8 | Якутск | UTC+9 |
| 9 | Владивосток | UTC+10 |
| 10 | Магадан | UTC+11 |
| 11 | Камчатка | UTC+12 |

### Серверы времени

Скрипт настраивает **chrony** на официальные российские Stratum-1 серверы ВНИИФТРИ:

- `ntp1.vniiftri.ru` — основной (Менделеево)
- `ntp2.vniiftri.ru` — резервный (Менделеево)
- `ntp21.vniiftri.ru` — Сибирь

### Безопасность и надёжность

- **Проверка root-прав** — скрипт завершается с подсказкой, если запущен не от root
- **Резервная копия** — перед изменением создаётся копия `/etc/chrony.conf` с датой
- **Проверка каждой операции** — после каждого действия выводится ✓ или ✗ с завершением при ошибке
- **Чтение из `/dev/tty`** — ввод работает корректно даже при запуске через `curl | sudo bash`

### Пример вывода

```bash
=========================================
  Настройка времени на РЕД ОС
=========================================

[1/6] Выбор часового пояса

Доступные часовые пояса:

  1. Калининград (UTC+2)
  2. Москва (UTC+3)
  3. Самара (UTC+4)
  ...

Выберите номер часового пояса [2]: 4

[2/6] Установка часового пояса: Екатеринбург (UTC+5)
✓ Часовой пояс успешно выполнено

[3/6] Отключение текущей синхронизации NTP...
✓ Отключение NTP успешно выполнено

[4/6] Установка chrony...
✓ Установка chrony успешно выполнено
✓ Резервная копия /etc/chrony.conf успешно выполнено

[5/6] Настройка серверов времени...
✓ Серверы времени настроены:
  - ntp1.vniiftri.ru (ВНИИФТРИ, основной)
  - ntp2.vniiftri.ru (ВНИИФТРИ, резервный)
  - ntp21.vniiftri.ru (ВНИИФТРИ, Сибирь)

[6/6] Запуск службы chronyd...
✓ Запуск chronyd успешно выполнено

Ожидать синхронизацию времени (до 30 секунд)? (y/n): y

Ожидание синхронизации времени (до 30 секунд)...
Синхронизация выполнена!

=========================================
  Итоговая информация
=========================================
...
```

---

## 2. Ручная настройка времени

> РЕД ОС основана на RPM-пакетах (совместима с RHEL/CentOS), поэтому используются стандартные команды `timedatectl`.

### Проверка текущих настроек

```bash
timedatectl status
```

### Установка часового пояса

Посмотреть доступные часовые пояса:

```bash
timedatectl list-timezones | grep Europe
timedatectl list-timezones | grep Asia
```

Установить часовой пояс:

```bash
# Москва (UTC+3)
sudo timedatectl set-timezone Europe/Moscow

# Екатеринбург (UTC+5)
sudo timedatectl set-timezone Asia/Yekaterinburg

# Владивосток (UTC+10)
sudo timedatectl set-timezone Asia/Vladivostok
```

### Быстрое переключение поясов (алиасы)

Добавьте в `~/.bashrc`:

```bash
alias tz-msk='sudo timedatectl set-timezone Europe/Moscow && date'
alias tz-ekb='sudo timedatectl set-timezone Asia/Yekaterinburg && date'
alias tz-vlad='sudo timedatectl set-timezone Asia/Vladivostok && date'
```

Применить:

```bash
source ~/.bashrc
tz-ekb  # Переключиться на Екатеринбург
```

### Синхронизация времени

Автоматическая синхронизация (рекомендуется):

```bash
sudo timedatectl set-ntp true
```

Ручная установка времени:

```bash
# Сначала отключить NTP
sudo timedatectl set-ntp false

# Установить время (формат: YYYY-MM-DD HH:MM:SS)
sudo timedatectl set-time "2026-04-07 15:30:00"
```

### Настройка chrony вручную

```bash
# Установка
sudo dnf install chrony -y

# Редактирование конфигурации
sudo nano /etc/chrony.conf
```

Оптимальные настройки для России:

```ini
# Серверы ВНИИФТРИ (Stratum-1)
server ntp1.vniiftri.ru iburst
server ntp2.vniiftri.ru iburst
server ntp21.vniiftri.ru iburst

# Резервные серверы
server ntp3.vniiftri.ru iburst
server ntp.ix.ru iburst

# Разрешить синхронизацию даже при больших смещениях
makestep 1.0 3

# Файл с данными дрейфа
driftfile /var/lib/chrony/drift

# Логи
logdir /var/log/chrony
```

Запуск и включение:

```bash
sudo systemctl enable --now chronyd
sudo systemctl status chronyd
```

### Проверка синхронизации

```bash
# Статус синхронизации
chronyc tracking

# Источники времени
chronyc sources -v

# Статистика по источникам
chronyc sourcestats -v

# Ручная синхронизация
sudo chronyc -a makestep
```

### Альтернатива: systemd-timesyncd

Если не нужен полный NTP-сервер:

```bash
# Включить timesyncd
sudo timedatectl set-ntp true

# Проверить статус
timedatectl status

# Посмотреть логи
journalctl -u systemd-timesyncd
```

---

## 3. Серверы времени России

### Stratum-1 серверы ВНИИФТРИ

| Сервер | Расположение | Примечание |
|--------|--------------|------------|
| `ntp1.vniiftri.ru` | Менделеево | Основной |
| `ntp2.vniiftri.ru` | Менделеево | Резервный |
| `ntp21.vniiftri.ru` | Сибирь | Для восточных регионов |
| `ntp3.vniiftri.ru` | — | Резервный |

### Альтернативные серверы

| Сервер | Описание |
|--------|----------|
| `ntp.ix.ru` | MSK-IX |
| `ntp1.niiftri.irkutsk.ru` | Иркутск |
| `0.ru.pool.ntp.org` | Международный пул (Россия) |
| `1.ru.pool.ntp.org` | Международный пул (Россия) |
| `2.ru.pool.ntp.org` | Международный пул (Россия) |
| `3.ru.pool.ntp.org` | Международный пул (Россия) |

### Локальный NTP-сервер для сети

Создайте свой NTP-сервер для локальной сети:

```bash
# В /etc/chrony.conf добавить
# Разрешить синхронизацию с локальной сети
allow 192.168.0.0/16
allow 10.0.0.0/8

# Для изолированной сети (без интернета)
local stratum 10
```

---

## 4. Работа с аппаратными часами (RTC)

### Определение типа часов

```bash
timedatectl status
# RTC in local TZ: no  (если yes — часы в локальном времени)
```

### Настройка RTC

```bash
# Установить RTC в UTC (рекомендуется для Linux)
sudo timedatectl set-local-rtc 0

# Установить RTC в локальное время (для Windows dual-boot)
sudo timedatectl set-local-rtc 1
```

### Синхронизация системных и аппаратных часов

```bash
# Скопировать системное время в RTC
sudo hwclock --systohc

# Скопировать RTC в системное время
sudo hwclock --hctosys

# Показать аппаратное время
sudo hwclock --show
```

### Dual-boot (Windows + Linux)

Если Windows сбрасывает время:

```bash
# Способ 1: Заставить Windows использовать UTC
# В реестре Windows: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation
# Создать DWORD: RealTimeIsUniversal = 1

# Способ 2: Заставить Linux использовать локальное время
sudo timedatectl set-local-rtc 1
```

---

## 5. Множественные часовые пояса

### Просмотр времени в разных поясах

```bash
# Используем TZ переменную окружения
TZ=Europe/Moscow date
TZ=Asia/Yekaterinburg date
TZ=America/New_York date

# Показать время в нескольких поясах одной командой
for tz in Europe/Moscow Asia/Yekaterinburg Asia/Vladivostok America/New_York; do
    echo "$tz: $(TZ=$tz date '+%Y-%m-%d %H:%M:%S')"
done
```

### Алиасы для быстрого просмотра

```bash
# В ~/.bashrc
alias time-msk='TZ=Europe/Moscow date'
alias time-ekb='TZ=Asia/Yekaterinburg date'
alias time-ny='TZ=America/New_York date'

# Все пояса одной командой
alias time-all='for tz in Europe/Moscow Asia/Yekaterinburg Asia/Vladivostok America/New_York; do echo "$tz: \$(TZ=\$tz date \"+%H:%M:%S\")"; done'
```

### Виджет в терминале

```bash
# Постоянное отображение времени в разных поясах
watch -n 1 'echo "Москва:   $(TZ=Europe/Moscow date "+%H:%M:%S")" && \
             echo "Екат-г:   $(TZ=Asia/Yekaterinburg date "+%H:%M:%S")" && \
             echo "Владик:   $(TZ=Asia/Vladivostok date "+%H:%M:%S")"'
```

---

## 6. Диагностика проблем

### Скрипт диагностики

```bash
#!/bin/bash
# time-diag.sh - диагностика времени
echo "=== Диагностика времени ==="

# 1. Системное время
echo -e "\n1. Текущее системное время:"
date
timedatectl status | grep -E "Time zone|Local time|Universal time|RTC|NTP"

# 2. Аппаратное время
echo -e "\n2. Аппаратное время (RTC):"
sudo hwclock --show 2>/dev/null || echo "  Не удалось прочитать RTC"

# 3. Синхронизация NTP
echo -e "\n3. Статус NTP синхронизации:"
if command -v chronyc &>/dev/null; then
    chronyc tracking | grep -E "Reference time|Stratum|Leap status"
elif systemctl is-active systemd-timesyncd &>/dev/null; then
    timedatectl status | grep -E "NTP|NTP synchronized"
else
    echo "  NTP не настроен"
fi

# 4. Разница с реальным временем
echo -e "\n4. Проверка с NTP-сервером:"
ntpdate -q ntp1.vniiftri.ru 2>/dev/null | grep offset

# 5. Файлы конфигурации
echo -e "\n5. Конфигурационные файлы:"
[ -f /etc/chrony.conf ] && echo "  ✓ /etc/chrony.conf существует"
[ -f /etc/ntp.conf ] && echo "  ✓ /etc/ntp.conf существует"
echo "  Часовой пояс: $(cat /etc/timezone 2>/dev/null || echo 'не найден')"

# 6. Проблемы в логах
echo -e "\n6. Последние ошибки времени:"
journalctl -u chronyd -u systemd-timesyncd --since "1 hour ago" | grep -i "error\|fail\|time" | tail -5
```

### Решение типичных проблем

| Проблема | Решение |
| :-------| :------ |
| Время сбрасывается после перезагрузки | `sudo hwclock --systohc` |
| Большое расхождение времени | `sudo chronyc -a makestep` |
| Windows сбивает время | Настроить Windows на UTC |
| RTC в локальном времени | `sudo timedatectl set-local-rtc 0` |
| Не работает NTP | Проверить firewall: `sudo firewall-cmd --add-service=ntp` |

---

## 7. Чек-лист и советы

### Чек-лист

| Действие | Команда | Эффект |
| :------- | :------ | :----- |
| ✅ Установить часовой пояс | `timedatectl set-timezone Europe/Moscow` | Правильное локальное время |
| ✅ Включить NTP | `timedatectl set-ntp true` | Автосинхронизация |
| ✅ Установить chrony | `sudo dnf install chrony` | Точная синхронизация |
| ✅ Настроить RTC в UTC | `timedatectl set-local-rtc 0` | Совместимость с Linux |
| ✅ Создать алиасы для поясов | добавить в `.bashrc` | Быстрое переключение |
| ✅ Проверить синхронизацию | `chronyc tracking` | Контроль точности |

### Бонусные советы

**Отображение времени в формате ISO 8601**

```bash
# В .bashrc
alias now='date "+%Y-%m-%d %H:%M:%S %z"'
alias now-utc='date -u "+%Y-%m-%d %H:%M:%S UTC"'
```

**Преобразование времени между поясами**

```bash
# Конвертер времени
convert_tz() {
    local time="$1"
    local from_tz="$2"
    local to_tz="$3"
    TZ="$from_tz" date -d "$time" "+%Y-%m-%d %H:%M:%S %z"
    TZ="$to_tz" date -d "$time" "+%Y-%m-%d %H:%M:%S %z"
}
# convert_tz "2024-01-01 12:00:00" "Europe/Moscow" "America/New_York"
```

**Использование в cron-задачах**

```bash
# Запуск задачи по московскому времени независимо от системного
CRON_TZ=Europe/Moscow
0 9 * * * /path/to/script.sh
```

### Важные предостережения

> ⚠️ Не меняйте время вручную, если включен NTP — это может вызвать конфликты

> ⚠️ При изменении часового пояса перезапустите сервисы, зависящие от времени:
> ```bash
> sudo systemctl restart crond
> sudo systemctl restart rsyslog
> ```

> ⚠️ Для критичных систем используйте несколько NTP-серверов

> ⚠️ При dual-boot с Windows выберите один из двух способов синхронизации, иначе время будет постоянно сбиваться

> ⚠️ Проверяйте `tzdata` перед важными событиями:
> ```bash
> sudo dnf update tzdata -y
> ```

---

**Эти инструкции помогут вам настроить корректное отображение времени, синхронизацию с российскими NTP-серверами и избежать проблем с временными метками в логах и задачах. Правильная настройка времени — основа стабильной работы любой системы!**

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Синхронизация** | chrony (рекомендуется), systemd-timesyncd |
| **Утилиты** | `timedatectl`, `chronyc`, `hwclock` |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 7.x и 8.x `chrony` предпочтителен для NTP-синхронизации. Для изолированных сетей настройте `local stratum 10` в конфигурации chrony. Рекомендуется использовать российские серверы ВНИИФТРИ (`ntp1.vniiftri.ru`, `ntp2.vniiftri.ru`) для максимальной точности синхронизации.
