# Runbook نصب Debian 13، PHP، Composer، Pterodactyl Panel، Docker و Wings

> **هدف این فایل:** Runbook ترتیبی برای نصب Debian 13، PHP و Composer، Pterodactyl Panel، Docker Engine، Wings، Firewall و سرویس‌های لازم است. هر مرحله هدف، فرمان و روش تأیید دارد. پیش از اجرای مرحله‌ای که Firewall، SSH، دیسک یا سرویس‌ها را تغییر می‌دهد، پیش‌نیاز و راه بازگشت همان بخش را بخوان.
>
> این Runbook یک آموزش قابل‌تکرار است؛ hostname، IP، دامنه‌ها و مسیرهای نمونه به‌صورت خودکار با مقادیر تو جایگزین نمی‌شوند. پیش از Copy/Paste، جدول بخش **0.3** را تکمیل کن و هر مقدار نمونه را در دستورها با مقدار محیط خودت تطبیق بده. این فایل محل ثبت گزارش/لاگ یک VM مشخص نیست.
>
> **قانون محرمانگی:** رمز MariaDB، رمز حساب، APP_KEY، Tokenها، URLهای Webhook، فایل .env و محتوای /etc/pterodactyl/config.yml را در GitHub یا چت قرار نده. فرمان‌ها و مقادیر نمونه را فقط به‌شکل محلی جایگزین کن.

---

## 0. پیش‌نیازها، مقادیر محیطی و قواعد اجرای امن

این Runbook نصب Debian 13 و زیرساخت Pterodactyl را مرحله‌به‌مرحله آموزش می‌دهد. بخش‌هایی از نسخهٔ مرجع ابتدا برای محیط FragCity نوشته شده‌اند، اما مقادیر میزبان/شبکه باید برای هر نصب جداگانه تعیین شوند.

### پیش از اجرا این مقادیر را مشخص کن

| Placeholder | معنی | از کجا پیدا شود |
|---|---|---|
| <NODE_HOSTNAME> | نام میزبان Debian | نامی که در نصاب و DNS انتخاب می‌کنی |
| <BASE_DOMAIN> | دامنه‌ای که مالک آن هستی | پنل مدیریت DNS |
| <PANEL_FQDN> | نام کامل DNS برای Panel | رکورد DNS و تنظیم APP_URL |
| <NODE_FQDN> | نام کامل DNS برای Wings/Node | رکورد DNS و TLS مخصوص Node |
| <NODE_LAN_IP> | IP داخلی ثابت Node اصلی | DHCP reservation و ip address |
| <CLONE_LAN_IP> | IP داخلی Clone موقت، فقط در سناریوی Clone | DHCP reservation برای MAC جدید |
| <LAN_CIDR> | محدودهٔ شبکهٔ داخلی | ip route و تنظیمات روتر |
| <LAN_GATEWAY_IP> | Gateway شبکه | خروجی ip route |
| <LINUX_USER> | حساب Linux عادی | حساب ساخته‌شده هنگام نصب Debian |
| <CS2_GAME_PORT> | Port تخصیص‌یافتهٔ CS2، اگر لازم است | Allocation واقعی در Panel |

**هیچ دستوری را با placeholderهای زاویه‌دار اجرا نکن.** پیش از Copy/Paste، تمام مقادیر مربوط به نصب خودت را در متن فرمان و فایل تنظیمات جایگزین کن. IP خصوصی LAN را به‌عنوان رکورد عمومی DNS استفاده نکن؛ رکورد عمومی باید به IPv4 عمومی قابل‌دسترسی اشاره کند.

### محدوده و قواعد ایمنی

- در Software selection، نصب Console-only پیشنهاد می‌شود؛ XFCE اجباری نیست و در صورت نصب‌بودن آن نیز دستورات این Runbook از Terminal اجرا می‌شوند. این سند آموزش SSH key یا بازکردن SSH از WAN ندارد.
- در VMware، دیسک VMDK قبلی یا نسخهٔ پشتیبان را به‌عنوان دیسک مقصد نصب تازه انتخاب و overwrite نکن.
- پیش از هر عملیات Partition/Format/Mount، دستگاه را با lsblk و blkid شناسایی کن؛ نامی مثل /dev/sdb را حدس نزن.
- TCP 80/443 برای TLS عمومی باید از اینترنت به IP داخلی رزروشدهٔ میزبان درست برسد. قانون UFW به‌تنهایی Port Forward روتر را تنظیم نمی‌کند.
- SSH، MariaDB و Redis را بی‌دلیل در اینترنت عمومی نکن.
- اگر از Clone موقت برای جایگزینی Node استفاده می‌کنی، VM اصلی و Clone را با هویت مشترک هم‌زمان روشن نکن. Node دوم مستقل باید Hostname، IP، DNS، TLS و config اختصاصی داشته باشد.
- رمزهای حساب، MariaDB، Redis، APP_KEY، Token، GSLT، Webhook URL، فایل .env و محتوای محرمانهٔ /etc/pterodactyl/config.yml را در GitHub یا چت منتشر نکن.

### قرارداد اجرای مرحله‌ای

- هر بلوک را فقط در محل اجرای مشخص‌شده اجرا کن: ترمینال/کنسول Debian، Windows PowerShell (فقط جایی که صریحاً نوشته شده)، prompt دیتابیس، یا فایل تنظیمات.
- JSON، YAML و NGINX config را در Bash اجرا نکن؛ آن‌ها باید در فایل مربوطه قرار گیرند.
- اگر نشست مدیریتی قطع شد، از کنسول VMware وارد Debian شو؛ نصب را از ابتدا تکرار نکن و فایل یا سرویس را بدون بررسی حذف/Restart نکن.
- اگر مرحله‌ای FAIL شد، مرحلهٔ بعد را اجرا نکن؛ ابتدا فرمان‌های فقط‌خواندنی همان بخش و علت خطا را بررسی کن.

## 1. نصب Debian 13 از صفر — Console-only

این مرحله از طریق نصاب Debian در VMware انجام می‌شود. وقتی به صفحهٔ Partitioning method رسیدی، مراحل زیر را دنبال کن؛ در نصب از قبل انجام‌شده، تا وقتی سیستم سالم است پارتیشن‌بندی را تکرار نکن.

### 1.1 تعیین نام میزبان و دامنه در نصاب

نمونهٔ مقادیر برای محیط مرجع این ریپو:
- **Hostname:** `<NODE_HOSTNAME>`
- **Domain name:** `<BASE_DOMAIN>`
- **FQDN موردنظر Node:** `<NODE_FQDN>`
- **FQDN موردنظر Panel:** `<PANEL_FQDN>`

برای محیط خودت، مقدارهای واقعی بخش 0.3 را وارد کن. اگر هنوز دامنه یا DNS آماده نیست، دامنهٔ متعلق به خودت را تعیین کن و پیش از صدور گواهی/انتشار عمومی DNS و Port Forward را تأیید کن.

تنظیم DNS، HTTPS و دسترسی عمومی بعد از نصب و بررسی اتصال شبکه انجام می‌شود؛ فیلد Domain name جایگزین آن‌ها نیست.

### 1.2 انتخاب طرح پارتیشن‌بندی

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

پس از نمایش صفحهٔ login متنی Debian، با حسابی که هنگام نصب ساختی وارد شو. نام حساب و رمز را در README یا چت ننویس. سپس این بلوک فقط‌خواندنی را اجرا کن:

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

این مرحله تغییری نمی‌دهد. اگر سیستم با نامی غیر از `<NODE_HOSTNAME>` بالا آمده یا دیسک مقصد غیرمنتظره است، پیش از مراحل بعدی خروجی را بفرست.

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

Hostname و FQDN را با جدول بخش 0.3 و DNS واقعی هماهنگ کن. مقادیر زیر برای محیط FragCity نمونه‌اند و برای نصب دیگر باید بررسی شوند. این Runbook از منطقهٔ زمانی **Asia/Tehran** استفاده می‌کند؛ آن را به UTC تغییر نده.

~~~bash
set -eu

TARGET_HOST="server1"
TARGET_FQDN="server1.fragcity.ir"

sudo hostnamectl set-hostname "$TARGET_HOST"
sudo sed -i -E '/^127\.0\.1[[:space:]]/d' /etc/hosts
printf '127.0.1.1 %s %s\n' "$TARGET_FQDN" "$TARGET_HOST" |
  sudo tee -a /etc/hosts >/dev/null

sudo timedatectl set-timezone Asia/Tehran
sudo systemctl enable --now chrony

echo "=== Verify ==="
hostname -f
timedatectl show -p Timezone -p NTPSynchronized -p NTP
~~~

