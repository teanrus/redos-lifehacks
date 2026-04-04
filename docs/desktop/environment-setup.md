# Настройка рабочего окружения

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## Лайфхаки по настройке рабочего окружения в РЕД ОС 7+

### 1. Быстрое переключение между рабочими столами

РЕД ОС по умолчанию использует окружение MATE или Cinnamon. Добавьте горячие клавиши для мгновенного переключения:

```bash
# Для MATE: переключение между рабочими столами
gsettings set org.mate.Marco.global-keybindings switch-to-workspace-left '<Super>Left'
gsettings set org.mate.Marco.global-keybindings switch-to-workspace-right '<Super>Right'
```

> **Совет:** Используйте `Super` (клавиша Windows) + стрелки — это быстрее, чем тянуться к мышке.

---

### 2. Автоматический запуск приложений при входе

Вместо ручного запуска каждый раз, настройте автозагрузку:

```bash
# Создайте файл автозапуска
mkdir -p ~/.config/autostart
nano ~/.config/autostart/myapp.desktop
```

```ini
[Desktop Entry]
Type=Application
Name=Мой терминал
Exec=mate-terminal
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

> **Совет:** Не перегружайте автозагрузку — оставьте только самое необходимое (мессенджер, терминал, монитор ресурсов).

---

### 3. Кастомизация панели задач

**Добавление апплетов на панель (MATE):**
- ПКМ по панели → «Добавить на панель» → выбирайте нужные апплеты
- Рекомендуемые: «Монитор системы», «Погода», «Буфер обмена»

**Для Cinnamon:**
- ПКМ по панели → «Апплеты» → установите дополнительные из каталога

> **Совет:** Апплет «Монитор системы» покажет загрузку CPU/RAM прямо на панели — сразу видно, что тормозит систему.

---

### 4. Горячие клавиши для запуска приложений

Настройте собственные сочетания клавиш:

```bash
# Для MATE
gsettings set org.mate.SettingsDaemon.plugins.media-keys custom-keybindings "['/org/mate/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.mate.settings-daemon.plugins.media-keys.custom-keybinding:/org/mate/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Терминал'
gsettings set org.mate.settings-daemon.plugins.media-keys.custom-keybinding:/org/mate/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'mate-terminal'
gsettings set org.mate.settings-daemon.plugins.media-keys.custom-keybinding:/org/mate/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>t'
```

**Полезные сочетания:**
- `<Super>t` — терминал
- `<Super>f` — файловый менеджер
- `<Super>b` — браузер
- `<Super>p` — менеджер задач (htop)

---

### 5. Настройка тем и внешнего вида

```bash
# Установка дополнительных тем
sudo dnf install mate-themes

# Выбор темы через терминал (MATE)
gsettings set org.mate.interface gtk-theme 'Menta'
gsettings set org.mate.interface icon-theme 'mate'
```

> **Совет:** Тёмные темы снижают нагрузку на глаза при длительной работе. Попробуйте `Arc-Dark` или `Adwaita-dark`.

---

### 6. Быстрый доступ к часто используемым папкам

Создайте закладки в файловом менеджере:

```bash
# Для Caja (MATE) — добавьте в ~/.gtk-bookmarks
echo "file:///home/$USER/Проекты" >> ~/.gtk-bookmarks
echo "file:///home/$USER/Документы/Важное" >> ~/.gtk-bookmarks
```

> **Совет:** Добавьте сетевые папки и общие ресурсы команды — экономите время на навигации.

---

### 7. Настройка уведомлений

Отключите назойливые уведомления или настройте их фильтрацию:

```bash
# Для MATE — отключение уведомлений о подключении устройств
gsettings set org.mate.notification-daemon sound-enabled false

# Настройка времени отображения
gsettings set org.mate.notification-daemon popup-timeout 3000
```

---

### 8. Использование dconf-editor для тонкой настройки

```bash
# Установка графического редактора настроек
sudo dnf install dconf-editor
```

> **Совет:** `dconf-editor` позволяет найти и изменить практически любую настройку системы. Будьте осторожны — неправильные изменения могут повлиять на стабильность.

---

### 9. Настройка буфера обмена

Установите менеджер буфера обмена для хранения истории копирования:

```bash
# Установка ClipIt
sudo dnf install clipit
```

После установки запустите из меню и настройте горячую клавишу (например, `Ctrl+Alt+H`) для вызова истории буфера.

> **Совет:** Настройте хранение до 50 элементов и включите «игнорировать пароли» для безопасности.

---

### 10. Создание собственных скриптов в PATH

Создайте папку для персональных скриптов:

```bash
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Теперь любые исполняемые файлы в `~/bin` будут доступны из терминала по имени.

**Пример полезного скрипта** (`~/bin/sysinfo`):
```bash
#!/bin/bash
echo "=== Информация о системе ==="
echo "ОС: $(cat /etc/redos-release)"
echo "Ядро: $(uname -r)"
echo "RAM: $(free -h | awk '/^Mem:/{print $3 "/" $2}')"
echo "Диск: $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " использовано)"}')"
```

```bash
chmod +x ~/bin/sysinfo
```

---

## См. также

- [Настройка автодополнения в терминале](/docs/desktop/bash-completion.md)

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Окружение** | MATE, Cinnamon |
| **Утилиты** | `gsettings`, `dconf-editor`, `clipit` |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> Большинство команд используют `gsettings` и совместимы с MATE/Cinnamon. В РЕД ОС 8.x с другим DE некоторые пути настроек могут отличаться.
