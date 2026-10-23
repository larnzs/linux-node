# FragCity Linux Node — راهنمای نصب و راه‌اندازی

این مخزن شامل آموزش‌های قابل‌تکرار برای Debian، زیرساخت Pterodactyl، اتصال WinSCP، ساخت Clone آزمایشی VMware و راه‌اندازی CS2 با K4ryuu است. راهنماهای آموزشی باید برای کاربری با hostname، IP و دامنهٔ متفاوت هم قابل استفاده باشند؛ گزارش وضعیت یک اجرای خاص در فایل Checkpoint جدا نگهداری می‌شود.

## راهنمای Git در ویندوز

- **[آموزش Push کردن پروژه از ویندوز به GitHub با Git](https://github.com/larnzs/linux-node/blob/main/Windows-GitHub-Push-Project.md)** — نصب Git و GitHub CLI، ورود امن، بررسی فایل‌های حساس، تنظیم Remote، Commit و Push، به‌همراه عیب‌یابی خطای احراز هویت.

## شبکه، NAT و فایروال MikroTik

- **[عیب‌یابی Hairpin NAT، Firewall و خطای TLS/Steam SDR در MikroTik داخل VMware](https://github.com/larnzs/linux-node/blob/main/MikroTik-VMware-Hairpin-NAT-and-Pterodactyl-Port-Forwarding.md)** — علت Drop شدن Hairpin ترافیک در Firewall و مهم‌تر از آن، DNAT بیش‌ازحد گسترده که HTTPS خروجی به Steam/Google را به Panel برمی‌گرداند؛ شامل لاگ گواهی اشتباه، محدودکردن Ruleهای LAN با `dst-address-list`، اصلاح Filter و چک‌لیست تست امن Pterodactyl.

## عیب‌یابی CS2 و CounterStrikeSharp

- **[رفع خطای inotify و شکست راه‌اندازی .NET در CounterStrikeSharp](https://github.com/larnzs/linux-node/blob/main/CounterStrikeSharp-inotify-Limits-Debian-Pterodactyl.md)** — تشخیص تفاوت سقف inotify instances، watches و فایل‌دسکریپتورهای پردازش؛ افزایش موقت و دائمی `max_user_instances`، بررسی PID و لاگ سرورهای Pterodactyl، آزمون پس از Restart و عیب‌یابی در صورت باقی‌ماندن خطا.

## ترتیب پیشنهادی مطالعه

1. **[نصب Debian 13، PHP، Composer، Docker، Firewall، Pterodactyl و Wings](https://github.com/larnzs/linux-node/blob/main/Debian-PHP-Composer-Docker-Firewall-Pterodactyl-Wings-Installation.md)** — برای نصب تازهٔ زیرساخت، از Debian Base تا Online شدن Node.
2. **[آموزش ساخت یوزر مدیریتی MariaDB محدود به 127.0.0.1](https://github.com/larnzs/linux-node/blob/main/MariaDB-Local-Admin-User.md)** — ساخت حساب دارای دسترسی سراسری، اعطای مجوزها، آزمایش اتصال TCP محلی و بررسی تفاوت Host حساب با bind-address سرویس.
3. **[اتصال کانتینرهای Pterodactyl به MariaDB میزبان با UFW](https://github.com/larnzs/linux-node/blob/main/Pterodactyl-Docker-MariaDB-UFW-Connectivity.md)** — بررسی bind-address، پیدا کردن رابط Gateway، اجازه محدود TCP/3306 در UFW، تست TCP از داخل کانتینر و عیب‌یابی مجوزهای دیتابیس.
3. **[آموزش K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop Cache](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md)** — پیش‌نیاز i386 روی amd64، واردکردن Egg، دستور نصب cs2node، تنظیم Wizard، Shared Base، Workshop و آزمون Multi Instance.
4. **[آموزش WinSCP](https://github.com/larnzs/linux-node/blob/main/%D8%A2%D9%85%D9%88%D8%B2%D8%B4%20winscp.md)** — اتصال SFTP با SSH key، دسترسی فایل‌ها و انتقال امن از مسیر staging.
5. **[عیب‌یابی SSH در ویندوز و ورود موقت با رمز](https://github.com/larnzs/linux-node/blob/main/Windows-SSH-Private-Key-Permissions.md)** — اصلاح Permission کلید خصوصی بعد از نصب مجدد Windows، فعال‌سازی موقت ورود با رمز در Debian و بازگشت به ورود کلیدی.
6. **[آموزش Full Clone و VMDK در VMware Workstation](https://github.com/larnzs/linux-node/blob/main/test-vmdk%20instructions.md)** — فقط وقتی به Clone جایگزین یا دیسک دادهٔ آزمایشی نیاز داری؛ برای نصب عادی Node الزامی نیست.

## قبل از اجرای دستورها

- دستورها را فقط در محل ذکرشده اجرا کن: Windows PowerShell، Debian host از طریق SSH، Panel، یا فایل پیکربندی. دستورهای host را داخل Container بازی اجرا نکن.
- hostname، IP، FQDN، نام کاربر، پورت‌ها، مسیر فایل‌ها و Allocationهای نمونه را با محیط خودت جایگزین کن. اگر Placeholder باقی مانده، بلوک را اجرا نکن.
- در Debian amd64، پیش‌نیاز Runtimeهای i386 باید پیش از نصب cs2node و اولین Update مرکزی تکمیل و با `steamcmd.sh +quit` آزمایش شود.
- برای Storage، پیش از partition/format/mount دستگاه را با `lsblk` و `blkid` شناسایی کن؛ اسم دیسک را حدس نزن.
- برای Shared VPK، Base مرکزی `/srv/cs2-shared` و Workshop Cache `/srv/cs2-workshop` دو ساختار جدا هستند. فایل خام را بدون مسیر و metadata لازم داخل Cache کپی نکن.
- تا زمانی که Manifest/Build ID و VPKهای Base تأیید نشده‌اند، سرور را Start نکن. ابتدا Instance اول را تأیید کن، سپس Instance دوم؛ پلاگین‌های اختصاصی را بعد از قبولی Multi Instance اضافه کن.
- Clone موقت که هویت VM اصلی را به ارث برده نباید هم‌زمان با VM اصلی روشن باشد.
- هرگز رمز، APP_KEY، Token، GSLT، Webhook URL، فایل `.env` یا محتوای محرمانهٔ config را در GitHub ثبت نکن. Webhook افشاشده را در ارائه‌دهنده باطل و جایگزین کن.

## روش استفاده از هر راهنما

هر فصل را به ترتیب اجرا کن: **پیش‌نیاز → فرمان دقیق → خروجی مورد انتظار → معیار قبولی → عیب‌یابی**. اگر معیار قبولی پاس نشد، جلو نرو و ابتدا خروجی تشخیصی همان مرحله را بررسی کن. از اجرای تکراری فرمان‌های تغییر‌دهنده بدون فهم خطا خودداری کن.

## گزارش وضعیت اجرای فعلی

این فایل‌ها فقط برای ادامهٔ اجرای مشخص FragCity هستند و جایگزین آموزش عمومی نیستند:

- [Checkpoint وضعیت دانلود cs2node](https://github.com/larnzs/linux-node/blob/main/cs2node-download-current-checkpoint.md)
- [گزارش اجرای آزمایشی cs2node](https://github.com/larnzs/linux-node/blob/main/%D9%88%D8%B6%D8%B9%DB%8C%D8%AA%20%D9%81%D8%B9%D9%84%DB%8C%20%D8%A2%D8%B2%D9%85%D8%A7%DB%8C%D8%B4%20cs2node.md)
