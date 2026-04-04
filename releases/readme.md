# Скрипты releases

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

В этой директории находятся **готовые bash-скрипты**, доступные для загрузки через GitHub Releases.

**Быстрый запуск любого скрипта:**
```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/<имя-скрипта>.sh | sudo bash
```

---

## 📋 Таблица скриптов

### ⚙️ Настройка системы

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`setup.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup.sh) | Мета-скрипт: репозитории, ядро, ПО, ViPNet, КриптоПро, 1С, мессенджеры | ⚠️ 7.x | [`scripts/setup/readme.md`](/scripts/setup/readme.md) |
| [`base-setup.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/base-setup.sh) | Базовая настройка: SELinux, DNF, репозитории, SSH, firewall, оптимизация | ⚠️ 7.x | [`scripts/setup/base-setup.md`](/scripts/setup/base-setup.md) |
| [`cleanup.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh) | Очистка: /tmp, кэш DNF, логи, браузеры, старые ядра, корзина | ✅ 7.x + 8.x | [`scripts/utils/cleanup.md`](/scripts/utils/cleanup.md) |

### 📦 Установка ПО

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`install-1c.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-1c.sh) | 1С:Предприятие: зависимости, клиент/сервер, КриптоПро, HASP | ⚠️ 7.x | [`scripts/install/install-1c.md`](/scripts/install/install-1c.md) |
| [`install-cryptopro.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-cryptopro.sh) | КриптоПро CSP: зависимости, Рутокен, ГОСТ, лицензирование | ✅ 7.x + 8.x | [`scripts/install/install-cryptopro.md`](/scripts/install/install-cryptopro.md) |
| [`install-messengers.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh) | Мессенджеры: Telegram, Среда, MAX, VK Messenger | ✅ 7.x + 8.x | [`scripts/install/install-messengers.md`](/scripts/install/install-messengers.md) |
| [`install-vipnet.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh) | ViPNet Client: VPN, firewall, автозапуск | ⚠️ 7.x | [`scripts/install/install-vipnet.md`](/scripts/install/install-vipnet.md) |
| [`install-office.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-office.sh) | Офисные пакеты: LibreOffice, Р7-Офис, МойОфис | ✅ 7.x + 8.x | [`docs/installation/office-setup.md`](/docs/installation/office-setup.md) |

### 🌐 Сеть

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`set_static_ip.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/set_static_ip.sh) | Статический IP: nmcli, бэкап, DNS | ✅ 7.x + 8.x | [`docs/network/static-ip.md`](/docs/network/static-ip.md) |
| [`setup_wifi.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_wifi.sh) | Wi-Fi: драйверы, подключение, hotspot, роуминг | ✅ 7.x + 8.x | [`docs/network/wifi-setup.md`](/docs/network/wifi-setup.md) |
| [`setup_proxy.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_proxy.sh) | Прокси: системный, DNF, Git, Docker, wget/curl | ✅ 7.x + 8.x | [`docs/network/proxy-setup.md`](/docs/network/proxy-setup.md) |
| [`setup_corporate_vpn.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup_corporate_vpn.sh) | VPN: OpenVPN, WireGuard, Cisco AnyConnect, split-tunneling | ✅ 7.x + 8.x | [`docs/network/vpn-settings.md`](/docs/network/vpn-settings.md) |
| [`setup-network-printer.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup-network-printer.sh) | Сетевой принтер: CUPS, firewalld, общий доступ | ✅ 7.x + 8.x | [`docs/peripheral/network-printer-server.md`](/docs/peripheral/network-printer-server.md) |

### 🔍 Диагностикака

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`network-diagnostics.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/network-diagnostics.sh) | Сетевая диагностика: интерфейсы, драйверы, DNS, firewall, Wi-Fi | ✅ 7.x + 8.x | [`docs/troubleshooting/network-issues.md`](/docs/troubleshooting/network-issues.md) |
| [`sound-diagnostics.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/sound-diagnostics.sh) | Диагностика звука: ALSA, PulseAudio, PipeWire, громкость | ✅ 7.x + 8.x | [`docs/troubleshooting/audio-issues.md`](/docs/troubleshooting/audio-issues.md) |
| [`package-install-fix.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/package-install-fix.sh) | Фикс установки ПО: репозитории, зависимости, кэш DNF, RPM база | ✅ 7.x + 8.x | [`docs/troubleshooting/software-issues.md`](/docs/troubleshooting/software-issues.md) |

