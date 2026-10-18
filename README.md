# FragCity — راهنمای مادرِ Copy/Paste از Debian تا سرورهای CS2

> **این فایل مرجع اجرایی واحد پروژه است.** فقط دستورها، توضیحات، پیش‌نیازها و checkpointهای مرحله‌ای در این سند قرار می‌گیرند. خروجی ترمینال، لاگ واقعی و نتیجهٔ اجرای فرمان‌ها عمداً در README ثبت نمی‌شود؛ خروجی لازم برای عیب‌یابی را فقط در گفت‌وگو بفرست. برای اجرای پروژه از صفر، از این سند شروع کن.
>
> **وضعیت فعلی: نصاب Debian 13 روی صفحهٔ `Disk partitioning scheme` است.** مسیر نصب: LVM غیررمزشده، تمام فایل‌های سیستم در یک پارتیشن اصلی؛ سپس تأیید کنترل‌شدهٔ تغییرات، mirror شبکه، انتخاب بسته‌های بدون Desktop و نصب GRUB. Hostname = `fc-node-01` و Domain name = `fragcity.ir`.
>
> **قانون secrets:** رمز MariaDB، رمز حساب، APP_KEY، token، فایل .env و محتوای /etc/pterodactyl/config.yml را در GitHub یا چت قرار نده. مقادیر نمونه را فقط به‌صورت محلی جایگزین کن.

---

## 0. وضعیت، محدوده و خط قرمزها

- هدف این است که **همین VM با نام `fc-node-01`** را از ابتدا با Debian 13 بدون محیط گرافیکی آماده کنیم.
- در نصاب وارد شده: **Hostname** = `fc-node-01` و **Domain name** = `fragcity.ir`. نام کامل موردنظر برای Node برابر `fc-node-01.fragcity.ir` است.
- آدرس موردنظر پنل: `panel.fragcity.ir`. طرح DNS برای بعد از نصب: هر دو نام `panel.fragcity.ir` و `fc-node-01.fragcity.ir` باید از طریق رکورد A به IP عمومی قابل‌دسترسی میزبان اشاره کنند. رکوردهای DNS هنوز در این سند به‌عنوان ساخته‌شده فرض نمی‌شوند؛ آن‌ها را در DNS authoritative دامنه (cPanel فقط اگر همان‌جا DNS مدیریت می‌شود) ثبت و بعد بررسی می‌کنیم.
- پرکردن فیلد Domain name در نصاب به‌تنهایی DNS، IP عمومی، Port Forwarding یا HTTPS را فعال نمی‌کند.
- هنگام نصب Debian 13، در صفحهٔ Software selection گزینهٔ `Debian desktop environment` را بردار و `SSH server` و `standard system utilities` را نگه دار. مدیریت با SSH از Windows و مرورگر Windows انجام می‌شود؛ محیط گرافیکی Debian لازم نیست. راهنما: https://wiki.debian.org/DesktopEnvironment
- VM فعلی روی VMware و Debian 13/Trixie است. IP، منابع و دیسک را بعد از شروع مجدد با بلوک بررسی مرحلهٔ 0 مشخص کن؛ از اعداد قدیمی برای نصب مجدد استفاده نکن.
- Panel در http://192.168.1.5 و مسیر /var/www/pterodactyl است. PHP-FPM socket برابر /run/php/php8.3-fpm.sock.
- مسیر `/home/steam` شامل فایل‌های CS2/KUS موجود است. **این مسیر را حذف، جابه‌جا، overwrite یا بدون طراحی mount دستکاری نکن.** برای ظرفیت دیسک، در هر مرحله مقدار فعلی را با `df -hT /` بررسی کن.
- تا بررسی مدل Storage/Egg، هیچ سرور بازی تازه‌ای از Egg نساز؛ ممکن است بازی را دوباره دانلود و فضای دیسک را پر کند.
- فعلاً Port Forwarding عمومی، دامنه و HTTPS نداریم. این PoC فقط در LAN و روی HTTP است.

### 0.1 حفاظت از دیسک قبلی

فایل‌های VMDK مربوط به Debian Desktop قبلی نزد کاربر موجود هستند. **آن VMDK پشتیبان را در طول نصب جاری به‌عنوان دیسک مقصد انتخاب نکن و آن را overwrite نکن.** نصب روی دیسک مقصد، تمام داده‌های همان دیسک را پاک خواهد کرد.

### 0.2 قرارداد اجرای مرحله‌ای

