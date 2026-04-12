#!/bin/bash
#
# sound-diagnostics.sh - Диагностика проблем со звуком в РЕД ОС
# Версия: 1.1
# Описание: Интерактивная диагностика и решение проблем со звуком
#

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Символы статуса
CHECK_MARK="✓"
CROSS_MARK="✗"
WARNING_MARK="⚠"

# Переменные для хранения результатов
declare -a ISSUES=()
declare -a RECOMMENDATIONS=()

# Проверка интерактивного режима
INTERACTIVE=false
if [ -t 0 ]; then
    INTERACTIVE=true
fi

#######################################
# Проверка прав root (опционально)
#######################################
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Скрипт запущен от root. Большинство команд не требуют прав root.${NC}"
        echo ""
    fi
}

#######################################
# Функция для запроса подтверждения
#######################################
confirm_action() {
    local message=$1
    local answer
    
    # Если не интерактивный режим, пропускаем вопрос
    if [ "$INTERACTIVE" = false ]; then
        echo -e "${YELLOW}⚠ Неинтерактивный режим: $message (пропущено)${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}$message (y/n)${NC}"
    read -r answer < /dev/tty
    if [[ $answer =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

#######################################
# Функция для проверки успешности
#######################################
check_success() {
    local action=$1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${CHECK_MARK} $action${NC}"
        return 0
    else
        echo -e "${RED}${CROSS_MARK} Ошибка: $action${NC}"
        return 1
    fi
}

#######################################
# Вывод заголовка
#######################################
print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Диагностика проблем со звуком в РЕД ОС${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BLUE}Дата запуска: $(date)${NC}"
    echo ""
}

#######################################
# Вывод раздела
#######################################
print_section() {
    echo ""
    echo -e "${BLUE}[INFO] $1:${NC}"
    echo -e "${BLUE}========================================${NC}"
}

#######################################
# Вывод успешной проверки
#######################################
print_success() {
    echo -e "  ${GREEN}${CHECK_MARK} $1${NC}"
}

#######################################
# Вывод ошибки
#######################################
print_error() {
    echo -e "  ${RED}${CROSS_MARK} $1${NC}"
}

#######################################
# Вывод предупреждения
#######################################
print_warning() {
    echo -e "  ${YELLOW}${WARNING_MARK} $1${NC}"
}

#######################################
# Проверка версии ОС
#######################################
check_os_version() {
    print_section "Информация о системе"
    
    if [ -f /etc/redos-release ]; then
        OS_VERSION=$(cat /etc/redos-release)
        print_success "ОС: $OS_VERSION"
    elif [ -f /etc/os-release ]; then
        OS_VERSION=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        print_success "ОС: $OS_VERSION"
    else
        print_warning "Не удалось определить версию ОС"
        ISSUES+=("Не удалось определить версию ОС")
    fi
    
    KERNEL_VERSION=$(uname -r)
    print_success "Ядро: $KERNEL_VERSION"
    
    ARCH=$(uname -m)
    print_success "Архитектура: $ARCH"
}

#######################################
# Проверка звуковой карты
#######################################
check_sound_card() {
    print_section "Звуковая карта"
    
    if command -v lspci &> /dev/null; then
        AUDIO_DEVICES=$(lspci | grep -i audio)
        if [ -n "$AUDIO_DEVICES" ]; then
            echo "$AUDIO_DEVICES" | while read -r line; do
                print_success "$line"
            done
        else
            print_warning "PCI аудиоустройства не найдены"
            ISSUES+=("PCI аудиоустройства не найдены")
        fi
    else
        print_warning "lspci не установлен"
    fi
    
    if command -v lsusb &> /dev/null; then
        USB_AUDIO=$(lsusb | grep -i audio)
        if [ -n "$USB_AUDIO" ]; then
            echo "$USB_AUDIO" | while read -r line; do
                print_success "USB: $line"
            done
        fi
    fi
}

#######################################
# Проверка устройств воспроизведения
#######################################
check_playback_devices() {
    print_section "Устройства воспроизведения"
    
    if command -v aplay &> /dev/null; then
        APLAY_OUTPUT=$(aplay -l 2>&1)
        if echo "$APLAY_OUTPUT" | grep -q "card"; then
            echo "$APLAY_OUTPUT" | grep "^card" | while read -r line; do
                print_success "$line"
            done
        else
            print_error "Устройства воспроизведения не найдены"
            ISSUES+=("Устройства воспроизведения не найдены")
            RECOMMENDATIONS+=("Проверьте подключение аудиоустройств")
        fi
    else
        print_warning "aplay не установлен (установите alsa-utils)"
    fi
}

#######################################
# Проверка устройств записи
#######################################
check_capture_devices() {
    print_section "Устройства записи"
    
    if command -v arecord &> /dev/null; then
        ARECORD_OUTPUT=$(arecord -l 2>&1)
        if echo "$ARECORD_OUTPUT" | grep -q "card"; then
            echo "$ARECORD_OUTPUT" | grep "^card" | while read -r line; do
                print_success "$line"
            done
        else
            print_warning "Устройства записи не найдены"
        fi
    else
        print_warning "arecord не установлен (установите alsa-utils)"
    fi
}

#######################################
# Проверка PulseAudio/PipeWire
#######################################
check_sound_server() {
    print_section "Проверка PulseAudio/PipeWire"
    
    PULSE_RUNNING=false
    PIPEWIRE_RUNNING=false
    
    # Проверка PulseAudio
    if command -v pactl &> /dev/null; then
        if pactl info 2>/dev/null | grep -q "PulseAudio"; then
            PULSE_RUNNING=true
            print_success "PulseAudio: running"
            
            # Количество модулей
            MODULE_COUNT=$(pactl list short modules | wc -l)
            print_success "Модули: $MODULE_COUNT загружено"
        fi
    fi
    
    # Проверка PipeWire
    if command -v systemctl &> /dev/null; then
        if systemctl --user is-active --quiet pipewire 2>/dev/null; then
            PIPEWIRE_RUNNING=true
            print_success "PipeWire: running"
        elif systemctl --user is-enabled pipewire 2>/dev/null | grep -q "enabled"; then
            print_warning "PipeWire: enabled but not running"
        else
            if command -v pipewire &> /dev/null; then
                print_warning "PipeWire: установлен, но не запущен"
            else
                print_warning "PipeWire: not installed"
            fi
        fi
    fi
    
    if [ "$PULSE_RUNNING" = false ] && [ "$PIPEWIRE_RUNNING" = false ]; then
        print_error "Звуковой сервер не запущен"
        ISSUES+=("Звуковой сервер не запущен")
        RECOMMENDATIONS+=("Запустите PulseAudio: systemctl --user start pulseaudio")
    fi
}

#######################################
# Проверка уровней громкости
#######################################
check_volume_levels() {
    print_section "Проверка уровней громкости"
    
    if command -v amixer &> /dev/null; then
        # Проверка Master
        MASTER_STATUS=$(amixer sget Master 2>/dev/null | tail -1)
        if [ -n "$MASTER_STATUS" ]; then
            if echo "$MASTER_STATUS" | grep -qi "\[off\]"; then
                print_error "Master: MUTE"
                ISSUES+=("Master заглушен")
                RECOMMENDATIONS+=("Включите Master: amixer sset Master unmute")
            else
                VOLUME=$(echo "$MASTER_STATUS" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]')
                if [ -n "$VOLUME" ]; then
                    print_success "Master: $VOLUME"
                else
                    print_warning "Master: статус неизвестен"
                fi
            fi
        else
            print_warning "Не удалось получить статус Master"
        fi
        
        # Проверка Speaker
        SPEAKER_STATUS=$(amixer sget Speaker 2>/dev/null | tail -1)
        if [ -n "$SPEAKER_STATUS" ]; then
            if echo "$SPEAKER_STATUS" | grep -qi "\[off\]"; then
                print_error "Speaker: MUTE"
                ISSUES+=("Speaker заглушен")
                RECOMMENDATIONS+=("Включите Speaker: amixer sset Speaker unmute")
            else
                VOLUME=$(echo "$SPEAKER_STATUS" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]')
                if [ -n "$VOLUME" ]; then
                    print_success "Speaker: $VOLUME"
                fi
            fi
        fi
        
        # Проверка PCM
        PCM_STATUS=$(amixer sget PCM 2>/dev/null | tail -1)
        if [ -n "$PCM_STATUS" ]; then
            if echo "$PCM_STATUS" | grep -qi "\[off\]"; then
                print_warning "PCM: MUTE"
            else
                VOLUME=$(echo "$PCM_STATUS" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]')
                if [ -n "$VOLUME" ]; then
                    print_success "PCM: $VOLUME"
                fi
            fi
        fi
        
        # Проверка Capture (микрофон)
        CAPTURE_STATUS=$(amixer sget Capture 2>/dev/null | tail -1)
        if [ -n "$CAPTURE_STATUS" ]; then
            if echo "$CAPTURE_STATUS" | grep -qi "\[off\]"; then
                print_warning "Capture (микрофон): MUTE"
            else
                VOLUME=$(echo "$CAPTURE_STATUS" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]')
                if [ -n "$VOLUME" ]; then
                    print_success "Capture (микрофон): $VOLUME"
                fi
            fi
        fi
    else
        print_warning "amixer не установлен (установите alsa-utils)"
    fi
}

#######################################
# Проверка устройств PulseAudio
#######################################
check_pactl_sinks() {
    print_section "Устройства PulseAudio"
    
    if command -v pactl &> /dev/null; then
        SINK_COUNT=$(pactl list short sinks 2>/dev/null | wc -l)
        if [ "$SINK_COUNT" -gt 0 ]; then
            print_success "Найдено устройств вывода: $SINK_COUNT"
            pactl list short sinks 2>/dev/null | while read -r line; do
                echo "    $line"
            done
        else
            print_warning "Устройства вывода не найдены"
            ISSUES+=("Устройства вывода PulseAudio не найдены")
        fi
        
        SOURCE_COUNT=$(pactl list short sources 2>/dev/null | wc -l)
        if [ "$SOURCE_COUNT" -gt 0 ]; then
            print_success "Найдено устройств ввода: $SOURCE_COUNT"
        else
            print_warning "Устройства ввода не найдены"
        fi
    fi
}

#######################################
# Интерактивное включение звука
#######################################
interactive_unmute() {
    if [ ${#ISSUES[@]} -eq 0 ]; then
        return
    fi

    echo ""
    echo -e "${YELLOW}Обнаружены проблемы:${NC}"
    for i in "${!ISSUES[@]}"; do
        echo "  $((i+1)). ${ISSUES[$i]}"
    done

    # Если неинтерактивный режим, выводим рекомендации
    if [ "$INTERACTIVE" = false ]; then
        echo ""
        echo -e "${YELLOW}⚠ Неинтерактивный режим: автоматическое исправление пропущено${NC}"
        echo -e "${CYAN}Рекомендации:${NC}"
        for issue in "${ISSUES[@]}"; do
            if [[ "$issue" == *"Master заглушен"* ]]; then
                echo "  • Включите Master: amixer sset Master unmute && amixer sset Master 80%"
            fi
            if [[ "$issue" == *"Speaker заглушен"* ]]; then
                echo "  • Включите Speaker: amixer sset Speaker unmute"
            fi
        done
        return
    fi

    # Предложение включить Master
    for issue in "${ISSUES[@]}"; do
        if [[ "$issue" == *"Master заглушен"* ]]; then
            echo ""
            if confirm_action "Включить Master"; then
                echo -e "${BLUE}[INFO] Включение Master...${NC}"
                amixer sset Master unmute &>/dev/null
                amixer sset Master 80% &>/dev/null
                print_success "Master включён (80%)"
            fi
        fi

        if [[ "$issue" == *"Speaker заглушен"* ]]; then
            echo ""
            if confirm_action "Включить Speaker"; then
                echo -e "${BLUE}[INFO] Включение Speaker...${NC}"
                amixer sset Speaker unmute &>/dev/null
                print_success "Speaker включён"
            fi
        fi
    done
}

#######################################
# Интерактивный перезапуск PulseAudio
#######################################
interactive_restart() {
    # Если неинтерактивный режим, пропускаем перезапуск
    if [ "$INTERACTIVE" = false ]; then
        echo ""
        echo -e "${YELLOW}⚠ Неинтерактивный режим: перезапуск звуковой подсистемы пропущен${NC}"
        echo -e "${CYAN}Для перезапуска выполните:${NC}"
        echo "  systemctl --user restart pulseaudio"
        echo "  # или для PipeWire:"
        echo "  systemctl --user restart pipewire wireplumber"
        return
    fi

    if confirm_action "Перезапустить PulseAudio для применения настроек"; then
        echo -e "${BLUE}[INFO] Перезапуск PulseAudio...${NC}"

        if command -v systemctl &> /dev/null; then
            if systemctl --user is-active --quiet pulseaudio 2>/dev/null; then
                systemctl --user restart pulseaudio 2>/dev/null && \
                    print_success "PulseAudio перезапущен" || \
                    print_warning "Не удалось перезапустить PulseAudio"
            elif systemctl --user is-active --quiet pipewire 2>/dev/null; then
                systemctl --user restart pipewire 2>/dev/null && \
                    print_success "PipeWire перезапущен" || \
                    print_warning "Не удалось перезапустить PipeWire"
                systemctl --user restart wireplumber 2>/dev/null
            else
                print_warning "Звуковой сервер не запущен"
            fi
        else
            pulseaudio -k 2>/dev/null
            pulseaudio --start 2>/dev/null
            print_success "PulseAudio перезапущен"
        fi
    fi
}

#######################################
# Вывод итогов диагностики
#######################################
print_summary() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Результаты диагностики:${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Статус звуковых устройств
    if command -v aplay &> /dev/null && aplay -l 2>/dev/null | grep -q "card"; then
        print_success "Звуковые устройства: OK"
    else
        print_error "Звуковые устройства: Требуется внимание"
    fi
    
    # Статус звукового сервера
    if command -v pactl &> /dev/null && pactl info 2>/dev/null | grep -q "PulseAudio"; then
        print_success "PulseAudio: OK"
    elif command -v systemctl &> /dev/null && systemctl --user is-active --quiet pipewire 2>/dev/null; then
        print_success "PipeWire: OK"
    else
        print_error "Звуковой сервер: Требуется внимание"
    fi
    
    # Статус уровней громкости
    if [ ${#ISSUES[@]} -eq 0 ]; then
        print_success "Уровни громкости: OK"
    else
        print_warning "Уровни громкости: Требуется настройка"
    fi
    
    # Рекомендации
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Рекомендации:${NC}"
        for i in "${!RECOMMENDATIONS[@]}"; do
            echo "  $((i+1)). ${RECOMMENDATIONS[$i]}"
        done
    fi
    
    echo ""
    echo -e "${CYAN}Полезные команды:${NC}"
    echo "  pavucontrol              # панель управления звуком"
    echo "  alsamixer                # консольный микшер"
    echo "  pulseaudio-equalizer-gtk # эквалайзер"
    echo "  speaker-test -c 2 -t wav # тест динамиков"
    
    echo ""
    echo -e "${GREEN}[INFO] Готово!${NC}"
}

#######################################
# Тест звука
#######################################
test_sound() {
    echo ""
    
    # Если неинтерактивный режим, пропускаем тест
    if [ "$INTERACTIVE" = false ]; then
        echo -e "${YELLOW}⚠ Неинтерактивный режим: тест звука пропущен${NC}"
        echo -e "${CYAN}Для теста выполните:${NC}"
        echo "  speaker-test -c 2 -t wav"
        return
    fi
    
    if confirm_action "Выполнить тест динамиков"; then
        echo -e "${BLUE}[INFO] Запуск теста стерео...${NC}"
        if command -v speaker-test &> /dev/null; then
            speaker-test -c 2 -t wav -D default
        else
            print_warning "speaker-test не установлен"
        fi
    fi
}

#######################################
# Основная функция
#######################################
main() {
    check_root
    print_header
    
    check_os_version
    check_sound_card
    check_playback_devices
    check_capture_devices
    check_sound_server
    check_volume_levels
    check_pactl_sinks
    
    interactive_unmute
    interactive_restart
    
    print_summary
    test_sound
}

# Запуск основной функции
main
