# install-messengers.sh Установка мессенджеров (Telegram, Среда, MAX, VK Messenger)

[![Version](https://img.shields.io/badge/version-1.0-green.svg)](https://github.com/teanrus/redos-lifehacks/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Что делает:**
- Установка Telegram:
  - Скачивает и распаковывает архив в /opt/telegram
  - Создает символическую ссылку /usr/bin/telegram
  - Создает ярлык в меню приложений
- Установка Среда:
  - Скачивает и устанавливает RPM-пакет
  - Создает ярлык в меню приложений
- Установка MAX:
  - Добавляет репозиторий MAX (при отсутствии)
  - Устанавливает через dnf install max
- Установка VK Messenger (опционально):
  - Скачивает и устанавливает RPM-пакет
  - Создает ярлык в меню приложений
- Каждый мессенджер устанавливается по отдельному запросу
- Проверка наличия установленной версии с предложением переустановки
- Автоматическая очистка временных файлов после установки

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-messengers.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/install-messengers.sh | sudo bash
```

**Пример диалога при запуске:**

```bash
=== 4. Выбор мессенджеров для установки ===
Будут установлены только выбранные мессенджеры

Установить мессенджер Telegram? (y/n): y
=== Установка Telegram ===
Получение информации о последнем релизе...
✓ Найдена последняя версия: v2.7
Загрузка tsetup.tar.xz...
✓ tsetup.tar.xz успешно загружен
Распаковка Telegram...
✓ Telegram успешно установлен

Установить корпоративный мессенджер Среда? (y/n): y
=== Установка Среда ===
Загрузка sreda.rpm...
✓ sreda.rpm успешно загружен
✓ Установка Среда успешно выполнено

Установить мессенджер MAX? (y/n): y
=== Установка MAX ===
✓ MAX успешно установлен

Установить мессенджер ВК (VK Messenger)? (y/n): n
Пропускаем установку VK Messenger
Установленные компоненты:

Telegram — универсальный мессенджер
Среда — корпоративный мессенджер для защищенного обмена сообщениями
MAX — корпоративный мессенджер MAX Desktop
VK Messenger — мессенджер от ВКонтакте (опционально)
```
**Полезные команды после установки:**

```bash
# Запуск мессенджеров
telegram      # Telegram
sreda         # Среда
max           # MAX
vk-messenger  # VK Messenger
```