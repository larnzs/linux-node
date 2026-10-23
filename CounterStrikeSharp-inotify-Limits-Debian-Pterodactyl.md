# عیب‌یابی و رفع محدودیت inotify در CounterStrikeSharp روی Debian و Pterodactyl

این آموزش برای زمانی است که یک یا چند سرور CS2 در Pterodactyl اجرا می‌شوند، اما CounterStrikeSharp هنگام راه‌اندازی .NET Runtime به‌طور ناگهانی بالا نمی‌آید و در لاگ خطای `inotify` یا `FileSystemWatcher` دیده می‌شود.

> **هدف:** افزایش کنترل‌شده و دائمی سقف `inotify instances` روی میزبان Debian، بررسی مستقل محدودیت فایل‌دسکریپتور پردازش، و بازیابی سرورهای خراب بدون reboot غیرضروری کل Node.

آموزش برای Debian میزبان Node نوشته شده است؛ دستورهای میزبان را داخل کنسول کانتینر CS2 اجرا نکن.

---

## 1. تشخیص خطا

نمونهٔ اصلی خطا شبیه این است:

```text
System.IO.IOException: The configured user limit (128) on the number of inotify instances has been reached, or the per-process limit on the number of open file descriptors has been reached.
   at System.IO.FileSystemWatcher.StartRaisingEvents()
   at Microsoft.Extensions.FileProviders.Physical.PhysicalFilesWatcher.TryEnableFileSystemWatcher()
   at Microsoft.Extensions.Configuration.FileConfigurationProvider...
CSSharp: Bootstrap::Run return failure.
CSSharp: Failed to initialize .NET runtime
```

این خطا هنگام ایجاد FileSystemWatcher رخ می‌دهد. در این وضعیت ممکن است CS2 و MetaMod هنوز بخشی از راه‌اندازی را انجام دهند، اما CounterStrikeSharp نتواند .NET Runtime را کامل مقداردهی اولیه کند. در نتیجه پلاگین‌های وابسته به CounterStrikeSharp بارگذاری نمی‌شوند یا کار نمی‌کنند.

**در قدم اول پلاگین‌ها را پاک یا دوباره نصب نکن.** ابتدا محدودیت سیستم‌عامل را بررسی کن؛ این خطا به‌تنهایی نشان نمی‌دهد که فایل پلاگین خراب است.

---

## 2. تفاوت سه محدودیت مهم

این مقادیر مستقل‌اند و نباید آن‌ها را با هم اشتباه گرفت:

| محدودیت | چه چیزی را محدود می‌کند؟ | چه زمانی آن را بررسی کنیم؟ |
| --- | --- | --- |
| `fs.inotify.max_user_instances` | تعداد inotify instanceهایی که یک real UID می‌تواند ایجاد کند | وقتی خطا مشخصاً از تمام‌شدن inotify instances حرف می‌زند |
| `fs.inotify.max_user_watches` | تعداد watchهای فایل/دایرکتوری برای یک real UID | وقتی مشکل مربوط به watchها باشد؛ معمولاً خطای متفاوتی دیده می‌شود |
| `Max open files` یا `RLIMIT_NOFILE` | تعداد file descriptorهای یک پردازش | وقتی سقف فایل‌دسکریپتور خود پردازش پر شده باشد |

در کنار این‌ها، `fs.inotify.max_queued_events` سقف رویدادهای صف‌شدهٔ هر inotify instance است و معمولاً راه‌حل این خطای مشخص نیست.

محدودیت‌های `max_user_instances` و `max_user_watches` بر اساس شناسهٔ واقعی کاربر لینوکس اعمال می‌شوند. بنابراین چند پردازش یا کانتینر ممکن است در استفاده از سهمیه با هم رقابت کنند؛ به‌خصوص اگر پردازش‌ها با UID یکسان اجرا شوند. جزئیات UID mapping در نصب‌هایی که Docker user-namespace remapping فعال دارند می‌تواند متفاوت باشد.

---

## 3. وضعیت فعلی میزبان را ثبت کن

با SSH به خود Debian Node وصل شو و این بلوک را اجرا کن:

