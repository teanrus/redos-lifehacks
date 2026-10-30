#!/usr/bin/env bash
set -Eeuo pipefail

readonly source_url="http://crl.roskazna.ru/crl/"
readonly certmgr="/opt/cprocsp/bin/amd64/certmgr"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/roskazna-certs.XXXXXX")"
readonly work_dir
download_dir="$work_dir/download"
readonly download_dir

cleanup() {
    rm -rf -- "$work_dir"
}

report_error() {
    local status=$?
    printf 'Ошибка в строке %s при выполнении: %s\n' \
        "${BASH_LINENO[0]}" "${BASH_COMMAND}" >&2
    exit "$status"
}

trap cleanup EXIT
trap report_error ERR

command -v wget >/dev/null || {
    printf 'Не найдена команда wget.\n' >&2
    exit 1
}
command -v sudo >/dev/null || {
    printf 'Не найдена команда sudo.\n' >&2
    exit 1
}
[[ -x "$certmgr" ]] || {
    printf 'Не найден исполняемый certmgr: %s\n' "$certmgr" >&2
    exit 1
}

sudo -v
mkdir -p "$download_dir"
printf 'Скачиваю сертификаты с сайта Росказны. Это может занять некоторое время.\n'
wget --recursive --level=1 --no-parent --no-directories \
    --accept=crl,crt,cer \
    --directory-prefix="$download_dir" "$source_url"

shopt -s nullglob
crl_files=("$download_dir"/*.crl)
crt_files=("$download_dir"/*.crt)
cer_files=("$download_dir"/*.cer)

if ((${#crl_files[@]} + ${#crt_files[@]} + ${#cer_files[@]} == 0)); then
    printf 'Не найдено ни одного файла .crl, .crt или .cer.\n' >&2
    exit 1
fi

for file in "${crl_files[@]}"; do
    sudo "$certmgr" -inst -crl -store mca -file "$file" >/dev/null
done

for file in "${crt_files[@]}" "${cer_files[@]}"; do
    sudo "$certmgr" -inst -certificate -store mca -file "$file" >/dev/null
done

printf 'Установка завершена: команды certmgr завершились без ошибок.\n'