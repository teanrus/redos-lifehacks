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
## 2. Продвинутое автодополнение в Zsh
Zsh предлагает гораздо более мощную систему автодополнения "из коробки".  
Установка `Zsh` и `Oh My Zsh`
```bash
# Установка Zsh
sudo dnf install zsh -y
# Установка Oh My Zsh (менеджер конфигурации)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
Включение автодополнения  
В `~/.zshrc` убедитесь, что есть эти строки :
```bash
# Включение автодополнения
autoload -U compinit
compinit
# Дополнительные настройки
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
```
Настройка `Zsh` с `Home Manager` (для `NixOS`) 
```nix
programs.zsh = {
  enable = true;
  enableCompletions = true;
  autosuggestion.enable = true;
  syntaxHighlighting.enable = true;
};
```
---
## 3. Умное автодополнение с описаниями
**`TShell` — универсальное автодополнение для любых команд**  
`TShell` — мощный `Zsh`-плагин, который автоматически извлекает параметры из `--help` и man-страниц .
```bash
# Установка TShell
git clone https://github.com/ainthacker/TShell.git
cd TShell
echo "source $(pwd)/terminal.zsh" >> ~/.zshrc
source ~/.zshrc
```
Что умеет `TShell` :
```bash
# Для security-инструментов
nmap -[TAB]
# Покажет: -sS:TCP SYN scan, -sU:UDP scan, -O:OS detection
# Для Docker
docker run -[TAB]
# Покажет: -d:detached mode, -p:publish ports, -v:bind mount volume
# Для Git
git commit -[TAB]
# Покажет: -m:commit message, -a:stage all changes, --amend:modify last commit
```
Автодополнение для своих скриптов  
Создайте файл `~/.bash_completion.d/myapp` (для `Bash`) :
```bash
# Bash версия
_myapp_completion() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "start stop restart status" -- "$cur") )
}
complete -F _myapp_completion myapp
```
Для `Zsh` :
```bash
# Zsh версия
_myapp_completion() {
    local -a commands
    commands=(
        'start:Start the application'
        'stop:Stop the application'
        'restart:Restart the application'
        'status:Show application status'
    )
    _describe 'command' commands
}
compdef _myapp_completion myapp
```
---
## 4. Меню-дополнение (циклический перебор)
>Обычное автодополнение показывает список вариантов, но не заполняет их автоматически. Меню-дополнение позволяет циклически перебирать варианты, нажимая Tab.
Настройка для Bash  
Создайте или отредактируйте `~/.inputrc` :
```bash
# Menu-complete: цикличный перебор вариантов при каждом Tab
TAB: menu-complete
# Shift+Tab - обратный перебор
"\e[Z": menu-complete-backward
# Показывать все варианты перед началом перебора
set show-all-if-ambiguous on
# Показывать общий префикс перед перебором
set menu-complete-display-prefix on
# Нечувствительное к регистру дополнение
set completion-ignore-case on
# Дефисы и подчеркивания считаются эквивалентными
set completion-map-case on
```
Применить настройки:
```bash
bind -f ~/.inputrc
```
Как это работает :
```bash
$ kde-builder --a<Tab>           # Первый Tab: показывает все варианты
--after  --all-config-projects  --all-kde-projects  --async
$ kde-builder --a<Tab><Tab>      # Второй Tab: подставляет первый вариант
$ kde-builder --after
$ kde-builder --after <Tab>      # Следующий Tab: переходит к следующему
$ kde-builder --after --all-config-projects
$ kde-builder --after --all-config-projects <Shift+Tab>  # Назад
$ kde-builder --after --async
```
---
## 5. Автоподсказки как в Fish
`Zsh-autosuggestions `добавляет подсказки "на лету" из истории, как в оболочке `Fish` .  
Установка
```bash
# Клонируем репозиторий
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
# Добавляем в .zshrc
echo "source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
# Перезагружаем
source ~/.zshrc
```
Настройка  
В `~/.zshrc` можно добавить :
```bash
# Цвет подсказки (серый по умолчанию)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"
# Стратегия: сначала история, потом дополнение
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Отключить для длинных строк (опционально)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
```
Горячие клавиши
```bash
# Принять подсказку (→ или End)
bindkey '^ ' autosuggest-accept   # Ctrl+Space
# Частично принять (слово за словом)
bindkey '^f' forward-word
```
---
## 6. Создание своих правил автодополнения
Для CLI-инструментов с поддержкой completion  
Многие современные CLI-инструменты генерируют скрипты автодополнения :
```bash
# Для DataRobot CLI
dr self completion bash | sudo tee /etc/bash_completion.d/dr
# Для VCF CLI
vcf completion bash > $HOME/.config/vcf/completion.bash.inc
echo "source '$HOME/.config/vcf/completion.bash.inc'" >> $HOME/.bashrc
```
Универсальный шаблон для `Bash` 
```bash
# Файл: ~/.bash_completion.d/myscript
_myscript_completion() {
    local cur prev words cword
    _init_completion || return
    
    # Список команд и их опций
    case "$prev" in
        --config|-c)
            # Дополнение для опции --config: имена файлов .conf
            _filedir "conf"
            return
            ;;
        --log|-l)
            # Дополнение для --log: директории
            _filedir -d
            return
            ;;
    esac
    
    # Основные команды
    if [[ "$cword" -eq 1 ]]; then
        COMPREPLY=($(compgen -W "start stop restart status help" -- "$cur"))
        return
    fi
    
    # Вложенные команды
    case "${COMP_WORDS[1]}" in
        status)
            COMPREPLY=($(compgen -W "--verbose --quiet" -- "$cur"))
            ;;
        start|stop|restart)
            COMPREPLY=($(compgen -W "--force --timeout" -- "$cur"))
            ;;
    esac
}
complete -F _myscript_completion myscript
```
Универсальный шаблон для `Zsh `
```bash
# Файл: ~/.zsh/completions/_myscript
#compdef myscript

