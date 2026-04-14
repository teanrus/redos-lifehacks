# Changelog

Все значимые изменения в проекте redos-lifehacks.

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версионирование: [Semantic Versioning](https://semver.org/lang/ru/).

---

## [v2.0] — 2026-04-14

Первый публичный релиз. Полная коллекция руководств и скриптов для РЕД ОС 7.3/8.0.

### Добавлено

#### Скрипты (30)

| Скрипт | Описание |
|--------|----------|
| `automount-sshfs.sh` | Автомонтирование SSHFS-папок при входе |
| `base-setup.sh` | Комплексная настройка: SELinux, DNF, репозитории, SSH, firewall, SSD |
| `cleanup.sh` | Очистка системы: кэш, журналы, старые ядра, корзины, бэкапы |
| `disk-usage.sh` | Анализ дискового пространства: большие файлы, дубликаты, ncdu |
| `install-1c.sh` | Установка 1С:Предприятие (клиент/сервер), КриптоПро, HASP, PostgreSQL |
| `install-cryptopro.sh` | КриптоПро CSP: зависимости, Рутокен, лицензия, ГОСТ |
| `install-messengers.sh` | Корпоративные мессенджеры: Telegram, Среда, MAX, VK Messenger |
| `install-office.sh` | Установка офисных пакетов: Р7-Офис, LibreOffice, МойОфис |
| `install-vipnet.sh` | ViPNet Client: VPN, firewall, автозапуск, импорт конфигурации |
| `mount-manager.sh` | Управление монтированием сетевых шар (CIFS/SMB): интерактивное меню, пресеты, fstab |
| `network-diagnostics.sh` | Диагностика сети: интерфейсы, DNS, маршруты, порты |
| `package-install-fix.sh` | Исправление ошибок установки пакетов: зависимости, GPG, lock |
| `redos-auto-update.sh` | Автообновление по расписанию: временное окно, режимы, уведомления MAX Messenger |
| `redos-info.sh` | Информация о системе: ОС, ядро, оборудование, диски, сеть, пакеты, сервисы |
| `redos-update-checker.sh` | Проверка и установка обновлений: DNF, безопасность, ядро |
| `rsync-copy.sh` | Интерактивное копирование файлов по SSH с проверками |
| `setup-network-printer.sh` | Сервер печати: CUPS + Samba + Avahi, Windows-клиенты, AD |
| `setup_corporate_vpn.sh` | Корпоративный VPN: OpenVPN, WireGuard, Cisco AnyConnect |
| `setup_proxy.sh` | Корпоративный прокси: HTTP/HTTPS, авторизация, DNF/Git/Docker |
| `setup_wifi.sh` | Wi-Fi: драйверы, hotspot, роуминг, энергопотребление |
| `set_password_policy.sh` | Политика паролей: yescrypt, pam_faillock, pam_pwquality |
| `set_static_ip.sh` | Статический IP: nmcli, несколько IP, автоматический откат |
| `smb-credentials-manager.sh` | Управление сохранёнными паролями SMB |
| `sound-diagnostics.sh` | Диагностика звука: PulseAudio/PipeWire, микрофон, Bluetooth |
| `system-health-check.sh` | Полная диагностика: CPU, RAM, диски, сеть, сервисы, отчёты TXT/HTML/JSON |
| `timedate.sh` | Настройка часового пояса: NTP, chrony, RTC |
| `usb-guard.sh` | Управление блокировкой USB-накопителей: UDISKS_IGNORE, authorized, белый список |
| `usb-install.sh` | Создание загрузочной USB: Ventoy, Rufus, Etcher, разметка |
| `user-migration.sh` | Миграция пользователя: файлы, браузеры, SSH-ключи, GNOME Keyring |

#### Документация

- **docs/desktop/** — рабочее окружение: SSHFS, автодополнение, среда, multi-monitor
- **docs/installation/** — установка: первые шаги, офис, принтеры, сканеры, время, USB
- **docs/network/** — сеть: прокси, статический IP, VPN, Wi-Fi, rsync
- **docs/optimization/** — оптимизация: загрузка, DNF, память, SSD, swap
- **docs/security/** — безопасность: аудит, шифрование, firewall, пароли, блокировка USB
- **docs/troubleshooting/** — решение проблем: звук, графика, сеть, принтеры, миграция, OOM, ключи
- **docs/peripheral/** — периферия: принтеры, сканеры, сервер печати, смарт-карты, штрих-коды
- **docs/monitoring/** — мониторинг: здоровье системы, логи, совместимость оборудования
- **VERSIONS.md** — полное сравнение РЕД ОС 7.x и 8.x: ядро, пакеты, архитектуры, EOL, миграция

#### Инструменты (tools/)

- `check-updates.md` — проверка обновлений системы
- `disk-usage.md` — анализ дискового пространства
- `redos-info.md` + `redos-info.sh` — информация о системе
- `system-health.md` — быстрая проверка состояния

#### Документация скриптов

- `scripts/monitoring/redos-auto-update.md` — автоматическое обновление по расписанию
- `scripts/monitoring/system-health-check.md` — полная диагностика системы

### Особенности релиза

- 28 bash-скриптов, приаттаченных к GitHub Release
- Все скрипты запускаемы через `curl -sL .../download/*.sh | sudo bash`, `wget -qO- ... | sudo bash` или локально с проверкой SHA256
- Совместимость: РЕД ОС 7.3, РЕД ОС 8.0 (x86_64, aarch64)
- Лицензия: MIT
- Отчёты: TXT, HTML, JSON
- Планирование: cron, systemd timer

---

[v2.0]: https://github.com/teanrus/redos-lifehacks/releases/tag/v2.0
