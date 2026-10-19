# آموزش نصب K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop Cache

این راهنما نصب و راه‌اندازی K4ryuu CS2 Egg-Go را از پیش‌نیازهای Debian تا تأیید Shared Base و Multi Instance آموزش می‌دهد. دستورهای نمونه روی Debian میزبان اجرا می‌شوند، نه داخل Container بازی. مقادیر hostname، IP، دامنه، نام Instance و Allocation مخصوص هر محیط‌اند؛ جدول بخش 1.1 را با مقادیر خودت پر کن و مقادیر نمونه را بدون تطبیق اجرا نکن.

## نقشهٔ اجرا

1. بررسی پیش‌نیازهای Node و آماده‌سازی Debian amd64 برای SteamCMD.
2. واردکردن Egg رسمی K4ryuu و ساخت یک سرور آزمایشی.
3. نصب cs2node با فرمان مشخص و تکمیل Wizard.
4. تأیید دانلود Base مرکزی در مسیر /srv/cs2-shared.
5. اتصال Instance اول به Base و سپس ساخت Instance دوم.
6. در صورت نیاز، انتقال کنترل‌شدهٔ VPKهای بازی و واردکردن Workshop.
7. پس از قبولی Multi Instance، نصب CounterStrikeSharp و پلاگین‌های منتخب.

**تا زمانی که مرحله‌ای تأیید نشده، به مرحلهٔ بعد نرو.** در صورت خطا، فرمان را پشت‌سرهم تکرار نکن؛ متن خطا و وضعیت سرویس را بررسی کن.

## 1. پیش‌نیازها

قبل از شروع، مطمئن شو:

- Debian 13 (Trixie) روی Node نصب شده و دسترسی مدیریتی sudo داری.
- Docker و Wings فعال‌اند و در Panel، Node وضعیت Online دارد.
- فضای آزاد کافی برای Shared Base و Workshop وجود دارد. Base استاندارد CS2 معمولاً حدود 35–40 GB یا بیشتر، بسته به Build/Depot، فضا می‌خواهد؛ محتوای Workshop به این مقدار اضافه می‌شود.
- حداقل یک Allocation آزاد و UDP قابل‌استفاده برای سرور آزمایشی در Panel تعریف شده است.
- هیچ Daemon قدیمی مثل cs2-vpk-daemon یا cs2-guard-daemon هم‌زمان همان فایل‌ها یا پورت‌ها را مدیریت نمی‌کند.
- سرور آزمایشی می‌تواند در زمان راه‌اندازی و آزمایش Offline باشد.

### 1.1 مقادیر نصب خودت را مشخص کن

این جدول را برای محیط خودت پر کن؛ مقادیر FragCity در ستون آخر فقط نمونه‌اند.

| مقدار | از کجا برداشته شود؟ | نمونهٔ FragCity |
|---|---|---|
| Node hostname | نام انتخابی Linux Node | fc-node-01 |
| Node IP | IP رزروشدهٔ Node فعلی، نه IP عمومی حدسی | Clone: 192.168.1.9 |
| Panel URL | آدرس واقعی پنل Pterodactyl تو | https://panel.fragcity.ir |
| Egg | Egg رسمی واردشده در Panel | KitsuneLab CS2 Go @ K4ryuu |
| Server name | نام یکتای Instance اول | fc-cs2-test-01 |
| Game allocation | یک Allocation آزاد واقعی از Panel | UDP 29001 در محیط FragCity |
| CS2 shared path | مسیر مرکزی VPK Sync | /srv/cs2-shared |

مسیرهای /srv/cs2-shared و /srv/cs2-workshop به IP یا hostname وابسته نیستند. Allocation را از پنل انتخاب کن؛ شمارهٔ پورت نمونه را کورکورانه تکرار نکن.

## 2. پیش‌نیاز الزامی Debian amd64: Runtime سی‌ودو بیتی

SteamCMD در Linux amd64 نیز از باینری 32-bit در مسیر linux32/steamcmd استفاده می‌کند. اگر کتابخانه‌ها و loader مناسب نصب نباشند، ممکن است خطای زیر دیده شود:

~~~text
cannot execute: required file not found
steamcmd: exit status 127
~~~

این مرحله را **قبل از نصب cs2node** اجرا کن:

~~~bash
set -eu

ARCH="$(dpkg --print-architecture)"
echo "Host architecture: $ARCH"

if [ "$ARCH" != "amd64" ]; then
  echo "STOP: these instructions expect Debian amd64."
  exit 1
fi

echo
echo "=== Enable i386 multiarch ==="
sudo dpkg --add-architecture i386
sudo apt-get update

echo
echo "=== Install SteamCMD 32-bit runtime libraries ==="
sudo apt-get install -y libc6:i386 libstdc++6:i386 libgcc-s1:i386