local -a commands
commands=(
    'start:Start the service (--force to force)'
    'stop:Stop the service (--timeout=N seconds)'
    'restart:Restart the service'
    'status:Show service status (--verbose for details)'
    'help:Show this help'
)

_arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '(-v --version)'{-v,--version}'[Show version]' \
    '1: :->command' \
    '*:: :->args'

case "$state" in
    command)
        _describe 'command' commands
        ;;
    args)
        case "$words[1]" in
            start)
                _arguments '--force[Force start]'
                ;;
            stop)
                _arguments '--timeout[Timeout in seconds]:seconds'
                ;;
        esac
        ;;
esac
```
---
## 7. Однострочный скрипт диагностики
Проверьте, правильно ли настроено автодополнение:
```bash
#!/bin/bash
# completion-check.sh - Диагностика автодополнения
echo "=== Диагностика автодополнения ==="
# 1. Проверка пакетов
echo -e "\n1. Установленные пакеты:"
rpm -qa | grep -E "bash-completion|zsh" || echo "  Не установлены"
# 2. Проверка файлов конфигурации
echo -e "\n2. Файлы конфигурации:"
[ -f /etc/bash_completion ] && echo "  ✓ /etc/bash_completion существует" || echo "  ✗ /etc/bash_completion отсутствует"
[ -f /usr/share/bash-completion/bash_completion ] && echo "  ✓ /usr/share/bash-completion/bash_completion существует"
# 3. Проверка подключения в .bashrc
echo -e "\n3. Настройки в .bashrc:"
grep -q "bash_completion" ~/.bashrc && echo "  ✓ bash_completion подключен" || echo "  ✗ bash_completion НЕ подключен"
# 4. Проверка .inputrc для menu-complete
echo -e "\n4. Настройки .inputrc:"
[ -f ~/.inputrc ] && grep -q "menu-complete" ~/.inputrc && echo "  ✓ menu-complete настроен" || echo "  ✗ menu-complete не настроен"
# 5. Проверка для Zsh
if [ -n "$ZSH_VERSION" ]; then
    echo -e "\n5. Настройки Zsh:"
    echo "  Версия Zsh: $ZSH_VERSION"
    echo "  fpath: $fpath"
fi
# 6. Проверка функции для конкретной команды
echo -e "\n6. Проверка для команды 'systemctl':"
type _systemctl 2>/dev/null && echo "  ✓ Функция _systemctl существует" || echo "  ✗ Функция _systemctl не найдена"
```
---
## 🎯 Чек-лист быстрых побед
| Действие                        | Команда/Файл                     | Эффект               |
| :------------------------------ | :------------------------------- | :------------------- |
| ✅ Установить bash-completion   | sudo dnf install bash-completion | Базовое дополнение   |
| ✅ Включить в .bashrc           | добавить строки из раздела 1     | Постоянная работа    |
| ✅ Настроить menu-complete      | создать ~/.inputrc               | Циклический перебор  |
| ✅ Установить Zsh + Oh My Zsh   | sudo dnf install zsh             | Мощное дополнение    |
| ✅ Добавить zsh-autosuggestions | клонировать репозиторий          | Подсказки из истории |
| ✅ Установить TShell            | клонировать и source             | Умные подсказки      |
| ✅ Создать свои completion'ы    | ~/.bash_completion.d/            | Для своих скриптов   |
## 💡 Бонусные советы
1. Поиск по истории с Ctrl+R 
```bash
# Нажмите Ctrl+R и начните печатать часть команды
(reverse-i-search)`ls': ls --help
# Повторный Ctrl+R — более ранние совпадения
# Enter — выполнить, Ctrl+G — отменить
```
2. Быстрый повтор команд 
```bash
!!              # Повторить последнюю команду
!$              # Подставить последний аргумент
!ls             # Выполнить последнюю команду на ls
!!:p            # Показать последнюю команду без выполнения
```
3. Редактирование строки 
```bash
Ctrl+A          # Перейти в начало строки
Ctrl+E          # Перейти в конец строки
Ctrl+U          # Удалить до начала
Ctrl+K          # Удалить до конца
Ctrl+W          # Удалить слово слева
Alt+B           # На слово назад
Alt+F           # На слово вперед
```
## ⚠️ Возможные проблемы и решения
Автодополнение не работает  
Проверьте установку пакета :
```bash
dnf info bash-completion
```
Проверьте файл completion'а :
```bash
type _systemctl  # Должна быть функция
```
Очистите кэш :
```bash
rm -rf ~/.cache/kde-builder/bash-completion/
complete -r systemctl
source /usr/share/bash-completion/completions/systemctl
```
Menu-complete не работает 
```bash
# Проверить привязку клавиш
bind -v | grep menu-complete
# Должно быть: menu-complete can be found on "\C-i"
# Принудительно привязать
bind 'TAB: menu-complete'
```
Медленная работа автодополнения
```bash
# Уменьшить время кэширования (в скриптах completion)
# Или отключить динамические дополнения для некоторых команд
complete -o default -o bashdefault command_name
```
---
**Эти лайфхаки помогут вам значительно ускорить работу в терминале, уменьшить количество ошибок и сделать командную строку по-настоящему удобной. Начните с базового автодополнения, затем добавьте menu-complete и автоподсказки — разница будет заметна сразу же!**