# Установка и настройка ViPNet Client для защищенного VPN-соединения

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Что делает:**
- Автоматически определяет последнюю версию ViPNet Client из репозитория
- Устанавливает необходимые зависимости (libpcap, iptables, python3 и др.)
- Загружает и устанавливает ViPNet Client (RPM-пакет)
- Настраивает сетевые интерфейсы для работы с VPN
- Добавляет правила firewall для корректной работы ViPNet
- Настраивает автозапуск сервиса ViPNet
- Создает ярлык в меню приложений
- Предлагает импортировать существующие конфигурации (пользователи, политики)
- Проверяет наличие установленной версии с предложением переустановки

**Особенности:**
- Поддержка как 32-битных, так и 64-битных версий
- Автоматическое определение архитектуры системы
- Совместимость с РЕД ОС 7.3 из коробки

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh | sudo bash
```

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/install-vipnet.sh | sudo bash
```

**Пример диалога при запуске:**

```bash
=== Установка ViPNet Client ===
Определение архитектуры системы...
✓ Обнаружена архитектура: x86_64
Поиск последней версии ViPNet Client...
✓ Найдена версия: 4.2.0-1234
Загрузка viрnet-client-4.2.0-1234.x86_64.rpm...
✓ Загрузка завершена
Установка зависимостей...
✓ Зависимости установлены
Установка ViPNet Client...
✓ ViPNet Client успешно установлен
Настройка firewall...
✓ Правила firewall добавлены
Настройка автозапуска...
✓ Сервис ViPNet добавлен в автозапуск

Желаете импортировать конфигурацию пользователя? (y/n): y
Укажите путь к файлу конфигурации (например, /home/user/viрnet.conf): /home/user/viрnet.conf
✓ Конфигурация импортирована

Установка завершена!
```

**Полезные команды после установки:**

```bash
# Запуск ViPNet Client
vipnet-client

# Управление сервисом
systemctl start vipnet    # Запуск сервиса
systemctl stop vipnet     # Остановка сервиса
systemctl status vipnet   # Проверка статуса

# Просмотр логов
journalctl -u vipnet -f   # Логи в реальном времени
```

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 |
| **Архитектура** | x86_64 (автоопределение) |
| **Права** | root (sudo) |
| **Скрипт** | [`install-vipnet.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-vipnet.sh) |
| **Совместимость** | ⚠️ РЕД ОС 7.x, ❌ РЕД ОС 8.x (не тестировался) |

> [!warning]
> Скрипт протестирован на **РЕД ОС 7.3 x86_64**.
> - Версия ViPNet жёстко привязана — для 8.x может потребоваться другой RPM
> - RPM-пакет может быть несовместим с РЕД ОС 8.x
> - Автоопределение архитектуры работает корректно
