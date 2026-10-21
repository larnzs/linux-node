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

تأیید کنید Gateway واقعی میزبان `172.18.0.1` است و MariaDB روی آن آدرس گوش می‌دهد. اگر فقط `127.0.0.1:3306` نمایش داده شود، کانتینر نمی‌تواند با Gateway به سرویس برسد؛ ابتدا bind-address را طبق راهنمای MariaDB تنظیم و سرویس را بررسی کنید.

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