- از این نقطه، فقط **بلوک مرحلهٔ جاری** را کپی و اجرا کن؛ به مراحل بعدی نپر.
- خروجی دستورها و لاگ‌ها فقط در چت بررسی می‌شوند و در این README ثبت نمی‌شوند.
- رمز، APP_KEY، Token و فایل‌های محرمانه را در چت یا GitHub قرار نده.
- در مسیر جدید، تا قبل از تأیید مرحلهٔ جاری، دستور مرحلهٔ بعد اجرا نشود.
- به مراحل Panel، Docker و Wings نپر؛ ابتدا نصب پایهٔ Debian Console-only را کامل می‌کنیم.

---

## 1. نصب Debian 13 از صفر — Console-only

این مرحله از طریق نصاب Debian در VMware انجام می‌شود. **وضعیت فعلی: Partitioning method.** دستورهای بعدی پس از کامل‌شدن همین مرحله اجرا می‌شوند.

### 1.1 نام‌گذاری در نصاب

مقادیر واردشده:
- **Hostname:** `fc-node-01`
- **Domain name:** `fragcity.ir`
- **FQDN موردنظر Node:** `fc-node-01.fragcity.ir`
- **FQDN موردنظر Panel:** `panel.fragcity.ir`

تنظیم DNS، HTTPS و دسترسی عمومی بعد از نصب و بررسی اتصال شبکه انجام می‌شود؛ فیلد Domain name جایگزین آن‌ها نیست.

### 1.2 Disk partitioning scheme — صفحهٔ فعلی

در این صفحه، گزینهٔ **All files in one partition (recommended for new users)** را انتخاب کن. این باعث می‌شود فضای فایل‌های سیستم، Docker و مسیر پیش‌فرض volumeهای Pterodactyl زیر `/var/lib/pterodactyl/volumes` از ابتدا به چند پارتیشن جدا با اندازه‌های ثابت تقسیم نشود. با LVM می‌توان بعداً Volumeها را مدیریت کرد، اما LVM خودش فضای فیزیکی اضافه نمی‌کند.

اگر هنوز انتخاب نکرده‌ای، **Encrypted LVM را انتخاب نکن**؛ ماشین باید پس از reboot بدون واردکردن passphrase در کنسول بالا بیاید.

### 1.3 بازبینی جدول پارتیشن‌ها و تأیید نوشتن

1. پس از انتخاب scheme، گزینهٔ Continue را بزن تا جدول پارتیشن‌های پیشنهادی نمایش داده شود.
2. پیش از تأیید، دوباره کنترل کن که دیسک مقصد همان VMDK جدید برای این نصب است و ظرفیت آن با برنامه مطابقت دارد. پیشنهاد شروع برای Node میزبان CS2 حداقل **250 GB** است؛ برای چندین نصب بازی/instance ممکن است فضای بیشتری لازم شود.
3. در جدول LVM، وجود پارتیشن بوت و Logical Volume مربوط به ریشه `/` و swap طبیعی است. چون LVM انتخاب شده، وجود پارتیشن جداگانهٔ `/boot` نیز طبیعی است.
4. فقط وقتی مطمئن شدی دیسک درست انتخاب شده، **Finish partitioning and write changes to disk** را انتخاب کن، Continue را بزن و در تأیید نهاییِ نوشتن تغییرات روی دیسک گزینهٔ **Yes** را انتخاب کن.
5. اگر ظرفیت یا نام دیسک اشتباه است، گزینهٔ **No / Go Back** را بزن. دیسک قبلی/پشتیبان را فرمت نکن.

### 1.4 نصب Base System

پس از تأیید پارتیشن‌بندی، Debian پارتیشن‌ها را فرمت می‌کند و سیستم پایه را نصب می‌کند. این مرحله را تا بازگشت صفحهٔ نصاب صبر کن؛ دکمهٔ Cancel یا خاموش‌کردن VM را نزن.

### 1.5 پیکربندی APT و Network Mirror

در صورت نمایش این سؤال‌ها:

1. **Scan additional installation media?** — اگر فقط همان ISO نصب را داری، **No**.
2. **Use a network mirror?** — **Yes**؛ سرور به بسته‌ها و به‌روزرسانی‌های امنیتی از اینترنت نیاز دارد.
3. **Mirror country** — کشور نزدیک و قابل‌دسترسی را انتخاب کن؛ سپس mirror پیش‌فرض پیشنهادی نصاب، معمولاً `deb.debian.org`، را نگه دار.
4. **HTTP proxy information** — اگر Proxy سازمانی تعریف نکرده‌ای، خالی بگذار و Continue کن.
5. اگر دریافت mirror شکست خورد، انتخاب mirror را یادداشت کن و خطای نصاب را بفرست؛ قبل از تکمیل نصب، به تنظیمات تصادفی DNS یا proxy تغییر نده.

