# وضعیت فعلی آزمایش cs2node — گزارش اجرا

این سند گزارش یک اجرای واقعی FragCity است، نه آموزش نصب عمومی. برای نصب تازه یا Node دیگری از [آموزش K4ryuu cs2node](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md) استفاده کن.

## محیط آزمایش

- Clone آزمایشی فعلی: hostname برابر fc-node-01 و IP داخلی برابر 192.168.1.9.
- VM اصلی با IP داخلی 192.168.1.7 باید در تمام مدت آزمایش خاموش بماند. این Clone در حال حاضر جایگزین موقت VM اصلی است، نه Node دوم برای اجرای هم‌زمان.
- Panel: https://panel.fragcity.ir.
- Instance آزمایشی: fc-cs2-test-01. تا تأیید Shared Base آن را Offline نگه دار.
- مسیر Base مرکزی: /srv/cs2-shared.
- مسیر Workshop Cache: /srv/cs2-workshop.
- آخرین بررسی اولیه حدود 182 GiB فضای آزاد نشان داده بود؛ پیش از هر انتقال حجیم دوباره df -hT / را اجرا کن.

## وضعیت cs2node

- Installer باینری را در /usr/local/bin/cs2node قرار داده و config را در /etc/cs2node/config.json نوشته است.
- سرویس cs2node.service برابر enabled و active گزارش شده است.
- cs2node status نسخهٔ 1.0.4 stable را نشان داده است.
- vpksync به مسیر /srv/cs2-shared و روش symlink تنظیم شده است.
- Moduleهای روشن در نصب فعلی: vpksync، alerts، addoncache، workshop، backup، cleanup، crashes، consolelog و metrics. guard خاموش است.
- URL وب‌هوک Discord در گفت‌وگو افشا شده است. آن را در Discord باطل و جایگزین کن؛ URL محرمانه را در هیچ سند عمومی ثبت نکن. طبق شواهد فعلی خطای شبکهٔ Discord علت اصلی مشکل SteamCMD نیست.

## رفع مشکل اولیهٔ SteamCMD

اولین تلاش برای اجرای SteamCMD با این خطا شکست خورد:

~~~text
/root/steamcmd/steamcmd.sh: line 37: /root/steamcmd/linux32/steamcmd: cannot execute: required file not found
central update failed err=steamcmd: exit status 127
~~~

سپس Runtimeهای i386 نصب شدند:

~~~text
libc6:i386
libstdc++6:i386
libgcc-s1:i386
~~~

آزمون زیر با موفقیت اجرا شد:

~~~bash
sudo /root/steamcmd/steamcmd.sh +quit
~~~

خروجی شامل Loading Steam API...OK و Unloading Steam API...OK بود. این ثابت می‌کند SteamCMD قابل اجراست؛ اما به‌تنهایی موفقیت دانلود CS2 را ثابت نمی‌کند.

## آخرین خروجی گزارش‌شده: Update مرکزی در حال اجرا بود

خروجی اخیر این وضعیت را نشان داده است:

- پردازش steamcmd.sh با آرگومان‌های +force_install_dir /srv/cs2-shared، +login anonymous و +app_update 730 فعال بود.
- پردازش /root/steamcmd/linux32/steamcmd حدود 27 دقیقه زمان اجرا و حدود 143% CPU گزارش کرده بود.
- اندازهٔ /srv/cs2-shared حدود 58 GiB بود.
- Manifest در /srv/cs2-shared/steamapps/appmanifest_730.acf وجود داشت و مقادیر گزارش‌شده عبارت بودند از:

~~~text
appid       730
StateFlags  1026
buildid     0
~~~

- تعداد VPKهای نهایی زیر /srv/cs2-shared/game برابر صفر بود.
- لاگ cs2node پس از Restart مقدار build=0 نشان داده بود، اما خطای جدیدی بعد از نصب Runtimeهای i386 در خروجی اخیر دیده نشده بود.

