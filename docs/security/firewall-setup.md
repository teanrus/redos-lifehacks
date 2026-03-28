# 🔥 Настройка Firewall (firewalld) в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

>Firewalld — мощный и гибкий менеджер фаервола, который использует зоны для управления правилами. Вот несколько лайфхаков для эффективной настройки.
---
## 📋 Содержание
1. [Быстрое управление зонами]()
2. [Продвинутая работа с правилами]()
3. [Маскировка и обход ограничений]()
4. [Безопасное удаленное управление]()
5. [Мониторинг и отладка]()
6. [Создание своих зон и сервисов]()
7. [Скрипт диагностики]()
---
## 1. Быстрое управление зонами
Просмотр текущей конфигурации
```bash
# Текущая зона по умолчанию
sudo firewall-cmd --get-default-zone
# Все активные зоны и интерфейсы
sudo firewall-cmd --get-active-zones
# Детальная информация о зоне
sudo firewall-cmd --zone=public --list-all
# Все зоны
sudo firewall-cmd --list-all-zones
```
Быстрая смена зоны
```bash
# Для интерфейса (постоянно)
sudo firewall-cmd --zone=internal --change-interface=eth0 --permanent
# Для всех интерфейсов по умолчанию
sudo firewall-cmd --set-default-zone=internal
# Временная смена (до перезагрузки)
sudo firewall-cmd --zone=dmz --add-interface=eth1
```
**Лайфхак: быстрый переключатель зон**  
Создайте алиасы в `~/.bashrc`:
```bash
# Быстрое переключение зон
alias fw-home='sudo firewall-cmd --set-default-zone=home && echo "Зона: home"'
alias fw-public='sudo firewall-cmd --set-default-zone=public && echo "Зона: public"'
alias fw-work='sudo firewall-cmd --set-default-zone=work && echo "Зона: work"'
alias fw-dmz='sudo firewall-cmd --set-default-zone=dmz && echo "Зона: dmz"'
# Показать текущую зону
alias fw-status='echo -n "Зона: "; sudo firewall-cmd --get-default-zone; sudo firewall-cmd --list-all'
```
---
## 2. Продвинутая работа с правилами
Открытие портов
```bash
# Открыть порт (временный)
sudo firewall-cmd --add-port=8080/tcp
# Открыть порт (постоянный)
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
# Открыть диапазон портов
sudo firewall-cmd --add-port=3000-3010/tcp --permanent
# Открыть порт для конкретного источника
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port port="22" protocol="tcp" accept' --permanent
```
**Лайфхак: открытие порта с проверкой**
```bash
# Функция для открытия порта с подтверждением
open-port() {
    local port=$1
    local proto=${2:-tcp}
    echo "Открываю порт $port/$proto..."
    sudo firewall-cmd --add-port=$port/$proto --permanent
    sudo firewall-cmd --reload
    # Проверяем, что порт открылся
    if sudo firewall-cmd --list-ports | grep -q "$port/$proto"; then
        echo "✓ Порт $port/$proto успешно открыт"
        sudo firewall-cmd --list-ports | grep "$port/$proto"
    else
        echo "✗ Ошибка: порт $port/$proto не открылся"
    fi
}
# Использование
open-port 8080 tcp
```
Массовое открытие портов
```bash
# Открыть несколько портов одной командой
for port in 80 443 8080 8443; do
    sudo firewall-cmd --add-port=$port/tcp --permanent
done
sudo firewall-cmd --reload
# Или из файла
cat ports.txt | while read port; do
    sudo firewall-cmd --add-port=$port/tcp --permanent
done
```
Блокировка IP-адресов
```bash
# Заблокировать IP (временная)
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" drop'
# Заблокировать IP (постоянно)
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" drop' --permanent
# Заблокировать подсеть
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" drop' --permanent
# Заблокировать IP на конкретный порт
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port port="22" protocol="tcp" reject' --permanent
```
Ограничение скорости (rate limiting)
```bash
# Ограничить количество подключений на SSH (защита от брутфорса)
sudo firewall-cmd --add-rich-rule='rule family="ipv4" service name="ssh" limit value="5/m" accept' --permanent
# Более сложное ограничение
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="http" limit value="100/s" accept' --permanent
```
---
## 3. Маскировка и обход ограничений
NAT и маскарадинг (для маршрутизатора)
```bash
# Включить маскарадинг (NAT) для зоны
sudo firewall-cmd --zone=public --add-masquerade --permanent
# Проброс портов (forwarding)
sudo firewall-cmd --add-forward-port=port=8080:proto=tcp:toport=80:toaddr=192.168.1.10 --permanent
# Проброс портов с сохранением исходного IP
sudo firewall-cmd --add-rich-rule='rule family="ipv4" destination address="192.168.1.1/32" forward-port port="8080" protocol="tcp" to-port="80" to-addr="192.168.1.10"' --permanent
```
**Лайфхак: быстрый VPN-шлюз**
```bash
# Настроить сервер как VPN-шлюз
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --zone=public --add-forward --permanent
# Включить IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
# Открыть порт для OpenVPN
sudo firewall-cmd --add-port=1194/udp --permanent
sudo firewall-cmd --reload
```
Обход ограничений для Docker
```bash
# Docker требует доступа к интерфейсу docker0
sudo firewall-cmd --zone=trusted --add-interface=docker0 --permanent
sudo firewall-cmd --zone=public --remove-interface=docker0 2>/dev/null
# Или добавить Docker в исключения
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="172.17.0.0/16" accept' --permanent
# Перезапустить Docker после изменений
sudo systemctl restart docker
```
---
## 4. Безопасное удаленное управление
Сохранение SSH доступа
```bash
# Всегда оставляйте SSH открытым при работе удаленно
sudo firewall-cmd --add-service=ssh --permanent
# Создайте "спасательное" правило на отдельный порт
sudo firewall-cmd --add-port=2222/tcp --permanent
# Ограничьте SSH только локальной сетью
sudo firewall-cmd --zone=internal --add-service=ssh --permanent
sudo firewall-cmd --zone=public --remove-service=ssh --permanent
```
**Лайфхак: "килл-свитч" для фаервола**  
Создайте скрипт аварийного отключения:
```bash
#!/bin/bash
# fw-killswitch.sh - Аварийное отключение фаервола с таймером
echo "⚠️  Фаервол будет отключен через 30 секунд..."
echo "Нажмите Ctrl+C для отмены"
# Таймер на 30 секунд
sleep 30
# Сохраняем текущие правила
sudo firewall-cmd --runtime-to-permanent
sudo mv /etc/firewalld/zones/public.xml /etc/firewalld/zones/public.xml.backup
# Создаем пустую зону (разрешаем всё)
sudo firewall-cmd --new-zone=emergency --permanent
sudo firewall-cmd --zone=emergency --set-target=ACCEPT --permanent
sudo firewall-cmd --set-default-zone=emergency --permanent
sudo firewall-cmd --reload
echo "✅ Фаервол отключен! Восстановление:"
echo "sudo firewall-cmd --set-default-zone=public"
echo "sudo firewall-cmd --reload"
```
Восстановление после блокировки
```bash
# Если заблокировали себя удаленно
# Способ 1: через консоль (IPMI/iDRAC)
systemctl stop firewalld
firewall-cmd --set-default-zone=public
systemctl start firewalld
# Способ 2: через другой порт
# Запустите временный SSH на другом порту
sudo /usr/sbin/sshd -p 2222
# Затем исправьте правила и вернитесь
```
---
## 5. Мониторинг и отладка
Просмотр логов фаервола
```bash
# Журнал блокировок
sudo journalctl -u firewalld -f
# Просмотр rejected/dropped пакетов
sudo journalctl -k | grep -i "firewall\|DROP\|REJECT"
# Если включено логирование
sudo firewall-cmd --set-log-denied=all
sudo journalctl -f | grep -i "firewall"
```
**Лайфхак: мониторинг атак**
```bash
# Скрипт для мониторинга подозрительной активности
#!/bin/bash
# fw-monitor.sh
echo "=== Мониторинг фаервола ==="
# 1. Количество заблокированных попыток за последний час
echo -e "\nЗаблокированные попытки за час:"
sudo journalctl --since "1 hour ago" | grep -i "firewall" | grep -i "block\|drop" | wc -l
# 2. Топ-10 атакующих IP
echo -e "\nТоп-10 атакующих IP:"
sudo journalctl --since "1 day ago" | grep -i "firewall" | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn | head -10
# 3. Активные правила
echo -e "\nАктивные правила:"
sudo firewall-cmd --list-all
# 4. Открытые порты
echo -e "\nОткрытые порты:"
sudo ss -tlnp | grep LISTEN
```
Анализ правил
```bash
# Проверка синтаксиса
sudo firewall-cmd --check-config
# Показать все правила в формате iptables
sudo firewall-cmd --direct --get-all-rules
# Экспорт правил для анализа
sudo firewall-cmd --list-all-zones > firewall-rules-backup.txt
```
---
## 6. Создание своих зон и сервисов
Создание пользовательской зоны
```bash
# Создать новую зону
sudo firewall-cmd --new-zone=myzone --permanent
sudo firewall-cmd --reload
# Настроить зону
sudo firewall-cmd --zone=myzone --set-target=DROP --permanent
sudo firewall-cmd --zone=myzone --add-service=ssh --permanent
sudo firewall-cmd --zone=myzone --add-port=8080/tcp --permanent
sudo firewall-cmd --zone=myzone --add-interface=eth1 --permanent
# Применить
sudo firewall-cmd --reload
```
Создание пользовательского сервиса  
Создайте файл `/etc/firewalld/services/myapp.xml`:
``xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>MyApp</short>
  <description>Пользовательское приложение</description>
  <port protocol="tcp" port="9000-9010"/>
  <port protocol="udp" port="9000"/>
  <module name="nf_conntrack_netbios_ns"/>
