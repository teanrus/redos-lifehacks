# Несколько рекомендаций по ускорению загрузки системы в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 🚀 1. Оптимизация служб (сервисов)
### Отключение ненужных сервисов
Проверьте, какие службы запускаются при загрузке:
```bash
# Список всех включенных служб
systemctl list-unit-files --type=service --state=enabled
# Анализ времени загрузки
systemd-analyze blame
# Критический путь загрузки
systemd-analyze critical-chain
```
Отключите ненужные службы:
```bash
# Примеры служб, которые часто можно отключить
sudo systemctl disable cups           # если не используете принтеры
sudo systemctl disable bluetooth      # если нет Bluetooth
sudo systemctl disable avahi-daemon   # если не используете mDNS
sudo systemctl disable ModemManager   # если нет модема
sudo systemctl disable firewalld      # если используете iptables/nftables (осторожно!)
```
## 🖥️ 2. Настройка загрузчика GRUB
### Уменьшение таймаута выбора меню
Отредактируйте /etc/default/grub:
```bash
sudo nano /etc/default/grub
```
Измените параметры:
```ini
# Уменьшить время ожидания меню
GRUB_TIMEOUT=2
# Скрыть меню (если не нужен выбор ОС)
GRUB_TIMEOUT_STYLE=hidden
# Добавить параметры для ускорения ядра
GRUB_CMDLINE_LINUX="quiet splash rhgb"
```
После изменений обновите конфигурацию:
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
## 🧹 3. Очистка и оптимизация автозагрузки
Проверьте пользовательские автозагрузки:
```bash
# Системные автозагрузки
ls /etc/xdg/autostart/
ls /usr/share/applications/autostart/
# Пользовательские автозагрузки
ls ~/.config/autostart/
```
Отключите ненужные приложения:
```bash
# Пример: отключить Skype из автозагрузки
sudo mv /etc/xdg/autostart/skypeforlinux.desktop /etc/xdg/autostart/skypeforlinux.desktop.disabled
```
Маскировка служб (полное отключение)
```bash
# Маскировка службы (запрет на включение)
sudo systemctl mask <служба>
```
## ⚡ 4. Оптимизация ядра
### Параметры загрузки ядра
Добавьте параметры для ускорения загрузки в GRUB_CMDLINE_LINUX:
```ini
GRUB_CMDLINE_LINUX="quiet rhgb nowatchdog nmi_watchdog=0 audit=0"
```
Пояснение параметров:
- `nowatchdog` — отключает аппаратный сторожевой таймер
- `nmi_watchdog=0` — отключает NMI watchdog
- `audit=0` — отключает аудит (если не нужен)
- `quiet` — скрывает лишние сообщения
- `rhgb` — графическая загрузка (красный экран)
После обновления:
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
## 🔧 5. Оптимизация Dracut (initramfs)
### Уменьшение размера initramfs
Отредактируйте /etc/dracut.conf.d/optimize.conf:
```ini
# Отключить ненужные модули
omit_dracutmodules+=" systemd network iscsi nfs mdraid lvm "
# Уменьшить сжатие для скорости (быстрее распаковка)
compress="lz4"
```
Пересоберите initramfs:
```bash
sudo dracut --force --regenerate-all
```
## 💾 6. Оптимизация дисковых операций
### Настройка fstab
Добавьте параметры монтирования в /etc/fstab:
```bash
# Пример для SSD с noatime (отключает обновление времени доступа)
UUID=xxx-xxx-xxx / ext4 defaults,noatime,nodiratime 1 1
# Для tmpfs (временные файлы в RAM)
tmpfs /tmp tmpfs defaults,noexec,nosuid,size=2G 0 0
```
Отключение fsck для быстрой загрузки
```bash
# Проверка последнего fsck
sudo tune2fs -l /dev/sda1 | grep "Mount count"
# Установить интервал проверки (опционально)
sudo tune2fs -c 0 -i 0 /dev/sda1  # отключает периодическую проверку
```
## 🔄 7. Оптимизация systemd
### Параллельный запуск служб
В /etc/systemd/system.conf:
```ini
[Manager]
# Увеличить лимит параллельных заданий
DefaultTasksMax=512
# Включить параллельный запуск
DefaultTimeoutStartSec=30s
```
Использование маскировки
```bash
# Маскировка служб, которые долго инициализируются
sudo systemctl mask systemd-networkd-wait-online.service
```
## 📊 8. Мониторинг и анализ
Анализ времени загрузки
```bash
# Время загрузки до графического интерфейса
systemd-analyze
# Подробный анализ критического пути
systemd-analyze critical-chain
# Построение графика загрузки (требуется graphviz)
systemd-analyze plot > boot.svg
```
Проверка самых медленных служб
```bash
systemd-analyze blame | head -20
```
## 🎯 9. Специфические для РЕД ОС настройки
Отключение SELinux (только если не требуется)
```bash
sudo nano /etc/selinux/config
# Измените SELINUX=disabled
SELINUX=disabled
```
Оптимизация NetworkManager
Создайте /etc/NetworkManager/conf.d/10-fast.conf:
```ini
[main]
# Отключить ожидание сетевых интерфейсов при загрузке
wait-for-network=0
[connectivity]
# Отключить проверку доступности интернета
enabled=false
```
## 📋 Чек-лист быстрых побед
| Действие                          | Ожидаемый эффект      |
| :-------------------------------- | :-------------------- |
| Уменьшить GRUB_TIMEOUT            | -1–3 секунды          |
| Отключить ненужные службы         | -5–15 секунд          |
| Добавить noatime в fstab          | -1–3 секунды (на SSD) |
| Отключить SELinux (если возможно) | -2–5 секунд           |
| Использовать nowatchdog           | -1–2 секунды          |
| Оптимизировать автозагрузку       | -3–10 секунд          |
| Сжать initramfs в lz4             | -0.5–2 секунды        |

**⚠️ Важные предостережения**
Создайте резервную копию перед изменениями:
```bash
sudo cp /etc/default/grub /etc/default/grub.backup
sudo cp /etc/fstab /etc/fstab.backup
```
**Тестируйте изменения постепенно, чтобы легко определить причину проблем.**
- Не отключайте критически важные службы (systemd-logind, dbus, polkit и др.).
- После отключения SELinux проверьте работу приложений — некоторые могут требовать его присутствия.
- Сохраните старый initramfs на случай проблем:
```bash
sudo cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.backup
```

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Загрузчик** | GRUB2 |
| **Init** | systemd, dracut |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> В РЕД ОС 8.x с ядром 6.x параметры `nowatchdog` и `audit=0` могут быть уже применены по умолчанию. Проверяйте через `systemd-analyze blame` перед отключением служб.