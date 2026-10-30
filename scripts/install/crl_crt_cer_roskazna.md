# Установка сертификатов Росказны

## Запуск

```bash
mkdir -p "$HOME/scripts" \
  && wget -O "$HOME/scripts/run.sh" https://github.com/teanrus/redos-lifehacks/releases/latest/download/crl_crt_cer_roskazna.sh \
  && chmod +x "$HOME/scripts/run.sh" \
  && "$HOME/scripts/run.sh" \
  && rm "$HOME/scripts/run.sh"
```

## От имени какого пользователя запускать

Скрипт устанавливает сертификаты и CRL в системное хранилище `mca`, то есть не только для одного пользователя: они будут доступны всем пользователям компьютера. Поэтому запустить скрипт нужно из учётной записи, которой разрешён `sudo`. Не запускайте весь скрипт через `sudo bash`: для установки он сам запрашивает повышение прав.
