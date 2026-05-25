# Автоматическая установка корпоративных обоев рабочего стола

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![RED OS](https://img.shields.io/badge/RED%20OS-7.3%20%7C%208.x-b30000?style=for-the-badge)](https://redos.red-soft.ru/)
[![RHEL](https://img.shields.io/badge/RHEL-8%20%7C%209-ee0000?style=for-the-badge)](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux)
[![Fedora](https://img.shields.io/badge/Fedora-39%20%7C%2040-0B57A4?style=for-the-badge)](https://fedoraproject.org/)
[![CentOS](https://img.shields.io/badge/CentOS-Stream%208%20%7C%209-262477?style=for-the-badge)](https://www.centos.org/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

> 📋 **Назначение**: Скрипты `setup-wallpaper.sh` и `remove-corporate-wallpaper.sh` предназначены для централизованной установки и управления корпоративными обоями рабочего стола из SMB-шары в Linux-системах с последующей блокировкой возможности изменения обоев пользователями.

**Поддерживаемые окружения**: GNOME, MATE, XFCE, KDE Plasma  
**Требования**: права `root`, пакет `cifs-utils`, Bash ≥ 4.0

---

## 📦 Компоненты

| Файл | Назначение |
|------|-----------|
| `setup-wallpaper.sh` | Установка обоев, применение lockdown, настройка автозапуска |
| `remove-corporate-wallpaper.sh` | Полный откат изменений, восстановление конфигураций |
| `apply-corporate-wallpaper.sh` | (создаётся автоматически) Применение обоев при входе пользователя |

---

## ⚙️ Настраиваемые параметры

### Основные переменные (в начале `setup-wallpaper.sh`)

| Переменная | Описание | Пример |
|------------|----------|--------|
| `SMB_SERVER` | IP-адрес или имя SMB-сервера | `192.168.22.11` |
| `SMB_SHARE` | Имя сетевой папки (шары) | `Share` |
| `SMB_FOLDER` | Каталог внутри шары | `backgrounds` |
| `SMB_FILE` | Имя файла обоев | `corporate-wallpaper.jpg` |
| `DESKTOP_ENV` | Окружение: `AUTO`, `GNOME`, `KDE`, `XFCE`, `MATE`, `ALL` | `AUTO` |

### Аутентификация SMB (рекомендуемый способ)

⚠️ **Не указывайте пароль в скрипте!** Используйте файл учётных данных:

```bash
# /etc/smb-credentials/corp-wallpaper
username=domain\wallpaper_user
password=YourSecurePassword
domain=WORKGROUP
```

```bash
# Настройка прав (обязательно!)
sudo chmod 600 /etc/smb-credentials/corp-wallpaper
sudo chown root:root /etc/smb-credentials/corp-wallpaper
```

| Переменная | Описание | Значение по умолчанию |
|------------|----------|---------------------|
| `SMB_CRED_FILE` | Путь к файлу учётных данных | `/etc/smb-credentials/corp-wallpaper` |
| `SMB_USER` / `SMB_PASS` | Резервный способ (не рекомендуется) | пустые |

### Пути и логирование

| Переменная | Описание | Значение |
|------------|----------|----------|
| `LOCAL_WALLPAPER_DIR` | Каталог для хранения обоев | `/usr/share/wallpapers` |
| `LOCAL_WALLPAPER` | Итоговый путь к файлу | `/usr/share/wallpapers/corporate-wallpaper.jpg` |
| `LOG_FILE` | Файл журнала | `/var/log/corporate-wallpaper.log` |
| `APPLY_SCRIPT` | Скрипт применения при входе | `/usr/local/bin/apply-corporate-wallpaper.sh` |

---

## 🚀 Быстрый старт

### 1. Подготовка учётных данных (рекомендуется)

```bash
sudo mkdir -p /etc/smb-credentials
sudo tee /etc/smb-credentials/corp-wallpaper > /dev/null <<EOF
username=domain\wallpaper_user
password=YourSecurePassword
EOF
sudo chmod 600 /etc/smb-credentials/corp-wallpaper
sudo chown root:root /etc/smb-credentials/corp-wallpaper
```

### 2. Загрузка и запуск

```bash
mkdir -p ~/scripts && cd ~/scripts
curl -LO https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup-wallpaper.sh
curl -LO https://github.com/teanrus/redos-lifehacks/releases/latest/download/setup-wallpaper.sh.sha256
sha256sum -c setup-wallpaper.sh.sha256
chmod +x setup-wallpaper.sh

# Запуск установки
sudo ./setup-wallpaper.sh
```

### 3. Обновление обоев (только если изменился файл)

```bash
sudo UPDATE_MODE=true ./setup-wallpaper.sh
# или
sudo ./setup-wallpaper.sh --update
```

---

## 🔄 Скрипт отката `remove-corporate-wallpaper.sh`

Для полного удаления корпоративных обоев и восстановления пользовательских настроек:

```bash
curl -LO https://github.com/teanrus/redos-lifehacks/releases/latest/download/remove-corporate-wallpaper.sh
chmod +x remove-corporate-wallpaper.sh
sudo ./remove-corporate-wallpaper.sh
```

### Что делает скрипт отката

- ✅ Снимает атрибут `immutable` (`chattr -i`) и удаляет файл обоев
- ✅ Удаляет скрипт применения и автозапуск для всех пользователей
- ✅ Восстанавливает `dconf`-настройки GNOME/MATE (удаляет кастомные правила)
- ✅ Откатывает XFCE kiosk-режим и конфиги
- ✅ Восстанавливает `/etc/xdg/kdeglobals` из бэкапа (KDE)
- ✅ Очищает профильные конфиги KDE и обновляет кеш (`kbuildsycoca5`)

> 💡 После отката пользователям рекомендуется **перезайти в сессию** для применения изменений.

---

## 🧠 Логика работы `setup-wallpaper.sh`

### 1. Проверка окружения и зависимостей

- Проверка прав `root` (`EUID`)
- Валидация обязательных переменных (`SMB_SERVER`, `SMB_SHARE`)
- Проверка наличия `cifs-utils` → автоустановка через `dnf`/`apt`
- Логирование всех этапов в `/var/log/corporate-wallpaper.log`

### 2. Определение графического окружения (при `DESKTOP_ENV=AUTO`)

Последовательная проверка:

1. Переменные `$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION`
2. Активные сессии через `loginctl`
3. Запущенные процессы (`gnome-shell`, `plasmashell`, etc.)
4. Установленные пакеты (`rpm -q`)

Результат: `GNOME` | `MATE` | `XFCE` | `KDE` | `ALL` | `UNKNOWN`

### 3. Безопасное монтирование SMB

```bash
# Создаётся временная точка через mktemp
MOUNT_POINT=$(mktemp -d /mnt/corp-wallpaper.XXXXXX)

# Монтирование с параметрами безопасности
mount -t cifs "//${SMB_SERVER}/${SMB_SHARE}" "${MOUNT_POINT}" \
    -o credentials=${SMB_CRED_FILE},ro,vers=3.0,sec=ntlmssp,noserverino
```

### 4. Копирование и защита обоев

- Копирование в `/usr/share/wallpapers/corporate-wallpaper.jpg`
- Установка прав `644`, владелец `root:root`
- Применение `chattr +i` (с обработкой ошибки, если ФС не поддерживает)
- **Режим `--update`**: сравнение `sha256sum` перед перезаписью

### 5. Применение настроек для каждого DE

#### GNOME / MATE (dconf)

- Создаётся правило в `/etc/dconf/db/local.d/00-corporate-wallpaper`
- Блокировка ключей через `/etc/dconf/db/local.d/locks/`
- Выполняется `dconf update`
- ⚠️ Не перезаписывает `/etc/dconf/profile/user` — совместимо с другими корпоративными политиками

#### XFCE

- Включает kiosk-режим: `/etc/xdg/xfce4/kiosk/kioskrc`
- Фиксирует путь к обоям в `xfce4-desktop.xml`
- Блокирует `CustomizeBackdrop=NONE`

#### KDE Plasma

- Создаёт бэкап `/etc/xdg/kdeglobals.backup` (если не существует)
- Добавляет секции `[Wallpaper]` и `[KDE Action Restrictions]`
- Создаёт профиль `/etc/kde/profile.d/corporate-wallpaper.conf`
- Обновляет кеш: `kbuildsycoca5 --noincremental`

### 6. Автозапуск при входе

Создаётся `/etc/xdg/autostart/corporate-wallpaper.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=Corporate Wallpaper Enforcer
Exec=/usr/local/bin/apply-corporate-wallpaper.sh
X-GNOME-Autostart-enabled=true
X-KDE-autostart-phase=2
```

- Копируется в `/etc/skel/` для новых пользователей
- Применяется ко всем существующим `/home/*` с корректными правами

### 7. Скрипт применения `apply-corporate-wallpaper.sh`

Выполняется при каждом входе пользователя:

- Определяет текущее DE через `$XDG_CURRENT_DESKTOP`
- Ждёт инициализации окружения (`until ...; do sleep 1; done`)
- Применяет обои через нативные инструменты:
  - **GNOME**: `gsettings set org.gnome.desktop.background ...`
  - **MATE**: `gsettings set org.mate.background ...`
  - **XFCE**: `xfconf-query -c xfce4-desktop ...`
  - **KDE**: `qdbus` + JavaScript-оценщик Plasma

---

## 🛡 Безопасность

| Угроза | Мера защиты |
|--------|-------------|
| Пароль в коде | ✅ Файл учётных данных с правами `600` |
| Перехват трафика | ✅ Опции `sec=ntlmssp`, `vers=3.0`, `ro` при монтировании |
| Случайное изменение обоев | ✅ Атрибут `chattr +i` (immutable) |
| Конфликт конфигов | ✅ Изолированные правила в `local.d`, бэкапы `kdeglobals` |
| Утечка через логи | ✅ Логирование только метаданных, без паролей |

> 🔐 **Рекомендация**: Используйте отдельную учётную запись с минимальными правами (только чтение) для доступа к SMB-шаре.

---

## 🧹 Отладка и логирование

Все события записываются в `/var/log/corporate-wallpaper.log`:

```bash
# Просмотр последних событий
sudo tail -f /var/log/corporate-wallpaper.log

# Поиск ошибок
sudo grep -i "error\|fail" /var/log/corporate-wallpaper.log

# Проверка статуса монтирования
mount | grep corp-wallpaper
```

### Типовые проблемы

| Симптом | Возможная причина | Решение |
|---------|------------------|---------|
| `Failed to mount SMB share` | Неверные учётные данные / нет доступа к порту 445 | Проверить `SMB_CRED_FILE`, firewall, доступность сервера |
| `chattr +i failed` | ФС не поддерживает immutable (NFS, некоторые LVM) | Предупреждение не критично, защита на уровне прав `644` остаётся |
| Обои не применяются в KDE | Не обновлён кеш конфигураций | Убедиться, что `kbuildsycoca5` доступен в `$PATH` |
| `dconf: not found` | Не установлен пакет `dconf` | Установить: `dnf install dconf` (GNOME/MATE) |
| Скрипт завершается с ошибкой | Включён `set -euo pipefail` | Проверить лог, убедиться в наличии всех зависимостей |

---

## 📦 Требования к системе

| Компонент | Минимальная версия | Примечание |
|-----------|-------------------|------------|
| ОС | RHEL 8+, Fedora 39+, РЕД ОС 7.3+ | Поддержка `bash ≥ 4.0`, `systemd` |
| Пакеты | `cifs-utils`, `dconf`, `xfconf`, `qdbus` | Устанавливаются автоматически при наличии пакетного менеджера |
| Сеть | Доступ к порту **445/TCP** (SMB/CIFS) | Проверить: `nc -zv SMB_SERVER 445` |
| Права | `root` (через `sudo`) | Для изменения системных конфигов |

---

## 🧪 Тестирование перед продакшеном

```bash
# 1. Запуск в режиме сухой проверки (добавьте --dry-run при необходимости)
sudo ./setup-wallpaper.sh 2>&1 | tee /tmp/wallpaper-test.log

# 2. Проверка применения для текущего пользователя
su -l testuser -c "/usr/local/bin/apply-corporate-wallpaper.sh"

# 3. Визуальная проверка: обои установлены, настройки заблокированы

# 4. Откат при необходимости
sudo ./remove-corporate-wallpaper.sh
```

---

## 📜 Лицензия и отказ от ответственности

Скрипты распространяются под лицензией **MIT**.  
Автор не несёт ответственности за возможные проблемы при использовании, включая потерю данных или некорректную работу системы.

> ⚠️ **Рекомендуется**:  
>
> - Создавать резервные копии `/etc/xdg/kdeglobals`, `/etc/dconf/db/` перед запуском  
> - Тестировать в изолированной среде перед развёртыванием на продуктивных системах  
> - Использовать систему управления конфигурациями (Ansible, Salt) для массового внедрения

---

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку `feature/your-improvement`
3. Внесите изменения с соблюдением `shellcheck` и стиля кода
4. Откройте Pull Request с описанием изменений

---

> 📌 **Подсказка**: Для интеграции с Ansible/Salt подготовлены отдельные плейбуки — см. каталог `ansible/` в репозитории.

[⬆️ Вернуться к списку lifehacks](../../README.md)
