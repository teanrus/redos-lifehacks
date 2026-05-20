# Changelog

Все значимые изменения в проекте redos-lifehacks.

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![Формат](https://img.shields.io/badge/Формат-Keep%20a%20Changelog%201.1.0-009812?style=for-the-badge)](https://keepachangelog.com/ru/1.1.0/)
[![Версионирование](https://img.shields.io/badge/Версионирование-Semantic%20Versioning%202.0.0-3F81FF?style=for-the-badge)](https://semver.org/lang/ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

---

## [Unreleased]

- 📖 **Wiki репозитория** — расширенная документация на [GitHub Wiki](https://github.com/teanrus/redos-lifehacks/wiki)
  
- Сравнение версий РЕД ОС 7.x и 8.x
- Руководства по миграции и диагностике
- Дополнительные сценарии использования

---

## [v2.0] — 2026-04-15

Публичный релиз. Коллекция руководств и скриптов для РЕД ОС 7.3/8.0.

### Добавлено

#### Скрипты

| Скрипт | Описание | Документация |
| --- | --- | --- |
| `automount-sshfs.sh` | Автомонтирование SSHFS-папок при входе | [Открыть](docs/desktop/automount-sshfs.md) |
| `base-setup.sh` | Комплексная настройка: SELinux, DNF, репозитории, SSH, firewall, SSD | [1](scripts/setup/base-setup.md), [2](docs/installation/first-steps.md) |
| `cleanup.sh` | Очистка системы: кэш, журналы, старые ядра, корзины, бэкапы | [Открыть](scripts/utils/cleanup.md) |
| `disk-usage.sh` | Анализ дискового пространства: большие файлы, дубликаты, ncdu | [Открыть](tools/disk-usage.md) |
| `install-messengers.sh` | Корпоративные мессенджеры: Telegram, Среда, MAX, VK Messenger | [Открыть](scripts/install/install-messengers.md) |
| `install-office.sh` | Установка офисных пакетов: Р7-Офис, LibreOffice, МойОфис | [Открыть](docs/installation/office-setup.md) |
| `install-vipnet.sh` | ViPNet Client: VPN, firewall, автозапуск, импорт конфигурации | [Открыть](scripts/install/install-vipnet.md) |
| `mount-manager.sh` | Управление монтированием сетевых шар (CIFS/SMB): интерактивное меню, пресеты, fstab | [Открыть](scripts/utils/mount-manager.md) |
| `network-diagnostics.sh` | Диагностика сети: интерфейсы, DNS, маршруты, порты | [Открыть](docs/troubleshooting/network-issues.md) |
| `quick-check.sh` | Быстрая проверка состояния системы | [Открыть](docs/monitoring/quick-check.md) |
| `redos-auto-update.sh` | Автообновление по расписанию: временное окно, режимы, уведомления MAX Messenger | [Открыть](scripts/monitoring/redos-auto-update.md) |
| `redos-info.sh` | Информация о системе: ОС, ядро, оборудование, диски, сеть, пакеты, сервисы | [Открыть](tools/redos-info.md) |
| `redos-update-checker.sh` | Проверка и установка обновлений: DNF, безопасность, ядро | [Открыть](tools/check-updates.md) |
| `rsync-copy.sh` | Интерактивное копирование файлов по SSH с проверками | [1](scripts/utils/rsync-copy.md), [2](docs/network/rsync-file-copy.md) |
| `set_password_policy.sh` | Политика паролей: yescrypt, pam_faillock, pam_pwquality | [Открыть](docs/security/password-policy.md) |
| `set_static_ip.sh` | Статический IP: nmcli, несколько IP, автоматический откат | [Открыть](docs/network/static-ip.md) |
| `setup_corporate_vpn.sh` | Корпоративный VPN: OpenVPN, WireGuard, Cisco AnyConnect | [Открыть](docs/network/vpn-settings.md) |
| `setup_network-printer.sh` | Сервер печати: CUPS + Samba + Avahi, Windows-клиенты, AD | [Открыть](docs/peripheral/network-printer-server.md) |
| `setup_proxy.sh` | Корпоративный прокси: HTTP/HTTPS, авторизация, DNF/Git/Docker | [Открыть](docs/network/proxy-setup.md) |
| `setup_wifi.sh` | Wi-Fi: драйверы, hotspot, роуминг, энергопотребление | [Открыть](docs/network/wifi-setup.md) |
| `smb-credentials-manager.sh` | Управление сохранёнными паролями SMB | [Открыть](scripts/utils/smb-credentials-manager.md) |
| `sound-diagnostics.sh` | Диагностика звука: PulseAudio/PipeWire, микрофон, Bluetooth | [Открыть](docs/troubleshooting/audio-issues.md) |
| `system-health-check.sh` | Полная диагностика: CPU, RAM, диски, сеть, сервисы, отчёты TXT/HTML/JSON | [1](scripts/monitoring/system-health-check.md), [2](docs/monitoring/system-health-check.md) |
| `timedate.sh` | Настройка часового пояса: NTP, chrony, RTC | [Открыть](docs/installation/timezone-setup.md) |
| `usb-guard.sh` | Управление блокировкой USB-накопителей: UDISKS_IGNORE, authorized, белый список | [1](scripts/utils/usb-guard.md), [2](docs/security/usb-guard.md) |
| `usb-install.sh` | Создание загрузочной USB: Ventoy, Rufus, Etcher, разметка | [Открыть](docs/installation/usb-install.md) |
| `user-migration.sh` | Миграция пользователя: файлы, браузеры, SSH-ключи, очистка GNOME Keyring | [Открыть](scripts/utils/user-migration.md) |

### Особенности релиза

- Скрипты организованы по категориям: setup, install, utils, monitoring
- Все скрипты запускаемы через `curl -sL .../download/*.sh | sudo bash`, `wget -qO- ... | sudo bash` или локально с проверкой SHA256
- Совместимость: РЕД ОС 7.3, РЕД ОС 8.0 (x86_64, aarch64)
- Лицензия: MIT
- Отчёты: TXT, HTML, JSON
- Планирование: cron, systemd timer
- Подробная документация в `docs/` с руководствами по настройке

---

[![Release v2.0](https://img.shields.io/badge/Release-v2.0-blue?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/releases/tag/v2.0)
[![Unreleased](https://img.shields.io/badge/Unreleased-changes-orange?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/compare/v2.0...HEAD)
[![Wiki](https://img.shields.io/badge/Wiki-documentation-purple?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/wiki)
[![Contributing](https://img.shields.io/badge/Contributing-guide-yellow?style=for-the-badge)](CONTRIBUTING.md)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)
