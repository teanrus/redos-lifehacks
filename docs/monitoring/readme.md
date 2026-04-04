# 📊 Мониторинг и диагностика РЕД ОС

> Комплексное руководство по мониторингу состояния системы, анализу журналов и проверке совместимости оборудования в РЕД ОС 7.x / 8.x.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.3-red.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

---

## О разделе

Данный раздел содержит практические руководства для системных администраторов и пользователей РЕД ОС по следующим направлениям:

- **Диагностика состояния системы** -- мониторинг CPU, RAM, дисков, сети, сервисов
- **Анализ журналов** -- работа с systemd journal, поиск ошибок, генерация отчётов
- **Совместимость оборудования** -- проверка и настройка аппаратного обеспечения

Каждый документ содержит готовые скрипты, таблицы метрик и пошаговые инструкции.

---

## 📑 Документы раздела

| Документ | Описание | Ссылка |
|----------|----------|--------|
| 📊 **Диагностика состояния системы** | Полный гайд по проверке CPU, RAM, дисков, сети, сервисов, безопасности, температуры. Скрипты `system-health-check.sh`, отчёты в TXT/HTML/JSON, cron и systemd timer | [→ system-health-check.md](system-health-check.md) |
| 📝 **Анализ журналов systemd** | Руководство по journalctl, фильтрация по времени/сервисам/приоритетам, анализ загрузки, скрипт `log-analyzer.sh`, мониторинг в реальном времени | [→ log-analyzer.md](log-analyzer.md) |
| 🔍 **Совместимость оборудования** | Проверка процессоров, GPU, сетевых адаптеров, накопителей, USB, Wi-Fi, Bluetooth, принтеров, ноутбуков, серверного оборудования. Скрипт `hw-check.sh`, отчёты HTML/JSON | [→ hardware-compatibility.md](hardware-compatibility.md) |

---

## Быстрый старт

### Экспресс-проверка системы (30 секунд)

```bash
echo "=== CPU ===" && uptime
echo "=== RAM ===" && free -h | head -3
echo "=== Disk ===" && df -h / | tail -1
echo "=== Network ===" && ip -br addr show | grep UP
echo "=== Failed Services ===" && systemctl --failed --no-pager
```

### Запуск полного скрипта диагностики

```bash
# Скачать и запустить system-health-check.sh
curl -sL https://raw.githubusercontent.com/teanrus/redos-lifehacks/main/docs/monitoring/scripts/system-health-check.sh -o /tmp/system-health-check.sh
chmod +x /tmp/system-health-check.sh
sudo bash /tmp/system-health-check.sh --full --report html
```

---

> [!tip]
> **Рекомендуемый порядок использования:**
> 1. Начните с [диагностики состояния системы](system-health-check.md) -- оцените общее состояние
> 2. При обнаружении проблем перейдите к [анализу журналов](log-analyzer.md) -- найдите причину
> 3. Для нового оборудования используйте [проверку совместимости](hardware-compatibility.md)
> 4. Настройте автоматические проверки через cron или systemd timer

---

## 📋 Структура скриптов

Все скрипты мониторинга имеют единый интерфейс:

```bash
# Основные флаги для всех скриптов
./script.sh --help          # Справка
./script.sh --full          # Полная проверка
./script.sh --report html   # Генерация отчёта в HTML
./script.sh --report json   # Генерация отчёта в JSON
./script.sh --report txt    # Генерация отчёта в TXT
./script.sh --quiet         # Тихий режим (только предупреждения)
```

---

## Метрики и пороговые значения

Общие пороговые значения для всех скриптов:

| Метрика | Норма | Предупреждение | Критично |
|---------|-------|----------------|----------|
| **CPU Load (1 min)** | < кол-ва ядер | = кол-во ядер | > 2x ядер |
| **RAM Usage** | < 70% | 70--90% | > 90% |
| **Swap Usage** | < 20% | 20--50% | > 50% |
| **Disk Usage** | < 80% | 80--90% | > 90% |
| **Disk I/O Wait** | < 10% | 10--25% | > 25% |
| **System Uptime** | > 1 дня | < 1 дня | < 1 часа |
| **Failed Services** | 0 | 1--2 | > 2 |
| **Security Updates** | 0 | 1--5 | > 5 |

> [!note]
> Точные пороговые значения могут отличаться в зависимости от нагрузки и назначения сервера. Настройте скрипты под свою инфраструктуру.

---

## Установка необходимых пакетов

Для полной функциональности всех скриптов установите:

```bash
# Базовые утилиты мониторинга
sudo dnf install -y htop glances lm_sensors smartmontools \
    iotop iftop nload sysstat jq net-tools

# Утилиты для анализа дисков
sudo dnf install -y hdparm nvme-cli fio

# Утилиты для анализа сети
sudo dnf install -y nmap tcpdump ethtool

# Для GPU (если есть NVIDIA)
sudo dnf install -y nvidia-smi 2>/dev/null || echo "NVIDIA driver not installed"
```

---

## Автоматическое планирование

### Через cron

```bash
# Ежедневная проверка в 08:00
0 8 * * * /opt/scripts/system-health-check.sh --report html >> /var/log/health-check.log 2>&1

# Ежечасная экспресс-проверка
0 * * * * /opt/scripts/system-health-check.sh --quick >> /var/log/health-check-quick.log 2>&1
```

### Через systemd timer

```bash
# Создать сервис
sudo tee /etc/systemd/system/system-health-check.service << 'EOF'
[Unit]
Description=System Health Check
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/scripts/system-health-check.sh --report html --output /var/reports/health/

[Install]
WantedBy=multi-user.target
EOF

# Создать таймер
sudo tee /etc/systemd/system/system-health-check.timer << 'EOF'
[Unit]
Description=Run System Health Check Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now system-health-check.timer
```

---

## Связанные разделы

- [Настройка сети](../network/readme.md)
- [Управление сервисами](../systemd/readme.md)
- [Безопасность](../security/readme.md)
- [Оптимизация производительности](../performance/readme.md)

---

## Участие в разработке

Если вы нашли ошибку, хотите дополнить руководство или предложить новый скрипт -- создайте Issue или Pull Request в репозитории.

- [Сообщить о проблеме](../../issues)
- [Предложить улучшение](../../issues/new)
- [Внести изменения](../../pulls)

---

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