در /etc/hosts باید یک نگاشت محلی درست برای FQDN و hostname وجود داشته باشد. این نگاشت جای رکورد A در DNS عمومی را نمی‌گیرد. انتظار می‌رود Timezone برابر Asia/Tehran باشد؛ NTP ممکن است برای Synchronization چند لحظه زمان بخواهد.

### 1.13 مرحلهٔ پنجم — بررسی اختیاری SSH

برای نصب و مدیریت این Runbook می‌توانی مستقیماً از Terminal داخل Debian/VMware استفاده کنی؛ ساخت SSH key یا اتصال روزمره از Windows جزو این آموزش نیست. اگر SSH server هنگام نصب Debian انتخاب شده باشد، وضعیتش را فقط بررسی کن:

~~~bash
set -eu
sudo sshd -t
sudo systemctl is-active ssh || true
sudo ss -ltnp | grep -E 'LISTEN.+:22([[:space:]]|$)' || true
~~~

این بررسی هیچ تنظیم SSH را تغییر نمی‌دهد. پورت 22 را از اینترنت عمومی Port Forward نکن. طبق طرح FragCity، دسترسی SSH از WAN بعداً در سیاست MikroTik مسدود می‌شود؛ تا آن زمان برای مدیریت از کنسول VMware استفاده کن یا فقط یک مسیر LAN مورداعتماد را نگه دار.

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
echo "=== System clock and NTP (Asia/Tehran) ==="
date
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

این بلوک فقط‌خواندنی است. نام‌های نمونه را با hostname/FQDN خودت هماهنگ کن و interface را از خروجی `ip -br address` در مرحلهٔ 1.14 انتخاب کن.

~~~bash
set -eu

TARGET_HOST="<NODE_HOSTNAME>"                 # Replace with your hostname
TARGET_FQDN="<NODE_FQDN>"     # Replace with your Node FQDN
IFACE="ens33"                            # Replace with the real LAN interface

echo "=== Host identity and local resolution ==="
hostname -s
hostname -f
getent hosts "$TARGET_HOST" || true
getent hosts "$TARGET_FQDN" || true

echo
echo "=== LAN identity ==="
ip -4 -o address show dev "$IFACE"
cat "/sys/class/net/$IFACE/address"

echo
echo "=== Default route ==="
ip route

echo
echo "=== Services and time ==="
sudo -v
systemctl is-active ssh chrony
timedatectl show -p Timezone -p NTPSynchronized -p NTP
~~~

اگر hostname یا FQDN resolve نشد، یا هشدار `sudo: unable to resolve host` تکرار شد، پیش از ادامه فایل `/etc/hosts` و مقدارهای بالای بلوک را بررسی کن. از hostname یا interface حدسی استفاده نکن.

### 1.16 مرحلهٔ هشتم — رزرو DHCP برای IP داخلی ثابت

هدف این است که MAC کارت شبکهٔ Node همیشه همان IP داخلی رزروشده را دریافت کند. فعلاً روی Debian آدرس استاتیک دستی تعریف نکن؛ رزرو DHCP و IP استاتیک داخل سیستم را هم‌زمان تنظیم نکن.

1. در Debian، نام interface و MAC را با بلوک زیر پیدا کن.
2. در روتر/DHCP server شبکه، subnet و gateway واقعی را بررسی کن. اگر از MikroTik/Winbox استفاده می‌کنی، مسیر معمول **IP → DHCP Server → Leases** است.
3. Lease همان MAC را پیدا کن و برای آن Reservation/Static Lease بساز.
4. یک IP آزاد از subnet خودت انتخاب کن؛ مطمئن شو به دستگاه دیگری اختصاص نیافته است.
5. پس از ذخیرهٔ رزرو، VM را از کنسول VMware با فرمان زیر reboot کن. این کار نشست ترمینال را قطع می‌کند؛ پس از بالا آمدن دوباره از خود کنسول VMware وارد شو.

~~~bash
sudo reboot
~~~

پس از reboot این بلوک را در Debian اجرا کن:

~~~bash
set -eu
IFACE="ens33"   # Replace only if ip -br address shows a different interface

ip -4 -o address show dev "$IFACE"
ip route
cat "/sys/class/net/$IFACE/address"
~~~

ادامه فقط وقتی انجام شود که IP و MAC با DHCP reservation مطابقت داشته باشند. اگر IP تغییر کرد، آدرس فعلی را از کنسول VM و روتر پیدا کن و قبل از ادامه تأیید کن. برای این Runbook نیازی به راه‌اندازی SSH key یا اجرای فرمان SSH از Windows نیست.

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

نکتهٔ URL: `https://<PUBLIC_IP>:80/` یعنی اتصال HTTPS روی پورت 80؛ این ترکیب غیرمعمول است. HTTP معمولاً با `http://<PUBLIC_IP>/` و HTTPS با `https://<PUBLIC_IP>/` استفاده می‌شود. تا وقتی رابط مدیریت مودم بررسی نشده، از صفحهٔ IP عمومی وارد حساب نشو.

#### قدم A — ورود محلی به مودم/روتر

1. از روی Debian در `ip route`، Gateway واقعی شبکه را شناسایی کن. `<LAN_GATEWAY_IP>` فقط یک نمونه است؛ Gateway را از روی خروجی خودت بخوان و حدس نزن.
2. از مرورگر داخل همان LAN، صفحهٔ مدیریت محلی Gateway را باز کن، مثلاً `http://<LAN_GATEWAY_IP>/`. فقط از آدرس محلی استفاده کن.
3. در تنظیمات مودم/روتر دنبال گزینه‌هایی با نام‌هایی مانند **Remote Management**, **Web Access from WAN**, **WAN HTTP/HTTPS Access**, **Remote Web Administration** یا **Management from Internet** بگرد.
4. دسترسی مدیریتی از WAN را برای HTTP و HTTPS خاموش کن؛ دسترسی مدیریتی از LAN را نگه دار تا بتوانی روتر را محلی مدیریت کنی. اگر نام گزینه‌ها یا عملکردشان نامشخص است، قبل از تغییر از صفحهٔ تنظیمات عکس بگیر و مدل دستگاه را مشخص کن؛ تنظیمات WAN، Bridge، PPPoE یا TR-069 را حدس‌زنان تغییر نده.
5. اگر رمز مدیریت مودم ضعیف یا پیش‌فرض است، یک رمز یکتا و قوی تنظیم کن. رمز را در چت یا README ننویس.

#### قدم B — بررسی از خارج شبکه

برای اینکه مشخص شود رابط مدیریت واقعاً از اینترنت قابل‌دسترسی است، از یک گوشی با **Wi-Fi خاموش و دیتای موبایل روشن** استفاده کن. تا وقتی این تست را نکرده‌ای، از نتیجهٔ تستی که روی همان LAN انجام شده نتیجه‌گیری قطعی نکن.

پس از غیرفعال‌کردن WAN management، از دیتای موبایل فقط صفحهٔ زیر را بررسی کن و **هیچ رمز مدیریتی وارد نکن**:
- `http://<PUBLIC_IP>/` (HTTP/80)
- `https://<PUBLIC_IP>/` (HTTPS/443)

اگر هنوز صفحهٔ ورود مودم از اینترنت دیده می‌شود، برای این مرحله توقف کن؛ مدیریت WAN را از تنظیمات خود دستگاه یا با کمک ISP غیرفعال کن. در صورت لزوم رمز مدیریتی مودم را هم عوض کن. اگر صفحه دیگر دیده نمی‌شود، این مسئله را به‌معنی آماده‌بودن Panel فرض نکن؛ هنوز Port Forwarding، UFW، NGINX و TLS باید جداگانه تنظیم و آزمایش شوند.

**قانون برای مراحل بعد:** رابط مدیریت مودم باید فقط از LAN قابل‌دسترسی باشد. وقتی Panel آماده شد، TCP 80 و 443 روتر را به IP داخلی رزروشدهٔ Debian هدایت می‌کنیم؛ آن را به خود مودم یا صفحهٔ مدیریت مودم هدایت نمی‌کنیم. هیچ‌وقت پورت 22، 3306 یا 6379 را برای دسترسی عمومی باز نکن.

### 1.18 مرحلهٔ دهم — بررسی و آماده‌سازی DNS عمومی

ابتدا FQDNهای واقعی Panel و Node را در متغیرهای زیر وارد کن. نام‌های نمونه باید با دامنه‌ای جایگزین شوند که مالک آن هستی و DNS آن را مدیریت می‌کنی. فرمان `dig`، DNS را می‌خواند و ورودی محلی `/etc/hosts` را دور می‌زند.

~~~bash
set -eu
BASE_DOMAIN="<BASE_DOMAIN>"                  # Replace with your domain
PANEL_FQDN="<PANEL_FQDN>"             # Replace with the real Panel FQDN
NODE_FQDN="<NODE_FQDN>"         # Replace with the real Node FQDN

