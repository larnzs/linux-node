# Runbook نصب K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop — با دروازهٔ ظرفیت و Backup

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

## 1. پیش‌نیازها، مقادیر محیطی و برنامهٔ ظرفیت

این آموزش برای Debian 13 amd64 با Pterodactyl Panel، Docker و Wings فعال است. تمام فرمان‌ها روی خود Debian host اجرا می‌شوند، مگر آن‌که صریحاً گفته شود در Panel، Windows یا داخل Container اجرا شوند.

### 1.1 ظرفیت قابل‌گسترش است؛ اما فضای خالی را زیر نظر داشته باش

در آخرین بررسی این VM، دیسک مجازی 150 GB، filesystem ریشه حدود 142 GB و فضای آزاد حدود 130 GB بود. VM با LVM نصب شده است؛ بنابراین پس از بزرگ‌کردن Virtual Disk در VMware می‌توان پارتیشن، Physical Volume، Logical Volume و filesystem را گسترش داد. **لازم نیست فقط به‌خاطر عدد 200 GB، پیش از شروع همه‌چیز ظرفیت را افزایش بدهی.**

Shared CS2 Base حدود چند ده گیگابایت فضا نیاز دارد و می‌تواند با ظرفیت فعلی شروع شود. Workshopهای متعدد و Backupهای محلی در طول زمان فضا مصرف می‌کنند؛ اگر از قبل می‌دانی بلافاصله مجموعهٔ بسیار بزرگی از Workshopها را وارد می‌کنی، قبل از آن مرحله افزایش دیسک منطقی است.

قواعد این بخش:
1. پیش از دانلود و بعد از آن `df -hT /` و `df -hT /srv` را بررسی کن. اگر `/srv` روی همان filesystem ریشه باشد، هر دو یک ظرفیت را نشان می‌دهند.
2. هنگامی که فضای آزاد به حدود 25–30 GB نزدیک شد، قبل از واردکردن Workshop جدید یا ساخت Backupهای بیشتر، دیسک VM را Extend کن. این آستانه پیشنهادی محافظه‌کارانه است، نه محدودیت فنی ثابت.
3. اگر ظرفیت را در VMware افزایش دادی، پیش از اجرای هر دستور resize، ساختار دیسک را دوباره با `lsblk`, `pvs`, `vgs`, `lvs` و `df -hT /` بررسی کن. نام `/dev/sda5` در این VM فعلی است و نباید برای VM دیگری بدون بازبینی کپی شود.
4. این راهنما هیچ فرمانی برای Format کردن یا حذف پارتیشن اجرا نمی‌کند. اگر قرار است دیسک دادهٔ جدید اضافه کنی، ابتدا تصمیم بگیر Shared Base و volumeها روی کدام filesystem باشند؛ mount point باید قبل از دانلود نهایی و ثابت باشد.

~~~bash
echo "=== RAM and swap ==="
free -h
swapon --show

echo
echo "=== Block devices and LVM ==="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
sudo pvs
sudo vgs
sudo lvs -a -o +devices

echo
echo "=== Filesystems ==="
df -hT /
df -hT /srv
df -ih /
findmnt -T /
findmnt -T /srv
~~~

برای دو Instance CS2، حدود 3.8 GiB RAM فعلی احتمالاً محدودکننده‌تر از فضای دیسک در مرحلهٔ آغازین است. پس از آماده‌شدن Base، مصرف واقعی RAM و Swap را هنگام تست Multi Instance بسنج؛ اگر VM هنوز حدود 4 GiB دارد، پیش از اجرای هم‌زمان دو سرور بهتر است RAM را نیز افزایش بده. پیشنهاد شروع برای هدف دو Instance حدود 8 GiB است، اما مصرف نهایی به پلاگین‌ها، نقشه و Workshop بستگی دارد.

### 1.2 پیش‌نیازهای فنی

- Debian 13 amd64، اینترنت خروجی و دسترسی مدیریتی root/sudo.
- Panel از HTTPS در دسترس باشد؛ Node در Panel برابر Online باشد؛ Docker و Wings فعال باشند.
- یک UDP Allocation واقعی و آزاد برای اولین سرور آزمایشی.
- سرورهای بازی در زمان آماده‌سازی Base خاموش بمانند.
- هیچ ابزار دیگری هم‌زمان روی `/srv/cs2-shared` بازی را Update نکند.
- فضای Backupهای محلی در برنامهٔ ظرفیت منظور شده باشد.

