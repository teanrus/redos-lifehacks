#!/bin/bash

# =============================================================================
# rsync-copy.sh — Интерактивный скрипт для копирования файлов через rsync
# Описание: Копирование файлов с исходной машины на целевую по SSH
# Документация: docs/network/rsync-file-copy.md
# =============================================================================

set -euo pipefail

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# Функции
# =============================================================================

# Функция для безопасного чтения ввода из терминала
read_from_terminal() {
    local prompt="$1"
    local answer
    echo -e "$prompt" >&2
    read -r answer < /dev/tty 2>/dev/null || true
    echo "$answer"
}

# Функция для чтения скрытого ввода (пароль)
read_secret() {
    local prompt="$1"
    local password
    echo -e "$prompt" >&2
    read -r -s password < /dev/tty 2>/dev/null || true
    echo "" >&2
    echo "$password"
}

# Функция для проверки успешности выполнения команд
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 успешно выполнено${NC}"
    else
        echo -e "${RED}✗ Ошибка при выполнении: $1${NC}"
        exit 1
    fi
}

# Функция для проверки наличия команды
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${YELLOW}Устанавливаю $1...${NC}"
        sudo dnf install -y "$1"
        check_success "Установка $1"
    fi
}

# Функция для проверки существования пути
check_path_exists() {
    local path="$1"
    if [ -e "$path" ]; then
        return 0
    else
        return 1
    fi
}