echo
echo "=== Confirm foreign architecture ==="
dpkg --print-foreign-architectures
~~~

خروجی باید شامل i386 باشد. این مرحله CS2 را دانلود نمی‌کند و فایل بازی موجود را تغییر نمی‌دهد.

**نکته:** در نصب کاملاً تازه ممکن است /root/steamcmd/steamcmd.sh هنوز ساخته نشده باشد؛ چون cs2node آن را هنگام اولین Update ایجاد می‌کند. اگر مسیر هنوز وجود ندارد، در این مرحله آن را اجرا نکن. بعد از نصب/راه‌اندازی daemon می‌توانی تست SteamCMD را انجام بدهی.

### 2.1 تست SteamCMD در صورت وجود نصب قبلی

اگر SteamCMD قبلاً روی همین Node نصب شده است:

~~~bash
if sudo test -x /root/steamcmd/steamcmd.sh; then
  sudo /root/steamcmd/steamcmd.sh +quit
else
  echo "SteamCMD is not installed yet; cs2node will bootstrap it on first update."
fi
~~~

تست موفق معمولاً خطوط Loading Steam API...OK و Unloading Steam API...OK را نمایش می‌دهد. اگر آزمون یک نصب قبلی خطا داد، اول همان خطا را رفع کن و سپس ادامه بده.

## 3. واردکردن Egg رسمی در Pterodactyl

1. وارد Panel خودت شو.
2. به **Admin → Nests → Import Egg** برو.
3. URL زیر را در فیلد Import قرار بده:

~~~text
https://raw.githubusercontent.com/K4ryuu/CS2-Egg-Go/main/pterodactyl/kitsunelab-cs2-go-egg.json
~~~

4. Nest مناسب CS2/Source موجود را انتخاب کن؛ فقط برای این کار Nest تکراری نساز.
5. Import را کامل کن و مطمئن شو Egg کامل **KitsuneLab CS2 Go @ K4ryuu** موجود است.

برای استفاده از cs2node، از Egg کامل استفاده کن، نه فایل standalone. Egg کامل دارای اتصال daemon است؛ بدون daemon هم می‌تواند مستقل اجرا شود.

## 4. ساخت Instance آزمایشی اول

در **Admin → Servers → Create Server** یک سرور آزمایشی بساز.

| فیلد | مقدار پیشنهادی |
|---|---|
| Server Name | یک نام یکتا مثل cs2-test-01 |
| Node | همان Node که cs2node روی آن نصب می‌شود |
| Default Allocation | یک Allocation آزاد واقعی از Panel |
| Additional Allocations | برای اولین تست خالی |
| Database Limit | 0، اگر برای این سرور Database پنل نیاز نیست |
| Memory | 3072 MiB برای شروع تست |
| CPU Limit | حدود 200% برای تست اولیه؛ ظرفیت واقعی را با آمار اندازه بگیر |
| Disk Space | 40960 MiB تا پیش از تأیید VPK Sync |
| Docker Image | ghcr.io/k4ryuu/cs2-egg-go:stable |
| Start Server when Installed | خاموش |

در Startup، Map را روی de_dust2 نگه دار. برای اتصال عمومی ممکن است به GSLT نیاز داشته باشی؛ Token را در README، لاگ عمومی یا چت ثبت نکن.

سرور را Create کن، ولی هنوز Start نکن. سرور فعلی را برای این کار حذف یا Reinstall نکن.

## 5. نصب cs2node — فرمان دقیق

این فرمان نصب Node daemon است. آن را روی Debian میزبان اجرا کن، نه داخل Container بازی:

~~~bash
curl -fsSL \
  https://github.com/K4ryuu/CS2-Egg-Go/releases/latest/download/cs2node_linux_amd64 \
  -o /tmp/cs2node

chmod +x /tmp/cs2node
file /tmp/cs2node

sudo /tmp/cs2node install
~~~

در پایان باید Installer اعلام کند که Binary در /usr/local/bin/cs2node قرار گرفته، تنظیمات در /etc/cs2node/config.json نوشته شده و سرویس cs2node نصب و راه‌اندازی شده است.

از sudo cs2node install --yes برای نصب اول استفاده نکن؛ این حالت پیش‌فرض همهٔ Moduleها را بدون Wizard می‌پذیرد. Wizard تعاملی را کامل کن.

## 6. پاسخ‌های پیشنهادی Wizard

### 6.1 تنظیم Node

| Prompt | انتخاب پیشنهادی |
|---|---|
| Proceed? | y |
| Update channel | stable |
| Self-update automatically | y |

### 6.2 تنظیم VPK Sync

vpksync را روشن کن. این Module یک CS2 Base کامل روی Node نگه می‌دارد و از طریق Mount فقط‌خواندنی در اختیار هر سرور قرار می‌دهد.