</service>
```

```bash
# Перезагрузить сервисы
sudo firewall-cmd --reload
# Использовать новый сервис
sudo firewall-cmd --add-service=myapp --permanent
```
Лайфхак: шаблон для типовых сервисов
```bash
# Создать сервис из шаблона
create-service() {
    local name=$1
    local port=$2
    local proto=${3:-tcp}
    cat << EOF | sudo tee /etc/firewalld/services/$name.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>$name</short>
  <description>Custom service $name</description>
  <port protocol="$proto" port="$port"/>
</service>
EOF
    
    sudo firewall-cmd --reload
    echo "✓ Сервис $name создан на порту $port/$proto"
}
# Использование
create-service myapp 8080 tcp
create-service myapp-udp 9000 udp
```
---
## 7. Скрипт диагностики
```bash
#!/bin/bash
# fw-diagnostic.sh - Диагностика фаервола
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
echo "=== Диагностика firewalld ==="
# 1. Статус сервиса
echo -e "\n${YELLOW}1. Статус firewalld:${NC}"
if systemctl is-active firewalld &>/dev/null; then
    echo -e "${GREEN}✓ Firewalld активен${NC}"
else
    echo -e "${RED}✗ Firewalld не запущен${NC}"
fi
# 2. Текущая конфигурация
echo -e "\n${YELLOW}2. Текущая конфигурация:${NC}"
echo "Зона по умолчанию: $(sudo firewall-cmd --get-default-zone)"
echo "Активные зоны:"
sudo firewall-cmd --get-active-zones
# 3. Открытые порты и сервисы
echo -e "\n${YELLOW}3. Открытые порты и сервисы:${NC}"
for zone in $(sudo firewall-cmd --get-zones); do
    if sudo firewall-cmd --zone=$zone --list-all | grep -q "ports:\|services:"; then
        echo -e "\nЗона: $zone"
        sudo firewall-cmd --zone=$zone --list-all | grep -E "services:|ports:"
    fi
