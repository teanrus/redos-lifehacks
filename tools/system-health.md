# Проверка состояния системы на базе операционной системы РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 📋 Требования и совместимость

| Параметр | Значение |
| -------- | -------- |
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **Права** | обычные / root (для полного доступа) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

---

## 💡 1: Быстрая проверка загрузки системы

Проверьте основные параметры системы одной командой:

```bash
echo "=== Версия ОС ===" && cat /etc/redos-release && \
echo -e "\n=== Ядро ===" && uname -r && \
echo -e "\n=== Uptime ===" && uptime -p && \
echo -e "\n=== Загрузка CPU ===" && top -bn1 | grep "Cpu(s)" && \
echo -e "\n=== Память ===" && free -h && \
echo -e "\n=== Диск ===" && df -h /
```

**Что показывает:**
- Версию РЕД ОС и ядра
- Время работы системы
- Текущую загрузку процессора
- Использование оперативной памяти
- Свободное место на корневом разделе

---

## 💡 2: Мониторинг критичных сервисов

Проверьте статус ключевых служб:

```bash
# Проверка важных сервисов
systemctl is-active NetworkManager sshd crond firewalld

# Просмотр всех активных сервисов
systemctl list-units --type=service --state=running --no-pager

# Поиск сервисов с ошибками
systemctl list-units --state=failed --no-pager
```

**Совет:** Создайте алиас для быстрой проверки:
```bash
echo 'alias syscheck="systemctl list-units --state=failed --no-pager"' >> ~/.bashrc
source ~/.bashrc
```

---

## 💡 3: Проверка журналов системы

Анализ системного журнала через `journalctl`:

```bash
# Ошибки за последние 24 часа
journalctl --since "24 hours ago" --priority=err --no-pager

# Ошибки ядра
journalctl -k --priority=warning --no-pager | tail -50

# Логи конкретной службы
journalctl -u sshd --since today --no-pager

# Очистка старых логов (освобождение места)
journalctl --vacuum-size=100M
```

**Важно:** Регулярная очистка журналов предотвращает переполнение диска.

---

## 💡 4: Диагностика сети

Проверка сетевого подключения и настроек:

```bash
# Статус сетевых интерфейсов
ip -br addr show

# Проверка DNS
cat /etc/resolv.conf

# Тест соединения
ping -c 3 8.8.8.8

# Прослушиваемые порты
ss -tulpn | head -20

# Таблица маршрутизации
ip route show
```

---

## 💡 5: Проверка обновлений безопасности

Регулярная проверка доступных обновлений:

```bash
# Проверка доступных обновлений
sudo dnf check-update

# Список пакетов с исправлениями безопасности
sudo dnf updateinfo list sec

# Установка только обновлений безопасности
sudo dnf update --security
```

**Автоматизация:** Настройте еженедельную проверку через cron:
```bash
# /etc/cron.weekly/check-updates
#!/bin/bash
dnf check-update > /var/log/updates-check.log 2>&1
```

---

## 💡 6: Мониторинг дискового пространства

Предотвращение переполнения дисков:

```bash
# Топ-10 самых больших папок
du -ah / --max-depth=1 2>/dev/null | sort -rh | head -10

# Поиск файлов >100МБ
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Проверка inode
df -i

# Очистка кэша пакетного менеджера
sudo dnf clean all
```

**Порог тревоги:** Если использование диска >85%, начните очистку.

---

> ⚠️ **Примечание:** Некоторые команды требуют прав root. Всегда проверяйте вывод команд перед выполнением деструктивных операций.