## 2. پیش‌نیاز الزامی Debian amd64: Runtime سی‌ودو بیتی

SteamCMD ممکن است از باینری 32-bit استفاده کند؛ داشتن سیستم‌عامل amd64 به‌تنهایی وجود loader و کتابخانه‌های i386 را تضمین نمی‌کند. این مرحله را قبل از نصب cs2node و اولین Update مرکزی انجام بده.

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

**معیار قبولی:** فرمان‌ها بدون خطا تمام شوند و i386 در خروجی foreign architectures دیده شود.

اگر فایل SteamCMD موجود بود و هیچ Update/دانلودی توسط cs2node در حال اجرا نبود، آزمون زیر را اجرا کن:

~~~bash
if sudo test -x /root/steamcmd/steamcmd.sh; then
  sudo /root/steamcmd/steamcmd.sh +quit
else
  echo "SteamCMD not initialized yet; cs2node will prepare it on first use."
fi
~~~

معیار قبولی اجرای SteamCMD، خروجی موفق مشابه Loading Steam API...OK و Unloading Steam API...OK است. این فقط قابل اجرا بودن SteamCMD را تأیید می‌کند، نه دانلود موفق CS2 را. اگر بعد از نصب cs2node خطای loader یا shared library گرفتی، قبل از Restart/تکرار نصب مطمئن شو هیچ SteamCMD فعالی وجود ندارد، سپس آزمون را اجرا کن؛ SteamCMD دستی را هم‌زمان با Update فعال cs2node اجرا نکن.

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

در Panel به **Admin → Servers → Create Server** برو و فقط یک Instance آزمایشی بساز. ابتدا مطمئن شو بخش 1.1 ظرفیت کافی را تأیید کرده و Node در Panel Online است.

| فیلد | مقدار آغازین |
|---|---|
| Server Name | نام یکتای خودت |
| Node | Node موردنظر |
| Default Allocation | Allocation آزاد واقعی |
| Additional Allocations | خالی برای آزمون اول |
| Memory | 2048 MiB برای آزمون پایه؛ سپس با اندازه‌گیری تنظیم شود |
| CPU Limit | مطابق ظرفیت Node؛ برای آزمون می‌توان 200% در نظر گرفت |
| Disk Space | 40960 MiB تا قبل از اثبات VPK Sync |
| Docker Image | ghcr.io/k4ryuu/cs2-egg-go:stable |
| Start after install | خاموش |

با حدود 8 GiB RAM اختصاص‌یافته به VM، برای اولین آزمون 2048 MiB شروع محافظه‌کارانه‌ای است؛ سرورهای دارای پلاگین و Workshop سنگین ممکن است 4 GiB یا بیشتر بخواهند. قبل از ساخت Instance دوم، مصرف RAM و Swap را هنگام تست واقعی اندازه بگیر و برای Debian/Panel/Docker/Wings هم حافظه رزرو کن.

در Startup، Map آزمایشی را تنظیم کن. اگر GSLT لازم است، آن را فقط در فیلد Panel وارد کن و در مستندات ذخیره نکن.

**Create کن، ولی سرور را Start نکن.** تا تأیید Shared Base آن را Reinstall یا Delete نکن. اگر نصب سرور خودکار شروع شد، صبر کن به پایان برسد، سپس مطمئن شو سرور خاموش است.

## 5. نصب cs2node — فرمان دقیق

این دستورها روی Debian host اجرا می‌شوند، نه داخل Container. پیش‌نیازها: ظرفیت بخش 1.1 تأیید شده، i386 runtime بخش 2 نصب است، Egg کامل Import شده و اولین Instance ساخته اما خاموش مانده است.

اگر /usr/local/bin/cs2node از قبل وجود دارد، این بخش را تکرار نکن؛ ابتدا وضعیت موجود را بررسی کن. نصب مجدد cs2node می‌تواند daemon را Restart کند.

~~~bash
set -eu

if sudo test -x /usr/local/bin/cs2node; then
  echo "STOP: cs2node is already installed. Inspect it instead of reinstalling."
  sudo /usr/local/bin/cs2node version || true
  sudo systemctl status cs2node --no-pager -l || true
  exit 1
