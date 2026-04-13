#!/bin/bash
##############################################################################
# quick-check.sh — Экспресс-диагностика системы
#
# Описание: Быстрая проверка CPU, RAM, диска, сети и сервисов
#
# Использование:
#   ./quick-check.sh
#
# Зависимости: bash, coreutils, systemctl, dnf, ip, free, df
# Совместимость: РЕД ОС 7.x ✅, РЕД ОС 8.x ✅
##############################################################################
set -u

echo "╔══════════════════════════════════════════════════════╗"
echo "║           ЭКСПРЕСС-ДИАГНОСТИКА СИСТЕМЫ              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# CPU Load
echo "📊 CPU Load (1m/5m/15m):"
uptime | awk -F'load average:' '{print $2}'
echo ""

# RAM
echo "🧠 RAM:"
free -h | grep -E "Mem|Swap"
echo ""

# Disk
echo "💾 Disk Usage:"
df -h --total 2>/dev/null | grep -E "Filesystem|/dev/|total" | head -5
echo ""

# Network
echo "🌐 Network Interfaces:"
ip -br addr show 2>/dev/null | grep -E "UP|UNKNOWN"
echo ""

# Failed Services
echo "❌ Failed Services:"
failed=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)
if [ "$failed" -gt 0 ]; then
    echo "   ⚠️  Найдено failed-сервисов: $failed"
    systemctl --failed --no-pager 2>/dev/null
else
    echo "   ✅ Все сервисы работают"
fi
echo ""

# Uptime
echo "⏱️  Uptime:"
uptime -p 2>/dev/null || uptime
echo ""

# Security Updates
echo "🔒 Pending Updates:"
pending=$(dnf check-update -q 2>/dev/null | wc -l)
echo "   Доступно обновлений: $pending"
