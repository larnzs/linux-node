# آموزش Mount سفارشی در Pterodactyl Wings برای FragCity

این راهنما خطای زیر را در Wings بررسی می‌کند و روش امنی برای آزمایش Mountهای فایل‌های پلاگین و کانفیگ FragCity ارائه می‌دهد:

```text
Skipped the mount for /home/container/...
```

## 1. علت خطا را تشخیص بده

روی نود لینوکس اجرا کن:

```bash
sudo journalctl -u wings --since "30 minutes ago" --no-pager \
  | grep -i -B 3 -A 5 -E 'skipping custom server mount|not in list of allowed mount points|allowed mount point|source_path|target_path'
```

اگر پیام زیر دیده شود:

```text
skipping custom server mount, not in list of allowed mount points
```

یعنی Source تعریف‌شده برای Mount زیر هیچ‌کدام از مسیرهای مجاز Wings قرار نگرفته است.

مسیرهای مجاز فعلی را بررسی کن:

```bash
sudo grep -n -A 10 '^allowed_mounts:' /etc/pterodactyl/config.yml
```

اگر خروجی چنین باشد، هیچ مسیر سفارشی مجاز نشده است:

```yaml
allowed_mounts: []
```

> گزینهٔ **User Mountable** در پنل و فهرست `allowed_mounts` در Wings دو تنظیم متفاوت‌اند. User Mountable امکان انتخاب/استفاده از Mount را در پنل فراهم می‌کند؛ اما Wings همچنان Source را با `allowed_mounts` اعتبارسنجی می‌کند.

## 2. قبل از اعمال تغییر، Mountهای خطرناک را اصلاح کن

Mount کردن یک پوشهٔ عمومی روی مسیر بزرگ‌تری از مسیر موردنیاز می‌تواند محتوای مقصد داخل کانتینر را بپوشاند.

برای آزمایش اولیه، از این مقصدهای مرحله‌ای استفاده کن:

| Source روی میزبان لینوکس | Target داخل کانتینر | Read Only |
|---|---|---|
| `/var/lib/pterodactyl/mounts/fragcity-kus-payload/mountplugins/game/csgo/addons` | `/home/container/fragcity-payload/plugins/game/csgo/addons` | روشن |
| `/var/lib/pterodactyl/mounts/fragcity-kus-payload/mountconfigs/game` | `/home/container/fragcity-payload/defaults/game` | روشن |

در صفحهٔ مدیریت Mountهای Pterodactyl مطمئن شو که:

1. Source دقیقاً همان مسیر مطلق واقعی روی میزبان است.
2. Target یک مسیر مطلق داخل کانتینر است.
3. گزینهٔ **User Mountable** برای Mountهایی که لازم است از صفحهٔ سرور انتخاب شوند، فعال است.
4. گزینهٔ **Read Only** برای این دو Mount آزمایشی فعال است.
5. Mountها به سرور موردنظر اختصاص داده شده‌اند.

این مقصدها صرفاً برای تأیید Mount هستند؛ در این مرحله پلاگین‌ها از مسیر مرحله‌ای بارگذاری نمی‌شوند. پس از موفقیت تست، پوشه‌های مشخص پلاگین را جداگانه به مسیر Runtime درست وصل کن.

**از این مقصدهای عمومی استفاده نکن:**

- `/home/container/game`
- `/home/container/game/csgo/addons`

Mount کردن کل `game` ممکن است فایل‌های بازی مدیریت‌شده توسط Node را بپوشاند. Mount کردن کل `addons` نیز ممکن است فایل‌های Metamod یا CounterStrikeSharp را که Egg مدیریت می‌کند، پنهان کند.

## 3. از تنظیمات Wings نسخهٔ پشتیبان بگیر

ابتدا سرور آزمایشی را از پنل متوقف کن. سپس:

```bash
sudo cp -a /etc/pterodactyl/config.yml \
  "/etc/pterodactyl/config.yml.bak-$(date +%F-%H%M%S)"
```

فایل را باز کن:

```bash
sudo nano /etc/pterodactyl/config.yml
```

این بخش را پیدا کن:

```yaml
allowed_mounts: []
```

و آن را به این شکل تغییر بده:

```yaml
allowed_mounts:
  - /var/lib/pterodactyl/mounts/fragcity-kus-payload
```

