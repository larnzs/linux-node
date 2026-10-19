## 13. ادامهٔ PoC: تأیید cs2node و Shared Base

این بخش برای Clone با IP `192.168.1.9` است. در تمام مدت تست، VM اصلی با IP `192.168.1.7` خاموش بماند.

طبق تصمیم کاربر، **فایل‌های بازی از Windows و از Volume فعلی Pterodactyl به Shared Base کپی نمی‌شوند**. Base مرکزی باید توسط `cs2node`/SteamCMD آماده شود. Volume موجود `fc-cs2-test-01` را حذف نکن؛ فعلاً در پنل Offline نگهش دار.

### وضعیت فعلی ثبت‌شده از لاگ نصب

- باینری رسمی به `/usr/local/bin/cs2node` منتقل شده است.
- config در `/etc/cs2node/config.json` نوشته شده و service file در `/etc/systemd/system/cs2node.service` ایجاد شده است.
- Installer گزارش کرده سرویس enable و start شده است؛ هنوز خروجی مستقل `systemctl status`، `cs2node doctor/status` و وجود بازی در `/srv/cs2-shared` تأیید نشده است.
- مسیر مرکزی پیکربندی‌شده `/srv/cs2-shared` و روش تحویل VPK برابر `symlink` است.
- `vpksync`، `alerts`، `addoncache`، `workshop`، `backup`، `cleanup`، `crashes`، `consolelog` و `metrics` روشن‌اند؛ `guard` خاموش است.
- URL وب‌هوک Discord در لاگ چت افشا شده است. آن را در Discord باطل و یک وب‌هوک تازه بساز؛ URL وب‌هوک را در GitHub یا خروجی قابل‌اشتراک نگذار.

### قدم بعدی — فقط خواندن وضعیت و فایل‌ها

این دستورها را روی Clone اجرا کن. آن‌ها فایل بازی را کپی یا حذف نمی‌کنند:

~~~bash
echo "=== Service enabled/active ==="
sudo systemctl is-enabled cs2node || true
sudo systemctl is-active cs2node || true
sudo systemctl status cs2node --no-pager

echo
echo "=== cs2node version/status/doctor ==="
sudo cs2node version
sudo cs2node status
sudo cs2node doctor

echo
echo "=== Central base directory ==="
if sudo test -d /srv/cs2-shared; then
  sudo ls -lah /srv/cs2-shared
  sudo du -sh /srv/cs2-shared
  sudo find /srv/cs2-shared -mindepth 1 -maxdepth 2 -printf '%y %p\\n' | head -n 80

  echo
  echo "=== Manifest ==="
  if sudo test -f /srv/cs2-shared/steamapps/appmanifest_730.acf; then
    sudo grep -E '"(appid|buildid|StateFlags)"' /srv/cs2-shared/steamapps/appmanifest_730.acf
  else
    echo "Manifest not present yet"
  fi

  echo
  echo "=== VPK count ==="
  sudo find /srv/cs2-shared/game -type f -name '*.vpk' 2>/dev/null | wc -l
else
  echo "/srv/cs2-shared does not exist"
fi

echo
echo "=== Recent cs2node logs ==="
sudo journalctl -u cs2node -n 120 --no-pager

echo
echo "=== Disk space ==="
df -hT / /srv /var/lib/pterodactyl/volumes 2>/dev/null
~~~

اگر SteamCMD هنوز دانلود می‌کند، آن را تکراری اجرا نکن و سرویس را Restart نکن. اگر `/srv/cs2-shared` خالی است یا خطای دانلود دیده می‌شود، چیزی را حذف نکن؛ خروجی وضعیت و journal را بررسی کن.

پس از تأیید manifest مرکزی، Build ID، VPKها و نتیجهٔ `doctor/status`:
1. سرور اول را Start کن و در Console پیام `Daemon-managed game files, SteamCMD skipped` را بررسی کن.
2. اگر سرور اول قبول شد، Instance دوم را با همان Egg کامل و Allocation مستقل بساز.
3. تا وقتی سرور دوم هم Shared Base را بدون دانلود مستقل تأیید نکرده، پلاگین‌های FragCity/KUS را اضافه نکن.

## 14. چک‌لیست مرحلهٔ جاری

