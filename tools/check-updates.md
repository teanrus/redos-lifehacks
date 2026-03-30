# Проверка доступных обновлений в операционной системе РЕД ОС

[![Version](https://img.shields.io/badge/version-1.0-green.svg)](https://github.com/teanrus/redos-lifehacks/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## Оглавление

- [Базовая проверка обновлений](#базовая-проверка-обновлений)
- [Автоматизация проверки](#автоматизация-проверки)
- [Проверка конкретных пакетов](#проверка-конкретных-пакетов)
- [Работа с репозиториями](#работа-с-репозиториями)
- [Логирование обновлений](#логирование-обновлений)

---

## Базовая проверка обновлений

### Быстрый просмотр всех доступных обновлений

```bash
sudo dnf check-update
```

Показывает список пакетов, для которых доступны обновления. Возвращает код выхода `100`, если обновления есть, и `0`, если система актуальна.

### Обновление с предварительным просмотром

```bash
sudo dnf check-update && sudo dnf upgrade
```

Сначала показывает доступные обновления, затем применяет их.

---

## Автоматизация проверки

### Скрипт для быстрой проверки

Создайте файл `/usr/local/bin/check-redos-updates`:

```bash
#!/bin/bash
echo "=== Проверка обновлений РЕД ОС ==="
echo "Дата: $(date)"
echo ""
sudo dnf check-update
echo ""
echo "=== Статус: $(sudo dnf check-update > /dev/null 2>&1 && echo 'Обновлений нет' || echo 'Есть доступные обновления') ==="
```

Сделайте его исполняемым:

```bash
sudo chmod +x /usr/local/bin/check-redos-updates
```

Теперь можно запускать просто: `check-redos-updates`

### Проверка в фоновом режиме

```bash
sudo dnf check-update --refresh &
```

Обновляет метаданные репозиториев и проверяет обновления в фоновом режиме.

---

## Проверка конкретных пакетов

### Поиск обновлений для конкретного пакета

```bash
sudo dnf list updates | grep <имя-пакета>
```

Пример:
```bash
sudo dnf list updates | grep kernel
```

### Проверка доступных версий пакета

```bash
dnf list --showduplicates <имя-пакета>
```

Показывает все доступные версии пакета в репозиториях.

### Проверка обновлений безопасности

```bash
sudo dnf updateinfo list security
```

Отображает только обновления, связанные с безопасностью.

---

## Работа с репозиториями

### Проверка активных репозиториев

```bash
dnf repolist
```

### Обновление метаданных репозиториев

```bash
sudo dnf makecache
```

Полезно выполнить перед проверкой обновлений, если давно не обновляли кэш.

### Проверка обновлений из конкретного репозитория

```bash
sudo dnf check-update --enablerepo=<repo-name>
```

Пример:
```bash
sudo dnf check-update --enablerepo=baseos
```

### Включение репозитория обновлений

```bash
sudo dnf config-manager --set-enabled updates
```

---

## Логирование обновлений

### Просмотр истории обновлений DNF

```bash
dnf history
```

Показывает все транзакции DNF с датами.

### Детальная информация о последней транзакции

```bash
dnf history info last
```

### Экспорт списка доступных обновлений в файл

```bash
sudo dnf check-update > ~/updates-$(date +%Y%m%d).txt 2>&1
```

### Автоматическое логирование

Добавьте в `/etc/cron.daily/log-updates`:

```bash
#!/bin/bash
sudo dnf check-update >> /var/log/dnf-updates.log 2>&1
```

---

> 💡 **Совет:** Регулярно проверяйте обновления безопасности с помощью `sudo dnf updateinfo list security` и применяйте их в первую очередь.