```bash
echo "=== inotify limits ==="
sysctl fs.inotify.max_user_instances
sysctl fs.inotify.max_user_watches
sysctl fs.inotify.max_queued_events

echo
echo "=== processes related to CS2 ==="
ps -eo pid,uid,cmd | grep -E '[c]s2|[c]s2egg|[c]s2node'

echo
echo "=== file descriptors pointing to inotify (rough count) ==="
sudo find /proc/[0-9]*/fd \
  -maxdepth 1 -type l \
  -lname 'anon_inode:inotify' \
  2>/dev/null | wc -l
```

### نکتهٔ مهم دربارهٔ عدد inotify

عدد آخر، تعداد لینک‌های file descriptor پیدا‌شده را می‌شمارد؛ **این عدد لزوماً تعداد instanceهای یکتا نیست**، چون یک descriptor ممکن است به پردازش دیگری منتقل شده باشد یا در چند پردازش دیده شود. از آن برای نشانه‌گیری اولیه استفاده کن، نه برای ادعای اینکه دقیقاً چند instance مصرف شده است.

مثلاً در یک بررسی ممکن است `max_user_instances=128` و شمارش لینک‌های inotify بیشتر از 128 باشد. این ترکیب دلیل خوبی برای بررسی بیشتر است، اما به‌تنهایی ثابت نمی‌کند که همهٔ لینک‌ها instanceهای مجزای متعلق به یک UID هستند.

برای دیدن UID و PID واقعی پردازش CS2 روی میزبان، از خروجی `ps` استفاده کن. اگر چند سرور با UID یکسان اجرا شوند، افزایش مصرف در یک پردازش می‌تواند روی امکان ساخت instance جدید توسط پردازش دیگری اثر بگذارد.

---

## 4. بررسی file descriptorهای یک سرور

ابتدا PID واقعی پردازش CS2 را پیدا کن:

```bash
ps -eo pid,uid,cmd | grep '[c]s2'
```

از بین نتایج، پردازشی را انتخاب کن که خط فرمان آن متعلق به سرور موردنظر است؛ برای نمونه، سروری که با `-port 29000` اجرا شده. مقدار PID در نمونه‌ها را کورکورانه استفاده نکن؛ پس از Restart ممکن است تغییر کند.

سپس PID واقعی را وارد کن:

```bash
PID=16500

echo "=== process limits ==="
grep -i "Max open files" "/proc/$PID/limits"

echo
echo "=== current open descriptors ==="
ls "/proc/$PID/fd" | wc -l

echo
echo "=== inotify descriptors visible in this process ==="
find "/proc/$PID/fd" \
  -maxdepth 1 -type l \
  -lname 'anon_inode:inotify' \
  2>/dev/null | wc -l
```

در خط `Max open files` معمولاً دو عدد برای سقف soft و hard نمایش داده می‌شود. تعداد فعلی descriptorها را با سقف soft مقایسه کن. اگر PID دیگر وجود ندارد، آن پردازش بسته شده یا PID عوض شده است؛ PID جدید را دوباره پیدا کن.

**اگر تعداد descriptorها به سقف soft نزدیک نیست، بی‌دلیل limit فایل‌دسکریپتور را افزایش نده.** اگر نزدیک سقف است، بخش عیب‌یابی مرحلهٔ 7 را دنبال کن.

---

## 5. راه‌حل موقت: افزایش سقف instanceها تا 1024

برای خطایی که مشخصاً به سقف پیش‌فرض 128 اشاره می‌کند، ابتدا می‌توان سقف را موقتاً روی میزبان افزایش داد:

```bash
sudo sysctl -w fs.inotify.max_user_instances=1024
```

بررسی کن که مقدار اعمال شده باشد:

```bash
sysctl fs.inotify.max_user_instances
```

خروجی مورد انتظار:

```text
fs.inotify.max_user_instances = 1024
```

این فرمان فوراً مقدار در حال اجرای کرنل را تغییر می‌دهد و برای اعمال‌شدنش reboot لازم نیست. با این حال، تغییر runtime به‌تنهایی تضمین نمی‌کند که پس از reboot باقی بماند.

### آزمایش پس از تغییر

1. در Pterodactyl فقط یکی از سرورهایی را که CounterStrikeSharp در آن fail شده، Stop و Start کن.
2. لاگ شروع را از ابتدا بررسی کن.
3. دنبال پیام موفقیت `CSSharp: .NET Runtime Initialised.` بگرد.
4. بررسی کن که `Bootstrap::Run return failure` و `Failed to initialize .NET runtime` دیگر ظاهر نشوند.
5. اگر این سرور درست شد، سرورهای دیگری را که قبلاً با همین خطا مواجه شده‌اند، جداگانه راه‌اندازی و بررسی کن.