این تنظیم فقط شاخهٔ اختصاصی FragCity را به‌عنوان مسیر مجاز معرفی می‌کند. مسیر ریشهٔ سیستم، یعنی `/`، را به فهرست اضافه نکن.

فایل را ذخیره کن. در Nano از `Ctrl+O`، سپس `Enter` و بعد `Ctrl+X` استفاده کن.

## 4. مسیر Source و مجوزهای آن را بررسی کن

این دستورها کمک می‌کنند مطمئن شوی مسیرهای تعریف‌شده واقعاً وجود دارند و مجوزهای پوشه‌های والد را بررسی کنی:

```bash
sudo namei -l /var/lib/pterodactyl/mounts/fragcity-kus-payload/mountplugins/game/csgo/addons
sudo namei -l /var/lib/pterodactyl/mounts/fragcity-kus-payload/mountconfigs/game
sudo find /var/lib/pterodactyl/mounts/fragcity-kus-payload -maxdepth 5 -type d -print
```

اگر پوشه‌ای وجود ندارد یا مسیر Source اشتباه تایپ شده، آن را قبل از راه‌اندازی مجدد اصلاح کن. از `chmod 777` برای رفع خطا استفاده نکن؛ Wings مسیرهای والد را از نظر امنیتی بررسی می‌کند و تغییر گستردهٔ مجوزها راه‌حل امنی نیست.

## 5. Wings را مجدداً راه‌اندازی و وضعیت را بررسی کن

```bash
sudo systemctl restart wings
sudo systemctl status wings --no-pager -l
```

وضعیت مورد انتظار:

```text
Active: active (running)
```

سپس فقط یک سرور آزمایشی را از پنل روشن کن.

خطاهای مربوط به Mount را بررسی کن:

```bash
sudo journalctl -u wings --since "5 minutes ago" --no-pager \
  | grep -i -E 'skipping custom server mount|not in list of allowed mount points|ignoring allowed mount point'
```

اگر این دستور خروجی نداشت، خطاهای جست‌وجوشده در این بازه دیده نشده‌اند؛ برای اثبات اعمال Mount، مرحلهٔ بعد را هم انجام بده.

## 6. Mountهای واقعی کانتینر را تأیید کن

شناسه و نام کانتینر را پیدا کن:

```bash
sudo docker ps --no-trunc --format 'table {{.ID}}\t{{.Names}}'
```

سپس به‌جای `<CONTAINER_ID>` شناسهٔ کانتینر سرور آزمایشی را قرار بده:

```bash
sudo docker inspect <CONTAINER_ID> --format '{{range .Mounts}}{{println .Source "->" .Destination "rw=" .RW}}{{end}}'
```

در خروجی باید هر دو Source آزمایشی به Targetهای مرحله‌ای مربوط به خودشان متصل شده باشند و `rw=false` نمایش داده شود.

اگر Mountها اعمال شده‌اند، فایل‌های نمایان در مسیرهای مرحله‌ای را از File Manager یا محیط کانتینر بررسی کن. اگر Wings هنوز Mount را رد می‌کند، خروجی جدید `journalctl` را بررسی کن؛ خطای تازه ممکن است مربوط به مجوز مسیر یا یک Source دیگر باشد.

## 7. معماری نهایی پیشنهادی FragCity

- فایل‌های پایهٔ CS2 را در اختیار سازوکار مدیریت فایل‌های بازی Egg/Node نگه دار.
- Metamod و CounterStrikeSharp را در مسیرهای تحت مدیریت Egg نگه دار.
- پوشه‌های پلاگین سفارشی را فقط به مقصد Runtime همان پلاگین Mount کن؛ از Mount کردن کل `addons` اجتناب کن.
- فایل‌های پیش‌فرض کانفیگ را مرحله‌ای نگه دار و با فرایند Seed به Volume اختصاصی هر سرور منتقل کن، تا ویرایش‌های مشتری‌ها با هر Restart بازنویسی نشوند.
- قبل از هر تغییر گسترده، یک سرور آزمایشی را بررسی کن.

## مرجع

- [Wings — مدیریت Mountهای سفارشی](https://github.com/pterodactyl/wings/blob/develop/server/mounts.go)
- [مستندات Mount در Pterodactyl](https://pterodactyl.io/wings/1.0/configuration.html)
