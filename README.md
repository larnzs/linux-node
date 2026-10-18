# FragCity — راهنمای مادرِ Copy/Paste از Debian تا سرورهای CS2

> **این فایل مرجع اجرایی واحد پروژه است.** فرمان‌ها و نتیجه‌های تأییدشده به ترتیب ثبت می‌شوند؛ بعد از هر مرحلهٔ جدید، همین فایل به‌روز خواهد شد. برای اجرای پروژه از صفر، از این سند شروع کن.
>
> **آخرین وضعیت: ۱۸ اکتبر ۲۰۲۶.** Pterodactyl Panel نسخهٔ 1.15.1 نصب و ورود از Windows در LAN تأیید شده؛ Docker Engine نسخهٔ 29.9.1 نصب و `hello-world` موفق؛ باینری Wings نسخهٔ 1.13.4 در `/usr/local/bin/wings` نصب و اجرای `--help` و `version` تأیید شده است. مرحلهٔ جاری: ساخت Node در Panel؛ config، اتصال، debug و سرویس systemd هنوز انجام نشده‌اند.
>
> **قانون secrets:** رمز MariaDB، رمز حساب، APP_KEY، token، فایل .env و محتوای /etc/pterodactyl/config.yml را در GitHub یا چت قرار نده. مقادیر نمونه را فقط به‌صورت محلی جایگزین کن.

---

## 0. محدوده و خط قرمزها

- فعلاً **همین VM موجود** با نام fc-node-01 را ادامه می‌دهیم؛ ساخت VM جدید بخشی از مسیر فعلی نیست.
- برای نصب‌های آینده Debian را بدون Desktop Environment نصب کن. در Software selection گزینهٔ Debian desktop environment را بردار و SSH server و standard system utilities را انتخاب کن. مدیریت Panel با مرورگر Windows انجام می‌شود؛ محیط گرافیکی Debian لازم نیست.
- وضعیت VM فعلی: Debian 13/Trixie، VMware، x86_64/amd64، kernel برابر 6.12.113+deb13-amd64، چهار vCPU، حدود 5.6 GiB RAM، IP برابر 192.168.1.5.
- Panel در http://192.168.1.5 و مسیر /var/www/pterodactyl است. PHP-FPM socket برابر /run/php/php8.3-fpm.sock.
- Root filesystem برابر 112 GiB و در آخرین snapshot حدود 27 GiB آزاد بود. مسیر /home/steam حدود 71 GiB فایل‌های CS2/KUS دارد. **این مسیر را حذف، جابه‌جا، overwrite یا بدون طراحی mount دستکاری نکن.**
- تا بررسی مدل Storage/Egg، هیچ سرور بازی تازه‌ای از Egg نساز؛ ممکن است بازی را دوباره دانلود و فضای دیسک را پر کند.
- فعلاً Port Forwarding عمومی، دامنه و HTTPS نداریم. این PoC فقط در LAN و روی HTTP است.

## 1. نصب Debian از صفر (راهنمای بازسازی)

این بخش برای نصب آینده است؛ برای ادامه روی VM فعلی Debian را دوباره نصب نکن.

### 1.1 هنگام نصب

1. ISO رسمی Debian 13.x netinst amd64 را از https://www.debian.org/distrib/ بگیر.
2. در VMware شبکه را Bridged بگذار. برای PoC اولیه 4 vCPU و حدود 6 GiB RAM در نظر بگیر. اندازهٔ دیسک باید برای Base Game و چند instance کافی باشد؛ در VM فعلی فضای آزاد برای دانلود تکراری CS2 کافی نیست.
3. Hostname: fc-node-01. کاربر عادی مانند fragcityadmin بساز و دسترسی sudo بده.
4. Desktop Environment را انتخاب نکن؛ SSH server و standard system utilities را انتخاب کن.
5. پارتیشن‌بندی باید فقط روی دیسک مجازی VMware باشد، نه دیسک فیزیکی Windows.
6. در روتر DHCP reservation بساز و IP را پس از بوت بررسی کن.

### 1.2 اولین بوت و ابزارهای پایه

~~~bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y sudo git curl ca-certificates gnupg2 lsb-release nano htop tmux jq rsync unzip tar xz-utils dnsutils netcat-openbsd openssh-server
sudo systemctl enable --now ssh
sudo reboot
~~~

از PowerShell ویندوز به Debian وصل شو؛ IP نمونهٔ لابراتوار:

~~~powershell
ssh fragcityadmin@192.168.1.5
~~~

