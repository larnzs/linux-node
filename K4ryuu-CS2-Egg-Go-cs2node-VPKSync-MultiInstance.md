# آموزش نصب K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop Cache

این آموزش برای Debian Node دارای Pterodactyl است. تمام دستورهای این فایل روی **خود Debian host** اجرا می‌شوند، مگر آن‌که صریحاً نوشته شود از Windows، Panel یا داخل Container استفاده کن. برای Node دیگری hostname، IP، دامنه و نام سرور را عوض کن؛ مسیرهای مرکزی پیش‌فرض را فقط وقتی تغییر بده که config نیز به‌روزرسانی شود.

> **هدف نهایی:** یک Shared CS2 Base در `/srv/cs2-shared`، Workshop Cache مجزا در `/srv/cs2-workshop` و دو Instance که از طریق daemon بازی را به‌صورت مشترک استفاده کنند. این آموزش به‌خودی‌خود فایل‌های Windows را تبدیل به Linux runtime نمی‌کند.

## نقشهٔ اجرا

1. پیش‌نیازهای Node و i386 را آماده و آزمایش کن.
2. Egg کامل رسمی را Import و یک Instance آزمایشی بساز، اما آن را Start نکن.
3. `cs2node` را با دستور مشخص نصب و Wizard را تکمیل کن.
4. دانلود/Update مرکزی را تا Build ID و VPKهای معتبر بررسی کن.
5. Instance اول را آزمایش کن، سپس Instance دوم را بساز.
6. اگر لازم شد، فایل‌های بازی و Workshop را جداگانه و با رعایت ساختار موردنیاز منتقل کن.
7. تنها پس از قبولی Multi Instance سراغ CounterStrikeSharp و پلاگین‌ها برو.

**اگر مرحله‌ای Fail شد، جلو نرو.** ابتدا معیار قبولی و فرمان‌های تشخیصی همان مرحله را اجرا کن.

## 1. پیش‌نیازها و مقادیر محیطی

پیش‌نیازها:

- Debian 13 amd64، دسترسی sudo و اتصال اینترنت خروجی.
- Pterodactyl Panel فعال، Docker و Wings سالم، Node در Panel برابر Online.
- فضای آزاد کافی برای Base کامل و Workshop؛ ظرفیت واقعی را با `df -hT /` بررسی کن.
- یک UDP Allocation آزاد برای Instance آزمایشی.
- سرورهای بازی Offline هنگام آماده‌سازی Base.
- هیچ daemon قدیمی دیگری نباید هم‌زمان همان Base را Update کند.

قبل از اجرا این جدول را با مقادیر واقعی پر کن:

| مقدار | از کجا تعیین شود | مقدار محیط خودت |
|---|---|---|
| Hostname | `hostnamectl --static` روی Node | `<NODE_HOSTNAME>` |
| IP/FQDN | شبکهٔ خودت یا DNS | `<NODE_IP_OR_FQDN>` |
| Panel URL | دامنهٔ واقعی Panel | `https://<PANEL_FQDN>` |
| نام سرور اول | نام یکتا در Panel | `<CS2_TEST_SERVER_NAME>` |
| Allocation | Panel → Node → Allocations | `<CS2_UDP_ALLOCATION>` |
| مسیر Base | تنظیم `vpksync.cs2_dir` | `/srv/cs2-shared` |
| مسیر Workshop | تنظیم ماژول Workshop | `/srv/cs2-workshop` |

دستور بررسی هویت و فضای دیسک:

~~~bash
hostnamectl --static
hostname -f
ip -br address
df -hT /
uname -m
dpkg --print-architecture
~~~

معیار قبولی: معماری `amd64`، IP درست، فضای کافی و Node Online. اگر معماری متفاوت است، دستورات مخصوص amd64 را کورکورانه اجرا نکن.

## 2. پیش‌نیاز الزامی Debian amd64: Runtime سی‌ودو بیتی

SteamCMD ممکن است از باینری 32-bit در `linux32/steamcmd` استفاده کند؛ داشتن سیستم‌عامل amd64 به‌تنهایی وجود loader و کتابخانه‌های i386 را تضمین نمی‌کند. این مرحله را **قبل از نصب cs2node و اولین Update مرکزی** انجام بده.

~~~bash
set -eu

