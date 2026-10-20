# آموزش ساخت یوزر مدیریتی MariaDB محدود به 127.0.0.1

این راهنما برای Debian و MariaDB نصب‌شده روی Linux Node نوشته شده است. در پایان، یک حساب MariaDB خواهیم داشت که دسترسی سراسری مدیریتی دارد، اما بخش Host حساب آن فقط `127.0.0.1` است.

> **هشدار امنیتی:** این حساب تقریباً تمام اختیارات مدیریتی MariaDB را دارد و می‌تواند به همه دیتابیس‌ها دسترسی داشته باشد و مجوزها را به حساب‌های دیگر بدهد. آن را برای نگهداری مدیریتی استفاده کن؛ رمز آن را در Git، مستندات، اسکریپت‌های عمومی یا فایل تنظیمات برنامه‌ها قرار نده.

## ۱. ساخت رمز قوی

در ترمینال Debian اجرا کن و خروجی را موقتاً در محل امنی نگه دار:

```bash
openssl rand -hex 32
```

این فرمان یک رمز تصادفی تولید می‌کند. مقدار خروجی را فقط در دستور ساخت حساب روی همان سرور وارد کن.

## ۲. ورود به MariaDB

برای جلوگیری از ذخیره‌شدن دستورهای SQL در تاریخچهٔ کلاینت MariaDB، با این فرمان وارد شو:

```bash
sudo env MYSQL_HISTFILE=/dev/null mariadb
```

این روش از حساب مدیریتی محلی موجود در نصب MariaDB استفاده می‌کند.

## ۳. ایجاد حساب و اعطای دسترسی کامل

در محیط MariaDB، نام حساب و رمز دلخواه را تنظیم کن. نمونهٔ زیر از نام `fragcity_admin` استفاده می‌کند:

```sql
CREATE USER 'fragcity_admin'@'127.0.0.1'
IDENTIFIED BY 'PASTE_GENERATED_PASSWORD_HERE';

GRANT ALL PRIVILEGES ON *.*
TO 'fragcity_admin'@'127.0.0.1'
WITH GRANT OPTION;

SHOW GRANTS FOR 'fragcity_admin'@'127.0.0.1';
```

به‌جای `PASTE_GENERATED_PASSWORD_HERE`، رمز تولیدشده در مرحلهٔ قبل را وارد کن. عبارت داخل کوتیشن باید رمز واقعی باشد؛ خودِ متن نمونه را استفاده نکن.

معنای دستورات:

- `'fragcity_admin'@'127.0.0.1'`: حسابی با بخش Host مشخص؛ این حساب با حساب‌های هم‌نام ولی Host متفاوت، مانند `'fragcity_admin'@'localhost'` یا `'fragcity_admin'@'%'` یکی نیست.
- `ALL PRIVILEGES ON *.*`: اعطای تمام مجوزهای قابل اعطا در سطح سراسری، برای تمام دیتابیس‌ها.
- `WITH GRANT OPTION`: اجازه می‌دهد این حساب مجوزهایی را که اختیار اعطایشان را دارد به حساب‌های دیگر واگذار کند.

تغییرات `CREATE USER` و `GRANT` فوراً اعمال می‌شوند؛ نیازی به اجرای `FLUSH PRIVILEGES` نیست.

در پایان از MariaDB خارج شو:

```sql
EXIT;
```

### اگر حساب از قبل وجود داشت

اگر `CREATE USER` خطای تکراری‌بودن حساب داد، ابتدا Hostهای موجود را بررسی کن:

```bash
sudo mariadb -e "SELECT User, Host FROM mysql.user WHERE User = 'fragcity_admin';"
```

اگر حساب دقیقاً با Host برابر `127.0.0.1` وجود دارد و قصد داری رمز آن را تغییر بدهی، از `ALTER USER` استفاده کن و سپس دوباره `GRANT` بالا را اجرا کن:

```sql
ALTER USER 'fragcity_admin'@'127.0.0.1'
IDENTIFIED BY 'PASTE_GENERATED_PASSWORD_HERE';
```

حساب‌های دارای Host دیگر را بدون بررسی وابستگی‌ها حذف یا تغییر نده.

