# 🐧 Лайф-хаки по настройке рабочей станции на базе операционной системы РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

**Коллекция проверенных решений, скриптов и настроек для комфортной работы в РЕД ОС 7.3.**

---

## 📖 О чем этот репозиторий

Этот репозиторий содержит собранные и систематизированные лайфхаки, скрипты и конфигурации для настройки рабочей станции на базе **РЕД ОС 7.3**. Здесь вы найдете решения для:

- 🚀 **Быстрой настройки** системы после установки
- 🔧 **Установки и настройки** популярного корпоративного ПО
- 🛡️ **Оптимизации безопасности** и производительности
- 🐛 **Решение типовых проблем** и ошибок
- 📚 **Документацию** с пошаговыми инструкциями

---

## 🚀 Быстрый старт

### Клонирование репозитория

```bash
git clone https://github.com/teanrus/redos-lifehacks.git
cd redos-lifehacks
```

## Основные скрипты
| Скрипт                                | Назначение                                            |
| :------------------------------------ | :---------------------------------------------------- |
| scripts/setup/base-setup.sh           | Базовая настройка системы (SELinux, DNF, репозитории) |
| scripts/install/install-cryptopro.sh  | Установка КриптоПро CSP                               |
| scripts/install/install-vipnet.sh     | Установка ViPNet (с выбором версии)                   |
| scripts/install/install-1c.sh         | Установка 1С:Предприятие                              |
| scripts/install/install-messengers.sh | Установка мессенджеров (Telegram, Viber, СРЕДА)       |
| scripts/utils/cleanup.sh              | Очистка системы от временных файлов                   |

## 📂 Структура репозитория

```text
redos-lifehacks/
├── scripts/           # Готовые скрипты для автоматизации
│   ├── setup/         # Скрипты настройки системы
│   ├── install/       # Скрипты установки ПО
│   └── utils/         # Вспомогательные скрипты
│
├── configs/           # Готовые конфигурационные файлы
│   ├── dnf/           # Настройки DNF
│   ├── selinux/       # Настройки SELinux
│   ├── network/       # Сетевые настройки
│   └── desktop/       # Настройки рабочего стола
│
├── docs/              # Подробная документация
│   ├── installation/  # Установка ОС
│   ├── troubleshooting/ # Решение проблем
│   ├── optimization/  # Оптимизация
│   └── security/      # Безопасность
│
├── examples/          # Примеры использования
└── tools/             # Полезные инструменты
```
## 🔥 Популярные лайфхаки
1. Ускорение DNF в 10 раз
```bash
echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
```
2. Отключение SELinux (для совместимости с некоторым ПО)
```bash
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```
3. Монтирование удаленной папки через SSH
```bash
sshfs user@server:/remote/path /local/mount/point
```
4. Быстрая установка всех обновлений
```bash
sudo dnf update -y
```
5. Настройка TRIM для SSD
```bash
sudo systemctl enable --now fstrim.timer
```