test "$(dpkg --print-architecture)" = "amd64" || {
  echo "STOP: this block is for Debian amd64."
  exit 1
}

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y libc6:i386 libstdc++6:i386 libgcc-s1:i386

echo "=== Enabled foreign architectures ==="
dpkg --print-foreign-architectures

echo "=== Installed i386 runtime packages ==="
dpkg-query -W libc6:i386 libstdc++6:i386 libgcc-s1:i386
~~~

معیار قبولی: فرمان‌ها بدون خطا پایان یابند و `i386` در فهرست معماری‌های foreign دیده شود.

اگر SteamCMD از قبل نصب است، این آزمون را اجرا کن:

~~~bash
sudo /root/steamcmd/steamcmd.sh +quit
~~~

معیار قبولی، خروجی موفق مشابه `Loading Steam API...OK` و `Unloading Steam API...OK` است. این فقط قابل اجرا بودن SteamCMD را ثابت می‌کند، نه دانلود موفق CS2 را. اگر مسیر SteamCMD وجود ندارد، این آزمون را فعلاً رد کن؛ cs2node هنگام اولین اجرا SteamCMD را آماده می‌کند. اگر خطای loader یا shared library گرفتی، نصب cs2node را شروع نکن.

## 3. واردکردن Egg کامل رسمی در Pterodactyl

این مرحله در مرورگر Windows انجام می‌شود:

1. وارد Panel خودت شو و به **Admin → Nests** برو.
2. Nest مناسب CS2/Source را باز کن و **Import Egg** را انتخاب کن.
3. این URL رسمی را در بخش Import قرار بده:

~~~text
https://raw.githubusercontent.com/K4ryuu/CS2-Egg-Go/main/pterodactyl/kitsunelab-cs2-go-egg.json
~~~

4. Import را انجام بده و وجود Egg کامل **KitsuneLab CS2 Go @ K4ryuu** را تأیید کن.
5. از Egg کامل استفاده کن، نه standalone Egg؛ نسخهٔ کامل برای handshake با cs2node لازم است.

معیار قبولی: Egg در Panel قابل انتخاب باشد و Docker image پیش‌فرض آن `ghcr.io/k4ryuu/cs2-egg-go:stable` باشد.

## 4. ساخت Instance آزمایشی اول

در **Admin → Servers → Create Server** یک Instance بساز:

| فیلد | مقدار آغازین |
|---|---|
| Server Name | نام یکتای خودت |
| Node | Node موردنظر |
| Default Allocation | Allocation آزاد واقعی |
| Additional Allocations | خالی برای آزمون اول |
| Memory | 3072 MiB برای شروع |
| CPU Limit | مقدار سازگار با ظرفیت Node؛ برای تست می‌توان 200% در نظر گرفت |
| Disk Space | 40960 MiB تا قبل از اثبات VPK Sync |
| Docker Image | `ghcr.io/k4ryuu/cs2-egg-go:stable` |
| Start after install | خاموش |

در Startup، Map آزمایشی را تنظیم کن. اگر GSLT لازم است، آن را فقط در فیلد Panel وارد کن و در مستندات ذخیره نکن.

**Create کن، ولی سرور را Start نکن.** تا تأیید Shared Base، آن را Reinstall یا Delete نکن.

## 5. نصب cs2node — فرمان دقیق

این بخش، فرمان نصب اصلی است. آن را روی Debian host اجرا کن، نه داخل Container:

~~~bash
curl -fsSL \
  https://github.com/K4ryuu/CS2-Egg-Go/releases/latest/download/cs2node_linux_amd64 \
  -o /tmp/cs2node

chmod +x /tmp/cs2node
file /tmp/cs2node
sudo /tmp/cs2node install
~~~

در Installer تعاملی:

- برای نصب تازه `y` را انتخاب کن.
- کانال `stable` را انتخاب کن.
- خودکارسازی Update باینری را مطابق سیاستت انتخاب کن.
- برای نصب اول از `--yes` استفاده نکن؛ باید Wizard را ببینی و Moduleها را آگاهانه تنظیم کنی.

معیار قبولی: Installer اعلام کند باینری در `/usr/local/bin/cs2node`، تنظیمات در `/etc/cs2node/config.json` و سرویس در `cs2node.service` نصب شده است.

اگر باینری دریافت نشد، قبل از اجرا وضعیت اینترنت/DNS و URL رسمی را بررسی کن. اگر Installer در مرحلهٔ SteamCMD خطای `cannot execute: required file not found` یا exit 127 داد، به بخش 2 برگرد.