## ۴. آزمایش اتصال TCP از 127.0.0.1

از شِل Linux اجرا کن:

```bash
mariadb --protocol=TCP --host=127.0.0.1 --user=fragcity_admin --password
```

هنگام درخواست، همان رمز حساب را وارد کن. پس از ورود، اجرا کن:

```sql
SELECT USER(), CURRENT_USER();
SHOW GRANTS;
```

در خروجی، حساب انتخاب‌شده باید با `fragcity_admin@127.0.0.1` مطابقت داشته باشد. سپس خارج شو:

```sql
EXIT;
```

برای بررسی اینکه فقط یک ورودی حساب با این نام وجود دارد، از نشست مدیریتی اجرا کن:

```bash
sudo mariadb -e "SELECT User, Host FROM mysql.user WHERE User = 'fragcity_admin';"
```

ورودی مورد انتظار:

```text
fragcity_admin | 127.0.0.1
```

## ۵. تفاوت مهم: محدودیت حساب با محدودیت Listener یکی نیست

ساخت حساب با Host برابر `127.0.0.1`، دسترسی **همین حساب** را محدود می‌کند؛ اما به‌تنهایی تضمین نمی‌کند که سرویس MariaDB از رابط‌های شبکهٔ دیگر اتصال نپذیرد. حساب‌های دیگر MariaDB همچنان ممکن است مجوز اتصال از Hostهای دیگری را داشته باشند.

وضعیت آدرس شنونده را بررسی کن:

```bash
sudo mariadb -NBe "SHOW VARIABLES LIKE 'bind_address';"
sudo ss -lntp | grep ':3306'
```

اگر MariaDB باید به‌طور کلی فقط اتصال محلی بپذیرد، مقدار `bind-address` باید در پیکربندی سرویس روی `127.0.0.1` تنظیم شود و پس از بررسی وابستگی‌ها، سرویس با احتیاط راه‌اندازی مجدد شود. **این تغییر را کورکورانه انجام نده**؛ اگر برنامه یا سرور دیگری لازم است از طریق شبکه به MariaDB وصل شود، ممکن است اتصال آن قطع شود. فایروال نیز باید مطابق طراحی شبکه بررسی شود.

## ۶. استفاده از MariaDB به‌عنوان Database Host در Pterodactyl

حساب `fragcity_admin@127.0.0.1` عمداً فقط برای اتصال محلی TCP ساخته شده است. **آن را بی‌دلیل به Host برابر `%` تبدیل نکن.** برای بخش **Admin → Database Hosts** یک حساب جداگانه برای Pterodactyl بساز؛ این حساب باید بتواند دیتابیس‌ها و یوزرهای مخصوص سرورها را ایجاد کند و برای همین `WITH GRANT OPTION` لازم دارد. حساب اتصال اصلی Panel به دیتابیس خودش را با این حساب مدیریتی یکی نکن.

### اول آدرس قابل دسترس برای Panel و سرورهای بازی را مشخص کن

مقدار `Host` در Database Host فقط برای اتصال مدیریتی Panel نیست؛ همان آدرس به‌عنوان آدرس اتصال دیتابیس به سرورهای بازی هم ارائه می‌شود. `127.0.0.1` برای این منظور مناسب نیست، چون داخل Container بازی به خود همان Container اشاره می‌کند، نه به Linux host. مستندات Pterodactyl این نیاز و الزام دسترسی از Containerها را توضیح می‌دهد: https://docs.pterodactyl.io/v2/guides/tutorials/mysql-setup

برای دیدن شبکه‌های Docker موجود اجرا کن:

```bash
docker network ls
```

اگر شبکهٔ Pterodactyl در خروجی با نام `pterodactyl_nw` دیده شد، Gateway و Subnet آن را بررسی کن:

```bash
docker network inspect pterodactyl_nw --format '{{range .IPAM.Config}}subnet={{.Subnet}} gateway={{.Gateway}}{{end}}'
```

اگر نام شبکه متفاوت است، نام واقعی را جایگزین کن. از IP نمونه کپی نکن؛ آدرس را از خروجی محیط خودت انتخاب کن. آدرسی که در فیلد **Host** پنل ثبت می‌کنی باید هم از خود Panel و هم از Containerهای بازی قابل دسترس باشد.