| Prompt | مقدار پیشنهادی |
|---|---|
| Enable vpksync? | y |
| SteamCMD directory | /root/steamcmd |
| Central CS2 install directory | /srv/cs2-shared |
| VPK delivery method | symlink |
| Parallel pushes | 8 |
| Restart servers after CS2 update | y |
| Restart policy | empty |
| Maximum delay before forced restart | 2 ساعت برای پروفایل FragCity؛ در صورت نیاز خودت انتخاب کن |
| In-game warning | 10 دقیقه برای پروفایل FragCity |
| SteamCMD validate | n برای Update معمول؛ validate زمان و شبکه بیشتری مصرف می‌کند |
| Update check interval | 30 دقیقه برای پروفایل FragCity؛ مقدار را آگاهانه انتخاب کن |

symlink به Linux kernel نسخهٔ 5.2 یا بالاتر نیاز دارد. اگر نصب تو Kernel قدیمی دارد، قبل از ادامه مستند رسمی VPK Sync را بررسی کن. restart_policy=empty یعنی پس از Update تا خالی‌شدن سرور یا رسیدن مهلت اجباری صبر می‌شود.

### 6.3 سایر Moduleها

برای اولین اثبات Shared Base، هر Module را آگاهانه روشن/خاموش کن؛ Enter خالی نزن چون پیش‌فرض بعضی گزینه‌ها ممکن است y باشد.

| Module | پیشنهاد برای شروع |
|---|---|
| guard | n؛ فقط وقتی برنامهٔ جداگانه برای ترافیک مشکوک داری روشن کن |
| alerts | n در تست اولیه، مگر Webhook و دسترسی شبکه به Discord را آزمایش کرده باشی |
| addoncache | اختیاری؛ در چند سرور مفید است تا دانلود Frameworkها از GitHub تکرار نشود |
| workshop | y اگر می‌خواهی آیتم‌های Workshop بین سرورها Cache و Share شوند |
| backup | اختیاری؛ پیش از روشن‌کردن فضای آرشیو و Retention را تعیین کن |
| cleanup | اختیاری؛ قواعد پاک‌سازی را بررسی کن چون این Module فایل حذف می‌کند |
| crashes | y برای نگهداری اطلاعات Crash |
| consolelog | اختیاری؛ Logها فضا مصرف می‌کنند |
| metrics | y اگر cs2node top یا Prometheus لازم داری؛ Endpoint پیش‌فرض فقط روی localhost است |

اگر Workshop را روشن کردی، dir را روی /srv/cs2-workshop بگذار، seed را y انتخاب کن و Retention را آگاهانه تعیین کن. keep_days=0 یعنی نسخه‌های بلااستفاده بدون محدودیت زمانی نگه داشته شوند. Moduleهای اضافه را بعداً نیز با اجرای مجدد sudo cs2node install می‌توان پیکربندی کرد.

**قبل از تأیید Summary** این موارد را کنترل کن:

- کانال stable است.
- vpksync روشن است.
- cs2_dir برابر /srv/cs2-shared است.
- روش VPK، symlink است.
- هیچ Webhook، Token یا رمز محرمانه‌ای در فایل مستندات ذخیره نشده است.

## 7. بررسی سرویس و شروع دانلود مرکزی

پس از تکمیل Wizard، وضعیت daemon را بررسی کن:

~~~bash
echo "=== Service ==="
sudo systemctl is-enabled cs2node
sudo systemctl is-active cs2node
sudo systemctl status cs2node --no-pager

echo
echo "=== Version and status ==="
sudo cs2node version
sudo cs2node status

echo
echo "=== Doctor ==="
sudo cs2node doctor
~~~

اولین تلاش VPK Sync، SteamCMD را به‌صورت خودکار در /root/steamcmd آماده می‌کند و CS2 را در مسیر مرکزی Update می‌کند. برای دیدن لاگ سرویس:

~~~bash
sudo journalctl -u cs2node -f
~~~

برای خروج از نمایش زندهٔ لاگ، Ctrl+C بزن؛ این کار سرویس را متوقف نمی‌کند. اگر دانلود ادامه دارد، سرویس را بی‌دلیل Restart نکن.

### 7.1 معیار قبولی Base مرکزی

پس از اتمام Update، این بلوک را اجرا کن:

~~~bash
BASE="/srv/cs2-shared"

echo "=== Central manifest ==="
if sudo test -s "$BASE/steamapps/appmanifest_730.acf"; then
  sudo grep -E '"(appid|buildid|StateFlags)"' \
    "$BASE/steamapps/appmanifest_730.acf"
else
  echo "Manifest not present"
fi

echo
echo "=== Game directory size ==="
sudo du -sh "$BASE/game" 2>/dev/null || true