## 6. پاسخ‌های پیشنهادی Wizard

این جدول‌ها پیشنهاد شروع هستند، نه مقادیر اجباری برای هر محیط. در پایان Summary را مرور کن؛ اگر مقدار ناخواسته‌ای دیدی، نصب را تأیید نکن.

### 6.1 Node

| Prompt | پیشنهاد |
|---|---|
| Proceed? | `y` |
| Update channel | `stable` |
| Self-update automatically | مطابق سیاست نگهداری تو؛ معمولاً `y` |

### 6.2 VPK Sync

| Prompt | پیشنهاد |
|---|---|
| Enable vpksync? | `y` |
| SteamCMD directory | `/root/steamcmd` |
| Central CS2 install directory | `/srv/cs2-shared` |
| VPK delivery method | `symlink` |
| Parallel pushes | `8` |
| Restart after CS2 update | `y` |
| Restart policy | `empty` |
| Maximum delay | طبق نیاز نگهداری تو؛ نمونهٔ FragCity: 2 ساعت |
| In-game warning | طبق نیاز تو؛ نمونهٔ FragCity: 10 دقیقه |
| Validate | `n` برای Update معمول |
| Update check interval | طبق سیاستت؛ نمونهٔ FragCity: 30 دقیقه |

روش `symlink` به Linux kernel نسخهٔ 5.2 یا بالاتر نیاز دارد. `restart_policy=empty` یعنی پس از Update، daemon تا خالی‌شدن سرور یا رسیدن مهلت نهایی صبر می‌کند.

### 6.3 سایر Moduleها

برای اثبات اولیه، فقط Moduleهای لازم را روشن کن. پیش‌فرض‌ها ممکن است `y` باشند؛ Enter خالی را بدون بررسی نزن.

| Module | انتخاب پیشنهادی برای شروع |
|---|---|
| guard | `n`؛ جداگانه ارزیابی شود |
| alerts | اختیاری؛ فقط اگر webhook داری و دسترسی شبکه‌اش تأیید شده |
| addoncache | اختیاری؛ برای Cache نسخه‌های frameworkها در سطح Node |
| workshop | `y` اگر Cache مشترک Workshop می‌خواهی |
| backup | اختیاری؛ ابتدا ظرفیت و retention را تعیین کن |
| cleanup | اختیاری؛ قوانین حذف فایل را پیش از فعال‌سازی بخوان |
| crashes | اختیاری؛ برای نگهداری Crash bundle |
| consolelog | اختیاری؛ به ظرفیت لاگ توجه کن |
| metrics | اختیاری؛ آدرس پیش‌فرض `127.0.0.1:9151` فقط روی خود میزبان قابل دسترسی است |

اگر Workshop روشن است، مسیر `/srv/cs2-workshop` را انتخاب کن. `keep_days=0` یعنی نسخه‌های بدون استفاده بدون محدودیت زمانی حفظ شوند.

قبل از تأیید Summary مطمئن شو `vpksync` روشن، `cs2_dir=/srv/cs2-shared` و روش `symlink` است. URL محرمانهٔ webhook را در GitHub یا لاگ عمومی نگذار.

## 7. بررسی سرویس و شروع دانلود مرکزی

پس از پایان Wizard، سرویس را بررسی کن:

~~~bash
echo "=== Enabled and active ==="
sudo systemctl is-enabled cs2node
sudo systemctl is-active cs2node
sudo systemctl status cs2node --no-pager

echo
echo "=== Status ==="
sudo cs2node status

echo
echo "=== Doctor ==="
sudo cs2node doctor
~~~

معیار اولیه: سرویس `enabled` و `active` باشد. ممکن است `doctor` در اولین Update هنوز نبودن Base را گزارش کند؛ تا پایان دانلود این وضعیت به معنی قبولی Base نیست.

برای دیدن لاگ زنده:

~~~bash
sudo journalctl -u cs2node -f
~~~

برای خروج از لاگ زنده `Ctrl+C` بزن؛ این کار daemon را متوقف نمی‌کند. در اولین اجرای vpksync، cs2node باید SteamCMD را آماده کند و CS2 را در `/srv/cs2-shared` Update کند. سرویس را بی‌دلیل Restart نکن.

### 7.1 معیار قبولی Base مرکزی