# Функция для проверки доступности хоста
check_host_reachable() {
    local ip="$1"
    if ping -c 2 -W 3 "$ip" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Функция для проверки SSH-доступа
check_ssh_access() {
    local user="$1"
    local host="$2"
    local password="$3"
    
    if sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=no "$user@$host" "echo 'SSH доступ подтверждён'" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Функция для проверки существования папки на удалённом хосте
check_remote_dir_exists() {
    local user="$1"
    local host="$2"
    local password="$3"
    local remote_path="$4"
    
    if sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$user@$host" "[ -d '$remote_path' ]" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Функция для создания папки на удалённом хосте
create_remote_dir() {
    local user="$1"
    local host="$2"
    local password="$3"
    local remote_path="$4"
    
    echo -e "${YELLOW}Создаю папку $remote_path на удалённом хосте...${NC}"
    if sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$user@$host" "mkdir -p '$remote_path'" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Папка создана${NC}"
        return 0
    else
        echo -e "${RED}✗ Не удалось создать папку${NC}"
        return 1
    fi
}

# Функция для отображения заголовка
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Копирование файлов через rsync (SSH)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Функция для отображения разделителя
print_separator() {
    echo -e "${BLUE}----------------------------------------${NC}"
}

# =============================================================================
# Основная логика
# =============================================================================

main() {
    print_header
    
    # Проверка необходимых утилит
    echo -e "${CYAN}Проверка необходимых утилит...${NC}"
    check_command rsync
    check_command sshpass
    echo ""
    
    # --- Шаг 1: Исходная папка ---
    print_separator
    echo -e "${CYAN}Шаг 1: Укажите исходную папку${NC}"
    print_separator
    
    while true; do
        SOURCE_DIR=$(read_from_terminal "Введите путь к исходной папке (например, /home/user/Документы):")
        
        if [ -z "$SOURCE_DIR" ]; then
            echo -e "${RED}✗ Путь не может быть пустым${NC}"
            continue
        fi
        
        # Проверка существования папки
        if check_path_exists "$SOURCE_DIR"; then
            if [ -d "$SOURCE_DIR" ]; then
                echo -e "${GREEN}✓ Папка найдена: $SOURCE_DIR${NC}"
                break
            else
                echo -e "${YELLOW}⚠ Указанный путь является файлом, а не папкой${NC}"
                continue
            fi
        else
            # Попытка найти папку с похожим именем (проверка регистра)
            PARENT_DIR=$(dirname "$SOURCE_DIR")
            BASE_NAME=$(basename "$SOURCE_DIR")
            
            if check_path_exists "$PARENT_DIR"; then
                SIMILAR=$(find "$PARENT_DIR" -maxdepth 1 -iname "$BASE_NAME" -type d 2>/dev/null | head -1)
                
                if [ -n "$SIMILAR" ]; then
                    echo -e "${YELLOW}⚠ Папка не найдена, но есть похожая: $SIMILAR${NC}"
                    USE_SIMILAR=$(read_from_terminal "Использовать этот путь? (да/нет):")
                    if [[ "$USE_SIMILAR" == "да" || "$USE_SIMILAR" == "y" || "$USE_SIMILAR" == "д" ]]; then
                        SOURCE_DIR="$SIMILAR"
                        echo -e "${GREEN}✓ Папка найдена: $SOURCE_DIR${NC}"
                        break
                    fi
                else
                    echo -e "${RED}✗ Папка не найдена: $SOURCE_DIR${NC}"
                fi
            else
                echo -e "${RED}✗ Папка не найдена: $SOURCE_DIR${NC}"
            fi
        fi
    done
    echo ""
    
    # --- Шаг 2: IP целевого компьютера ---
    print_separator
    echo -e "${CYAN}Шаг 2: Укажите IP целевого компьютера${NC}"
    print_separator
    
    while true; do
        TARGET_IP=$(read_from_terminal "Введите IP-адрес целевого компьютера (например, 192.168.1.200):")
        
        if [ -z "$TARGET_IP" ]; then
            echo -e "${RED}✗ IP-адрес не может быть пустым${NC}"
            continue
        fi
        
        echo -e "${YELLOW}Проверяю доступность $TARGET_IP...${NC}"
        if check_host_reachable "$TARGET_IP"; then
            echo -e "${GREEN}✓ Компьютер доступен: $TARGET_IP${NC}"
            break
        else
            echo -e "${RED}✗ Компьютер не отвечает по адресу $TARGET_IP${NC}"
            RETRY=$(read_from_terminal "Попробовать снова? (да/нет):")
            if [[ "$RETRY" != "да" && "$RETRY" != "y" && "$RETRY" != "д" ]]; then
                echo -e "${YELLOW}Операция отменена пользователем${NC}"
                exit 0
            fi
        fi
    done
    echo ""
    
    # --- Шаг 3: Пользователь целевого компьютера ---
    print_separator
    echo -e "${CYAN}Шаг 3: Укажите пользователя целевого компьютера${NC}"
    print_separator
    
    while true; do
        TARGET_USER=$(read_from_terminal "Введите имя пользователя (например, admin или user):")
        
        if [ -z "$TARGET_USER" ]; then
            echo -e "${RED}✗ Имя пользователя не может быть пустым${NC}"
            continue
        fi
        
        echo -e "${GREEN}✓ Пользователь: $TARGET_USER${NC}"
        break
    done
    echo ""
    
    # --- Шаг 4: Пароль пользователя ---
    print_separator
    echo -e "${CYAN}Шаг 4: Укажите пароль пользователя${NC}"
    print_separator
    
    while true; do
        TARGET_PASSWORD=$(read_secret "Введите пароль пользователя $TARGET_USER:")
        
        if [ -z "$TARGET_PASSWORD" ]; then
            echo -e "${RED}✗ Пароль не может быть пустым${NC}"
            continue
        fi
        
        echo -e "${YELLOW}Проверяю SSH-доступ для $TARGET_USER@$TARGET_IP...${NC}"
        if check_ssh_access "$TARGET_USER" "$TARGET_IP" "$TARGET_PASSWORD"; then
            echo -e "${GREEN}✓ SSH-доступ подтверждён для $TARGET_USER@$TARGET_IP${NC}"
            break
        else
            echo -e "${RED}✗ Не удалось подключиться по SSH. Проверьте пароль и настройки.${NC}"
            echo -e "${YELLOW}Подсказка: На РЕД ОС обычные пользователи могут не иметь SSH-доступа.${NC}"
            RETRY=$(read_from_terminal "Попробовать снова? (да/нет):")
            if [[ "$RETRY" != "да" && "$RETRY" != "y" && "$RETRY" != "д" ]]; then
                echo -e "${YELLOW}Операция отменена пользователем${NC}"
                exit 0
            fi
        fi
    done
    echo ""
    
    # --- Шаг 5: Целевая папка ---
    print_separator
    echo -e "${CYAN}Шаг 5: Укажите целевую папку${NC}"
    print_separator
    
    while true; do
        TARGET_DIR=$(read_from_terminal "Введите путь к целевой папке на удалённом компьютере (например, /home/user/Документы/backup):")
        
        if [ -z "$TARGET_DIR" ]; then
            echo -e "${RED}✗ Путь не может быть пустым${NC}"
            continue
        fi
        
        echo -e "${YELLOW}Проверяю существование папки $TARGET_DIR на $TARGET_IP...${NC}"
        if check_remote_dir_exists "$TARGET_USER" "$TARGET_IP" "$TARGET_PASSWORD" "$TARGET_DIR"; then
            echo -e "${GREEN}✓ Папка существует: $TARGET_DIR${NC}"
            break
        else
            echo -e "${YELLOW}⚠ Папка не существует: $TARGET_DIR${NC}"
            CREATE_DIR=$(read_from_terminal "Создать эту папку? (да/нет):")
            if [[ "$CREATE_DIR" == "да" || "$CREATE_DIR" == "y" || "$CREATE_DIR" == "д" ]]; then
                if create_remote_dir "$TARGET_USER" "$TARGET_IP" "$TARGET_PASSWORD" "$TARGET_DIR"; then
                    break
                else
                    echo -e "${RED}✗ Не удалось создать папку${NC}"
                    RETRY=$(read_from_terminal "Попробовать другой путь? (да/нет):")
                    if [[ "$RETRY" != "да" && "$RETRY" != "y" && "$RETRY" != "д" ]]; then
                        echo -e "${YELLOW}Операция отменена пользователем${NC}"
                        exit 0
                    fi
                fi
            else
                RETRY=$(read_from_terminal "Попробовать другой путь? (да/нет):")
                if [[ "$RETRY" != "да" && "$RETRY" != "y" && "$RETRY" != "д" ]]; then
                    echo -e "${YELLOW}Операция отменена пользователем${NC}"
                    exit 0
                fi
            fi
        fi
    done
    echo ""
    
    # --- Шаг 6: Настройки копирования ---
    print_separator
    echo -e "${CYAN}Шаг 6: Настройте параметры копирования${NC}"
    print_separator
    echo ""
    echo -e "${YELLOW}Выберите опции rsync (да — включить, нет — выключить):${NC}"
    echo ""
    
    # Архивный режим
    ANSWER=$(read_from_terminal "Использовать архивный режим (-a)? Сохраняет права, метки, ссылки. (да/нет) [да]:")
    if [[ "$ANSWER" == "нет" || "$ANSWER" == "n" || "$ANSWER" == "н" ]]; then
        USE_ARCHIVE=false
    else
        USE_ARCHIVE=true
    fi
    
    # Подробный вывод
    ANSWER=$(read_from_terminal "Включить подробный вывод (-v)? (да/нет) [да]:")
    if [[ "$ANSWER" == "нет" || "$ANSWER" == "n" || "$ANSWER" == "н" ]]; then
        USE_VERBOSE=false
    else
        USE_VERBOSE=true
    fi
    
    # Сжатие данных
    ANSWER=$(read_from_terminal "Использовать сжатие данных при передаче (-z)? (да/нет) [да]:")
    if [[ "$ANSWER" == "нет" || "$ANSWER" == "n" || "$ANSWER" == "н" ]]; then
        USE_COMPRESS=false
    else
        USE_COMPRESS=true
    fi
    
    # Прогресс
    ANSWER=$(read_from_terminal "Отображать прогресс копирования (--progress)? (да/нет) [да]:")
    if [[ "$ANSWER" == "нет" || "$ANSWER" == "n" || "$ANSWER" == "н" ]]; then
        USE_PROGRESS=false
    else
        USE_PROGRESS=true
    fi
    
    # Ускоренное копирование
    ANSWER=$(read_from_terminal "Использовать ускоренное копирование? (сжатие level=9 + aes128-gcm) (да/нет) [нет]:")
    if [[ "$ANSWER" == "да" || "$ANSWER" == "y" || "$ANSWER" == "д" ]]; then
        USE_FAST=true
    else
        USE_FAST=false
    fi
    
    echo ""
    
    # --- Сборка команды rsync ---
    RSYNC_OPTS=""
    
    if $USE_ARCHIVE; then
        RSYNC_OPTS="$RSYNC_OPTS -a"
    fi
    if $USE_VERBOSE; then
        RSYNC_OPTS="$RSYNC_OPTS -v"
    fi
    if $USE_COMPRESS && ! $USE_FAST; then
        RSYNC_OPTS="$RSYNC_OPTS -z"
    fi
    if $USE_PROGRESS; then
        RSYNC_OPTS="$RSYNC_OPTS --progress"
    fi
    
    # Ускоренное копирование (переопределяет сжатие и добавляет SSH-опции)
    if $USE_FAST; then
        RSYNC_OPTS="$RSYNC_OPTS --compress-level=9"
        SSH_OPTS="ssh -c aes128-gcm@openssh.com"
    else
        SSH_OPTS="ssh"
    fi
    
    # Добавляем слэш в конец исходного пути (копировать содержимое)
    SOURCE_DIR_WITH_SLASH="${SOURCE_DIR%/}/"
    
    # Формирование полной команды
    RSYNC_CMD="rsync$RSYNC_OPTS --partial -e \"$SSH_OPTS\" \"$SOURCE_DIR_WITH_SLASH\" \"$TARGET_USER@$TARGET_IP:$TARGET_DIR/\""
    
    # --- Итоговая информация ---
    print_separator
    echo -e "${CYAN}Итоговая конфигурация:${NC}"
    print_separator
    echo -e "${GREEN}Источник:${NC}      $SOURCE_DIR_WITH_SLASH"
    echo -e "${GREEN}Цель:${NC}          $TARGET_USER@$TARGET_IP:$TARGET_DIR/"
    echo -e "${GREEN}Опции rsync:${NC}   $RSYNC_OPTS --partial"
    echo -e "${GREEN}SSH метод:${NC}     $SSH_OPTS"
    echo ""
    echo -e "${YELLOW}Команда:${NC}"
    echo -e "${CYAN}$RSYNC_CMD${NC}"
    echo ""
    
    CONFIRM=$(read_from_terminal "Начать копирование? (да/нет):")
    if [[ "$CONFIRM" != "да" && "$CONFIRM" != "y" && "$CONFIRM" != "д" ]]; then
        echo -e "${YELLOW}Операция отменена пользователем${NC}"
        exit 0
    fi
    
    # --- Копирование ---
    print_separator
    echo -e "${CYAN}Копирование файлов...${NC}"
    print_separator
    echo ""
    
    START_TIME=$(date +%s)
    
    # Выполняем rsync
    set +e  # Отключаем exit on error для обработки ошибок rsync
    eval sshpass -p "\"$TARGET_PASSWORD\"" $RSYNC_CMD
    RSYNC_EXIT_CODE=$?
    set -e
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    echo ""
    
    # --- Результаты ---
    print_separator
    echo -e "${CYAN}Результаты копирования:${NC}"
    print_separator
    
    if [ $RSYNC_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Копирование завершено успешно!${NC}"
        echo ""
        echo -e "${GREEN}Источник:${NC}  $SOURCE_DIR_WITH_SLASH"
        echo -e "${GREEN}Цель:${NC}      $TARGET_USER@$TARGET_IP:$TARGET_DIR/"
        echo -e "${GREEN}Время:${NC}     ${MINUTES} мин ${SECONDS} сек"
        echo ""
        echo -e "${YELLOW}Проверить результат можно командой:${NC}"
        echo -e "${CYAN}ssh $TARGET_USER@$TARGET_IP \"ls -la '$TARGET_DIR/'\"${NC}"
    else
        echo -e "${RED}✗ Копирование завершилось с ошибкой (код: $RSYNC_EXIT_CODE)${NC}"
        echo ""
        echo -e "${YELLOW}Возможные причины:${NC}"
        echo -e "  - Недостаточно прав на запись"
        echo -e "  - Закончилось место на целевом диске"
        echo -e "  - Обрыв соединения"
        echo ""
        echo -e "${YELLOW}Попробуйте снова — rsync продолжит с места прерывания.${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}  Готово!${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Запуск основной функции
main "$@"
