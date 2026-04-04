# Базовая настройка системы

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Что делает:**
- Отключает SELinux
- Настраивает DNF (параллельная загрузка, fastestmirror)
- Добавляет репозитории R7 Office, MAX Desktop, Яндекс.Браузер
- Устанавливает R7 Office, MAX, Яндекс.Браузер
- Устанавливает и обновляет ядро (redos-kernels6)
- Настраивает часовой пояс (Asia/Yekaterinburg, UTC+5)
- Настраивает SSH и firewall
- Оптимизирует систему (swappiness, TRIM для SSD)

**Запуск (последняя версия):**
```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/base-setup.sh | sudo bash
```

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 |
| **Архитектура** | x86_64 |
| **Права** | root (sudo) |
| **Скрипт** | [`base-setup.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/base-setup.sh) |
| **Совместимость** | ⚠️ РЕД ОС 7.x (тестировался на 7.3), ❌ РЕД ОС 8.x (не тестировался) |

> [!warning]
> Скрипт **base-setup.sh** протестирован только на **РЕД ОС 7.3**.
> - Отключает SELinux (`SELINUX=disabled`) — не рекомендуется для сертифицированных сред
> - Репозиторий MAX использует `el/9` (RHEL 9 / РЕД ОС 8-совместимый) — может конфликтовать с 7.x
> - Часовой пояс жёстко задан как `Asia/Yekaterinburg` — измените при необходимости
> - Использует `grub2-mkconfig` — корректно для BIOS; на UEFI путь может отличаться
> - Для РЕД ОС 8.x рекомендуется адаптировать скрипт (проверить пакеты и репозитории)