پس از اتمام Update، اجرا کن:

~~~bash
BASE="/srv/cs2-shared"

echo "=== Manifest ==="
if sudo test -s "$BASE/steamapps/appmanifest_730.acf"; then
  sudo grep -E '"(appid|buildid|StateFlags)"' "$BASE/steamapps/appmanifest_730.acf"
else
  echo "Manifest not present"
fi

echo
echo "=== Game size ==="
sudo du -sh "$BASE/game" 2>/dev/null || true

echo
echo "=== VPK count ==="
sudo find "$BASE/game" -type f -name '*.vpk' 2>/dev/null | wc -l

echo
echo "=== Free disk ==="
df -hT /

echo
echo "=== Doctor and status ==="
sudo cs2node doctor
sudo cs2node status
~~~

Base فقط وقتی آماده است که Manifest معتبر با `appid=730` و Build ID واقعی وجود داشته باشد، فایل‌های بازی/VPK در درخت نهایی حاضر باشند و `doctor/status` نبودن Base را گزارش نکند. وجود پوشهٔ خالی کافی نیست.

### 7.2 اگر Base هنوز خالی است یا دانلود کامل به نظر نمی‌رسد

سرور بازی را Start نکن. چیزی را حذف نکن. این بلوک فقط‌خواندنی است:

~~~bash
BASE="/srv/cs2-shared"

echo "=== Recent daemon logs ==="
sudo journalctl -u cs2node -n 120 --no-pager -o short-iso

echo
echo "=== SteamCMD processes ==="
ps -eo pid,etime,stat,%cpu,%mem,args |
  grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true

echo
echo "=== Directory sizes ==="
sudo du -sh /root/steamcmd /root/Steam "$BASE" 2>/dev/null || true
sudo du -xhd2 "$BASE" 2>/dev/null | sort -h | tail -n 40

echo
echo "=== Steam staging directories ==="
sudo find "$BASE/steamapps" -maxdepth 4 -type d -print 2>/dev/null | head -n 100

echo
echo "=== Steam log tails ==="
for log in /root/Steam/logs/content_log.txt /root/Steam/logs/stderr.txt /root/Steam/logs/connection_log.txt; do
  if sudo test -f "$log"; then
    echo "=== $log ==="
    sudo tail -n 40 "$log"
  fi
done
~~~

تفسیر:

- اگر SteamCMD فعال است و `steamapps/downloading/730` حجم می‌گیرد، منتظر بمان؛ فایل‌ها هنوز لزوماً به `game/` نهایی منتقل نشده‌اند.
- اگر پردازش فعال نیست و Manifest نهایی/Build ID معتبر وجود ندارد، علت را از Journal و لاگ‌های Steam بررسی کن.
- هم‌زمان با نوشتن SteamCMD، WinSCP upload انجام نده و سرویس را Restart/Stop نکن.
- اگر لازم شد انتقال فایل را جایگزین دانلود کنی، ابتدا سرویس را متوقف کن، نبودن همهٔ پردازش‌های SteamCMD را تأیید کن و سپس طبق بخش 10 عمل کن. فایل‌های در حال دانلود را حذف نکن.

## 8. اتصال Instance اول به Shared Base

فقط پس از قبولی بخش 7، از Panel سرور اول را Start کن. در Console دنبال پیام موفق زیر یا معادل دقیقش بگرد:

~~~text
KitsuneLab | OK | Daemon-managed game files, SteamCMD skipped
~~~

سپس تأیید کن:

- Map با موفقیت Load می‌شود.
- سرور Crash/Restart loop ندارد.
- `sudo cs2node status` سرور را شناسایی می‌کند.
- Stop/Start دوباره هم به Shared Base متصل می‌شود.
- تنظیمات writable مانند cfg و addons مختص همان Instance می‌مانند.

اگر پیام daemon failure یا نبودن VPK دیدی، قبولی محسوب نمی‌شود؛ `sudo cs2node doctor`، `sudo cs2node status` و Journal را بررسی کن.

## 9. ساخت Instance دوم و اثبات Multi Instance

بعد از قبولی کامل Instance اول:

