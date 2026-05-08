#!/bin/bash
##############################################################################
# user-migration.sh — Миграция пользователя в РЕД ОС
#
# Назначение: Создание нового пользователя и перенос всех данных от старого
#
# Использование:
#   sudo ./user-migration.sh [ОПЦИИ]
#
# Опции:
#   -h, --help              Справка
#   -u, --user USERNAME     Имя нового пользователя
#   -o, --old-user OLDNAME  Имя старого пользователя
#
# Зависимости: bash, coreutils, rsync
# Совместимость: РЕД ОС 7.x ✅, РЕД ОС 8.x ✅
##############################################################################
set -u

# ============================================ #
# ЦВЕТОВОЕ ОФОРМЛЕНИЕ
# ============================================ #

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================ #
# ФУНКЦИИ
# ============================================ #

print_header() {
    echo ""
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}============================================${NC}"
}

print_step() {
    echo ""
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

clear_new_user_keyrings() {
    local keyrings_dir="/home/$NEW_USER/.local/share/keyrings"

    if [ ! -d "$keyrings_dir" ]; then
        return
    fi

    find "$keyrings_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
}

format_bytes() {
    local bytes="${1:-0}"
    numfmt --to=iec --suffix=B "$bytes" 2>/dev/null || echo "${bytes} байт"
}

get_dir_size_bytes() {
    local dir="$1"
    local size

    if [ ! -d "$dir" ]; then
        echo 0
        return
    fi

    size=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')
    echo "${size:-0}"
}

get_free_space_bytes() {
    local path="$1"
    local free_space

    free_space=$(df -PB1 "$path" 2>/dev/null | awk 'NR==2 {print $4}')
    echo "${free_space:-0}"
}

# ============================================ #
# ПРОВЕРКА ПРАВ ДОСТУПА
# ============================================ #

if [ "$EUID" -ne 0 ]; then 
    print_error "Запустите скрипт от имени root (sudo ./user-migration.sh)"
    exit 1
fi

print_header "🔄 МИГРАЦИЯ ПОЛЬЗОВАТЕЛЯ В РЕД ОС"

# ============================================ #
# ПОЛУЧЕНИЕ СПИСКА ПОЛЬЗОВАТЕЛЕЙ
# ============================================ #

print_step "Получение списка пользователей системы..."

# Получаем список обычных пользователей (UID >= 1000)
mapfile -t USERS < <(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

if [ ${#USERS[@]} -eq 0 ]; then
    print_error "Не найдено обычных пользователей в системе (UID >= 1000)"
    exit 1
fi

print_success "Найдено пользователей: ${#USERS[@]}"

# ============================================ #
# ВЫБОР СТАРОГО ПОЛЬЗОВАТЕЛЯ
# ============================================ #

print_header "👤 ВЫБОР СТАРОГО ПОЛЬЗОВАТЕЛЯ"
echo ""
echo "Список пользователей системы:"
echo ""

# Вывод нумерованного списка
for i in "${!USERS[@]}"; do
    num=$((i + 1))
    # Получаем дополнительную информацию о пользователе
    user_info=$(getent passwd "${USERS[$i]}" | cut -d: -f5)
    home_dir=$(getent passwd "${USERS[$i]}" | cut -d: -f6)
    
    if [ -n "$user_info" ]; then
        echo -e "   ${num}) ${USERS[$i]} ${CYAN}($user_info)${NC}"
    else
        echo -e "   ${num}) ${USERS[$i]}"
    fi
    echo -e "      Домашний каталог: ${home_dir}"
done

echo ""

# Запрос выбора пользователя
while true; do
    echo ""
    echo -n "Введите номер пользователя для переноса данных (1-${#USERS[@]}): "
    read user_choice
    
    # Проверка на корректность ввода
    if [[ "$user_choice" =~ ^[0-9]+$ ]]; then
        if [ "$user_choice" -ge 1 ] && [ "$user_choice" -le "${#USERS[@]}" ]; then
            OLD_USER="${USERS[$((user_choice - 1))]}"
            break
        else
            print_warning "Введите число от 1 до ${#USERS[@]}"
        fi
    else
        print_warning "Введите корректное число"
    fi
done

print_success "Выбран пользователь: ${OLD_USER}"

# Проверка существования домашнего каталога
if [ ! -d "/home/$OLD_USER" ]; then
    print_warning "Домашний каталог /home/$OLD_USER не найден"
    echo -n "Продолжить без переноса файлов? (y/n): "
    read continue_choice
    if [ "$continue_choice" != "y" ]; then
        print_error "Операция отменена"
        exit 1
    fi
fi

# ============================================ #
# ОЦЕНКА ОБЪЕМА ДАННЫХ И СВОБОДНОГО МЕСТА
# ============================================ #

TRANSFER_MODE="copy"
TRANSFERRED_DATA_BYTES=0
TRANSFER_STATUS="не выполнялся"
OLD_HOME="/home/$OLD_USER"
HOME_TARGET_ROOT="/home"

print_header "💾 ПРОВЕРКА МЕСТА НА ДИСКЕ"

if [ -d "$OLD_HOME" ]; then
    DATA_SIZE_BYTES=$(get_dir_size_bytes "$OLD_HOME")
    DATA_SIZE_HUMAN=$(format_bytes "$DATA_SIZE_BYTES")
    FREE_SPACE_BYTES=$(get_free_space_bytes "$HOME_TARGET_ROOT")
    FREE_SPACE_HUMAN=$(format_bytes "$FREE_SPACE_BYTES")

    echo ""
    echo "Оценка переносимых данных:"
    echo "-------------------------------------------"
    echo -e "📁 Каталог источника: $OLD_HOME"
    echo -e "📦 Объем данных: ${CYAN}$DATA_SIZE_HUMAN${NC}"
    echo -e "💽 Свободно в $HOME_TARGET_ROOT: ${CYAN}$FREE_SPACE_HUMAN${NC}"
    echo "-------------------------------------------"
    echo ""

    if [ "$DATA_SIZE_BYTES" -gt "$FREE_SPACE_BYTES" ]; then
        print_warning "Свободного места недостаточно для копирования всех данных."
        echo "   Рекомендуется освободить место на разделе $HOME_TARGET_ROOT и запустить скрипт повторно."
        echo ""
        echo "Выберите дальнейшее действие:"
        echo "   1) Прекратить работу скрипта"
        echo "   2) Не копировать данные, а переместить их новому пользователю"
        echo ""

        while true; do
            echo -n "Ваш выбор (1/2): "
            read disk_space_choice

            case "$disk_space_choice" in
                1)
                    print_error "Операция отменена. Освободите место на диске и запустите скрипт повторно."
                    exit 1
                    ;;
                2)
                    TRANSFER_MODE="move"
                    print_warning "Выбран режим перемещения: исходные файлы будут удаляться после успешного переноса."
                    break
                    ;;
                *)
                    print_warning "Введите 1 или 2"
                    ;;
            esac
        done
    else
        print_success "Свободного места достаточно для копирования данных"
    fi
else
    DATA_SIZE_BYTES=0
    DATA_SIZE_HUMAN=$(format_bytes "$DATA_SIZE_BYTES")
    FREE_SPACE_BYTES=$(get_free_space_bytes "$HOME_TARGET_ROOT")
    FREE_SPACE_HUMAN=$(format_bytes "$FREE_SPACE_BYTES")
    print_warning "Домашний каталог старого пользователя не найден, оценка данных равна 0"
fi

# ============================================ #
# ВВОД ДАННЫХ НОВОГО ПОЛЬЗОВАТЕЛЯ
# ============================================ #

print_header "👤 ДАННЫЕ НОВОГО ПОЛЬЗОВАТЕЛЯ"

# Ввод логина нового пользователя
while true; do
    echo ""
    echo -n "Введите логин нового пользователя (латиницей): "
    read NEW_USER
    
    # Проверка на пустой ввод
    if [ -z "$NEW_USER" ]; then
        print_warning "Логин не может быть пустым"
        continue
    fi
    
    # Проверка на допустимые символы
    if [[ ! "$NEW_USER" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        print_warning "Логин должен начинаться с буквы и содержать только латинские буквы, цифры, '-' и '_'"
        continue
    fi
    
    # Проверка существования пользователя
    if id "$NEW_USER" &>/dev/null; then
        print_warning "Пользователь '$NEW_USER' уже существует"
        continue
    fi
    
    break
done

print_success "Логин нового пользователя: ${NEW_USER}"

# Ввод ФИО
echo ""
echo -n "Введите ФИО нового пользователя (например: Новикова Анна Михайловна): "
read NEW_USER_FULL_NAME

if [ -z "$NEW_USER_FULL_NAME" ]; then
    NEW_USER_FULL_NAME="Новый пользователь"
    print_warning "ФИО не указано, установлено значение по умолчанию: '$NEW_USER_FULL_NAME'"
fi

# Ввод должности/комментария
echo -n "Введите должность или комментарий (например: Ведущий специалист): "
read NEW_USER_COMMENT

if [ -z "$NEW_USER_COMMENT" ]; then
    NEW_USER_COMMENT=""
fi

# ============================================ #
# ПОДТВЕРЖДЕНИЕ ОПЕРАЦИИ
# ============================================ #

print_header "📋 ПОДТВЕРЖДЕНИЕ ОПЕРАЦИИ"

echo ""
echo "Параметры миграции:"
echo "-------------------------------------------"
echo -e "📁 Старый пользователь: ${RED}$OLD_USER${NC}"
echo -e "👤 Новый пользователь: ${GREEN}$NEW_USER${NC}"
echo -e "📝 ФИО: $NEW_USER_FULL_NAME"
echo -e "📦 Объем переносимых данных: $DATA_SIZE_HUMAN"
if [ "$TRANSFER_MODE" = "move" ]; then
    echo -e "🚚 Режим переноса: перемещение данных"
else
    echo -e "🚚 Режим переноса: копирование данных"
fi
if [ -n "$NEW_USER_COMMENT" ]; then
    echo -e "💼 Должность: $NEW_USER_COMMENT"
fi
echo "-------------------------------------------"
echo ""

echo -n "Продолжить миграцию? (y/n): "
read confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    print_error "Операция отменена пользователем"
    exit 0
fi

# ============================================ #
# 1. СОЗДАНИЕ НОВОГО ПОЛЬЗОВАТЕЛЯ
# ============================================ #

print_step "Шаг 1/8: Создание нового пользователя..."

comment_string="$NEW_USER_FULL_NAME"
if [ -n "$NEW_USER_COMMENT" ]; then
    comment_string="$NEW_USER_FULL_NAME, $NEW_USER_COMMENT"
fi

useradd -m -c "$comment_string" "$NEW_USER"

if [ $? -eq 0 ]; then
    print_success "Пользователь '$NEW_USER' успешно создан"
else
    print_error "Ошибка при создании пользователя"
    exit 1
fi

# ============================================ #
# 2. УСТАНОВКА ПАРОЛЯ
# ============================================ #

print_step "Шаг 2/8: Установка пароля для нового пользователя"
echo "   Введите пароль дважды при запросе системы:"
echo ""

passwd "$NEW_USER"

# ============================================ #
# 3. ДОБАВЛЕНИЕ В ГРУППЫ
# ============================================ #

print_step "Шаг 3/8: Добавление в группы..."

# Запрос на добавление в группу wheel
echo ""
echo "Группа 'wheel' предоставляет права администратора (доступ к sudo)"
echo ""
echo -n "Добавить пользователя '$NEW_USER' в группу 'wheel'? (y/n): "
read add_to_wheel

if [ "$add_to_wheel" = "y" ] || [ "$add_to_wheel" = "Y" ]; then
    usermod -aG wheel "$NEW_USER"
    print_success "Добавлен в группу 'wheel' (sudo)"
else
    print_warning "Пользователь не добавлен в группу 'wheel'"
    echo "   Для добавления позже выполните: sudo usermod -aG wheel $NEW_USER"
fi

# ============================================ #
# 4. ПЕРЕНОС ФАЙЛОВ
# ============================================ #

print_step "Шаг 4/8: Перенос файлов из /home/$OLD_USER/"

if [ -d "/home/$OLD_USER" ]; then
    echo ""
    print_warning "Перенос файлов может занять несколько минут..."
    echo ""
    
    if [ "$TRANSFER_MODE" = "move" ]; then
        # Перемещение файлов: после успешной передачи исходные файлы удаляются.
        rsync -avh --progress --remove-source-files "/home/$OLD_USER/" "/home/$NEW_USER/"
        transfer_result=$?

        if [ $transfer_result -eq 0 ]; then
            find "/home/$OLD_USER" -mindepth 1 -depth -type d -empty -delete 2>/dev/null || true
            print_success "Файлы успешно перемещены"
            TRANSFERRED_DATA_BYTES="$DATA_SIZE_BYTES"
            TRANSFER_STATUS="перемещено"
        else
            print_warning "При перемещении возникли ошибки"
            TRANSFER_STATUS="перемещение завершилось с ошибками"
        fi
    else
        # Копирование всех файлов с сохранением атрибутов
        rsync -avh --progress "/home/$OLD_USER/" "/home/$NEW_USER/"
        transfer_result=$?
    
        if [ $transfer_result -eq 0 ]; then
            print_success "Файлы успешно скопированы"
            TRANSFERRED_DATA_BYTES="$DATA_SIZE_BYTES"
            TRANSFER_STATUS="скопировано"
        else
            print_warning "При копировании возникли ошибки"
            TRANSFER_STATUS="копирование завершилось с ошибками"
        fi
    fi
else
    print_warning "Домашний каталог старого пользователя не найден, перенос пропущен"
    TRANSFER_STATUS="пропущен"
fi

# ============================================ #
# 5. ПЕРЕНОС ДАННЫХ БРАУЗЕРОВ
# ============================================ #

print_step "Шаг 5/8: Перенос данных браузеров..."

browser_count=0

if [ "$TRANSFER_MODE" = "move" ]; then
    print_warning "Отдельный перенос браузеров пропущен: профили уже вошли в перемещение домашнего каталога"
else
# Google Chrome / Chromium
if [ -d "/home/$OLD_USER/.config/google-chrome" ]; then
    if rsync -avh "/home/$OLD_USER/.config/google-chrome/" "/home/$NEW_USER/.config/google-chrome/"; then
        print_success "Google Chrome: данные перенесены"
        browser_count=$((browser_count + 1))
    fi
fi

if [ -d "/home/$OLD_USER/.config/chromium" ]; then
    if rsync -avh "/home/$OLD_USER/.config/chromium/" "/home/$NEW_USER/.config/chromium/"; then
        print_success "Chromium: данные перенесены"
        browser_count=$((browser_count + 1))
    fi
fi

# Mozilla Firefox
if [ -d "/home/$OLD_USER/.mozilla/firefox" ]; then
    if rsync -avh "/home/$OLD_USER/.mozilla/firefox/" "/home/$NEW_USER/.mozilla/firefox/"; then
        print_success "Mozilla Firefox: данные перенесены"
        browser_count=$((browser_count + 1))
    fi
fi

# Яндекс.Браузер
if [ -d "/home/$OLD_USER/.config/Yandex/YandexBrowser" ]; then
    if rsync -avh "/home/$OLD_USER/.config/Yandex/YandexBrowser/" "/home/$NEW_USER/.config/Yandex/YandexBrowser/"; then
        print_success "Яндекс.Браузер: данные перенесены"
        browser_count=$((browser_count + 1))
    fi
fi

# Opera
if [ -d "/home/$OLD_USER/.config/opera" ]; then
    if rsync -avh "/home/$OLD_USER/.config/opera/" "/home/$NEW_USER/.config/opera/"; then
        print_success "Opera: данные перенесены"
        browser_count=$((browser_count + 1))
    fi
fi

if [ $browser_count -eq 0 ]; then
    print_warning "Данные браузеров не найдены или уже перенесены"
fi
fi

# ============================================ #
# 6. ОЧИСТКА СВЯЗКИ КЛЮЧЕЙ GNOME KEYRING
# ============================================ #

print_step "Шаг 6/8: Очистка связки ключей GNOME Keyring..."

if [ -d "/home/$NEW_USER/.local/share/keyrings" ]; then
    clear_new_user_keyrings
    print_success "Связка ключей нового пользователя очищена"
    echo "   При первом входе GNOME Keyring создаст новую связку ключей для $NEW_USER"
else
    print_warning "Каталог связки ключей не найден, очистка не требуется"
fi

# ============================================ #
# 7. ИСПРАВЛЕНИЕ ПРАВ ДОСТУПА
# ============================================ #

print_step "Шаг 7/8: Исправление прав доступа..."

# Смена владельца всех файлов на нового пользователя
chown -R "$NEW_USER":"$NEW_USER" "/home/$NEW_USER/"

# Установка корректных прав на домашний каталог
chmod 750 "/home/$NEW_USER"

# Установка правильных прав на скрытые папки
chmod 700 "/home/$NEW_USER/.ssh" 2>/dev/null || true
chmod 600 "/home/$NEW_USER/.ssh/"* 2>/dev/null || true

print_success "Права доступа установлены"

# ============================================ #
# 8. ПРОВЕРКА РЕЗУЛЬТАТА
# ============================================ #

print_step "Шаг 8/8: Проверка результата..."

echo ""
echo "📊 Информация о пользователе:"
echo "-------------------------------------------"
id "$NEW_USER"
echo ""

echo "📁 Размер перенесённых данных:"
echo "-------------------------------------------"
du -sh "/home/$NEW_USER/" 2>/dev/null || echo "   Данные недоступны"
echo ""

NEW_HOME_SIZE_BYTES=$(get_dir_size_bytes "/home/$NEW_USER")
NEW_HOME_SIZE_HUMAN=$(format_bytes "$NEW_HOME_SIZE_BYTES")
TRANSFERRED_DATA_HUMAN=$(format_bytes "$TRANSFERRED_DATA_BYTES")

echo "📊 Сводка переноса:"
echo "-------------------------------------------"
echo "   Режим: $([ "$TRANSFER_MODE" = "move" ] && echo "перемещение" || echo "копирование")"
echo "   Статус: $TRANSFER_STATUS"
echo "   Оценка исходных данных: $DATA_SIZE_HUMAN"
echo "   Перенесено по оценке: $TRANSFERRED_DATA_HUMAN"
echo "   Текущий размер /home/$NEW_USER: $NEW_HOME_SIZE_HUMAN"
echo "-------------------------------------------"
echo ""

echo "📂 Структура домашнего каталога (первые 15 строк):"
echo "-------------------------------------------"
ls -la "/home/$NEW_USER/" | head -15
echo ""

# ============================================ #
# ЗАВЕРШЕНИЕ
# ============================================ #

print_header "✅ МИГРАЦИЯ УСПЕШНО ЗАВЕРШЕНА!"

echo ""
echo "📝 Следующие шаги:"
echo "   1. Выйдите из системы под текущим пользователем"
echo "   2. Войдите под пользователем: $NEW_USER"
echo "   3. Проверьте работу браузеров и приложений"
echo ""

# ============================================ #
# УДАЛЕНИЕ СТАРОГО ПОЛЬЗОВАТЕЛЯ
# ============================================ #

print_header "🗑️  УДАЛЕНИЕ СТАРОГО ПОЛЬЗОВАТЕЛЯ"

echo ""
echo -e "${RED}⚠️  ВНИМАНИЕ!${NC}"
echo "Это действие удалит:"
echo "   - Учётную запись пользователя: $OLD_USER"
echo "   - Домашний каталог: /home/$OLD_USER"
echo "   - Почтовый ящик: /var/spool/mail/$OLD_USER"
echo "   - Все файлы пользователя в системе"
echo ""
echo -e "${RED}Это действие НЕОБРАТИМО!${NC}"
echo ""

echo -n "Удалить старого пользователя '$OLD_USER'? (y/n): "
read delete_choice

if [ "$delete_choice" = "y" ] || [ "$delete_choice" = "Y" ]; then
    echo ""
    print_warning "Удаление пользователя $OLD_USER..."
    
    # Завершение всех процессов пользователя
    pkill -9 -u "$OLD_USER" 2>/dev/null || true
    pkill -15 -u "$OLD_USER" 2>/dev/null || true
    
    # Удаление пользователя и его домашнего каталога
    userdel -r "$OLD_USER"
    
    if [ $? -eq 0 ]; then
        print_success "Пользователь '$OLD_USER' успешно удалён"
    else
        print_warning "Ошибка при удалении пользователя (возможно, он ещё используется)"
        echo "   Попробуйте удалить вручную позже: sudo userdel -r $OLD_USER"
    fi
else
    print_warning "Старый пользователь не удалён"
    echo "   Для удаления позже выполните: sudo userdel -r $OLD_USER"
fi

# ============================================ #
# ФИНАЛЬНОЕ СООБЩЕНИЕ
# ============================================ #

print_header "🎉 РАБОТА СКРИПТА ЗАВЕРШЕНА"

echo ""
echo -e "Новый пользователь готов к работе: ${GREEN}$NEW_USER${NC}"
echo "Перенос данных: $TRANSFER_STATUS, объем: $TRANSFERRED_DATA_HUMAN"
echo "Размер домашнего каталога /home/$NEW_USER: $NEW_HOME_SIZE_HUMAN"
echo ""
echo "📞 Поддержка:"
echo "   Документация: https://github.com/teanrus/redos-lifehacks"
echo "   Скрипт: https://github.com/teanrus/redos-lifehacks/releases/latest/download/user-migration.sh"
echo ""
echo "============================================"
