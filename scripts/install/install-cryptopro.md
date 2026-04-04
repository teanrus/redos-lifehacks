# Установка КриптоПро CSP с автоматическим определением последней версии

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## Что делает:

- Устанавливает зависимости (ifd-rutokens, token-manager, pcsc-lite и др.)
- Загружает и устанавливает КриптоПро CSP
- Настраивает работу с Рутокен
- Предлагает установить лицензию
- Настраивает интеграцию ГОСТ-шифрования с файловым менеджером

**Запуск (последняя версия):**

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-cryptopro.sh | sudo bash
```

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 |
| **Права** | root (sudo) |
| **Скрипт** | [`install-cryptopro.sh`](https://github.com/teanrus/redos-lifehacks/releases/latest/download/install-cryptopro.sh) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> КриптоПро CSP работает на обеих версиях.
> Зависимости (pcsc-lite, ifd-rutokens) могут отличаться — скрипт проверяет наличие.
> Для РЕД ОС 8.x проверьте совместимость версии КриптоПро.
