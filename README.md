# FragCity Linux Node — راهنمای نصب و راه‌اندازی

این ریپو شامل آموزش‌های مرحله‌ای برای نصب زیرساخت Debian/Pterodactyl، ساخت محیط آزمایشی VMware و راه‌اندازی CS2 با Egg رسمی K4ryuu است. هر راهنما باید مستقل از IP و hostname نمونه قابل استفاده باشد؛ قبل از اجرای دستورها، بخش مقادیر محیطی همان راهنما را با اطلاعات واقعی خودت تطبیق بده.

## مسیر پیشنهادی مطالعه و اجرا

1. **[نصب Debian 13، PHP، Composer، Docker، Firewall، Pterodactyl و Wings](https://github.com/larnzs/linux-node/blob/main/Debian-PHP-Composer-Docker-Firewall-Pterodactyl-Wings-Installation.md)**  
   نصب سیستم‌عامل، SSH/UFW، PHP و Composer، پایگاه داده، Panel، Docker، Wings، Queue Worker و Scheduler. از این راهنما برای آماده‌سازی زیرساخت استفاده کن.

2. **[آموزش K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop Cache](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md)**  
   پیش‌نیازهای Debian amd64، فرمان دقیق نصب cs2node، تنظیم Wizard، دانلود/بررسی Shared Base، انتقال کنترل‌شدهٔ VPKها و Workshop، و اثبات کارکرد دو Instance.

3. **[آموزش Full Clone و VMDK در VMware Workstation](https://github.com/larnzs/linux-node/blob/main/test-vmdk%20instructions.md)**  
   فقط در صورت نیاز به Clone آزمایشی: ساخت Full Clone، حفظ VM اصلی، تغییر و بازگردانی Port Forward، اجرای health check و افزودن اختیاری VMDK. این راهنما دستورهای Clone را از نصب عادی Node جدا می‌کند.

4. **[آموزش WinSCP — اتصال SFTP با کلید SSH](https://github.com/larnzs/linux-node/blob/main/%D8%A2%D9%85%D9%88%D8%B2%D8%B4%20winscp.md)**  
   اتصال گرافیکی از Windows به Linux، تنظیم IP/port/user/key خودت، انتقال فایل‌ها، فهم مجوزها و روش اختیاری و فقط‌خواندنی مشاهدهٔ فایل‌های root.

## پیش از Copy/Paste

- **مقادیر محیطی:** hostname، IP داخلی، دامنه/FQDN، subnet شبکه، نام کاربر Linux، مسیر نصب Panel و پورت‌های Node باید با محیط واقعی تو هماهنگ باشند. مقادیر 192.168.1.7، 192.168.1.9، fc-node-01 و fragcity.ir در راهنماها نمونه‌های یک محیط مشخص‌اند، نه مقادیر عمومی.
- **مکان اجرای فرمان:** مشخص کن دستور باید در Windows PowerShell، نشست SSH روی Debian، prompt دیتابیس یا داخل یک فایل تنظیمات اجرا شود. JSON، YAML و NGINX config را در Bash اجرا نکن.
- **Storage:** پیش از هر عملیات partition/format/mount، دستگاه را با lsblk و blkid شناسایی کن؛ نامی مثل /dev/sdb را حدس نزن.
- **CS2 و i386:** در Debian amd64، Runtimeهای سازگار i386 را طبق راهنمای K4ryuu، قبل از نصب cs2node و اولین Update مرکزی نصب کن.
- **Shared Base و Workshop:** بازی در /srv/cs2-shared و Workshop Cache در /srv/cs2-workshop دو ساختار مجزا هستند. فایل‌های بازی یا Workshop را بدون حفظ ساختار و metadata مربوط مستقیماً به Cache مرکزی کپی نکن.
- **ترتیب آزمون:** اول Base مرکزی را با cs2node doctor/status، Manifest، Build ID و VPK count تأیید کن؛ سپس Instance اول را آزمایش و بعد Instance دوم را بساز. تا قبولی Multi Instance، پلاگین‌های FragCity/KUS را وارد این مسیر نکن.
- **Clone:** اگر Clone موقتاً جای VM اصلی را می‌گیرد، دو VM با هویت مشترک را هم‌زمان روشن نکن. مقصد Port Forward و IP را هنگام شروع/پایان تست با دقت عوض کن. برای Node دوم مستقل، از هویت و config اختصاصی استفاده کن.
- **Secrets:** رمزها، APP_KEY، Token، GSLT، Webhook URL، فایل .env و محتوای محرمانهٔ /etc/pterodactyl/config.yml را در GitHub یا چت منتشر نکن. اگر Webhook افشا شد، آن را باطل و دوباره بساز.

## گزارش اجرای جاری

برای وضعیت واقعی آزمون cs2node، خروجی آخرین مرحله و قدم بعدی فقط‌خواندنی، از [Checkpoint آزمایش cs2node](https://github.com/larnzs/linux-node/blob/main/%D9%88%D8%B6%D8%B9%DB%8C%D8%AA%20%D9%81%D8%B9%D9%84%DB%8C%20%D8%A2%D8%B2%D9%85%D8%A7%DB%8C%D8%B4%20cs2node.md) استفاده کن. این گزارش جدا از آموزش‌های تکرارپذیر نگه داشته می‌شود.

## استاندارد هر آموزش

هر بخش را به ترتیب اجرا کن: **پیش‌نیاز → فرمان دقیق → نتیجهٔ مورد انتظار → معیار قبولی → عیب‌یابی**. اگر یکی از معیارهای قبولی برقرار نیست، به مرحلهٔ بعد نرو و ابتدا خروجی فقط‌خواندنی همان مرحله را بررسی کن. لاگ اجرای یک VM خاص را در سند آموزشی دائمی جایگزین دستورالعمل نکن؛ راهنما باید برای نصب‌های بعدی قابل استفاده بماند.

## وضعیت اجرای فعلی (گزارش عملیاتی، نه آموزش)

برای ادامهٔ آزمون زندهٔ FragCity، وضعیت جاری را در [checkpoint دانلود cs2node](https://github.com/larnzs/linux-node/blob/main/cs2node-download-current-checkpoint.md) ببین. این فایل از راهنماهای آموزشی جداست؛ برای نصب جدید، دستورالعمل عمومی همان راهنماها را اجرا و مقادیر محیطی خودت را جایگزین کن.
