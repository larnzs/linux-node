# FragCity — راهنمای مادرِ Copy/Paste از Debian تا سرورهای CS2

> **این فایل مرجع اجرایی واحد پروژه است.** از اینجا به بعد توضیحات، ترتیب اجرا، تصمیم‌های فنی و بلوک‌های Copy/Paste در همین README نوشته می‌شوند. خروجی ترمینال، لاگ واقعی، رمزها و نتیجهٔ اجرای فرمان‌ها در README ثبت نمی‌شوند؛ لاگ لازم برای عیب‌یابی را فقط در گفت‌وگو بفرست. بعد از هر مرحله فقط مرحلهٔ جاری را اجرا کن و برای ادامه، به‌روزرسانی README را بخوان.
>
> **وضعیت فعلی: Debian Console-only آماده‌سازی شده و SSH key/hardening تا 1.19.3 گزارش شده است.** اولویت فوری: مرحلهٔ 1.17.1 برای بررسی و غیرفعال‌کردن مدیریت مودم از WAN؛ نمایش صفحهٔ مودم روی IP عمومی از LAN به‌تنهایی ثابت نمی‌کند که از اینترنت هم قابل‌دسترسی است. سپس UFW در 1.19.4، تأیید 1.20 و Snapshot در 1.21؛ نصب Panel فقط پس از این بررسی‌ها. Panel، Docker، Wings و CS2 هنوز روی این Debian تازه نصب نشده‌اند.
>
> **قانون secrets:** رمز MariaDB، رمز حساب، APP_KEY، token، فایل .env و محتوای /etc/pterodactyl/config.yml را در GitHub یا چت قرار نده. مقادیر نمونه را فقط به‌صورت محلی جایگزین کن.

---

## 0. وضعیت، محدوده و خط قرمزها

- هدف این است که **همین VM با نام `fc-node-01`** را از ابتدا با Debian 13 بدون محیط گرافیکی آماده کنیم.
- در نصاب وارد شده: **Hostname** = `fc-node-01` و **Domain name** = `fragcity.ir`. نام کامل موردنظر برای Node برابر `fc-node-01.fragcity.ir` است.
- آدرس موردنظر پنل: `panel.fragcity.ir`. طرح DNS برای بعد از نصب: هر دو نام `panel.fragcity.ir` و `fc-node-01.fragcity.ir` باید از طریق رکورد A به IP عمومی قابل‌دسترسی میزبان اشاره کنند. رکوردهای DNS هنوز در این سند به‌عنوان ساخته‌شده فرض نمی‌شوند؛ آن‌ها را در DNS authoritative دامنه (cPanel فقط اگر همان‌جا DNS مدیریت می‌شود) ثبت و بعد بررسی می‌کنیم.
- پرکردن فیلد Domain name در نصاب به‌تنهایی DNS، IP عمومی، Port Forwarding یا HTTPS را فعال نمی‌کند.
- هنگام نصب Debian 13، در صفحهٔ Software selection گزینهٔ `Debian desktop environment` را بردار و `SSH server` و `standard system utilities` را نگه دار. مدیریت با SSH از Windows و مرورگر Windows انجام می‌شود؛ محیط گرافیکی Debian لازم نیست. راهنما: https://wiki.debian.org/DesktopEnvironment
- VM فعلی روی VMware و Debian 13/Trixie است. IP، منابع و دیسک را بعد از شروع مجدد با بلوک بررسی مرحلهٔ 0 مشخص کن؛ از اعداد قدیمی برای نصب مجدد استفاده نکن.
- Panel جدید هنوز روی این Debian نصب نشده است؛ نشانی نهایی آن `https://panel.fragcity.ir` خواهد بود. مسیرهای `/var/www/pterodactyl` و تنظیمات Panel فقط بعد از نصب در مراحل آینده ایجاد می‌شوند.
- فایل‌های CS2/KUS متعلق به VMDK سیستم قبلی هستند که کاربر آن را نگه داشته است. **در نصب تازه آن دیسک را overwrite یا بدون طرح مشخص mount نکن.** این مسیر بازی در Debian تازه فرض نمی‌شود؛ نصب/آزمایش CS2 در فاز جداگانه و روی محیط آزمایشگاهی انجام خواهد شد.
- تا بررسی مدل Storage/Egg، هیچ سرور بازی تازه‌ای از Egg نساز؛ ممکن است بازی را دوباره دانلود و فضای دیسک را پر کند.
- فعلاً Port Forwarding عمومی، دامنه و HTTPS نداریم. این PoC فقط در LAN و روی HTTP است.

### 0.1 حفاظت از دیسک قبلی

فایل‌های VMDK مربوط به Debian Desktop قبلی نزد کاربر موجود هستند. **آن VMDK پشتیبان را در طول نصب جاری به‌عنوان دیسک مقصد انتخاب نکن و آن را overwrite نکن.** نصب روی دیسک مقصد، تمام داده‌های همان دیسک را پاک خواهد کرد.

### 0.2 قرارداد اجرای مرحله‌ای

- از این نقطه، فقط **بلوک مرحلهٔ جاری** را کپی و اجرا کن؛ به مراحل بعدی نپر.
- هر بلوک، محل اجرا را مشخص می‌کند: `PowerShell` یعنی پنجرهٔ Windows که prompt آن با `PS C:\\...` شروع می‌شود؛ `bash` یعنی نشست SSH که prompt آن شبیه `sv1@fc-node-01:~# FragCity — راهنمای مادرِ Copy/Paste از Debian تا سرورهای CS2

> **این فایل مرجع اجرایی واحد پروژه است.** از اینجا به بعد توضیحات، ترتیب اجرا، تصمیم‌های فنی و بلوک‌های Copy/Paste در همین README نوشته می‌شوند. خروجی ترمینال، لاگ واقعی، رمزها و نتیجهٔ اجرای فرمان‌ها در README ثبت نمی‌شوند؛ لاگ لازم برای عیب‌یابی را فقط در گفت‌وگو بفرست. بعد از هر مرحله فقط مرحلهٔ جاری را اجرا کن و برای ادامه، به‌روزرسانی README را بخوان.
>
> **وضعیت فعلی: نصب Console-only و مراحل پایهٔ 1.9 تا 1.14 تکمیل شده‌اند.** مرحلهٔ جاری: مراحل 1.15 تا 1.19 برای بررسی hostname، رزرو DHCP، بررسی IPv4 عمومی/CGNAT، DNS عمومی، کلید و سخت‌سازی SSH و Firewall. Panel، Docker، Wings و instance بازی CS2 هنوز روی این Debian تازه نصب نشده‌اند.
>
> **قانون secrets:** رمز MariaDB، رمز حساب، APP_KEY، token، فایل .env و محتوای /etc/pterodactyl/config.yml را در GitHub یا چت قرار نده. مقادیر نمونه را فقط به‌صورت محلی جایگزین کن.

---

## 0. وضعیت، محدوده و خط قرمزها

- هدف این است که **همین VM با نام `fc-node-01`** را از ابتدا با Debian 13 بدون محیط گرافیکی آماده کنیم.
- در نصاب وارد شده: **Hostname** = `fc-node-01` و **Domain name** = `fragcity.ir`. نام کامل موردنظر برای Node برابر `fc-node-01.fragcity.ir` است.
- آدرس موردنظر پنل: `panel.fragcity.ir`. طرح DNS برای بعد از نصب: هر دو نام `panel.fragcity.ir` و `fc-node-01.fragcity.ir` باید از طریق رکورد A به IP عمومی قابل‌دسترسی میزبان اشاره کنند. رکوردهای DNS هنوز در این سند به‌عنوان ساخته‌شده فرض نمی‌شوند؛ آن‌ها را در DNS authoritative دامنه (cPanel فقط اگر همان‌جا DNS مدیریت می‌شود) ثبت و بعد بررسی می‌کنیم.
- پرکردن فیلد Domain name در نصاب به‌تنهایی DNS، IP عمومی، Port Forwarding یا HTTPS را فعال نمی‌کند.
- هنگام نصب Debian 13، در صفحهٔ Software selection گزینهٔ `Debian desktop environment` را بردار و `SSH server` و `standard system utilities` را نگه دار. مدیریت با SSH از Windows و مرورگر Windows انجام می‌شود؛ محیط گرافیکی Debian لازم نیست. راهنما: https://wiki.debian.org/DesktopEnvironment
- VM فعلی روی VMware و Debian 13/Trixie است. IP، منابع و دیسک را بعد از شروع مجدد با بلوک بررسی مرحلهٔ 0 مشخص کن؛ از اعداد قدیمی برای نصب مجدد استفاده نکن.
- Panel جدید هنوز روی این Debian نصب نشده است؛ نشانی نهایی آن `https://panel.fragcity.ir` خواهد بود. مسیرهای `/var/www/pterodactyl` و تنظیمات Panel فقط بعد از نصب در مراحل آینده ایجاد می‌شوند.
- فایل‌های CS2/KUS متعلق به VMDK سیستم قبلی هستند که کاربر آن را نگه داشته است. **در نصب تازه آن دیسک را overwrite یا بدون طرح مشخص mount نکن.** این مسیر بازی در Debian تازه فرض نمی‌شود؛ نصب/آزمایش CS2 در فاز جداگانه و روی محیط آزمایشگاهی انجام خواهد شد.
- تا بررسی مدل Storage/Egg، هیچ سرور بازی تازه‌ای از Egg نساز؛ ممکن است بازی را دوباره دانلود و فضای دیسک را پر کند.
- فعلاً Port Forwarding عمومی، دامنه و HTTPS نداریم. این PoC فقط در LAN و روی HTTP است.

### 0.1 حفاظت از دیسک قبلی

فایل‌های VMDK مربوط به Debian Desktop قبلی نزد کاربر موجود هستند. **آن VMDK پشتیبان را در طول نصب جاری به‌عنوان دیسک مقصد انتخاب نکن و آن را overwrite نکن.** نصب روی دیسک مقصد، تمام داده‌های همان دیسک را پاک خواهد کرد.

### 0.2 قرارداد اجرای مرحله‌ای

 است. نحو این دو محیط متفاوت است؛ کد PowerShell را داخل Bash اجرا نکن.
