# base-setup.sh Базовая настройка системы

[![Version](https://img.shields.io/badge/version-1.0-green.svg)](https://github.com/teanrus/redos-lifehacks/releases)
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

**Запуск (фиксированная версия v1.0):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/download/v1.0/base-setup.sh | sudo bash
```