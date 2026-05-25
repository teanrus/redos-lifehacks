#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Corporate Wallpaper Setup Script
# Supports: GNOME, MATE, XFCE, KDE Plasma
# Requires: root privileges, cifs-utils, bash >= 4.0
# ==============================================================================

# --- Configuration (override via env vars or edit below) ---
SMB_SERVER="${SMB_SERVER:-}"
SMB_SHARE="${SMB_SHARE:-}"
SMB_FOLDER="${SMB_FOLDER:-backgrounds}"
SMB_FILE="${SMB_FILE:-corporate-wallpaper.jpg}"
DESKTOP_ENV="${DESKTOP_ENV:-AUTO}"
UPDATE_MODE="${UPDATE_MODE:-false}"

# Security: Prefer credentials file. Fallback to env vars with warning.
SMB_CRED_FILE="${SMB_CRED_FILE:-/etc/smb-credentials/corp-wallpaper}"
SMB_USER="${SMB_USER:-}"
SMB_PASS="${SMB_PASS:-}"

# Paths
LOCAL_WALLPAPER_DIR="/usr/share/wallpapers"
LOCAL_WALLPAPER="${LOCAL_WALLPAPER_DIR}/corporate-wallpaper.jpg"
LOG_FILE="/var/log/corporate-wallpaper.log"
APPLY_SCRIPT="/usr/local/bin/apply-corporate-wallpaper.sh"
AUTOSTART_GLOBAL="/etc/xdg/autostart/corporate-wallpaper.desktop"
AUTOSTART_SKEL="/etc/skel/.config/autostart/corporate-wallpaper.desktop"

MOUNT_POINT=""
CURRENT_DE=""

# --- Logging ---
log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${ts}] [${level}] ${msg}" | tee -a "${LOG_FILE}" >&2
}

# --- Trap & Cleanup ---
cleanup() {
    if [[ -n "${MOUNT_POINT}" && -d "${MOUNT_POINT}" ]]; then
        log INFO "Unmounting ${MOUNT_POINT}..."
        umount -l "${MOUNT_POINT}" 2>/dev/null || true
        rmdir "${MOUNT_POINT}" 2>/dev/null || true
    fi
    log INFO "Cleanup completed."
}
trap cleanup EXIT ERR INT TERM

# --- Usage ---
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]
  --update, -u      Check remote hash and update only if changed.
  --help, -h        Show this help message.
Environment Variables:
  SMB_SERVER, SMB_SHARE, SMB_USER, SMB_PASS (or SMB_CRED_FILE)
  DESKTOP_ENV=GNOME|MATE|XFCE|KDE|ALL|AUTO (default: AUTO)
EOF
    exit "${1:-0}"
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --update|-u) UPDATE_MODE=true; shift ;;
        --help|-h)   usage 0 ;;
        *)           log ERROR "Unknown option: $1"; usage 1 ;;
    esac
done

# --- Validation ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log ERROR "This script must be run as root."
        exit 1
    fi
}

prepare_credentials() {
    if [[ -f "${SMB_CRED_FILE}" ]]; then
        return 0
    fi
    if [[ -z "${SMB_USER}" || -z "${SMB_PASS}" ]]; then
        log ERROR "SMB credentials missing. Provide SMB_USER/SMB_PASS or create ${SMB_CRED_FILE}"
        exit 1
    fi
    log WARN "Plaintext credentials detected. Generating secure credential file..."
    mkdir -p "$(dirname "${SMB_CRED_FILE}")"
    cat > "${SMB_CRED_FILE}" <<CREDS
username=${SMB_USER}
password=${SMB_PASS}
CREDS
    chmod 600 "${SMB_CRED_FILE}"
    chown root:root "${SMB_CRED_FILE}"
}

validate_inputs() {
    [[ -z "${SMB_SERVER}" || -z "${SMB_SHARE}" ]] && { log ERROR "SMB_SERVER and SMB_SHARE must be set."; exit 1; }
    for cmd in mount cp chmod chattr dconf xfconf-query kbuildsycoca5; do
        command -v "$cmd" >/dev/null 2>&1 || log WARN "Command '${cmd}' not found. Related DE features may fail."
    done
    if ! rpm -q cifs-utils >/dev/null 2>&1 && ! dpkg -l cifs-utils >/dev/null 2>&1; then
        log INFO "Installing cifs-utils..."
        if command -v dnf >/dev/null 2>&1; then dnf install -y cifs-utils >/dev/null;
        elif command -v apt >/dev/null 2>&1; then apt install -y cifs-utils >/dev/null;
        else log ERROR "Package manager not supported."; exit 1; fi
    fi
}