- خروجی دستورها و لاگ‌ها فقط در چت بررسی می‌شوند و در این README ثبت نمی‌شوند.
- رمز، APP_KEY، Token، کلید خصوصی SSH و فایل‌های محرمانه را در چت یا GitHub قرار نده.
- در مسیر جدید، تا قبل از تأیید مرحلهٔ جاری، دستور مرحلهٔ بعد اجرا نشود.
- به مراحل Panel، Docker و Wings نپر؛ ابتدا نصب پایهٔ Debian Console-only و دسترسی امن SSH را کامل می‌کنیم.

---

## 1. نصب Debian 13 از صفر — Console-only

این مرحله از طریق نصاب Debian در VMware انجام می‌شود. **وضعیت فعلی: Partitioning method.** دستورهای بعدی پس از کامل‌شدن همین مرحله اجرا می‌شوند.

### 1.1 نام‌گذاری در نصاب

مقادیر واردشده:
- **Hostname:** `fc-node-01`
- **Domain name:** `fragcity.ir`
- **FQDN موردنظر Node:** `fc-node-01.fragcity.ir`
- **FQDN موردنظر Panel:** `panel.fragcity.ir`

تنظیم DNS، HTTPS و دسترسی عمومی بعد از نصب و بررسی اتصال شبکه انجام می‌شود؛ فیلد Domain name جایگزین آن‌ها نیست.

### 1.2 Disk partitioning scheme — صفحهٔ فعلی

در این صفحه، گزینهٔ **All files in one partition (recommended for new users)** را انتخاب کن. این باعث می‌شود فضای فایل‌های سیستم، Docker و مسیر پیش‌فرض volumeهای Pterodactyl زیر `/var/lib/pterodactyl/volumes` از ابتدا به چند پارتیشن جدا با اندازه‌های ثابت تقسیم نشود. با LVM می‌توان بعداً Volumeها را مدیریت کرد، اما LVM خودش فضای فیزیکی اضافه نمی‌کند.

اگر هنوز انتخاب نکرده‌ای، **Encrypted LVM را انتخاب نکن**؛ ماشین باید پس از reboot بدون واردکردن passphrase در کنسول بالا بیاید.

### 1.3 بازبینی جدول پارتیشن‌ها و تأیید نوشتن

1. پس از انتخاب scheme، گزینهٔ Continue را بزن تا جدول پارتیشن‌های پیشنهادی نمایش داده شود.
2. پیش از تأیید، دوباره کنترل کن که دیسک مقصد همان VMDK جدید برای این نصب است و ظرفیت آن با برنامه مطابقت دارد. پیشنهاد شروع برای Node میزبان CS2 حداقل **250 GB** است؛ برای چندین نصب بازی/instance ممکن است فضای بیشتری لازم شود.
3. در جدول LVM، وجود پارتیشن بوت و Logical Volume مربوط به ریشه `/` و swap طبیعی است. چون LVM انتخاب شده، وجود پارتیشن جداگانهٔ `/boot` نیز طبیعی است.
4. فقط وقتی مطمئن شدی دیسک درست انتخاب شده، **Finish partitioning and write changes to disk** را انتخاب کن، Continue را بزن و در تأیید نهاییِ نوشتن تغییرات روی دیسک گزینهٔ **Yes** را انتخاب کن.
5. اگر ظرفیت یا نام دیسک اشتباه است، گزینهٔ **No / Go Back** را بزن. دیسک قبلی/پشتیبان را فرمت نکن.

### 1.4 نصب Base System

پس از تأیید پارتیشن‌بندی، Debian پارتیشن‌ها را فرمت می‌کند و سیستم پایه را نصب می‌کند. این مرحله را تا بازگشت صفحهٔ نصاب صبر کن؛ دکمهٔ Cancel یا خاموش‌کردن VM را نزن.

### 1.5 پیکربندی APT و Network Mirror

در صورت نمایش این سؤال‌ها:

1. **Scan additional installation media?** — اگر فقط همان ISO نصب را داری، **No**.
2. **Use a network mirror?** — **Yes**؛ سرور به بسته‌ها و به‌روزرسانی‌های امنیتی از اینترنت نیاز دارد.
3. **Mirror country** — کشور نزدیک و قابل‌دسترسی را انتخاب کن؛ سپس mirror پیش‌فرض پیشنهادی نصاب، معمولاً `deb.debian.org`، را نگه دار.
4. **HTTP proxy information** — اگر Proxy سازمانی تعریف نکرده‌ای، خالی بگذار و Continue کن.
5. اگر دریافت mirror شکست خورد، انتخاب mirror را یادداشت کن و خطای نصاب را بفرست؛ قبل از تکمیل نصب، به تنظیمات تصادفی DNS یا proxy تغییر نده.

Debian عموماً استفاده از network mirror را پیشنهاد می‌کند، و آدرس `deb.debian.org` گزینهٔ پیش‌فرض مناسبی است. راهنمای رسمی: https://www.debian.org/releases/trixie/amd64/install.en.pdf (بخش‌های 6.3.6.1 و 6.3.6.2).

### 1.6 Software selection — نصب Console-only

وقتی صفحهٔ **Software selection** یا **Software selection and install** را دیدی، فقط این گزینه‌ها باید تیک داشته باشند:

- [x] **SSH server**
- [x] **standard system utilities**

و این گزینه باید **تیک نداشته باشد**:

- [ ] **Debian desktop environment**

هر گزینهٔ Desktop مانند GNOME/Xfce/KDE، و نیز Web server یا Print server را برای این مرحله انتخاب نکن. وب‌سرور Panel را بعداً به‌صورت کنترل‌شده با NGINX نصب می‌کنیم؛ Apache پیش‌فرض لازم نیست. سپس Continue را بزن و تا پایان نصب بسته‌ها صبر کن.

### 1.7 نصب GRUB Boot Loader

وقتی نصاب پرسید **Install the GRUB boot loader to your primary drive?** گزینهٔ **Yes** را انتخاب کن.

در صفحهٔ **Device for boot loader installation**:

1. اگر فهرست شامل دیسک کاملِ مقصد، مثلاً `/dev/sda` همراه با توضیح/ظرفیت آن است، همان ورودی را انتخاب کن؛ به‌جای ورود دستی، این روش بهتر است.
2. اگر **Enter device manually** را انتخاب کرده‌ای و فیلد متن باز شده، مسیر باید نام **کل دیسک** باشد. اگر دیسک مقصدِ این VM واقعاً `/dev/sda` است، بنویس:
   
   ~~~text
   /dev/sda
   ~~~

3. `/dev/sda1` پارتیشن اول دیسک است، نه کل دیسک؛ برای حالت معمول نصب GRUB به دیسک سیستم، آن را وارد نکن. اسلش انتهایی هم نگذار.
4. نام دستگاه ممکن است با توجه به نوع مجازی‌سازی/کنترلر فرق کند: `/dev/sda`، `/dev/vda` یا `/dev/nvme0n1`. فقط دستگاهی را وارد کن که نام و ظرفیتش با دیسک مقصد Debian تطبیق دارد؛ اسم را حدس نزن.
5. اگر بیش از یک دیسک در فهرست وجود دارد، یا فقط پارتیشن‌هایی مثل `/dev/sda1` می‌بینی و نمی‌توانی دیسک کامل را شناسایی کنی، به‌جای تأیید یا حدس‌زدن، توقف کن و از صفحه عکس بفرست.

در حالت انتخاب دستگاه دستی، نصاب مسیر دقیق دستگاه را می‌خواهد؛ این مسیر URL یا مسیر یک پوشه نیست. راهنما: https://wiki.debian.org/DebianInstaller/Bugs/GrubInstaller و https://www.debian.org/doc/manuals/debian-handbook/sect.config-bootloader.da.html.

### 1.8 پایان نصب و اولین reboot

1. وقتی پیام **Installation complete** یا **Finish the installation** نمایش داده شد، Continue را بزن.
2. اگر VM دوباره به نصاب برگشت، در VMware از تنظیمات CD/DVD فایل ISO را Disconnect کن یا اتصال ISO هنگام بوت را خاموش کن؛ باید از دیسک مجازی Debian بوت شود.
3. در صفحهٔ Console باید به صفحهٔ login متنی برسد. ورود کاربر را خودت انجام بده؛ نام کاربری و رمز را در README ثبت نکن.

### 1.9 مرحلهٔ اول — شناسایی اولیهٔ سیستم

پس از نمایش `fc-node-01 Login:` وارد حسابی شو که هنگام نصب ساخته‌ای. نام حساب و رمز را در README یا چت ننویس. سپس این بلوک فقط‌خواندنی را اجرا کن:

~~~bash
set -u

echo "=== OS ==="
cat /etc/os-release

echo
echo "=== Account and hostname ==="
id
groups
hostname
hostname -f || true

echo
echo "=== Network ==="
ip -br address
ip route

echo
echo "=== CPU, RAM and storage ==="
lscpu | grep -E '^(Architecture|CPU\(s\)|Model name|Thread|Core|Socket)'
free -h
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
df -hT /

echo
echo "=== Clock and virtualization ==="
timedatectl status
systemd-detect-virt || true
~~~

این مرحله تغییری نمی‌دهد. اگر سیستم با نامی غیر از `fc-node-01` بالا آمده یا دیسک مقصد غیرمنتظره است، پیش از مراحل بعدی خروجی را بفرست.

### 1.10 مرحلهٔ دوم — به‌روزرسانی Debian و آماده‌سازی sudo

فقط اگر مرحلهٔ اول نشان داد سیستم Debian 13 (Trixie) است، سیستم را به‌روزرسانی کن.

**مسیر معمول، اگر `sudo` از قبل نصب است و کاربر اجازهٔ مدیریتی دارد:**

~~~bash
set -eu
sudo apt update
sudo apt full-upgrade -y
~~~

**اگر با پیام `sudo: command not found` روبه‌رو شدی:** این یعنی فرمان `sudo` نصب نیست؛ حتی اگر با حساب root وارد شده باشی، اجرای `sudo apt update` کار نمی‌کند. در نشست SSH با حساب عادی، وارد shell کاربر root شو:

~~~bash
su -
~~~

