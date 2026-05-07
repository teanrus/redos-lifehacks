# REDOS BACKUP v2.4

[![RED OS](https://img.shields.io/badge/RED%20OS-7.3%20%7C%208.x-b30000?style=for-the-badge)](https://redos.red-soft.ru/)
[![Bash](https://img.shields.io/badge/Bash-script-2b2b2b?style=for-the-badge&logo=gnubash)](https://www.gnu.org/software/bash/)
[![Backup Tool](https://img.shields.io/badge/Backup-tool-c40000?style=for-the-badge)](https://github.com/teanrus/redos-lifehacks)
[![Rsync](https://img.shields.io/badge/Rsync-supported-8b0000?style=for-the-badge)](https://rsync.samba.org/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks?style=for-the-badge&color=aa0000)](https://github.com/teanrus/redos-lifehacks/stargazers)

Утилита резервного копирования пользовательских данных и домашних каталогов для РЕД ОС.

## Возможности

* резервное копирование пользовательских данных через XDG-каталоги
* полный backup домашнего каталога (`HOME`)
* автоматический поиск USB-накопителей
* проверка свободного места перед копированием
* безопасное копирование через `rsync`
* отображение прогресса копирования
* поддержка русских каталогов и путей
* логирование операций
* обработка ошибок и аварийное завершение

---

## Режимы работы

### 1. Только пользовательские данные

Копируются основные пользовательские каталоги:

* Рабочий стол
* Документы
* Загрузки
* Музыка
* Изображения
* Видео

Каталоги определяются автоматически через XDG:

```bash
~/.config/user-dirs.dirs
```

В этом режиме дополнительно исключаются приватные данные:

```text
.ssh
.gnupg
.pki
```

---

### 2. Полный бэкап HOME

Создаётся резервная копия всего домашнего каталога пользователя.

При этом автоматически исключаются временные и ненужные данные:

```text
.cache
.local/share/Trash
.thumbnails
.gvfs
.npm
.cargo
.steam
.var/app
thinclient_drives
```

---

## Используемые технологии

* `bash`
* `rsync`
* `findmnt`
* `du`
* `df`
* `numfmt`

---

## Запуск

```bash
chmod +x redos-backup-v2.4.sh
sudo ./redos-backup-v2.4.sh
```

### Скачивание с проверкой целостности

```bash
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-backup-v2.4.sh -o redos-backup-v2.4.sh
curl -sL https://github.com/teanrus/redos-lifehacks/releases/latest/download/redos-backup-v2.4.sh.sha256 -o redos-backup-v2.4.sh.sha256
sha256sum -c redos-backup-v2.4.sh.sha256
sudo bash redos-backup-v2.4.sh
```

---

## Сценарий работы

1. Выбор пользователя
2. Выбор режима резервного копирования
3. Автоматический поиск USB-накопителей
4. Выбор каталога назначения
5. Проверка свободного места
6. Подтверждение операции
7. Копирование данных
8. Вывод результата и пути к логу

---

## Логирование

Лог работы сохраняется в:

```text
/tmp/redos-backup.log
```

---

## Особенности

## Проверка свободного места

Перед копированием выполняется расчёт размера данных и сравнение со свободным местом на накопителе.

При нехватке места операция отменяется до начала копирования.

---

### Безопасное копирование

Используется:

```bash
rsync -aL
```

что обеспечивает:

* сохранение структуры каталогов
* корректную работу с симлинками
* устойчивость к ошибкам
* возможность восстановления после прерывания

---

## Требования

Необходимые пакеты:

```bash
rsync
coreutils
util-linux
```

---

## Совместимость

* РЕД ОС
* Linux с systemd
* KDE Plasma
* GNOME
* XFCE