echo
echo "=== VPK count ==="
sudo find "$BASE/game" -type f -name '*.vpk' 2>/dev/null | wc -l

echo
echo "=== Disk free space ==="
df -hT / /srv /var/lib/pterodactyl/volumes 2>/dev/null

echo
echo "=== Doctor ==="
sudo cs2node doctor

echo
echo "=== Status ==="
sudo cs2node status
~~~

Base فقط وقتی آماده محسوب می‌شود که Manifest با appid=730 و Build ID وجود داشته باشد، فایل‌های بازی/VPKها حاضر باشند و cs2node doctor/status نبودن Base را گزارش نکند. صرف وجود /srv/cs2-shared کافی نیست.

### 7.2 اگر Base هنوز خالی است یا دانلود کامل به نظر نمی‌رسد

اگر central build خالی است، Build ID صفر است یا VPK count صفر نشان داده می‌شود، سرور بازی را Start نکن و هیچ فایلی را حذف نکن. این بلوک فقط‌خواندنی است و هم‌زمان کمک می‌کند بفهمی فایل‌ها هنوز در پوشهٔ موقت دانلود Steam هستند یا خیر.

~~~bash
BASE="/srv/cs2-shared"

echo "=== Recent journal ==="
sudo journalctl -u cs2node -n 120 --no-pager -o short-iso

echo
echo "=== SteamCMD processes ==="
ps -eo pid,etime,stat,%cpu,%mem,args |
  grep -E '[s]teamcmd\\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true

echo
echo "=== Directory sizes ==="
sudo du -sh /root/steamcmd /root/Steam "$BASE" 2>/dev/null || true

echo
echo "=== Size by central subdirectory ==="
sudo du -xhd2 "$BASE" 2>/dev/null | sort -h | tail -n 40

echo
echo "=== Steam depot staging directories ==="
if sudo test -d "$BASE/steamapps"; then
  sudo find "$BASE/steamapps" -maxdepth 4 -type d -print | head -n 100
else
  echo "No steamapps directory yet."
fi

echo
echo "=== File count by extension under central Base ==="
sudo find "$BASE" -xdev -type f -printf '%f\\n' 2>/dev/null |
  awk '{
    name=$0
    if (name ~ /\\./) {
      sub(/^.*\\./, "", name)
      ext=tolower(name)
    } else {
      ext="[no extension]"
    }
    count[ext]++
  }
  END {
    for (ext in count) printf "%-24s %d\\n", ext, count[ext]
  }' | sort -k2,2nr | head -n 25

echo
echo "=== Largest files under central Base ==="
sudo find "$BASE" -xdev -type f -printf '%s\\t%p\\n' 2>/dev/null |
  sort -nr | head -n 25 | numfmt --field=1 --to=iec

echo
echo "=== Steam log files ==="
sudo find /root/Steam/logs -maxdepth 1 -type f \\
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\\n' 2>/dev/null | sort

for log in /root/Steam/logs/content_log.txt /root/Steam/logs/stderr.txt /root/Steam/logs/connection_log.txt; do
  if sudo test -f "$log"; then
    echo
    echo "=== Tail: $log ==="
    sudo tail -n 40 "$log"
  fi
done
~~~

**تفسیر:** اگر پردازش SteamCMD هنوز زنده است، اول خروجی اندازهٔ زیرپوشه‌ها را بررسی کن. در حین Update ممکن است داده‌ها داخل steamapps/downloading/730 باشند و هنوز به game/ نهایی منتقل نشده باشند؛ در این وضعیت VPK count صفر به‌تنهایی شکست قطعی نیست. پردازش فعال را Stop/Restart نکن و WinSCP upload هم‌زمان انجام نده. اگر SteamCMD دیگر زنده نیست اما Build ID صفر/Manifest نهایی غایب است، علت خروج را از Journal و لاگ‌های Steam پیدا کن. خطای cannot execute: required file not found با Exit Code 127 نشان می‌دهد Runtime مربوط به i386 را طبق بخش 2 بررسی کن.


## 8. اتصال Instance اول به Shared Base

فقط بعد از قبولی بخش 7، از پنل سرور اول را Start کن. در Console باید پیام موفق مشابه این دیده شود:

~~~text
KitsuneLab | OK | Daemon-managed game files, SteamCMD skipped
~~~

سپس بررسی کن:

- Map بدون خطا بارگذاری شده باشد.
- Console سرور آنلاین بماند و چرخهٔ Crash/Restart تکراری رخ ندهد.
- sudo cs2node status سرور و ارتباط Egg را نشان دهد.
- مصرف Disk سرور نسبت به نصب standalone کاهش یافته باشد.
- پس از Stop/Start، سرور همچنان فایل‌ها را از Shared Base بگیرد.

