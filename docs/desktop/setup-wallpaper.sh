#!/bin/bash
# setup-wallpaper.sh - скрипт установки корпоративных обоев из SMB-шары с блокировкой изменений
# Поддерживает: MATE, GNOME, XFCE, KDE Plasma
# Запускать с правами root (sudo)

set -euo pipefail

# ========== НАСТРАИВАЕМЫЕ ПАРАМЕТРЫ ==========
SMB_SERVER="192.168.22.11"  # Укажите адрес сервера
SMB_SHARE="Share"  # Укажите шару
SMB_FOLDER="backgrounds"  # Укажите каталог
SMB_FILE="corporate-wallpaper.jpg"  # Укажите файл корпоративных обоев
SMB_PATH="smb://${SMB_SERVER}/${SMB_SHARE}/${SMB_FOLDER}/${SMB_FILE}"
SMB_USER="user"  # Укажите имя пользователя SMB, если требуется, например "domain\\user"
SMB_PASS="passwd"  # Укажите пароль, если требуется

LOCAL_WALLPAPER_DIR="/usr/share/wallpapers"
LOCAL_WALLPAPER_FILE="${LOCAL_WALLPAPER_DIR}/corporate-wallpaper.jpg"
MOUNT_POINT="/mnt/smb_temp"

# Можно принудительно указать окружение: DESKTOP_ENV=GNOME sudo ./setup-wallpaper.sh
# Допустимые значения: AUTO, MATE, GNOME, XFCE, KDE, ALL
DESKTOP_ENV="${DESKTOP_ENV:-AUTO}"
# =============================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        log "ОШИБКА: Команда $1 не найдена. Установите необходимый пакет."
        exit 1
    fi
}

normalize_de_name() {
    local value
    value="$(echo "${1:-}" | tr '[:lower:]' '[:upper:]')"

    case "${value}" in
        *KDE*|*PLASMA*) echo "KDE" ;;
        *GNOME*) echo "GNOME" ;;
        *MATE*) echo "MATE" ;;
        *XFCE*|*XFCE4*) echo "XFCE" ;;
        ALL) echo "ALL" ;;
        *) echo "UNKNOWN" ;;
    esac
}

detect_de_from_process_env() {
    local env_file env_value

    for env_file in /proc/[0-9]*/environ; do
        [ -r "${env_file}" ] || continue
        env_value="$(tr '\0' '\n' <"${env_file}" 2>/dev/null \
            | awk -F= '/^(XDG_CURRENT_DESKTOP|DESKTOP_SESSION|GDMSESSION)=/ {print $2; exit}' || true)"
        if [ -n "${env_value}" ]; then
            normalize_de_name "${env_value}"
            return
        fi
    done

    echo "UNKNOWN"
}

detect_de_from_loginctl() {
    local session_id desktop de

    command -v loginctl &>/dev/null || {
        echo "UNKNOWN"
        return
    }

    while read -r session_id; do
        [ -n "${session_id}" ] || continue
        desktop="$(loginctl show-session "${session_id}" -p Desktop --value 2>/dev/null || true)"
        de="$(normalize_de_name "${desktop}")"
        if [ "${de}" != "UNKNOWN" ]; then
            echo "${de}"
            return
        fi
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')

    echo "UNKNOWN"
}

detect_de_from_processes() {
    if pgrep -x plasmashell &>/dev/null || pgrep -x kwin_x11 &>/dev/null || pgrep -x kwin_wayland &>/dev/null; then
        echo "KDE"
    elif pgrep -x gnome-shell &>/dev/null; then
        echo "GNOME"
    elif pgrep -x mate-session &>/dev/null || pgrep -x marco &>/dev/null; then
        echo "MATE"
    elif pgrep -x xfce4-session &>/dev/null || pgrep -x xfdesktop &>/dev/null; then
        echo "XFCE"
    else
        echo "UNKNOWN"
    fi
}

detect_de_from_packages() {
    if command -v rpm &>/dev/null; then
        if rpm -q plasma-workspace &>/dev/null; then
            echo "KDE"
        elif rpm -q gnome-shell &>/dev/null; then
            echo "GNOME"
        elif rpm -q mate-desktop &>/dev/null; then
            echo "MATE"
        elif rpm -q xfdesktop &>/dev/null || rpm -q xfce4-session &>/dev/null; then
            echo "XFCE"
        else
            echo "UNKNOWN"
        fi
    else
        echo "UNKNOWN"
    fi
}