رمز حساب root را وارد کن؛ هنگام تایپ چیزی نمایش داده نمی‌شود. وقتی prompt متعلق به root شد، دستورهای زیر را بدون `sudo` اجرا کن:

~~~bash
set -eu
apt update
apt full-upgrade -y
apt install -y sudo
usermod -aG sudo DEBIAN_USERNAME
~~~

در فرمان آخر، `DEBIAN_USERNAME` را با نام واقعی حساب عادی Debian جایگزین کن؛ نام root را ننویس. سپس `exit` بزن تا به حساب عادی برگردی، یک بار دیگر `exit` بزن تا از SSH خارج شوی و دوباره با همان حساب عادی وصل شو. بررسی کن:

~~~bash
sudo -v
sudo apt update
~~~

پس از نصب sudo و اضافه‌کردن حساب به گروه sudo، از این به بعد بلوک‌های بعدی README را از نشست تازهٔ SSH با حساب عادی اجرا کن. اگر `su -` هم رمز root را نپذیرفت، به‌جای فعال‌کردن ورود root از طریق SSH یا تغییر تصادفی تنظیمات، وضعیت رمز حساب root را از کنسول VMware بررسی کن.

اگر APT دربارهٔ حذف بسته‌های مهم یا خطای Repository هشدار داد، ادامه نده و پیام را بررسی کن.

### 1.11 مرحلهٔ سوم — نصب ابزارهای پایهٔ مدیریت سرور

~~~bash
set -eu
sudo apt install -y \
  sudo git curl ca-certificates gnupg lsb-release \
  nano vim-tiny htop tmux jq rsync unzip zip tar xz-utils \
  dnsutils netcat-openbsd lsof tree openssh-server chrony
~~~

این بلوک فقط ابزارهای سیستم، ابزارهای شبکه، SSH و همگام‌سازی ساعت را نصب می‌کند. **Docker، PHP، MariaDB، Pterodactyl، Wings و CS2 عمداً در این مرحله نصب نمی‌شوند.**

### 1.12 مرحلهٔ چهارم — تثبیت Hostname/FQDN و ساعت

نامی که در نصاب وارد شد باید روی سیستم نیز ثابت باشد. این بلوک hostname را روی `fc-node-01` می‌گذارد و FQDN موردنظر را در hosts محلی تعریف می‌کند. تعریف محلی hosts جای رکورد DNS عمومی را نمی‌گیرد.

~~~bash
set -eu

sudo hostnamectl set-hostname fc-node-01

sudo sed -i -E '/^127\.0\.1\.1[[:space:]]/d' /etc/hosts
printf '%s\n' '127.0.1.1 fc-node-01.fragcity.ir fc-node-01' \
  | sudo tee -a /etc/hosts >/dev/null

sudo timedatectl set-timezone UTC
sudo systemctl enable --now chrony
~~~

برای سرور، UTC را در سیستم‌عامل نگه می‌داریم تا زمان‌های لاگ و عیب‌یابی یکدست باشند. منطقهٔ زمانی نمایشی سایت، در صورت نیاز، جداگانه در خود Panel تنظیم می‌شود.

### 1.13 مرحلهٔ پنجم — فعال‌سازی و بررسی SSH

~~~bash
set -eu

sudo sshd -t
sudo systemctl enable --now ssh
sudo systemctl is-active ssh chrony

echo
echo "=== SSH listening sockets ==="
sudo ss -ltnp | grep -E 'LISTEN.+:22([[:space:]]|$)' || true

echo
echo "=== Effective SSH policy (read-only) ==="
sudo sshd -T | grep -Ei '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication) '
~~~

فعلاً تنظیمات ورود SSH را تغییر نده و پورت 22 را هنوز روی اینترنت عمومی باز نکن. بعد از اینکه اتصال LAN و کلید SSH را آزمایش کردیم، سخت‌سازی SSH و فایروال را جداگانه انجام می‌دهیم.

### 1.14 مرحلهٔ ششم — بررسی DNS، اینترنت خروجی و همگام‌سازی زمان

~~~bash
set -eu

echo "=== Host identity ==="
hostname
hostname -f

echo
echo "=== LAN and routing ==="
ip -br address
ip route

echo
echo "=== DNS lookup ==="
getent ahosts deb.debian.org

echo
echo "=== HTTPS connectivity ==="
curl -fsSI --max-time 15 https://deb.debian.org/ -o /dev/null \
  -w 'HTTPS status: %{http_code}\n'

echo
echo "=== UTC clock and NTP ==="
date -u
timedatectl show -p Timezone -p NTPSynchronized -p NTP
chronyc tracking

echo
echo "=== Storage ==="
df -hT /
df -ih /
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
~~~

این بلوک آخر وضعیت فعلی شبکه، دسترسی HTTPS و ساعت را بررسی می‌کند. اگر `getent`، `curl` یا `chronyc` خطا داد، بلوک را دوباره و پشت‌سرهم اجرا نکن؛ خروجی را همین‌جا بفرست تا اول علت را مشخص کنیم.

### 1.15 مرحلهٔ هفتم — بررسی نهایی hostname، شبکه و وضعیت سرویس‌ها

این بلوک فقط‌خواندنی است و مطمئن می‌شود هشدار قبلی مربوط به تغییر hostname تکرار نمی‌شود. مقدار MAC برای رزرو DHCP در مرحلهٔ بعد استفاده خواهد شد.

~~~bash
set -eu

echo "=== Host identity and local resolution ==="
hostname -s
hostname -f
getent hosts fc-node-01
getent hosts fc-node-01.fragcity.ir

echo
echo "=== LAN identity ==="
ip -4 -o address show dev ens33
ip route
printf 'MAC: '
cat /sys/class/net/ens33/address

echo
echo "=== Services and time ==="
sudo -v
systemctl is-active ssh chrony
timedatectl show -p Timezone -p NTPSynchronized -p NTP
~~~

اگر hostname به‌درستی resolve نشد یا هشدار `sudo: unable to resolve host` همچنان تکرار شد، قبل از مراحل شبکه خروجی را بفرست؛ پیکربندی‌های بیشتری را حدس‌زنان تغییر نده.

### 1.16 مرحلهٔ هشتم — رزرو DHCP برای IP داخلی ثابت

هدف این است که MAC کارت شبکهٔ `ens33` همیشه همان IP داخلی را دریافت کند. فعلاً روی Debian آدرس استاتیک دستی تعریف نکن؛ رزرو DHCP و تنظیم IP استاتیک داخل سیستم را هم‌زمان انجام نده.

1. از مرحلهٔ 1.15، MAC کارت شبکه را یادداشت کن.
2. وارد دستگاهی شو که DHCP شبکهٔ فعلی `192.168.1.0/24` را مدیریت می‌کند. Gateway فعلی `192.168.1.1` است، اما فرض نکن که حتماً خودش DHCP Server است.
3. اگر از MikroTik/Winbox استفاده می‌کنی: به **IP → DHCP Server → Leases** برو، Lease مربوط به IP `192.168.1.7` را با MAC مرحلهٔ قبل تطبیق بده و **Make Static** را بزن. اگر DHCP را دستگاه دیگری مدیریت می‌کند، همان‌جا رزرو مشابه بساز.
4. مطمئن شو رزرو از همان IP `192.168.1.7` برای همان MAC استفاده می‌کند؛ آدرس متعلق به دستگاه دیگری را رزرو یا جابه‌جا نکن.
5. بعد از ذخیرهٔ رزرو، VM را از SSH با فرمان زیر reboot کن. این فرمان اتصال SSH را قطع می‌کند؛ طبیعی است.

~~~bash
sudo reboot
~~~

پس از بالا آمدن VM، از PowerShell دوباره وصل شو:

~~~powershell
ssh sv1@192.168.1.7
~~~

و IP/route را بررسی کن:

~~~bash
ip -4 -o address show dev ens33
ip route
cat /sys/class/net/ens33/address
~~~

ادامه فقط وقتی انجام شود که IP و MAC با رزرو DHCP مطابق باشند. اگر IP تغییر کرد، آدرس تازه را از کنسول VMware پیدا کن و قبل از ادامهٔ راهنما آن را تأیید کن.

### 1.17 مرحلهٔ نهم — بررسی IPv4 عمومی، NAT و CGNAT

این بلوک فقط IPv4 خروجی‌ای را که سرویس بیرونی می‌بیند نمایش می‌دهد؛ به‌تنهایی ثابت نمی‌کند اتصال ورودی از اینترنت قابل‌دسترسی است.

~~~bash
set -eu
echo "=== External IPv4 seen by an HTTPS service ==="
curl -4fsS --max-time 15 https://api.ipify.org
printf '\n'

echo
echo "=== Local default route ==="
ip -4 route
~~~

در پنل روتر یا مودم، **WAN IPv4** را با آدرسی که فرمان بالا نشان می‌دهد مقایسه کن:

- اگر یکسان‌اند و WAN IPv4 عمومی است، احتمالاً روتر IP عمومی را مستقیم دریافت کرده است؛ همچنان باید قوانین ورودی و ISP بررسی شوند.
- اگر WAN IPv4 در بازه‌های خصوصی `10.0.0.0/8`، `172.16.0.0/12`، `192.168.0.0/16` یا بازهٔ CGNAT یعنی `100.64.0.0/10` است، یا با آدرس بیرونی تفاوت دارد، احتمال NAT بالادستی، Double NAT یا CGNAT وجود دارد. قبل از هر Port Forwarding باید مسیر واقعی مشخص شود.
- فعلاً هیچ پورتی را برای WAN باز نکن. اگر IP عمومی ورودی از ISP در دسترس نیست، قبل از انتشار سرویس باید راه‌حل اتصال مناسب انتخاب شود.

آدرس IP و نتیجهٔ بررسی را در README ننویس؛ README فقط دستورها و مراحل تکرارپذیر را نگه می‌دارد.

### 1.17.1 مهم — صفحهٔ ورود مودم روی IP عمومی و پورت 80