اگر پیام KL-DMN-03 یا KL-DMN-04 دیدی، قبولی محسوب نمی‌شود. sudo cs2node doctor، sudo cs2node status و Journal را بررسی کن.

## 9. ساخت Instance دوم و اثبات Multi Instance

بعد از قبولی سرور اول:

1. از Admin → Servers → Create Server یک سرور دوم با همان Egg کامل KitsuneLab CS2 Go @ K4ryuu و Image ghcr.io/k4ryuu/cs2-egg-go:stable بساز.
2. برای سرور دوم یک Allocation آزاد و مستقل انتخاب کن.
3. سرور دوم را Start کن.
4. همان پیام Daemon-managed game files, SteamCMD skipped را در Console ببین.
5. sudo cs2node status را اجرا و شناسایی هر دو سرور را تأیید کن.
6. فایل‌های cfg، تنظیمات Plugin و داده‌های قابل‌نوشتن سرورها را مستقل نگه دار؛ هر دو Instance را به یک Volume نوشتنی وصل نکن.

سقف Disk هر سرور را به حدود 5 GB فقط پس از اندازه‌گیری واقعی مصرف و قبولی Multi Instance کاهش بده. تا قبل از این آزمون، برای سرور اول 40 GB را حفظ کن.

## 10. انتقال کنترل‌شدهٔ VPKهای بازی با WinSCP

این مرحله اختیاری است و فقط وقتی اجرا می‌شود که SteamCMD قابل‌اجرا باشد و Base تا حدی دانلود شده باشد. انتقال فایل از Windows ممکن است ترافیک شبکه را کم کند، اما **تضمین نمی‌کند SteamCMD دانلود را کامل رد کند**؛ SteamCMD باید Manifest/Depotهای Linux را بررسی و فایل‌های لازم را تکمیل کند.

### 10.1 ابتدا دانلود را کاملاً متوقف کن

سرورهای بازی باید Offline باشند. اول پردازش و وضعیت را ثبت کن؛ سپس سرویس را متوقف کن:

~~~bash
echo "=== Before stopping ==="
ps -eo pid,etime,stat,args |
  grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true

sudo systemctl stop cs2node
sleep 2

echo
echo "=== Service state ==="
sudo systemctl is-active cs2node || true

echo
echo "=== Remaining SteamCMD processes ==="
ps -eo pid,etime,stat,args |
  grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true
~~~

ادامه فقط وقتی مجاز است که سرویس متوقف و پردازش SteamCMD باقی نمانده باشد. اگر دانلود هنوز در حال اجراست، WinSCP را هم‌زمان آغاز نکن.

### 10.2 فایل‌های Windows را به پوشهٔ موقت بفرست

در WinSCP با حساب معمولی SFTP، فایل‌های منبع را ابتدا به پوشه‌ای زیر Home کاربر منتقل کن؛ مثلاً:

~~~text
/home/<linux-user>/cs2-base-staging/game/
~~~

عبارت <linux-user> را با نام کاربر واقعی Debian جایگزین کن. در staging مسیر داخل game/ باید ساختار اصلی بازی را حفظ کند؛ برای مثال csgo/maps/ باید به همان مسیر نسبی منتقل شود.

از staging فقط فایل‌های .vpk را در مرحلهٔ بعد ادغام می‌کنیم. این موارد را از منبع Windows جایگزین نکن:

- steamapps/appmanifest_730.acf
- .steam/ و Steam/
- خود SteamCMD
- EXE، DLL، فایل‌های runtime و باینری‌های مخصوص Windows

### 10.3 ادغام کنترل‌شدهٔ VPKها

ابتدا مطمئن شو `rsync` نصب است، سپس مسیر staging و مقصد را در بلوک فقط‌خواندنی بررسی کن. فایل‌های Windows را ابتدا به پوشهٔ staging منتقل کن؛ هیچ‌گاه مستقیماً به `/srv/cs2-shared` آپلود نکن.

~~~bash
sudo apt-get update
sudo apt-get install -y rsync
~~~

پس از تأیید Source و Target، این فرمان فقط VPKها را در مسیر نسبی یکسان اضافه می‌کند؛ VPKای که از قبل در مقصد وجود دارد overwrite نمی‌شود:

~~~bash
set -eu

BASE="/srv/cs2-shared"
STAGE="$HOME/cs2-base-staging/game"

if ! sudo test -d "$BASE/game"; then
  echo "STOP: central game directory does not exist. Do not copy yet."
  exit 1
fi

if [ ! -d "$STAGE" ]; then
  echo "STOP: staging game directory not found: $STAGE"
  exit 1
fi

echo "=== VPK files in staging ==="
find "$STAGE" -type f -name '*.vpk' | wc -l

echo
echo "=== VPK files already central ==="
sudo find "$BASE/game" -type f -name '*.vpk' | wc -l