done
# 4. Rich rules
echo -e "\n${YELLOW}4. Rich правила:${NC}"
for zone in $(sudo firewall-cmd --get-zones); do
    rules=$(sudo firewall-cmd --zone=$zone --list-rich-rules 2>/dev/null)
    if [ -n "$rules" ]; then
        echo -e "\nЗона: $zone"
        echo "$rules"
    fi
done
# 5. Проверка важных портов
echo -e "\n${YELLOW}5. Проверка критических портов:${NC}"
critical_ports=("22/tcp" "80/tcp" "443/tcp" "3306/tcp" "5432/tcp")
for port in "${critical_ports[@]}"; do
    if sudo firewall-cmd --list-ports | grep -q "$port"; then
        echo -e "  ${GREEN}✓${NC} Порт $port открыт"
    else
        echo -e "  ${RED}✗${NC} Порт $port закрыт"
    fi
done
# 6. Логи блокировок (последние 10)
echo -e "\n${YELLOW}6. Последние блокировки:${NC}"
sudo journalctl -u firewalld --since "1 hour ago" | grep -i "block\|drop" | tail -5 || echo "Нет блокировок за последний час"
# 7. Статистика подключений
echo -e "\n${YELLOW}7. Активные подключения:${NC}"
sudo conntrack -L 2>/dev/null | wc -l | xargs echo "Активных соединений:"
echo -e "\n${GREEN}Диагностика завершена${NC}"
```
---
## 🎯 Чек-лист быстрых побед
| Действие                | Команда                                           | Эффект                          |
| :---------------------- | :------------------------------------------------ | :------------------------------ |
| ✅ Проверить статус     | sudo firewall-cmd --state                         | Убедиться, что фаервол работает |
| ✅ Открыть SSH          | sudo firewall-cmd --add-service=ssh --permanent   | Не потерять доступ              |
| ✅ Установить зону      | sudo firewall-cmd --set-default-zone=public       | Базовая защита                  |
| ✅ Добавить порт        | sudo firewall-cmd --add-port=8080/tcp --permanent | Открыть приложение              |
| ✅ Включить логирование | sudo firewall-cmd --set-log-denied=all            | Отслеживать атаки               |
| ✅ Сохранить правила    | sudo firewall-cmd --runtime-to-permanent          | Не потерять после reboot        |
| ✅ Создать backup       | sudo firewall-cmd --list-all-zones > backup.txt   | Для восстановления              |
## 💡 Бонусные советы
1. Быстрое копирование правил между серверами
``bash
# Экспорт
sudo firewall-cmd --list-all-zones > fw-rules.txt
# Импорт на другом сервере
cat fw-rules.txt | while read zone; do
    # Парсинг и применение
done
```
2. Временные правила для тестирования
```bash
# Открыть порт на 5 минут
sudo firewall-cmd --add-port=8080/tcp
(sleep 300 && sudo firewall-cmd --remove-port=8080/tcp) &
```
3. Автоматическая блокировка брутфорса
```bash
# Установить fail2ban
sudo dnf install fail2ban -y
# Настроить защиту SSH
cat << EOF | sudo tee /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/secure
maxretry = 3
bantime = 3600
EOF
sudo systemctl enable --now fail2ban
```
4. Просмотр правил в iptables формате
```bash
# Показать raw правила iptables
sudo iptables -L -n -v
sudo ip6tables -L -n -v
# Показать правила для конкретной таблицы
sudo iptables -t nat -L -n -v
```
>⚠️ **Важные предостережения**  
>Всегда тестируйте правила перед применением на production:
```bash
sudo firewall-cmd --add-port=8080/tcp  # временно
# проверить
sudo firewall-cmd --remove-port=8080/tcp
```
При удаленной работе оставьте SSH открытым:
```bash
# Добавьте запасной порт
sudo firewall-cmd --add-port=2222/tcp --permanent
sudo firewall-cmd --reload
```
Перед перезагрузкой проверьте конфигурацию:
```bash
sudo firewall-cmd --check-config
sudo firewall-cmd --runtime-to-permanent
```
Создайте скрипт восстановления:
```bash
# fw-restore.sh
sudo systemctl stop firewalld
sudo mv /etc/firewalld/zones/public.xml /etc/firewalld/zones/public.xml.broken
sudo cp /etc/firewalld/zones/public.xml.backup /etc/firewalld/zones/public.xml
sudo systemctl start firewalld
```
При работе с Docker учитывайте, что он создает свои правила:
```bash
# Лучше использовать trusted зону для docker0
sudo firewall-cmd --zone=trusted --add-interface=docker0 --permanent
```
---
**Эти лайфхаки помогут вам эффективно управлять firewalld, защитить систему от несанкционированного доступа и быстро реагировать на инциденты безопасности. Правильная настройка фаервола — это основа безопасности любой системы!**
