# Changelog

Все значимые изменения в проекте redos-lifehacks.

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версионирование: [Semantic Versioning](https://semver.org/lang/ru/).

---

## [v2.0] — 2026-04-14

Первый публичный релиз. Полная коллекция руководств и скриптов для РЕД ОС 7.3/8.0.

### Добавлено

#### Скрипты (29)

| Скрипт | Описание |
| ------ | -------- |
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
| `quick-check.sh` | Быстрая проверка состояния системы |
| `redos-auto-update.sh` | Автообновление по расписанию: временное окно, режимы, уведомления MAX Messenger |
| `redos-info.sh` | Информация о системе: ОС, ядро, оборудование, диски, сеть, пакеты, сервисы |
| `redos-update-checker.sh` | Проверка и установка обновлений: DNF, безопасность, ядро |
| `rsync-copy.sh` | Интерактивное копирование файлов по SSH с проверками |
| `set_password_policy.sh` | Политика паролей: yescrypt, pam_faillock, pam_pwquality |
| `set_static_ip.sh` | Статический IP: nmcli, несколько IP, автоматический откат |
| `setup_corporate_vpn.sh` | Корпоративный VPN: OpenVPN, WireGuard, Cisco AnyConnect |
| `setup_network-printer.sh` | Сервер печати: CUPS + Samba + Avahi, Windows-клиенты, AD |
| `setup_proxy.sh` | Корпоративный прокси: HTTP/HTTPS, авторизация, DNF/Git/Docker |
| `setup_wifi.sh` | Wi-Fi: драйверы, hotspot, роуминг, энергопотребление |
| `smb-credentials-manager.sh` | Управление сохранёнными паролями SMB |
| `sound-diagnostics.sh` | Диагностика звука: PulseAudio/PipeWire, микрофон, Bluetooth |
| `system-health-check.sh` | Полная диагностика: CPU, RAM, диски, сеть, сервисы, отчёты TXT/HTML/JSON |
| `timedate.sh` | Настройка часового пояса: NTP, chrony, RTC |
| `usb-guard.sh` | Управление блокировкой USB-накопителей: UDISKS_IGNORE, authorized, белый список |
| `usb-install.sh` | Создание загрузочной USB: Ventoy, Rufus, Etcher, разметка |
| `user-migration.sh` | Миграция пользователя: файлы, браузеры, SSH-ключи, GNOME Keyring |

### Особенности релиза

- 29 bash-скриптов в `scripts/` и `docs/`
- Скрипты организованы по категориям: setup, install, utils, monitoring
- Все скрипты запускаемы через `curl -sL .../download/*.sh | sudo bash`, `wget -qO- ... | sudo bash` или локально с проверкой SHA256
- Совместимость: РЕД ОС 7.3, РЕД ОС 8.0 (x86_64, aarch64)
- Лицензия: MIT
- Отчёты: TXT, HTML, JSON
- Планирование: cron, systemd timer
- Подробная документация в `docs/` с руководствами по настройке

---

[v2.0]: https://github.com/teanrus/redos-lifehacks/releases/tag/v2.0