if [[ "$BASE_DOMAIN" == *REPLACE* || "$PANEL_FQDN" == *REPLACE* || "$NODE_FQDN" == *REPLACE* ]]; then
  echo "STOP: replace all domain examples before querying DNS."
  exit 1
fi

echo "=== Authoritative DNS servers ==="
dig +short NS "$BASE_DOMAIN"

echo
echo "=== Public A records ==="
dig +short A "$PANEL_FQDN"
dig +short A "$NODE_FQDN"

echo
echo "=== Existing IPv6 records ==="
dig +short AAAA "$PANEL_FQDN"
dig +short AAAA "$NODE_FQDN"
~~~

1. از روی NS مشخص کن مدیریت DNS واقعاً در کدام سرویس انجام می‌شود و فقط در همان پنل Zone را ویرایش کن.
2. پس از تأیید داشتن IPv4 عمومی قابل‌استفاده در مرحلهٔ 1.17، رکوردهای **A** مربوط به Panel و Node را به همان IP عمومی تنظیم کن؛ هرگز IP خصوصی LAN را به‌عنوان رکورد عمومی قرار نده.
3. اگر Cloudflare داری، برای راه‌اندازی اولیهٔ Wings رکورد Node را **DNS only** نگه دار؛ پراکسی عمومی را بدون طراحی و پشتیبانی از پورت‌ها فرض نگیر.
4. رکورد **AAAA** نساز یا نگه ندار مگر IPv6 عمومی، مسیر ورودی، سرویس و Firewall همگی واقعاً تنظیم و آزمایش شده باشند.
5. خروجی A را با IPv4 عمومی تأییدشده تطبیق بده. اگر رکوردها هنوز به‌روز نشده‌اند یا مقدار نامناسب دارند، قبل از ادامه علت را مشخص کن.

ساخت رکورد DNS به‌تنهایی Port Forwarding، TLS یا دسترسی ورودی را فعال نمی‌کند.

### 1.19 مرحلهٔ یازدهم — ممیزی Base و سیاست شبکه

در ادامهٔ این Runbook، نصب و مدیریت از کنسول/ترمینال خود Debian انجام می‌شود. آموزش ساخت SSH key در Windows، تغییر sshd_config و اتصال روزمره با کلید SSH از این سند حذف شده است؛ برای مراحل این نصب لازم نیست.

**قواعد مهم شبکه برای FragCity:**
- این Runbook قوانین UFW را ایجاد، حذف یا بازنویسی نمی‌کند. وضعیت موجود را فقط می‌خواند؛ تغییر Firewall باید آگاهانه و جداگانه انجام شود.
- در طرح نهایی MikroTik، مدیریت روتر از WAN و اتصال SSH از WAN باید مسدود باشند. برای مدیریت میزبان می‌توان از VMware console یا یک مسیر مدیریتی محدود و مورداعتماد استفاده کرد.
- «بستن تمام پورت‌های WAN» به معنی خارج‌شدن Panel، Wings/SFTP و سرورهای CS2 از دسترس اینترنت است. در سیاست نهایی فقط پورت‌های موردنیاز محصول را مجاز کن؛ SSH، مدیریت روتر، MariaDB و Redis را از WAN منتشر نکن.
- گواهی‌های این Runbook با HTTP-01 صادر می‌شوند؛ برای تمدید خودکار، TCP/80 باید به مسیر challenge روی Debian برسد. اگر در آینده پورت 80 را کاملاً ببندی، روش تمدید گواهی باید عوض شود.
- Docker می‌تواند قواعد شبکهٔ خودش را برای پورت‌های Container بسازد؛ UFW به‌تنهایی مرز امنیتی کامل برای پورت‌های منتشرشدهٔ Docker نیست. سیاست WAN را در MikroTik هم بررسی کن.

~~~bash
set -eu

echo "=== Base OS ==="
. /etc/os-release
printf 'OS=%s VERSION_ID=%s CODENAME=%s\n' "$NAME" "$VERSION_ID" "$VERSION_CODENAME"
hostname -f

echo
echo "=== Timezone and NTP ==="
timedatectl show -p Timezone -p NTPSynchronized -p NTP

echo
echo "=== Package health ==="
sudo apt-get check
sudo dpkg --audit

echo
echo "=== Network and storage ==="
ip -br address
ip route
free -h
df -hT /
df -ih /

echo
echo "=== Existing firewall state (read-only) ==="
sudo ufw status verbose || true
~~~

**Snapshot/Backup:** فعلاً Snapshot را به‌عنوان مرحلهٔ اجباری پیش از نصب برنامه نگیر. پس از تکمیل هر دو Runbook و قبولی آزمون CS2، نسخهٔ پشتیبان مستقل از VM خاموش‌شده تهیه می‌کنیم. Snapshot زنجیره‌ای VMDK جای Backup مستقل را نمی‌گیرد.

## 2. نصب PHP 8.3 و نیازمندی‌های Panel (نصب تازه)

این فصل برای نصب تازه است. اگر بسته‌ها یا تنظیمات از قبل وجود دارند، بخش بررسی را اجرا کن و فایل‌های منبع موجود را کورکورانه بازنویسی نکن.

### 2.1 افزودن مخزن Sury برای PHP 8.3

Debian 13 مخزن PHP 8.3 موردنیاز این نسخهٔ Panel را به‌صورت پیش‌فرض ارائه نمی‌دهد؛ از مخزن Sury استفاده می‌کنیم. اگر فایل منبع یا keyring از قبل وجود دارد، آن را بررسی کن و بی‌دلیل جایگزین نکن.

~~~bash
set -eu

sudo apt update
sudo apt install -y ca-certificates curl

if ! sudo test -s /usr/share/keyrings/debsuryorg-archive-keyring.gpg; then
  curl -fsSL https://packages.sury.org/debsuryorg-archive-keyring.deb \
    -o /tmp/debsuryorg-archive-keyring.deb
  sudo apt install -y /tmp/debsuryorg-archive-keyring.deb
fi

if ! sudo test -s /etc/apt/sources.list.d/php.sources; then
  sudo tee /etc/apt/sources.list.d/php.sources >/dev/null <<'SOURCE'
Types: deb
URIs: https://packages.sury.org/php/
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/debsuryorg-archive-keyring.gpg
SOURCE
else
  echo "Existing php.sources found; not overwriting it."
  sudo sed -n '1,80p' /etc/apt/sources.list.d/php.sources
fi

sudo apt update

echo
echo "=== PHP 8.3 candidate ==="
apt-cache policy php8.3-cli
~~~

**معیار قبولی:** apt update موفق باشد و php8.3-cli یک Candidate واقعی نشان دهد. اگر Candidate برابر none بود، متوقف شو و مخزن/keyring را بررسی کن.

### 2.2 نصب PHP، NGINX و سرویس‌های موردنیاز

~~~bash
sudo apt install -y \
  php8.3 php8.3-cli php8.3-common php8.3-gd php8.3-mysql \
  php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl \
  php8.3-zip php8.3-fpm php8.3-intl php8.3-opcache \
  mariadb-server redis-server nginx git curl tar unzip
~~~

فعال‌سازی و بررسی:

~~~bash
sudo systemctl enable --now nginx mariadb redis-server php8.3-fpm

for service in nginx mariadb redis-server php8.3-fpm; do
  printf '%s: ' "$service"
  sudo systemctl is-active "$service"
done

echo
echo "=== Local listeners ==="
sudo ss -ltnp | grep -E ':(22|80|443|3306|6379)\b' || true
~~~

MariaDB باید فقط روی loopback مانند 127.0.0.1:3306 و Redis روی loopback مانند 127.0.0.1:6379 گوش دهد. برای این دو سرویس Port Forward عمومی نساز.

### 2.3 نصب Composer با اعتبارسنجی Installer

این روش امضای SHA-384 رسمی Installer را با فایل دانلودشده مقایسه می‌کند. اگر مطابقت نداشت، نصب متوقف می‌شود.

~~~bash
set -eu

cd /tmp
EXPECTED_CHECKSUM="$(curl -fsSL https://composer.github.io/installer.sig)"
curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
ACTUAL_CHECKSUM="$(sha384sum /tmp/composer-setup.php | awk '{print $1}')"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
  echo "ERROR: Composer installer checksum mismatch; refusing to install."
  rm -f /tmp/composer-setup.php
  exit 1
fi

sudo php8.3 /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f /tmp/composer-setup.php

php8.3 -v
COMPOSER_ALLOW_SUPERUSER=1 php8.3 /usr/local/bin/composer --version
~~~

