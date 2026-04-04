# 💳 Смарт-карты и RFID в РЕД ОС

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%207.x-orange.svg)](https://redos.red-soft.ru/)
[![Platform](https://img.shields.io/badge/platform-RED%20OS%208.x-green.svg)](https://redos.red-soft.ru/)
[![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

Руководство по работе со смарт-картами и RFID-устройствами в РЕД ОС. PC/SC Lite, Рутокен, JaCarta, eToken, аутентификация через PAM, электронная подпись, алгоритмы ГОСТ, интеграция с КриптоПро, управление сертификатами.

---

## 📋 Оглавление

1. [Архитектура работы со смарт-картами](#архитектура-работы-со-смарт-картами)
2. [Установка PC/SC Lite](#установка-pcsc-lite)
3. [Считыватели смарт-карт](#считыватели-смарт-карт)
4. [Рутокен](#рутокен)
5. [JaCarta](#jacarta)
6. [eToken](#etoken)
7. [PAM-аутентификация](#pam-аутентификация)
8. [Электронная подпись](#электронная-подпись)
9. [Алгоритмы ГОСТ](#алгоритмы-гост)
10. [Интеграция с КриптоПро](#интеграция-с-криптопро)
11. [Настройка браузеров для ЭП](#настройка-браузеров-для-эп)
12. [Управление сертификатами](#управление-сертификатами)
13. [Диагностика и устранение проблем](#диагностика-и-устранение-проблем)
14. [Справочник команд](#справочник-команд)
15. [Требования и совместимость](#требования-и-совместимость)

---

## Архитектура работы со смарт-картами

### Стек PC/SC

```
┌──────────────────────────────────────────────────────┐
│           Приложение (браузер, КриптоПро)             │
└──────────────────┬───────────────────────────────────┘
                   │ PKCS#11 / Cryptoki
                   ▼
┌──────────────────────────────────────────────────────┐
│        Библиотека токена (pkcs11.so)                 │
│  rutoken-pkcs11 │ jcPkcs11 │ eTPKCS11               │
└──────────────────┬───────────────────────────────────┘
                   │ PC/SC API
                   ▼
┌──────────────────────────────────────────────────────┐
│          PC/SC Lite (pcscd)                          │
│  Демон-посредник между приложением и считывателем     │
└──────────────────┬───────────────────────────────────┘
                   │ libusb
                   ▼
┌──────────────────────────────────────────────────────┐
│          CCID-драйвер считывателя                     │
│  Поддержка USB-считывателей (ACS, Gemalto и др.)     │
└──────────────────┬───────────────────────────────────┘
                   │ USB
                   ▼
┌──────────────────────────────────────────────────────┐
│          Считыватель смарт-карт                       │
│  ACS ACR122U │ Gemalto │ Рутокен ЭЦП                 │
└──────────────────────────────────────────────────────┘
```

### Основные компоненты

| Компонент | Пакет | Назначение |
|-----------|-------|------------|
| **PC/SC Lite** | `pcsc-lite` | Демон pcscd, PC/SC API |
| **CCID** | `pcsc-lite-ccid` | Драйвер USB-считывателей |
| **OpenSC** | `opensc` | Утилиты для смарт-карт |
| **PKCS#11** | `p11-kit` | Управление PKCS#11 модулями |
| **GnuPG** | `gnupg`, `gnupg2-pkcs11` | Работа с ключами |
| **pcsc-tools** | `pcsc-tools` | Утилита pcsc_scan |

---

## Установка PC/SC Lite

### Базовая установка

```bash
# Установка PC/SC Lite
sudo dnf install -y pcsc-lite pcsc-lite-ccid pcsc-tools

# Установка OpenSC
sudo dnf install -y opensc opensc-proxy

# Установка p11-kit
sudo dnf install -y p11-kit p11-kit-trust p11-kit-server

# Включение службы
sudo systemctl enable pcscd
sudo systemctl start pcscd

# Проверка статуса
systemctl status pcscd
```

### Проверка обнаружения

```bash
# Проверка считывателя
pcsc_scan

# Пример вывода:
# PC/SC device scanner
# Detected 1 reader(s)
#  0: ACS ACR122U PIC-C Interface 00 00
#
# Waiting for the first reader... found one
#
# Reader 0: ACS ACR122U PIC-C Interface 00 00
#   Card state: Card inserted,
#   ATR: 3B 9C 96 00 52 75 74 6F 6B 65 6E 43 53
#   ATR Text: Rutoken ECP
```

### Альтернативная проверка

```bash
# Через OpenSC
opensc-tool -l

# Пример вывода:
# No.  Reader  Name
# 0    0       ACS ACR122U PIC-C Interface 00 00
#      3B 9C 96 00 52 75 74 6F 6B 65 6E 43 53

# Подробная информация о карте
opensc-tool -a
opensc-tool -n
opensc-tool -i
```

---

## Считыватели смарт-карт

### Поддерживаемые считыватели

| Считыватель | Тип | CCID | Примечание |
|-------------|-----|------|------------|
| **ACS ACR122U** | USB, NFC | ✅ | RFID/NFC, самый популярный |
| **ACS ACR38U** | USB | ✅ | Контактный |
| **ACS ACR1252U** | USB, NFC | ✅ | Новее ACR122U |
| **Gemalto IDBridge CT30** | USB | ✅ | Контактный |
| **Gemalto IDBridge K30** | USB, NFC | ✅ | Комбинированный |
| **Рутокен Lite** | USB | ✅ | Встроенный считыватель |
| **Рутокен ЭЦП** | USB | ✅ | Встроенный считыватель |
| **ZCS Zeliop'S** | USB | ✅ | Контактный |
| **HID Omnikey 5321** | USB | ✅ | Контактный |
| **HID Omnikey 5427** | USB, NFC | ✅ | Комбинированный |

### Настройка считывателя ACS ACR122U

```bash
# Проверка обнаружения
lsusb | grep -i acs
# Bus 001 Device 004: ID 072f:2200 Advanced Card Systems, Ltd ACR122U

# Проверка через pcscd
sudo systemctl status pcscd
pcsc_scan

# Если считыватель не определяется:
# 1. Проверить blacklist
cat /etc/modprobe.d/blacklist.conf | grep nfc

# 2. Отключить конфликтующий модуль
echo "blacklist pn533" | sudo tee -a /etc/modprobe.d/blacklist-pn533.conf
echo "blacklist nfc" | sudo tee -a /etc/modprobe.d/blacklist-nfc.conf

# 3. Перезагрузить
sudo rmmod pn533 2>/dev/null || true
sudo rmmod nfc 2>/dev/null || true
sudo systemctl restart pcscd
```

---

## Рутокен

### Линейка Рутокен

| Устройство | Тип | ГОСТ | PKCS#11 | Примечание |
|------------|-----|------|---------|------------|
| **Рутокен Lite** | Токен | ❌ | ✅ | Хранение сертификатов |
| **Рутокен ЭЦП 2.0** | Токен | ✅ | ✅ | ГОСТ-алгоритмы |
| **Рутокен ЭЦП 3.0** | Токен | ✅ | ✅ | Новое поколение |
| **Рутокен S** | Токен | ❌ | ✅ | Базовый |
| **Рутокен PINPad** | Токен | ✅ | ✅ | С клавиатурой |
| **Рутокен 2.0 Micro** | Токен | ✅ | ✅ | Форм-фактор microSD |
| **Рутокен WEB** | Плагин | ✅ | ✅ | Для браузеров |

### Установка драйверов Рутокен

```bash
# Установка из репозитория (если доступен)
sudo dnf install -y librutoken rutoken-drivers

# Или установка с официального сайта
# https://www.rutoken.ru/download/drivers/

# Распаковка
tar -xzf rutoken-drivers-linux-*.tar.gz
cd rutoken-drivers-linux-*/

# Установка
sudo ./install.sh

# Установка PKCS#11 библиотеки
sudo dnf install -y libpkcs11

# Проверка
pcsc_scan
```

### Работа с Рутокен

```bash
# Проверка токена
pcsc_scan

# Открыть утилиту управления
rutoken-mgr

# Через pkcs11-tool (из opensc)
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so --list-slots

# Информация о токене
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so --show-info

# Список объектов на токене
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so --list-objects

# Инициализация токена (ВНИМАНИЕ: стирает все данные!)
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so \
    --init-token \
    --label "My Rutoken" \
    --so-pin 87654321

# Изменение PIN-кода
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so \
    --login --pin 12345678 \
    --change-pin \
    --new-pin 87654321
```

### Таблица совместимости Рутокен

| Модель | РЕД ОС 7.3 | РЕД ОС 8.0 | PC/SC | PKCS#11 | ГОСТ |
|--------|-----------|-----------|-------|---------|------|
| Рутокен Lite | ✅ | ✅ | ✅ | ✅ | ❌ |
| Рутокен ЭЦП 2.0 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Рутокен ЭЦП 3.0 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Рутокен S | ✅ | ✅ | ✅ | ✅ | ❌ |
| Рутокен PINPad | ✅ | ✅ | ✅ | ✅ | ✅ |
| Рутокен 2.0 Micro | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## JaCarta

### Линейка JaCarta

| Устройство | Тип | ГОСТ | Примечание |
|------------|-----|------|------------|
| **JaCarta LT** | Токен | ❌ | Хранение сертификатов |
| **JaCarta PKI/ГОСТ** | Токен | ✅ | ГОСТ-алгоритмы |
| **JaCarta-2 PKI/ГОСТ** | Токен | ✅ | Новое поколение |
| **JaCarta MICRO** | Токен | ✅ | Компактный |
| **JaCarta RFID** | Бесконтактная | ✅ | RFID-форм-фактор |

### Установка драйверов JaCarta

```bash
# Скачивание с https://www.aladdin-rd.ru/support/jacarta/download/

# Установка RPM
sudo dnf install -y jcPKCS11-*.rpm
sudo dnf install -y jc-client-*.rpm

# Или установка из архива
tar -xzf jacarta-linux-*.tar.gz
cd jacarta-linux-*/
sudo ./install.sh

# Проверка
pcsc_scan

# Через PKCS#11
pkcs11-tool --module /usr/lib/libjcPKCS11.so --list-slots
```

### Работа с JaCarta

```bash
# Утилита управления JaCarta
jc-panel

# Список токенов
jc-client list

# Информация о токене
pkcs11-tool --module /usr/lib/libjcPKCS11.so --show-info

# Список объектов
pkcs11-tool --module /usr/lib/libjcPKCS11.so --list-objects

# Инициализация
pkcs11-tool --module /usr/lib/libjcPKCS11.so \
    --init-token \
    --label "My JaCarta" \
    --so-pin 87654321
```

---

## eToken

### Линейка eToken

| Устройство | Тип | ГОСТ | Примечание |
|------------|-----|------|------------|
| **eToken 5110** | Токен | ❌ | SafeNet (Thales) |
| **eToken 5110 CC** | Токен | ❌ | Common Criteria |
| **eToken 5300** | Токен | ❌ | С кнопкой |
| **eToken 7200** | Токен | ❌ | NFC |

### Установка драйверов eToken

```bash
# Safenet Authentication Client (SAC)
# Скачивание с https://cpl.thalesgroup.com/

# Установка
sudo dnf install -y SAC-*.rpm

# Проверка
pcsc_scan

# Через PKCS#11
pkcs11-tool --module /usr/lib/libeTPkcs11.so --list-slots
```

### Работа с eToken

```bash
# Утилита управления
/usr/bin/SAC

# Проверка через pkcs11-tool
pkcs11-tool --module /usr/lib/libeTPkcs11.so --list-objects

# Инициализация
pkcs11-tool --module /usr/lib/libeTPkcs11.so \
    --init-token \
    --label "My eToken" \
    --so-pin 87654321
```

---

## PAM-аутентификация

### Вход в систему по смарт-карте

```bash
# Установка PAM-модуля PKCS#11
sudo dnf install -y pam_pkcs11

# Или pam-pkcs11 из репозитория
sudo dnf install -y pam-pkcs11
```

### Настройка pam_pkcs11

```bash
# Создание конфигурации
sudo mkdir -p /etc/pam_pkcs11
sudo mkdir -p /etc/pam_pkcs11/certs

# Создание конфигурационного файла
sudo nano /etc/pam_pkcs11/pam_pkcs11.conf
```

```conf
pam_pkcs11 {
    # Используемый PKCS#11 модуль
    use_pkcs11_module = rutoken;

    # PKCS#11 модуль Рутокен
    pkcs11_module rutoken {
        module = /usr/lib/librtpkcs11ecp.so;
        description = "Rutoken PKCS#11";
        slot_num = 0;
        ca_dir = /etc/pam_pkcs11/certs;
        crl_dir = /etc/pam_pkcs11/crl;
        cert_policy = signature;
    }

    # Маппинг пользователей
    use_mappers = cn, null;

    mapper_search = file;

    # Маппер по CN
    mapper cn {
        debug = false;
        module = internal;
        ignorecase = true;
        search = cn;
    }

    # Маппер по умолчанию
    mapper null {
        debug = false;
        module = null;
    }
}
```

### Настройка PAM

```bash
# Добавление в PAM-конфигурацию
sudo nano /etc/pam.d/system-auth
```

```conf
# Добавить в начало (перед pam_unix.so):
auth    sufficient    pam_pkcs11.so    quiet
account sufficient    pam_pkcs11.so
```

```bash
# Для GNOME Display Manager
sudo nano /etc/pam.d/gdm-password
# Добавить:
auth    sufficient    pam_pkcs11.so    quiet
```

### Создание маппинга пользователей

```bash
# Создать файл маппинга
sudo nano /etc/pam_pkcs11/user_map

# Формат: сертификат → пользователь
# CN=Иванов Иван Иванович,O=Organization,C=RU ivanov

# Или использование pkcs11_make_link
pkcs11_make_link /etc/pam_pkcs11/user_map
```

### Настройка для lightdm / sddm

```bash
# Для lightdm
sudo nano /etc/pam.d/lightdm
# Добавить:
auth    sufficient    pam_pkcs11.so    quiet

# Для sddm
sudo nano /etc/pam.d/sddm
# Добавить:
auth    sufficient    pam_pkcs11.so    quiet
```

---

## Электронная подпись

### Стандарты ЭП

| Стандарт | Описание | Применение |
|----------|----------|------------|
| **CMS/PKCS#7** | Cryptographic Message Syntax | Стандартная ЭП |
| **GOST R 34.10-2012** | ГОСТ-подпись | Российские стандарты |
| **GOST R 34.10-2001** | Старый ГОСТ | Устаревший, но используется |
| **XAdES** | XML Advanced Electronic Signatures | Документооборот |
| **PAdES** | PDF Advanced Electronic Signatures | Подпись PDF |
| **CAdES** | CMS Advanced Electronic Signatures | Усиленная подпись |

### Создание подписи через OpenSSL

```bash
# Подпись файла (стандартная)
openssl cms -sign \
    -in document.pdf \
    -signer cert.pem \
    -inkey private.key \
    -out document.pdf.sig \
    -outform DER

# Верификация
openssl cms -verify \
    -in document.pdf.sig \
    -CAfile ca-cert.pem \
    -content document.pdf

# Отсоединённая подпись
openssl cms -sign \
    -in document.txt \
    -signer cert.pem \
    -inkey private.key \
    -out document.txt.sig \
    -outform DER \
    -nodetach
```

### Подпись через PKCS#11

```bash
# Подпись с использованием токена
openssl cms -sign \
    -in document.pdf \
    -signer cert.pem \
    -keyform engine \
    -engine pkcs11 \
    -inkey "pkcs11:token=Rutoken%20ECP;id=01" \
    -out document.pdf.sig \
    -outform DER
```

---

## Алгоритмы ГОСТ

### Поддерживаемые алгоритмы

| Алгоритм | Назначение | Стандарт |
|----------|-----------|----------|
| **ГОСТ Р 34.10-2012** | Электронная подпись | 256/512 бит |
| **ГОСТ Р 34.10-2001** | Электронная подпись | Устаревший |
| **ГОСТ Р 34.11-2012** | Хеш-функция | 256/512 бит (Стрибог) |
| **ГОСТ Р 34.11-94** | Хеш-функция | Устаревший |
| **ГОСТ 28147-89** | Симметричное шифрование | 256 бит |
| **ГОСТ Р 34.12-2015 (Кузнечик)** | Симметричное шифрование | 256 бит |
| **ГОСТ Р 34.13-2015** | Режимы шифрования | CMAC, CTR, OMAC |

### OpenSSL с поддержкой ГОСТ

```bash
# Установка OpenSSL с ГОСТ
sudo dnf install -y openssl openssl-engine

# Проверка ГОСТ-движка
openssl engine -t gost

# Настройка openssl.cnf
sudo nano /etc/pki/tls/openssl.cnf
```

Добавить в `openssl.cnf`:

```ini
[openssl_init]
engines = engine_section

[engine_section]
gost = gost_section

[gost_section]
engine_id = gost
default_algorithms = ALL
CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet
```

### Генерация ГОСТ-ключей

```bash
# Генерация ключевой пары ГОСТ
openssl genpkey -algorithm GOST2012_256 \
    -pkeyopt paramset:A \
    -out gost_private.key

# Извлечение публичного ключа
openssl pkey -in gost_private.key \
    -pubout \
    -out gost_public.key

# Создание CSR (Certificate Signing Request)
openssl req -new \
    -key gost_private.key \
    -out gost_request.csr \
    -subj "/C=RU/O=Organization/CN=User Name"
```

---

## Интеграция с КриптоПро

### Установка КриптоПро CSP

```bash
# Скачивание с https://www.cryptopro.ru/products/csp/downloads

# Распаковка
tar -xzf linux-amd64_deb.tgz  # или rpm
cd linux-amd64/

# Установка
sudo ./install.sh

# Или ручная установка RPM
sudo dnf install -y lsb-cprocsp-base-*.rpm
sudo dnf install -y lsb-cprocsp-rdr-*.rpm
sudo dnf install -y lsb-cprocsp-kc1-*.rpm
sudo dnf install -y lsb-cprocsp-capilite-*.rpm

# Проверка установки
/opt/cprocsp/bin/amd64/cpconfig -license -view

# Ввод лицензии
sudo /opt/cprocsp/bin/amd64/cpconfig -license -set XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
```

### Настройка Рутокен с КриптоПро

```bash
# Установка поддержки Рутокен
sudo dnf install -y lsb-cprocsp-rutoken-*.rpm

# Проверка видимости токена
/opt/cprocsp/bin/amd64/cpconfig -hardware reader -view

# Проверка контейнеров
/opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -verifycontext -fqcn

# Просмотр контейнеров на токене
/opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -verifycontext
```

### Создание ключевой пары на токене

```bash
# Создание контейнера на Рутокен
/opt/cprocsp/bin/amd64/csptest -keyset \
    -newkeyset \
    -container '\\.\Aktiv Rutoken ECP 00 00\MY_CONTAINER' \
    -provtype 80 \
    -provname 'Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP'

# Создание запроса на сертификат
/opt/cprocsp/bin/amd64/certmgr \
    -inst -store uMy \
    -file cert.cer \
    -cont '\\.\Aktiv Rutoken ECP 00 00\MY_CONTAINER'
```

### Установка сертификата

```bash
# Установка сертификата из файла
/opt/cprocsp/bin/amd64/certmgr -inst \
    -file my_cert.cer \
    -store uMy

# Установка из контейнера токена
/opt/cprocsp/bin/amd64/certmgr -inst \
    -cont '\\.\Aktiv Rutoken ECP 00 00\MY_CONTAINER' \
    -store uMy

# Список сертификатов
/opt/cprocsp/bin/amd64/certmgr -list

# Удаление сертификата
/opt/cprocsp/bin/amd64/certmgr -del \
    -cert <serial_number>
```

### Подписание документов

```bash
# Подписание файла
/opt/cprocsp/bin/amd64/cryptcp -sign \
    -dn 'CN=User Name' \
    -der \
    document.pdf \
    document.pdf.sig

# Проверка подписи
/opt/cprocsp/bin/amd64/cryptcp -verify \
    document.pdf.sig

# Подписание с присоединённой подписью
/opt/cprocsp/bin/amd64/cryptcp -sign \
    -dn 'CN=User Name' \
    -detached \
    document.pdf \
    document.pdf.sig

# Шифрование
/opt/cprocsp/bin/amd64/cryptcp -encr \
    -dn 'CN=Recipient' \
    document.pdf \
    document.pdf.encrypted
```

---

## Настройка браузеров для ЭП

### Настройка Firefox

```bash
# Открыть: Настройки → Приватность и защита → Устройства безопасности

# Добавить PKCS#11 модуль:
# 1. Загрузить
# 2. Имя модуля: Rutoken PKCS#11
# 3. Файл модуля: /usr/lib/librtpkcs11ecp.so

# Через about:config
# security.mixed_content.block_active_content → false
```

```bash
# Через командную строку (автоматическая настройка)
# Создать autoconfig
sudo nano /usr/lib64/firefox/defaults/pref/autoconfig.js
```

```js
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
```

```bash
sudo nano /usr/lib64/firefox/firefox.cfg
```

```js
// Настройка PKCS#11 модуля
const { Cc, Ci } = require("chrome");
var pkcs11 = Cc["@mozilla.org/security/pkcs11moduledb;1"]
    .getService(Ci.nsIPKCS11ModuleDB);
pkcs11.addModule("Rutoken PKCS#11", "/usr/lib/librtpkcs11ecp.so", 0, 0);
```

### Настройка Chromium / Яндекс.Браузер

```bash
# Запуск с поддержкой PKCS#11
chromium --ssl-client-auth-module=/usr/lib/librtpkcs11ecp.so

# Или через переменную окружения
export NSS_PKCS11_LIBRARY=/usr/lib/librtpkcs11ecp.so
chromium

# Для Яндекс.Браузера
export NSS_PKCS11_LIBRARY=/usr/lib/librtpkcs11ecp.so
yandex-browser
```

### Настройка через CryptoPro Extension

```bash
# Установка расширения CryptoPro Extension в браузер
# https://www.cryptopro.ru/sites/default/files/products/csp/cades_extension/

# Для Chromium-based браузеров:
# chrome://extensions/ → Загрузить распакованное расширение
```

### Проверка работы ЭП в браузере

```bash
# Проверить доступность токена
pcsc_scan

# Проверить сертификат в КриптоПро
/opt/cprocsp/bin/amd64/certmgr -list

# Проверить плагин браузера
# Перейти на https://www.cryptopro.ru/sites/default/files/products/csp/cades_plugin/
```

---

## Управление сертификатами

### Просмотр сертификатов

```bash
# Через КриптоПро
/opt/cprocsp/bin/amd64/certmgr -list

# Через OpenSSL (для файла)
openssl x509 -in cert.pem -text -noout

# Через certutil (NSS)
certutil -L -d sql:$HOME/.pki/nssdb

# Через pkcs11-tool
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so \
    --login --pin 12345678 \
    --list-objects --type cert
```

### Импорт сертификата

```bash
# В хранилище КриптоПро
/opt/cprocsp/bin/amd64/certmgr -inst \
    -file certificate.cer \
    -store uMy

# В NSS-хранилище (браузер)
certutil -A -d sql:$HOME/.pki/nssdb \
    -n "My Certificate" \
    -t "TC,TC,TC" \
    -i certificate.pem

# В токен
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so \
    --login --pin 12345678 \
    --write-object certificate.der \
    --type cert
```

### Экспорт сертификата

```bash
# Из хранилища КриптоПро
/opt/cprocsp/bin/amd64/certmgr -export \
    -dest exported_cert.cer \
    -dn 'CN=User Name'

# В формате PEM
openssl pkcs12 -in certificate.pfx \
    -out certificate.pem \
    -nodes
```

### Проверка цепочки сертификатов

```bash
# Проверка через OpenSSL
openssl verify -CAfile ca-chain.pem certificate.pem

# Проверка CRL (список отзыва)
openssl verify -CRLfile crl.pem -CAfile ca-chain.pem certificate.pem

# Проверка через КриптоПро
/opt/cprocsp/bin/amd64/certmgr -verify \
    -dn 'CN=User Name'
```

### Работа с хранилищем NSS

```bash
# Создать хранилище
mkdir -p $HOME/.pki/nssdb
certutil -N -d sql:$HOME/.pki/nssdb --empty-password

# Добавить CA-сертификат
certutil -A -d sql:$HOME/.pki/nssdb \
    -n "My CA" \
    -t "CT,C,C" \
    -i ca-cert.pem

# Список сертификатов
certutil -L -d sql:$HOME/.pki/nssdb

# Удаление сертификата
certutil -D -d sql:$HOME/.pki/nssdb \
    -n "Old Certificate"
```

---

## Диагностика и устранение проблем

### Основные команды диагностики

```bash
# Проверка считывателя
pcsc_scan
lsusb | grep -iE 'acs|gemalto|rutoken|hid|omnikey'

# Проверка PC/SC демона
systemctl status pcscd
pcscd -a -d -f  # Запуск в режиме отладки

# Проверка токена
opensc-tool -l
opensc-tool -a
opensc-tool -n

# Проверка PKCS#11
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so --list-slots
p11tool --list-tokens

# Проверка КриптоПро
/opt/cprocsp/bin/amd64/cpconfig -license -view
/opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -verifycontext
/opt/cprocsp/bin/amd64/certmgr -list

# Проверка udev
udevadm monitor --udev

# Проверка прав
ls -l /dev/bus/usb/*/*
```

### Типичные проблемы и решения

| Проблема | Причина | Решение |
|----------|---------|---------|
| `pcsc_scan` не видит считыватель | CCID/udev | Установить `pcsc-lite-ccid`, перезапустить `pcscd` |
| Считыватель есть, карты нет | Конфликт модулей | `blacklist pn533 nfc`, перезапустить |
| `pkcs11-tool` не видит слоты | Библиотека PKCS#11 | Проверить путь к `.so`, права доступа |
| PIN заблокирован | Неверные попытки | Обратиться к администратору УЦ |
| КриптоПро не видит токен | Драйвер | Установить `lsb-cprocsp-rutoken` |
| Браузер не запрашивает сертификат | PKCS#11 не подключён | Добавить модуль в настройках браузера |
| `pcscd` падает | Конфликт версий | Удалить дубликаты `pcsc-lite` |
| `Permission denied` при доступе | udev-правила | Создать правило для USB-устройства |

### Решение проблем с PC/SC

```bash
# 1. Полная переустановка
sudo dnf remove -y pcsc-lite pcsc-lite-ccid
sudo dnf install -y pcsc-lite pcsc-lite-ccid pcsc-tools

# 2. Запуск в режиме отладки
sudo systemctl stop pcscd
sudo pcscd -a -d -f

# 3. В другом терминале:
pcsc_scan

# 4. Проверить udev-правила
cat /etc/udev/rules.d/60-pcscd.rules

# Создать правило, если отсутствует:
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="072f", MODE="0666"' | \
    sudo tee /etc/udev/rules.d/60-pcscd-custom.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Решение проблем с КриптоПро

```bash
# 1. Проверить лицензию
/opt/cprocsp/bin/amd64/cpconfig -license -view

# 2. Проверить контейнеры
/opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -verifycontext -fqcn

# 3. Проверить токены
/opt/cprocsp/bin/amd64/cpconfig -hardware reader -view

# 4. Переустановить драйвер токена
sudo /opt/cprocsp/bin/amd64/cpconfig -hardware reader \
    -del "Rutoken"
sudo /opt/cprocsp/bin/amd64/cpconfig -hardware reader \
    -add "Rutoken"

# 5. Проверить журналы
tail -f /var/log/cprocsp/*.log
```

---

## Справочник команд

| Команда | Описание | Пример |
|---------|----------|--------|
| `pcsc_scan` | Сканирование считывателей | `pcsc_scan` |
| `pcscd` | Демон PC/SC | `sudo systemctl start pcscd` |
| `opensc-tool -l` | Список считывателей | `opensc-tool -l` |
| `opensc-tool -a` | ATR карты | `opensc-tool -a` |
| `pkcs11-tool` | Управление PKCS#11 | `pkcs11-tool --list-slots` |
| `p11tool` | Управление p11-kit | `p11tool --list-tokens` |
| `certutil` | Управление NSS | `certutil -L -d sql:~/.pki/nssdb` |
| `cpconfig` | Настройка КриптоПро | `cpconfig -license -view` |
| `certmgr` | Управление сертификатами | `certmgr -list` |
| `csptest` | Тестирование CSP | `csptest -keyset -enum_cont` |
| `cryptcp` | Подпись/шифрование | `cryptcp -sign doc.pdf doc.sig` |
| `rutoken-mgr` | Управление Рутокен | `rutoken-mgr` |
| `jc-panel` | Панель JaCarta | `jc-panel` |

### Управление токеном

| Команда | Описание |
|---------|----------|
| `pkcs11-tool --init-token` | Инициализация токена |
| `pkcs11-tool --change-pin` | Смена PIN |
| `pkcs11-tool --list-objects` | Список объектов |
| `pkcs11-tool --write-object` | Запись объекта |
| `certmgr -inst` | Установка сертификата |
| `certmgr -del` | Удаление сертификата |
| `certmgr -export` | Экспорт сертификата |

---

## 📋 Требования и совместимость

| Параметр | Значение |
|----------|----------|
| **ОС** | РЕД ОС 7.3 / 8.0 |
| **Архитектура** | x86_64 / aarch64 |
| **PC/SC Lite** | 1.9.x+ |
| **OpenSC** | 0.23.x+ |
| **КриптоПро CSP** | 5.0+ |
| **Рутокен** | Драйверы 2.x+ |
| **JaCarta** | Драйверы 3.x+ |
| **Права** | root (установка), пользователь (чтение) |
| **Совместимость** | ✅ РЕД ОС 7.x, ✅ РЕД ОС 8.x |

> [!note]
> PC/SC Lite, КриптоПро и ГОСТ работают на обеих версиях. Проверьте совместимость версии КриптоПро.

### ⭐ Если этот репозиторий помог вам, поставьте звезду! [![Stars](https://img.shields.io/github/stars/teanrus/redos-lifehacks.svg)](https://github.com/teanrus/redos-lifehacks/stargazers)

### Вместе сделаем работу в РЕД ОС удобнее и эффективнее!