Debian عموماً استفاده از network mirror را پیشنهاد می‌کند، و آدرس `deb.debian.org` گزینهٔ پیش‌فرض مناسبی است. راهنمای رسمی: https://www.debian.org/releases/trixie/amd64/install.en.pdf (بخش‌های 6.3.6.1 و 6.3.6.2).

### 1.6 Software selection — نصب Console-only

وقتی صفحهٔ **Software selection** یا **Software selection and install** را دیدی، فقط این گزینه‌ها باید تیک داشته باشند:

- [x] **SSH server**
- [x] **standard system utilities**

و این گزینه باید **تیک نداشته باشد**:

- [ ] **Debian desktop environment**

هر گزینهٔ Desktop مانند GNOME/Xfce/KDE، و نیز Web server یا Print server را برای این مرحله انتخاب نکن. وب‌سرور Panel را بعداً به‌صورت کنترل‌شده با NGINX نصب می‌کنیم؛ Apache پیش‌فرض لازم نیست. سپس Continue را بزن و تا پایان نصب بسته‌ها صبر کن.

### 1.7 نصب GRUB Boot Loader

وقتی نصاب پرسید **Install the GRUB boot loader to your primary drive?** گزینهٔ **Yes** را انتخاب کن.

اگر فهرست دستگاه‌ها نمایش داده شد، دیسک کامل سیستم‌عامل را انتخاب کن، مثل `/dev/sda`، نه پارتیشن خاصی مثل `/dev/sda1`. نام دستگاه را بر اساس ظرفیت/ترتیب همان VM انتخاب کن؛ اگر چند دیسک هم‌اندازه نمایش داده می‌شوند و مطمئن نیستی کدام دیسک نصب است، انتخاب نکن و قبل از ادامه راهنمایی بگیر.

### 1.8 پایان نصب و اولین reboot

1. وقتی پیام **Installation complete** یا **Finish the installation** نمایش داده شد، Continue را بزن.
2. اگر VM دوباره به نصاب برگشت، در VMware از تنظیمات CD/DVD فایل ISO را Disconnect کن یا اتصال ISO هنگام بوت را خاموش کن؛ باید از دیسک مجازی Debian بوت شود.
3. در صفحهٔ Console باید به صفحهٔ login متنی برسد. ورود کاربر را خودت انجام بده؛ نام کاربری و رمز را در README ثبت نکن.

### 1.9 اولین به‌روزرسانی و ابزارهای پایه

بعد از ورود به Debian تازه، این بلوک را یک‌بار اجرا کن. اگر `sudo` دسترسی ندارد یا فرمان شکست خورد، خروجی خطا را بفرست و ادامه نده.

~~~bash
set -eu

sudo apt update
sudo apt full-upgrade -y
sudo apt install -y \
  sudo git curl ca-certificates gnupg2 lsb-release nano htop tmux jq \
  rsync unzip tar xz-utils dnsutils netcat-openbsd openssh-server

sudo systemctl enable --now ssh
sudo reboot
~~~

### 1.10 بررسی اولیهٔ سیستم تازه

پس از reboot وارد کنسول یا SSH شو و این بلوک فقط‌خواندنی را اجرا کن:

~~~bash
set -eu

echo "=== OS and hostname ==="
cat /etc/os-release
hostname
hostname -f || true

echo
echo "=== Network ==="
hostname -I
ip -br address
ip route

echo
echo "=== Virtualization and CPU ==="
systemd-detect-virt || true
uname -m
uname -r
lscpu | grep -E '^(Architecture|CPU\\(s\\)|Model name|Thread|Core|Socket)'

echo
echo "=== Memory and storage ==="
free -h
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
df -hT /
df -ih /
nproc

echo
echo "=== SSH and Internet ==="
sudo systemctl is-active ssh
getent hosts deb.debian.org
curl -fsSI --max-time 15 https://deb.debian.org/ | head -n 1
~~~

**معیار پایان مرحلهٔ Debian:** سیستم به متن login بوت شود؛ معماری `x86_64`، IP شبکه و default route معتبر باشد، SSH فعال باشد و دسترسی HTTPS به Debian mirror کار کند. اگر `hostname -f` هنوز FQDN را درست نشان نداد، نگران نشو؛ بعداً DNS و resolver را بررسی می‌کنیم. خروجی این بلوک را به README اضافه نکن؛ فقط خروجی لازم برای عیب‌یابی را در گفت‌وگو بفرست.

### 1.11 IP ثابت در LAN و DNS عمومی — بعد از بوت، نه داخل نصاب