echo
echo "Review these numbers before copying."
~~~

اگر تعداد و مسیرهای منبع با چیزی که قصد انتقالش را داری مطابقت داشت، تنها بعد از توقف قطعی SteamCMD این دستور را اجرا کن:

~~~bash
sudo rsync -rltv --ignore-existing \
  --include='*/' \
  --include='*.vpk' \
  --exclude='*' \
  "$STAGE/" \
  "$BASE/game/"
~~~

این فرمان مسیرهای نسبی زیر game/ را حفظ می‌کند و فقط فایل‌های VPK را کپی می‌کند. اگر منبع شامل VPKهای ناقص/ناسازگار باشد یا SteamCMD به Manifest/Depotهای دیگر نیاز داشته باشد، دانلود همچنان انجام می‌شود یا فایل‌ها اصلاح می‌شوند. appmanifest_730.acf را از Windows جایگزین نکن.

پس از انتقال، باید SteamCMD فایل‌ها را بررسی کند. برای اینکه فایل‌های seedشده با Build مرکزی تطبیق داده شوند، در حالی که سرویس متوقف است، Wizard را دوباره اجرا کن و در بخش `vpksync` گزینهٔ `validate` را موقتاً `y` قرار بده. مسیر `cs2_dir` و باقی تنظیمات را حفظ کن؛ به‌خصوص ماژول‌ها را آگاهانه انتخاب کن، چون Wizard در اجرای مجدد نیز تنظیمات را می‌نویسد.

~~~bash
sudo /usr/local/bin/cs2node install
~~~

پس از پایان Wizard، لاگ را دنبال کن:

~~~bash
sudo journalctl -u cs2node -f
~~~

پس از تکمیل Update/validation، دوباره معیارهای بخش 7.1 را بررسی کن. اگر Base سالم شد، Wizard را یک بار دیگر اجرا کن و `validate` را به `n` برگردان تا اعتبارسنجی کامل در هر Update زمان/ترافیک اضافی مصرف نکند. تا وقتی Manifest، Build ID، VPK count و `cs2node doctor` معتبر نیستند، سرور را Start نکن.

## 11. Workshop Cache — مسیر درست و روش واردکردن

Workshop Cache ماژول K4ryuu با Shared Base بازی فرق دارد:

- Shared CS2 Base: /srv/cs2-shared/
- Workshop Store روی Node: /srv/cs2-workshop/
- ساختار داخلی Store: /srv/cs2-workshop/730/<item-id>/<manifest>/
- فایل meta.json در هر نسخه برای شناسایی کامل فایل‌ها و Manifest لازم است.

**فایل‌های Workshop ویندوز را مستقیم و خام داخل /srv/cs2-workshop کپی نکن.** ماژول این پوشه را صرفاً فهرستی از VPKها فرض نمی‌کند؛ metadata و نسخهٔ آیتم را لازم دارد.

### 11.1 منبع Workshop ویندوز را شناسایی کن

در نصب استاندارد Steam Workshop، ساختاری مشابه این وجود دارد:

~~~text
steamapps/workshop/
  appworkshop_730.acf
  content/730/<item-id>/<files...>
~~~

ممکن است فایل‌ها با ساختار دیگری روی دیسک باشند. اگر فقط پوشه‌ای مانند game/csgo_community_addons داری، آن را بدون بررسی با Workshop Cache ماژول یکی فرض نکن؛ ابتدا ریشه و محتویات واقعی منبع را شناسایی کن.

### 11.2 واردکردن از مسیر مورد انتظار Egg/Node

ماژول، محتوای Workshop هر سرور را پیش از شروع فرآیند بازی از مسیر Volume زیر می‌خواند:

~~~text
game/bin/linuxsteamrt64/steamapps/workshop/
  appworkshop_730.acf
  content/730/<item-id>/<files...>
~~~

فقط زمانی از این روش استفاده کن که منبع ویندوز واقعاً این ساختار را دارد و فایل ACF متعلق به همان مجموعهٔ Workshop است. اگر فقط VPKها یا پوشه‌ای مانند game/csgo_community_addons موجود است، این مرحله را اجرا نکن تا ساختار منبع بررسی شود.

نمونهٔ انتقال برای Source با ساختار معتبر:

1. سرور آزمایشی را Stop کن.
2. با WinSCP کل پوشهٔ Workshop را به staging زیر Home کاربر منتقل کن؛ به‌طور نمونه، فایل ACF باید در \$HOME/workshop-staging/appworkshop_730.acf و پوشهٔ content باید در \$HOME/workshop-staging/content/730/ قرار گیرد.
3. در Panel/Node Volume UUID سرور آزمایشی را مشخص کن؛ از UUID سرور فعلی FragCity برای سرور دیگری استفاده نکن.
4. مسیر زیر را با UUID واقعی همان سرور تنظیم کن. فرمان فقط وقتی اجرا شود که سرور خاموش و فایل ACF و content موجود باشند.