- [x] فضای آزاد Windows host بررسی شد؛ D در زمان بررسی حدود 301.8 GB آزاد داشت.
- [x] مسیر VMX روی C و فایل VMDK روی D پیدا شد.
- [x] Full Clone ساخته شد؛ VMware گزینهٔ I Copied It را در اولین بوت انتخاب کرد.
- [x] MAC کلون جدید است و DHCP فعلاً IP برابر 192.168.1.9 داده است.
- [x] hostname داخل Clone به fc-node-01 برگردانده شد؛ /etc/hosts نام میزبان را resolve می‌کند.
- [x] Health check فقط‌خواندنی نتیجهٔ 24 PASS / 1 WARN / 0 FAIL داد.
- [x] Nginx، PHP 8.3-FPM، MariaDB، Redis، Docker و Wings فعال گزارش شده‌اند؛ Nginx test و HTTPS محلی Panel موفق بودند.
- [x] مسیر Panel برابر /var/www/pterodactyl، نسخه Laravel برابر 12.64.0، QUEUE_CONNECTION برابر redis و Cron فعال است.
- [x] PHP CLI در /usr/bin/php نسخه 8.3.35 است؛ www-data می‌تواند Artisan را اجرا کند و queue:work و schedule:run موجودند.
- [x] در پیش‌بررسی اولیه هیچ Queue Worker در حال اجرا و هیچ Scheduler cron entry برای `artisan schedule:run` پیدا نشد؛ این نقص روی Clone با مرحلهٔ 3.4.1 اصلاح شد.
- [x] قانون UFW ورودی 29001/udp عمداً برای سرور CS2 آینده باز است؛ طبق تصمیم کاربر آن را تغییر نده.
- [x] بلوک استاندارد README بخش 3.4.1 روی Clone اجرا شد؛ `pteroq.service` ایجاد و راه‌اندازی شد.
- [x] تأیید شد `pteroq.service` هم `active` و هم `enabled` است و خط `schedule:run` در crontab ریشه وجود دارد.
- [x] طبق تأیید کاربر در 2026-10-18، شبکه و پنل عملیاتی هستند؛ بررسی دسترسی شبکه/پنل برای Clone با IP `192.168.1.9` تکمیل‌شده ثبت شد.
- [x] دسترسی پنل و عملیاتی بودن شبکه طبق تأیید کاربر تأیید شد.
- [x] Egg رسمی CS2-Egg-Go وارد شده و اولین Instance `fc-cs2-test-01` ساخته شده است؛ کاربر پایان دانلود اولیه را گزارش کرده است.
- [x] خروجی اولیه نشان داد Kernel `6.12.113+deb13-amd64` و فضای آزاد root حدود 182 GB است.
- [x] Volume فعلی manifest با appid=730، StateFlags=4، buildid=25966348 و 739 فایل VPK دارد؛ باینری `cs2node` نصب شده و Installer گزارش کرده سرویس start شده است. وجود محتوا در `/srv/cs2-shared` هنوز باید جداگانه تأیید شود.
- [x] بازرسی read-only پایان یافت: game/csgo حدود 61 GB، game/csgo/maps حدود 9.6 GB، game/csgo_community_addons حدود 6.4 GB و مجموع VPKها 67.75 GiB؛ حجم 69 GB خطا تلقی نمی‌شود.
- [x] تصمیم گرفته شد فایل‌های بازی از Windows یا Volume فعلی برای Seed استفاده نشوند؛ Shared Base باید از ابتدا با SteamCMD دانلود شود.
- [ ] پیش‌بررسی بخش 8.1 راهنمای server-creation؛ `fc-cs2-test-01` در حالت Offline بماند.
- [x] نصب رسمی `cs2node` انجام شده؛ `vpksync` فعال است و `cs2_dir=/srv/cs2-shared` ثبت شده است. ماژول‌های `alerts`, `addoncache`, `workshop`, `backup`, `cleanup`, `crashes`, `consolelog`, `metrics` نیز روشن و `guard` خاموش است.
- [ ] بررسی `cs2node doctor/status`، لاگ systemd، manifest/VPKهای `/srv/cs2-shared` و سپس دانلود تازهٔ Base مرکزی؛ پس از تأیید Base پیام SteamCMD skipped را در سرور اول بررسی کن. VMDK دوم برای این PoC لازم نیست.
- [ ] پس از قبولی Shared Base و Instance دوم، CounterStrikeSharp/MetaMod و پلاگین‌های Fun Mode منتخب طبق بخش 9 راهنمای ساخت سرور نصب و تأیید شوند؛ configs و addons هر Instance مستقل بمانند.
- [ ] پس از قبولی PoC، در صورت نیاز VMDK داده جداگانه به Clone اضافه و شناسایی شود؛ این کار برای نصب اولیهٔ Shared Base الزامی نیست.
- [ ] هنگام بازگشت، ابتدا Clone خاموش، سپس Port Forwardها به 192.168.1.7 برگردانده شوند و بعد VM اصلی روشن شود؛ سپس مرحله 3.4.1 README روی VMDK اصلی هم اجرا شود.

**آخرین checkpoint:** Clone با IP `192.168.1.9` و hostname `fc-node-01` فعال است و VM اصلی باید خاموش بماند. شبکه و پنل طبق تأیید کاربر عملیاتی‌اند؛ Queue Worker و Scheduler روی Clone فعال‌اند. پورت `29001/udp` را تغییر نده. اولین Instance `fc-cs2-test-01` ساخته شده و پایان دانلود اولیه گزارش شده؛ manifest موجود در Volume با `appid=730` و `buildid=25966348` دیده شده است. طبق تصمیم کاربر، از فایل‌های Windows یا Volume موجود برای Seed استفاده نمی‌شود. Installer رسمی `cs2node` گزارش کرده config و systemd unit نوشته شده و سرویس فعال/اجرا شده است؛ `vpksync` به `/srv/cs2-shared` با روش `symlink` پیکربندی شده و Moduleهای addoncache, workshop, backup, cleanup, crashes, consolelog, metrics و alerts نیز روشن‌اند. محتوای Shared Base هنوز تأیید نشده؛ قدم بعدی `cs2node doctor/status`, `journalctl`, manifest و VPK count در مسیر مرکزی است. URL وب‌هوک افشاشده باید در Discord باطل و جایگزین شود. VMDK دوم برای PoC لازم نیست. پس از قبولی Base و Instance دوم، پلاگین‌ها آزمایش می‌شوند. تغییرات Queue/Scheduler روی VM اصلی باید جداگانه اعمال شوند.
