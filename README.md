# FragCity Linux Node — فهرست آموزش‌ها و Runbookها

این ریپو برای آموزش و اجرای مرحله‌ای نصب زیرساخت Debian و Nodeهای CS2 نگهداری می‌شود. هر راهنما به‌صورت یک Runbook مستقل نوشته شده است؛ ابتدا پیش‌نیازها و مقادیر محیطی آن را بخوان، سپس فقط مرحلهٔ جاری را اجرا کن.

## از کجا شروع کنم؟

1. **[نصب Debian 13، PHP، Composer، Docker، Firewall، Pterodactyl و Wings](https://github.com/larnzs/linux-node/blob/main/Debian-PHP-Composer-Docker-Firewall-Pterodactyl-Wings-Installation.md)**  
   نصب سیستم‌عامل، SSH، UFW، PHP/Composer، دیتابیس، Panel، Docker، Wings، Queue Worker و Scheduler. مقادیر دامنه، hostname، IP و حساب Linux در بخش 0.3 قابل تنظیم‌اند.

2. **[آموزش K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop Cache](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md)**  
   آموزش مستقل واردکردن Egg، نصب دقیق cs2node، پیش‌نیاز i386 برای Debian amd64، راه‌اندازی Shared Base، VPK Sync، انتقال کنترل‌شدهٔ فایل‌ها و آزمایش Instance دوم.

3. **[آموزش Full Clone و VMDK در VMware Workstation](https://github.com/larnzs/linux-node/blob/main/test-vmdk%20instructions.md)**  
   ساخت Full Clone، نگهداری VM اصلی، تغییر Port Forwardها، health check، افزودن اختیاری دیسک داده و بازگشت امن به VM اصلی.

4. **[آموزش WinSCP — اتصال SFTP با کلید SSH](https://github.com/larnzs/linux-node/blob/main/%D8%A2%D9%85%D9%88%D8%B2%D8%B4%20winscp.md)**  
   اتصال گرافیکی از Windows به Linux، تنظیم کاربر/IP/کلید خودت، انتقال فایل‌ها، مدیریت مجوزها و مشاهدهٔ فقط‌خواندنی فایل‌های root.

## قبل از Copy/Paste

- مقادیر FragCity مانند hostname، IP، FQDN، username و پورت فقط نمونه‌اند. در هر Runbook جدول مقادیر را بررسی کن و مقدارهای متعلق به محیط خودت را تنظیم کن.
- فرمان‌های Clone را فقط در سناریوی Clone اجرا کن. VM اصلی و Clone با هویت فعلی نباید هم‌زمان روشن باشند.
- پیش از format یا mount دیسک، آن را با lsblk و blkid شناسایی کن؛ اسم دستگاه را حدس نزن.
- Debian 13 amd64 برای SteamCMD به Runtimeهای i386 نیاز دارد. در آموزش K4ryuu این پیش‌نیاز قبل از فرمان نصب cs2node آمده است.
- Base مرکزی CS2 در /srv/cs2-shared قرار می‌گیرد؛ Workshop Cache در /srv/cs2-workshop ساختار و metadata متفاوتی دارد. فایل‌های Workshop را خام به مسیر Cache مرکزی نریز.
- هیچ Webhook URL، GSLT، Token، APP_KEY، رمز دیتابیس، فایل .env یا config.yml محرمانه‌ای را در GitHub یا چت منتشر نکن.

## Checkpoint اجرای فعلی FragCity — 2026-10-19

این بخش فقط وضعیت همین آزمایش را ثبت می‌کند؛ برای انجام نصب تازه از راهنماهای بالا پیروی کن.

- Clone: hostname fc-node-01، IP 192.168.1.9. VM اصلی با IP 192.168.1.7 باید خاموش بماند.
- Panel، Docker، Wings، Queue Worker و Scheduler روی Clone قبلاً تنظیم شده‌اند.
- Instance آزمایشی fc-cs2-test-01 ساخته شده و دانلود standalone اولیه طبق گزارش پایان یافته است.
- cs2node نصب شده و سرویس active/enabled است. Moduleهای vpksync، alerts، addoncache، workshop، backup، cleanup، crashes، consolelog و metrics روشن‌اند؛ guard خاموش است.
- Runtimeهای i386 نصب شده‌اند و آزمون sudo /root/steamcmd/steamcmd.sh +quit با پیام‌های Loading Steam API...OK و Unloading Steam API...OK موفق بوده است.
- پس از Restart، vpksync مقدار build=0 گزارش کرد؛ در بررسی Base مرکزی Manifest وجود نداشت و VPK count صفر بود. این وضعیت به‌تنهایی نمی‌گوید تلاش بعدی هنوز فعال است یا شکست خورده؛ قدم بعدی اجرای بلوک تشخیصی فقط‌خواندنی در بخش 7.2 راهنمای K4ryuu است.
- پس از شروع/تأیید دانلود، انتقال VPKهای asset با WinSCP فقط در زمان توقف قطعی SteamCMD انجام می‌شود. Workshop جداگانه و فقط با ساختار و ACF مناسب خودش وارد Cache خواهد شد.
- URL وب‌هوک Discord پیش‌تر در لاگ چت افشا شده است. اگر هنوز انجام نشده، وب‌هوک قبلی را در Discord باطل و با مقدار تازه جایگزین کن؛ مقدار جدید را در مستندات ثبت نکن.

## نکتهٔ نگهداری مستندات

نتیجه‌های اجرای مختص این VM را فقط در همین Checkpoint خلاصه کن. متن آموزش‌ها باید مستقل از IP/hostname فعلی قابل‌فهم باشد و در هر مرحله فرمان دقیق، پیش‌نیاز، روش تأیید و مسیر عیب‌یابی داشته باشد.