1. در روتر، برای MAC آداپتور VM یک **DHCP reservation** تعریف کن تا LAN IP ثابت بماند؛ مقدار IP واقعی را بعد از نصب مشخص می‌کنیم.
2. در DNS authoritative دامنه، رکوردهای A زیر باید به IP عمومی قابل‌دسترسی میزبان اشاره کنند:
   - `panel.fragcity.ir`
   - `fc-node-01.fragcity.ir`
3. هنوز DNS record، TLS، port forwarding یا دسترسی اینترنتی را ساخته‌شده فرض نکن. هر کدام را جداگانه بررسی و سپس پیکربندی می‌کنیم.

---

## 2. نصب PHP 8.3 و نیازمندی‌های Panel (نصب تازه)

این مرحله پس از نصب پاک Debian Console-only اجرا می‌شود؛ روی سیستم قدیمی پیش از نصب مجدد اجرا نکن.

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

Composer را از https://getcomposer.org/download/ دریافت کن و روش بررسی checksum/signature را از همان صفحه دنبال کن؛ checksum قدیمی را ثابت فرض نکن.

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

نسخهٔ نصب‌شدهٔ Panel برابر 1.15.1 است. برای بازسازی، صفحهٔ https://github.com/pterodactyl/panel/releases را دوباره بررسی و نسخه را pin کن.

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

اصلاح مجوز Cache برای نصب تازه:

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

این فرمان‌ها فقط در نصب تازه و در نقطهٔ مناسب فرایند اجرا شوند؛ Migration و ساخت Administrator را بی‌دلیل روی نصب فعال تکرار نکن.

بررسی Eggها:

~~~bash
sudo mariadb panel -e "SELECT id, name, nest_id FROM eggs WHERE LOWER(name) LIKE '%counter%strike%' OR LOWER(name) LIKE '%cs2%' ORDER BY name;"
~~~

فرمان بالا صرفاً برای بررسی فهرست Eggهای همین نصب است. نام یا شناسهٔ Egg را حدس نزن؛ تا زمانی که سازگاری Egg با CS2 تأیید نشده، سرور جدید نساز.

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

پس از فعال‌سازی، دسترسی را از مرورگر Windows بررسی کن. این پیکربندی فقط برای LAN/HTTP است.

### 3.6 عیب‌یابی مسیر `/admin` در LAN

اگر `http://192.168.1.5/admin` باز نمی‌شود، قبل از تغییر تنظیمات Node این بررسی‌های فقط‌خواندنی را روی Debian اجرا کن. خروجی ترمینال را به README اضافه نکن.

~~~bash
set +e

echo "=== Local HTTP routes ==="
for path in / /admin /auth/login; do
  printf '%-14s ' "$path"
  curl --connect-timeout 5 --max-time 15 -sS -o /dev/null \
    -w 'HTTP=%{http_code} redirect=%{redirect_url}\n' \
    -H 'Host: 192.168.1.5' "http://127.0.0.1${path}"
done

echo
echo "=== Web services ==="
sudo systemctl is-active nginx php8.3-fpm mariadb redis-server

echo
echo "=== NGINX configuration syntax ==="
sudo nginx -t

echo
echo "=== Registered admin routes ==="
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan route:list --path=admin
~~~

راهنمای تفسیر برای ادامهٔ عیب‌یابی:
- اگر مسیر `/` و `/admin` به‌صورت محلی پاسخ HTTP می‌دهند، وب‌سرور دست‌کم درخواست را دریافت می‌کند؛ رفتار مرورگر و نوع redirect را جداگانه بررسی کن.
- اگر `/admin` پاسخ `500` می‌دهد، خطای Laravel را بررسی کن؛ اگر `502` می‌دهد، NGINX و PHP-FPM را بررسی کن.
- اگر درخواست محلی سالم است ولی از Windows باز نمی‌شود، ارتباط LAN، IP ماشین و فایروال را بررسی کن.
- تا پیش از مشخص‌شدن خطا، NGINX را بازنویسی نکن، سرویس‌ها را کورکورانه restart نکن و Node جدید نساز.



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

فضای دیسک با زمان تغییر می‌کند؛ همیشه مقدار فعلی `df -hT /` را پیش از تخصیص فضا ملاک قرار بده. مسیر `/home/steam` را دستکاری نکن.

### 4.2 لاگ‌ها و سرویس‌ها

~~~bash
sudo systemctl is-active nginx mariadb redis-server php8.3-fpm docker
sudo ss -ltnup
sudo journalctl -u nginx -n 80 --no-pager
sudo journalctl -u php8.3-fpm -n 80 --no-pager
~~~