در نصب وابستگی‌های Panel، Composer را با کاربر www-data اجرا کن؛ باینری Composer در /usr/local/bin/composer قرار می‌گیرد.

### 2.4 پس‌بررسی سلامت

~~~bash
(
set -eu

echo "=== Package manager health ==="
sudo apt-get check
sudo dpkg --audit

echo
echo "=== Required PHP extensions ==="
for module in bcmath curl dom gd intl json mbstring mysqli openssl PDO pdo_mysql posix tokenizer xml zip; do
  php8.3 -m | grep -Eixq "$module" || { echo "MISSING: $module"; exit 1; }
  echo "OK: $module"
done

echo
echo "=== Service and syntax checks ==="
sudo /usr/sbin/php-fpm8.3 -t
sudo /usr/sbin/nginx -t
sudo mariadb -Nse "SELECT VERSION();"
redis-cli ping

for service in nginx mariadb redis-server php8.3-fpm; do
  printf '%s: enabled=' "$service"
  sudo systemctl is-enabled "$service"
  printf '%s: active=' "$service"
  sudo systemctl is-active "$service"
done
)
~~~

redis-cli ping باید PONG برگرداند. اگر هرکدام از معیارها Fail شد، نصب Panel را شروع نکن.

## 3. نصب و پیکربندی Pterodactyl Panel

### 3.0 نسخهٔ Panel و سازگاری

Baseline آزمایش‌شده در این Runbook (بررسی‌شده در 21 اکتبر 2026):
- Panel: v1.15.1
- PHP CLI/FPM: PHP 8.3
- Debian: Debian 13 (Trixie)
- Wings: v1.13.4 (فصل 6)

پیش از نصب تازه در زمان دیگری، Releaseهای رسمی و مستندات همان شاخه را بررسی کن و Beta/Pre-release را برای Production انتخاب نکن:
- Releases: https://github.com/pterodactyl/panel/releases
- راهنمای نصب: https://docs.pterodactyl.io/v1/panel/getting-started

اگر نیازمندی‌های رسمی نسخه‌ها تغییر کرده‌اند، قبل از اجرای فرمان‌ها سازگاری Panel، PHP و Wings را دوباره بررسی کن.

### 3.1 دریافت فایل‌های Panel و نصب وابستگی‌ها

در نصب تازه اگر /var/www/pterodactyl/.env از قبل موجود باشد، متوقف شو و نصب را دوباره اجرا نکن. APP_KEY پس از تولید باید حفظ شود.

~~~bash
(
set -Eeuo pipefail

PANEL_VERSION="v1.15.1"
PANEL_DIR="/var/www/pterodactyl"
ARCHIVE="/tmp/pterodactyl-panel-v1.15.1.tar.gz"

echo "=== Check for existing installation ==="
if sudo test -e "$PANEL_DIR/.env"; then
  echo "STOP: .env already exists; this is not a clean install."
  exit 1
fi

echo
echo "=== Prepare and download official release ==="
sudo install -d -o www-data -g www-data "$PANEL_DIR"
sudo curl -fL \
  "https://github.com/pterodactyl/panel/releases/download/$PANEL_VERSION/panel.tar.gz" \
  -o "$ARCHIVE"
sudo tar -xzf "$ARCHIVE" -C "$PANEL_DIR"

echo
echo "=== Set ownership and writable paths ==="
sudo chown -R www-data:www-data "$PANEL_DIR"
sudo find "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache" -type d -exec chmod 750 {} +
sudo find "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache" -type f -exec chmod 640 {} +

echo
echo "=== Create initial environment file ==="
sudo cp "$PANEL_DIR/.env.example" "$PANEL_DIR/.env"
sudo chown www-data:www-data "$PANEL_DIR/.env"
sudo chmod 640 "$PANEL_DIR/.env"

echo
echo "=== Prepare Composer home ==="
sudo install -d -m 0750 -o www-data -g www-data /var/www/.composer

echo
echo "=== Install dependencies as www-data ==="
cd "$PANEL_DIR"
sudo -u www-data env HOME=/var/www COMPOSER_HOME=/var/www/.composer \
  php8.3 /usr/local/bin/composer install \
  --no-dev --optimize-autoloader --no-interaction

echo
echo "=== Generate APP_KEY exactly once ==="
sudo -u www-data php8.3 artisan key:generate

echo
echo "=== Verify installation ==="
sudo -u www-data php8.3 artisan --version
sudo test -s "$PANEL_DIR/vendor/autoload.php"
sudo test -s "$PANEL_DIR/.env"
sudo stat -c 'owner=%U:%G mode=%a path=%n' "$PANEL_DIR/.env"

echo
echo "=== Panel files and dependencies installed ==="
)
~~~

**رفتار Composer و رفع خطا:**
- پیام Filter list / curl error 56 لزوماً شکست نصب نیست. اگر Composer تمام شد، وابستگی‌ها و vendor/autoload.php ایجاد شدند و کد خروجی موفق بود، ادامه بده.
- اگر Composer واقعاً با کد خطا خارج شد، کل بلوک 3.1 را دوباره اجرا نکن؛ ابتدا اینترنت/Packagist را بررسی کن و سپس فقط دستور composer install را مجدداً اجرا کن.
- وابستگی‌ها باید با کاربر www-data نصب شوند.
- دستور key:generate را پس از نصب اولیه دوباره اجرا نکن؛ تغییر APP_KEY می‌تواند داده‌های رمزنگاری‌شده را غیرقابل‌خواندن کند.

### 3.2 ساخت دیتابیس و کاربر MariaDB

این مرحله برای نصب تازه است. اگر دیتابیس یا حساب از قبل وجود دارد، ابتدا آن را بررسی کن.

~~~bash
sudo env MYSQL_HISTFILE=/dev/null mariadb
~~~

داخل prompt مربوط به MariaDB این SQL را اجرا کن. رمز نمونه را با رمز قوی، یکتا و محرمانهٔ خودت جایگزین کن. رمز واقعی را در چت یا README قرار نده.

~~~sql
CREATE DATABASE panel
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'pterodactyl'@'127.0.0.1'
  IDENTIFIED BY 'REPLACE_WITH_A_UNIQUE_PASSWORD';

GRANT ALL PRIVILEGES ON panel.*
  TO 'pterodactyl'@'127.0.0.1';

SHOW GRANTS FOR 'pterodactyl'@'127.0.0.1';
EXIT;
~~~

**پیش از Migration، اتصال مستقیم را آزمایش کن.** دستور از تو رمز را تعاملی می‌پرسد؛ هنگام تایپ چیزی نمایش داده نمی‌شود:

~~~bash
mariadb --protocol=TCP --host=127.0.0.1 --port=3306 \
  --user=pterodactyl --password panel \
  -e "SELECT DATABASE(), USER(), CURRENT_USER();"
~~~

انتظار می‌رود دیتابیس panel و حساب pterodactyl@127.0.0.1 استفاده شود.

#### اگر SQLSTATE[HY000] [1045] Access denied گرفتی

این خطا را فوراً به تفاوت localhost و 127.0.0.1 نسبت نده و دیتابیس/کاربر جدید نساز. ابتدا بدون نمایش رمز، مقادیر تنظیم‌شده را بررسی کن:

~~~bash
cd /var/www/pterodactyl
grep -E '^(DB_CONNECTION|DB_HOST|DB_PORT|DB_DATABASE|DB_USERNAME)=' .env
~~~

برای این نصب، DB_HOST برابر 127.0.0.1، DB_PORT برابر 3306، DB_DATABASE برابر panel و DB_USERNAME برابر pterodactyl است. اگر ورود مستقیم با همان رمز موفق نیست، حساب موجود را در MariaDB اصلاح کن:

~~~bash
sudo env MYSQL_HISTFILE=/dev/null mariadb
~~~

~~~sql
ALTER USER 'pterodactyl'@'127.0.0.1'
  IDENTIFIED BY 'THE_SAME_NEW_PASSWORD_YOU_WILL_ENTER_IN_PANEL';

SHOW GRANTS FOR 'pterodactyl'@'127.0.0.1';
EXIT;
~~~

سپس همان رمز را در Wizard دیتابیس Panel وارد و آزمون مستقیم را تکرار کن. رمز را در چت یا خط فرمان ذخیره نکن.

### 3.3 Wizardهای محیط برنامه و دیتابیس

این فرمان‌ها تعاملی‌اند. بعد از اجرا منتظر سؤال بعدی بمان و مقادیر را وارد کن:

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:environment:setup
~~~