1. از Panel یک Server جدید روی همان Node بساز.
2. Allocation متفاوت و آزاد اختصاص بده.
3. همان Egg کامل و Image پایدار را انتخاب کن.
4. سرور دوم را Start کن و در Console پیام daemon-managed/SteamCMD skipped را بررسی کن.
5. `sudo cs2node status` و `df -hT /` را قبل و بعد مقایسه کن.
6. هر دو Instance را جداگانه Stop/Start کن و استقلال cfg، map، addons و تنظیماتشان را تأیید کن.

**قبولی Multi Instance:** هر دو سرور بالا می‌آیند، VPKهای پایه را از Base مرکزی می‌گیرند، پورت‌های مستقل دارند و فایل‌های تنظیماتی writable بین آن‌ها مشترک نیست. تا آن زمان محدودیت دیسک سرور دوم را کم نکن و پلاگین‌های اختصاصی اضافه نکن.

## 10. انتقال کنترل‌شدهٔ VPKهای بازی با WinSCP

این روش جایگزین دانلود نیست مگر آن‌که Base به‌درستی reconcile شود. فایل‌های Windows را به‌عنوان Linux runtime استفاده نکن؛ فقط assetهایی را منتقل کن که ساختار و سازگاری آن‌ها تأیید شده است. SteamCMD باید در پایان Base را بررسی کند.

### 10.1 ابتدا نوشتن را متوقف کن

1. تمام CS2 Instanceهای Node را Offline نگه دار.
2. daemon را متوقف کن:

~~~bash
sudo systemctl stop cs2node
sudo systemctl is-active cs2node || true
ps -eo pid,etime,args | grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true
~~~

3. اگر هر پردازش SteamCMD هنوز زنده است، **آپلود را شروع نکن**؛ ابتدا وضعیت آن را بررسی کن و تا پایان/توقف کنترل‌شده صبر کن.
4. مطمئن شو هیچ فرایند دیگری در `/srv/cs2-shared` نمی‌نویسد.

### 10.2 فایل‌ها را به Staging منتقل کن

در WinSCP با راهنمای مستقل WinSCP به Home حساب عادی وصل شو. فایل‌های انتخاب‌شده را ابتدا به مسیری مثل:

~~~text
/home/USERNAME/cs2-staging/
~~~

منتقل کن؛ `USERNAME` را با حساب واقعی جایگزین کن. فضای staging باید کافی باشد. مسیر بازی ویندوز را مستقیماً به مسیر لینوکس نچسبان؛ پوشه‌های top-level ممکن است ساختار متفاوت داشته باشند.

### 10.3 بررسی و ادغام

قبل از انتقال از Windows، مشخص کن هر فایل دقیقاً در کدام مسیر نسبی مقصد قرار می‌گیرد. فایل‌های اجرایی Linux، کتابخانه‌ها، Manifest و تنظیمات per-instance را از نسخهٔ Windows overwrite نکن. فایل‌های VPK را فقط با حفظ مسیر نسبی تأییدشده وارد کن؛ هیچ فرمان `rsync --delete` یا پاک‌سازی کلی اجرا نکن.

بعد از انتقال، daemon را اجرا کن:

~~~bash
sudo systemctl start cs2node
sudo systemctl status cs2node --no-pager
sudo journalctl -u cs2node -n 100 --no-pager
sudo cs2node doctor
sudo cs2node status
~~~

سپس معیارهای بخش 7 را دوباره اجرا کن. اگر Build ID واقعی و Base معتبر حاصل نشد، سرور را Start نکن.

## 11. Workshop Cache — مسیر درست و روش واردکردن

Workshop Cache ماژول مستقلی است؛ فایل‌های Workshop را با Base اصلی بازی مخلوط نکن.

### 11.1 منبع را شناسایی کن

ابتدا مسیر واقعی Workshop ویندوز را مشخص کن و فایل ACF مربوط به App Workshop را پیدا کن. از نام پوشه یا حجم فایل به‌تنهایی ID/version نساز.

روی Node این مسیرها را بررسی کن:

~~~bash
sudo find /var/lib/pterodactyl/volumes -type f -name 'appworkshop_730.acf' -print
sudo find /srv/cs2-workshop -maxdepth 4 -type f -name 'meta.json' -print 2>/dev/null | head -n 50
~~~

اگر ACF موجود نیست، هنوز Workshop را وارد Cache مرکزی نکن؛ ابتدا منبع و metadata را مشخص کن.

### 11.2 واردکردن