fi

curl -fsSL \
  https://github.com/K4ryuu/CS2-Egg-Go/releases/latest/download/cs2node_linux_amd64 \
  -o /tmp/cs2node

chmod +x /tmp/cs2node
file /tmp/cs2node
sha256sum /tmp/cs2node
sudo /tmp/cs2node install
~~~

در Installer تعاملی:
- برای نصب تازه y را انتخاب کن.
- کانال stable را انتخاب کن.
- خودکارسازی Update باینری را مطابق سیاست نگهداری FragCity تنظیم کن؛ پروفایل این محیط self-update را روشن نگه می‌دارد.
- از --yes استفاده نکن؛ Wizard را بخوان و ماژول‌ها را آگاهانه تنظیم کن.

معیار قبولی: Installer باینری را در /usr/local/bin/cs2node، تنظیمات را در /etc/cs2node/config.json و سرویس را در cs2node.service نصب کند.

اگر باینری دریافت نشد، URL رسمی، DNS و اینترنت خروجی را بررسی کن. اگر SteamCMD خطای cannot execute: required file not found یا exit 127 داد، نصب را تکرار نکن؛ به بخش 2 برگرد و loader/i386 runtime را بررسی کن.

## 6. پاسخ‌های پیشنهادی Wizard

این پروفایل مطابق تنظیمات انتخاب‌شده برای FragCity است. مقدارها را قبل از تأیید Summary مرور کن؛ برای فضای Workshop و Backup باید ظرفیت کافی داشته باشی.

### 6.1 Node

| Prompt | تنظیم FragCity |
|---|---|
| Proceed? | y |
| Update channel | stable |
| Self-update automatically | y |

### 6.2 VPK Sync

| Prompt / option | تنظیم FragCity |
|---|---|
| Enable vpksync | y |
| SteamCMD directory | /root/steamcmd |
| Central CS2 install directory | /srv/cs2-shared |
| VPK delivery method | symlink |
| Parallel pushes | 8 |
| Restart after CS2 update | y |
| Restart policy | empty |
| Maximum delay | 2 hours |
| In-game warning | 10 minutes |
| Validate | n برای Update معمول |
| Update check interval | 30 minutes |

روش symlink به Linux kernel نسخهٔ 5.2 یا جدیدتر نیاز دارد. restart_policy=empty یعنی بعد از Update، daemon تا خالی‌شدن سرور یا رسیدن حداکثر مهلت صبر می‌کند.

### 6.3 سایر Moduleها

| Module | انتخاب/مقدار FragCity | ملاحظه |
|---|---|---|
| guard | n | فعلاً غیرفعال؛ در این نصب انتخاب شده است |
| alerts | enabled | Webhook را فقط داخل Wizard وارد کن و هرگز در README/چت ذخیره نکن |
| addoncache | enabled | refresh interval = 30 minutes |
| workshop | enabled | dir = /srv/cs2-workshop، seed/all = yes، keep_days = 0 |
| backup | enabled | dir = /srv/cs2-backups، hour = 5 به وقت Asia/Tehran، keep_days = 14، keep_count = 7 |
| cleanup | enabled | قوانین پیش‌فرض را بعداً مرور کن و مطمئن شو فایل‌های لازم را حذف نمی‌کنند |
| crashes | اختیاری | برای نگهداری crash bundle مفید است |
| consolelog | اختیاری | مصرف دیسک را در نظر بگیر |
| metrics | اختیاری | پیش‌فرض 127.0.0.1:9151 را عمومی نکن |

**هشدار فضای دیسک:** keep_days=0 در Workshop به معنی نگه‌داشتن نسخه‌های بدون استفاده بدون محدودیت زمانی است؛ cache می‌تواند رشد کند. Backup روزانهٔ 7 نسخه نیز فضا مصرف می‌کند. چون این مسیرها در این نصب روی همان filesystem قرار دارند، df -hT را مرتب بررسی کن. اگر Cache/Backup ظرفیت را تهدید می‌کند، retention را آگاهانه تغییر بده؛ هیچ Cleanup کلی یا حذف پوشه‌ای را کورکورانه اجرا نکن.

قبل از تأیید Summary مطمئن شو vpksync روشن، cs2_dir برابر /srv/cs2-shared و روش symlink است. برای Workshop نیز /srv/cs2-workshop را انتخاب کن.