مقادیر راهنما:
- Application Name: FragCity Panel
- URL: https://panel.fragcity.ir
- Timezone: Asia/Tehran
- Cache Driver / Session Driver / Queue Driver: redis، اگر Wizard این گزینه‌ها را می‌پرسد
- Redis host/port: 127.0.0.1 / 6379
- Redis password: خالی، چون Redis در این نصب روی loopback و بدون رمز است
- Public registration: فعلاً غیرفعال
- Email sender: آدرس متعلق به FragCity؛ SMTP واقعی بعداً جداگانه پیکربندی و آزمایش شود

سپس Wizard دیتابیس را اجرا کن:

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:environment:database
~~~

مقادیر:
- Host: 127.0.0.1
- Port: 3306
- Database: panel
- Username: pterodactyl
- Password: همان رمز تأییدشده در مرحلهٔ 3.2

**اگر ظاهراً دستور گیر کرد:**
- اگر prompt مانند Database Password: یا علامت > نمایش داده شده، Wizard منتظر ورودی است؛ رمز را وارد کن. هنگام تایپ رمز چیزی نمایش داده نمی‌شود.
- بعضی اجرای اولیهٔ artisan در این نصب حدود یک دقیقه طول کشید. فوراً کل نصب را تکرار نکن.
- اگر فرمان واقعاً تمام نشد، یک آزمون فقط‌خواندنی اجرا کن:

~~~bash
cd /var/www/pterodactyl
sudo -u www-data timeout --kill-after=2s 20s php8.3 artisan --version
echo "Exit code: $?"
~~~

اگر کد خروجی 124 بود، دستور طی 20 ثانیه تمام نشده است؛ علت شبکه‌ای یا bootstrap برنامه را بررسی کن. اگر artisan --version سریع است اما Wizard مشکل دارد، فقط همان Wizard را عیب‌یابی کن.

### 3.4 Permissionها، Migration/Seed و Admin

ابتدا مجوزهای runtime را تنظیم و قابل‌نوشتن‌بودن Cache را آزمایش کن:

~~~bash
(
set -eu
cd /var/www/pterodactyl

sudo chown -R www-data:www-data storage bootstrap/cache
sudo find storage bootstrap/cache -type d -exec chmod 750 {} +
sudo find storage bootstrap/cache -type f -exec chmod 640 {} +

sudo -u www-data sh -c \
  'touch storage/framework/cache/data/.fragcity-permission-test &&
   rm storage/framework/cache/data/.fragcity-permission-test &&
   echo "OK: www-data can write to Laravel cache"'
)
~~~

وقتی اتصال مستقیم دیتابیس سالم است، اجرا کن:

~~~bash
(
set -eu
cd /var/www/pterodactyl

echo "=== Migrate and seed initial data ==="
sudo -u www-data php8.3 artisan migrate --seed --force

echo
echo "=== Verify migration status ==="
sudo -u www-data php8.3 artisan migrate:status
)
~~~

معیار قبولی: فرمان بدون خطا تمام شود و Migrationها در وضعیت Ran باشند. NestSeeder و EggSeeder باید با وضعیت DONE تمام شوند.

Seed ممکن است Egg قدیمی Counter-Strike: Global Offensive را ایجاد کند. وجود آن به معنی نصب یا تأیید Egg کامل CS2/Kitsune نیست؛ Egg رسمی K4ryuu در Runbook دوم جداگانه وارد می‌شود.

سپس یک بار حساب Administrator را بساز:

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:user:make
~~~

گزینهٔ Administrator را برای حساب مدیریتی خودت فعال کن. اگر این حساب قبلاً ساخته شده، دوباره آن را نساز.

### 3.4.1 Queue Worker و Scheduler

Queue Worker کارهای صف را پردازش می‌کند؛ Scheduler وظایف زمان‌بندی‌شده را هر دقیقه اجرا می‌کند. پیش‌نیاز این نصب QUEUE_CONNECTION=redis و Redis فعال است.

ابتدا بررسی کن فایل سرویس از قبل وجود نداشته باشد و queue driver درست باشد:

~~~bash
cd /var/www/pterodactyl
grep '^QUEUE_CONNECTION=' .env
sudo redis-cli ping
sudo test ! -e /etc/systemd/system/pteroq.service && echo "No existing pteroq.service"
~~~

اگر pteroq.service از قبل وجود دارد، آن را کورکورانه بازنویسی نکن. برای نصب تازه:

~~~bash
sudo tee /etc/systemd/system/pteroq.service >/dev/null <<'UNIT'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service
StartLimitIntervalSec=180
StartLimitBurst=30

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/pterodactyl
Restart=always
ExecStart=/usr/bin/php8.3 /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT

sudo chmod 0644 /etc/systemd/system/pteroq.service
sudo systemd-analyze verify /etc/systemd/system/pteroq.service
sudo systemctl daemon-reload
sudo systemctl enable --now pteroq.service
~~~

Scheduler در این نصب در crontab مربوط به root ثبت شد. ابتدا نسخهٔ پشتیبان محلی از crontab بساز؛ اگر ورودی وجود دارد آن را تکرار نکن:

~~~bash
(
set -eu

BACKUP="/root/root-crontab-before-pterodactyl-scheduler-$(date +%Y%m%d-%H%M%S)"
sudo sh -c 'crontab -l > "$1" 2>/dev/null || true' sh "$BACKUP"
sudo chmod 0600 "$BACKUP"

SCHEDULER='* * * * * /usr/bin/php8.3 /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1'

if sudo crontab -l 2>/dev/null | grep -Fq '/var/www/pterodactyl/artisan schedule:run'; then
  echo "Scheduler entry already exists; no duplicate added."
else
  { sudo crontab -l 2>/dev/null || true; printf '%s\n' "$SCHEDULER"; } | sudo crontab -
fi

echo "Root crontab backup: $BACKUP"
sudo crontab -l | grep -F '/var/www/pterodactyl/artisan schedule:run'
)
~~~

معیار قبولی:

~~~bash
sudo systemctl is-enabled pteroq.service
sudo systemctl is-active pteroq.service
sudo systemctl is-active redis-server cron
sudo systemctl status pteroq.service --no-pager -l
~~~

اگر Queue Worker بالا نمی‌آید:

~~~bash
sudo journalctl -u pteroq.service -n 80 --no-pager
~~~

### 3.5 Virtual Host در NGINX برای Panel

این بلوک فایل NGINX را ایجاد می‌کند و سایت را فعال می‌کند. اگر فایل موجود بود، خودکار روی آن نمی‌نویسد.

~~~bash
(
set -Eeuo pipefail

CONFIG="/etc/nginx/sites-available/pterodactyl.conf"
ENABLED="/etc/nginx/sites-enabled/pterodactyl.conf"

if sudo test -e "$CONFIG" || sudo test -L "$CONFIG"; then
  echo "STOP: configuration already exists; inspect it instead of overwriting."
  exit 1
fi

sudo tee "$CONFIG" >/dev/null <<'NGINX'
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
        location ~ /\. {
            deny all;
        }
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

    location ~ /\.ht {
        deny all;
    }
}
NGINX

sudo ln -s "$CONFIG" "$ENABLED"

echo "=== Validate configuration ==="
sudo /usr/sbin/nginx -t

echo
echo "=== Disable Debian default site symlink if present ==="
if sudo test -L /etc/nginx/sites-enabled/default; then
  sudo rm /etc/nginx/sites-enabled/default
fi

sudo /usr/sbin/nginx -t
sudo systemctl reload nginx
sudo systemctl is-active nginx

echo
echo "=== Test Panel virtual host locally ==="
curl -sS --connect-timeout 5 --max-time 20 -o /dev/null \
  -w 'HTTP status: %{http_code}\n' \
  -H 'Host: panel.fragcity.ir' http://127.0.0.1/
)
~~~

معیار قبولی اولیه: NGINX syntax موفق باشد و درخواست محلی با Host=panel.fragcity.ir پاسخ HTTP 200 بدهد. اگر خطا بود، دوباره کل بلوک را اجرا نکن؛ فایل و symlink موجود را بررسی کن.

### 3.6 صدور TLS برای Panel

پیش‌نیازها: DNS عمومی panel.fragcity.ir به IP عمومی صحیح اشاره کند، TCP/80 ورودی به Debian برسد و صفحهٔ مدیریت مودم از WAN منتشر نباشد. قوانین UFW اینجا تغییر نمی‌کنند.

~~~bash
sudo apt install -y certbot python3-certbot-nginx
sudo /usr/sbin/nginx -t
sudo certbot --nginx --redirect -d panel.fragcity.ir
~~~

ایمیل مدیریتی را در prompt وارد کن؛ آن را در README یا چت ذخیره نکن.

پس از صدور موفق گواهی، APP_URL را نهایی کن و Cache مربوط به Laravel را بازسازی کن:

~~~bash
(
set -eu
cd /var/www/pterodactyl

sudo sed -i 's#^APP_URL=.*#APP_URL=https://panel.fragcity.ir#' .env
sudo -u www-data php8.3 artisan config:clear
sudo -u www-data php8.3 artisan cache:clear
sudo -u www-data php8.3 artisan view:clear
sudo -u www-data php8.3 artisan config:cache

sudo /usr/sbin/nginx -t
sudo systemctl reload nginx

curl -sS --connect-timeout 5 --max-time 20 -o /dev/null \
  -w 'HTTPS status: %{http_code}\n' https://panel.fragcity.ir/

sudo certbot certificates
sudo certbot renew --dry-run
)
~~~

معیار قبولی این نصب: APP_URL برابر https://panel.fragcity.ir، پاسخ HTTPS برابر 200 و آزمون certbot renew --dry-run موفق باشد.

## 4. بررسی نهایی Panel و صدور TLS برای Node

### 4.1 بررسی سلامت Panel (فقط‌خواندنی)

~~~bash
(
set -eu
cd /var/www/pterodactyl

echo "=== Versions ==="
php8.3 -v | head -n 2
sudo -u www-data php8.3 artisan --version

echo
echo "=== Package and config checks ==="
sudo apt-get check
sudo /usr/sbin/php-fpm8.3 -t
sudo /usr/sbin/nginx -t

echo
echo "=== Services ==="
for service in nginx php8.3-fpm mariadb redis-server pteroq cron; do
  printf '%s: ' "$service"
  sudo systemctl is-active "$service"
done

echo
echo "=== Panel route ==="
curl -sS -o /dev/null -w 'Panel HTTPS: %{http_code}\n' https://panel.fragcity.ir/
)
~~~

Panel باید HTTPS status 200 بدهد. اگر پاسخ 500/502 است، قبل از ساخت Node لاگ‌های Laravel/NGINX را بررسی کن.

### 4.2 تأیید DNS و مسیر ورودی Node

دامنهٔ Node در این نصب server1.fragcity.ir است. نام Panel و Node می‌توانند به یک IP عمومی اشاره کنند، اما هرکدام گواهی مربوط به خودشان را می‌گیرند.

در Windows PowerShell بررسی کن:

~~~powershell
Resolve-DnsName panel.fragcity.ir -Type A -Server 1.1.1.1 -DnsOnly |
    Format-Table Name, Type, IPAddress

Resolve-DnsName server1.fragcity.ir -Type A -Server 1.1.1.1 -DnsOnly |
    Format-Table Name, Type, IPAddress
~~~

هر دو رکورد باید به IPv4 عمومی فعلی اشاره کنند. در Debian IPهای واقعی را دوباره بررسی کن:

~~~bash
echo "=== Public IPv4 seen by HTTPS service ==="
curl -4fsS --max-time 10 https://api.ipify.org
printf '\n'

echo
echo "=== LAN address and route ==="
ip -4 -brief address
ip -4 route
~~~

در اجرای مرجع، IP عمومی 85.185.40.85 و IP داخلی 192.168.1.13 بودند؛ در نصب تازه این مقادیر را دوباره اندازه بگیر.

### 4.3 ساخت ACME Webroot برای Node

این Virtual Host فقط challenge را سرو می‌کند و در مسیر عادی / پاسخ 404 می‌دهد. اگر فایل یا symlink از قبل وجود دارد، آن را بازنویسی نکن.

~~~bash
(
set -Eeuo pipefail

CONFIG="/etc/nginx/sites-available/server1-acme.conf"
ENABLED="/etc/nginx/sites-enabled/server1-acme.conf"
WEBROOT="/var/www/letsencrypt"

if sudo test -e "$CONFIG" || sudo test -L "$CONFIG" ||
   sudo test -e "$ENABLED" || sudo test -L "$ENABLED"; then
  echo "STOP: Node ACME config or link already exists. Inspect it first."
  exit 1
fi

sudo install -d -o root -g root -m 0755 \
  "$WEBROOT/.well-known/acme-challenge"

sudo tee "$CONFIG" >/dev/null <<'NGINX'
server {
    listen 80;
    listen [::]:80;
    server_name server1.fragcity.ir;

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
        default_type text/plain;
        try_files $uri =404;
    }

    location / {
        return 404;
    }
}
NGINX

sudo chmod 0644 "$CONFIG"
sudo ln -s "$CONFIG" "$ENABLED"
sudo /usr/sbin/nginx -t
sudo systemctl reload nginx
sudo systemctl is-active nginx
)
~~~

### 4.4 آزمایش مسیر ACME پیش از صدور گواهی

این آزمون جلوی خطای 404 را می‌گیرد که در اجرای مرجع رخ داد. تا وقتی متن آزمایشی با HTTP 200 برنگشته، گواهی را درخواست نکن.

~~~bash
(
set -eu

WEBROOT="/var/www/letsencrypt"
PROBE="$WEBROOT/.well-known/acme-challenge/fragcity-test"
BODY="/tmp/fragcity-acme-test-response"

cleanup() {
  sudo rm -f "$PROBE" "$BODY"
}
trap cleanup EXIT

printf '%s\n' 'fragcity-acme-path-ok' |
  sudo tee "$PROBE" >/dev/null

HTTP_CODE="$(curl -sS --connect-timeout 5 --max-time 10 \
  --resolve server1.fragcity.ir:80:127.0.0.1 \
  -o "$BODY" -w '%{http_code}' \
  http://server1.fragcity.ir/.well-known/acme-challenge/fragcity-test)"

echo "HTTP status: $HTTP_CODE"
cat "$BODY"

if [ "$HTTP_CODE" != "200" ] || ! grep -qx 'fragcity-acme-path-ok' "$BODY"; then
  echo "STOP: Local ACME test failed. Do not request a certificate."
  exit 1
fi

echo "OK: ACME webroot path works locally."
)
~~~

اگر 404 دریافت شد:
1. فایل کانفیگ و symlink را با sed و ls بررسی کن.
2. با sudo /usr/sbin/nginx -T مطمئن شو server_name مربوط به Node در تنظیم فعال وجود دارد.
3. مسیر فایل آزمایشی باید /var/www/letsencrypt/.well-known/acme-challenge/fragcity-test باشد.
4. اگر آزمون هنوز شکست خورد، خروجی و 20 خط آخر /var/log/nginx/error.log را بررسی کن؛ بقیهٔ تنظیمات را کورکورانه تغییر نده.

### 4.5 صدور گواهی Node با Webroot

بعد از قبولی تست محلی و بررسی DNS عمومی و Port Forward:

~~~bash
sudo certbot certonly \
  --webroot \
  --webroot-path /var/www/letsencrypt \
  -d server1.fragcity.ir
~~~

گواهی و کلید خصوصی این نصب در این مسیرها ثبت شدند:
- /etc/letsencrypt/live/server1.fragcity.ir/fullchain.pem
- /etc/letsencrypt/live/server1.fragcity.ir/privkey.pem

بررسی:

~~~bash
(
set -eu

sudo certbot certificates
sudo test -s /etc/letsencrypt/live/server1.fragcity.ir/fullchain.pem
sudo test -s /etc/letsencrypt/live/server1.fragcity.ir/privkey.pem
sudo openssl x509 -in /etc/letsencrypt/live/server1.fragcity.ir/fullchain.pem \
  -noout -checkhost server1.fragcity.ir
sudo openssl x509 -in /etc/letsencrypt/live/server1.fragcity.ir/fullchain.pem \
  -noout -checkend 0
sudo certbot renew --dry-run
)
~~~

این گواهی برای Wings است؛ گواهی Panel جای آن را نمی‌گیرد. چون Node از Webroot استفاده می‌کند، Virtual Host مربوط به ACME را نگه دار تا تمدید خودکار از همان مسیر انجام شود.

## 5. نصب Docker Engine

این بلوک برای نصب تازهٔ Debian 13 amd64 است. در ابتدای اجرا وجود Docker و بسته‌های هم‌نام/متعارض بررسی می‌شود. اگر Docker از قبل نصب باشد، بلوک متوقف می‌شود تا نصب قبلی بررسی شود. این مرحله هیچ قانون UFW یا Port Forward روتر را تغییر نمی‌دهد.