### ساخت حساب اختصاصی Database Host

در SQL زیر، `PANEL_SOURCE_IP` را با IP مبدأیی جایگزین کن که MariaDB واقعاً از اتصال Panel می‌بیند. این آدرس ممکن است با `127.0.0.1` متفاوت باشد. بخش Host حساب MariaDB باید با منبع اتصال Panel مطابقت داشته باشد:

```sql
CREATE USER 'pterodactyl_dbadmin'@'PANEL_SOURCE_IP'
IDENTIFIED BY 'REPLACE_WITH_A_NEW_STRONG_PASSWORD';

GRANT ALL PRIVILEGES ON *.*
TO 'pterodactyl_dbadmin'@'PANEL_SOURCE_IP'
WITH GRANT OPTION;

SHOW GRANTS FOR 'pterodactyl_dbadmin'@'PANEL_SOURCE_IP';
```

`PANEL_SOURCE_IP` و `REPLACE_WITH_A_NEW_STRONG_PASSWORD` مقدارهای نمونه‌اند و باید قبل از اجرا جایگزین شوند؛ آن‌ها را عیناً اجرا نکن. برای این حساب از رمز جداگانه استفاده کن و رمز آن را در Git ثبت نکن.

### توجه به Listener و Firewall

حتی اگر حساب مدیریتی درست باشد، اتصال Containerها تا وقتی MariaDB روی آدرس مناسب گوش ندهد کار نمی‌کند. مقدار فعلی را بررسی کن:

```bash
sudo mariadb -NBe "SHOW VARIABLES LIKE 'bind_address';"
sudo ss -lntp | grep ':3306'
```

MariaDB باید روی آدرسی گوش دهد که در Database Host انتخاب شده و برای Containerها قابل دسترس است. به‌جای بازکردن پورت 3306 برای همهٔ اینترنت، دسترسی Firewall را فقط برای Subnetهای موردنیاز Docker/Node محدود کن و هیچ Port Forward عمومی برای 3306 نساز، مگر اینکه دلیل مشخص و کنترل دسترسی جداگانه داشته باشی. تغییر `bind-address` را پس از شناسایی آدرس درست و بررسی مسیرهای اتصال انجام بده تا اتصال سرویس‌های موجود قطع نشود.

### افزودن در پنل

در **Admin → Database Hosts → Create New**:

- **Name:** نام قابل تشخیص مثل `FragCity MariaDB`
- **Host:** آدرس قابل دسترس برای Panel و Containerها که در مراحل قبل مشخص کردی؛ نه به‌صورت خودکار `127.0.0.1`
- **Port:** `3306` مگر اینکه عمداً پورت دیگری پیکربندی کرده باشی
- **Username:** `pterodactyl_dbadmin`
- **Password:** رمز همان حساب
- **Linked Node:** نود موردنظر را انتخاب کن تا Panel این Host را برای سرورهای آن نود در اولویت قرار دهد

پس از ذخیره، برای سرور آزمایشی یک دیتابیس ایجاد کن و اتصال از داخل Container را بررسی کن. اگر ساخت دیتابیس شکست خورد، ابتدا خطای اتصال/مجوز Panel را بررسی کن؛ اگر دیتابیس ساخته می‌شود ولی برنامهٔ داخل بازی وصل نمی‌شود، آدرس Host، Listener، Firewall و دسترسی کاربر دیتابیس را جداگانه بررسی کن.

## چک‌لیست نهایی

- [ ] حساب `fragcity_admin@127.0.0.1` ساخته شده است.
- [ ] خروجی `SHOW GRANTS` مجوزهای مورد انتظار و `WITH GRANT OPTION` را نشان می‌دهد.
- [ ] اتصال با `--protocol=TCP --host=127.0.0.1` موفق است.
- [ ] برای نام کاربری یکسان، Hostهای اضافی ناخواسته وجود ندارند.
- [ ] وضعیت `bind-address` جداگانه بررسی شده و رمز در مخزن ثبت نشده است.