~~~bash
set -eu

STAGE="$HOME/workshop-staging"
VOL="/var/lib/pterodactyl/volumes/<SERVER_UUID>"

if [ ! -s "$STAGE/appworkshop_730.acf" ] || [ ! -d "$STAGE/content/730" ]; then
  echo "STOP: a valid appworkshop_730.acf and content/730 directory are required."
  exit 1
fi

if ! sudo test -d "$VOL/game"; then
  echo "STOP: target volume not found. Check SERVER_UUID."
  exit 1
fi

TARGET="$VOL/game/bin/linuxsteamrt64/steamapps/workshop"
sudo install -d "$TARGET"

echo "Source Workshop item folders:"
find "$STAGE/content/730" -mindepth 1 -maxdepth 1 -type d | wc -l

echo "Review the source and target before copying:"
sudo ls -ld "$VOL" "$TARGET"
~~~

5. اگر پوشهٔ مقصد خالی است و ACF منبع معتبر است، فایل‌ها را به‌صورت اضافه‌کردن بدون overwrite منتقل کن. اگر مقصد از قبل فایل دارد، متوقف شو و ACF موجود را به‌صورت جداگانه بررسی/پشتیبان‌گیری کن؛ به‌طور خودکار آن را با نسخهٔ Windows جایگزین نکن.

~~~bash
set -eu
if sudo find "$TARGET" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
  echo "STOP: Workshop target is not empty. Review its ACF/content before merging."
  exit 1
fi

OWNER="$(sudo stat -c '%u:%g' "$VOL")"
sudo rsync -rtv --ignore-existing --chown="$OWNER" \
  "$STAGE/" "$TARGET/"
~~~

6. Start سرور آزمایشی کن تا Workshop Module آیتم‌ها را در مسیر خود جذب کند.
7. پس از Boot، sudo cs2node workshop را اجرا کن و وجود آیتم/نسخه را بررسی کن.

این مسیر برای Workshop Cache است، نه برای کپی مستقیم به /srv/cs2-workshop. ماژول metadata خود را هنگام جذب محتوا می‌سازد. اگر ACF معتبر نباشد، شناسه/Manifest قابل‌قبول نباشد یا نسخهٔ جدیدتری در انتظار باشد، ممکن است آیتم را Cache نکند؛ در آن صورت فایل‌های بیشتری کپی نکن و Console/Journals را بررسی کن.

### 11.3 تأیید Cache و آماده‌سازی Instance بعدی

~~~bash
echo "=== Workshop cache ==="
sudo cs2node workshop

echo
echo "=== Workshop store size ==="
sudo du -sh /srv/cs2-workshop 2>/dev/null || true

echo
echo "=== Cached item metadata ==="
sudo find /srv/cs2-workshop/730 -mindepth 3 -maxdepth 3 \
  -name meta.json -print 2>/dev/null | head -n 50
~~~

به عنوان بخشی از آزمایش، در پنل سرور اول را Stop/Start کن و Console را بررسی کن. سپس سرور دوم را Start کن و مطمئن شو آیتم‌های Cacheشده به آن پیشنهاد می‌شوند. گزینه‌های دانلود مجدد خودکار در Pluginهایی مانند MultiAddonManager و AddonsManager می‌توانند صرفه‌جویی Cache را از بین ببرند؛ تنظیمات آن‌ها را مطابق مستندات رسمی‌شان بررسی کن.

## 12. بعد از قبولی Multi Instance: CounterStrikeSharp و پلاگین‌ها

این مرحله را فقط پس از قبولی Shared Base، Instance اول و Instance دوم انجام بده.

1. سرور آزمایشی را Stop کن.
2. در Startup مقدار INSTALL_CSS=1 را انتخاب کن. Egg طبق طراحی خود Metamod را نیز فعال می‌کند.
3. INSTALL_SWIFTLY=0 و INSTALL_MODSHARP=0 را برای این تست نگه دار؛ چند Framework ناسازگار را هم‌زمان فعال نکن.
4. سرور را Start کن و Console را بررسی کن.
5. پلاگین‌های تأییدشده را یکی‌یکی مستقر کن.

مسیرهای متداول داخل Container:

| مورد | مسیر |
|---|---|
| پلاگین‌های CounterStrikeSharp | /home/container/game/csgo/addons/counterstrikesharp/plugins/ |
| تنظیمات CSS/Pluginها | /home/container/game/csgo/addons/counterstrikesharp/configs/ |
| فایل‌های cfg بازی/Mode | /home/container/game/csgo/cfg/ |