# --- DE Detection ---
detect_de() {
    if [[ "${DESKTOP_ENV}" != "AUTO" ]]; then
        CURRENT_DE="${DESKTOP_ENV}"
        return 0
    fi
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        case "${XDG_CURRENT_DESKTOP}" in
            *GNOME*) CURRENT_DE="GNOME" ;;
            *KDE*)   CURRENT_DE="KDE" ;;
            *XFCE*)  CURRENT_DE="XFCE" ;;
            *MATE*)  CURRENT_DE="MATE" ;;
        esac
    fi
    if [[ -z "${CURRENT_DE:-}" ]]; then
        if loginctl list-sessions --no-legend 2>/dev/null | grep -q 'seat0'; then
            CURRENT_DE=$(loginctl show-session $(loginctl --no-legend | awk 'NR==1{print $1}') -p Desktop 2>/dev/null | cut -d= -f2 || true)
        fi
    fi
    if [[ -z "${CURRENT_DE:-}" || "${CURRENT_DE}" == "UNKNOWN" ]]; then
        log WARN "DE detection inconclusive. Applying settings for ALL supported DEs."
        CURRENT_DE="ALL"
    fi
    log INFO "Target DE: ${CURRENT_DE}"
}

# --- Core Logic ---
mount_smb() {
    MOUNT_POINT=$(mktemp -d /mnt/corp-wallpaper.XXXXXX)
    log INFO "Mounting SMB share to ${MOUNT_POINT}..."
    local creds_opt="credentials=${SMB_CRED_FILE}"
    mount -t cifs "//${SMB_SERVER}/${SMB_SHARE}" "${MOUNT_POINT}" \
    -o "${creds_opt},ro,vers=3.0,sec=ntlmssp,noserverino" || {
        log ERROR "Failed to mount SMB share."
        exit 1
    }
}

copy_wallpaper() {
    local remote_path="${MOUNT_POINT}/${SMB_FOLDER}/${SMB_FILE}"
    [[ ! -f "${remote_path}" ]] && { log ERROR "Wallpaper not found at ${remote_path}"; exit 1; }

    mkdir -p "${LOCAL_WALLPAPER_DIR}"

    if [[ "${UPDATE_MODE}" == "true" ]]; then
        if [[ -f "${LOCAL_WALLPAPER}" ]]; then
            local remote_hash local_hash
            remote_hash=$(sha256sum "${remote_path}" | awk '{print $1}')
            local_hash=$(sha256sum "${LOCAL_WALLPAPER}" | awk '{print $1}')
            if [[ "${remote_hash}" == "${local_hash}" ]]; then
                log INFO "Wallpaper is already up-to-date. Skipping copy."
                return 0
            fi
            log INFO "New version detected. Updating..."
            chattr -i "${LOCAL_WALLPAPER}" 2>/dev/null || true
        fi
    fi

    cp -f "${remote_path}" "${LOCAL_WALLPAPER}"
    chmod 644 "${LOCAL_WALLPAPER}"
    chown root:root "${LOCAL_WALLPAPER}"
    chattr +i "${LOCAL_WALLPAPER}" 2>/dev/null || log WARN "chattr +i failed (filesystem may not support immutable)."
    log INFO "Wallpaper installed and protected."
}

configure_dconf() {
    local de_name="$1"
    local schema
    case "${de_name}" in
        GNOME) schema="org.gnome.desktop.background" ;;
        MATE)  schema="org.mate.background" ;;
    esac
    local db_dir="/etc/dconf/db/local.d"
    local lock_dir="/etc/dconf/db/local.d/locks"
    mkdir -p "${db_dir}" "${lock_dir}"

    cat > "${db_dir}/00-corporate-wallpaper" <<EOF
[${schema}]
picture-uri='file://${LOCAL_WALLPAPER}'
picture-options='zoom'
EOF
    echo "/${schema}/picture-uri" > "${lock_dir}/corporate-wallpaper"
    echo "/${schema}/picture-options" >> "${lock_dir}/corporate-wallpaper"
    dconf update
    log INFO "dconf settings applied for ${de_name}."
}

configure_xfce() {
    mkdir -p /etc/xdg/xfce4/kiosk /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
    cat > /etc/xdg/xfce4/kiosk/kioskrc <<EOF
[xfce4-session]
CustomizeBackdrop=NONE
[xfce4-desktop]
CustomizeBackdrop=NONE
EOF
    cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<XML
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string" value="${LOCAL_WALLPAPER}"/>
        <property name="image-style" type="int" value="5"/>
      </property>
    </property>
  </property>
</channel>
XML
    log INFO "XFCE lockdown applied."
}