بررسی سیستم:

~~~bash
set -u
cat /etc/os-release
hostname
hostname -I
ip -br address
ip route
systemd-detect-virt || true
uname -m
uname -r
lscpu | grep -E '^(Architecture|CPU\(s\)|Model name|Thread|Core|Socket)'
free -h
df -hT /
df -ih /
nproc
sudo systemctl is-active ssh
~~~

انتظار: Debian 13.x، معماری x86_64/amd64، IP معتبر، مسیر پیش‌فرض و SSH فعال. اگر IP متفاوت است، در ادامه آدرس واقعی را جایگزین کن.

---

## 2. نصب PHP 8.3 و نیازمندی‌های Panel (نصب تازه)

در VM فعلی PHP 8.3.35، MariaDB، Redis، NGINX و Composer نصب هستند؛ این بخش برای بازسازی است و لازم نیست اکنون دوباره اجرا شود.

### 2.1 Repository برای PHP 8.3

~~~bash
set -eu
sudo apt update
sudo apt install -y ca-certificates curl gnupg2 lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/sury-php.gpg
sudo chmod a+r /etc/apt/keyrings/sury-php.gpg
. /etc/os-release
echo "deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${VERSION_CODENAME} main" | sudo tee /etc/apt/sources.list.d/sury-php.list
sudo apt update
~~~

### 2.2 نصب بسته‌ها

~~~bash
sudo apt install -y \
  php8.3 php8.3-cli php8.3-common php8.3-gd php8.3-mysql \
  php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl \
  php8.3-zip php8.3-fpm php8.3-intl php8.3-opcache \
  mariadb-server redis-server nginx git curl tar unzip
~~~

Composer را از https://getcomposer.org/download/ نصب کن و روش بررسی checksum/signature را از همان صفحه دنبال کن؛ checksum قدیمی را ثابت فرض نکن. در VM فعلی Composer 2.10.3 در /usr/local/bin/composer است.

بررسی:

~~~bash
set -eu
php8.3 -v
composer --version
for module in bcmath curl dom gd intl json mbstring mysqli openssl PDO pdo_mysql posix tokenizer xml zip; do
  php8.3 -m | grep -Eixq "$module" || { echo "MISSING: $module"; exit 1; }
  echo "OK: $module"
done
sudo systemctl enable --now nginx mariadb redis-server php8.3-fpm
sudo systemctl is-active nginx mariadb redis-server php8.3-fpm
sudo ss -ltnp | grep -E ':(22|80|443|3306|6379)\b' || true
~~~

MariaDB باید روی 127.0.0.1:3306 و Redis روی loopback بمانند؛ برای این PoC این پورت‌ها را عمومی نکن.

---

## 3. نصب Pterodactyl Panel 1.15.1 (نصب تازه)

نسخهٔ VM فعلی با خروجی واقعی artisan p:info برابر 1.15.1 تأیید شده. برای بازسازی، صفحهٔ https://github.com/pterodactyl/panel/releases را دوباره بررسی و نسخه را pin کن.

### 3.1 دریافت فایل‌ها و Composer

فقط برای نصب تازه اجرا شود. اگر /var/www/pterodactyl/.env وجود دارد، آن را overwrite نکن.

~~~bash
set -eu
sudo install -d -o www-data -g www-data /var/www/pterodactyl
cd /var/www/pterodactyl

if sudo test -e .env; then
  echo "STOP: .env already exists; this is not a clean install."
  exit 1
fi

sudo curl -fL https://github.com/pterodactyl/panel/releases/download/v1.15.1/panel.tar.gz -o /tmp/panel.tar.gz
sudo tar -xzf /tmp/panel.tar.gz -C /var/www/pterodactyl
sudo chown -R www-data:www-data /var/www/pterodactyl
sudo chmod -R 755 storage bootstrap/cache
sudo cp .env.example .env
sudo chown www-data:www-data .env
sudo chmod 640 .env

cd /var/www/pterodactyl
sudo -u www-data /usr/local/bin/composer install --no-dev --optimize-autoloader
sudo -u www-data php8.3 artisan key:generate
~~~

APP_KEY فقط یک‌بار هنگام نصب تازه تولید می‌شود. آن را دوباره تولید نکن.

### 3.2 دیتابیس اختصاصی

ابتدا وجود دیتابیس و حساب را بررسی کن؛ روی نصب موجود CREATE را کورکورانه تکرار نکن.