### برداشت فعلی

پردازش فعال، مصرف 58 GiB و Manifest با StateFlags برابر 1026 و buildid برابر صفر با یک Update ناتمام سازگارند. SteamCMD ممکن است محتوای در حال دریافت را ابتدا زیر steamapps/downloading/730 بنویسد و فقط در مرحلهٔ Commit آن را به درخت نهایی بازی منتقل کند؛ بنابراین صفر بودن VPKهای نهایی به‌تنهایی ثابت نمی‌کند که دانلود انجام نشده است.

در نسخهٔ upstream فعلی، خروجی استاندارد app_update به Journal فرستاده نمی‌شود؛ در نتیجه درصد دانلود لزوماً در journalctl دیده نمی‌شود. فعلاً SteamCMD را Restart یا Stop نکن و هم‌زمان WinSCP آپلود نکن. ابتدا ساختار پوشهٔ downloading و لاگ‌های خود SteamCMD را بررسی کن.

## گام بعدی — فقط‌خواندنی

این بلوک فقط وضعیت را بررسی می‌کند؛ چیزی را حذف، منتقل یا Restart نمی‌کند:

~~~bash
echo "=== SteamCMD processes ==="
ps -eo pid,etime,stat,%cpu,%mem,args |
  grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true

echo
echo "=== Directory sizes ==="
sudo du -sh /root/steamcmd /root/Steam /srv/cs2-shared 2>/dev/null || true
sudo du -xhd2 /srv/cs2-shared/steamapps 2>/dev/null | sort -h | tail -n 30

echo
echo "=== Steam log files ==="
sudo ls -lah /root/Steam/logs 2>/dev/null || true
for log in content_log.txt stderr.txt connection_log.txt; do
  if sudo test -f "/root/Steam/logs/$log"; then
    echo "=== $log (tail) ==="
    sudo tail -n 60 "/root/Steam/logs/$log"
  fi
done

echo
echo "=== Central manifest ==="
if sudo test -s /srv/cs2-shared/steamapps/appmanifest_730.acf; then
  sudo grep -E '"(appid|buildid|StateFlags)"' /srv/cs2-shared/steamapps/appmanifest_730.acf
else
  echo "Central manifest not found"
fi

echo
echo "=== Final-tree VPK count ==="
sudo find /srv/cs2-shared/game -type f -name '*.vpk' 2>/dev/null | wc -l

echo
echo "=== Free disk space ==="
df -hT /
~~~

### تصمیم پس از بررسی

- اگر SteamCMD هنوز فعال است و پوشهٔ downloading رشد می‌کند، اجازه بده ادامه دهد؛ در همان زمان WinSCP اجرا نکن.
- اگر پردازش SteamCMD پایان یافته اما Base ناقص مانده است، اول لاگ‌های SteamCMD را بررسی کن؛ قبل از Resume یا آپلود، علت را مشخص کن.
- اگر تصمیم به Pause برای انتقال فایل‌ها گرفته شد، ابتدا cs2node را متوقف کن و نبودن تمام پردازش‌های SteamCMD را تأیید کن؛ پوشهٔ downloading/730 را حذف نکن.
- VPKهای بازی و Workshop دو مسیر متفاوت دارند. Workshop باید از ساختار game/bin/linuxsteamrt64/steamapps/workshop به Volume سرور آزمایشی وارد شود تا ماژول K4ryuu بتواند نسخه و metadata را بشناسد؛ فایل خام Workshop را مستقیم داخل /srv/cs2-workshop نریز.

## منابع رسمی

- [K4ryuu: Node daemon](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md)
- [K4ryuu: VPK Sync](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md)
- [K4ryuu: Workshop Cache](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/workshop.md)
- [K4ryuu: Node config](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/node-config.md)
- [Steam appmanifest StateFlags reference](https://github.com/pinkwah/steam-appmanifest/blob/master/README.md)