detect_desktop_environment() {
    local de

    de="$(normalize_de_name "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-${GDMSESSION:-}}}")"
    [ "${de}" != "UNKNOWN" ] && { echo "${de}"; return; }

    de="$(detect_de_from_loginctl)"
    [ "${de}" != "UNKNOWN" ] && { echo "${de}"; return; }

    de="$(detect_de_from_process_env)"
    [ "${de}" != "UNKNOWN" ] && { echo "${de}"; return; }

    de="$(detect_de_from_processes)"
    [ "${de}" != "UNKNOWN" ] && { echo "${de}"; return; }

    detect_de_from_packages
}

cleanup_mount() {
    if mountpoint -q "${MOUNT_POINT}" 2>/dev/null; then
        umount "${MOUNT_POINT}" 2>/dev/null || true
    fi
    rmdir "${MOUNT_POINT}" 2>/dev/null || true
}

mount_smb_share() {
    log "Создание временной точки монтирования..."
    mkdir -p "${MOUNT_POINT}"

    log "Монтирование SMB-шары ${SMB_PATH}..."
    if [ -n "${SMB_USER}" ] && [ -n "${SMB_PASS}" ]; then
        mount -t cifs "//${SMB_SERVER}/${SMB_SHARE}" "${MOUNT_POINT}" \
            -o "username=${SMB_USER},password=${SMB_PASS},vers=3.0,uid=0,gid=0"
    elif [ -n "${SMB_USER}" ]; then
        mount -t cifs "//${SMB_SERVER}/${SMB_SHARE}" "${MOUNT_POINT}" \
            -o "username=${SMB_USER},vers=3.0,uid=0,gid=0"
    else
        mount -t cifs "//${SMB_SERVER}/${SMB_SHARE}" "${MOUNT_POINT}" \
            -o "guest,vers=3.0,uid=0,gid=0"
    fi
}

install_wallpaper_file() {
    local source_file="${MOUNT_POINT}/${SMB_FOLDER}/${SMB_FILE}"

    if [ ! -f "${source_file}" ]; then
        log "ОШИБКА: Файл ${source_file} не найден"
        exit 1
    fi

    log "Создание каталога ${LOCAL_WALLPAPER_DIR}..."
    mkdir -p "${LOCAL_WALLPAPER_DIR}"

    if [ -f "${LOCAL_WALLPAPER_FILE}" ] && command -v chattr &>/dev/null; then
        chattr -i "${LOCAL_WALLPAPER_FILE}" 2>/dev/null || true
    fi

    log "Копирование корпоративных обоев в ${LOCAL_WALLPAPER_FILE}..."
    cp "${source_file}" "${LOCAL_WALLPAPER_FILE}"
    chmod 644 "${LOCAL_WALLPAPER_FILE}"
    chown root:root "${LOCAL_WALLPAPER_FILE}"

    if command -v chattr &>/dev/null; then
        log "Установка защиты файла через chattr +i..."
        chattr +i "${LOCAL_WALLPAPER_FILE}" 2>/dev/null || \
            log "ПРЕДУПРЕЖДЕНИЕ: не удалось установить chattr +i для ${LOCAL_WALLPAPER_FILE}"
    fi
}

write_autostart_apply_script() {
    log "Создание универсального скрипта применения обоев..."

    cat > /usr/local/bin/apply-corporate-wallpaper.sh << EOF
#!/bin/bash
set +e

LOCAL_WALLPAPER_FILE="${LOCAL_WALLPAPER_FILE}"

[ -f "\${LOCAL_WALLPAPER_FILE}" ] || exit 0

normalize_de_name() {
    local value
    value="\$(echo "\${1:-}" | tr '[:lower:]' '[:upper:]')"
    case "\${value}" in
        *KDE*|*PLASMA*) echo "KDE" ;;
        *GNOME*) echo "GNOME" ;;
        *MATE*) echo "MATE" ;;
        *XFCE*|*XFCE4*) echo "XFCE" ;;
        *) echo "UNKNOWN" ;;
    esac
}

DE="\$(normalize_de_name "\${XDG_CURRENT_DESKTOP:-\${DESKTOP_SESSION:-\${GDMSESSION:-}}}")"

apply_kde() {
    command -v qdbus &>/dev/null || return 0
    [ -n "\${DBUS_SESSION_BUS_ADDRESS:-}" ] || return 0

    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (i = 0; i < allDesktops.length; i++) {
            allDesktops[i].wallpaperPlugin = 'org.kde.image';
            allDesktops[i].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
            allDesktops[i].writeConfig('Image', 'file://\${LOCAL_WALLPAPER_FILE}');
        }
    " 2>/dev/null || true
}