~~~bash
(
set -Eeuo pipefail

echo "=== 1. Check architecture ==="
. /etc/os-release
if [ "$ID" != "debian" ] || [ "$VERSION_CODENAME" != "trixie" ]; then
  echo "STOP: this block expects Debian 13 Trixie."
  exit 1
fi

if [ "$(dpkg --print-architecture)" != "amd64" ]; then
  echo "STOP: this block was validated for amd64."
  exit 1
fi

echo
echo "=== 2. Check for existing/conflicting packages ==="
for package in docker-ce docker-ce-cli containerd.io docker.io docker-compose docker-doc docker-buildx docker-buildx-plugin docker-compose-plugin podman-docker containerd runc; do
  if dpkg -s "$package" >/dev/null 2>&1; then
    echo "STOP: package already installed: $package"
    dpkg-query -W "$package" || true
    exit 1
  fi
done

if command -v docker >/dev/null 2>&1; then
  echo "STOP: a docker executable already exists."
  command -v docker
  exit 1
fi

if sudo test -e /etc/apt/sources.list.d/docker.sources ||
   sudo test -e /etc/apt/keyrings/docker.asc; then
  echo "STOP: Docker repository configuration already exists; inspect it first."
  exit 1
fi

echo
echo "=== 3. Install repository prerequisites ==="
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings

echo
echo "=== 4. Add official Docker signing key ==="
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo
echo "=== 5. Configure official repository ==="
CODENAME="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"
ARCH="$(dpkg --print-architecture)"

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<SOURCE
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $CODENAME
Components: stable
Architectures: $ARCH
Signed-By: /etc/apt/keyrings/docker.asc
SOURCE

echo
echo "=== 6. Install Docker Engine and plugins ==="
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

echo
echo "=== 7. Enable and start Docker ==="
sudo systemctl enable --now docker

echo
echo "=== 8. Verify Docker ==="
sudo docker --version
sudo systemctl is-enabled docker
sudo systemctl is-active docker
sudo docker info --format 'Server={{.ServerVersion}} Containers={{.Containers}} Images={{.Images}}'

echo
echo "=== 9. Test container execution ==="
sudo docker run --rm hello-world

echo
echo "=== Docker setup finished ==="
)
~~~

معیار قبولی: Docker enabled و active باشد، docker info موفق شود و کانتینر hello-world پیام موفقیت نشان دهد.

در اجرای مرجع Docker نسخهٔ 29.9.2 نصب شد. نسخه‌ها برای نصب آینده ثابت نیستند؛ بسته‌ها را از مخزن رسمی دریافت کن.

**نکتهٔ Firewall:** Docker می‌تواند برای پورت‌های Container قواعد شبکهٔ خودش را بسازد و بعضی انتشار پورت‌ها را از کنترل معمول UFW عبور دهد. بعداً در سیاست MikroTik فقط سرویس‌های عمدی را از WAN در دسترس قرار بده. فعلاً سرور بازی نساز و هیچ پورت Game را منتشر نکن. مرجع: https://docs.docker.com/engine/install/debian/#firewall-limitations

## 6. نصب و پیکربندی Wings و اتصال Node

### 6.1 پیش‌بررسی منابع

قبل از ساخت Node و دانلود CS2، ظرفیت فعلی را اندازه بگیر:

~~~bash
echo "=== Hostname and architecture ==="
hostnamectl --static
hostname -f
uname -m
dpkg --print-architecture

echo
echo "=== RAM and swap ==="
free -h
swapon --show

echo
echo "=== Root filesystem ==="
df -hT /
df -ih /
~~~

در نصب مرجع، RAM حدود 3.8 GiB و فضای آزاد root حدود 130 GB بود. این ظرفیت برای Base بازی و مجموعهٔ بزرگ Workshop محدود است؛ قبل از دانلود، ظرفیت هدف را دوباره بررسی کن.

### 6.2 نصب باینری Wings

Baseline این نصب v1.13.4 است. قبل از نصب تازه در زمان دیگری، Release رسمی را بررسی کن:
https://github.com/pterodactyl/wings/releases

برای Release v1.13.4 فایل amd64 رسمی دارای SHA-256 زیر بود:
7e763389bb5d386a7d32ccdd46cffcf1ab9ed697e5c2aca7fe44183b527cd4c0

~~~bash
(
set -Eeuo pipefail

VERSION="v1.13.4"
URL="https://github.com/pterodactyl/wings/releases/download/$VERSION/wings_linux_amd64"
TEMP_FILE="/tmp/wings_linux_amd64"
BIN_PATH="/usr/local/bin/wings"
EXPECTED_SHA256="7e763389bb5d386a7d32ccdd46cffcf1ab9ed697e5c2aca7fe44183b527cd4c0"

test "$(dpkg --print-architecture)" = "amd64" || {
  echo "STOP: this binary is for amd64."
  exit 1
}

if sudo test -e "$BIN_PATH"; then
  echo "STOP: $BIN_PATH already exists; inspect before replacing."
  sudo stat "$BIN_PATH"
  exit 1
fi

curl -fL --retry 3 --connect-timeout 10 "$URL" -o "$TEMP_FILE"
ACTUAL_SHA256="$(sha256sum "$TEMP_FILE" | awk '{print $1}')"

if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
  echo "ERROR: checksum mismatch; refusing to install."
  rm -f "$TEMP_FILE"
  exit 1
fi

file "$TEMP_FILE"
sudo install -o root -g root -m 0755 "$TEMP_FILE" "$BIN_PATH"
rm -f "$TEMP_FILE"
sudo install -d -o root -g root -m 0755 /etc/pterodactyl

"$BIN_PATH" --help
"$BIN_PATH" version
sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' "$BIN_PATH"
)
~~~

معیار قبولی: checksum مطابق، باینری در /usr/local/bin/wings و فرمان‌های wings --help و wings version موفق باشند.

### 6.3 ساخت Location و Node در Panel

این مرحله در مرورگر و با حساب Administrator در https://panel.fragcity.ir انجام می‌شود.

1. از Admin → Locations یک Location بساز یا Location موردنظر را انتخاب کن.
2. از Admin → Nodes → Create New یک Node بساز.
3. برای محیط مرجع:

| فیلد | مقدار/قاعده |
|---|---|
| Name | server1 |
| FQDN | server1.fragcity.ir |
| Communicate Over SSL | فعال؛ گواهی معتبر برای همین FQDN صادر شده |
| Behind Proxy | خاموش، مگر اینکه Reverse Proxy واقعی برای Wings داشته باشی |
| Daemon Port | 8080 |
| Daemon SFTP Port | 2022 |
| Server File Directory | /var/lib/pterodactyl/volumes |
| Memory / Disk | بر مبنای free -h و df -hT /، با فضای رزرو برای OS و سرویس‌ها |
| Over-allocation | برای شروع 0 |

Node Memory و Disk Limit به‌صورت فیزیکی RAM یا دیسک را رزرو نمی‌کنند؛ مجموع تخصیص سرورها باید با ظرفیت واقعی سازگار بماند. برای این ماشین حدود 4 GiB RAM، حدود 3 GiB نقطهٔ شروع محافظه‌کارانه‌تری برای Memory قابل‌تخصیص است؛ اجرای هم‌زمان CS2 و Workshop ممکن است به RAM و دیسک جداگانه نیاز داشته باشد.

**در این مرحله Allocation بازی نساز و Server CS2 را Start نکن.** نصب Egg کامل و Shared Base در Runbook دوم انجام می‌شود.

### 6.4 تولید فایل محرمانهٔ config از Auto-Deploy

فایل /etc/pterodactyl/config.yml بعد از نصب باینری به‌تنهایی ساخته نمی‌شود. Node را در Panel ذخیره کن و فرمان Auto-Deploy خود Panel را دریافت کن.

1. در Panel به Admin → Nodes → server1 → Configuration برو.
2. در قسمت Auto-Deploy روی Generate Token بزن و فرمان کامل تولیدشده را کپی کن.
3. همان فرمان را در ترمینال خود Debian اجرا کن. آن را در Windows PowerShell اجرا نکن و Token یا Node ID را خودت حدس نزن.
4. فرمان و Token را در چت، ویدئو یا GitHub قرار نده.

سپس وجود فایل را بررسی کن:

~~~bash
(
set -eu
CONFIG="/etc/pterodactyl/config.yml"

if sudo test -s "$CONFIG"; then
  echo "OK: Wings config exists."
  sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' "$CONFIG"
else
  echo "ERROR: config.yml was not created. Do not create an empty file."
  exit 1
fi
)
~~~

انتظار می‌رود مالک فایل root:root و permission آن 600 باشد. محتویات YAML این فایل محرمانه است؛ آن را نمایش نده یا وارد Git نکن.

### 6.5 آزمون Wings در foreground

پس از تولید config، اجرا کن:

~~~bash
sudo /usr/local/bin/wings --debug
~~~

در لاگ سالم انتظار داریم Wings پیکربندی را از /etc/pterodactyl/config.yml بخواند، به API پنل وصل شود و Web Server را روی 0.0.0.0:8080 و SFTP را روی 0.0.0.0:2022 تنظیم کند. total_configs=0 طبیعی است تا وقتی روی Node هیچ Serverای نساخته‌ای.