## 7. بررسی سرویس و شروع دانلود مرکزی

پس از پایان Wizard، سرویس را بررسی کن. اگر اولین اجرای daemon دانلود را شروع کرد، درحالی‌که فضای آزاد واقعی هنوز از شرط بخش 1.1 کمتر است، سرور را Start نکن و ابتدا Storage را توسعه بده.

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

معیار اولیه: سرویس enabled و active باشد. در اولین اجرای daemon ممکن است Base هنوز وجود نداشته باشد؛ این وضعیت به‌تنهایی قبولی Base نیست.

برای لاگ زنده:

~~~bash
sudo journalctl -u cs2node -f
~~~

برای خروج از لاگ زنده Ctrl+C بزن؛ این کار daemon را متوقف نمی‌کند. در اولین اجرای vpksync، cs2node باید SteamCMD را آماده کند و CS2 را در /srv/cs2-shared Update کند. سرویس را بی‌دلیل Restart نکن.

**پیش از انتظار برای دانلود، دوباره ظرفیت را بررسی کن:**

~~~bash
df -hT /
df -hT /srv
df -ih /
free -h
~~~

اگر /srv روی همان filesystem ریشه باشد، df -hT /srv و df -hT / فضای یکسانی نشان می‌دهند. حدود 130 GB فضای آزاد برای شروع Shared Base کافی می‌تواند باشد، اما لزوماً برای Base به‌علاوهٔ مجموعهٔ بزرگ Workshop و چند Backup کافی نیست. دانلود را با پایش مداوم فضای آزاد انجام بده و پیش از نزدیک‌شدن فضای آزاد به حدود 25–30 GB، VM را Extend کن.

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
df -hT /srv

echo
echo "=== Doctor and status ==="
sudo cs2node doctor
sudo cs2node status
~~~

Base فقط وقتی آماده است که Manifest معتبر با appid=730 و Build ID واقعی وجود داشته باشد، فایل‌های بازی/VPK در درخت نهایی حاضر باشند و doctor/status نبودن Base را گزارش نکنند. وجود پوشهٔ خالی کافی نیست.

### 7.2 اگر Base هنوز خالی است یا دانلود کامل به نظر نمی‌رسد

سرور بازی را Start نکن و چیزی را حذف نکن. این بلوک فقط‌خواندنی است:

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
- اگر SteamCMD فعال است و steamapps/downloading/730 رشد می‌کند، منتظر بمان؛ فایل‌ها هنوز لزوماً به game نهایی منتقل نشده‌اند.
- اگر پردازش فعال نیست و Manifest نهایی/Build ID معتبر وجود ندارد، Journal و لاگ‌های Steam را بررسی کن.
- هم‌زمان با نوشتن SteamCMD، WinSCP upload انجام نده و سرویس را Restart/Stop نکن.
- اگر در نصب amd64 خطای loader رخ داد، فقط وقتی Update فعال نیست و پردازش SteamCMD وجود ندارد، فرمان زیر را اجرا کن:

~~~bash
sudo /root/steamcmd/steamcmd.sh +quit
~~~

اگر موفق شد، سپس در صورت نیاز سرویس cs2node را دوباره فعال کن. اگر خطا ادامه داشت، نصب را کورکورانه تکرار نکن.

اگر تصمیم گرفتی انتقال دستی انجام بدهی، ابتدا سرویس را متوقف کن، نبودن همهٔ پردازش‌های SteamCMD را تأیید کن، و سپس طبق بخش 10 عمل کن. فایل‌های در حال دانلود را پاک نکن.

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

- [ ] قبل از Download، فضای آزاد حداقل متناسب با برنامهٔ FragCity بررسی شده؛ برای این برنامه حدود 200 GB فضای آزاد با حاشیهٔ امن هدف است.
- [ ] RAM VM متناسب با تست انتخاب شده؛ برای هدف دو Instance پیشنهاد شروع 8 GiB است.
- [ ] Runtimeهای i386 قبل از اولین Update آماده و SteamCMD قابل اجراست.
- [ ] Egg کامل K4ryuu در Panel Import شده است.
- [ ] cs2node نصب، enabled و active است.
- [ ] Manifest مرکزی appid=730 و Build ID واقعی دارد.
- [ ] VPKهای Base حاضرند و doctor/status خطای Base نمی‌دهند.
- [ ] Instance اول پیام daemon-managed/SteamCMD skipped نشان می‌دهد.
- [ ] Instance دوم نیز موفق است و Allocation جدا دارد.
- [ ] cfg/addons/configهای writable بین Instanceها مشترک نیستند.
- [ ] Workshop Cache فقط با metadata معتبر و در مسیر خودش وارد شده است.
- [ ] Retention مربوط به Workshop و Backup با فضای آزاد واقعی سازگار است.
- [ ] تا قبل از قبولی Multi Instance، پلاگین‌های اختصاصی اضافه نشده‌اند.