~~~bash
sudo mariadb -Nse "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='panel';"
sudo mariadb -Nse "SELECT CONCAT(User, '@', Host) FROM mysql.user WHERE User='pterodactyl';"
~~~

برای نصب تازه:

~~~bash
sudo env MYSQL_HISTFILE=/dev/null mariadb
~~~

داخل prompt مربوط به MariaDB، یک رمز قوی و یکتا را به‌صورت محلی جایگزین کن:

~~~sql
CREATE DATABASE panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'REPLACE_WITH_A_UNIQUE_PASSWORD';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
SHOW GRANTS FOR 'pterodactyl'@'127.0.0.1';
EXIT;
~~~

رمز را در سند نگذار. اگر user از قبل وجود دارد، برای تعویض رمز از ALTER USER استفاده کن، نه CREATE USER.

### 3.3 Wizardهای Panel

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:environment:setup
sudo -u www-data php8.3 artisan p:environment:database
~~~

مقادیر PoC فعلی: URL برابر http://192.168.1.5، timezone برابر Asia/Tehran، cache/session/queue برابر redis، Redis host برابر 127.0.0.1 و port برابر 6379، DB host برابر 127.0.0.1، port برابر 3306، database برابر panel و user برابر pterodactyl. رمز DB را در prompt و به‌شکل خصوصی وارد کن. Redis password در wizard فعلی خالی بود.

### 3.4 اصلاح مجوز Cache، Migration و مدیر

اصلاح واقعی Cache permission و آزمون موفق:

~~~bash
set -eu
cd /var/www/pterodactyl
sudo chown -R www-data:www-data storage bootstrap/cache
sudo find storage bootstrap/cache -type d -exec chmod 750 {} +
sudo find storage bootstrap/cache -type f -exec chmod 640 {} +
sudo -u www-data sh -c 'touch storage/framework/cache/data/.fragcity-permission-test && rm storage/framework/cache/data/.fragcity-permission-test && echo "OK: www-data can write to Laravel cache"'
~~~

فقط برای نصب تازه:

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan migrate --seed --force
sudo -u www-data php8.3 artisan p:user:make
~~~

هر دو فرمان در نصب فعلی موفق شدند و حساب Administrator ساخته شد. روی نصب فعلی دوباره اجرا نکن مگر دلیل مشخصی وجود داشته باشد.

بررسی Eggها:

~~~bash
sudo mariadb panel -e "SELECT id, name, nest_id FROM eggs WHERE LOWER(name) LIKE '%counter%strike%' OR LOWER(name) LIKE '%cs2%' ORDER BY name;"
~~~

نتیجهٔ قبلی: فقط Egg به نام Counter-Strike: Global Offensive، ID برابر 11 و Nest ID برابر 2 دیده شد؛ Egg اختصاصی CS2 هنوز تأیید نشده است.

### 3.5 پیکربندی NGINX برای LAN

فایل /etc/nginx/sites-available/pterodactyl.conf در VM فعلی:

