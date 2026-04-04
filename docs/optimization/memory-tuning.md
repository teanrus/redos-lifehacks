# Оптимизация потребления памяти в операционной системе РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Параметры ядра** | `vm.swappiness`, `vm.vfs_cache_pressure`, `vm.dirty_ratio` |
| **Утилиты** | `sysctl`, `free`, `zram-generator` |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x с большими объёмами RAM значение `vm.swappiness=10` рекомендуется по умолчанию. Для серверов с zram используйте `zram-generator`.

---

## 💡 1: Анализ текущего потребления памяти

Детальная информация об использовании памяти:

```bash
# Подробная статика
free -h

# Детализация по типам памяти
cat /proc/meminfo | head -30

# Топ-10 процессов по потреблению RAM
ps aux --sort=-%mem | head -11

# Мониторинг в реальном времени
htop
```

**Что искать:**
- `available` — реально доступная память (важнее, чем `free`)
- `buff/cache` — кэш, который может быть освобождён при необходимости
- Если `available < 10%` от общей RAM — система испытывает нехватку памяти

---

## 💡 2: Настройка swappiness

`swappiness` определяет, насколько активно система использует swap:

```bash
# Текущее значение (по умолчанию обычно 60)
cat /proc/sys/vm/swappiness

# Временное изменение (до перезагрузки)
sudo sysctl vm.swappiness=10

# Постоянное изменение
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf
```

**Рекомендуемые значения:**
| Сценарий | swappiness |
|----------|------------|
| Сервер с большим объёмом RAM | 10 |
| Рабочая станция | 20-30 |
| Система с малым объёмом RAM (<4 ГБ) | 60 |
| SSD-диск (меньше износ) | 10-15 |

---

## 💡 3: Включение zram для сжатия памяти

Zram создаёт сжатый блок в RAM, уменьшая использование swap на диске:

```bash
# Установка zram-generator
sudo dnf install zram-generator

# Создание конфигурации
sudo tee /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
EOF

# Активация
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service

# Проверка
swapon --show
```

**Преимущества zram:**
- Сжатие данных в RAM (коэффициент ~2.5:1)
- Меньше операций записи на диск (важно для SSD)
- Заметный прирост производительности на системах с малым объёмом RAM

---

## 💡 4: Очистка кэша памяти

Освобождение памяти, занятой под кэш:

```bash
# Просмотр кэша
free -h | grep buff/cache

# Очистка pagecache
sudo sysctl vm.drop_caches=1

# Очистка dentries и inodes
sudo sysctl vm.drop_caches=2

# Полная очистка
sudo sysctl vm.drop_caches=3
```

**Автоматизация** (скрипт для cron):
```bash
#!/bin/bash
# /etc/cron.daily/clear-cache.sh
if [ $(free -m | awk '/^Mem:/{print $7}') -lt 512 ]; then
    echo 3 > /proc/sys/vm/drop_caches
    echo "$(date): Cache cleared" >> /var/log/cache-cleanup.log
fi
```

> ⚠️ **Важно:** Очистка кэша временно снижает производительность — система будет заново загружать данные с диска.

---

## 💡 5: Оптимизация vfs_cache_pressure

Управляет склонностью ядра освобождать кэш inode и dentry:

```bash
# Текущее значение (по умолчанию 100)
cat /proc/sys/vm/vfs_cache_pressure

# Уменьшение (сохранять кэш файловой системы дольше)
sudo sysctl vm.vfs_cache_pressure=50

# Постоянная настройка
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.d/99-memory.conf
sudo sysctl -p /etc/sysctl.d/99-memory.conf
```

**Рекомендации:**
- Файловые серверы: `50-100`
- Рабочие станции с множеством мелких файлов: `30-50`
- Базы данных: `100-200`

---

## 💡 6: Настройка dirty pages

Параметры записи «грязных» страниц на диск:

```bash
# Текущие значения
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio

# Оптимизация для серверов
sudo tee -a /etc/sysctl.d/99-memory.conf << EOF
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
EOF

sudo sysctl -p /etc/sysctl.d/99-memory.conf
```

**Значения:**
| Параметр | Описание | Рекомендуемое значение |
|----------|----------|------------------------|
| `dirty_background_ratio` | % RAM, при котором начинается фоновая запись | 5 |
| `dirty_ratio` | % RAM, при котором процесс блокируется для записи | 10 |

Меньшие значения = более частая, но менее агрессивная запись на диск.

---

## 💡 7: Поиск утечек памяти

Обнаружение процессов, потребляющих чрезмерный объём RAM:

```bash
# Процессы с наибольшим RSS ( Resident Set Size )
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20

# Проверка на утечки через smaps
sudo find /proc/*/smaps -exec grep -l "Rss:" {} \; 2>/dev/null | head -5 | xargs cat 2>/dev/null | grep "^Rss:" | awk '{sum+=$2} END {print "Total RSS: " sum/1024 " MB"}'

# Мониторинг slab-кэша
sudo slabtop -s c -o | head -15
```

**Признаки утечки:**
- Постоянный рост RSS процесса без освобождения
- Увеличение `Slab` в `/proc/meminfo`
- Система не освобождает память после завершения приложений

---

## 💡 8: Отключение ненужных служб

Каждый запущенный сервис потребляет память. Отключите лишнее:

```bash
# Просмотр сервисов по потреблению памяти
systemctl list-units --type=service --state=running --no-pager

# Отключение ненужного сервиса
sudo systemctl disable --now bluetooth.service
sudo systemctl disable --now cups.service
sudo systemctl disable --now avahi-daemon.service

# Проверка экономии
free -h
```

**Кандидаты на отключение** (если не используются):
| Сервис | Назначение | Когда отключить |
|--------|------------|-----------------|
| `bluetooth` | Bluetooth | На серверах |
| `cups` | Печать | На серверах |
| `avahi-daemon` | mDNS/DNS-SD | В изолированных сетях |
| `ModemManager` | Модемы | Без 3G/4G модемов |
| `geoclue` | Геолокация | На серверах |

---

> ⚠️ **Примечание:** Изменения параметров `sysctl` могут повлиять на производительность. Тестируйте настройки в нерабочее время и делайте резервные копии конфигураций.