اگر بازکردن IP عمومی در مرورگر صفحهٔ مدیریت مودم/روتر را نشان داد، **در آن صفحه رمز وارد نکن و فعلاً Port Forwarding وب را تنظیم نکن.** باید مشخص کنیم آیا رابط مدیریت از سمت WAN واقعاً قابل‌دسترسی است یا مرورگر از داخل LAN به‌خاطر NAT loopback/رفتار خود روتر به صفحهٔ محلی رسیده است. مشاهدهٔ صفحه از داخل LAN به‌تنهایی ثابت نمی‌کند که اینترنت هم آن را می‌بیند.

نکتهٔ URL: `https://85.185.40.85:80/` یعنی اتصال HTTPS روی پورت 80؛ این ترکیب غیرمعمول است. HTTP معمولاً با `http://85.185.40.85/` و HTTPS با `https://85.185.40.85/` استفاده می‌شود. تا وقتی رابط مدیریت مودم بررسی نشده، از صفحهٔ IP عمومی وارد حساب نشو.

#### قدم A — ورود محلی به مودم/روتر

1. از روی Debian، در `ip route`، Gateway فعلی شبکه را ببین؛ در وضعیت فعلی راهنما مقدار آن `192.168.1.1` است، اما اگر عوض شده از مقدار واقعی استفاده کن.
2. از مرورگر داخل همان LAN، صفحهٔ مدیریت محلی Gateway را باز کن، مثلاً `http://192.168.1.1/`. فقط از آدرس محلی استفاده کن.
3. در تنظیمات مودم/روتر دنبال گزینه‌هایی با نام‌هایی مانند **Remote Management**, **Web Access from WAN**, **WAN HTTP/HTTPS Access**, **Remote Web Administration** یا **Management from Internet** بگرد.
4. دسترسی مدیریتی از WAN را برای HTTP و HTTPS خاموش کن؛ دسترسی مدیریتی از LAN را نگه دار تا بتوانی روتر را محلی مدیریت کنی. اگر نام گزینه‌ها یا عملکردشان نامشخص است، قبل از تغییر از صفحهٔ تنظیمات عکس بگیر و مدل دستگاه را مشخص کن؛ تنظیمات WAN، Bridge، PPPoE یا TR-069 را حدس‌زنان تغییر نده.
5. اگر رمز مدیریت مودم ضعیف یا پیش‌فرض است، یک رمز یکتا و قوی تنظیم کن. رمز را در چت یا README ننویس.

#### قدم B — بررسی از خارج شبکه

برای اینکه مشخص شود رابط مدیریت واقعاً از اینترنت قابل‌دسترسی است، از یک گوشی با **Wi-Fi خاموش و دیتای موبایل روشن** استفاده کن. تا وقتی این تست را نکرده‌ای، از نتیجهٔ تستی که روی همان LAN انجام شده نتیجه‌گیری قطعی نکن.

پس از غیرفعال‌کردن WAN management، از دیتای موبایل فقط صفحهٔ زیر را بررسی کن و **هیچ رمز مدیریتی وارد نکن**:
- `http://85.185.40.85/` (HTTP/80)
- `https://85.185.40.85/` (HTTPS/443)

اگر هنوز صفحهٔ ورود مودم از اینترنت دیده می‌شود، برای این مرحله توقف کن؛ مدیریت WAN را از تنظیمات خود دستگاه یا با کمک ISP غیرفعال کن. در صورت لزوم رمز مدیریتی مودم را هم عوض کن. اگر صفحه دیگر دیده نمی‌شود، این مسئله را به‌معنی آماده‌بودن Panel فرض نکن؛ هنوز Port Forwarding، UFW، NGINX و TLS باید جداگانه تنظیم و آزمایش شوند.

**قانون برای مراحل بعد:** رابط مدیریت مودم باید فقط از LAN قابل‌دسترسی باشد. وقتی Panel آماده شد، TCP 80 و 443 روتر را به IP داخلی رزروشدهٔ Debian هدایت می‌کنیم؛ آن را به خود مودم یا صفحهٔ مدیریت مودم هدایت نمی‌کنیم. هیچ‌وقت پورت 22، 3306 یا 6379 را برای دسترسی عمومی باز نکن.

### 1.18 مرحلهٔ دهم — بررسی و آماده‌سازی DNS عمومی

ابتدا Nameserverهای دامنه و رکوردهای واقعی را بررسی کن. فرمان `dig` از DNS استفاده می‌کند و ورودی محلی `/etc/hosts` را دور می‌زند.

~~~bash
set -eu
echo "=== Authoritative DNS servers ==="
dig +short NS fragcity.ir

echo
echo "=== Public A records ==="
dig +short A panel.fragcity.ir
dig +short A fc-node-01.fragcity.ir

echo
echo "=== Existing IPv6 records ==="
dig +short AAAA panel.fragcity.ir
dig +short AAAA fc-node-01.fragcity.ir
~~~

1. از روی NS مشخص کن مدیریت DNS واقعاً در کدام سرویس انجام می‌شود و فقط در همان پنل Zone را ویرایش کن.
2. پس از تأیید داشتن IPv4 عمومی قابل‌استفاده در مرحلهٔ 1.17، رکوردهای **A** برای `panel.fragcity.ir` و `fc-node-01.fragcity.ir` را به همان IPv4 عمومی تنظیم کن؛ هرگز IP داخلی `192.168.1.7` را به‌عنوان رکورد عمومی قرار نده.
3. اگر Cloudflare داری، برای راه‌اندازی اولیهٔ Wings رکورد Node را **DNS only** نگه دار؛ پراکسی عادی Cloudflare نباید بدون طراحی و پشتیبانی از پورت‌ها فرض گرفته شود.
4. رکورد **AAAA** نساز یا نگه ندار مگر IPv6 عمومی، مسیر ورودی، سرویس و Firewall همگی واقعاً تنظیم و آزمایش شده باشند.
5. برای تأیید نهایی، فرمان‌های `dig` بالا را دوباره اجرا کن. خروجی A باید با IPv4 عمومی تأییدشده مطابقت داشته باشد. اگر رکوردها هنوز به‌روز نشده‌اند یا مقدار نامناسب دارند، قبل از ادامه علت را مشخص کن.

ساخت رکورد DNS به‌تنهایی Port Forwarding، TLS یا قابلیت دسترسی ورودی را فعال نمی‌کند.

### 1.19 مرحلهٔ یازدهم — کلید SSH، سخت‌سازی ورود و Firewall میزبان

#### SSH اینجا دقیقاً چه کاری انجام می‌دهد؟

SSH (Secure Shell) یک اتصال مدیریتی رمزنگاری‌شده بین Windows و Debian است. به‌جای تایپ‌کردن دستورها در کنسول VMware، دستورها را از Windows Terminal/PowerShell اجرا می‌کنی و روی Debian انجام می‌شوند.

در احراز هویت با کلید، یک **جفت کلید** داریم:
- **کلید خصوصی** با نام `id_ed25519_fragcity` روی کامپیوتر Windows می‌ماند؛ آن را به سرور یا چت نفرست.
- **کلید عمومی** با پسوند `.pub` روی Debian در `~/.ssh/authorized_keys` حساب کاربری ذخیره می‌شود.
- هنگام اتصال، Windows ثابت می‌کند کلید خصوصی متناظر را دارد؛ لازم نیست رمز حساب Debian از طریق SSH استفاده شود.

در این مرحله اول کلید را آزمایش می‌کنیم؛ بعد ورود با رمز SSH را غیرفعال می‌کنیم. این تنظیم با رمز کاربر برای ورود محلی یا `sudo` یکی نیست. ورود مستقیم root از SSH نیز غیرفعال می‌شود. **پورت 22 را از روتر به اینترنت فوروارد نکن.**

**قانون بسیار مهم تشخیص پنجره:**
- اگر خط فرمان `PS C:\...>` می‌بینی، در Windows PowerShell هستی.
- اگر `sv1@fc-node-01:~$` می‌بینی، داخل Debian از طریق SSH هستی.
- فرمان‌هایی که با `$env:USERPROFILE` و `Test-Path` شروع می‌شوند فقط برای PowerShell هستند. اگر آن‌ها را در Bash اجرا کنی، ممکن است خطای `keyPath: unbound variable` بگیری؛ این خطا به‌خودی‌خود به معنی خرابی SSH یا Debian نیست. یک پنجرهٔ PowerShell جدید باز کن و کد را همان‌جا اجرا کن.

#### 1.19.1 ساخت کلید SSH در Windows

**محل اجرا: Windows PowerShell، نه داخل نشست SSH.** یک پنجرهٔ جدید PowerShell باز کن تا prompt آن `PS C:\...>` باشد. مسیر اختصاصی کلید FragCity را بررسی و در صورت نبودن فایل‌ها بساز:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"

if ((Test-Path $keyPath) -or (Test-Path "$keyPath.pub")) {
    throw "Key path already exists. Do not overwrite it; use the existing key or choose a new unique filename."
}

ssh-keygen -t ed25519 -a 64 -f $keyPath -C "fragcity-windows"
~~~

اگر کلید از قبل ساخته شده، دوباره آن را نساز؛ از همان فایل موجود استفاده کن. اگر برای کلید passphrase انتخاب کردی، آن را در جای امن نگه دار. فایل خصوصی `id_ed25519_fragcity` را هیچ‌وقت ارسال نکن؛ فقط فایل `.pub` کلید عمومی است.

#### 1.19.2 نصب کلید عمومی برای حساب Debian

**محل اجرا: همان Windows PowerShell.** این بار PowerShell محتوای فایل عمومی را از طریق اتصال SSH به فایل `authorized_keys` روی Debian می‌فرستد. در این اولین اتصال، ممکن است رمز فعلی حساب Debian پرسیده شود؛ این رفتار طبیعی است.

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$debianUser = Read-Host "Debian non-root username"
$nodeIp = Read-Host "Debian node LAN IPv4"
$target = "$debianUser@$nodeIp"

if (!(Test-Path "$keyPath.pub")) {
    throw "Public key file was not found. Stop and check the key path."
}

Get-Content -Raw "$keyPath.pub" | ssh $target "umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
~~~

نام حساب و IP را هنگام prompt وارد کن. این فرمان یک‌بار کلید را اضافه می‌کند؛ بی‌دلیل آن را تکرار نکن، چون ممکن است خط یکسان چندبار به `authorized_keys` اضافه شود.