ساختار توزیع رسمی هر Plugin را حفظ کن؛ Dependencyها و Gamedata را بررسی کن. فایل‌های config و cfg نوشتنی هر Instance خصوصی بمانند و محتوای VIP که از قبل تصمیم گرفته شده حذف شود، به Deployment برنگردد.

## 13. عیب‌یابی سریع

| علامت | بررسی بعدی |
|---|---|
| SteamCMD خطای cannot execute: required file not found می‌دهد | بخش 2؛ Runtimeهای i386 را بررسی کن |
| cs2node فعال است، اما central build خالی است | sudo cs2node doctor، Journal، SteamCMD processها و رشد /srv/cs2-shared را بررسی کن |
| Manifest وجود ندارد یا VPK count صفر است | Base آماده نیست؛ Instance را Start نکن |
| سرور محلی SteamCMD را اجرا می‌کند | در Console دنبال پیام Daemon-managed game files, SteamCMD skipped بگرد؛ cs2node doctor/status را بررسی کن |
| shared dir not mounted | Kernel، وضعیت daemon و زمان Start شدن Container را بررسی کن |
| Workshop Cache خالی مانده | ساختار ورودی، appworkshop_730.acf، Manifest و sudo cs2node workshop را بررسی کن |

فرمان‌های تشخیصی اصلی:

~~~bash
sudo cs2node doctor
sudo cs2node status
sudo journalctl -u cs2node -n 120 --no-pager
ps -eo pid,etime,stat,args | grep -E '[s]teamcmd|[l]inux32/steamcmd|[l]inux64/steamcmd' || true
~~~

## 14. چک‌لیست پایان نصب

- [ ] Runtimeهای i386 قبل از نصب/اولین Update آماده شده‌اند.
- [ ] cs2node.service فعال و enabled است.
- [ ] /srv/cs2-shared/steamapps/appmanifest_730.acf وجود دارد و Build ID دارد.
- [ ] cs2node doctor Base مرکزی را می‌شناسد و VPK count صفر نیست.
- [ ] Instance اول پیام Daemon-managed game files, SteamCMD skipped نشان می‌دهد.
- [ ] Instance دوم نیز از Base مرکزی استفاده می‌کند و فایل‌های قابل‌نوشتن آن مستقل هستند.
- [ ] در صورت استفاده از Workshop Cache، cs2node workshop آیتم‌ها/نسخه‌های معتبر را نشان می‌دهد.
- [ ] پس از قبولی Multi Instance، Framework/Pluginها در مرحلهٔ جداگانه تست شده‌اند.

## منابع رسمی K4ryuu

- [Egg installation](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md)
- [Node daemon installation](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md)
- [VPK Sync](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md)
- [Workshop cache](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/workshop.md)
- [Node config reference](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/node-config.md)
- [Troubleshooting](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/troubleshooting.md)

## 15. ادامهٔ نصب بعد از توقف یا خطا

این بخش برای هر Node قابل استفاده است؛ وضعیت یک VM یا IP مشخص را ثبت نمی‌کند.

1. اگر روی Debian amd64 پیام `cannot execute: required file not found` و `exit status 127` دیدی، به بخش 2 برگرد و وجود `i386` و بسته‌های `libc6:i386`، `libstdc++6:i386` و `libgcc-s1:i386` را بررسی کن.
2. اگر `cs2node` فعال است اما `central build` خالی است، وجود دایرکتوری را موفقیت نصب حساب نکن. `sudo cs2node doctor`، `sudo cs2node status`، Journal، پردازش‌های SteamCMD و رشد `/srv/cs2-shared` را بررسی کن.
3. اگر SteamCMD هنوز در حال اجراست، به آن فرصت بده؛ آن را دوباره اجرا نکن، سرویس را بی‌دلیل Restart نکن و هم‌زمان WinSCP آپلود نکن.
4. اگر باید فایل منتقل کنی، ابتدا سرورهای بازی را Offline نگه دار، سپس `cs2node` را متوقف و نبودن پردازش SteamCMD را تأیید کن؛ فقط بعد از آن به بخش 10 یا 11 برو.
5. اگر اتصال Webhook در دسترس نیست، این خطا به‌تنهایی نشانهٔ خرابی VPK Sync نیست. Alerts را مطابق سیاست شبکهٔ خود تنظیم کن؛ اگر URL وب‌هوک افشا شد، آن را در Discord باطل و جایگزین کن.
6. اگر نصب را از نشست قبلی ادامه می‌دهی، پیش از تغییر پیکربندی از تنظیمات فعلی `/etc/cs2node/config.json` نسخهٔ پشتیبان محدوددسترسی بگیر و همهٔ پاسخ‌های Wizard را آگاهانه انتخاب کن. فایل config کامل یا URL محرمانه را در چت/GitHub قرار نده.
