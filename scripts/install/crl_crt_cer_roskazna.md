# Установка сертификатов Росказны

## 1. Создать директорию для скриптов

```bash
mkdir -p "$HOME/scripts"
cd "$HOME/scripts"
```

## 2. Запуск

```bash
# Вариант 1: Быстрый запуск (curl)
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/crl_crt_cer_roskazna.sh | sudo bash

# Вариант 2: Быстрый запуск (wget)
wget -qO- https://github.com/teanrus/redos-lifehacks/releases/latest/download/crl_crt_cer_roskazna.sh | sudo bash

# Вариант 3: Скачивание с проверкой целостности
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/crl_crt_cer_roskazna.sh -o run.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/crl_crt_cer_roskazna.sh.sha256 -o run.sh.sha256
sha256sum -c install-messengers.sh.sha256
sudo bash install-messengers.sh

wget -O run https://github.com/teanrus/redos-lifehacks/releases/latest/download/crl_crt_cer_roskazna.sh && chmod +x run && ./run && rm run
```

## 3. Выполнить скрипт

```bash
chmod +x "$HOME/scripts/install_crl_crt_cer_roskazna.sh"
"$HOME/scripts/install_crl_crt_cer_roskazna.sh"
```

## От имени какого пользователя запускать

Скрипт устанавливает сертификаты и CRL в системное хранилище `mca`, то есть не только для одного пользователя: они будут доступны всем пользователям компьютера. Поэтому запустить скрипт нужно из учётной записи, которой разрешён `sudo`. Не запускайте весь скрипт через `sudo bash`: для установки он сам запрашивает повышение прав.