apply_gnome() {
    command -v gsettings &>/dev/null || return 0
    gsettings set org.gnome.desktop.background picture-uri "file://\${LOCAL_WALLPAPER_FILE}" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-uri-dark "file://\${LOCAL_WALLPAPER_FILE}" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-options "zoom" 2>/dev/null || true
}

apply_mate() {
    command -v gsettings &>/dev/null || return 0
    gsettings set org.mate.background picture-filename "\${LOCAL_WALLPAPER_FILE}" 2>/dev/null || true
    gsettings set org.mate.background picture-options "zoom" 2>/dev/null || true
}

apply_xfce() {
    command -v xfconf-query &>/dev/null || return 0

    props="\$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/(last-image|image-path)$' || true)"
    if [ -n "\${props}" ]; then
        echo "\${props}" | while read -r prop; do
            [ -n "\${prop}" ] || continue
            xfconf-query -c xfce4-desktop -p "\${prop}" -s "\${LOCAL_WALLPAPER_FILE}" 2>/dev/null || true
        done
    else
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
            -n -t string -s "\${LOCAL_WALLPAPER_FILE}" 2>/dev/null || true
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-path \
            -n -t string -s "\${LOCAL_WALLPAPER_FILE}" 2>/dev/null || true
    fi

    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style \
        -n -t int -s 5 2>/dev/null || true
}

case "\${DE}" in
    KDE) apply_kde ;;
    GNOME) apply_gnome ;;
    MATE) apply_mate ;;
    XFCE) apply_xfce ;;
    *)
        apply_kde
        apply_gnome
        apply_mate
        apply_xfce
        ;;
esac
EOF

    chmod +x /usr/local/bin/apply-corporate-wallpaper.sh

    log "Настройка системного автозапуска применения обоев..."
    mkdir -p /etc/xdg/autostart /etc/skel/.config/autostart
    cat > /etc/xdg/autostart/corporate-wallpaper.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Corporate Wallpaper
Exec=/usr/local/bin/apply-corporate-wallpaper.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Comment=Apply corporate wallpaper
EOF
    cp /etc/xdg/autostart/corporate-wallpaper.desktop /etc/skel/.config/autostart/corporate-wallpaper.desktop
}

ensure_dconf_profile() {
    mkdir -p /etc/dconf/profile

    if [ ! -f /etc/dconf/profile/user ]; then
        cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF
    elif ! grep -qx "system-db:local" /etc/dconf/profile/user; then
        echo "system-db:local" >> /etc/dconf/profile/user
    fi
}

setup_gnome_lockdown() {
    log "Настройка GNOME: системные обои и блокировка через dconf..."

    ensure_dconf_profile
    mkdir -p /etc/dconf/db/local.d /etc/dconf/db/local.d/locks
    cat > /etc/dconf/db/local.d/00-corporate-wallpaper << EOF
[org/gnome/desktop/background]
picture-uri='file://${LOCAL_WALLPAPER_FILE}'
picture-uri-dark='file://${LOCAL_WALLPAPER_FILE}'
picture-options='zoom'
EOF

    cat > /etc/dconf/db/local.d/locks/corporate-wallpaper << 'EOF'
/org/gnome/desktop/background/picture-uri
/org/gnome/desktop/background/picture-uri-dark
/org/gnome/desktop/background/picture-options
EOF

    if command -v dconf &>/dev/null; then
        dconf update
    else
        log "ПРЕДУПРЕЖДЕНИЕ: dconf не найден, блокировка GNOME применится после установки dconf и выполнения dconf update"
    fi
}

setup_mate_lockdown() {
    log "Настройка MATE: системные обои и блокировка через dconf..."

    ensure_dconf_profile
    mkdir -p /etc/dconf/db/local.d /etc/dconf/db/local.d/locks
    cat > /etc/dconf/db/local.d/01-corporate-wallpaper-mate << EOF
[org/mate/background]
picture-filename='${LOCAL_WALLPAPER_FILE}'
picture-options='zoom'
EOF

    cat > /etc/dconf/db/local.d/locks/corporate-wallpaper-mate << 'EOF'
/org/mate/background/picture-filename
/org/mate/background/picture-options
EOF

    if command -v dconf &>/dev/null; then
        dconf update
    else
        log "ПРЕДУПРЕЖДЕНИЕ: dconf не найден, блокировка MATE применится после установки dconf и выполнения dconf update"
    fi
}

