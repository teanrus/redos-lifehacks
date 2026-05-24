# Окружение рабочего стола

[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](/LICENSE)
[![RED OS](https://img.shields.io/badge/RED%20OS-7.3%20%7C%208.x-b30000?style=for-the-badge)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks/stargazers)

## 🗂️ [Автомонтирование SSHFS папок при входе](/docs/desktop/automount-sshfs.md)

Удалённые файловые системы: установка SSHFS, монтирование через fstab/systemd/автозагрузку, аутентификация по SSH-ключам, кэширование, сжатие, диагностика проблем, автоматическая настройка скриптом

## ⌨️ [Настройка автодополнения в терминале](/docs/desktop/bash-completion.md)

Автодополнение команд: bash-completion, Zsh + Oh My Zsh, menu-complete (циклический перебор), автоподсказки как в Fish (zsh-autosuggestions), TShell, создание своих правил completion, диагностика

## 🖥️ [Настройка рабочего окружения](/docs/desktop/environment-setup.md)

Рабочее окружение: переключение рабочих столов, автозапуск приложений, кастомизация панели задач, горячие клавиши, темы оформления, закладки папок, уведомления, dconf-editor, буфер обмена (ClipIt), персональные скрипты в PATH

## 🖥️ [Настройка многомониторной конфигурации](/docs/desktop/multi-monitor.md)

Несколько мониторов: определение подключённых дисплеев, настройка разрешения и расположения, сохранение конфигурации, масштабирование HiDPI

## 🖼️ [Автоматическая установка корпоративных обоев рабочего стола](/docs/desktop/setup-wallpaper.md)

## 🖼️ Корпоративные обои

Скрипт `docs/desktop/setup-wallpaper.sh` автоматизирует установку единого фона рабочего стола для всех пользователей:

```bash
# Настройте параметры SMB в начале скрипта
sudo bash docs/desktop/setup-wallpaper.sh
```

**Особенности:**

- ✅ Поддержка MATE, GNOME, XFCE, KDE Plasma
- ✅ Автоопределение окружения или ручное указание через `DESKTOP_ENV=GNOME`
- ✅ Защита файла обоев через `chattr +i`
- ✅ Блокировка изменения настроек через dconf/Kiosk
- ✅ Применение при входе любого пользователя

> ⚠️ Требуются права root и доступ к указанной SMB-шаре.
