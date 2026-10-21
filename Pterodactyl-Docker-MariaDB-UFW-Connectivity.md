# اتصال کانتینرهای Pterodactyl به MariaDB میزبان با UFW

این راهنما توضیح می‌دهد چطور سرورهای بازی داخل Docker بتوانند به MariaDB نصب‌شده روی Debian host وصل شوند، بدون اینکه پورت 3306 برای اینترنت باز شود.

## سناریوی این سرور

- شبکه Docker: `pterodactyl_nw`
- رابط شبکه میزبان: `pterodactyl0`
- Subnet IPv4: `172.18.0.0/16`
- Gateway میزبان: `172.18.0.1`
- MariaDB port: `3306/tcp`
- MariaDB باید روی `127.0.0.1:3306` و `172.18.0.1:3306` گوش کند.
- UFW فعال است و سیاست ورودی پیش‌فرض `deny` است.

> آدرس‌ها و نام رابط بالا مخصوص اجرای ثبت‌شده‌اند. قبل از اجرا در ماشین دیگر، مقدارهای واقعی را بررسی کنید و کورکورانه کپی نکنید.

## مرحله 1 — بررسی شبکه و Listener دیتابیس

روی Debian host اجرا کنید؛ نه داخل کانتینر بازی:

```bash
docker network inspect pterodactyl_nw \
  --format '{{range .IPAM.Config}}Subnet={{.Subnet}} Gateway={{.Gateway}}{{"\\n"}}{{end}}'

ip -o -4 addr show
sudo ss -lntp | grep ':3306'
sudo mariadb -NBe "SHOW VARIABLES LIKE 'bind_address';"
sudo ufw status verbose
```

تأیید کنید Gateway واقعی میزبان `172.18.0.1` است و MariaDB روی آن آدرس گوش می‌دهد. اگر فقط `127.0.0.1:3306` نمایش داده شود، کانتینر نمی‌تواند از طریق Gateway به سرویس برسد؛ ابتدا `bind-address` را طبق مراحل زیر تنظیم کنید.

### تنظیم bind-address در MariaDB

این مراحل را روی Debian host اجرا کنید، نه داخل کانتینر بازی. در این محیط MariaDB 11.8.6 نصب است و خط ثبت‌شدهٔ تنظیم باید شامل هر دو IP زیر باشد تا اتصال محلی میزبان حفظ شود و Gateway شبکه Docker نیز Listener داشته باشد.

1. از فایل تنظیمات نسخه پشتیبان بگیرید:

```bash
sudo cp -a /etc/mysql/mariadb.conf.d/50-server.cnf \
  /root/50-server.cnf.backup
```

2. فایل را باز کنید:

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

3. داخل بخش `[mysqld]`، خط موجود `bind-address` را **ویرایش کنید**؛ خط تکراری دیگری نسازید. مقدار باید دقیقاً این باشد:

```ini
bind-address = 127.0.0.1,172.18.0.1
```

4. ذخیره کنید و MariaDB را مجدداً راه‌اندازی کنید:

```bash
sudo systemctl restart mariadb
sudo systemctl --no-pager --full status mariadb
```

5. تأیید کنید هر دو Listener بالا آمده‌اند:

```bash
sudo ss -lntp | grep ':3306'
sudo mariadb -NBe "SHOW VARIABLES LIKE 'bind_address';"
```

خروجی `ss` باید دو Listener برای `127.0.0.1:3306` و `172.18.0.1:3306` نشان دهد. اگر سرویس بالا نیامد، قبل از ادامه خطا را بررسی کنید:

```bash
sudo journalctl -u mariadb -n 50 --no-pager
```

توجه: `bind-address` فقط تعیین می‌کند MariaDB روی کدام IPها گوش کند؛ این تنظیم به‌تنهایی دسترسی را ایمن یا مجوز ورود SQL را اعطا نمی‌کند. قانون محدود UFW و Host مجاز حساب MariaDB نیز باید جداگانه درست باشند. اگر Gateway یا Subnet شبکه Docker در ماشین دیگری متفاوت است، IP نمونه را پس از بررسی شبکه با مقدار واقعی جایگزین کنید.

## مرحله 2 — پیدا کردن رابط Gateway

