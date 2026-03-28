# 📊 Настройка аудита действий пользователей в Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

>Аудит действий пользователей критически важен для безопасности, расследования инцидентов и соответствия требованиям (ФСТЭК, PCI DSS и др.). Вот несколько лайфхаков для настройки аудита в РЕД ОС.

## 📋 Содержание
1. [Базовое включение аудита](#1-базовое-включение-аудита)
2. [Правила аудита для пользователей](#2-правила-аудита-для-пользователей)
3. [Мониторинг критических файлов и команд](#3-мониторинг-критических-файлов-и-команд)
4. [Аудит sudo и повышения привилегий](#4-аудит-sudo-и-повышения-привилегий)
5. [Отслеживание сессий и tty](#5-отслеживание-сессий-и-tty)
6. [Централизованный сбор логов](#6-централизованный-сбор-логов)
7. [Cкрипт настройки](#7-скрипт-настройки)
---
## 1. Базовое включение аудита
Установка и запуск auditd
```bash
# Установка (обычно уже установлен)
sudo dnf install audit audit-libs -y
# Включение и запуск
sudo systemctl enable auditd
sudo systemctl start auditd
# Проверка статуса
sudo systemctl status auditd
sudo auditctl -s
```
Основные настройки  
Редактируем `/etc/audit/auditd.conf`:
```bash
sudo nano /etc/audit/auditd.conf
```
```ini
# Важные параметры
log_file = /var/log/audit/audit.log
max_log_file = 50                    # Максимальный размер файла (МБ)
max_log_file_action = ROTATE         # Действие при достижении лимита
num_logs = 10                        # Количество сохраняемых файлов
space_left = 75                      # Свободное место для предупреждения (МБ)
space_left_action = EMAIL            # Действие при нехватке места
action_mail_acct = root@localhost    # Email для уведомлений
admin_space_left = 50                # Критический порог места
admin_space_left_action = SUSPEND    # Действие при критической нехватке
disk_full_action = SUSPEND           # Действие при заполнении диска
disk_error_action = SUSPEND          # Действие при ошибке диска
flush = INCREMENTAL_ASYNC            # Режим записи логов
```
**Лайфхак: ротация и сжатие логов**
```bash
# Настроить автоматическую ротацию
sudo nano /etc/logrotate.d/audit
bash
/var/log/audit/*.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 0600 root root
    postrotate
        /sbin/service auditd rotate 2>/dev/null || true
    endscript
}
```
---
## 2. Правила аудита для пользователей
Мониторинг входа/выхода пользователей
```bash
# Добавить правила мониторинга входа
sudo auditctl -w /var/log/lastlog -p wa -k user_login
sudo auditctl -w /var/log/wtmp -p wa -k user_login
sudo auditctl -w /var/log/btmp -p wa -k failed_login
sudo auditctl -w /var/run/utmp -p wa -k user_login
# Сделать постоянными
sudo aureport --login
```
Отслеживание действий конкретного пользователя
```bash
# Мониторинг всех действий пользователя "username"
sudo auditctl -a always,exit -F uid=1000 -S all -k user_actions_1000
# Мониторинг команд пользователя
sudo auditctl -a always,exit -F uid=1000 -F exe=/bin/bash -S execve -k user_commands
```
**Лайфхак: аудит смены пользователей (su/sudo)**
```bash
# Мониторинг смены пользователя
sudo auditctl -w /bin/su -p x -k user_switch
sudo auditctl -w /usr/bin/sudo -p x -k user_switch
# Мониторинг файлов авторизации
sudo auditctl -w /etc/passwd -p wa -k user_management
sudo auditctl -w /etc/shadow -p wa -k user_management
sudo auditctl -w /etc/group -p wa -k user_management
sudo auditctl -w /etc/sudoers -p wa -k user_management
```
Просмотр отчетов по пользователям
```bash
# Все логины
sudo aureport --login
# Действия пользователя
sudo ausearch -k user_commands -i
# Ошибки авторизации
sudo ausearch -m USER_LOGIN -sv no -i
```
---
## 3. Мониторинг критических файлов и команд
Отслеживание изменений важных файлов
```bash
# Создание скрипта мониторинга
cat << 'EOF' | sudo tee /etc/audit/rules.d/important-files.rules
# Критичные файлы
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /etc/hosts -p wa -k hosts_changes
-w /etc/resolv.conf -p wa -k dns_changes
# Критичные директории
-w /etc/init.d/ -p wa -k init_scripts
-w /usr/local/bin/ -p wa -k bin_changes
-w /root/.bashrc -p wa -k root_bashrc
-w /etc/rc.local -p wa -k rc_local
# Модули ядра
-w /lib/modules/ -p wa -k kernel_modules
EOF
# Применить правила
sudo augenrules --load
```
Мониторинг опасных команд
```bash
# Создание правил для опасных команд
cat << 'EOF' | sudo tee /etc/audit/rules.d/dangerous-commands.rules
# Удаление файлов
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -k file_deletion
# Изменение прав
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -k permission_changes
# Изменение владельца
-a always,exit -F arch=b64 -S chown,fchown,lchown -F auid>=1000 -k ownership_changes
# Загрузка модулей ядра
-w /sbin/insmod -p x -k kernel_module
-w /sbin/rmmod -p x -k kernel_module
-w /sbin/modprobe -p x -k kernel_module
# Остановка аудита
-w /sbin/auditctl -p x -k audit_stop
-w /sbin/auditd -p x -k audit_stop
EOF
sudo augenrules --load
```
**Лайфхак: аудит выполнения команд**
```bash
# Запись всех команд, выполняемых в shell
echo "export PROMPT_COMMAND='history -a'" | sudo tee -a /etc/profile.d/history-log.sh
# Расширенное логирование истории
cat << 'EOF' | sudo tee -a /etc/profile.d/history-log.sh
export HISTTIMEFORMAT="%F %T "
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTFILE=/var/log/history/$USER-$HOSTNAME.log
export PROMPT_COMMAND='history -a'
EOF
# Создание директории для истории
sudo mkdir -p /var/log/history
sudo chmod 777 /var/log/history
```
---
## 4. Аудит sudo и повышения привилегий
Мониторинг sudo команд
```bash
# Включить логирование sudo
sudo nano /etc/sudoers
```
```bash
# Добавить в /etc/sudoers
Defaults log_output
Defaults logfile=/var/log/sudo.log
Defaults log_year
Defaults log_host
Defaults syslog=auth
Defaults mail_always
Defaults mailto=admin@example.com
```
```bash
# Правила аудита для sudo
sudo auditctl -w /usr/bin/sudo -p x -k sudo_exec
sudo auditctl -w /usr/bin/sudoedit -p x -k sudo_exec
```
Отслеживание повышения привилегий
```bash
# Мониторинг процессов, меняющих UID
sudo auditctl -a always,exit -F arch=b64 -S setuid,seteuid,setresuid -k privilege_escalation
sudo auditctl -a always,exit -F arch=b64 -S setgid,setegid,setresgid -k privilege_escalation
# Мониторинг запуска процессов от root
sudo auditctl -a always,exit -F uid=0 -F auid>=1000 -S execve -k root_execution
```
Просмотр sudo операций
```bash
# Просмотр sudo логов
sudo ausearch -k sudo_exec -i
# Специальные отчеты
sudo aureport --user -i | grep -i sudo
sudo aureport --summary -i
```
---
## 5. Отслеживание сессий и tty
Запись всех терминальных сессий
```bash
# Установка ttyrec или script
sudo dnf install ttyrec -y
# Создание скрипта логирования сессий
cat << 'EOF' | sudo tee /etc/profile.d/tty-log.sh
# Запись всех сессий
if [ ! -d /var/log/sessions ]; then
    mkdir -p /var/log/sessions
    chmod 700 /var/log/sessions
fi
SESSION_LOG="/var/log/sessions/${USER}_$(date +%Y%m%d_%H%M%S).log"
script -q -f "$SESSION_LOG" 2>/dev/null
EOF
```
Мониторинг активных сессий
```bash
# Скрипт мониторинга сессий
cat << 'EOF' | sudo tee /usr/local/bin/session-monitor.sh
#!/bin/bash
# Мониторинг активных сессий
echo "=== Активные сессии ==="
w -h
echo -e "\n=== Длительные сессии (>2 часа) ==="
who -u | awk '$4 > "02:00" {print}'
echo -e "\n=== Последние логины ==="
last -n 10
echo -e "\n=== Неудачные попытки входа ==="
lastb -n 10
# Проверка на множественные сессии одного пользователя
echo -e "\n=== Пользователи с множественными сессиями ==="
who | awk '{print $1}' | sort | uniq -c | awk '$1 > 1 {print $2 " - " $1 " сессий"}'
EOF
sudo chmod +x /usr/local/bin/session-monitor.sh
```
Лайфхак: алерты на новые сессии
```bash
# Создание алертов при входе пользователей
cat << 'EOF' | sudo tee /etc/profile.d/login-alert.sh
#!/bin/bash
# Отправка уведомления при входе
echo "Пользователь $USER вошел в систему $(date) с IP $(echo $SSH_CONNECTION | awk '{print $1}')" | \
    mail -s "Login Alert: $USER" admin@example.com 2>/dev/null
# Логирование в отдельный файл
echo "$(date) - $USER - $SSH_CONNECTION" >> /var/log/user-logins.log
EOF
sudo chmod +x /etc/profile.d/login-alert.sh
```
---
## 6. Централизованный сбор логов
Настройка rsyslog для аудита
```bash
# Настройка отправки auditd логов на центральный сервер
sudo nano /etc/rsyslog.d/audit.conf
```
```bash
# Отправка audit логов на сервер
if $programname == 'auditd' then @10.0.0.10:514
& ~
```
```bash
# Настройка auditd для syslog
sudo nano /etc/audit/auditd.conf
```
```ini
# Добавить для отправки в syslog
write_logs = yes
log_format = ENRICHED
```
Лайфхак: сбор логов с помощью audisp
```bash
# Настройка плагина audisp для отправки
sudo nano /etc/audit/audisp-remote.conf
```
```ini
remote_server = 10.0.0.10
port = 60
transport = TCP
```
Использование auditd с SIEM
```bash
# Установка аудит-сплаunk (пример)
sudo dnf install audispd-plugins -y
# Настройка отправки в формате JSON
sudo nano /etc/audit/plugins.d/syslog.conf
```
```ini
active = yes
direction = out
path = /sbin/audisp-syslog
type = always
args = LOG_LOCAL6
format = json
```
---
## 7. Скрипт настройки
```bash
#!/bin/bash
# audit-setup.sh - Быстрая настройка аудита
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
echo -e "${GREEN}=== Настройка системы аудита ===${NC}"
# 1. Установка и запуск
echo -e "\n${YELLOW}1. Установка auditd:${NC}"
sudo dnf install -y audit audispd-plugins
sudo systemctl enable auditd
sudo systemctl start auditd
# 2. Базовые правила
echo -e "\n${YELLOW}2. Применение базовых правил:${NC}"
sudo auditctl -a always,exit -F arch=b64 -S execve -F auid>=1000 -k user_cmd
sudo auditctl -w /etc/passwd -p wa -k passwd_changes
sudo auditctl -w /etc/shadow -p wa -k shadow_changes
sudo auditctl -w /etc/sudoers -p wa -k sudoers_changes
sudo auditctl -w /bin/su -p x -k su_usage
sudo auditctl -w /usr/bin/sudo -p x -k sudo_usage
# 3. Мониторинг входа
echo -e "\n${YELLOW}3. Мониторинг входа пользователей:${NC}"
sudo auditctl -w /var/log/wtmp -p wa -k login_log
sudo auditctl -w /var/log/btmp -p wa -k failed_login
# 4. Сохранение правил
echo -e "\n${YELLOW}4. Сохранение правил:${NC}"
sudo augenrules --load
sudo service auditd restart
# 5. Проверка
echo -e "\n${YELLOW}5. Проверка статуса:${NC}"
sudo auditctl -l
sudo systemctl status auditd --no-pager
echo -e "\n${GREEN}✓ Настройка аудита завершена!${NC}"
echo -e "\nПолезные команды:"
echo "  sudo ausearch -k user_cmd -i    # Поиск команд пользователей"
echo "  sudo aureport --login           # Отчет по входам"
echo "  sudo aureport --failed          # Отчет по ошибкам"
```
---
## 🎯 Чек-лист быстрых побед
| Действие             | Команда                              | Эффект                  |
| :------------------- | :----------------------------------- | :---------------------- |
| ✅ Включить auditd   | sudo systemctl enable --now auditd   | Базовый аудит           |
| ✅ Мониторинг входа  | sudo auditctl -w /var/log/wtmp -p wa | Отслеживание логинов    |
| ✅ Аудит sudo        | sudo auditctl -w /usr/bin/sudo -p x  | Запись команд sudo      |
| ✅ Мониторинг passwd | sudo auditctl -w /etc/passwd -p wa   | Отслеживание изменений  |
| ✅ Сохранить правила | sudo augenrules --load               | Постоянная конфигурация |
| ✅ Проверить логи    | sudo ausearch -m USER_LOGIN -i       | Просмотр событий        |
## 💡 Бонусные советы
1. Быстрый поиск в audit логах
```bash
# Поиск по ключу
sudo ausearch -k user_cmd -i
# Поиск по времени
sudo ausearch -ts today -k sudo_usage -i
# Поиск по пользователю
sudo ausearch -ua 1000 -i
# Поиск ошибок
sudo ausearch -sv no -i
```
2. Создание отчетов
```bash
# Ежедневный отчет
cat << 'EOF' | sudo tee /usr/local/bin/audit-daily-report.sh
#!/bin/bash
REPORT_FILE="/var/log/audit-reports/audit-$(date +%Y%m%d).txt"
mkdir -p /var/log/audit-reports
{
    echo "=== Audit Report $(date) ==="
    echo ""
    echo "1. Логины за день:"
    sudo aureport --login -ts today
    echo ""
    echo "2. Sudo операции:"
    sudo ausearch -ts today -k sudo_usage -i
    echo ""
    echo "3. Изменения файлов:"
    sudo ausearch -ts today -k passwd_changes -i
    echo ""
} > $REPORT_FILE
mail -s "Audit Report $(date)" admin@example.com < $REPORT_FILE
EOF
sudo chmod +x /usr/local/bin/audit-daily-report.sh
```
3. Мониторинг в реальном времени
```bash
# Просмотр логов в реальном времени
sudo tail -f /var/log/audit/audit.log | \
    grep --color -E "USER_LOGIN|USER_CMD|sudo|su|passwd"
# Использование ausearch с watch
watch -n 5 'sudo ausearch -ts 1 minute ago -i | tail -20'
```
4. Защита auditd логов
```bash
# Настройка неизменяемости логов
sudo chattr +a /var/log/audit/audit.log
# Настройка ротации с правами
sudo nano /etc/logrotate.d/audit
```
>⚠️ **Важные предостережения**  
>Не переполните диск — следите за свободным местом:
```bash
df -h /var/log/audit
sudo auditctl -s | grep "backlog"
```
Тестируйте правила перед массовым применением:
```bash
sudo auditctl -t  # Временно отключить
sudo auditctl -R /etc/audit/rules.d/test.rules
```
Сохраняйте копии логов для расследований:
```bash
sudo tar -czf audit-backup-$(date +%Y%m%d).tar.gz /var/log/audit/
```
Настройте алерты при нехватке места:
```bash
# В /etc/audit/auditd.conf
space_left_action = SYSLOG
admin_space_left_action = SUSPEND
```
Для ФСТЭК требований используйте:
```bash
# Включить все рекомендованные правила
sudo ausearch -i | grep -i "failed"
```
---
**Эти лайфхаки помогут вам настроить полноценный аудит действий пользователей, отслеживать критически важные изменения в системе и соответствовать требованиям безопасности. Правильно настроенный аудит — это ключ к пониманию того, что происходит в вашей системе в любой момент времени!**