وجود باینری Wings به‌تنهایی به معنی ایجاد یا فعال‌بودن سرویس systemd نیست؛ وضعیت سرویس را فقط پس از مرحلهٔ ساخت سرویس بررسی کن.

### 4.3 اتصال Windows و تونل دیتابیس

از PowerShell:

~~~powershell
ssh <debian-user>@<node-lan-ip>
~~~

برای تونل موقت به MariaDB، پنجره PowerShell را باز نگه دار:

~~~powershell
ssh -N -L 3307:127.0.0.1:3306 <debian-user>@<node-lan-ip>
~~~

در کلاینت دیتابیس ویندوز، host برابر 127.0.0.1 و port برابر 3307 است؛ user/password همان حساب دیتابیس. پورت 3306 را در روتر باز نکن.

---

## 5. Docker Engine — نصب روی Debian Console-only

این بلوک را فقط روی Debian تازه و پس از تکمیل مراحل 1 تا 4 اجرا کن. روی سیستم قدیمی پیش از نصب مجدد اجرا نکن.

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

پس از نصب یا برای عیب‌یابی، آزمون‌های زیر را اجرا کن. خروجی آن‌ها را به این README اضافه نکن؛ در صورت نیاز به عیب‌یابی، خروجی مرتبط را در گفت‌وگو بفرست.

آزمون‌های بررسی:

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

پس از تکمیل نصب Panel و ورود به آن، می‌توانی از این فرمان برای بررسی نسخه استفاده کنی. خروجی را در README قرار نده.

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:info
~~~

برای راه‌اندازی Wings در شاخهٔ Panel 1.x از راهنمای رسمی https://docs.pterodactyl.io/v1/wings/installing استفاده کن و پیش از نصب، Release سازگار را در https://github.com/pterodactyl/wings/releases بررسی کن.

### 6.2 نصب باینری Wings

این مرحله بعد از ساخت Panel و قبل از ساخت Node اجرا شود. فرمان نصب در بلوک زیر برای سیستم تازه آماده شده است؛ اگر باینری از قبل وجود داشت، بلوک عمداً متوقف می‌شود تا فایل موجود بدون بررسی بازنویسی نشود.

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

فرمان‌های بررسیِ فقط‌خواندنی (خروجی را در README ثبت نکن):

~~~bash
sudo /usr/local/bin/wings version
sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /usr/local/bin/wings
~~~

این فرمان‌ها فقط باینری محلی را بررسی می‌کنند و به‌معنی پیکربندی یا اتصال Wings به Panel نیستند.

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

قبل از تنظیم Node، فضای آزاد فعلی را ملاک بگیر.

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

| بخش | وضعیت مسیر جدید |
|---|---|
| هدف محیط | Debian 13 Console-only؛ بدون Desktop Environment |
| نصاب Debian | روی `Disk partitioning scheme`؛ انتخاب `All files in one partition` و تأیید دیسک مقصد گام‌های جاری‌اند |
| Hostname | در نصاب وارد شده: `fc-node-01` |
| Domain name | در نصاب وارد شده: `fragcity.ir` |
| FQDNهای هدف | `panel.fragcity.ir` و `fc-node-01.fragcity.ir` |
| DNS / public IP / TLS | بعد از نصب بررسی و تنظیم شوند؛ هنوز آماده فرض نشوند |
| VMDK قبلی | نسخهٔ قبلی نزد کاربر موجود است؛ نباید به‌عنوان دیسک مقصد overwrite شود |
| Panel / Docker / Wings | روی نصب تازه هنوز نصب نشده‌اند |
| Node و Wings config | بعد از نصب Panel و ساخت Node |
| CS2 instance | هنوز نساز؛ ابتدا Storage/Egg/Volume طراحی شود |
| Website/Wallet/Billing | مراحل آینده |

خروجی اجرای فرمان‌ها، لاگ‌ها، رمزها، نام حساب‌های شخصی و SHAهای فایل‌ها را به این README اضافه نکن. این سند فقط دستورها، تصمیم‌های معماری و مراحل تکرارپذیر را نگه می‌دارد.

## منابع رسمی

- Debian Installer guide: https://www.debian.org/releases/trixie/amd64/install.en.pdf

- Debian: https://www.debian.org/distrib/
- Panel releases: https://github.com/pterodactyl/panel/releases
- Wings 1.x installation: https://docs.pterodactyl.io/v1/wings/installing
- Wings releases: https://github.com/pterodactyl/wings/releases
- Docker on Debian: https://docs.docker.com/engine/install/debian/
- Composer: https://getcomposer.org/download/
