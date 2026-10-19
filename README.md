# FragCity Linux Node — راهنماهای Debian و CS2

این ریپو، مراحل تکرارپذیر ساخت Linux Node برای FragCity را مستند می‌کند. مسیر اجرا و وضعیت فعلی را از راهنمای مربوط به همان مرحله دنبال کن؛ هیچ‌کدام از فایل‌ها محل ثبت رمزها، Tokenها، فایل `.env` یا URL وب‌هوک نیستند.

## راهنماها

1. **[نصب Debian، PHP، Composer، Docker، Firewall، Pterodactyl و Wings](https://github.com/larnzs/linux-node/blob/main/Debian-PHP-Composer-Docker-Firewall-Pterodactyl-Wings-Installation.md)**  
   Runbook اصلی نصب سیستم‌عامل و زیرساخت Panel/Node، تنظیم PHP و Composer، دیتابیس و Redis، Docker، firewall، NGINX، Pterodactyl، Wings، Queue Worker و Scheduler.

2. **[K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Multi Instance](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md)**  
   راهنمای Egg رسمی K4ryuu، اولین Instance آزمایشی، نصب cs2node، Shared Base، VPK Sync و معیارهای قبولی Instance دوم.

3. **[Clone و VMDK آزمایشی](https://github.com/larnzs/linux-node/blob/main/test-vmdk%20instructions.md)**  
   دستورالعمل Clone، بازگردانی امن به VM اصلی، بررسی سلامت و Storage جداگانهٔ اختیاری.

4. **[آموزش WinSCP — اتصال گرافیکی با کلید SSH](https://github.com/larnzs/linux-node/blob/main/%D8%A2%D9%85%D9%88%D8%B2%D8%B4%20winscp.md)**  
   راهنمای اتصال از ویندوز به Debian با SFTP، تنظیم کلید خصوصی SSH، مشاهده و انتقال فایل‌ها، محدودیت مجوزها و عیب‌یابی.

## وضعیت جاری — 2026-10-19

- Debian Clone با hostname برابر `fc-node-01` و IP برابر `192.168.1.9` برای تست استفاده می‌شود؛ VM اصلی با IP `192.168.1.7` باید خاموش بماند.
- Panel، Docker، Wings، Queue Worker و Scheduler روی Clone قبلاً راه‌اندازی و طبق گزارش کاربر عملیاتی‌اند.
- Instance آزمایشی `fc-cs2-test-01` ساخته شده و پایان دانلود اولیهٔ بازی گزارش شده است.
- Installer رسمی `cs2node` گزارش کرده config و systemd unit نوشته شده و سرویس enable/start شده است. `vpksync` با مسیر مرکزی `/srv/cs2-shared` و روش `symlink` تنظیم شده، اما وجود manifest و فایل‌های واقعی در این مسیر هنوز باید بررسی شود.
- هیچ فایل بازی از Windows یا Volume موجود برای Seed استفاده نمی‌شود؛ Base مرکزی باید با SteamCMD آماده شود.
- وب‌هوک Discord در خروجی چت افشا شده است؛ پیش از اتکا به ماژول Alerts، وب‌هوک قبلی را در Discord باطل و جایگزین کن.

## قواعد ایمنی

- فرمان‌های مربوط به Clone را روی VM اصلی اجرا نکن.
- دو VM با هویت/دامنهٔ فعلی را هم‌زمان روشن نکن.
- پیش از فرمت‌کردن یا Mount کردن VMDK، خروجی `lsblk` و `blkid` را بررسی کن؛ نام دیسک را حدس نزن.
- تا وقتی Shared Base و Multi Instance تأیید نشده‌اند، پلاگین‌های FragCity/KUS را اضافه نکن.
- خروجی config کامل، Webhook URL، Tokenها، APP_KEY، رمز دیتابیس و `.env` را در GitHub یا چت قرار نده.