## منابع رسمی K4ryuu

- [مخزن CS2-Egg-Go](https://github.com/K4ryuu/CS2-Egg-Go)
- [Egg installation](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md)
- [Node daemon](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md)
- [VPK Sync module](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md)
- [Workshop module](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/workshop.md)
- [Node configuration reference](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/node-config.md)

## 15. ادامهٔ اجرای زنده

برای ادامهٔ اجرای زنده روی همین Node، قبل از هر مرحله از checkpoint عملیاتی استفاده کن و از دوباره‌اجرای بلوک‌های نصب خودداری کن:
[Checkpoint عملیاتی دانلود cs2node](https://github.com/larnzs/linux-node/blob/main/cs2node-download-current-checkpoint.md)

منابع رسمی و نسخه‌های جاری:
- [CS2-Egg-Go](https://github.com/K4ryuu/CS2-Egg-Go)
- [Egg installation](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md)
- [Node daemon](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md)
- [VPK Sync](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md)
- [Workshop](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/workshop.md)
- [Node config reference](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/node-config.md)

## 16. Backup مستقل VM پس از اثبات Multi Instance

این کار را فقط پس از قبولی همهٔ معیارهای بخش 14 انجام بده. قبل از آن، کل VM هنوز به‌عنوان تصویر نهایی قابل‌بازیابی محسوب نمی‌شود.

1. از Panel، همهٔ CS2 Instanceها را به‌صورت کنترل‌شده Stop کن. مطمئن شو SteamCMD/Update در حال نوشتن نیست و cs2node وضعیت پایدار دارد.
2. از کنسول Debian، VM را با خاموش‌کردن امن سیستم خاموش کن؛ از Power Off ناگهانی در VMware استفاده نکن.
3. در VMware Snapshot Manager، هر زنجیرهٔ Snapshot را بررسی کن. فایل‌های Snapshot descriptor را دستی پاک نکن. اگر لازم است Consolidate انجام شود، از ابزار خود VMware استفاده کن و مطمئن شو عملیات تمام شده است.
4. از کل پوشهٔ VM کپی بگیر یا OVA خروجی بگیر. فقط فایل descriptor کوچک VMDK را کپی نکن؛ VMX و تمام دیسک‌های وابسته، از جمله هر Data VMDK اضافه، باید در Backup موجود باشند.
5. مقصد باید فضای کافی برای کل دیسک‌ها، Shared Base، Workshop و Backupهای محلی داشته باشد. نسخهٔ کپی‌شده را از نظر اندازه و در صورت امکان SHA-256 بررسی کن.
6. از Backup یک بوت آزمایشی در شبکهٔ ایزوله انجام بده تا IP/hostname یا سرویس‌ها با VM اصلی تداخل نداشته باشند.

### محدودیت مهم Clone

این VM فقط یک تصویر بازیابی از محیط فعلی است، نه یک Node مستقل آمادهٔ روشن‌شدن هم‌زمان. کپی کامل آن شامل دیتابیس و APP_KEY پنل، گواهی‌های TLS، فایل .env، config.yml و هویت Node/Wings خواهد بود. VM اصلی و Clone را هم‌زمان روی شبکهٔ تولیدی با همان hostname/IP/Node identity روشن نکن. برای تبدیل Clone به Node مستقل، ابتدا hostname/IP/DNS/TLS و Node configuration را جداگانه طراحی و بازتولید کن.

فایل Backup شامل اسرار عملیاتی است؛ آن را در محل خصوصی و امن نگه دار. هرگز فایل‌های .env، APP_KEY، config.yml، Tokenها یا GSLT را در GitHub نگذار.
