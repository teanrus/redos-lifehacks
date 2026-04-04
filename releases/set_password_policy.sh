#!/bin/bash
#
# Скрипт настройки политики безопасности паролей для РЕД ОС
# Версия: 2.0
# Запуск: curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/set_password_policy.sh | sudo bash
# GitHub: https://github.com/teanrus/redos-lifehacks
#

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Вспомогательные функции
# ============================================================================

# Функция для безопасного чтения ввода из терминала
read_from_terminal() {
    local prompt=$1
    local answer
    echo -e "$prompt" >&2
    read -r answer < /dev/tty 2>/dev/null || true
    echo "$answer"
}

# Функция для запроса подтверждения
confirm_action() {
    local message=$1
    local answer
    
    answer=$(read_from_terminal "${YELLOW}$message (y/n)${NC}")
    if [[ $answer =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Функция для проверки успешности выполнения
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 успешно выполнено${NC}" >&2
    else
        echo -e "${RED}✗ Ошибка при выполнении: $1${NC}" >&2
        exit 1
    fi
}

# Логирование
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${BLUE}========================================${NC}"; }

# ============================================================================
# Проверка прав root
# ============================================================================
if [[ $EUID -ne 0 ]]; then
    log_error "Скрипт должен выполняться от имени root"
    exit 1
fi

# Проверка ОС (опционально - предупреждение если не РЕД ОС)
if [[ -f /etc/os-release ]]; then
    OS_ID=$(grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    if [[ "$OS_ID" != "redos" ]]; then
        log_warn "Скрипт разработан для РЕД ОС, обнаружена: $OS_ID"
        log_warn "Продолжение работы возможно, но не гарантируется"
    fi
fi

log_header
log_info "Настройка политики безопасности паролей в РЕД ОС"
log_header
echo ""

# ============================================================================
# Получение списка пользователей
# ============================================================================
declare -a USERS_ARRAY
USERS_ARRAY=($(awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1}' /etc/passwd))

echo -e "${BLUE}Обнаружены пользовательские учетные записи:${NC}"
if [[ ${#USERS_ARRAY[@]} -eq 0 ]]; then
    echo "  (нет пользователей с UID 1000-65534)"
else
    for user in "${USERS_ARRAY[@]}"; do
        echo "  - $user"
    done
fi
echo ""

# ============================================================================
# Выбор пользователя для применения настроек
# ============================================================================
echo -e "${BLUE}Выберите пользователя для применения настроек:${NC}"
echo "  1) Применить ко всем пользователям"
for i in "${!USERS_ARRAY[@]}"; do
    echo "  $((i + 2))) ${USERS_ARRAY[$i]}"
done
echo "  $(( ${#USERS_ARRAY[@]} + 2 ))) Пропустить настройку пользователей"
echo ""

USER_CHOICE=$(read_from_terminal "${YELLOW}Ваш выбор (1-${#USERS_ARRAY[@]}+2):${NC}")

TARGET_USERS=()
if [[ "$USER_CHOICE" == "1" ]]; then
    TARGET_USERS=("${USERS_ARRAY[@]}")
    echo -e "${GREEN}→ Будут применены настройки ко всем пользователям${NC}"
elif [[ "$USER_CHOICE" -ge 2 && "$USER_CHOICE" -le $(( ${#USERS_ARRAY[@]} + 1 )) ]]; then
    TARGET_USERS=("${USERS_ARRAY[$((USER_CHOICE - 2))]}")
    echo -e "${GREEN}→ Настройки будут применены к пользователю: ${TARGET_USERS[0]}${NC}"
else
    echo -e "${YELLOW}→ Настройка пользователей будет пропущена${NC}"
fi
echo ""

# ============================================================================
# Меню выбора действий
# ============================================================================
echo -e "${BLUE}Выберите действия для выполнения:${NC}"
echo ""

# Массивы для хранения пунктов меню и флагов
declare -a MENU_ITEMS
declare -A MENU_ENABLED

MENU_ITEMS=(
    "Настройка алгоритма хеширования (yescrypt)"
    "Настройка блокировки после неудачных попыток входа (pam_faillock)"
    "Настройка сложности паролей (pam_pwquality)"
    "Настройка истории паролей (pam_pwhistory)"
    "Настройка срока действия паролей"
    "Проверка прав доступа к системным файлам"
    "Настройка аудита (если установлен auditd)"
    "Настройка sudo (опционально)"
)

# По умолчанию все пункты включены
for i in "${!MENU_ITEMS[@]}"; do
    MENU_ENABLED[$i]=1
done

# Вывод меню
for i in "${!MENU_ITEMS[@]}"; do
    if [[ ${MENU_ENABLED[$i]} -eq 1 ]]; then
        echo -e "  [$((i + 1))] ✓ ${MENU_ITEMS[$i]}"
    else
        echo -e "  [$((i + 1))] ✗ ${MENU_ITEMS[$i]}"
    fi
done
echo "  [0] → Перейти к выполнению"
echo ""

# Обработка выбора пунктов меню
while true; do
    CHOICE=$(read_from_terminal "${YELLOW}Введите номер пункта для переключения (0 для продолжения):${NC}")
    
    if [[ "$CHOICE" == "0" ]]; then
        break
    fi
    
    if [[ "$CHOICE" -ge 1 && "$CHOICE" -le ${#MENU_ITEMS[@]} ]]; then
        IDX=$((CHOICE - 1))
        if [[ ${MENU_ENABLED[$IDX]} -eq 1 ]]; then
            MENU_ENABLED[$IDX]=0
            echo -e "  [$CHOICE] ✗ ${MENU_ITEMS[$IDX]}"
        else
            MENU_ENABLED[$IDX]=1
            echo -e "  [$CHOICE] ✓ ${MENU_ITEMS[$IDX]}"
        fi
    else
        echo -e "${RED}Неверный номер, попробуйте снова${NC}"
    fi
done
echo ""

# ============================================================================
# Выполнение выбранных действий
# ============================================================================

# Переменные для хранения результатов
declare -A RESULTS

# ============================================================================
# 1. Настройка алгоритма хеширования (yescrypt)
# ============================================================================
if [[ ${MENU_ENABLED[0]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}1. Настройка алгоритма хеширования (yescrypt)${NC}"
    log_header
    
    if confirm_action "Применить настройку алгоритма хеширования?"; then
        LOGIN_DEFS="/etc/login.defs"

        if grep -q "^ENCRYPT_METHOD" "$LOGIN_DEFS"; then
            sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD yescrypt/' "$LOGIN_DEFS"
        else
            echo "ENCRYPT_METHOD yescrypt" >> "$LOGIN_DEFS"
        fi

        if grep -q "^YESCRYPT_COST_FACTOR" "$LOGIN_DEFS"; then
            sed -i 's/^YESCRYPT_COST_FACTOR.*/YESCRYPT_COST_FACTOR 10/' "$LOGIN_DEFS"
        else
            echo "YESCRYPT_COST_FACTOR 10" >> "$LOGIN_DEFS"
        fi
        
        check_success "Алгоритм yescrypt настроен"
        RESULTS[0]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[0]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 2. Настройка блокировки после неудачных попыток входа (pam_faillock)
# ============================================================================
if [[ ${MENU_ENABLED[1]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}2. Настройка pam_faillock (блокировка после неудачных попыток)${NC}"
    log_header
    
    if confirm_action "Применить настройку блокировки (3 попытки, 15 минут)?"; then
        SYSTEM_AUTH="/etc/pam.d/system-auth"
        BACKUP_DIR="/etc/pam.d/backup"

        mkdir -p "$BACKUP_DIR"
        cp "$SYSTEM_AUTH" "$BACKUP_DIR/system-auth.$(date +%Y%m%d_%H%M%S)"

        # Удаляем старые строки pam_faillock и pam_tally2, если есть
        sed -i '/pam_faillock/d' "$SYSTEM_AUTH"
        sed -i '/pam_tally2/d' "$SYSTEM_AUTH"

        # Добавляем настройки pam_faillock в секцию auth
        if grep -q "pam_env.so" "$SYSTEM_AUTH"; then
            sed -i '/pam_env.so/a auth        required      pam_faillock.so preauth silent audit deny=3 unlock_time=900' "$SYSTEM_AUTH"
            sed -i '/pam_faillock.so preauth/a auth        [default=die]   pam_faillock.so authfail audit deny=3 unlock_time=900' "$SYSTEM_AUTH"
        fi

        # Добавляем сброс счётчика при успешном входе
        if grep -q "pam_unix.so" "$SYSTEM_AUTH"; then
            sed -i '/pam_unix.so.*sufficient/a auth        sufficient    pam_faillock.so authsucc audit deny=3 unlock_time=900' "$SYSTEM_AUTH"
        fi
        
        check_success "pam_faillock настроен"
        RESULTS[1]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[1]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 3. Настройка сложности паролей (pam_pwquality)
# ============================================================================
if [[ ${MENU_ENABLED[2]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}3. Настройка сложности паролей (pam_pwquality)${NC}"
    log_header
    
    # Запрос минимальной длины пароля
    MINLEN_INPUT=$(read_from_terminal "${YELLOW}Минимальная длина пароля (по умолчанию 14):${NC}")
    if [[ -z "$MINLEN_INPUT" || ! "$MINLEN_INPUT" =~ ^[0-9]+$ ]]; then
        MINLEN_INPUT=14
    fi
    
    if confirm_action "Применить настройку сложности паролей (мин. $MINLEN_INPUT символов)?"; then
        PWQUALITY_CONF="/etc/security/pwquality.conf"

        cat > "$PWQUALITY_CONF" << EOF
# Настройка сложности паролей для РЕД ОС
# Минимальная длина пароля
minlen = $MINLEN_INPUT

# Обязательное наличие различных типов символов
# Отрицательное значение означает обязательное наличие
dcredit = -1    # минимум 1 цифра
ucredit = -1    # минимум 1 заглавная буква
lcredit = -1    # минимум 1 строчная буква
ocredit = -1    # минимум 1 специальный символ

# Максимальное количество одинаковых подряд идущих символов
maxrepeat = 3

# Максимальное количество одинаковых символов подряд в одной позиции
maxclassrepeat = 4

# Проверка на наличие слова пользователя в пароле
usercheck = 1

# Минимальное количество различных классов символов
minclass = 4

# Количество попыток ввода пароля
retry = 3

# Принудительное применение к root
enforce_for_root = 1
EOF

        SYSTEM_AUTH="/etc/pam.d/system-auth"
        # Добавляем pam_pwquality в system-auth если ещё не добавлен
        if ! grep -q "pam_pwquality.so" "$SYSTEM_AUTH"; then
            sed -i '/pam_unix.so.*password/i password    requisite     pam_pwquality.so try_first_pass local_users_only' "$SYSTEM_AUTH"
        fi
        
        check_success "pam_pwquality настроен"
        RESULTS[2]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[2]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 4. Настройка истории паролей (pam_pwhistory)
# ============================================================================
if [[ ${MENU_ENABLED[3]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}4. Настройка истории паролей (pam_pwhistory)${NC}"
    log_header
    
    if confirm_action "Применить настройку истории паролей (запоминание 5 последних)?"; then
        HISTORY_CONF="/etc/security/pwhistory.conf"

        cat > "$HISTORY_CONF" << 'EOF'
# Настройка истории паролей для РЕД ОС
# Количество запоминаемых старых паролей
remember = 5

# Принудительное применение к root
enforce_for_root = 1
EOF

        SYSTEM_AUTH="/etc/pam.d/system-auth"
        # Добавляем pam_pwhistory в system-auth если ещё не добавлен
        if ! grep -q "pam_pwhistory.so" "$SYSTEM_AUTH"; then
            sed -i '/pam_pwquality.so/a password    required      pam_pwhistory.so remember=5 use_authtok' "$SYSTEM_AUTH"
        fi
        
        check_success "pam_pwhistory настроен"
        RESULTS[3]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[3]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 5. Настройка срока действия паролей
# ============================================================================
if [[ ${MENU_ENABLED[4]} -eq 1 && ${#TARGET_USERS[@]} -gt 0 ]]; then
    log_header
    echo -e "${BLUE}5. Настройка срока действия паролей${NC}"
    log_header
    
    if confirm_action "Применить настройку срока действия паролей (90 дней)?"; then
        for user in "${TARGET_USERS[@]}"; do
            if id "$user" &>/dev/null; then
                chage --maxdays 90 --mindays 7 --warn 5 --inactive 14 "$user" 2>/dev/null
                check_success "Настройки для пользователя $user"
            else
                echo -e "${RED}✗ Пользователь $user не найден${NC}"
            fi
        done
        RESULTS[4]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[4]="✗ Пропущено"
    fi
    echo ""
elif [[ ${MENU_ENABLED[4]} -eq 1 ]]; then
    echo -e "${YELLOW}5. Настройка срока действия паролей - пропущено (пользователи не выбраны)${NC}"
    RESULTS[4]="✗ Нет пользователей"
    echo ""
fi

# ============================================================================
# 6. Проверка прав доступа к системным файлам
# ============================================================================
if [[ ${MENU_ENABLED[5]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}6. Проверка прав доступа к системным файлам${NC}"
    log_header
    
    if confirm_action "Установить рекомендуемые права доступа?"; then
        # /etc/shadow - только root
        chown root:root /etc/shadow
        chmod 0000 /etc/shadow
        check_success "Права на /etc/shadow"

        # /etc/passwd - чтение всем, запись только root
        chown root:root /etc/passwd
        chmod 644 /etc/passwd
        check_success "Права на /etc/passwd"

        # /etc/group - чтение всем, запись только root
        chown root:root /etc/group
        chmod 644 /etc/group
        check_success "Права на /etc/group"
        
        RESULTS[5]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[5]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# 7. Настройка аудита (если установлен auditd)
# ============================================================================
if [[ ${MENU_ENABLED[6]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}7. Настройка аудита${NC}"
    log_header
    
    if command -v auditctl &> /dev/null; then
        if confirm_action "Применить правила аудита изменений паролей?"; then
            AUDIT_RULES="/etc/audit/rules.d/password_audit.rules"

            cat > "$AUDIT_RULES" << 'EOF'
# Аудит изменений паролей
-w /usr/bin/passwd -p x -k password_change
-w /etc/shadow -p wa -k shadow_access
-w /etc/security/opasswd -p wa -k password_history
-w /etc/pam.d/system-auth -p wa -k pam_config_change
EOF

            # Применяем правила
            auditctl -R "$AUDIT_RULES" 2>/dev/null || log_warn "Не удалось применить правила аудита"
            
            check_success "Аудит настроен"
            RESULTS[6]="✓ Выполнено"
        else
            echo -e "${YELLOW}→ Пропущено${NC}"
            RESULTS[6]="✗ Пропущено"
        fi
    else
        log_warn "auditd не установлен - настройка аудита пропущена"
        RESULTS[6]="✗ auditd не найден"
    fi
    echo ""
fi

# ============================================================================
# 8. Настройка sudo (опционально)
# ============================================================================
if [[ ${MENU_ENABLED[7]} -eq 1 ]]; then
    log_header
    echo -e "${BLUE}8. Настройка sudo${NC}"
    log_header
    
    if confirm_action "Настроить timeout для sudo (5 минут)?"; then
        SUDOERS="/etc/sudoers"

        if ! grep -q "timestamp_timeout" "$SUDOERS"; then
            # Добавляем настройку timeout для sudo (5 минут)
            echo "Defaults timestamp_timeout=5" | EDITOR='tee -a' visudo
            check_success "sudo timeout установлен"
        else
            echo -e "${GREEN}✓ sudo timeout уже настроен${NC}"
        fi
        
        RESULTS[7]="✓ Выполнено"
    else
        echo -e "${YELLOW}→ Пропущено${NC}"
        RESULTS[7]="✗ Пропущено"
    fi
    echo ""
fi

# ============================================================================
# Итоги
# ============================================================================
log_header
log_info "Настройка политики безопасности завершена!"
log_header
echo ""
echo -e "${BLUE}Результаты выполнения:${NC}"
echo ""

for i in "${!MENU_ITEMS[@]}"; do
    if [[ -n "${RESULTS[$i]}" ]]; then
        printf "  %-60s %s\n" "${MENU_ITEMS[$i]}" "${RESULTS[$i]}"
    fi
done

echo ""
if [[ ${#TARGET_USERS[@]} -gt 0 ]]; then
    echo -e "${BLUE}Настройки применены к пользователям:${NC}"
    for user in "${TARGET_USERS[@]}"; do
        echo "  - $user"
    done
    echo ""
    log_warn "Важно: Пользователям потребуется сменить пароли при следующем входе"
fi

echo ""
echo -e "${BLUE}Полезные команды для проверки:${NC}"
echo "  chage -l \$USER                    # проверка политики паролей"
echo "  grep -E '^\\\$y\\\$' /etc/shadow     # проверка алгоритма хеширования"
echo "  grep pam_faillock /etc/pam.d/system-auth  # проверка блокировки"
echo ""
