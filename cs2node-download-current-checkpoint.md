# Checkpoint عملیاتی — دانلود CS2 با cs2node

> **این فایل گزارش وضعیت اجرای فعلی FragCity است، نه آموزش نصب عمومی.** برای نصب روی Node دیگر از [راهنمای آموزشی K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md) استفاده کن.

## وضعیت مشاهده‌شده در آخرین خروجی کاربر — 2026-10-19

- Clone آزمایشی: hostname نمونه **fc-node-01**، IP برابر **192.168.1.9**. VM اصلی با IP برابر **192.168.1.7** باید خاموش بماند تا Clone خاموش شود.
- Instance آزمایشی **fc-cs2-test-01** باید Offline بماند تا Shared Base و VPK Sync تأیید شوند.
- پیش‌نیاز i386 نصب شده است: **libc6:i386**، **libstdc++6:i386** و **libgcc-s1:i386**.
- آزمون **sudo /root/steamcmd/steamcmd.sh +quit** موفق شده و پیام‌های **Loading Steam API...OK** و **Unloading Steam API...OK** را نشان داده است.
- **cs2node.service** برابر enabled و active بوده است.
- پردازش SteamCMD در آخرین خروجی هنوز زنده بوده: **/root/steamcmd/linux32/steamcmd +force_install_dir /srv/cs2-shared +login anonymous +app_update 730 +quit**، حدود 27 دقیقه runtime و حدود 143% CPU.
- اندازهٔ **/srv/cs2-shared** حدود 58 GiB گزارش شده است.
- در **/srv/cs2-shared/steamapps/appmanifest_730.acf**، **appid=730**، **StateFlags=1026** و **buildid=0** دیده شده است.
- تعداد فایل‌های .vpk زیر **/srv/cs2-shared/game** صفر بوده است؛ وجود فایل‌های نهایی و آمادهٔ بازی هنوز تأیید نشده است.
- خروجی فعلی به‌تنهایی ثابت نمی‌کند Update شکست خورده است. با توجه به پردازش زنده و حجم نوشته‌شده، باید نخست بررسی شود آیا فایل‌ها هنوز زیر **steamapps/downloading/730** هستند یا خیر.
- خطای Webhook Discord در این محیط طبق گفتهٔ کاربر ناشی از محدودیت/قطع شبکهٔ Discord است و عامل اصلی خطای SteamCMD پیشین نیست. URL وب‌هوک را در این فایل یا هر مستند عمومی ثبت نکن.

## گام بعدی — فقط بازرسی خواندنی، در حالی که SteamCMD فعال است

**فعلاً cs2node را Stop/Restart نکن و WinSCP upload را شروع نکن.** روی Node این بلوک را اجرا کن:

~~~bash
BASE="/srv/cs2-shared"

echo "=== SteamCMD process ==="
ps -eo pid,etime,stat,%cpu,%mem,args |
  grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true

echo
echo "=== Central directory usage by level ==="
sudo du -xhd2 "$BASE" 2>/dev/null | sort -h | tail -n 40

echo
echo "=== Steam staging folders ==="
if sudo test -d "$BASE/steamapps"; then
  sudo find "$BASE/steamapps" -maxdepth 4 -type d -print | head -n 100
else
  echo "No steamapps directory."
fi

echo
echo "=== File counts by extension ==="
sudo find "$BASE" -xdev -type f -printf '%f\n' 2>/dev/null |
  awk '{
    name=$0
    if (name ~ /\./) {
      sub(/^.*\./, "", name)
      ext=tolower(name)
    } else ext="[no extension]"
    count[ext]++
  }
  END {for (ext in count) printf "%-24s %d\n", ext, count[ext]}' |
  sort -k2,2nr | head -n 25

echo
echo "=== Largest files ==="
sudo find "$BASE" -xdev -type f -printf '%s\t%p\n' 2>/dev/null |
  sort -nr | head -n 25 | numfmt --field=1 --to=iec

echo
echo "=== Steam log files ==="
sudo find /root/Steam/logs -maxdepth 1 -type f -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort

for log in /root/Steam/logs/content_log.txt /root/Steam/logs/stderr.txt /root/Steam/logs/connection_log.txt; do
  if sudo test -f "$log"; then
    echo
    echo "=== $log ==="
    sudo tail -n 40 "$log"
  fi
done
~~~

### چطور نتیجه را تفسیر کنیم؟

1. اگر بیشترین حجم در **/srv/cs2-shared/steamapps/downloading/730** باشد و پردازش SteamCMD زنده باشد، دانلود/پردازش depot هنوز در جریان است؛ فایل‌ها هنوز لزوماً به **game/** نهایی منتقل نشده‌اند. در این حالت WinSCP را هم‌زمان اجرا نکن.
2. اگر پردازش تمام شده باشد اما **buildid=0**، بدون Manifest معتبر یا بدون VPK نهایی مانده باشد، باید خطای واقعی SteamCMD را از Journal و logها پیدا کنیم؛ هنوز Base را آماده حساب نکن.
3. فقط بعد از آنکه تصمیم گرفتیم انتقال WinSCP لازم است، سرورهای بازی را Offline نگه می‌داریم، سرویس را به‌صورت کنترل‌شده متوقف می‌کنیم و نبودن پردازش SteamCMD را تأیید می‌کنیم. پس از آن VPKهای asset با حفظ مسیر نسبی به staging منتقل و ادغام می‌شوند؛ SteamCMD بعداً باید آن‌ها را reconcile کند.
4. Workshop جداست. فایل‌های خام Windows را مستقیم داخل **/srv/cs2-workshop** کپی نکن؛ واردکردن باید از طریق ساختار Volume و **appworkshop_730.acf** معتبر انجام شود تا Module بتواند **meta.json** نسخه‌ها را بسازد.
5. بعد از انتقال/Update، معیار قبولی همچنان Manifest با Build ID واقعی، VPKهای نهایی، **sudo cs2node doctor/status** و پیام Console زیر برای Instance اول است:

~~~text
KitsuneLab | OK | Daemon-managed game files, SteamCMD skipped
~~~

## لینک آموزش‌های مرجع

- [آموزش اصلی cs2node/VPK Sync/Workshop](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md)
- [آموزش نصب Debian/PHP/Composer/Docker/Firewall/Pterodactyl/Wings](https://github.com/larnzs/linux-node/blob/main/Debian-PHP-Composer-Docker-Firewall-Pterodactyl-Wings-Installation.md)
- [آموزش WinSCP](https://github.com/larnzs/linux-node/blob/main/%D8%A2%D9%85%D9%88%D8%B2%D8%B4%20winscp.md)
