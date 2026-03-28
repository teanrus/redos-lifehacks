# 🚀 Настройка автодополнения в терминале

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

>Автодополнение (Tab completion) — одна из самых мощных функций командной строки, которая может сэкономить часы набора команд. Вот несколько лайфхаков для настройки автодополнения в РЕД ОС и других Linux-системах.
---
## 📋 Содержание
1. Базовое автодополнение в Bash
2. Продвинутое автодополнение в Zsh
3. Умное автодополнение с описаниями
4. Меню-дополнение (циклический перебор)
5. Автоподсказки как в Fish
6. Создание своих правил автодополнения
7. Однострочный скрипт диагностики
---
## 1. Базовое автодополнение в Bash
**Включение автодополнения**  
В большинстве современных дистрибутивов (включая РЕД ОС) автодополнение уже установлено, но может быть отключено. Проверьте и включите :
```bash
# Установить пакет bash-completion
sudo dnf install bash-completion -y
```
Добавьте в ~/.bashrc (если еще нет) :
```bash
# enable bash completion in interactive shells
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi
```
Применить изменения:
```bash
source ~/.bashrc
```
Проверка работы
```bash
# Нажмите Tab дважды для списка команд, начинающихся с sys
sys<Tab><Tab>
# systemctl  sysstat  systemd  syslog
```
---