configure_kde() {
    local kdeglobals="/etc/xdg/kdeglobals"
    [[ ! -f "${kdeglobals}.backup" ]] && cp -a "${kdeglobals}" "${kdeglobals}.backup" 2>/dev/null || true

    sed -i '/^\[Wallpaper\]/,/^$/d; /^\[KDE Action Restrictions\]/,/^$/d' "${kdeglobals}" 2>/dev/null || true
    cat >> "${kdeglobals}" <<EOF
[Wallpaper]
Image=${LOCAL_WALLPAPER}
[Desktop][Locale][sl]
Image=${LOCAL_WALLPAPER}
[KDE Action Restrictions]
wallpapersettings=true
EOF
    mkdir -p /etc/kde/profile.d
    cat > /etc/kde/profile.d/corporate-wallpaper.conf <<EOF
[Wallpaper]
Image=${LOCAL_WALLPAPER}
[KDE Action Restrictions]
wallpapersettings=true
EOF
    if command -v kbuildsycoca5 >/dev/null 2>&1; then
        kbuildsycoca5 --noincremental 2>/dev/null || true
    fi
    log INFO "KDE Plasma lockdown applied."
}

create_apply_script() {
    cat > "${APPLY_SCRIPT}" << 'APPLY_EOF'
#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="/usr/share/wallpapers/corporate-wallpaper.jpg"
[[ ! -f "${WALLPAPER}" ]] && exit 0

DESKTOP="${XDG_CURRENT_DESKTOP:-}"

if [[ "${DESKTOP}" == *"GNOME"* || "${DESKTOP}" == *"MATE"* ]]; then
    until gsettings list-keys org.gnome.desktop.background >/dev/null 2>&1; do sleep 1; done
    if echo "${DESKTOP}" | grep -q "MATE"; then
        gsettings set org.mate.background picture-filename "${WALLPAPER}"
    else
        gsettings set org.gnome.desktop.background picture-uri "file://${WALLPAPER}"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER}"
    fi
elif [[ "${DESKTOP}" == *"XFCE"* ]]; then
    until xfconf-query -c xfce4-desktop -p /backdrop >/dev/null 2>&1; do sleep 1; done
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "${WALLPAPER}" -t string
elif [[ "${DESKTOP}" == *"KDE"* ]]; then
    until qdbus org.kde.plasmashell >/dev/null 2>&1; do sleep 1; done
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (var i=0; i<allDesktops.length; i++) {
            var d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', '${WALLPAPER}');
        }"
fi
APPLY_EOF
    chmod +x "${APPLY_SCRIPT}"
    log INFO "Apply script created at ${APPLY_SCRIPT}."
}

setup_autostart() {
    mkdir -p /etc/xdg/autostart /etc/skel/.config/autostart
    cat > "${AUTOSTART_GLOBAL}" <<EOF
[Desktop Entry]
Type=Application
Name=Corporate Wallpaper Enforcer
Exec=${APPLY_SCRIPT}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-KDE-autostart-phase=2
EOF
    cp -f "${AUTOSTART_GLOBAL}" "${AUTOSTART_SKEL}"

    for home_dir in /home/*; do
        if [[ -d "${home_dir}" ]]; then
            local user_home="${home_dir}/.config/autostart"
            mkdir -p "${user_home}"
            cp -f "${AUTOSTART_GLOBAL}" "${user_home}/"
            chown -R "$(stat -c '%u:%g' "${home_dir}")" "${user_home}/corporate-wallpaper.desktop"
        fi
    done
    log INFO "Autostart configured for all users."
}

# --- Main ---
main() {
    log INFO "=== Corporate Wallpaper Setup Started ==="
    check_root
    prepare_credentials
    validate_inputs
    detect_de

    mount_smb
    copy_wallpaper

    case "${CURRENT_DE}" in
        GNOME) configure_dconf "GNOME" ;;
        MATE)  configure_dconf "MATE" ;;
        XFCE)  configure_xfce ;;
        KDE)   configure_kde ;;
        ALL)
            configure_dconf "GNOME"
            configure_dconf "MATE"
            configure_xfce
            configure_kde
            ;;
        *) log WARN "Unknown DE '${CURRENT_DE}'. Skipping lockdown." ;;
    esac

    create_apply_script
    setup_autostart
    log INFO "=== Setup Completed Successfully ==="
}

main