برای این آزمایش لازم نیست کل Node را reboot کنی یا Docker daemon را Restart کنی.

---

## 6. دائمی‌کردن تنظیم در Debian

اگر آزمایش تأیید کرد که افزایش سقف مشکل را حل می‌کند، تنظیم را در فایل مستقل sysctl نگه دار:

```bash
sudo tee /etc/sysctl.d/99-fragcity-inotify.conf > /dev/null <<'EOF'
fs.inotify.max_user_instances = 1024
EOF
```

سپس فایل‌های تنظیمات sysctl را بارگذاری کن:

```bash
sudo sysctl --system
```

تأیید نهایی:

```bash
sysctl fs.inotify.max_user_instances
cat /etc/sysctl.d/99-fragcity-inotify.conf
```

مقدار باید همچنان `1024` باشد و فایل تنظیمات باید شامل همان یک مقدار باشد.

### چرا مقدار 1024؟

این مقدار افزایش معناداری از 128 است و نقطهٔ شروعی محافظه‌کارانه برای Node دارای چند سرور CS2 است. **این عدد تضمین نمی‌کند که تعداد نامحدودی سرور اجرا می‌شود.** اگر مصرف واقعی به سقف جدید نزدیک شد، ابتدا پردازش‌های مصرف‌کننده و اینکه آیا پس از Stop به‌درستی خارج می‌شوند بررسی شود؛ سپس بر اساس میزان مصرف واقعی تصمیم بگیر که آیا مقدار بیشتری لازم است.

به‌صورت خودکار `max_user_watches`، `max_queued_events` یا محدودیت فایل‌دسکریپتور را هم بالا نبر. هر کدام علت و روش تشخیص متفاوتی دارند.

---

## 7. اگر پس از افزایش به 1024 خطا همچنان باقی بود

در این حالت، متن خطا را دوباره بخوان و موارد زیر را به ترتیب بررسی کن.

### A. مقدار واقعاً اعمال شده است؟

```bash
sysctl fs.inotify.max_user_instances
```

اگر مقدار 1024 نیست، بررسی کن فایل در مسیر درست ذخیره شده و `sysctl --system` خطایی گزارش نداده باشد.

### B. پردازش واقعاً به سقف فایل‌دسکریپتور رسیده است؟

PID فعلی همان سرور را دوباره پیدا کن و مرحلهٔ 4 را اجرا کن. اگر تعداد فعلی FDها نزدیک `Max open files` soft limit است، مشکل ممکن است از `RLIMIT_NOFILE` خود پردازش باشد، نه از `max_user_instances`.

در Pterodactyl، سرور بازی داخل کانتینر اجرا می‌شود. محدودیت FD کانتینر را با مقدار پیش‌فرض میزبان یکی فرض نکن. پیش از تغییر تنظیمات Docker، کانتینر صحیح را مشخص کن و پیکربندی آن را بررسی کن:

```bash
docker ps --no-trunc
```

تغییر `default-ulimits` در تنظیمات Docker می‌تواند روی **کانتینرهای جدید** اثر بگذارد و تغییر آن ممکن است نیازمند Restart سرویس Docker در زمان نگه‌داری باشد؛ این کار می‌تواند تمام سرورهای روی Node را مختل کند. بنابراین فقط وقتی شواهد نشان می‌دهد FD limit پر است سراغ این تغییر برو، نه صرفاً به خاطر وجود کلمهٔ «file descriptors» در متن خطا.

### C. آیا سرور واقعاً بعد از Stop بسته شده است؟

پس از Stop سرور در Pterodactyl، پردازش‌های مربوط به همان سرور را دوباره بررسی کن:

```bash
ps -eo pid,uid,cmd | grep '[c]s2'
```

اگر پردازش قدیمی پس از Stop همچنان وجود دارد، ابتدا علت بسته‌نشدن صحیح آن را بررسی کن. پردازش‌های باقی‌مانده می‌توانند منابع را مصرف کنند. صرفاً برای پاک‌کردن این خطا، همهٔ پردازش‌هایی که نام `cs2` دارند را یک‌جا Kill نکن؛ ممکن است سرورهای سالم دیگر را هم متوقف کنی.