setup_xfce_lockdown() {
    log "Настройка XFCE: системные обои и блокировка через kioskrc..."

    mkdir -p /etc/xdg/xfce4/kiosk
    cat > /etc/xdg/xfce4/kiosk/kioskrc << 'EOF'
[xfce4-desktop]
CustomizeBackdrop=NONE
EOF

    mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
    cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="${LOCAL_WALLPAPER_FILE}"/>
          <property name="image-path" type="string" value="${LOCAL_WALLPAPER_FILE}"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

    chmod 644 /etc/xdg/xfce4/kiosk/kioskrc
    chmod 644 /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
}

setup_kde_lockdown() {
    log "Настройка KDE Plasma: системные обои и блокировка через Kiosk..."

    local kde_globals="/etc/xdg/kdeglobals"
    local kde_profile_dir="/etc/kde-profile"
    local kde_profile_file="${kde_profile_dir}/locked-profile"

    mkdir -p /etc/xdg "${kde_profile_dir}"

    if [ -f "${kde_globals}" ] && [ ! -f "${kde_globals}.backup" ]; then
        cp "${kde_globals}" "${kde_globals}.backup" 2>/dev/null || true
    fi

    if [ -f "${kde_globals}" ]; then
        sed -i '/# BEGIN CORPORATE WALLPAPER/,/# END CORPORATE WALLPAPER/d' "${kde_globals}" 2>/dev/null || true
    fi

    cat >> "${kde_globals}" << EOF

# BEGIN CORPORATE WALLPAPER
[KDE Action Restrictions][\$i]
plasma/plasmashell/unlockedDesktop=false
systemsettings/desktop=false

[Wallpaper][\$i]
Image=file://${LOCAL_WALLPAPER_FILE}
# END CORPORATE WALLPAPER
EOF

    cat > "${kde_profile_file}" << EOF
[General]
Name=Corporate Lockdown

[KDE Action Restrictions]
plasma/plasmashell/unlockedDesktop=false
systemsettings/desktop=false

[Wallpaper]
Image=file://${LOCAL_WALLPAPER_FILE}
EOF
}

setup_existing_users_autostart() {
    log "Настройка автозапуска для существующих пользователей..."

    for user_home in /home/*; do
        [ -d "${user_home}" ] || continue

        local username user_autostart
        username="$(basename "${user_home}")"
        user_autostart="${user_home}/.config/autostart"

        mkdir -p "${user_autostart}"
        cp /etc/xdg/autostart/corporate-wallpaper.desktop "${user_autostart}/corporate-wallpaper.desktop"
        chown -R "${username}:${username}" "${user_autostart}" 2>/dev/null || true
    done
}

apply_lockdown_for_de() {
    local de="$1"

    case "${de}" in
        KDE) setup_kde_lockdown ;;
        GNOME) setup_gnome_lockdown ;;
        MATE) setup_mate_lockdown ;;
        XFCE) setup_xfce_lockdown ;;
        ALL)
            setup_kde_lockdown
            setup_gnome_lockdown
            setup_mate_lockdown
            setup_xfce_lockdown
            ;;
        *)
            log "ПРЕДУПРЕЖДЕНИЕ: окружение не определено, применяем настройки для всех поддерживаемых DE"
            setup_kde_lockdown
            setup_gnome_lockdown
            setup_mate_lockdown
            setup_xfce_lockdown
            ;;
    esac
}

log "=== Начало установки корпоративных обоев ==="

if [ "${EUID}" -ne 0 ]; then
    log "ОШИБКА: Скрипт должен запускаться с правами root (sudo)"
    exit 1
fi

log "Проверка зависимостей..."
check_command mount
check_command umount
check_command cp
check_command chmod
check_command chown
check_command sed
check_command awk

if ! command -v mount.cifs &>/dev/null; then
    log "Установка cifs-utils..."
    dnf install -y cifs-utils
fi

if [ "${DESKTOP_ENV}" = "AUTO" ]; then
    DETECTED_DE="$(detect_desktop_environment)"
else
    DETECTED_DE="$(normalize_de_name "${DESKTOP_ENV}")"
fi

log "Определено графическое окружение: ${DETECTED_DE}"

trap cleanup_mount EXIT
mount_smb_share
install_wallpaper_file
cleanup_mount
trap - EXIT

write_autostart_apply_script
apply_lockdown_for_de "${DETECTED_DE}"
setup_existing_users_autostart

log "=== Установка завершена успешно ==="
log "Корпоративные обои установлены: ${LOCAL_WALLPAPER_FILE}"
log "Блокировка настроена для окружения: ${DETECTED_DE}"
log "Для полного применения пользователям необходимо перезайти в систему"