```bash
IFACE="$(ip -o -4 addr show | awk '$4 ~ /^172\\.18\\.0\\.1\\// {print $2; exit}')"

if [ -z "$IFACE" ]; then
  echo "ERROR: Docker gateway interface not found; stop here."
else
  echo "Docker interface: $IFACE"
fi
```

در اجرای ثبت‌شده، نتیجه `pterodactyl0` بود. اگر رابط پیدا نشد، قانون فایروال اضافه نکنید؛ ابتدا Subnet/Gateway واقعی را پیدا کنید.

## مرحله 3 — اجازه محدود UFW برای MariaDB

فقط پس از تأیید Subnet، Gateway و رابط، روی میزبان اجرا کنید:

```bash
sudo ufw allow in on pterodactyl0 \
  from 172.18.0.0/16 to 172.18.0.1 \
  port 3306 proto tcp
```

این قانون ورودی TCP پورت 3306 را فقط از Subnet داخلی Docker، از طریق رابط `pterodactyl0` و به مقصد Gateway میزبان مجاز می‌کند. **از اجرای `ufw allow 3306/tcp` خودداری کنید**؛ آن دستور گسترده‌تر است و می‌تواند دیتابیس را در معرض شبکه‌های نامطلوب قرار دهد.

برای ماشین دیگری، رابط، Subnet و Gateway را با مقادیر همان ماشین جایگزین کنید. اگر UFW از قبل قانون معادل دارد، قانون تکراری نسازید.

## مرحله 4 — آزمایش TCP از داخل کانتینر

روی میزبان، کانتینر را پیدا کنید:

```bash
docker ps --format 'table {{.ID}}\\t{{.Names}}\\t{{.Networks}}\\t{{.Status}}'
```

جایگزین `CONTAINER_ID` را با شناسه کانتینر واقعی کنید:

```bash
docker exec CONTAINER_ID bash -lc \
'if timeout 3 bash -c "</dev/tcp/172.18.0.1/3306"; then echo TCP_OK; else echo TCP_FAIL; fi'
```

- `TCP_OK`: اتصال TCP برقرار است؛ این **به‌تنهایی** تأیید نمی‌کند نام کاربری، رمز یا مجوز SQL درست است.
- `TCP_FAIL`: مرحله بعدی بررسی فایروال و Listener است. برای مشاهده رویدادهای اخیر UFW:

```bash
sudo journalctl -k --since "5 minutes ago" --no-pager | grep -iE 'UFW|DROP|REJECT'
```

نمونه رخداد مسدودشده ممکن است `IN=pterodactyl0 SRC=172.18.0.2 DST=172.18.0.1 DPT=3306` داشته باشد. پس از افزودن قانون محدود، تست TCP را دوباره اجرا کنید.

## مرحله 5 — حساب MariaDB و تنظیم پلاگین

پس از دریافت `TCP_OK`:

1. از تنظیمات Database Host در Pterodactyl، نام دیتابیس، نام کاربری و رمز همان دیتابیس را بردارید.
2. در تنظیمات پلاگین، Host را به `172.18.0.1` و Port را به `3306` تنظیم کنید.
3. اگر خطای اتصال ادامه دارد، مجوزهای SQL و Host مجاز حساب را بررسی کنید. حساب `'fragcity_admin'@'127.0.0.1'` فقط برای اتصال مطابق Host تعریف‌شده است و خودبه‌خود اجازه ورود از کانتینر را نمی‌دهد.
4. حساب مدیریتی دارای `ALL PRIVILEGES ON *.* WITH GRANT OPTION` را در پلاگین‌ها به اشتراک نگذارید. برای هر پلاگین/کاربرد، حسابی با کمترین مجوز لازم و دسترسی فقط به دیتابیس موردنیاز در نظر بگیرید.

## نکات امنیتی

- پورت 3306 را به اینترنت باز نکنید.
- تغییر `bind-address` فقط Listener شبکه را تنظیم می‌کند؛ جایگزین UFW و مجوزهای SQL نیست.
- قبل از تغییر فایل‌های MariaDB نسخه پشتیبان بگیرید و بعد از restart، `systemctl status mariadb` و `ss -lntp` را بررسی کنید.
- اگر Subnet Docker عوض شود، قانون محدود UFW و آدرس اتصال پلاگین باید دوباره بررسی شوند.