حالا **یک پنجرهٔ تازهٔ PowerShell** باز کن تا نشست قبلی، اگر هنوز باز است، برای بازیابی در دسترس بماند. کد زیر باید با کلید خصوصی Windows احراز هویت کند و عمداً اجازهٔ استفاده از رمز SSH را نمی‌دهد:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$debianUser = Read-Host "Debian non-root username"
$nodeIp = Read-Host "Debian node LAN IPv4"
$target = "$debianUser@$nodeIp"

ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath $target
~~~

اگر وارد شدی، کلید و فایل `authorized_keys` درست کار می‌کنند. اگر اتصال ناموفق بود، تنظیمات SSH را سخت‌تر نکن و رمز ورود SSH را هنوز غیرفعال نکن؛ اول خطا را بررسی کن.

#### 1.19.3 سخت‌سازی SSH؛ فقط پس از موفقیت ورود کلیدی

**محل اجرای بلوک اول: نشست SSH فعلی در Debian** که با حساب عادی وارد آن شده‌ای. این فایل تنظیمات SSH را برای اتصال‌های جدید تغییر می‌دهد:

~~~bash
set -eu
sudo tee /etc/ssh/sshd_config.d/00-fragcity-hardening.conf >/dev/null <<'EOF'
PubkeyAuthentication yes
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF

sudo sshd -t
sudo sshd -T | grep -Ei '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
sudo systemctl reload ssh
~~~

این دستورات به ترتیب:
1. احراز هویت با کلید را فعال و ورود root و احراز هویت SSH با رمز را غیرفعال می‌کنند.
2. `sshd -t` نحو فایل‌های پیکربندی را بررسی می‌کند؛ در صورت موفقیت، معمولاً خروجی ندارد. اگر خطا داد، به‌خاطر `set -e` اجرای بلوک متوقف می‌شود و فرمان `reload` اجرا نخواهد شد.
3. `sshd -T` سیاست مؤثر SSH را نشان می‌دهد؛ مقادیر مورد انتظار عبارت‌اند از `permitrootlogin no`، `passwordauthentication no`، `kbdinteractiveauthentication no` و `pubkeyauthentication yes`.
4. `systemctl reload ssh` از سرویس می‌خواهد پیکربندی معتبر جدید را بخواند. این فرمان لازم نیست سیستم را reboot کند؛ نشست SSH فعلی هم معمولاً باز می‌ماند.

**چرا پنجرهٔ دوم مهم است؟** نشست فعلی ممکن است با تنظیمات قبلی باز مانده باشد، حتی اگر اتصال جدید به‌دلیل تنظیم اشتباه شکست بخورد. بنابراین نشست فعلی را نبند. یک پنجرهٔ تازهٔ PowerShell باز کن و اتصال صرفاً با کلید را دوباره آزمایش کن:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$debianUser = Read-Host "Debian non-root username"
$nodeIp = Read-Host "Debian node LAN IPv4"
$target = "$debianUser@$nodeIp"

ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath $target "hostname; id"
~~~

اگر این دستور نام میزبان و اطلاعات حساب را برگرداند و با رمز حساب Debian وارد نشد، آزمایش اتصال جدید موفق است. فقط پس از موفقیت، نشست قبلی را ببند. اگر ناموفق بود، همان نشست قبلی را باز نگه دار و خروجی خطا را بررسی کن.

#### 1.19.4 Firewall میزبان با UFW

فقط پس از موفقیت آزمایش کلید در مرحلهٔ 1.19.3، قواعد Firewall را تنظیم کن. قاعدهٔ SSH برای شبکهٔ LAN فعلی نوشته شده است؛ اگر subnet عوض شده، پیش از فعال‌کردن Firewall آن را با شبکهٔ واقعی تطبیق بده.

~~~bash
set -eu
sudo apt install -y ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

sudo ufw --force enable
sudo ufw status verbose
~~~

این کار SSH ورودی را به subnet فعلی LAN محدود می‌کند و برای وب پورت‌های TCP 80 و 443 را در Firewall خود Debian مجاز می‌سازد. وجود این قواعد به‌تنهایی سرویسی را در اینترنت منتشر نمی‌کند؛ روتر هنوز Port Forwarding جداگانه می‌خواهد. تا وقتی Wings نصب و TLS آن پیکربندی نشده است، پورت‌های `8080` و `2022` را باز نکن؛ پورت `22` را نیز از روتر به WAN فوروارد نکن.

اگر نشست SSH قطع شد، از کنسول VMware وضعیت را بررسی کن؛ Firewall را با افزودن پورت‌ها یا بازکردن SSH برای کل اینترنت به‌صورت حدسی تغییر نده.

راهنماهای رسمی: https://manpages.debian.org/trixie/openssh-server/sshd_config.5.en.html و https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29

### 1.20 مرحلهٔ دوازدهم — تأیید SSH و Firewall پس از اعمال قواعد

**اول بلوک Debian را از نشست SSH اجرا کن.** این مرحله وضعیت را می‌خواند و سرویس یا قاعده‌ای را تغییر نمی‌دهد:

~~~bash
set -eu
echo "=== Host identity ==="
hostname -f

echo
echo "=== SSH service and effective policy ==="
sudo sshd -t
sudo systemctl is-active ssh
sudo sshd -T | grep -Ei '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '

echo
echo "=== Firewall ==="
sudo ufw status verbose

echo
echo "=== Listening sockets ==="
sudo ss -ltnp

echo
echo "=== Time and network ==="
timedatectl show -p Timezone -p NTPSynchronized -p NTP
ip -4 route
~~~

سپس از **یک پنجرهٔ تازهٔ Windows PowerShell** دوباره اتصال کلیدی را تست کن. نام کاربری، IP و مسیر کلید را در همان پنجره وارد کن:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$debianUser = Read-Host "Debian non-root username"
$nodeIp = Read-Host "Debian node LAN IPv4"
$target = "$debianUser@$nodeIp"

Test-NetConnection $nodeIp -Port 22
ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath $target "hostname; id"
~~~

مرحله کامل است وقتی SSH از LAN فعال باشد، Firewall نشان دهد فعال است، و اتصال کلیدی از پنجرهٔ تازه موفق شود. اگر هرکدام شکست خورد، نصب Panel را شروع نکن و همان خروجی را در گفت‌وگو بفرست.

### 1.21 مرحلهٔ سیزدهم — ساخت نقطهٔ بازگشت در VMware

قبل از نصب PHP، MariaDB، Redis، NGINX و Panel بهتر است نقطهٔ بازگشت داشته باشی:

1. اگر نسخهٔ VMware تو Snapshot را پشتیبانی می‌کند، از رابط VMware برای همین VM یک Snapshot بساز.
2. نام پیشنهادی: `debian13-base-ssh-firewall`.
3. VMDK سیستم قبلی را انتخاب، mount یا overwrite نکن. Snapshot جای backup مستقل را نمی‌گیرد؛ اگر از فایل VM هم backup می‌گیری، دیسک مقصد را با دقت بررسی کن.
4. اگر Snapshot در نسخهٔ VMware در دسترس نیست، این گام اختیاری را رد کن و به‌جای آن برنامهٔ backup جداگانه داشته باش.

### مسیر اجرایی بعد از مرحلهٔ 1.21 — دستهٔ شش‌گامی

هدف این دسته آماده‌کردن وابستگی‌ها، نصب فایل‌های Panel و ساخت دیتابیس است. بلوک‌ها را به‌ترتیب اجرا کن و فقط وقتی یک بلوک بدون خطا تمام شد، سراغ بلوک بعدی برو.

1. **مرحلهٔ 1.21 — Snapshot در VMware:** از همین VM یک Snapshot با نام `debian13-base-ssh-firewall` بساز. اگر نسخهٔ VMware Snapshot ندارد، این مرحله اختیاری است؛ برای دیسک VM قبلی هیچ تغییری نده.
2. **مرحلهٔ 2.1 — مخزن PHP 8.3:** بلوک کامل بخش 2.1 را اجرا کن. شرط قبولی: آخرین `sudo apt update` با کد خروج صفر تمام شود.
3. **مرحلهٔ 2.2 — بسته‌های موردنیاز:** بلوک بخش 2.2 را اجرا کن. در صورت خطای APT یا ناسازگاری بسته، متوقف شو و خطا را بررسی کن.
4. **مرحلهٔ 2.3 — Composer و بررسی سرویس‌ها:** بلوک بخش 2.3 را اجرا کن. فقط در صورت تأیید نسخهٔ PHP، Composer، افزونه‌ها و فعال‌بودن سرویس‌ها ادامه بده.
5. **مرحلهٔ 3.1 — فایل‌های Panel:** بلوک بخش 3.1 را فقط روی نصب تازه اجرا کن. در این راهنما نسخهٔ پایدار انتخابی `v1.15.1` است؛ قبل از اجرا صفحهٔ Release رسمی را دوباره بررسی کن. اگر فایل `.env` از قبل وجود داشت، اسکریپت باید متوقف شود؛ آن را overwrite نکن.
6. **مرحلهٔ 3.2 — دیتابیس و حساب اختصاصی:** ابتدا دستورهای بررسی ابتدای بخش 3.2 را اجرا کن. فقط اگر نصب واقعاً تازه است، دیتابیس و حسابی که در بخش 3.2 آمده‌اند را بساز. رمز دیتابیس را به‌صورت محلی در prompt قرار بده؛ آن را در GitHub، README یا گزارش گفت‌وگو ثبت نکن.

**ایست بازرسی:** بعد از پایان موفق مرحلهٔ 3.2، همین‌جا متوقف شو و خروجی‌های مراحل 2.1 تا 3.2 را برای بررسی بفرست. رمز واردشده، محتوای `.env`، کلید `APP_KEY` و اطلاعات ورود را نفرست. فعلاً مرحله‌های 3.3 به بعد را اجرا نکن؛ ابتدا صحت نسخه‌ها، سرویس‌ها، فایل‌های برنامه و دیتابیس را بررسی می‌کنیم.