اگر خطای Configuration File Not Found دیدی، Wings را دوباره نصب نکن؛ به بخش 6.4 برگرد و فایل config را بررسی کن. اگر اتصال API/TLS شکست خورد، لاگ را بخوان و رازها را پیش از ارسال خروجی حذف کن.

برای خروج کنترل‌شده از debug پس از بررسی، Ctrl+C بزن.

### 6.6 ساخت سرویس دائمی Wings

ابتدا مطمئن شو اجرای foreground متوقف شده و فایل سرویس از قبل موجود نیست:

~~~bash
sudo test ! -e /etc/systemd/system/wings.service && echo "No existing wings.service"
~~~

برای نصب تازه:

~~~bash
sudo tee /etc/systemd/system/wings.service >/dev/null <<'UNIT'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
StartLimitIntervalSec=180
StartLimitBurst=30

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT

sudo chmod 0644 /etc/systemd/system/wings.service
sudo systemd-analyze verify /etc/systemd/system/wings.service
sudo systemctl daemon-reload
sudo systemctl enable --now wings
~~~

### 6.7 بررسی سرویس، TLS و وضعیت Node

~~~bash
(
set -eu

echo "=== Wings service ==="
sudo systemctl is-enabled wings
sudo systemctl is-active wings
sudo systemctl status wings --no-pager -l

echo
echo "=== Wings listeners ==="
sudo ss -ltnp | grep -E ':(8080|2022)\b'

echo
echo "=== Local TLS test ==="
curl -sS --connect-timeout 5 --max-time 10 \
  --resolve server1.fragcity.ir:8080:127.0.0.1 \
  -o /dev/null -w 'HTTPS status: %{http_code}\n' \
  https://server1.fragcity.ir:8080/
)
~~~

در اجرای مرجع، پاسخ محلی HTTPS روی پورت 8080 برابر 401 بود. این پاسخ برای درخواست ناشناس قابل‌قبول است و نشان می‌دهد TLS و endpoint پاسخ داده‌اند؛ به‌تنهایی اثبات نمی‌کند Port Forward خارجی صحیح است.

در Panel وضعیت Admin → Nodes → server1 را بررسی کن. برای آزمون خارجی می‌توان از یک شبکهٔ بیرونی درخواست زیر را زد:

~~~text
https://server1.fragcity.ir:8080/
~~~

Timeout یا خطای TLS نیازمند بررسی DNS، گواهی، Router/NAT و سرویس است. این Runbook عمداً دستورهای ufw allow، ufw reset یا تغییر خودکار Firewall ندارد. قواعد فعلی UFW را دست‌کاری نکن؛ Port Forward و سیاست WAN را طبق طرح MikroTik بررسی کن.

### 6.8 یادداشت مهم دربارهٔ MikroTik و دسترسی WAN

این نصب از کنسول محلی Debian مدیریت می‌شود و آموزش SSH key یا تغییر sshd_config ندارد؛ طبق تصمیم FragCity این مراحل در این Runbook لازم نیستند.

در سیاست نهایی MikroTik:
- دسترسی SSH و مدیریت روتر از WAN را نده.
- MariaDB روی 3306 و Redis روی 6379 را از WAN منتشر نکن.
- اگر Panel و بازی‌ها باید از اینترنت کار کنند، به‌جای Drop کردن تمام ورودی‌ها، فقط مسیرها و پورت‌های عمدی را مجاز کن: Panel HTTPS، Wings/SFTP و Allocationهای واقعی بازی.
- برای صدور و تمدید خودکار گواهی‌های HTTP-01، TCP/80 باید به challenge webroot دسترسی داشته باشد. اگر آن را می‌بندی، روش ACME/renewal را قبل از بستن تغییر بده.
- پورت SSH را به‌عنوان روش مدیریت عمومی Port Forward نکن.

این سند هیچ تغییر Firewall اجرا نمی‌کند؛ تغییر نهایی باید مرحلهٔ جداگانه‌ای با بررسی دسترسی LAN/WAN و روش بازگشت باشد.

## 7. پایان این Runbook و انتقال به راهنمای CS2

این سند تا آماده‌شدن Debian، Panel، TLS، Docker و Wings ادامه دارد. ساخت Egg کامل Kitsune، نصب cs2node، دانلود Shared Base و Workshop، VPK Sync و اثبات Multi Instance در راهنمای اختصاصی زیر انجام می‌شود:

**[راهنمای نصب K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop Cache](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md)**

قبل از شروع Runbook دوم این معیارها را تأیید کن:

~~~bash
(
set -eu

echo "=== Debian identity ==="
hostname -f
timedatectl show -p Timezone -p NTPSynchronized -p NTP
uname -m
dpkg --print-architecture

echo
echo "=== Capacity ==="
free -h
df -hT /
df -ih /

echo
echo "=== Core services ==="
for service in nginx php8.3-fpm mariadb redis-server cron pteroq docker wings; do
  printf '%s: ' "$service"
  sudo systemctl is-active "$service"
done

echo
echo "=== Panel HTTPS ==="
curl -sS --connect-timeout 5 --max-time 20 -o /dev/null \
  -w 'HTTP status: %{http_code}\n' https://panel.fragcity.ir/

echo
echo "=== Node local TLS ==="
curl -sS --connect-timeout 5 --max-time 10 \
  --resolve server1.fragcity.ir:8080:127.0.0.1 \
  -o /dev/null -w 'HTTPS status: %{http_code}\n' \
  https://server1.fragcity.ir:8080/
)
~~~

در نصب مرجع، Panel باید HTTP 200 بدهد و Wings در تست محلی می‌تواند 401 بدهد. Timezone باید Asia/Tehran حفظ شده باشد. اگر سرویس inactive بود یا DNS/TLS خطا داد، قبل از دانلود CS2 علت را مشخص کن.

## 8. Backup نهایی VMDK پس از تکمیل CS2

**این مرحله را بعد از تکمیل و قبولی Runbook دوم انجام بده، نه همین حالا.** هدف ساخت نسخهٔ مستقل و قابل‌بازیابی از VM آمادهٔ FragCity است.

1. پس از قبولی آزمون Multi Instance، Instanceهای CS2 را از Panel به شکل کنترل‌شده Stop کن.
2. Debian را به‌شکل امن خاموش کن. در VMware مطمئن شو وضعیت VM برابر Powered Off است.
3. در VMware Snapshot Manager زنجیرهٔ Snapshot را بررسی کن. اگر Snapshot وجود دارد، پیش از کپی برای Consolidate/Delete از خود VMware تصمیم بگیر؛ فایل‌های Snapshot descriptor را دستی از File Manager پاک نکن.
4. از کل پوشهٔ VM نسخهٔ پشتیبان بگیر، نه فقط یکی از descriptorهای کوچک VMDK. فایل VMX و تمام VMDK/extent/snapshotهای وابسته باید با هم نگه داشته شوند. Export به OVA یا کپی کامل پوشه در حالت خاموش می‌تواند خروجی مستقل باشد.
5. مقصد Backup باید فضای کافی برای دیسک مجازی و دادهٔ CS2/Workshop داشته باشد. پس از کپی، اندازه‌ها و در صورت امکان SHA-256 فایل‌های Backup را بررسی کن.
6. یکبار از روی Backup در شبکهٔ ایزوله/بدون IP تکراری بوت آزمایشی انجام بده. Clone و VM اصلی را هم‌زمان با hostname، IP، TLS و identity یکسان روی شبکهٔ تولیدی روشن نکن.

**Backup مستقل با VMware Snapshot متفاوت است.** زنجیرهٔ Snapshot شکسته می‌تواند VM را غیرقابل‌بوت کند؛ نسخهٔ پشتیبان باید کامل، خاموش و جداگانه قابل‌آزمایش باشد.

## 9. محرمانگی و قواعد نهایی Runbook

- هرگز فایل .env، APP_KEY، گذرواژهٔ MariaDB، Token مربوط به Auto-Deploy، محتوای /etc/pterodactyl/config.yml، GSLT یا URL محرمانهٔ Webhook را در GitHub، چت یا ویدئوی عمومی نگذار.
- این Runbook قوانین UFW و سیاست MikroTik را تغییر نمی‌دهد؛ حفظ و بازبینی آن‌ها باید آگاهانه باشد.
- اگر بلوکی با STOP یا خطا متوقف شد، کل بلوک نصب را بی‌دلیل از ابتدا اجرا نکن. ابتدا وضعیت موجود را فقط‌خواندنی بررسی کن.
- لاگ‌های یک نصب خاص را در سند عمومی قرار نده؛ سند باید مراحل عمومی، پیش‌نیازها، معیارهای قبولی و مسیر رفع خطا را ثبت کند.