### 🔧 Утилиты

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`redos-update-checker.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-update-checker.sh) | Проверка обновлений: обновления, безопасность, ядро, отчёт | ✅ 7.x + 8.x | [`tools/check-updates.md`](/tools/check-updates.md) |
| [`redos-info.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-info.sh) | Информация о системе: ОС, ядро, железо, диски, сеть, пакеты | ✅ 7.x + 8.x | [`tools/redos-info.md`](/tools/redos-info.md) |
| [`disk-usage.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/disk-usage.sh) | Анализ диска: df, du, большие файлы, кэш, дубликаты | ✅ 7.x + 8.x | [`tools/disk-usage.md`](/tools/disk-usage.md) |

### 🚀 Миграция и установка

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`user-migration.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/user-migration.sh) | Миграция пользователя: перенос данных, браузеров, прав | ✅ 7.x + 8.x | [`docs/troubleshooting/user-migration.md`](/docs/troubleshooting/user-migration.md) |
| [`usb-install.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/usb-install.sh) | Загрузочная USB: Ventoy, ISO РЕД ОС | ✅ 7.x + 8.x | [`docs/installation/usb-install.md`](/docs/installation/usb-install.md) |

### 🖥️ Рабочий стол

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`automount-sshfs.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/automount-sshfs.sh) | Автомонтирование SSHFS: fstab, systemd, автозагрузка, SSH-ключи | ✅ 7.x + 8.x | [`docs/desktop/automount-sshfs.md`](/docs/desktop/automount-sshfs.md) |

### 🔒 Безопасность

| Скрипт | Описание | Совместимость | Документация |
|--------|----------|:-------------:|-------------|
| [`set_password_policy.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/set_password_policy.sh) | Политика паролей: yescrypt, pam_faillock, аудит, sudo | ✅ 7.x + 8.x | [`docs/security/password-policy.md`](/docs/security/password-policy.md) |

---

## 📊 Сводка совместимости

| Совместимость | Количество скриптов | Скрипты |
|:-------------:|:-------------------:|---------|
| ✅ **7.x + 8.x** | **19** | Все универсальные скрипты |
| ⚠️ **Только 7.x** | **4** | `setup.sh`, `base-setup.sh`, `install-1c.sh`, `install-vipnet.sh` |

### Почему некоторые скрипты только для 7.x?

| Скрипт | Причина |
|--------|---------|
| `setup.sh` | Хардкод «РЕД ОС 7.3»; репозиторий MAX `el/9` конфликтует с 7.x |
| `base-setup.sh` | Привязка к `redos-kernels6-release`; специфичный часовой пояс |
| `install-1c.sh` | Зависимость `libpng12` недоступна в РЕД ОС 8.x |
| `install-vipnet.sh` | RPM-пакет жёстко привязан к версии для 7.x |

---

## 🚀 Быстрый старт

### Полная настройка новой системы (РЕД ОС 7.3)

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup.sh | sudo bash
```

### Базовая настройка (без ПО)

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/base-setup.sh | sudo bash
```

### Очистка системы

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/cleanup.sh | sudo bash
```

### Проверка здоровья системы

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-info.sh | sudo bash
```

---

## ⚠️ Предостережения

- Все скрипты требуют **прав root** (sudo)
- Перед запуском **прочитайте документацию** — понимайте, что делает скрипт
- Скрипты `setup.sh` и `base-setup.sh` **отключают SELinux** — не рекомендуется для сертифицированных сред
- Всегда делайте **резервную копию** перед запуском
- Скрипты протестированы на **РЕД ОС 7.3 x86_64** — совместимость с 8.x не гарантируется для всех

---

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
