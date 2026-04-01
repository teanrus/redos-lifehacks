# Настройка операционной системы РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

## Описание работы скриптов:

<details>
  <summary>Базовая настройка системы РЕД ОС 7.3 (base-setup.sh)</summary>

### 📋 Полный порядок работы скрипта:
1. Информация о системе
2. Настройка SELinux — отключение
3. Настройка DNF — параллельная загрузка
4. Добавление репозиториев — R7, MAX, Яндекс.Браузер
5. Установка программ — R7 Office, MAX, Яндекс.Браузер, дополнительные пакеты
6. Обновление системы
7. Установка ядра — redos-kernels6 + обновление GRUB
8. Установка утилит — сетевые, системные, архиваторы
9. Настройка времени — Екатеринбург (UTC+5)
10. Настройка SSH
11. Настройка Firewall
12. Настройка hostname
13. Оптимизация — swappiness, I/O scheduler, TRIM
14. Итоги и перезагрузка

### Использование:
```bash
# Скачать скрипт
wget https://raw.githubusercontent.com/teanrus/redos-lifehacks/main/scripts/setup/base-setup.sh
# Сделать исполняемым
chmod +x base-setup.sh
# Запустить
sudo ./base-setup.sh
```
</details>