~~~nginx
server {
    listen 80;
    listen [::]:80;
    server_name 192.168.1.5;
    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    add_header X-Content-Type-Options nosniff;
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ^~ /assets/ {
        location ~ /\. { deny all; }
        try_files $uri =404;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht { deny all; }
}
~~~

فعال‌سازی/تست:

~~~bash
set -eu
if ! sudo test -e /etc/nginx/sites-enabled/pterodactyl.conf && ! sudo test -L /etc/nginx/sites-enabled/pterodactyl.conf; then
  sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
fi
if sudo test -L /etc/nginx/sites-enabled/default; then
  sudo rm /etc/nginx/sites-enabled/default
fi
sudo /usr/sbin/nginx -t
sudo systemctl reload nginx
sudo systemctl is-active nginx
curl -sS -o /dev/null -w 'HTTP status: %{http_code}\n' -H 'Host: 192.168.1.5' http://127.0.0.1/
~~~

ورود از Windows به http://192.168.1.5 موفق شد. این فقط LAN/HTTP است.

---

## 4. بررسی منابع و عیب‌یابی

### 4.1 دیسک

~~~bash
set -u
df -hT /
df -ih /
sudo du -xhd1 / 2>/dev/null | sort -h
sudo du -xhd1 /var /usr /home /opt /tmp 2>/dev/null | sort -h
sudo du -sh /var/cache/apt/archives 2>/dev/null || true
sudo journalctl --disk-usage
sudo du -sh /var/log /var/lib/docker /var/lib/containerd 2>/dev/null || true
~~~

نتیجهٔ ثبت‌شده: root برابر 112 GiB، حدود 80 GiB مصرف، حدود 27 GiB آزاد؛ /home/steam حدود 71 GiB. اعداد با زمان تغییر می‌کنند.

### 4.2 لاگ‌ها و سرویس‌ها

~~~bash
sudo systemctl is-active nginx mariadb redis-server php8.3-fpm docker
sudo ss -ltnup
sudo journalctl -u nginx -n 80 --no-pager
sudo journalctl -u php8.3-fpm -n 80 --no-pager
~~~

تا وقتی Wings نصب نشده، نبودن service آن طبیعی است.

### 4.3 اتصال Windows و تونل دیتابیس

از PowerShell:

~~~powershell
ssh fragcityadmin@192.168.1.5
~~~

برای تونل موقت به MariaDB، پنجره PowerShell را باز نگه دار:

~~~powershell
ssh -N -L 3307:127.0.0.1:3306 fragcityadmin@192.168.1.5
~~~

در کلاینت دیتابیس ویندوز، host برابر 127.0.0.1 و port برابر 3307 است؛ user/password همان حساب دیتابیس. پورت 3306 را در روتر باز نکن.

---

## 5. Docker Engine (تأیید شده؛ روی همین VM دوباره نصب نکن)

بلوک زیر سابقهٔ روش نصب از repository رسمی است. روی VM فعلی که docker.sources دارد، دوباره اجرا نکن.

~~~bash
set -eu
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
if ! sudo test -s /etc/apt/keyrings/docker.asc; then
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
fi
sudo chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
~~~

در تلاش ابتدایی HTTP 403 دیده شد؛ تست مجدد endpointهای رسمی هر دو HTTP 200 داد و بسته‌ها نصب شدند.

نتیجهٔ واقعی: Docker version 29.9.1, build dfc520d؛ سرویس ACTIVE؛ docker info نسخهٔ Server برابر 29.9.1 و docker run --rm hello-world موفق بود.

آزمون تکرارپذیر:

~~~bash
sudo docker --version
sudo systemctl is-active docker
sudo docker info --format 'Server={{.ServerVersion}} Containers={{.Containers}} Images={{.Images}}'
sudo docker run --rm hello-world
df -h /
~~~

این فقط Docker را تأیید می‌کند، نه Wings یا اجرای CS2.

---

## 6. Wings و Node — مرحلهٔ جاری

### 6.1 بررسی نسخهٔ Panel

اجراشده:

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:info
~~~

نتیجهٔ واقعی:
- Panel Version: 1.15.1
- Latest Version: error
- Up-to-Date: Yes
- URL: http://192.168.1.5
- Environment production، Debug No، timezone Asia/Tehran
- Cache/Queue/Session برابر redis
- DB host برابر 127.0.0.1:3306، database برابر panel، user برابر pterodactyl.

Latest Version: error یعنی این فرمان نتوانست مقدار Latest را دریافت کند؛ به‌تنهایی دلیل خرابی Panel نیست. برای شاخهٔ Panel 1.x از راهنمای رسمی https://docs.pterodactyl.io/v1/wings/installing استفاده می‌کنیم. صفحهٔ Release رسمی که ۱۸ اکتبر ۲۰۲۶ بررسی شد v1.13.4 را آخرین Release معرفی می‌کرد: https://github.com/pterodactyl/wings/releases .

### 6.2 نصب و تأیید باینری Wings v1.13.4 — انجام شده

این گام در ۱۸ اکتبر ۲۰۲۶ اجرا شد؛ **دوباره دانلود یا روی فایل موجود نصب نکن** مگر اینکه دلیل مشخصی برای تعویض باینری داشته باشیم.

فرمان اجراشده:

~~~bash
set -eu

if sudo test -e /usr/local/bin/wings; then
  echo "STOP: /usr/local/bin/wings already exists; inspect it instead of overwriting."
  sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /usr/local/bin/wings
  exit 1
fi

sudo install -d -o root -g root -m 0755 /etc/pterodactyl
curl -fL \
  "https://github.com/pterodactyl/wings/releases/download/v1.13.4/wings_linux_amd64" \
  -o /tmp/wings_linux_amd64
file /tmp/wings_linux_amd64
sha256sum /tmp/wings_linux_amd64
sudo install -o root -g root -m 0755 \
  /tmp/wings_linux_amd64 /usr/local/bin/wings
/usr/local/bin/wings --help
~~~

خروجی‌های واقعی ثبت‌شده:
- فایل: ELF 64-bit LSB executable، x86-64، statically linked، stripped.
- SHA-256: `7e763389bb5d386a7d32ccdd46cffcf1ab9ed697e5c2aca7fe44183b527cd4c0`
- `sudo /usr/local/bin/wings version`: خروجی `wings vv1.13.4` و Copyright © 2018–2026 Dane Everitt & Contributors.
- مالکیت و مجوز: `owner=root:root mode=755 size=28299424 path=/usr/local/bin/wings`.

فرمان بررسیِ فقط‌خواندنی برای دفعات بعد:

~~~bash
sudo /usr/local/bin/wings version
sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /usr/local/bin/wings
~~~

این خروجی‌ها نصب باینری را تأیید می‌کنند، نه اتصال Wings به Panel.

### 6.3 ساخت Node از مرورگر Windows — گام بعدی

این مرحله از مرورگر Windows انجام می‌شود؛ داخل Debian فرمانی برای ساخت Node لازم نیست.

**اول فضای فعلی را فقط بررسی کن** (بدون تغییر فایل‌ها):

~~~bash
echo "=== RAM ==="
free -h
echo
echo "=== Root filesystem ==="
df -hT /
~~~

آخرین snapshot ما حدود 27 GiB فضای آزاد داشت، اما قبل از تنظیم Node مقدار فعلی را ملاک بگیر.

در مرورگر Windows:
1. وارد `http://192.168.1.5` شو و مطمئن شو با حساب Administrator وارد شده‌ای.
2. از **Admin → Locations** یک Location بساز یا Location موجود را انتخاب کن؛ مثلاً Short Code برابر `lan` و Description برابر `FragCity LAN`.
3. به **Admin → Nodes → Create New** برو.
4. در Identity: نام `fc-node-01`، توضیح اختیاری، و Location مرحلهٔ قبل را انتخاب کن.
5. در Network/Daemon: برای PoC محلی، FQDN/IP برابر `192.168.1.5`، SSL خاموش، Daemon Port برابر `8080` و Daemon SFTP Port برابر `2022` باشد، مگر اینکه UI نسخهٔ فعلی مقادیر دیگری را نشان دهد. چون هنوز دامنه و TLS نداریم، IP و HTTP فقط برای LAN است.
6. در بخش منابع، با RAM ثبت‌شدهٔ حدود 5.6 GiB، **Total Memory = 4096 MiB** و Memory Overallocate = `0` تنظیم مناسب شروع است. برای دیسک، فقط اگر بررسی بالا نشان دهد حداقل حدود 22 GiB فضای خالی باقی مانده، **Total Disk Space = 16000 MiB** و Disk Overallocate = `0` قرار بده؛ اگر فضای آزاد کمتر است، مقدار را پایین‌تر بگذار تا دست‌کم حدود 6 GiB برای Debian/Docker و لاگ‌ها محفوظ بماند. این اعداد ظرفیت تخصیصی Panel هستند، نه رزرو یا افزایش فضای فیزیکی.
7. اگر فیلد Server File Directory نمایش داده شد، فعلاً مقدار پیش‌فرض `/var/lib/pterodactyl/volumes` را حفظ کن. **آن را روی `/home/steam` تنظیم نکن**؛ طرح استفادهٔ مجدد از بازی موجود هنوز طراحی نشده است.
8. Node را ذخیره کن. سپس وارد صفحهٔ همان Node شو و نتیجهٔ ساخت را بررسی کن.

فعلاً Allocation برای سرور بازی نساز و هیچ سروری ایجاد نکن؛ ابتدا اتصال Wings را تأیید می‌کنیم و سپس Storage/Egg/Ports را جداگانه طراحی می‌کنیم.

### 6.4 تولید config محرمانه از خود Panel

پس از ساخته‌شدن Node، تب **Configuration** همان Node را باز کن و در بخش **Auto-Deploy** روی **Generate Token** بزن. فرمان کامل Bash را که خود Panel می‌سازد، مستقیم و بدون ویرایش در SSH مربوط به Debian اجرا کن. token یا command تولیدشده را اینجا نفرست و در GitHub قرار نده.

پس از اجرای فرمان دقیق Auto-Deploy از Panel، فقط وجود فایل را بررسی کن:

~~~bash
sudo test -s /etc/pterodactyl/config.yml && echo "OK: node config exists"
sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /etc/pterodactyl/config.yml
~~~

Token و Node ID را حدس نزن؛ UI آن‌ها را تولید می‌کند. فایل config نباید وارد Git شود.

### 6.5 اجرای foreground

فقط بعد از Node creation و config:

~~~bash
sudo wings --debug
~~~

لاگ را بررسی کن. اگر بدون خطای fatal اجرا شد با Ctrl+C متوقفش کن. اگر خطا داد، متن خطا را بفرست و token/secret را حذف کن. تا debug موفق نشده، systemd service نساز و WAN را باز نکن.

### 6.6 systemd (پس از debug موفق)

~~~bash
sudo tee /etc/systemd/system/wings.service >/dev/null <<'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now wings
sudo systemctl status wings --no-pager
sudo systemctl is-active wings
~~~

تأیید: سرویس active و Node در Panel برابر Online شود. اگر خطا داشت:

~~~bash
sudo journalctl -u wings -n 100 --no-pager
sudo systemctl status wings --no-pager
sudo ss -ltnup | grep -E ':(8080|2022)\b' || true
~~~

پیش از استفادهٔ عمومی، دامنه، TLS مخصوص Panel و Wings، firewall و Router/VMware NAT را جداگانه طراحی کن.

---

## 7. Storage و CS2/KUS — بعد از Online شدن Node

این فصل هنوز فرمان اجرایی ندارد. پیش از ساخت اولین سرور:
1. فضای دیسک و حجم دانلود واقعی را بسنجیم.
2. مشخص کنیم Egg فعلی CS:GO قدیمی است یا CS2 را درست نصب می‌کند.
3. روش استفاده از بازی موجود زیر /home/steam در مدل Container/Volume را طراحی کنیم.
4. CPU/RAM/disk و portهای instance آزمایشی را تعیین کنیم.
5. Start/Stop/Console/Files/SFTP و جدایی داده‌ها را آزمایش کنیم.

تا آن زمان instance جدید نساز و به /home/steam دست نزن.

## 8. سایت FragCity، Wallet و فروش مدت‌دار — فازهای بعد

این بخش هنوز دستور نهاییِ اجرا و آزمایش‌شده ندارد. پس از اثبات PoC سرور بازی، همین runbook با فرمان‌های معتبر برای موارد زیر ادامه پیدا می‌کند:
- API امن بین سایت Raw PHP و Pterodactyl؛
- اتصال فروشگاه/Paymenter؛
- شارژ Wallet، کسر یک‌باره، سفارش و expires_at؛
- suspend/stop هنگام انقضا بدون حذف داده؛
- backup/restore، retry و idempotency؛
- Node دوم، آزمون ظرفیت و نصب تکرارپذیر؛
- DNS/TLS، firewall و دسترسی عمومی پس از قبولی آزمون LAN.

فرمان اجرانشده را به‌عنوان دستور آمادهٔ Production ثبت نمی‌کنیم؛ پس از اجرا و تست به همین سند اضافه می‌شود.

## 9. آخرین checkpoint

| بخش | وضعیت |
|---|---|
| Debian 13، SSH و LAN | انجام شده طبق خروجی‌های ثبت‌شده |
| Panel 1.15.1 | نصب؛ ورود Windows تأیید شده |
| MariaDB، Redis، PHP-FPM، NGINX | فعال؛ DB/Redis روی loopback |
| Cache permissions | اصلاح و تأیید شده |
| Migration/seed و Admin | موفق |
| Docker 29.9.1 | نصب؛ daemon active؛ hello-world موفق |
| Wings v1.13.4 | باینری نصب شده؛ `version` و مالکیت/مجوز تأیید شده |
| Node fc-node-01 | مرحلهٔ جاری: ساخت در Panel |
| Wings config/debug/systemd | منتظر Node؛ config محرمانه باید محلی تولید شود |
| CS2 instance | هنوز ساخته نشده؛ Storage/Egg/Volume مسدودکننده است |
| دامنه/TLS/Port Forwarding عمومی | انجام نشده |
| Website/Wallet/Billing | مراحل آینده |
| /home/steam | بدون تغییر حفظ شود |

## منابع رسمی

- Debian: https://www.debian.org/distrib/
- Panel releases: https://github.com/pterodactyl/panel/releases
- Wings 1.x installation: https://docs.pterodactyl.io/v1/wings/installing
- Wings releases: https://github.com/pterodactyl/wings/releases
- Docker on Debian: https://docs.docker.com/engine/install/debian/
- Composer: https://getcomposer.org/download/
