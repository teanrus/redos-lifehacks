#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Corporate Wallpaper Rollback Script
# Removes lockdown, autostart, and protected wallpaper.
# ==============================================================================

LOG_FILE="/var/log/corporate-wallpaper.log"
LOCAL_WALLPAPER="/usr/share/wallpapers/corporate-wallpaper.jpg"
APPLY_SCRIPT="/usr/local/bin/apply-corporate-wallpaper.sh"
AUTOSTART_GLOBAL="/etc/xdg/autostart/corporate-wallpaper.desktop"
AUTOSTART_SKEL="/etc/skel/.config/autostart/corporate-wallpaper.desktop"

log() {
    local level="$1"; shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ROLLBACK] [$level] $*" | tee -a "${LOG_FILE}" >&2
}

check_root() { [[ $EUID -ne 0 ]] && { log ERROR "Run as root."; exit 1; }; }

log INFO "=== Starting Rollback ==="
check_root

# 1. Снять защиту и удалить файл
if [[ -f "${LOCAL_WALLPAPER}" ]]; then
    log INFO "Removing immutable flag..."
    chattr -i "${LOCAL_WALLPAPER}" 2>/dev/null || true
    rm -f "${LOCAL_WALLPAPER}"
fi

# 2. Удалить скрипт применения
rm -f "${APPLY_SCRIPT}" 2>/dev/null || true

# 3. Удалить автозапуск
rm -f "${AUTOSTART_GLOBAL}" "${AUTOSTART_SKEL}" 2>/dev/null || true
for home in /home/*; do
    [[ -d "${home}/.config/autostart" ]] && rm -f "${home}/.config/autostart/corporate-wallpaper.desktop" 2>/dev/null || true
done

# 4. Откат dconf (GNOME/MATE)
rm -f /etc/dconf/db/local.d/00-corporate-wallpaper 2>/dev/null || true
rm -f /etc/dconf/db/local.d/locks/corporate-wallpaper 2>/dev/null || true
dconf update 2>/dev/null || true

# 5. Откат XFCE
rm -f /etc/xdg/xfce4/kiosk/kioskrc 2>/dev/null || true
rm -f /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml 2>/dev/null || true

# 6. Откат KDE
if [[ -f /etc/xdg/kdeglobals.backup ]]; then
    cp -f /etc/xdg/kdeglobals.backup /etc/xdg/kdeglobals
    rm -f /etc/xdg/kdeglobals.backup
    log INFO "Restored kdeglobals from backup."
else
    sed -i '/^\[Wallpaper\]/,/^$/d; /^\[KDE Action Restrictions\]/,/^$/d' /etc/xdg/kdeglobals 2>/dev/null || true
    log WARN "No kdeglobals backup found. Attempted inline cleanup."
fi
rm -f /etc/kde/profile.d/corporate-wallpaper.conf 2>/dev/null || true
command -v kbuildsycoca5 >/dev/null 2>&1 && kbuildsycoca5 --noincremental 2>/dev/null || true

# 7. Очистка кеша и логов
log INFO "Rollback completed. Users may need to re-login for changes to apply."
log INFO "=== Rollback Finished ==="