در این مرحله، از ساختار مورد انتظار ماژول استفاده کن و فایل‌ها را به‌صورت staging منتقل کن. برای هر آیتم باید شناسه و نسخه از metadata معتبر استخراج شود؛ فایل خام را مستقیم داخل `/srv/cs2-workshop` نریز. قبل از نوشتن، daemon و فرایند دانلود Workshop را متوقف و نبودن نویسندهٔ فعال را تأیید کن.

پس از Import، ساختار Cache و فایل‌های metadata را بررسی کن و سپس `sudo cs2node workshop` را اجرا کن. اگر نسخهٔ ماژول با ساختار فایل‌های موجود همخوان نیست، انتقال را متوقف کن و مستندات رسمی همان نسخه را بخوان.

### 11.3 تأیید Cache

~~~bash
sudo cs2node workshop
sudo cs2node doctor
sudo cs2node status
~~~

معیار قبولی: ماژول آیتم‌های Cache شده را بشناسد، metadata معتبر باشد و هیچ Instanceای به مسیر نادرست اشاره نکند.

## 12. بعد از قبولی Multi Instance: CounterStrikeSharp و پلاگین‌ها

فقط پس از اثبات Base، Instance اول و Instance دوم سراغ framework/plugin برو. نسخه‌های رسمی و سازگار را از منبع اصلی دریافت کن. cfg، addons و configs نوشتنی باید per-instance باقی بمانند؛ shared base را برای نصب پلاگین تغییر نده. هیچ‌کدام از مراحل این آموزش به‌تنهایی مجوز تغییر مخزن KUS یا اجرای اسکریپت‌های آن نیست.

## 13. عیب‌یابی سریع

| نشانه | اقدام |
|---|---|
| `cannot execute: required file not found` یا exit 127 | بخش 2؛ معماری i386 و Runtimeها را بررسی کن |
| `cs2node` فعال است اما central build خالی است | بخش 7.2؛ پردازش، Journal، staging و logهای Steam را بررسی کن |
| SteamCMD فعال و downloading در حال رشد است | صبر کن؛ Restart یا WinSCP هم‌زمان انجام نده |
| پیام `Daemon-managed game files, SteamCMD skipped` دیده نمی‌شود | `doctor`، `status` و Journal را بررسی کن؛ سرور را آماده حساب نکن |
| Webhook Discord وصل نمی‌شود | مشکل را جدا از VPK Sync بررسی کن؛ URL محرمانه را منتشر نکن |
| می‌خواهی انتقال فایل را انجام دهی | ابتدا همهٔ نویسنده‌ها را متوقف کن؛ سپس بخش 10 یا 11 را دنبال کن |

## 14. چک‌لیست پایان نصب

- [ ] Runtimeهای i386 قبل از نصب/اولین Update آماده و SteamCMD قابل اجراست.
- [ ] Egg کامل K4ryuu در Panel Import شده است.
- [ ] `cs2node` نصب، enabled و active است.
- [ ] Manifest مرکزی `appid=730` و Build ID واقعی دارد.
- [ ] VPKهای Base حاضرند و `cs2node doctor/status` خطای Base نمی‌دهند.
- [ ] Instance اول پیام daemon-managed/SteamCMD skipped نشان می‌دهد.
- [ ] Instance دوم نیز موفق است و Allocation جدا دارد.
- [ ] cfg/addons/configهای writable بین Instanceها مشترک نیستند.
- [ ] Workshop Cache فقط با metadata معتبر و در مسیر خودش وارد شده است.
- [ ] تا قبل از قبولی Multi Instance، پلاگین‌های اختصاصی اضافه نشده‌اند.

## منابع رسمی K4ryuu

- [مخزن CS2-Egg-Go](https://github.com/K4ryuu/CS2-Egg-Go)
- [Egg installation](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md)
- [Node daemon](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md)
- [VPK Sync module](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md)
- [Workshop module](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/workshop.md)
- [Node configuration reference](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/node-config.md)

## 15. ادامهٔ اجرای زنده

برای نصب روی Node دیگر از همین آموزش استفاده کن و مقادیر محیطی را جایگزین کن. وضعیت فعلی یک اجرای خاص، IP/hostname آن و خروجی تشخیصی آن را در [Checkpoint عملیاتی دانلود cs2node](https://github.com/larnzs/linux-node/blob/main/cs2node-download-current-checkpoint.md) دنبال کن؛ گزارش اجرای زنده جایگزین مراحل آموزشی این فایل نیست.