### D. آیا خطا مربوط به watchهاست؟

در این آموزش مقدار فعلی `max_user_watches` را فقط ثبت می‌کنیم. اگر لاگ دقیقاً خطای مربوط به watch quota یا خطایی مانند `No space left on device` نشان می‌دهد، آن را جداگانه بررسی کن. `max_user_watches` تعداد watchها را محدود می‌کند؛ `max_user_instances` تعداد instanceها را. افزایش یکی جایگزین دیگری نیست.

### E. اگر بعد از Restart فقط CounterStrikeSharp fail شد

اگر CS2 و MetaMod بالا هستند اما همچنان این موارد دیده می‌شوند:

```text
CSSharp: Bootstrap::Run return failure.
CSSharp: Failed to initialize .NET runtime
```

CounterStrikeSharp هنوز قابل‌استفاده نیست. به‌جای نصب مجدد پلاگین‌ها، لاگ کامل از ابتدای شروع، مقدار sysctl، PID و `Max open files` همان پردازش را ثبت کن. خطاهای پیشین و جدید را مقایسه کن تا مشخص شود علت واقعاً تغییر کرده یا خیر.

---

## 8. بازگرداندن تنظیم

اگر پس از آزمایش تصمیم گرفتی مقدار دائمی را حذف کنی، ابتدا بدان که کاهش سقف می‌تواند باعث شود ساخت inotify instanceهای جدید دوباره شکست بخورد. این کار سرویس‌ها را به‌طور خودکار تعمیر نمی‌کند.

برای حذف تنظیم اختصاصی FragCity:

```bash
sudo rm /etc/sysctl.d/99-fragcity-inotify.conf
```

برای بازگرداندن مقدار runtime به مقدار قبلی نمونهٔ این Node یعنی 128:

```bash
sudo sysctl -w fs.inotify.max_user_instances=128
```

این فرمان فقط مقدار فعلی کرنل را تغییر می‌دهد؛ با حذف فایل و reboot نیز تنظیم دیگر از فایل اختصاصی FragCity بارگذاری نمی‌شود، مگر اینکه فایل دیگری همان مقدار را تنظیم کند. قبل از کاهش سقف مطمئن شو که عمداً قصد بازگشت به محدودیت قبلی را داری، چون اگر استفادهٔ فعلی بیشتر باشد، راه‌اندازی instanceهای تازه ممکن است دوباره شکست بخورد.

---

## 9. چک‌لیست نهایی قبولی

- [ ] مقدار `fs.inotify.max_user_instances` روی میزبان به مقدار انتخاب‌شده رسیده است.
- [ ] فایل دائمی `/etc/sysctl.d/99-fragcity-inotify.conf` وجود دارد و مقدار درست دارد.
- [ ] یک سرور دارای خطا بدون reboot کردن کل Node Restart شده است.
- [ ] در لاگ جدید پیام `CSSharp: .NET Runtime Initialised.` دیده می‌شود.
- [ ] خطای `configured user limit (128)` یا خطاهای بعدی مقداردهی .NET تکرار نشده‌اند.
- [ ] سرورهای دیگری که قبلاً fail شده بودند، جداگانه آزمایش شده‌اند.
- [ ] اگر خطا باقی است، `Max open files` و تعداد FDهای پردازش بررسی شده‌اند.
- [ ] هیچ secretای از قبیل Web API Key، GSLT، رمز سرور یا توکن در گزارش‌ها و GitHub منتشر نشده است.

---

## 10. منابع فنی

- [Linux man-pages: inotify(7)](https://man7.org/linux/man-pages/man7/inotify.7.html) — تفاوت `max_user_instances`، `max_user_watches` و `max_queued_events`.
- [Microsoft Learn: File watcher limits on Linux](https://learn.microsoft.com/en-us/aspnet/core/tutorials/dotnet-watch?view=aspnetcore-3.1) — توضیح خطاهای inotify در ابزارهای .NET و تفاوت سقف instanceها با FD limit.
- [CounterStrikeSharp issue #1145](https://github.com/roflmuffin/CounterStrikeSharp/issues/1145) — نمونه‌ای از همین متن خطا هنگام بارگذاری CounterStrikeSharp.