**نکتهٔ دسترسی وب:** طبق گزارش فعلی، Port Forward پورت 80 موقتاً به همین VM اشاره می‌کند. با فعال‌شدن NGINX ممکن است صفحهٔ پیش‌فرض آن از طریق HTTP قابل‌دسترسی شود. اطلاعات ورود را روی HTTP وارد نکن. فعال‌سازی Virtual Host مربوط به Panel و انتشار نهایی باید طبق بخش‌های 3.5 و 3.7، پس از بررسی دسترسی روتر، DNS و TLS انجام شود.

**هیچ instance یا فایل بازی CS2 در این فاز نصب نمی‌شود.**
---

## 2. نصب PHP 8.3 و نیازمندی‌های Panel (نصب تازه)

این مرحله پس از نصب پاک Debian Console-only اجرا می‌شود؛ روی سیستم قدیمی پیش از نصب مجدد اجرا نکن.

### 2.1 Repository برای PHP 8.3

~~~bash
set -eu
sudo apt update
sudo apt install -y ca-certificates curl gnupg2 lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/sury-php.gpg
sudo chmod a+r /etc/apt/keyrings/sury-php.gpg
. /etc/os-release
echo "deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${VERSION_CODENAME} main" | sudo tee /etc/apt/sources.list.d/sury-php.list
sudo apt update
~~~

### 2.2 نصب بسته‌ها

~~~bash
sudo apt install -y \
  php8.3 php8.3-cli php8.3-common php8.3-gd php8.3-mysql \
  php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl \
  php8.3-zip php8.3-fpm php8.3-intl php8.3-opcache \
  mariadb-server redis-server nginx git curl tar unzip
~~~

### 2.3 نصب Composer 2 با بررسی امضای نصب‌کننده

این بلوک را پس از تکمیل مرحلهٔ 2.2 اجرا کن. ابتدا امضای فعلی را از Composer دریافت می‌کند و با SHA-384 فایل نصب‌کننده مقایسه می‌کند؛ اگر مطابقت نداشت، نصب متوقف می‌شود.

~~~
set -eu
cd /tmp

EXPECTED_CHECKSUM="$(curl -fsSL https://composer.github.io/installer.sig)"
curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
ACTUAL_CHECKSUM="$(sha384sum /tmp/composer-setup.php | awk '{print $1}')"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
  echo "ERROR: Composer installer signature mismatch; refusing to install."
  rm -f /tmp/composer-setup.php
  exit 1
fi

sudo php8.3 /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f /tmp/composer-setup.php

php8.3 /usr/local/bin/composer --version
~~~

در ادامه، Composer را با `php8.3 /usr/local/bin/composer` اجرا کن تا به‌صورت تصادفی از نسخهٔ PHP متفاوتی که ممکن است پیش‌فرض سیستم باشد استفاده نکند.

مرجع رسمی: https://getcomposer.org/download/

بررسی:

~~~bash
set -eu
php8.3 -v
php8.3 /usr/local/bin/composer --version
for module in bcmath curl dom gd intl json mbstring mysqli openssl PDO pdo_mysql posix tokenizer xml zip; do
  php8.3 -m | grep -Eixq "$module" || { echo "MISSING: $module"; exit 1; }
  echo "OK: $module"
done
sudo systemctl enable --now nginx mariadb redis-server php8.3-fpm
sudo systemctl is-active nginx mariadb redis-server php8.3-fpm
sudo ss -ltnp | grep -E ':(22|80|443|3306|6379)\b' || true
~~~

MariaDB باید روی 127.0.0.1:3306 و Redis روی loopback بمانند؛ برای این PoC این پورت‌ها را عمومی نکن.

---

## 3. نصب Pterodactyl Panel — فاز آینده، پیش از اجرا نسخه را بازبینی کن

در بازبینی **2026-10-18**، صفحهٔ Release رسمی، `v1.15.1` را آخرین نسخهٔ پایدار و نسخه‌های `v2.0.0-beta.*` را Open Beta نشان می‌دهد؛ برای این مسیر، نسخهٔ پایدار 1.x انتخاب شده است. پیش از اجرا، https://github.com/pterodactyl/panel/releases را دوباره بررسی کن. اگر Release پایدار جدیدتری منتشر شده، نسخه و نیازمندی‌های آن را بازبینی کن و سپس URL و شمارهٔ نسخهٔ pin‌شده در این بخش را به‌صورت آگاهانه تغییر بده.

### 3.1 دریافت فایل‌ها و Composer

فقط برای نصب تازه اجرا شود. اگر /var/www/pterodactyl/.env وجود دارد، آن را overwrite نکن.

~~~bash
set -eu
sudo install -d -o www-data -g www-data /var/www/pterodactyl
cd /var/www/pterodactyl

if sudo test -e .env; then
  echo "STOP: .env already exists; this is not a clean install."
  exit 1
fi

sudo curl -fL https://github.com/pterodactyl/panel/releases/download/v1.15.1/panel.tar.gz -o /tmp/panel.tar.gz
sudo tar -xzf /tmp/panel.tar.gz -C /var/www/pterodactyl
sudo chown -R www-data:www-data /var/www/pterodactyl
sudo find storage bootstrap/cache -type d -exec chmod 750 {} +
sudo find storage bootstrap/cache -type f -exec chmod 640 {} +
sudo cp .env.example .env
sudo chown www-data:www-data .env
sudo chmod 640 .env

# Give www-data a dedicated writable Composer home instead of relying on /var/www permissions.
sudo install -d -o www-data -g www-data -m 0750 /var/www/.composer

cd /var/www/pterodactyl
sudo -u www-data env HOME=/var/www COMPOSER_HOME=/var/www/.composer \
  php8.3 /usr/local/bin/composer install --no-dev --optimize-autoloader --no-interaction
sudo -u www-data php8.3 artisan key:generate

# Read-only checks; do not print the contents of .env.
sudo -u www-data php8.3 artisan --version
sudo test -s /var/www/pterodactyl/.env && echo "OK: .env exists"
sudo stat -c '%U:%G %a %n' /var/www/pterodactyl/.env /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache
~~~

APP_KEY فقط یک‌بار هنگام نصب تازه تولید می‌شود. آن را دوباره تولید نکن.

### 3.2 دیتابیس اختصاصی

ابتدا وجود دیتابیس و حساب را بررسی کن؛ روی نصب موجود CREATE را کورکورانه تکرار نکن.

~~~bash
sudo mariadb -Nse "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='panel';"
sudo mariadb -Nse "SELECT CONCAT(User, '@', Host) FROM mysql.user WHERE User='pterodactyl';"
~~~

برای نصب تازه:

~~~bash
sudo env MYSQL_HISTFILE=/dev/null mariadb
~~~

داخل prompt مربوط به MariaDB، یک رمز قوی و یکتا را به‌صورت محلی جایگزین کن:

~~~sql
CREATE DATABASE panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'REPLACE_WITH_A_UNIQUE_PASSWORD';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
SHOW GRANTS FOR 'pterodactyl'@'127.0.0.1';
EXIT;
~~~

رمز را در سند نگذار. اگر user از قبل وجود دارد، برای تعویض رمز از ALTER USER استفاده کن، نه CREATE USER.

### 3.3 Wizardهای Panel

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:environment:setup
sudo -u www-data php8.3 artisan p:environment:database
~~~

مقادیر هدف برای نصب جدید: تا وقتی فقط NGINX/HTTP محلی را آزمایش می‌کنیم، URL در Wizard برابر `http://panel.fragcity.ir` باشد؛ بعد از صدور و تأیید گواهی TLS در مرحلهٔ 3.7، مقدار را به `https://panel.fragcity.ir` تغییر می‌دهیم. timezone سیستم‌عامل UTC، cache/session/queue برابر redis، Redis host برابر `127.0.0.1` و port برابر `6379`، DB host برابر `127.0.0.1`، port برابر `3306`، database برابر `panel` و user برابر `pterodactyl` است. رمزهای DB/Redis را فقط داخل prompt وارد کن و در README/چت ننویس. تا قبل از تأیید TLS و Firewall، Panel را از روتر روی WAN منتشر نکن.

### 3.4 اصلاح مجوز Cache، Migration و مدیر

اصلاح مجوز Cache برای نصب تازه:

~~~bash
set -eu
cd /var/www/pterodactyl
sudo chown -R www-data:www-data storage bootstrap/cache
sudo find storage bootstrap/cache -type d -exec chmod 750 {} +
sudo find storage bootstrap/cache -type f -exec chmod 640 {} +
sudo -u www-data sh -c 'touch storage/framework/cache/data/.fragcity-permission-test && rm storage/framework/cache/data/.fragcity-permission-test && echo "OK: www-data can write to Laravel cache"'
~~~

فقط برای نصب تازه:

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan migrate --seed --force
sudo -u www-data php8.3 artisan p:user:make
~~~

این فرمان‌ها فقط در نصب تازه و در نقطهٔ مناسب فرایند اجرا شوند؛ Migration و ساخت Administrator را بی‌دلیل روی نصب فعال تکرار نکن.

بررسی Eggها:

~~~bash
sudo mariadb panel -e "SELECT id, name, nest_id FROM eggs WHERE LOWER(name) LIKE '%counter%strike%' OR LOWER(name) LIKE '%cs2%' ORDER BY name;"
~~~

فرمان بالا صرفاً برای بررسی فهرست Eggهای همین نصب است. نام یا شناسهٔ Egg را حدس نزن؛ تا زمانی که سازگاری Egg با CS2 تأیید نشده، سرور جدید نساز.

### 3.5 پیکربندی NGINX برای LAN

فایل /etc/nginx/sites-available/pterodactyl.conf در VM فعلی:

~~~nginx
server {
    listen 80;
    listen [::]:80;
    server_name panel.fragcity.ir;
    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    add_header X-Content-Type-Options nosniff;
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ^~ /assets/ {
        location ~ /\. { deny all; }
        try_files $uri =404;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht { deny all; }
}
~~~

فعال‌سازی/تست:

~~~bash
set -eu
if ! sudo test -e /etc/nginx/sites-enabled/pterodactyl.conf && ! sudo test -L /etc/nginx/sites-enabled/pterodactyl.conf; then
  sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
fi
if sudo test -L /etc/nginx/sites-enabled/default; then
  sudo rm /etc/nginx/sites-enabled/default
fi
sudo /usr/sbin/nginx -t
sudo systemctl reload nginx
sudo systemctl is-active nginx
curl -sS -o /dev/null -w 'HTTP status: %{http_code}\n' -H 'Host: panel.fragcity.ir' http://127.0.0.1/
~~~

پس از فعال‌سازی، دسترسی را از مرورگر Windows بررسی کن. این پیکربندی فقط برای LAN/HTTP است.

اگر دامنه از LAN به IP عمومی resolve می‌شود ولی روتر NAT loopback ندارد، برای آزمایش محلی می‌توانی روی Windows، فایل hosts را با دسترسی Administrator ویرایش کنی و موقتاً این نگاشت را اضافه کنی: `<node-lan-ip> panel.fragcity.ir`. آدرس IP داخلی را از مرحلهٔ 1.15/1.16 بگیر؛ IP را حدس نزن. این تغییر فقط روی همان Windows اثر دارد.

### 3.6 عیب‌یابی مسیر `/admin` در LAN

اگر `https://panel.fragcity.ir/admin` باز نمی‌شود، قبل از تغییر تنظیمات Node این بررسی‌های فقط‌خواندنی را روی Debian اجرا کن. خروجی ترمینال را به README اضافه نکن.

~~~bash
set +e

echo "=== Local HTTP routes ==="
for path in / /admin /auth/login; do
  printf '%-14s ' "$path"
  curl --connect-timeout 5 --max-time 15 -sS -o /dev/null \
    -w 'HTTP=%{http_code} redirect=%{redirect_url}\n' \
    -H 'Host: panel.fragcity.ir' "http://127.0.0.1${path}"
done

echo
echo "=== Web services ==="
sudo systemctl is-active nginx php8.3-fpm mariadb redis-server

echo
echo "=== NGINX configuration syntax ==="
sudo nginx -t

echo
echo "=== Registered admin routes ==="
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan route:list --path=admin
~~~

راهنمای تفسیر برای ادامهٔ عیب‌یابی:
- اگر مسیر `/` و `/admin` به‌صورت محلی پاسخ HTTP می‌دهند، وب‌سرور دست‌کم درخواست را دریافت می‌کند؛ رفتار مرورگر و نوع redirect را جداگانه بررسی کن.
- اگر `/admin` پاسخ `500` می‌دهد، خطای Laravel را بررسی کن؛ اگر `502` می‌دهد، NGINX و PHP-FPM را بررسی کن.
- اگر درخواست محلی سالم است ولی از Windows باز نمی‌شود، ارتباط LAN، IP ماشین و فایروال را بررسی کن.
- تا پیش از مشخص‌شدن خطا، NGINX را بازنویسی نکن، سرویس‌ها را کورکورانه restart نکن و Node جدید نساز.

### 3.7 صدور TLS برای Panel و انتشار وب پس از آزمون LAN

**این مرحله فقط زمانی اجرا شود که Panel در LAN روی HTTP سالم است**, رکورد `panel.fragcity.ir` به IPv4 عمومی فعلی اشاره می‌کند، و مرحلهٔ 1.17.1 تأیید کرده که رابط مدیریت مودم از WAN غیرفعال است. IP عمومی بیرونی و WAN IPv4 نمایش‌داده‌شده در روتر باید بررسی شوند؛ اگر WAN پشت CGNAT یا NAT بالادستی است، ابتدا مسیر ورودی را حل کن. پورت‌های 80/443 باید بعداً به Debian فوروارد شوند، نه به رابط مدیریتی مودم.

1. در Firewall روتر، فقط پس از تأیید آمادگی سرور، Port Forward برای **TCP 80 → IP داخلی Node:80** و **TCP 443 → IP داخلی Node:443** بساز. از WAN هیچ Port Forward برای SSH 22، MariaDB 3306، Redis 6379، Wings 8080 یا SFTP 2022 نساز.
2. UFW مرحلهٔ 1.19.4 باید اجازهٔ TCP 80 و 443 را داشته باشد. بررسی کن NGINX روی پورت 80 پاسخ می‌دهد.
3. هنگام اعتبارسنجی HTTP-01، سرویس موقتاً از اینترنت روی HTTP قابل‌دسترسی خواهد بود. در این زمان اطلاعات ورود را از طریق HTTP وارد نکن؛ بعد از موفقیت TLS به HTTPS مهاجرت کن. اگر دسترسی ورودی از اینترنت قابل اثبات نیست، Port Forward را حدس‌زنان تغییر نده.
4. پس از آماده‌شدن NAT ورودی، روی Debian اجرا کن:

~~~
set -eu
sudo apt install -y certbot python3-certbot-nginx
sudo nginx -t
sudo certbot --nginx --redirect -d panel.fragcity.ir
~~~

در Wizard مربوط به Certbot، ایمیل مدیریتی خودت را وارد کن؛ آن را در README ننویس. Certbot باید گواهی را نصب کند و HTTP را به HTTPS هدایت کند. اگر اعتبارسنجی شکست خورد، قبل از تکرار فرمان، DNS، Port Forward، Firewall و دسترسی بیرونی TCP 80 را بررسی کن.

5. پس از صدور موفق گواهی، URL محیط Panel را به HTTPS تغییر بده و Cache تنظیمات را بازسازی کن:

~~~
set -eu
sudo sed -i -E 's#^APP_URL=.*#APP_URL=https://panel.fragcity.ir#' /var/www/pterodactyl/.env
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan config:clear
sudo -u www-data php8.3 artisan cache:clear
sudo -u www-data php8.3 artisan view:clear
sudo -u www-data php8.3 artisan config:cache
sudo nginx -t
sudo systemctl reload nginx
~~~

6. بررسی کن:

~~~
set -eu
curl -fsSI --max-time 15 https://panel.fragcity.ir/
sudo certbot certificates
sudo certbot renew --dry-run
~~~

معیار قبولی: درخواست HTTPS بدون خطای گواهی پاسخ دهد و `certbot renew --dry-run` موفق باشد. اگر رکورد DNS، WAN یا دسترسی ورودی هنوز آماده نیست، این مرحله را اجرا نکن. Wings TLS برای `fc-node-01.fragcity.ir` کار جداگانه‌ای است و با گواهی Panel خودکار تکمیل نمی‌شود.

منابع: https://certbot.eff.org/instructions?ws=nginx و https://docs.pterodactyl.io/v1/panel/getting-started



---

## 4. بررسی منابع و عیب‌یابی

### 4.1 دیسک

~~~bash
set -u
df -hT /
df -ih /
sudo du -xhd1 / 2>/dev/null | sort -h
sudo du -xhd1 /var /usr /home /opt /tmp 2>/dev/null | sort -h
sudo du -sh /var/cache/apt/archives 2>/dev/null || true
sudo journalctl --disk-usage
sudo du -sh /var/log /var/lib/docker /var/lib/containerd 2>/dev/null || true
~~~

فضای دیسک با زمان تغییر می‌کند؛ همیشه مقدار فعلی `df -hT /` را پیش از تخصیص فضا ملاک قرار بده. مسیر `/home/steam` را دستکاری نکن.

### 4.2 لاگ‌ها و سرویس‌ها

~~~bash
sudo systemctl is-active nginx mariadb redis-server php8.3-fpm docker
sudo ss -ltnup
sudo journalctl -u nginx -n 80 --no-pager
sudo journalctl -u php8.3-fpm -n 80 --no-pager
~~~

وجود باینری Wings به‌تنهایی به معنی ایجاد یا فعال‌بودن سرویس systemd نیست؛ وضعیت سرویس را فقط پس از مرحلهٔ ساخت سرویس بررسی کن.

### 4.3 اتصال Windows و تونل دیتابیس

از PowerShell:

~~~powershell
ssh <debian-user>@<node-lan-ip>
~~~

برای تونل موقت به MariaDB، پنجره PowerShell را باز نگه دار:

~~~powershell
ssh -N -L 3307:127.0.0.1:3306 <debian-user>@<node-lan-ip>
~~~

در کلاینت دیتابیس ویندوز، host برابر 127.0.0.1 و port برابر 3307 است؛ user/password همان حساب دیتابیس. پورت 3306 را در روتر باز نکن.

---

## 5. Docker Engine — نصب روی Debian Console-only

این بلوک را فقط روی Debian تازه و پس از تکمیل مراحل 1 تا 4 اجرا کن. روی سیستم قدیمی پیش از نصب مجدد اجرا نکن.

~~~bash
set -eu
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
if ! sudo test -s /etc/apt/keyrings/docker.asc; then
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
fi
sudo chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
~~~

پس از نصب یا برای عیب‌یابی، آزمون‌های زیر را اجرا کن. خروجی آن‌ها را به این README اضافه نکن؛ در صورت نیاز به عیب‌یابی، خروجی مرتبط را در گفت‌وگو بفرست.

آزمون‌های بررسی:

~~~bash
sudo docker --version
sudo systemctl is-active docker
sudo docker info --format 'Server={{.ServerVersion}} Containers={{.Containers}} Images={{.Images}}'
sudo docker run --rm hello-world
df -h /
~~~

این فقط Docker را تأیید می‌کند، نه Wings یا اجرای CS2.

---

## 6. Wings و Node — مرحلهٔ جاری

### 6.1 بررسی نسخهٔ Panel

پس از تکمیل نصب Panel و ورود به آن، می‌توانی از این فرمان برای بررسی نسخه استفاده کنی. خروجی را در README قرار نده.

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:info
~~~

برای راه‌اندازی Wings در شاخهٔ Panel 1.x از راهنمای رسمی https://docs.pterodactyl.io/v1/wings/installing استفاده کن و پیش از نصب، Release سازگار را در https://github.com/pterodactyl/wings/releases بررسی کن.

### 6.2 نصب باینری Wings

این مرحله بعد از ساخت Panel و قبل از ساخت Node اجرا شود. فرمان نصب در بلوک زیر برای سیستم تازه آماده شده است؛ اگر باینری از قبل وجود داشت، بلوک عمداً متوقف می‌شود تا فایل موجود بدون بررسی بازنویسی نشود.

~~~bash
set -eu

if sudo test -e /usr/local/bin/wings; then
  echo "STOP: /usr/local/bin/wings already exists; inspect it instead of overwriting."
  sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /usr/local/bin/wings
  exit 1
fi

sudo install -d -o root -g root -m 0755 /etc/pterodactyl
curl -fL \
  "https://github.com/pterodactyl/wings/releases/download/v1.13.4/wings_linux_amd64" \
  -o /tmp/wings_linux_amd64
file /tmp/wings_linux_amd64
sha256sum /tmp/wings_linux_amd64
sudo install -o root -g root -m 0755 \
  /tmp/wings_linux_amd64 /usr/local/bin/wings
/usr/local/bin/wings --help
~~~

فرمان‌های بررسیِ فقط‌خواندنی (خروجی را در README ثبت نکن):

~~~bash
sudo /usr/local/bin/wings version
sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /usr/local/bin/wings
~~~

این فرمان‌ها فقط باینری محلی را بررسی می‌کنند و به‌معنی پیکربندی یا اتصال Wings به Panel نیستند.

### 6.3 ساخت Node از مرورگر Windows — گام بعدی

این مرحله از مرورگر Windows انجام می‌شود؛ داخل Debian فرمانی برای ساخت Node لازم نیست.

**اول فضای فعلی را فقط بررسی کن** (بدون تغییر فایل‌ها):

~~~bash
echo "=== RAM ==="
free -h
echo
echo "=== Root filesystem ==="
df -hT /
~~~

قبل از تنظیم Node، فضای آزاد فعلی را ملاک بگیر.

در مرورگر Windows:
1. وارد `https://panel.fragcity.ir` شو و مطمئن شو با حساب Administrator وارد شده‌ای. این مرحله فقط بعد از تنظیم DNS و گواهی TLS انجام می‌شود.
2. از **Admin → Locations** یک Location بساز یا Location موجود را انتخاب کن؛ مثلاً Short Code برابر `lan` و Description برابر `FragCity LAN`.
3. به **Admin → Nodes → Create New** برو.
4. در Identity: نام `fc-node-01`، توضیح اختیاری، و Location مرحلهٔ قبل را انتخاب کن.
5. در Network/Daemon: FQDN برابر `fc-node-01.fragcity.ir`، SSL فعال پس از صدور و نصب گواهی معتبر برای همین نام، Daemon Port برابر `8080` و Daemon SFTP Port برابر `2022` باشد. DNS عمومی باید به IP عمومی Node برسد و قبل از ساخت Node باید TLS و فایروال بررسی شده باشند. از IP خصوصی در FQDN عمومی استفاده نکن.
6. در بخش منابع، مقادیر Memory/Disk را فقط بر اساس خروجی واقعی `free -h` و `df -hT /` در سرور تازه تعیین کن. برای شروع Overallocate را `0` نگه دار و فضای کافی برای Debian، Docker، لاگ‌ها و رشد بعدی آزاد بگذار. اعداد ثابتِ VM قبلی را به Node جدید تعمیم نده؛ ظرفیت تخصیصی Panel فضای فیزیکی اضافه نمی‌کند.
7. اگر فیلد Server File Directory نمایش داده شد، فعلاً مقدار پیش‌فرض `/var/lib/pterodactyl/volumes` را حفظ کن. **آن را روی `/home/steam` تنظیم نکن**؛ طرح استفادهٔ مجدد از بازی موجود هنوز طراحی نشده است.
8. Node را ذخیره کن. سپس وارد صفحهٔ همان Node شو و نتیجهٔ ساخت را بررسی کن.

فعلاً Allocation برای سرور بازی نساز و هیچ سروری ایجاد نکن؛ ابتدا اتصال Wings را تأیید می‌کنیم و سپس Storage/Egg/Ports را جداگانه طراحی می‌کنیم.

### 6.4 تولید config محرمانه از خود Panel

پس از ساخته‌شدن Node، تب **Configuration** همان Node را باز کن و در بخش **Auto-Deploy** روی **Generate Token** بزن. فرمان کامل Bash را که خود Panel می‌سازد، مستقیم و بدون ویرایش در SSH مربوط به Debian اجرا کن. token یا command تولیدشده را اینجا نفرست و در GitHub قرار نده.

پس از اجرای فرمان دقیق Auto-Deploy از Panel، فقط وجود فایل را بررسی کن:

~~~bash
sudo test -s /etc/pterodactyl/config.yml && echo "OK: node config exists"
sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /etc/pterodactyl/config.yml
~~~

Token و Node ID را حدس نزن؛ UI آن‌ها را تولید می‌کند. فایل config نباید وارد Git شود.

### 6.5 اجرای foreground

فقط بعد از Node creation و config:

~~~bash
sudo wings --debug
~~~

لاگ را بررسی کن. اگر بدون خطای fatal اجرا شد با Ctrl+C متوقفش کن. اگر خطا داد، متن خطا را بفرست و token/secret را حذف کن. تا debug موفق نشده، systemd service نساز و WAN را باز نکن.

### 6.6 systemd (پس از debug موفق)

~~~bash
sudo tee /etc/systemd/system/wings.service >/dev/null <<'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now wings
sudo systemctl status wings --no-pager
sudo systemctl is-active wings
~~~

تأیید: سرویس active و Node در Panel برابر Online شود. اگر خطا داشت:

~~~bash
sudo journalctl -u wings -n 100 --no-pager
sudo systemctl status wings --no-pager
sudo ss -ltnup | grep -E ':(8080|2022)\b' || true
~~~

پیش از استفادهٔ عمومی، دامنه، TLS مخصوص Panel و Wings، firewall و Router/VMware NAT را جداگانه طراحی کن.

---

## 7. Storage و CS2/KUS — بعد از Online شدن Node

این فصل هنوز فرمان اجرایی ندارد. پیش از ساخت اولین سرور:
1. فضای دیسک و حجم دانلود واقعی را بسنجیم.
2. مشخص کنیم Egg فعلی CS:GO قدیمی است یا CS2 را درست نصب می‌کند.
3. روش استفاده از بازی موجود زیر /home/steam در مدل Container/Volume را طراحی کنیم.
4. CPU/RAM/disk و portهای instance آزمایشی را تعیین کنیم.
5. Start/Stop/Console/Files/SFTP و جدایی داده‌ها را آزمایش کنیم.

تا آن زمان instance جدید نساز و به /home/steam دست نزن.

## 8. سایت FragCity، Wallet و فروش مدت‌دار — فازهای بعد

این بخش هنوز دستور نهاییِ اجرا و آزمایش‌شده ندارد. پس از اثبات PoC سرور بازی، همین runbook با فرمان‌های معتبر برای موارد زیر ادامه پیدا می‌کند:
- API امن بین سایت Raw PHP و Pterodactyl؛
- اتصال فروشگاه/Paymenter؛
- شارژ Wallet، کسر یک‌باره، سفارش و expires_at؛
- suspend/stop هنگام انقضا بدون حذف داده؛
- backup/restore، retry و idempotency؛
- Node دوم، آزمون ظرفیت و نصب تکرارپذیر؛
- DNS/TLS، firewall و دسترسی عمومی پس از قبولی آزمون LAN.

فرمان اجرانشده را به‌عنوان دستور آمادهٔ Production ثبت نمی‌کنیم؛ پس از اجرا و تست به همین سند اضافه می‌شود.

## 9. آخرین checkpoint

| بخش | وضعیت مسیر جدید |
|---|---|
| هدف محیط | Debian 13 Console-only؛ بدون Desktop Environment |
| نصب سیستم‌عامل | تکمیل شده؛ console login روی `fc-node-01 tty1` |
| مرحلهٔ جاری | UFW و بررسی‌های مرحلهٔ 1.20 موفق‌اند؛ ورود تازه با کلید SSH نیز با موفقیت تأیید شد. گام بعدی Snapshot مرحلهٔ 1.21 و سپس اجرای ترتیبی 2.1، 2.2، 2.3، 3.1 و 3.2 است؛ بعد از 3.2 توقف کن و لاگ‌ها را برای بررسی بفرست. |
| مراحل پایه | مراحل 1.9 تا 1.18 اجرا شده‌اند؛ نتیجهٔ هر مرحله را از لاگ‌های همین گفتگو بررسی کن |
| Hostname | `fc-node-01` |
| Domain name / FQDN | `fragcity.ir` و `fc-node-01.fragcity.ir` |
| IP LAN / رزرو DHCP | آخرین خروجی: `192.168.1.7/24` روی `ens33`، Gateway برابر `192.168.1.1`. رزرو DHCP روتر را پیش از اتکا به IP در Port Forward تأیید کن. |
| Panel FQDN هدف | `panel.fragcity.ir` |
| DNS / public IP | رکوردهای عمومی باید پیش از TLS با IPv4 عمومی WAN تطبیق داده شوند |
| SSH hardening | سرویس فعال، پیکربندی sshd معتبر، ورود root و احراز هویت با رمز غیرفعال، احراز هویت کلیدی فعال، و ورود واقعی از پنجرهٔ تازهٔ Windows PowerShell موفق است. |
| Firewall UFW | فعال؛ ورودی پیش‌فرض مسدود، خروجی مجاز، SSH محدود به LAN `192.168.1.0/24` و TCP پورت‌های 80/443 مجاز است. |
| Panel / Docker / Wings | نصب روی Debian تازه هنوز آغاز نشده |
| CS2 instance / game files | در این فاز نصب نمی‌شوند؛ طراحی روی محیط آزمایشگاهی و فاز جداگانه |
| Website/Wallet/Billing | فازهای بعدی |

خروجی اجرای فرمان‌ها، لاگ‌ها، رمزها، نام حساب‌های شخصی و SHAهای فایل‌ها را به این README اضافه نکن. این سند فقط دستورها، تصمیم‌های معماری و مراحل تکرارپذیر را نگه می‌دارد.

## منابع رسمی

- Debian Installer guide: https://www.debian.org/releases/trixie/amd64/install.en.pdf

- Debian: https://www.debian.org/distrib/
- Panel releases: https://github.com/pterodactyl/panel/releases
- Wings 1.x installation: https://docs.pterodactyl.io/v1/wings/installing
- Wings releases: https://github.com/pterodactyl/wings/releases
- Docker on Debian: https://docs.docker.com/engine/install/debian/
- Composer: https://getcomposer.org/download/
