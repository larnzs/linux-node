# FragCity — راهنمای مادرِ Copy/Paste از Debian تا سرورهای CS2

> **این فایل مرجع اجرایی واحد پروژه است.** از اینجا به بعد توضیحات، ترتیب اجرا، تصمیم‌های فنی و بلوک‌های Copy/Paste در همین README نوشته می‌شوند. خروجی ترمینال، لاگ واقعی، رمزها و نتیجهٔ اجرای فرمان‌ها در README ثبت نمی‌شوند؛ لاگ لازم برای عیب‌یابی را فقط در گفت‌وگو بفرست. بعد از هر مرحله فقط مرحلهٔ جاری را اجرا کن و برای ادامه، به‌روزرسانی README را بخوان.
>
> **وضعیت فعلی:** پنل Pterodactyl، Docker و Wings راه‌اندازی شده‌اند؛ شبکه و پنل طبق تأیید کاربر عملیاتی‌اند. هنوز CS2 Instance ساخته نشده است. کاربر انتخاب کرده که ابتدا طبق راهنمای K4ryuu یک سرور پایه با Egg رسمی CS2-Egg-Go روی Clone آزمایش شود؛ فصل جدید [server-creation instruction.md](https://github.com/larnzs/linux-node/blob/main/server-creation%20instruction.md) مسیر Import Egg و ساخت این Instance را ثبت می‌کند. این تست standalone فایل‌های بازی را در Volume معمول Pterodactyl دانلود می‌کند و به حدود 40 GB فضای آزاد نیاز دارد. پس از موفقیت تست پایه، VMDK داده فقط به Clone افزوده و شناسایی می‌شود؛ نصب cs2node/VPK sync و Shared Base تا آماده‌شدن Storage مستقل انجام نمی‌شود. VM اصلی با IP 192.168.1.7 تا پایان تست خاموش می‌ماند؛ Clone با IP 192.168.1.9 فعال است. v2.0.0-beta.2 هنوز Open Beta است و برای پنل اصلی انتخاب نشده.
>
> **قانون secrets:** رمز MariaDB، رمز حساب، APP_KEY، token، فایل .env و محتوای /etc/pterodactyl/config.yml را در GitHub یا چت قرار نده. مقادیر نمونه را فقط به‌صورت محلی جایگزین کن.

---

## 0. وضعیت، محدوده و خط قرمزها

- هدف این است که **همین VM با نام `fc-node-01`** را از ابتدا با Debian 13 بدون محیط گرافیکی آماده کنیم.
- در نصاب وارد شده: **Hostname** = `fc-node-01` و **Domain name** = `fragcity.ir`. نام کامل موردنظر برای Node برابر `fc-node-01.fragcity.ir` است.
- آدرس پنل: `panel.fragcity.ir` و FQDN مربوط به Node: `fc-node-01.fragcity.ir`. هر دو رکورد A باید به IPv4 عمومی فعلی اشاره کنند؛ روش بررسی قابل‌تکرار در مرحلهٔ 3.7.2 آمده است. پس از تغییر IP عمومی، DNS و Port Forward را دوباره بررسی کن.
- پرکردن فیلد Domain name در نصاب به‌تنهایی DNS، IP عمومی، Port Forwarding یا HTTPS را فعال نمی‌کند.
- هنگام نصب Debian 13، در صفحهٔ Software selection گزینهٔ `Debian desktop environment` را بردار و `SSH server` و `standard system utilities` را نگه دار. مدیریت با SSH از Windows و مرورگر Windows انجام می‌شود؛ محیط گرافیکی Debian لازم نیست. راهنما: https://wiki.debian.org/DesktopEnvironment
- VM فعلی روی VMware و Debian 13/Trixie است. IP، منابع و دیسک را بعد از شروع مجدد با بلوک بررسی مرحلهٔ 0 مشخص کن؛ از اعداد قدیمی برای نصب مجدد استفاده نکن.
- Panel `v1.15.1` روی `https://panel.fragcity.ir` نصب شده است؛ مسیرهای `/var/www/pterodactyl` و تنظیمات آن در مراحل بعدیِ این راهنما استفاده می‌شوند.
- فایل‌های CS2/KUS متعلق به VMDK سیستم قبلی هستند که کاربر آن را نگه داشته است. **در نصب تازه آن دیسک را overwrite یا بدون طرح مشخص mount نکن.** این مسیر بازی در Debian تازه فرض نمی‌شود؛ نصب/آزمایش CS2 در فاز جداگانه و روی محیط آزمایشگاهی انجام خواهد شد.
- تا بررسی مدل Storage/Egg، هیچ سرور بازی تازه‌ای از Egg نساز؛ ممکن است بازی را دوباره دانلود و فضای دیسک را پر کند.
- برای صدور و تمدید گواهی‌های Let's Encrypt با روش HTTP-01، TCP 80 باید از اینترنت به IP LAN رزروشدهٔ همین VM برسد. پورت‌های عمومی را فقط طبق مراحل مربوطه و با حداقل دسترسی لازم منتشر کن؛ قاعدهٔ UFW به‌تنهایی جای Port Forward روتر را نمی‌گیرد. SSH، MariaDB و Redis را در اینترنت عمومی نکن.

### 0.1 حفاظت از دیسک قبلی

فایل‌های VMDK مربوط به Debian Desktop قبلی نزد کاربر موجود هستند. **آن VMDK پشتیبان را در طول نصب جاری به‌عنوان دیسک مقصد انتخاب نکن و آن را overwrite نکن.** نصب روی دیسک مقصد، تمام داده‌های همان دیسک را پاک خواهد کرد.

### 0.2 قرارداد اجرای مرحله‌ای

- فقط **بلوک مرحلهٔ جاری** را اجرا کن؛ به مراحل بعدی نپر.
- محل اجرا را از برچسب زبان و توضیح قبل از بلوک بررسی کن:
  - `powershell`: پنجرهٔ Windows PowerShell با prompt شبیه `PS C:\\...`؛
  - `bash`: نشست SSH دبیان با prompt شبیه `sv1@fc-node-01:~$`؛
  - `sql`: فقط داخل prompt مربوط به MariaDB/MySQL، بعد از بازکردن کلاینت دیتابیس؛
  - `nginx`, `yaml`, `json` و مشابه آن: **محتوای فایل** هستند، نه فرمان Bash. آن‌ها را در فایل مربوطه paste کن، نه در ترمینال.
- برای ویرایش فایل، ابتدا فقط فرمان بازکردن ویرایشگر را در Bash اجرا کن؛ مثلاً `sudo nano /etc/nginx/sites-available/pterodactyl.conf`. سپس در خود Nano محتوای فایل را paste کن. برای ذخیره در Nano از `Ctrl+O`، سپس `Enter` و برای خروج از `Ctrl+X` استفاده کن.
- کد NGINX که با `server {` شروع می‌شود را **هرگز مستقیم در Bash اجرا نکن**. دیدن خطاهایی مانند `server: command not found` پس از این اشتباه، به‌تنهایی ثابت نمی‌کند که NGINX خراب شده است یا فایل پیکربندی ذخیره شده است.
- بلوک Bash را کامل و یک‌جا اجرا کن؛ اگر بلوک با `(...)` احاطه شده، پرانتزها را حذف نکن. این کار کمک می‌کند خطای داخل آن بلوک، نشست تعاملی اصلی SSH را نبندد.
- اگر SSH ناگهان قطع شد، از یک پنجرهٔ تازهٔ PowerShell طبق بخش «اتصال روزمره از Windows PowerShell به Debian» دوباره وصل شو. نصب یا مهاجرت را از ابتدا تکرار نکن، سرویس را کورکورانه restart نکن و تا اجرای آزمون‌های فقط‌خواندنی، فایل یا symlink را حذف/فعال نکن.
- خروجی لازم را برای عیب‌یابی در گفت‌وگو بفرست، اما رمزها، APP_KEY، token و محتوای `.env` یا `config.yml` را ارسال نکن.

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
# Confirm that df -ih / prints the inode summary before continuing.
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

نکتهٔ URL: `https://<PUBLIC_IP>:80/` یعنی اتصال HTTPS روی پورت 80؛ این ترکیب غیرمعمول است. HTTP معمولاً با `http://<PUBLIC_IP>/` و HTTPS با `https://<PUBLIC_IP>/` استفاده می‌شود. تا وقتی رابط مدیریت مودم بررسی نشده، از صفحهٔ IP عمومی وارد حساب نشو.

#### قدم A — ورود محلی به مودم/روتر

1. از روی Debian، در `ip route`، Gateway فعلی شبکه را ببین؛ در وضعیت فعلی راهنما مقدار آن `192.168.1.1` است، اما اگر عوض شده از مقدار واقعی استفاده کن.
2. از مرورگر داخل همان LAN، صفحهٔ مدیریت محلی Gateway را باز کن، مثلاً `http://192.168.1.1/`. فقط از آدرس محلی استفاده کن.
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

### 1.21 ممیزی نهایی Base Debian و آزمون ماندگاری پس از reboot

این هنوز بخشی از Chapter 1 است؛ در این گام سرویس‌های Panel نصب نمی‌شوند. هدف این است که سیستم‌عامل، APT، SSH، Firewall، زمان، شبکه و فضای دیسک را پس از راه‌اندازی مجدد دوباره تأیید کنیم. قبل از اجرای بلوک، مطمئن شو کار در نشست SSH با حساب عادیِ عضو گروه `sudo` انجام می‌شود.

**الف) اعمال آخرین به‌روزرسانی‌های Debian و بررسی سلامت APT:**

~~~bash
set -eu

sudo apt update
sudo apt full-upgrade -y
sudo apt-get check
sudo dpkg --audit

echo
echo "=== SSH config validation ==="
sudo sshd -t

echo
echo "=== Firewall before reboot ==="
sudo ufw status verbose

echo
echo "=== Time synchronization before reboot ==="
timedatectl show -p Timezone -p NTPSynchronized -p NTP
~~~

اگر APT دربارهٔ تعارض، حذف بستهٔ مهم، یا انتخاب دستی فایل پیکربندی سؤال غیرمنتظره‌ای نشان داد، حدس نزن؛ متوقف شو و متن همان سؤال را بفرست. در صورت خطای هر دستور نیز مرحله را متوقف کن.

**ب) راه‌اندازی مجدد کنترل‌شده برای آزمایش ماندگاری تنظیمات:**

~~~bash
sudo reboot
~~~

قطع‌شدن نشست SSH طبیعی است. بعد از بالا آمدن VM، از Windows PowerShell در یک نشست تازه با کلید SSH وصل شو. اگر IP داخلی تغییر کرده است، IP واقعیِ رزروشده را از کنسول VMware یا DHCP بررسی کن؛ IP جدید را حدس نزن.

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$debianUser = Read-Host "Debian non-root username"
$nodeIp = Read-Host "Debian node LAN IPv4"
$target = "$debianUser@$nodeIp"

Test-NetConnection $nodeIp -Port 22
ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath $target "hostname; id"
~~~

اگر فرمان بالا خروجی `hostname; id` را نشان داد و سپس به `PS C:\\...` برگشت، **این رفتار طبیعی است**: فرمان از راه دور اجرا شده و SSH بعد از پایانش اتصال را بسته است. برای بازکردن یک Shell تعاملی روی Debian، در همان پنجرهٔ PowerShell فرمان زیر را جداگانه اجرا کن:

~~~powershell
ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath $target
~~~

هنگام اجرای این فرمان، انتهای دستور نباید عبارت `"hostname; id"` داشته باشد. وقتی prompt شبیه `sv1@fc-node-01:~### 1.21 ممیزی نهایی Base Debian و آزمون ماندگاری پس از reboot

این هنوز بخشی از Chapter 1 است؛ در این گام سرویس‌های Panel نصب نمی‌شوند. هدف این است که سیستم‌عامل، APT، SSH، Firewall، زمان، شبکه و فضای دیسک را پس از راه‌اندازی مجدد دوباره تأیید کنیم. قبل از اجرای بلوک، مطمئن شو کار در نشست SSH با حساب عادیِ عضو گروه `sudo` انجام می‌شود.

**الف) اعمال آخرین به‌روزرسانی‌های Debian و بررسی سلامت APT:**

~~~bash
set -eu

sudo apt update
sudo apt full-upgrade -y
sudo apt-get check
sudo dpkg --audit

echo
echo "=== SSH config validation ==="
sudo sshd -t

echo
echo "=== Firewall before reboot ==="
sudo ufw status verbose

echo
echo "=== Time synchronization before reboot ==="
timedatectl show -p Timezone -p NTPSynchronized -p NTP
~~~

اگر APT دربارهٔ تعارض، حذف بستهٔ مهم، یا انتخاب دستی فایل پیکربندی سؤال غیرمنتظره‌ای نشان داد، حدس نزن؛ متوقف شو و متن همان سؤال را بفرست. در صورت خطای هر دستور نیز مرحله را متوقف کن.

**ب) راه‌اندازی مجدد کنترل‌شده برای آزمایش ماندگاری تنظیمات:**

~~~bash
sudo reboot
~~~

قطع‌شدن نشست SSH طبیعی است. بعد از بالا آمدن VM، از Windows PowerShell در یک نشست تازه با کلید SSH وصل شو. اگر IP داخلی تغییر کرده است، IP واقعیِ رزروشده را از کنسول VMware یا DHCP بررسی کن؛ IP جدید را حدس نزن.

 ظاهر شد، داخل Debian هستی و می‌توانی بخش «ج) پس از ورود تازه، بررسی نهایی روی Debian» را اجرا کنی.

دستور سادهٔ `ssh sv1@192.168.1.7` ممکن است شکست بخورد، چون کلید `id_ed25519_fragcity` را صریحاً معرفی نمی‌کند. پس از غیرفعال‌کردن PasswordAuthentication، باید کلید درست را ارائه دهی. همچنین `sv1` نام کاربری است؛ `fc-node-01` نام میزبان است، نه نام حساب.


**ج) پس از ورود تازه، بررسی نهایی روی Debian:**

~~~bash
set -eu

echo "=== OS and host identity ==="
. /etc/os-release
printf 'OS=%s %s\n' "$NAME" "$VERSION_ID"
hostname -f
getent hosts "$(hostname -f)"

echo
echo "=== Package manager health ==="
sudo apt-get check
sudo dpkg --audit

echo
echo "=== SSH and firewall ==="
sudo sshd -t
sudo systemctl is-active ssh
sudo sshd -T | grep -Ei '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
sudo ufw status verbose

echo
echo "=== Time, network and routes ==="
timedatectl show -p Timezone -p NTPSynchronized -p NTP
ip -4 -o address show dev ens33
ip -4 route

echo
echo "=== Memory, swap and storage baseline ==="
free -h
swapon --show
df -hT /
df -ih /
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

echo
echo "=== Listening TCP sockets ==="
sudo ss -ltnp
~~~

**معیار قبولی مرحلهٔ 1.21:**
- ورود جدید با کلید SSH پس از reboot موفق باشد؛ `hostname -f` برابر `fc-node-01.fragcity.ir` باشد.
- `sudo apt-get check` بدون خطا تمام شود و `sudo dpkg --audit` مورد ناقصی گزارش نکند.
- سرویس SSH فعال، پیکربندی آن معتبر، ورود root و احراز هویت SSH با رمز غیرفعال، و احراز هویت کلیدی فعال بماند.
- UFW فعال بماند؛ timezone برابر `UTC` و وضعیت `NTPSynchronized=yes` باشد؛ IP/route و فضای دیسک منطقی باشند.
- چون هنوز Chapter 2 اجرا نشده، پورت‌های برنامه‌ای مثل 80، 443، 3306 و 6379 نباید از این مرحله به‌عنوان سرویس‌های آمادهٔ برنامه انتظار بروند. اگر روی این پورت‌ها listener غیرمنتظره دیدی، پیش از ادامه بررسی کن.

اگر هر معیار شکست خورد، Chapter 1 را کامل علامت نزن و مرحلهٔ 2.1 را اجرا نکن؛ خروجی مرتبط را در گفت‌وگو بفرست. حتی اگر همهٔ معیارها موفق بودند، بعد از ارسال لاگ‌های مرحلهٔ 1.21 همین‌جا توقف کن و تا بررسی و تأیید لاگ‌ها در گفت‌وگو، مرحلهٔ 1.22 را اجرا نکن. خروجی‌ها را داخل README ذخیره نکن.

### 1.22 Snapshot پایه در VMware

فقط پس از قبولی مرحلهٔ 1.21 از همین VM یک Snapshot بگیر:

- نام پیشنهادی: `debian13-base-ready`
- اگر Snapshot قبلی با نام `debian13-base-ssh-firewall` را **قبل از** ممیزی و reboot نهایی گرفته‌ای، آن را نگه دار و در صورت امکان یک Snapshot تازه با نام بالا بساز؛ Snapshot قدیمی را به‌عنوان وضعیت نهایی Base معرفی نکن.
- اگر VMware Snapshot را پشتیبانی نمی‌کند، این مرحله را رد کن اما آن را در چت اعلام کن؛ Snapshot جای Backup مستقل فایل VM یا داده‌ها را نمی‌گیرد.
- به دیسک/VMDK سیستم قبلی دست نزن و آن را overwrite یا بدون برنامه mount نکن.

### تعریف پایان Chapter 1 — Debian Base آماده است

Chapter 1 زمانی کامل است که تمام موارد زیر تأیید شوند:

1. نصب Debian 13 Console-only و به‌روزرسانی بسته‌های پایه انجام شده باشد.
2. حساب غیر root عضو `sudo` باشد و مدیریت روزمره با SSH Key انجام شود.
3. Hostname/FQDN، نام محلی میزبان، timezone و NTP درست باشند.
4. IP رزروشده، gateway و مسیر خروجی شبکه پس از reboot همچنان درست باشند.
5. SSH hardening و قواعد UFW پس از reboot باقی مانده باشند.
6. APT و وضعیت بسته‌های نصب‌شده سالم باشند و منابع CPU/RAM/swap/disk ثبت و بررسی شوند.
7. مرحلهٔ 1.21 قبول شده باشد و Snapshot مرحلهٔ 1.22 گرفته شده باشد یا به‌صراحت به‌عنوان پشتیبانی‌نشده/ردشده ثبت شود.

**مرزبندی مهم:** Chapter 1 فقط پایهٔ سیستم‌عامل و دسترسی امن میزبان است. PHP، NGINX، MariaDB، Redis، فایل‌های Panel، Docker و Wings نرم‌افزارهای لایهٔ برنامه‌اند؛ برای همین در Chapter 2 و فصل‌های بعدی می‌آیند. اینکه دستورشان روی Debian اجرا می‌شود، آن‌ها را به کارِ Base OS تبدیل نمی‌کند. این تفکیک عمدی است تا نصب برنامه به‌صورت مرحله‌ای، قابل‌بررسی و قابل‌بازیابی باشد.

**دروازهٔ جداگانهٔ انتشار عمومی:** بررسی WAN Management مودم در مرحلهٔ 1.17.1 هنوز از لاگ‌های فعلی تأیید نشده است. این موضوع مانع نصب محلی و آزمایش LAN نیست، اما پیش از فعال‌کردن TLS/انتشار اینترنت در مرحلهٔ 3.7 باید حل و از شبکهٔ بیرونی بررسی شود. چون TCP 80 موقتاً به Debian فوروارد شده، حتماً آن را قبل از مرحلهٔ 2.2 حذف کن؛ NGINX در آن مرحله نصب و فعال می‌شود. Port Forward را فقط طبق پیش‌شرط‌های مرحلهٔ 3.7 موقتاً برگردان.


### اتصال روزمره از Windows PowerShell به Debian — دستور مهم و همیشگی

این راهنما را برای هر بار اتصال نگه دار. آن را در **Windows PowerShell** اجرا کن؛ نه داخل Bash/Debian. هر پنجرهٔ PowerShell تازه که باز می‌کنی، دوباره متغیرها را تعریف کن:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$target = "sv1@192.168.1.7"

ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath $target
~~~

- اگر از تو `Enter passphrase for key` خواسته شد، passphrase همان کلید خصوصی SSH را وارد کن. هنگام تایپ، کاراکترها نمایش داده نمی‌شوند؛ این طبیعی است.
- وقتی prompt به شکل `sv1@fc-node-01:~# FragCity — راهنمای مادرِ Copy/Paste از Debian تا سرورهای CS2

> **این فایل مرجع اجرایی واحد پروژه است.** از اینجا به بعد توضیحات، ترتیب اجرا، تصمیم‌های فنی و بلوک‌های Copy/Paste در همین README نوشته می‌شوند. خروجی ترمینال، لاگ واقعی، رمزها و نتیجهٔ اجرای فرمان‌ها در README ثبت نمی‌شوند؛ لاگ لازم برای عیب‌یابی را فقط در گفت‌وگو بفرست. بعد از هر مرحله فقط مرحلهٔ جاری را اجرا کن و برای ادامه، به‌روزرسانی README را بخوان.
>
> **وضعیت فعلی: مراحل 1.9 تا 1.20 برای Debian Console-only انجام شده‌اند؛ ورود تازه با SSH Key و فعال‌بودن UFW تأیید شده است.** Chapter 1 هنوز کامل نیست: ابتدا مرحلهٔ 1.21 ممیزی نهایی و آزمون reboot، سپس مرحلهٔ 1.22 Snapshot (یا ثبت علت ردکردن آن) را انجام بده. تا تأیید این دو گام، مرحلهٔ 2.1 را شروع نکن. مدیریت WAN مودم هنوز به‌عنوان تأییدشده ثبت نشده؛ این مانع ساخت محلی Panel نیست، اما پیش‌نیاز انتشار عمومی/TLS است. Port Forward پورت 80 طبق گزارش موقتاً به Debian اشاره می‌کند و باید قبل از نصب/فعال‌شدن NGINX غیرفعال شود.
>
> **قانون secrets:** رمز MariaDB، رمز حساب، APP_KEY، token، فایل .env و محتوای /etc/pterodactyl/config.yml را در GitHub یا چت قرار نده. مقادیر نمونه را فقط به‌صورت محلی جایگزین کن.

---

## مسیر اجرایی پس از تکمیل Chapter 1

**Chapter 1:** Snapshot مرحلهٔ 1.22 با نام `debian13-base-ready` طبق گزارش کاربر گرفته شده و ممیزی/reboot مرحلهٔ 1.21 تأیید شده است.

**Chapter 2:** مراحل 2.1 تا 2.3 طبق لاگ نصب و بررسی شده‌اند:
- PHP 8.3.35 و افزونه‌های موردنیاز؛
- Composer 2.10.3، نصب‌کننده با تطبیق SHA-384؛
- NGINX، MariaDB، Redis و PHP-FPM نصب و `active`؛
- MariaDB روی `127.0.0.1:3306` و Redis روی loopback.

**پیش از گام بعد:** لاگ نشان می‌دهد NGINX اکنون روی `0.0.0.0:80` و `[::]:80` گوش می‌دهد. اگر Port Forward موقت TCP 80 هنوز در مودم/روتر به `192.168.1.7:80` اشاره می‌کند، همین حالا آن rule را disable/delete کن؛ فعلاً صفحهٔ پیش‌فرض NGINX را نباید از اینترنت منتشر کنیم. اگر قبلاً حذفش کرده‌ای، دوباره تغییرش نده.

سپس مرحلهٔ **2.4 — پس‌بررسی سلامت** را اجرا کن. بعد از بررسی لاگ 2.4، مرحلهٔ 3.1 را اجرا می‌کنیم. در نصب تازه، 3.1 فایل‌های نسخهٔ پایدار انتخاب‌شدهٔ Panel را دریافت می‌کند و فقط یک‌بار `APP_KEY` می‌سازد؛ هرگز اجرای 3.1 را روی مسیر دارای `.env` موجود تکرار نکن. مرحلهٔ 3.2 دیتابیس را می‌سازد و بعد از آن متوقف می‌شویم تا لاگ‌ها بازبینی شوند.

**مرحله‌های اجراشده طبق لاگ:** 2.1، 2.2 و 2.3.

## 2. نصب PHP 8.3 و نیازمندی‌های Panel (نصب تازه)

این مرحله پس از نصب پاک Debian Console-only اجرا می‌شود؛ روی سیستم قدیمی پیش از نصب مجدد اجرا نکن.

### 2.1 بررسی مخزن PHP 8.3 (اول بررسی، بعد تصمیم)

در لاگ مرحلهٔ 1.21، APT قبلاً این مخزن را دیده بود: `https://packages.sury.org/php trixie InRelease`. بنابراین فعلاً کلید یا فایل منبع جدید نساز و فرمان `gpg --dearmor -o ...` را کورکورانه تکرار نکن؛ ممکن است فایل کلید/منبع از قبل وجود داشته باشد یا با نام دیگری تنظیم شده باشد.

**محل اجرا: نشست SSH در Debian با کاربر عادی `sv1`.** این بلوک مخزن را تغییر نمی‌دهد؛ فقط فایل‌های تنظیمات فعلی، نسخهٔ قابل‌دسترس PHP، بسته‌های نصب‌شده و سلامت APT را بررسی می‌کند:

~~~bash
set -eu

echo "=== Debian release ==="
. /etc/os-release
printf 'OS=%s\nVERSION_ID=%s\nCODENAME=%s\n' "$NAME" "$VERSION_ID" "$VERSION_CODENAME"

echo
echo "=== Existing Sury PHP repository definitions ==="
sudo grep -RnsH --include='*.list' --include='*.sources' \
  'packages.sury.org/php' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null || true

echo
echo "=== Possible existing Sury keyring files ==="
sudo find /etc/apt/keyrings /usr/share/keyrings -maxdepth 1 -type f \
  \( -iname '*sury*php*' -o -iname '*debsury*' \) \
  -printf '%M %u:%g %p\n' 2>/dev/null || true

echo
echo "=== Refresh package metadata ==="
sudo apt update

echo
echo "=== PHP 8.3 package candidate ==="
apt-cache policy php8.3-cli

echo
echo "=== PHP 8.3 packages already installed, if any ==="
dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package} ${Version}\n' 'php8.3*' 2>/dev/null || true
~~~

**معیار قبولی 2.1:**
- `sudo apt update` بدون خطا و با کد خروج صفر تمام شود.
- `apt-cache policy php8.3-cli` یک `Candidate` واقعی نشان دهد؛ اگر `Candidate: (none)` بود، متوقف شو و خروجی را بفرست.
- در نتیجهٔ بررسی باید روشن باشد مخزن از کدام فایل منبع و کدام keyring استفاده می‌کند. اگر منبع در فایل دیگری ثبت شده، از روی گزارش آن را دوباره اضافه نکن.

اگر مخزن درست کار می‌کند، مرحلهٔ 2.1 تمام است و به نصب بسته‌ها در 2.2 می‌رویم. اگر مخزن پیدا نشد یا خطای امضا/Release رخ داد، فایل تنظیمات را حذف یا جایگزین نکن؛ خروجی را بفرست تا دقیقاً همان تنظیم موجود را اصلاح کنیم.

مرجع رسمی Pterodactyl تأیید می‌کند Debian 13 به مخزن اضافی برای PHP نیاز دارد و PHP 8.3/8.4 جزو نسخه‌های پشتیبانی‌شده هستند: https://docs.pterodactyl.io/v2/panel/getting-started

### 2.2 نصب بسته‌ها

**پیش‌شرط شبکه:** پیش از اجرای این بلوک، Port Forward مربوط به TCP 80 را در مودم/روتر حذف کن. با نصب NGINX، سرویس وب روی پورت 80 فعال می‌شود؛ در این مرحله Panel هنوز تکمیل نشده و TLS آماده نیست. UFW اجازهٔ 80/443 دارد، اما بدون Port Forward ورودی همچنان از اینترنت به Debian هدایت نمی‌شود.

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


### 2.4 پس‌بررسی سلامت پس از نصب

این مرحله فقط‌خواندنی است و پیش از دریافت فایل‌های Panel اجرا می‌شود. بسته‌ها و سرویس‌ها در لاگ قبلی نصب شده‌اند؛ این بررسی سلامت Package Manager، نحو NGINX/PHP-FPM، اتصال محلی دیتابیس/Redis و پورت‌های در حال گوش‌دادن را کنترل می‌کند.

**چرا فرمان قبلی SSH را قطع کرد؟** در اجرای قبلی، `nginx -v 2>&1` با `nginx: command not found` شکست خورد. در نشست کاربر عادی، مسیر `/usr/sbin` ممکن است داخل `PATH` نباشد. چون بلوک با `set -eu` شروع شده بود، اولین خطای فرمان باعث پایان اجرای Shell و در نتیجه بسته‌شدن نشست SSH شد. خود SSH خراب نیست و لاگ نشان نمی‌دهد که NGINX حذف شده باشد. برای مسیر قطعی از `sudo /usr/sbin/nginx -v` استفاده می‌کنیم.

**مهم:** کل بلوک را داخل یک subshell یعنی بین `(` و `)` اجرا می‌کنیم. اگر فرمانی خطا بدهد، همان بلوک متوقف می‌شود ولی نباید نشست تعاملی SSH را ببندد.

**پیش‌شرط امنیتی:** قبل از اجرا بررسی کن Port Forward موقت TCP 80 در مودم/روتر حذف شده باشد. NGINX روی پورت 80 گوش می‌دهد و UFW آن را مجاز کرده است؛ باقی‌ماندن Port Forward می‌تواند صفحهٔ پیش‌فرض NGINX را از اینترنت قابل‌دسترسی کند.

~~~bash
(
set -eu

echo "=== Package manager health ==="
sudo apt-get check
sudo dpkg --audit

echo
echo "=== Installed versions ==="
php8.3 -v
php8.3 /usr/local/bin/composer --version
mariadb --version
redis-server --version
sudo /usr/sbin/nginx -v 2>&1

echo
echo "=== PHP-FPM syntax ==="
sudo /usr/sbin/php-fpm8.3 -t

echo
echo "=== NGINX syntax ==="
sudo /usr/sbin/nginx -t

echo
echo "=== Required services: enabled ==="
for service in nginx mariadb redis-server php8.3-fpm; do
  printf '%s: ' "$service"
  sudo systemctl is-enabled "$service"
done

echo
echo "=== Required services: active ==="
for service in nginx mariadb redis-server php8.3-fpm; do
  printf '%s: ' "$service"
  sudo systemctl is-active "$service"
done

echo
echo "=== MariaDB local socket/query ==="
sudo mariadb -Nse "SELECT VERSION();"

echo
echo "=== Redis local health ==="
redis-cli ping

echo
echo "=== Local NGINX response ==="
curl --connect-timeout 5 --max-time 10 -sS -o /dev/null \
  -w 'HTTP status: %{http_code}\n' http://127.0.0.1/

echo
echo "=== Listening TCP ports ==="
sudo ss -ltnp
)
~~~

معیار قبولی:
- `apt-get check` بدون خطا تمام شود و `dpkg --audit` مورد ناقصی گزارش نکند.
- `php-fpm8.3 -t` و `nginx -t` موفق باشند.
- هر چهار سرویس `nginx`, `mariadb`, `redis-server`, `php8.3-fpm` هم enabled و هم active باشند.
- پرس‌وجوی محلی MariaDB یک نسخه برگرداند و Redis پاسخ `PONG` بدهد.
- درخواست محلی NGINX یک status HTTP برگرداند؛ قبل از نصب Virtual Host، پاسخ صفحهٔ پیش‌فرض روی loopback طبیعی است.
- MariaDB و Redis فقط روی loopback گوش دهند. NGINX روی پورت 80 انتظار می‌رود؛ پورت 443 تا پیش از پیکربندی TLS هنوز ممکن است listener نداشته باشد.

اگر معیار قبولی برقرار نبود، 3.1 را اجرا نکن؛ خروجی خطا/سرویس‌های ناموفق را بفرست. در صورت بروز خطا، به‌دلیل اجرای بلوک داخل subshell، باید prompt نشست SSH باقی بماند. لاگ‌های واقعی را در README ثبت نکن.

## 3. نصب Pterodactyl Panel — فاز آینده، پیش از اجرا نسخه را بازبینی کن

### 3.0 بررسی نسخه‌ها و تصمیم معماری (بازبینی 2026-10-18)

#### وضعیت انتشار رسمی

- **Pterodactyl Panel 1.x:** آخرین نسخهٔ پایدارِ قابل‌مشاهده در صفحهٔ رسمی Releases، `v1.15.1` است.
- **Pterodactyl Panel 2.x:** آخرین پیش‌انتشارِ قابل‌مشاهده، `v2.0.0-beta.2` است که در 14 اکتبر 2026 منتشر شده و Release آن صراحتاً Open Beta / Pre-release است. صفحهٔ معرفی Beta توصیه می‌کند آن را روی محیط آزمایشگاهی تست کنید و برای Production روی 1.x بمانید.
- لینک‌های مرجع: https://github.com/pterodactyl/panel/releases ، https://docs.pterodactyl.io/v1/panel/getting-started و https://docs.pterodactyl.io/v2/panel/getting-started

#### تفاوت‌های مهم v1 و v2

| موضوع | Panel 1.x (پایدار) | Panel 2.0 (Open Beta) |
|---|---|---|
| وضعیت برای Production | خط پایدار فعلی؛ انتخاب محافظه‌کارانه‌تر برای سرویس واقعی | پیش‌انتشار؛ برای تست و ارزیابی، نه انتخاب اصلی Production در وضعیت فعلی |
| رابط مدیریت | رابط و معماری قدیمی‌تر 1.x | رابط کاربری جدیدتر و یکپارچه‌تر برای Admin و User |
| توسعه و سفارشی‌سازی | Theme/Addonهای 1.x ممکن است با نسخه و روش نصب وابسته باشند؛ تغییر مستقیم Core نگهداری و ارتقا را دشوار می‌کند | سیستم رسمی Extensions و Themes برای افزودن صفحه، تب جزئیات، ستون، تنظیم، API و UI بدون patch کردن Core |
| ظاهر Panel | در صورت تغییر فایل‌های اصلی، نگهداری تغییرات بین آپدیت‌ها دشوار است | Theme می‌تواند رنگ‌ها و بخش‌هایی از رابط را تغییر بدهد؛ برای سفارشی‌سازی UI روش ساختاریافته‌تری دارد |
| Egg grouping | Eggها زیر Nest گروه‌بندی می‌شوند | Tags جای Nest را می‌گیرند؛ یک Egg می‌تواند چند Tag بگیرد و Nodeها هم Tag دارند |
| API | Client API و Application API | Client و Application API عمدتاً باقی‌اند، Admin API جدید اضافه شده؛ endpointهای مربوط به Nest در Application API حذف شده‌اند و باید از Tags/Eggs استفاده شود |
| فناوری Frontend | خط قدیمی‌تر frontend در 1.x | Laravel 13، React 19، TanStack، Tailwind 4 و Vite |
| نیازمندی‌های نصب | وابسته به نسخهٔ 1.x انتخابی | PHP 8.3/8.4، Composer 2، Redis، و MariaDB 10.11/11 یا MySQL 8/9؛ افزونهٔ intl لازم است |
| Wings | از جدول سازگاری مستندات 1.x استفاده می‌کنیم | فعلاً جدول رسمی کامل نسخه‌های Wings وجود ندارد؛ مستندات v2 صراحتاً Wings 1.13.2 و 1.13.3 را در تست تأیید کرده‌اند. سازگاری نسخهٔ دیگر را حدس نزن |
| ریسک مهاجرت | در همان خط پایدار آپدیت می‌شود | برای ارتقا از 1.x به 2.0 باید راهنمای جداگانه و Backup/آزمون روی کپی اجرا شود؛ Nestها، کدهای سفارشی و ادغام Billing نیازمند بازبینی‌اند |

#### امکانات v2 دقیقاً کجا برای FragCity کاربرد دارند؟

1. **Themes:** اگر بخواهیم خود پنل Pterodactyl (به‌ویژه بخش مدیریت داخلی) رنگ‌بندی و ظاهر اختصاصی داشته باشد. این با طراحی سایت مشتریان FragCity یکی نیست.
2. **Extensions:** اگر بعداً بخواهیم داخل خود Pterodactyl صفحه یا تنظیمات داخلی مخصوص عملیات FragCity، جزئیات Node/Server، فیلدهای فرم یا API داخلی اضافه کنیم، بدون ویرایش مستقیم Core این مسیر هدفمندتر است. اما Extension با دسترسی خود Panel اجرا می‌شود و بالقوه به دیتابیس و اطلاعات کاربران دسترسی دارد؛ فقط کدی را نصب کن که به توسعه‌دهنده‌اش اعتماد داری.
3. **Tags به‌جای Nests:** اگر Eggها را بر اساس بازی، دستهٔ عملکرد یا قابلیت Node برچسب‌گذاری کنیم و یک Egg در چند دسته قرار بگیرد. اما این تفاوت بر API و کد Billing/Provisioning هم اثر می‌گذارد.
4. **Admin API:** برای اتوماسیون مدیریت امکانات خود Panel مثل Eggها، Tags، Settings و Extensions. ساخت، تعلیق یا حذف Server برای سیستم Billing هنوز معمولاً از Application API انجام می‌شود؛ لازم نیست صرفاً برای ساخت سایت FragCity همه‌چیز را داخل Panel پیاده کنیم.
5. **سایت مشتری FragCity:** در معماری فعلی، ثبت‌نام/ورود، Wallet، پرداخت، اشتراک مدت‌دار، تاریخ انقضا و تجربهٔ مشتری در Raw PHP خود FragCity می‌مانند. Pterodactyl موتور مدیریت Server است. بنابراین قابلیت Theme در v2 مزیت مفیدی است، اما پیش‌نیاز ساخت پنل مشتری نیست.

نکتهٔ سازگاری API: در v2 مسیرهای `/api/application/nests` حذف شده‌اند؛ مسیرهای معادل Tags/Eggs به‌کار می‌روند. درخواست‌های دیگر Application API مثل ساخت، Suspend و Delete سرور و کلیدهای Client/Application عموماً حفظ می‌شوند. چون Backend فروش FragCity هنوز در حال توسعه است، این تفاوت را در طراحی API Client ثبت می‌کنیم و endpoint مربوط به Nest را به‌عنوان قرارداد دائمی جدید نمی‌سازیم.

#### تصمیم برای همین نصب

**نسخهٔ پیشنهادی برای مسیر اصلی فعلی: Panel 1.15.1 Stable.**

دلیل انتخاب:
- این VM قرار است پایهٔ عملیاتی FragCity Node/Panel شود، نه صرفاً یک UI demo.
- هنوز نیازی نداریم مشتریان را با حساب، Wallet یا Billing به داخل UI خود Pterodactyl منتقل کنیم؛ آن بخش‌ها در سایت خودمان خواهند بود.
- Open Beta بودن v2 ریسک و تغییرات اضافه برای provisioning، API Client، Eggs/Tags و هماهنگ‌کردن Wings ایجاد می‌کند. برای Production، مستندات خود پروژه فعلاً v1.x را توصیه می‌کنند.
- قابلیت‌های Extension/Theme در v2 ارزشمندند؛ بعداً می‌توانیم با Clone جداگانه از Snapshot آزمایشگاهی آن‌ها را ارزیابی کنیم و فقط پس از Stable شدن و تست سازگاری، مهاجرت را تصمیم بگیریم.

این تصمیم به‌معنی کنارگذاشتن v2 نیست؛ فقط بین **پنل اصلی که باید قابل‌اعتماد باشد** و **محیط آزمایش ویژگی‌های جدید** تفکیک می‌کنیم. تا قبل از اجرای مرحلهٔ 3.1، Release رسمی را دوباره چک کن. اگر سیاست پروژه عوض شد و همین VM قرار بود فقط آزمایشگاه Beta باشد، دستورات نصب v2 باید به‌صورت جداگانه و صریح نوشته شوند؛ URL نسخهٔ 1.x را به‌جای v2 عوض کردن به‌تنهایی کافی نیست.

### وضعیت لازم قبل از نصب 3.1

قبل از اجرای دریافت فایل‌های Panel، مرحلهٔ 2.4 پس‌بررسی سلامت را اجرا و نتیجه را تأیید کن. مطمئن شو Port Forward موقت TCP 80 در مودم/روتر به Debian حذف شده است؛ NGINX روی پورت 80 گوش می‌دهد و نصب برنامه هنوز تکمیل نشده است.

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

# ساخت مسیر قابل‌نوشتن اختصاصی Composer برای کاربر www-data
sudo install -d -m 0750 /var/www/.composer
sudo chown www-data:www-data /var/www/.composer
sudo chmod 0750 /var/www/.composer

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

رمز را در سند نگذار. اگر user از قبل وجود دارد، برای تعویض رمز از **ALTER USER** استفاده کن، نه **CREATE USER**.

#### تغییر رمز حساب MariaDB موجود (در صورت نیاز)

این فرمان‌ها را در ترمینال SSH دبیان اجرا کن و رمز نمونه را فقط در محیط خودت جایگزین کن. از رمز واقعی در چت یا README استفاده نکن:

~~~bash
sudo env MYSQL_HISTFILE=/dev/null mariadb
~~~

داخل prompt مربوط به MariaDB:

~~~sql
ALTER USER 'pterodactyl'@'127.0.0.1'
IDENTIFIED BY 'PUT_YOUR_NEW_PASSWORD_HERE';

SHOW GRANTS FOR 'pterodactyl'@'127.0.0.1';
EXIT;
~~~

**ALTER USER** رمز حساب موجود را عوض می‌کند؛ دیتابیس را حذف یا دوباره ایجاد نکن. لازم نیست پس از آن **FLUSH PRIVILEGES** اجرا شود. رمز جدید را در Password Manager نگه دار.

#### تونل مدیریتی MariaDB از Windows PowerShell

برای اتصال ابزار GUI روی ویندوز به MariaDB محلی دبیان، فرمان زیر را در **Windows PowerShell** اجرا کن. این تونل پورت محلی ویندوز **3307** را به **127.0.0.1:3306** روی سرور هدایت می‌کند:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$target = "sv1@192.168.1.7"

ssh -v -N -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath -L 3307:127.0.0.1:3306 $target
~~~

- پنجرهٔ PowerShell را تا زمانی که اتصال دیتابیس لازم است باز نگه دار؛ بستن آن تونل را قطع می‌کند.
- در ابزار دیتابیس روی ویندوز از Host برابر **127.0.0.1**، Port برابر **3307**، Database برابر **panel** و Username برابر **pterodactyl** استفاده کن؛ رمز همان رمز جدید دیتابیس است.
- در یک پنجرهٔ PowerShell جداگانه می‌توانی بررسی کنی:

~~~powershell
Test-NetConnection 127.0.0.1 -Port 3307
~~~

اگر خروجی **TcpTestSucceeded : True** بود، پورت محلی قابل اتصال است؛ اتصال به خود دیتابیس با اطلاعات ورود را هم آزمایش کن. این روش به SSH در شبکهٔ LAN متکی است؛ پورت MariaDB را برای دسترسی عمومی روتر باز نکن.

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

### 3.4.1 راه‌اندازی اجباری Queue Worker و Scheduler — بخش ضروری نصب Panel

**این دو جزء در نصب اولیه جا افتاده بودند؛ اصلاحش اجباری است، نه اختیاری.** طبق راهنمای رسمی Pterodactyl 1.x، Scheduler باید هر دقیقه `artisan schedule:run` را اجرا کند و Queue Worker باید در پس‌زمینه `artisan queue:work` را پردازش کند. بدون این دو، بخشی از کارهای پس‌زمینهٔ Panel، ایمیل‌ها و وظایف زمان‌بندی‌شده پردازش نمی‌شوند. مرجع رسمی: https://docs.pterodactyl.io/v1/panel/getting-started

**زمان اجرا در ترتیب نصب:** پس از تنظیم Panel، آماده بودن PHP/Artisan و Redis، و پیش از اعلام تکمیل نصب Panel. این مرحله در نصب تازه و همچنین برای همین VM که الان در حال ترمیم آن هستیم لازم است.

**نکتهٔ چند-VMDK:** فایل‌های هر VM مستقل‌اند. این بلوک را اکنون روی Clone فعال با IP `192.168.1.9` اجرا کن. زمانی که به VMDK اصلی برگشتی، ابتدا Clone را کاملاً خاموش کن، Port Forwardها را به `192.168.1.7` برگردان و فقط VM اصلی را بوت کن؛ سپس همین بلوک را روی آن اجرا کن. دو VM هرگز هم‌زمان روشن نباشند. بلوک عمداً هر دو IP مورد انتظار را قبول می‌کند و پیش از تغییر، hostname، مسیر Panel، `QUEUE_CONNECTION=redis`، Redis، Cron و دستورات Artisan را چک می‌کند.

این بلوک از روی مستندات رسمی Pterodactyl تنظیم شده و برای اجرای مجدد، duplicate Scheduler اضافه نمی‌کند. اگر `pteroq.service` از قبل وجود داشته اما تنظیماتش با فرمان مورد انتظار تفاوت داشته باشد، آن را بازنویسی نمی‌کند و با خطا متوقف می‌شود. از crontab ریشه هم قبل از تغییر یک نسخهٔ محلی با مجوز محدود می‌گیرد.

~~~bash
sudo bash <<'SETUP'
set -Eeuo pipefail

EXPECTED_HOST="fc-node-01"
PANEL_DIR="/var/www/pterodactyl"
UNIT_PATH="/etc/systemd/system/pteroq.service"
EXPECTED_EXEC="/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3"

echo "=== 1. Identify this VM and verify prerequisites ==="
CURRENT_HOST="$(hostnamectl --static)"

if [[ "$CURRENT_HOST" != "$EXPECTED_HOST" ]]; then
    echo "ERROR: expected hostname $EXPECTED_HOST; found $CURRENT_HOST. Nothing changed."
    exit 1
fi

if ! ip -o -4 address show | grep -Eq '192\.168\.1\.(7|9)/'; then
    echo "ERROR: expected active FragCity VM at 192.168.1.7 or 192.168.1.9. Nothing changed."
    exit 1
fi

if [[ ! -f "$PANEL_DIR/artisan" || ! -f "$PANEL_DIR/.env" ]]; then
    echo "ERROR: Panel files not found at $PANEL_DIR. Nothing changed."
    exit 1
fi

if ! systemctl is-active --quiet redis-server; then
    echo "ERROR: redis-server is not active. Nothing changed."
    exit 1
fi

if ! systemctl is-active --quiet cron; then
    echo "ERROR: cron is not active. Nothing changed."
    exit 1
fi

if ! grep -Eq "^QUEUE_CONNECTION=(redis|\"redis\"|'redis')[[:space:]]*$" "$PANEL_DIR/.env"; then
    echo "ERROR: QUEUE_CONNECTION is not explicitly set to redis. Nothing changed."
    exit 1
fi

echo "Hostname, active VM IP, Panel path, QUEUE_CONNECTION=redis, Redis and Cron: OK."

echo
echo "=== 2. Verify PHP CLI and Artisan ==="
if [[ ! -x /usr/bin/php ]]; then
    echo "ERROR: /usr/bin/php is missing or not executable. Nothing changed."
    exit 1
fi

runuser -u www-data -- /usr/bin/php "$PANEL_DIR/artisan" --version

ARTISAN_LIST="$(runuser -u www-data -- /usr/bin/php "$PANEL_DIR/artisan" list --raw 2>/dev/null)"
if ! printf '%s\n' "$ARTISAN_LIST" | grep -Eq '^queue:work[[:space:]]'; then
    echo "ERROR: queue:work was not found in Artisan. Nothing changed."
    exit 1
fi
if ! printf '%s\n' "$ARTISAN_LIST" | grep -Eq '^schedule:run([[:space:]]|$)'; then
    echo "ERROR: schedule:run was not found in Artisan. Nothing changed."
    exit 1
fi
echo "Both Artisan commands are present."

echo
echo "=== 3. Create or validate pteroq.service ==="

if [[ -e "$UNIT_PATH" ]]; then
    if grep -Fxq "User=www-data" "$UNIT_PATH" &&
       grep -Fxq "Group=www-data" "$UNIT_PATH" &&
       grep -Fxq "WorkingDirectory=/var/www/pterodactyl" "$UNIT_PATH" &&
       grep -Fxq "ExecStart=$EXPECTED_EXEC" "$UNIT_PATH"; then
        echo "Existing pteroq.service matches required user, path and command; preserving it."
    else
        echo "ERROR: $UNIT_PATH already exists but does not match expected configuration."
        echo "It was not overwritten. Inspect it manually before continuing."
        exit 1
    fi
else
    cat > "$UNIT_PATH" <<'UNIT'
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
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT
    chmod 0644 "$UNIT_PATH"
    echo "Created $UNIT_PATH"
fi

systemd-analyze verify "$UNIT_PATH"
systemctl daemon-reload
systemctl enable --now pteroq.service

echo
echo "=== 4. Add scheduler to root crontab without duplicating it ==="

if ! command -v crontab >/dev/null 2>&1; then
    echo "ERROR: crontab command not found. Queue Worker was configured, but Scheduler was not changed."
    exit 1
fi

CRONTAB_BACKUP="/root/root-crontab-before-pterodactyl-scheduler-$(date +%Y%m%d-%H%M%S)"
crontab -l > "$CRONTAB_BACKUP" 2>/dev/null || true
chmod 0600 "$CRONTAB_BACKUP"
echo "Root crontab backup: $CRONTAB_BACKUP"

SCHEDULER_LINE='* * * * * /usr/bin/php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1'

if crontab -l 2>/dev/null | grep -Fq '/var/www/pterodactyl/artisan schedule:run'; then
    echo "A scheduler entry for this Panel already exists; no duplicate added."
else
    { crontab -l 2>/dev/null || true; printf '%s\n' "$SCHEDULER_LINE"; } | crontab -
    echo "Added the scheduler entry to root's crontab."
fi

echo
echo "=== 5. Verify both components ==="
systemctl is-enabled pteroq.service
systemctl is-active pteroq.service
systemctl status pteroq.service --no-pager -l

echo
crontab -l | grep -F '/var/www/pterodactyl/artisan schedule:run'

echo
echo "Queue Worker and Scheduler are configured on this VM."
echo "Repeat this procedure on the other VMDK later, when that VM alone is powered on."
echo "Keep the original and Clone powered on one at a time only."
SETUP
~~~

**معیار قبولی بلافاصله بعد از اجرا:**

~~~bash
sudo systemctl is-enabled pteroq.service
sudo systemctl is-active pteroq.service
sudo systemctl status pteroq.service --no-pager -l
sudo crontab -l | grep -F '/var/www/pterodactyl/artisan schedule:run'
~~~

انتظار می‌رود `pteroq.service` هم `enabled` و هم `active` باشد و خط Scheduler در crontab ریشه وجود داشته باشد. اگر سرویس فعال نشد، به‌جای نصب مجدد Panel، خروجی زیر را برای عیب‌یابی بفرست:

~~~bash
sudo systemctl status pteroq.service --no-pager -l
sudo journalctl -u pteroq.service -n 40 --no-pager
~~~

نتیجهٔ ثبت‌شده در 2026-10-18: این مرحله روی Clone با IP `192.168.1.9` با موفقیت اجرا شد؛ `pteroq.service` هم `enabled` و هم `active (running)` بود و خط Scheduler در crontab ریشه تأیید شد. این تغییرات به‌صورت خودکار به VMDK اصلی منتقل نمی‌شوند؛ هنگام بازگشت به آن نیز همین مرحله را جداگانه اجرا کن. هنگام `systemd-analyze verify` یک هشدار جداگانه دربارهٔ مسیر قدیمی `PIDFile` در `wings.service` زیر `/var/run/` دیده شد؛ این هشدار Queue Worker را متوقف نکرده است و باید جداگانه و پس از بررسی فایل سرویس پیگیری شود.

**پورت `29001/udp` که برای سرور CS2 رزرو کرده‌ای در این مرحله دست‌نخورده می‌ماند.**

### 3.5 پیکربندی NGINX برای LAN

**بلوک NGINX زیر را به‌عنوان فرمان Bash اجرا نکن.** محتوای آن باید داخل فایل `/etc/nginx/sites-available/pterodactyl.conf` ذخیره شود. ابتدا در SSH دبیان این فرمان را اجرا کن:

~~~bash
sudo nano /etc/nginx/sites-available/pterodactyl.conf
~~~

وقتی ویرایشگر **Nano** باز شد، بلوک NGINX زیر را داخل ویرایشگر paste کن، نه در prompt ترمینال. سپس با `Ctrl+O`، `Enter` و `Ctrl+X` ذخیره کن و خارج شو. اگر فایل جدید باز شد، خالی‌بودن آن پیش از paste طبیعی است.

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

# Validate the new site before disabling Debian's default site.
sudo /usr/sbin/nginx -t

if sudo test -L /etc/nginx/sites-enabled/default; then
  sudo rm /etc/nginx/sites-enabled/default
fi

# Validate again; reload only after both syntax checks pass.
sudo /usr/sbin/nginx -t
sudo systemctl reload nginx
sudo systemctl is-active nginx
curl -sS -o /dev/null -w 'HTTP status: %{http_code}\n' -H 'Host: panel.fragcity.ir' http://127.0.0.1/
~~~

#### اگر محتوای NGINX اشتباهاً در Bash paste شد یا SSH قطع شد

خطاهایی مثل `-bash: server: command not found` معمولاً یعنی محتوا در محل اشتباه وارد شده است؛ این پیام به‌تنهایی به معنی خرابی NGINX نیست. **پیش از فعال‌سازی یا reload، دوباره وارد Debian شو و فقط وضعیت فعلی را بررسی کن.**

در یک پنجرهٔ تازهٔ **Windows PowerShell**، دستور اتصال روزمرهٔ بخش 1 را اجرا کن. بعد از بازشدن نشست SSH، این بلوک فقط‌خواندنی را کامل اجرا کن:

~~~bash
(
echo "=== NGINX site file ==="
if sudo test -f /etc/nginx/sites-available/pterodactyl.conf; then
  sudo stat -c '%U:%G %a %s bytes %n' /etc/nginx/sites-available/pterodactyl.conf
  sudo sed -n '1,180p' /etc/nginx/sites-available/pterodactyl.conf
else
  echo "CONFIG FILE MISSING: /etc/nginx/sites-available/pterodactyl.conf"
fi

echo
echo "=== Enabled site links ==="
sudo ls -l /etc/nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-enabled/default 2>&1

echo
echo "=== NGINX syntax test ==="
sudo /usr/sbin/nginx -t

echo
echo "=== NGINX service ==="
sudo systemctl is-active nginx
sudo systemctl status nginx --no-pager -l
)
~~~

این بلوک چیزی را فعال، حذف، ذخیره یا reload نمی‌کند. لاگش را برای بررسی بفرست. اگر آزمون syntax شکست خورد، فایل را اصلاح نکن یا سرویس را reload نکن تا علت مشخص شود. اگر فایل وجود ندارد، محتوا را فقط با بازکردن Nano طبق دستور ابتدای همین مرحله وارد کن.

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

### 3.7 صدور TLS برای Panel و Node — راهنمای مرجع

برای FragCity دو hostname جدا داریم و هرکدام گواهی TLS مناسب خودش را لازم دارد:

- Panel مشتری/ادمین: panel.fragcity.ir
- Node و Wings: fc-node-01.fragcity.ir

**گواهی Panel به‌تنهایی گواهی Node را ایجاد نمی‌کند.** اگر Wings روی مسیر گواهی Node تنظیم شده باشد ولی آن گواهی صادر نشده باشد، Wings با خطای missing fullchain.pem متوقف می‌شود. این راهنما هر دو گواهی و بازیابی همان خطا را پوشش می‌دهد.

**پیش‌شرط شبکه:** Panel در LAN سالم باشد؛ رابط مدیریت روتر از WAN قابل دسترسی نباشد؛ DNS عمومی برای hostname موردنظر به IP عمومی فعلی اشاره کند؛ و Port Forward ورودی TCP 80/443 (برای این VM) به IP LAN رزروشدهٔ Node هدایت شود. اگر WAN پشت CGNAT/NAT بالادستی است، پیش از صدور گواهی مسیر ورودی را حل کن. هیچ Port Forward عمومی برای SSH 22، MariaDB 3306 یا Redis 6379 ایجاد نکن. Wings/SFTP ports را هم تا بعد از آزمون و بازبینی firewall عمومی نکن.

#### 3.7.1 گواهی Panel

~~~bash
set -eu
sudo apt install -y certbot python3-certbot-nginx
sudo /usr/sbin/nginx -t
sudo certbot --nginx --redirect -d panel.fragcity.ir
~~~

در prompt مربوط به Certbot، ایمیل مدیریتی خودت را وارد کن؛ آن را در README یا چت ننویس. سپس URL برنامه را به HTTPS تغییر بده و Cache را بازسازی کن:

~~~bash
set -eu
sudo sed -i -E 's#^APP_URL=.*#APP_URL=https://panel.fragcity.ir#' /var/www/pterodactyl/.env
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan config:clear
sudo -u www-data php8.3 artisan cache:clear
sudo -u www-data php8.3 artisan view:clear
sudo -u www-data php8.3 artisan config:cache
sudo /usr/sbin/nginx -t
sudo systemctl reload nginx
~~~

بررسی اولیهٔ Panel:

~~~bash
set -eu
curl -fsSI --max-time 15 https://panel.fragcity.ir/
sudo certbot certificates
sudo certbot renew --dry-run
~~~

#### 3.7.2 گواهی جداگانهٔ Node/Wings

گواهی `panel.fragcity.ir` جای گواهی `fc-node-01.fragcity.ir` را نمی‌گیرد. برای صدور و تمدید گواهی Node با روش HTTP-01، رکورد A عمومی باید به IPv4 عمومی فعلی اشاره کند و TCP 80 از روتر به IP LAN رزروشدهٔ همین VM برسد.

**بررسی DNS عمومی — در Windows PowerShell، نه SSH:**

~~~powershell
$names = @("fc-node-01.fragcity.ir", "panel.fragcity.ir")

foreach ($name in $names) {
    Resolve-DnsName -Name $name -Type A -ErrorAction Continue |
        Select-Object Name, Type, IPAddress
    Resolve-DnsName -Name $name -Type A -Server 1.1.1.1 -DnsOnly -ErrorAction Continue |
        Select-Object Name, Type, IPAddress
}
~~~

پاسخ هر دو resolver را با IPv4 عمومی فعلی مقایسه کن. `getent ahostsv4` روی Debian ممکن است از نگاشت محلی `/etc/hosts` تأثیر بگیرد؛ برای تأیید DNS عمومی از بلوک PowerShell بالا استفاده کن. اگر مسیر DNS-over-HTTPS از Debian در دسترس نبود، به‌جای آن همین بررسی PowerShell را اجرا کن.

**صدور گواهی Node — در Debian، فقط وقتی DNS و Port Forward درست‌اند و گواهی Node هنوز وجود ندارد:**

~~~bash
sudo certbot certonly --nginx -d fc-node-01.fragcity.ir
~~~

**بررسی فایل‌ها و تمدید خودکار:**

~~~bash
set -eu
sudo test -s /etc/letsencrypt/live/panel.fragcity.ir/fullchain.pem
sudo test -s /etc/letsencrypt/live/panel.fragcity.ir/privkey.pem
sudo test -s /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem
sudo test -s /etc/letsencrypt/live/fc-node-01.fragcity.ir/privkey.pem
sudo openssl x509 -in /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem -noout -checkhost fc-node-01.fragcity.ir
sudo openssl x509 -in /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem -noout -checkend 0
sudo certbot renew --dry-run
~~~

اگر فایل گواهی Node وجود ندارد، به بخش صدور بالا برگرد. اگر فایل‌ها وجود دارند ولی Wings باز هم خطای TLS داد، مسیرهای گواهی را با تنظیمات Node تطبیق بده؛ فایل خالی نساز، symlink دستی ایجاد نکن و محتوای محرمانهٔ `/etc/pterodactyl/config.yml` را منتشر نکن.

منابع:
- https://certbot.eff.org/instructions?ws=nginx
- https://docs.pterodactyl.io/v1/guides/tutorials/ssl-certificates

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

این بلوک وضعیت سرویس‌های لایهٔ وب/دیتابیس را بررسی می‌کند:

~~~bash
(
echo "=== Core web/database services ==="
sudo systemctl is-active nginx mariadb redis-server php8.3-fpm

echo
echo "=== Listening sockets ==="
sudo ss -ltnup

echo
echo "=== Recent NGINX and PHP-FPM logs ==="
sudo journalctl -u nginx -n 80 --no-pager
sudo journalctl -u php8.3-fpm -n 80 --no-pager
)
~~~

**وضعیت Docker:** نصب Chapter 5 در همین VM انجام و تأیید شده است؛ سرویس فعال است و `docker run --rm hello-world` با موفقیت پایان یافته. اگر در بررسی بعدی Docker در دسترس نبود، این بلوک فقط‌خواندنی را اجرا کن:

~~~bash
(
echo "=== Docker packages ==="
dpkg-query -W -f='${binary:Package} ${Status}\\n' docker-ce docker-ce-cli containerd.io docker.io 2>/dev/null || true
echo
echo "=== Docker command ==="
command -v docker || true
echo
echo "=== Docker service ==="
sudo systemctl status docker --no-pager -l || true
)
~~~

پورت‌های Wings یعنی 8080 و SFTP یعنی 2022 تا پیش از نصب و پیکربندی Wings انتظار نمی‌روند. MariaDB روی `127.0.0.1:3306` و Redis روی `127.0.0.1:6379` باید محلی باقی بمانند؛ برای آن‌ها Port Forward عمومی نساز.

وجود باینری Wings به‌تنهایی به معنی ایجاد یا فعال‌بودن سرویس systemd نیست؛ وضعیت سرویس را فقط پس از مرحلهٔ ساخت سرویس بررسی کن.

### 4.3 اتصال Windows و تونل دیتابیس

**از دستور قدیمیِ دارای `<debian-user>` و `<node-lan-ip>` استفاده نکن.** برای VM فعلی، اتصال SSH باید کلید اختصاصی FragCity را معرفی کند. این دستور را در **Windows PowerShell** اجرا کن؛ نه در Bash دبیان:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$target = "sv1@192.168.1.7"

ssh -v -N `
  -o IdentitiesOnly=yes `
  -o PreferredAuthentications=publickey `
  -o PasswordAuthentication=no `
  -i $keyPath `
  -L 3307:127.0.0.1:3306 `
  $target
~~~

- اگر آدرس LAN رزروشدهٔ Node عوض شده است، پیش از اجرا `192.168.1.7` را با IP تأییدشدهٔ فعلی جایگزین کن؛ IP را حدس نزن.
- پنجرهٔ PowerShell را باز نگه دار تا تونل فعال بماند. در صورت درخواست، passphrase کلید SSH را وارد کن؛ هنگام تایپ نمایش داده نمی‌شود. برای بستن تونل، در همان پنجره `Ctrl+C` بزن.
- در پنجرهٔ دوم PowerShell، اتصال TCP محلی را بررسی کن:

~~~powershell
Test-NetConnection 127.0.0.1 -Port 3307
~~~

مقدار `TcpTestSucceeded : True` یعنی پورت محلی قابل اتصال است. سپس در کلاینت دیتابیس ویندوز وارد کن:

| فیلد | مقدار |
|---|---|
| Host | `127.0.0.1` |
| Port | `3307` |
| Database | `panel` |
| Username | `pterodactyl` |
| Password | رمز فعلی MariaDB که خودت تعیین کرده‌ای |

این تونل به MariaDB محلی Node هدایت می‌شود؛ لازم نیست و **نباید** پورت 3306 را در روتر باز کنی. رمز دیتابیس یا passphrase کلید SSH را در چت یا README ننویس.

---

## 5. Docker Engine — نصب روی Debian Console-only

**وضعیت:** نصب Docker Engine روی این Debian تکمیل و تأیید شده است. بلوک زیر به‌عنوان دستور تکرارپذیر برای نصب تازه حفظ می‌شود؛ در همین VM آن را دوباره اجرا نکن مگر پس از بررسی علت و نیاز واقعی.

**نکتهٔ امنیت شبکه:** مستندات رسمی Docker هشدار می‌دهند که پورت‌های container که Docker منتشر می‌کند، ممکن است قواعد معمول UFW را دور بزنند. پیش از انتشار پورت‌های Wings یا هر سرور بازی، طراحی Firewall/NAT را بازبینی می‌کنیم. فعلاً هیچ Container/instance بازی ایجاد نکن و پورت‌های بازی را در روتر باز نکن. مرجع رسمی: https://docs.docker.com/engine/install/debian/#firewall-limitations

این بلوک برای نصب تکرارپذیر روی Debian تازه است؛ روی همین VM نصب‌شده دوباره اجرا نکن.

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

**Checkpoint تأییدشده در VM فعلی:** نسخهٔ Docker برابر 29.9.1 گزارش شد، سرویس `docker` فعال بود، `docker info` بدون خطا پاسخ داد و `docker run --rm hello-world` موفق شد. فضای ریشه پس از آزمون حدود 253 GB آزاد داشت. لاگ کامل این آزمون در README ذخیره نمی‌شود.

---

## 6. Wings و Node — باینری نصب شده؛ اتصال هنوز انجام نشده

### 6.1 بررسی نسخهٔ Panel

پس از نصب Panel و ورود به آن، از این فرمان برای بررسی نسخه و پیکربندی عمومی استفاده کن. خروجی را در README قرار نده؛ ایمیل/شناسهٔ کاربر و هر مقدار حساس را نیز به چت نفرست.

~~~bash
cd /var/www/pterodactyl
sudo -u www-data php8.3 artisan p:info
~~~

**Checkpoint تأییدشده:** Panel برابر `1.15.1` و `Up-to-Date: Yes` گزارش شده، URL نصب `https://panel.fragcity.ir` است، Debug Mode خاموش است، و Driverهای cache/queue/session روی Redis و دیتابیس روی MariaDB تنظیم شده‌اند.

**کار با ایمیل نیاز به تکمیل دارد:** خروجی فعلی `p:info` هنوز `smtp.example.com` و `no-reply@example.com` را نشان می‌داد؛ این‌ها مقادیر نمونه‌اند. تا قبل از استفاده از ایمیل برای reset password، اعلان‌ها یا تأیید حساب، SMTP واقعی را به‌صورت جداگانه تنظیم و تست کن. رمز SMTP را در README یا چت ننویس. این مورد مانع آزمایش محلی Node نیست، اما برای production کامل نشده است.

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

**Checkpoint تأییدشده در VM فعلی:** باینری Wings نسخهٔ `1.13.4` نصب شده، executable لینوکسی x86-64 است و مالک/مجوز آن `root:root` با mode برابر `755` است. این فقط نصب باینری را تأیید می‌کند؛ فایل محرمانهٔ `/etc/pterodactyl/config.yml` هنوز از Panel تولید نشده، سرویس systemd مربوط به Wings هنوز ساخته/راه‌اندازی نشده و Node آنلاین نیست. بلوک نصب باینری را دوباره اجرا نکن.

### 6.3 پیش‌بررسی DNS/TLS و ساخت Node از مرورگر Windows

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

**پیش‌شرط مهم FQDN/TLS:** گواهی `panel.fragcity.ir` به‌تنهایی برای `fc-node-01.fragcity.ir` معتبر نیست. پیش از ساخت Node با SSL فعال:
- رکورد A عمومی هر دو دامنه را با Windows PowerShell طبق مرحلهٔ 3.7.2 بررسی کن.
- Port Forward مربوط به HTTP-01 را به IP LAN رزروشدهٔ Node هدایت کن.
- گواهی مستقل Node را طبق مرحلهٔ 3.7.2 صادر و مسیرهای `fullchain.pem` و `privkey.pem` را بررسی کن.

در مرورگر Windows، پس از آماده‌شدن DNS و گواهی معتبر Node:
1. وارد `https://panel.fragcity.ir` شو و مطمئن شو با حساب Administrator وارد شده‌ای. این مرحله فقط بعد از تنظیم DNS و گواهی TLS انجام می‌شود.
2. از **Admin → Locations** یک Location بساز یا Location موجود را انتخاب کن؛ مثلاً Short Code برابر `lan` و Description برابر `FragCity LAN`.
3. به **Admin → Nodes → Create New** برو.
4. در Identity: نام `fc-node-01`، توضیح اختیاری، و Location مرحلهٔ قبل را انتخاب کن.
5. در Network/Daemon: FQDN برابر `fc-node-01.fragcity.ir`، SSL فعال پس از صدور و نصب گواهی معتبر برای همین نام، Daemon Port برابر `8080` و Daemon SFTP Port برابر `2022` باشد. DNS عمومی باید به IP عمومی Node برسد و قبل از ساخت Node باید TLS و فایروال بررسی شده باشند. از IP خصوصی در FQDN عمومی استفاده نکن.
6. در بخش منابع، مقادیر Memory/Disk را بر اساس خروجی واقعی free -h و df -hT / تعیین کن. Overallocate را برای شروع 0 نگه دار و فضای کافی برای Debian، Docker و لاگ‌ها باقی بگذار. مقدار انتخاب‌شدهٔ فعلی برای این Node برابر 4096 MiB (4 GiB) است؛ این سقف مجموع RAM قابل‌تخصیص در Panel است، نه رزرو فیزیکی RAM و نه مقدار خودکار برای هر سرور.
7. اگر فیلد Server File Directory نمایش داده شد، فعلاً مقدار پیش‌فرض `/var/lib/pterodactyl/volumes` را حفظ کن. **آن را روی `/home/steam` تنظیم نکن**؛ طرح استفادهٔ مجدد از بازی موجود هنوز طراحی نشده است.
8. Node را ذخیره کن. سپس وارد صفحهٔ همان Node شو و نتیجهٔ ساخت را بررسی کن.

فعلاً Allocation برای سرور بازی نساز و هیچ سروری ایجاد نکن؛ ابتدا اتصال Wings را تأیید می‌کنیم و سپس Storage/Egg/Ports را جداگانه طراحی می‌کنیم.

### 6.4 تولید config محرمانه از خود Panel

فایل /etc/pterodactyl/config.yml به‌صورت خودکار هنگام نصب باینری Wings ساخته نمی‌شود. این فایل باید بعد از ساخت Node از فرمان Auto-Deploy خود Panel یا از محتوای تب Configuration ایجاد شود. در این مرحله روش Auto-Deploy را استفاده کن.

1. در مرورگر Windows وارد https://panel.fragcity.ir شو و به Admin → Nodes برو.
2. Node ساخته‌شدهٔ fc-node-01 را باز کن و وارد تب Configuration شو. اگر Node هنوز ذخیره نشده، ابتدا به مرحلهٔ 6.3 برگرد و آن را کامل بساز.
3. در بخش Auto-Deploy روی Generate Token بزن. Panel یک فرمان Bash تولید می‌کند که شامل آدرس Panel، token و Node ID واقعی است.
4. از Windows PowerShell یک نشست SSH تعاملی تازه باز کن:

~~~powershell
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519_fragcity"
$target = "sv1@192.168.1.7"

ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath $target
~~~

5. وقتی prompt شبیه sv1@fc-node-01:~$ دیدی، همان فرمانی را که Panel در Auto-Deploy نشان داده، کامل و بدون ویرایش در ترمینال SSH دبیان paste کن و اجرا کن. فرمان را در PowerShell ویندوز اجرا نکن و خودت token یا Node ID نساز.
6. token و فرمان تولیدشده را در چت، README، عکس یا لاگ عمومی نفرست. اگر command خروجی خطا داد، متن را پیش از ارسال بررسی کن و هر token یا secret را حذف کن.

پس از اجرای موفق فرمان Auto-Deploy، فقط وجود فایل و metadata آن را بررسی کن:

~~~bash
(
if sudo test -s /etc/pterodactyl/config.yml; then
  echo "OK: node config exists"
  sudo stat -c 'owner=%U:%G mode=%a size=%s path=%n' /etc/pterodactyl/config.yml
else
  echo "MISSING: Auto-Deploy has not created /etc/pterodactyl/config.yml"
fi
)
~~~

**اگر فایل هنوز وجود ندارد:** خودت با touch، nano یا tee فایل خالی نساز و به مراحل TLS/debug بعدی نرو. اول بررسی کن که Node در Panel ذخیره شده، Generate Token را زده‌ای، فرمان کامل را در نشست SSH دبیان اجرا کرده‌ای و خروجی آن موفق بوده است. بعد از قطع‌شدن SSH دوباره وصل شو و آزمون فقط‌خواندنی بالا را تکرار کن؛ قطع‌شدن اتصال به‌تنهایی علت را مشخص نمی‌کند.

اگر command از موجودبودن config خبر داد، گزینهٔ override را خودسرانه اضافه نکن؛ ابتدا وضعیت فایل و Node را بررسی کنیم. فایل config محرمانه است و نباید وارد Git یا چت شود.

منبع رسمی: https://docs.pterodactyl.io/v1/wings/installing

### 6.5 بررسی گواهی TLS مخصوص Node

پیش از اجرای Wings، مطمئن شو گواهی جداگانهٔ `fc-node-01.fragcity.ir` در مسیر مورد انتظار موجود و معتبر است. اگر گواهی وجود ندارد، مراحل صدور و بررسی را در **3.7.2** اجرا کن.

~~~bash
set -eu
sudo test -s /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem
sudo test -s /etc/letsencrypt/live/fc-node-01.fragcity.ir/privkey.pem
sudo openssl x509 -in /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem -noout -checkhost fc-node-01.fragcity.ir
sudo openssl x509 -in /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem -noout -checkend 0
~~~

### 6.6 اجرای آزمایشی Wings در foreground — تکمیل‌شده

این آزمون باید پیش از ساخت سرویس systemd انجام شود. پس از ساخته‌شدن Node، تولید `/etc/pterodactyl/config.yml` از Auto-Deploy و آماده‌شدن گواهی TLS، فرمان زیر را در SSH اجرا کن:

~~~bash
sudo wings --debug
~~~

اگر Wings بدون خطای `FATAL` اجرا شد و پایدار ماند، با `Ctrl+C` آن را به‌شکل کنترل‌شده متوقف کن و سپس به مرحلهٔ ساخت سرویس برو. در اجرای فعلی این آزمون پایدار ماند و با `Ctrl+C` متوقف شد.
### 6.7 سرویس دائمی systemd برای Wings — تکمیل‌شده

پس از موفقیت آزمون foreground، سرویس systemd را بساز تا Wings پس از reboot هم خودکار اجرا شود. بلوک نصب برای میزبان تازه مستند شده است؛ روی VM فعلی این مرحله اجرا شده و سرویس `wings` فعال و enable شده است. آن را بی‌دلیل دوباره اجرا نکن.

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
sudo systemctl is-active wings
sudo systemctl is-enabled wings
~~~

اگر سرویس بالا نمی‌آید، این فرمان‌های تشخیصی را فقط در همان زمان اجرا کن؛ خروجی آن‌ها را به README اضافه نکن:

~~~bash
sudo systemctl status wings --no-pager
sudo journalctl -u wings -n 100 --no-pager
sudo ss -ltnup | grep -E ':(8080|2022)\b' || true
~~~

پیش از انتشار عمومیِ پورت‌های Wings/SFTP، طراحی Firewall و Router/VMware NAT را جداگانه بررسی کن.


### 6.8 بازکردن Firewall و Port Forward برای Wings/SFTP — تکمیل‌شده

راه‌اندازی سرویس Wings و گواهی TLS به‌تنهایی برای اتصال عمومی کافی نبود؛ علت مشکل، نبودن Port Forward روتر به Node بود. با اجازه‌دادن TCP پورت‌های `8080` و `2022` در UFW و هدایت آن‌ها از روتر به IP رزروشدهٔ Node، ارتباط Node با پنل برقرار شد. این بخش را برای نصب‌های بعدی به‌صورت راهنمای تکرارپذیر نگه می‌داریم؛ خروجی ترمینال در README ثبت نمی‌شود.

#### 6.8.1 اجازهٔ ورودی در UFW — در Debian

~~~bash
sudo ufw allow 8080/tcp
sudo ufw allow 2022/tcp
sudo ufw status numbered
sudo ss -ltnp | grep -E ':(8080|2022)\b'
~~~

- TCP `8080`: Wings API با HTTPS؛ پنل و مرورگر برای ارتباط با Node از آن استفاده می‌کنند.
- TCP `2022`: SFTP برای دسترسی به فایل‌های سرور.
- این قوانین فقط فایروال Debian را تنظیم می‌کنند؛ به‌تنهایی Port Forward روتر ایجاد نمی‌کنند.

#### 6.8.2 Port Forward — در روتر

ابتدا IP فعلی Node را روی Debian با `ip -4 -br address` شناسایی کن و رزرو DHCP را در روتر تأیید کن. سپس دو قانون **TCP** بساز و مقصد را به همان IP رزروشده قرار بده:

| پورت ورودی WAN | IP مقصد LAN | پورت مقصد | پروتکل | کاربرد |
|---:|---|---:|---|---|
| 8080 | IP رزروشدهٔ Node | 8080 | TCP | Wings API / HTTPS |
| 2022 | IP رزروشدهٔ Node | 2022 | TCP | SFTP |

این پورت‌ها را به پنل مدیریت مودم هدایت نکن. برای این دو سرویس UDP لازم نیست. پورت‌های بازی را فعلاً باز نکن؛ آن‌ها پس از تعیین Allocationهای اولین Instance جداگانه طراحی می‌شوند. پورت‌های SSH `22`، MariaDB `3306` و Redis `6379` را برای دسترسی عمومی باز نکن.

#### 6.8.3 آزمون از بیرون شبکه و بررسی وضعیت Node — روش تأیید

برای تأیید پس از اعمال قوانین روتر، از دستگاهی خارج از LAN (مثلاً گوشی با Wi-Fi خاموش و دیتای موبایل روشن) مرورگر را به آدرس زیر ببر:

~~~text
https://fc-node-01.fragcity.ir:8080/
~~~

پاسخ `401 Unauthorized` با گواهی معتبر برای درخواست بدون ورود، به‌تنهایی خطا نیست و نشان می‌دهد endpoint پاسخ داده است. Timeout یا ناتوانی در اتصال، نیازمند بررسی IP مقصد، Port Forward، UFW و دسترسی WAN است. اگر اتصال عمومی موفق شد، صفحهٔ **Admin → Nodes → fc-node-01** را refresh کن و وضعیت Node را بررسی کن.

تست از داخل همان LAN ممکن است به‌دلیل نداشتن NAT loopback در روتر، نتیجهٔ گمراه‌کننده بدهد؛ برای سنجش Port Forward از شبکهٔ خارجی تست کن. راهنمای رسمی: https://docs.pterodactyl.io/v1/panel/troubleshooting

---

## 7. Storage و CS2/KUS — preflight پیش از اولین Instance

Wings و سرویس systemd راه‌اندازی شده‌اند. **فعلاً هیچ سرور CS2 نساز، هیچ Egg/Installer را اجرا نکن، فایل‌های `/home/steam` را جابه‌جا یا حذف نکن و پورت بازی را روی روتر باز نکن.** ابتدا باید وضعیت دیسک‌ها، فایل‌های موجود و محل ذخیره‌سازی Docker/Pterodactyl را فقط‌خواندنی بررسی کنیم.

سبک‌بودن Debian Console-only ممکن است سربار سیستم‌عامل را نسبت به Desktop کاهش دهد، اما به‌تنهایی تضمین نمی‌کند مشکل slow frame در CS2 برطرف شود. بعداً باید baseline سرور را با بار کنترل‌شده بسنجیم و مشخص کنیم slow frame به server timing اشاره دارد یا FPS/frametime کلاینت.

### 7.1 بررسی فضای ذخیره‌سازی — تکمیل‌شده

این مرحله فقط اطلاعات دیسک و مسیرهای موجود را می‌خواند؛ چیزی نصب، دانلود، پاک یا جابه‌جا نمی‌کند. در SSH دبیان اجرا کن:

~~~bash
set -u

echo "=== Root filesystem capacity and inode usage ==="
df -hT /
df -ih /

echo
echo "=== Important storage paths ==="
for path in \
  /home \
  /home/steam \
  /var/lib/docker \
  /var/lib/pterodactyl \
  /var/lib/pterodactyl/volumes \
  /var/lib/pterodactyl/archives \
  /var/lib/pterodactyl/backups
do
  echo
  echo "--- $path"
  if [ -e "$path" ]; then
    findmnt -T "$path" || true
    df -hT "$path" || true
    sudo du -sh "$path" 2>/dev/null || true
  else
    echo "Path does not exist yet."
  fi
done

echo
echo "=== Existing /home/steam directory layout (if present) ==="
if [ -d /home/steam ]; then
  sudo find /home/steam -maxdepth 2 -type d -print | head -n 60
else
  echo "/home/steam is not present on this installation."
fi

echo
echo "=== Docker storage location and usage ==="
sudo docker info --format 'DockerRootDir={{.DockerRootDir}}'
sudo docker system df
sudo docker ps -a --size

echo
echo "=== Pterodactyl volume directory names (if present) ==="
if [ -d /var/lib/pterodactyl/volumes ]; then
  sudo find /var/lib/pterodactyl/volumes -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
fi
~~~

**تفسیر نتایج:**
- `df -hT` ظرفیت کل/آزاد و نوع filesystem را نشان می‌دهد؛ `du -sh` میزان مصرف خود مسیر را نشان می‌دهد. این دو عدد مفهوم متفاوتی دارند.
- `findmnt -T /home/steam` روشن می‌کند فایل‌های احتمالی بازی روی کدام filesystem قرار گرفته‌اند.
- `docker system df` و `docker ps -a --size` کمک می‌کنند بفهمیم Docker از قبل فضایی مصرف کرده یا Container/Volume موجودی دارد.
- خروجی ترمینال را در README نگذار؛ فقط اگر لازم شد برای تحلیل در همین گفت‌وگو بفرست و هر مقدار حساس را حذف کن.

**نتیجهٔ بررسی فقط‌خواندنی:** روی Node فعلی هنوز `/home/steam`، مسیرهای Volume/Archive/Backup مربوط به سرورهای Pterodactyl و هیچ Container یا Docker Volume مربوط به سرور بازی وجود ندارد. این VM فعلاً Base Game را نصب نکرده است؛ از این وضعیت پاک به‌عنوان مبنای آزمایش استفاده کن. خروجی خام ترمینال یا لاگ به README اضافه نشود.

### 7.2 ممیزی اسکریپت‌های KUS و معماری Shared Base — تکمیل‌شده

مستند معماری FragCity: [CS2-MULTI-INSTANCE.md](https://github.com/larnzs/FragCity-RawPHPbackend/blob/main/docs/CS2-MULTI-INSTANCE.md).

**نتیجهٔ بررسی ریپوها:**

- [Dockerfile خود FragCity/KUS](https://github.com/larnzs/cs2-kus-addons/blob/integration/kus-monorepo/docker/Dockerfile)، [Compose](https://github.com/larnzs/cs2-kus-addons/blob/integration/kus-monorepo/docker/docker-compose.yml)، [install_docker.sh](https://github.com/larnzs/cs2-kus-addons/blob/integration/kus-monorepo/docker/install_docker.sh) و [update.sh](https://github.com/larnzs/cs2-kus-addons/blob/integration/kus-monorepo/docker/update.sh) برای مسیر فعلی تک‌سرورند. Compose یک container name ثابت و یک named volume به نام `cs2-volume` دارد. Volume باعث می‌شود نصب بازی بین اجرای مجدد همان deployment باقی بماند؛ ولی اگر هر Instance یک Volume مستقل بگیرد، نصب بازی در آن Volume تکرار می‌شود. اگر چند سرور یک Volume نوشتنی را با هم شریک شوند، تغییرات فایل و تنظیمات با هم تداخل می‌کنند.
- `install_docker.sh` بازی را با SteamCMD در مسیر پایدار `/home/steam/cs2` نصب/Update می‌کند و سپس payload ردیابی‌شده را روی درخت بازی overlay می‌کند. این اسکریپت یک provisioner برای Shared Base چندمشتری‌ای نیست و مستقیماً نباید به‌عنوان Egg هر Instance استفاده شود.
- [Compose اصلی KUS](https://github.com/kus/cs2-modded-server/blob/master/docker-compose.yml) نیز یک سرویس و یک Volume پایدار تعریف می‌کند؛ یادداشت Docker اصلی KUS می‌گوید Volume نصب بازی را بین اجراها حفظ می‌کند. این الگو جلوی دانلود دوباره در هر restart همان deployment را می‌گیرد، اما به‌تنهایی برای چند Instance مستقل با Base خواندنی مشترک کافی نیست.
- [Linux instance template](https://github.com/larnzs/cs2-kus-addons/tree/integration/kus-monorepo/linux/instances/instance-template) از `/home/steam/cs2` مشترک استفاده می‌کند و فایل‌های `CUSTOM_FOLDER/cfg` و `CUSTOM_FOLDER/addons` را پیش از Start به همان runtime کپی می‌کند. README خودش هشدار می‌دهد که این overlay فایل‌ها را بین دو سرور فعال ایزوله نمی‌کند؛ بنابراین برای چند مشتری هم‌زمان بدون اصلاح معماری استفاده نشود.
- Shared Base برای PoC در سند FragCity انتخاب شده، ولی مکانیزم اتصال Base و Volume خصوصی (mount، OverlayFS یا روش دیگر) هنوز پیاده‌سازی منتخب یا آزمایش‌شده نیست. این بخش هیچ‌یک از دو ریپوی KUS یا FragCity را تغییر نمی‌دهد.

**نامزدهای فنی برای PoC، نه تصمیم نهایی:**

- [Pterodactyl custom mounts](https://docs.pterodactyl.io/v1/guides/configuration/mounts) اجازه می‌دهد مسیر میزبان به Container mount شود؛ منبع باید در `allowed_mounts` مربوط به Wings مجاز شده و Mount نیز در Panel تنظیم شود. محدودیت مهم: Mountهای سفارشی در File Manager و SFTP نمایش داده نمی‌شوند. پس به‌تنهایی ممکن است نیاز File Manager مشتری به فایل‌های خصوصی را برآورده نکنند.
- [Linux OverlayFS](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html) امکان ترکیب lower/upper را دارد، اما upper و work باید روی یک filesystem باشند و رفتار copy-up/delete/whiteout باید در آزمون واقعی سنجیده شود. این فقط نامزد آزمایش است، نه روش انتخاب‌شده.

**ممنوعیت تا پایان PoC:** اسکریپت‌های `docker/update.sh`، `docker/install_docker.sh`، `linux/install.sh` یا هر Egg مربوط به نصب CS2 را روی Node اصلی اجرا نکن. هیچ payloadی از `game/csgo` را روی Base مرکزی copy/merge نکن و از runtime مشترک نوشتنی برای دو Instance استفاده نکن.

### 7.3 آماده‌سازی کپی آزمایشگاهی و VMDK دوم — گام جاری

راهنمای مستقل Clone و دیسک: [test-vmdk instructions.md](https://github.com/larnzs/linux-node/blob/main/test-vmdk%20instructions.md). فصل جاری برای Egg/ساخت سرور: [server-creation instruction.md](https://github.com/larnzs/linux-node/blob/main/server-creation%20instruction.md).
کد کامل اسکریپت جامع سلامت فقط‌خواندنی در بخش 10 فایل test-vmdk instructions.md است؛ نیازی به دانلود فایل جداگانه نیست. شبکه و پنل طبق تأیید کاربر عملیاتی‌اند. این اسکریپت فقط وضعیت VM را بررسی می‌کند و دیسک داده یا Shared Base را آماده نمی‌سازد.

**تصمیم مهم در این فاز:** Clone فعلی قرار است موقتاً جای VM اصلی را بگیرد؛ این یک Node دوم برای اجرای هم‌زمان نیست. تا پایان تست، VM اصلی باید کاملاً خاموش بماند و فقط Clone روشن باشد. بنابراین باید Panel، دیتابیس، Nginx، PHP-FPM، Redis، گواهی‌ها و تنظیمات موجود Wings در Clone حفظ شوند. **اسکریپت قبلی که این سرویس‌ها را disable می‌کرد یا machine-id و SSH host keys را بازتولید می‌کرد برای این مدل استفاده نشود.**

#### 7.3.1 استفاده از Full Clone به‌عنوان جایگزین موقت

1. Full Clone در VMware ساخته شده و در بوت اول گزینهٔ **I Copied It** انتخاب شده است. راهنمای Broadcom: https://knowledge.broadcom.com/external/article/310359/copy-workstation-virtual-machine-from-on.html
2. VMware برای Clone، MAC جدید ساخته و DHCP فعلاً IP **192.168.1.9** داده است. IP اصلی **192.168.1.7** باقی می‌ماند؛ در مودم برای MAC کلون DHCP reservation برابر 192.168.1.9 ثبت کن.
3. hostname در Clone به fc-node-01 برگردانده شده و /etc/hosts نیز به نام اصلی اشاره می‌کند. هشدار ابتدایی sudo مبنی بر unable to resolve host fc-node-01-test پیش از اصلاح hosts ظاهر شد؛ با getent hosts fc-node-01 و sudo -v وضعیت نهایی را تأیید کن.
4. مقصد قوانین **موجود** Port Forward برای TCP 80/443، TCP 8080 و TCP 2022 برای زمان تست به Clone با IP `192.168.1.9` تنظیم شده بود. طبق تأیید کاربر در 2026-10-18، شبکه و پنل عملیاتی هستند؛ برای این مرحله، بررسی دسترسی و Port Forward را تکمیل‌شده در نظر می‌گیریم. قانون تکراری با پورت عمومی یکسان نساز. DNS عمومی نیاز به تغییر ندارد، مگر IPv4 عمومی WAN تغییر کرده باشد.
5. Nginx، PHP 8.3-FPM، MariaDB و Redis روی Clone فعال گزارش شده‌اند؛ Wings نیز قبلاً با `sudo systemctl enable --now wings` فعال/اجرا شده است. طبق تأیید کاربر در 2026-10-18، پنل بالا می‌آید و شبکه عملیاتی است؛ این مرحله از بررسی شبکه و دسترسی پنل تکمیل‌شده محسوب می‌شود. اگر بعداً Node به Offline تغییر کرد، قبل از دست‌کاری `config.yml`، مقصد Port Forward TCP 8080 و لاگ اخیر Wings را بررسی کن.
6. تصمیم به‌روزشده در 2026-10-19: ابتدا طبق فصل [server-creation instruction.md](https://github.com/larnzs/linux-node/blob/main/server-creation%20instruction.md) فقط یک Instance پایه با Egg رسمی CS2-Egg-Go و بدون Node daemon آزمایش می‌شود؛ نخستین Start می‌تواند تا حدود 40 GB داخل Volume عادی Pterodactyl دانلود کند، پس فضای آزاد را پیش از Start بررسی کن. این گام به معنی آماده‌شدن Shared Base نیست. نصب cs2node/VPK sync، انتقال مسیر `/srv/cs2-shared` و اجرای چند Instance تا شناسایی و mount ایمن VMDK دادهٔ دوم انجام نمی‌شوند. هیچ اسکریپت KUS را اجرا نکن.
7. بازگشت به VM اصلی: خاموش‌کردن کامل Clone، برگرداندن مقصدهای Port Forward از 192.168.1.9 به 192.168.1.7، و فقط سپس روشن‌کردن VM اصلی. **دو VM هرگز هم‌زمان روشن نشوند.**

**آخرین health check کاملِ اولیه (2026-10-18):** 24 PASS / 1 WARN / 0 FAIL. Nginx، PHP-FPM، MariaDB، Redis، Docker و Wings فعال‌اند؛ Nginx test و HTTPS محلی Panel موفق بود و پورت‌های TCP موردنیاز LISTEN بودند. در ادامه، مرحلهٔ 3.4.1 برای Queue Worker و Scheduler روی Clone با IP `192.168.1.9` با موفقیت اجرا و تأیید شد: `pteroq.service` برابر `enabled` و `active (running)` است و ورودی `schedule:run` در crontab ریشه وجود دارد. طبق تأیید کاربر در 2026-10-18، شبکه و پنل از مسیر موردنظر عملیاتی‌اند؛ تأیید دستی Port Forward/دسترسی پنل برای این مرحله تکمیل‌شده ثبت می‌شود. Queue Worker و Scheduler هنوز باید جداگانه روی VMDK اصلی اعمال شوند. UFW قانون `29001/udp` را برای CS2 آینده باز نگه می‌دارد و نباید تغییر کند.

#### 7.3.2 محدودهٔ اولین آزمون

طبق راهنمای رسمی K4ryuu، اولین گام اکنون یک سرور CS2-Egg-Go به‌صورت standalone و بدون Node daemon است تا نصب فایل‌های بازی، راه‌اندازی Source 2، اتصال Client، Console و Stop/Start در یک Instance آزمایش شود. راهنمای مرحله‌به‌مرحله در [server-creation instruction.md](https://github.com/larnzs/linux-node/blob/main/server-creation%20instruction.md) قرار دارد.

این تست اولیه می‌تواند حدود 40 GB از Volume سرور در Storage فعلی مصرف کند؛ قبل از Start فضای آزاد را بررسی کن. پس از قبولی این تست، VMDK داده فقط به Clone اضافه و شناسایی می‌شود؛ سپس مسیر Storage مشترک آماده و cs2node/VPK sync آزمایش می‌شود. هنوز Instance دوم، Shared Base، Update خودکار Base یا Production اجرا نمی‌شود.

#### 7.3.3 افزودن VMDK داده فقط به Clone

1. پیش از انتخاب ظرفیت، فضای آزاد واقعی روی درایو Windows میزبان را بررسی کن. آخرین بررسی حدود 301.8 GB فضای آزاد روی D نشان داد؛ قبل از عملیات سنگین دوباره بررسی کن.
2. در VMware یک virtual hard disk کاملاً جدید فقط به **Clone** اضافه کن؛ فایل VMDK اصلی یا دیسک موجود را به‌عنوان دیسک جدید انتخاب نکن.
3. پس از بوت Clone، فقط با این فرمان‌ها دستگاه‌ها را بخوان:

~~~bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
sudo blkid
~~~

4. دیسک تازه را با اندازه، نوع، filesystem و mountpoint شناسایی کن. **فرمت، partitioning یا mount نکن** تا نام دستگاه و جدا بودن آن از دیسک سیستم با خروجی بررسی و صریحاً تأیید شود.
5. پس از تأیید دیسک جدید، filesystem و mount دائمی مخصوص Base/دادهٔ بازی طراحی می‌شود. مسیر نهایی و فرمان‌های mkfs یا /etc/fstab قبل از شناسایی دقیق دستگاه نوشته/اجرا نمی‌شوند.

**قدم فعلی:** Import کردن Egg رسمی طبق فصل جدید و آماده‌کردن یک سرور آزمایشی روی Clone. VM اصلی و ریپوی KUS دست‌نخورده می‌مانند؛ VMDK داده و Shared Base همچنان گام‌های بعدی‌اند.

### 7.4 تصمیم Storage — پس از بررسی 7.3

پس از آماده‌شدن VM آزمایشگاهی و VMDK، قبل از نصب Base این موارد را مشخص می‌کنیم:
1. مسیر و filesystem نهایی Base مرکزی و SteamCMD.
2. روش read-only اشتراک Base و پوشه‌های خصوصی هر Instance.
3. سازگاری Egg/Startup با CS2 واقعی، نه صرفاً Egg قدیمی CS:GO.
4. Backup/Restore و رفتار حذف/Reinstall یک Instance.
5. فضای لازم برای Base، نقشه‌ها/Workshop، addons، logها و backup.

### 7.5 اولین سرور آزمایشی — پس از قبولی طراحی Storage

فقط پس از تأیید Storage، سازگاری Egg، CPU/RAM/disk و طراحی Allocation/Firewall یک Instance آزمایشی کم‌بار می‌سازیم. سپس Start/Stop/Console/Files/SFTP، جدایی داده‌ها و baseline عملکرد را بررسی می‌کنیم. افزونه‌ها و نقشه‌ها باید مرحله‌ای اضافه شوند تا اثر هر تغییر قابل‌اندازه‌گیری باشد.

تا تکمیل مراحل قبل، هیچ Instance جدیدی روی Node اصلی نساز و به `/home/steam` دست نزن.



پس از دیدن وضعیت واقعی، قبل از ایجاد Instance این موارد را مشخص می‌کنیم:
1. آیا `/home/steam` واقعاً وجود دارد و حاوی فایل‌های بازی موردنیاز KUS است؟
2. آیا فایل‌های آن متعلق به همین نصب Debian هستند یا در دیسک/پشتیبان جدا قرار دارند؟
3. Egg انتخابی واقعاً CS2 نصب می‌کند یا Egg قدیمی CS:GO است؟
4. آیا می‌توان محتوای موجود را ایمن استفاده کرد، یا هر Container به نصب مستقل نیاز دارد؟ فایل‌های host را به مسیر Volume نسبت ندهیم مگر مدل mount و مالکیت آن دقیقاً مشخص شده باشد.
5. ظرفیت لازم برای فایل بازی، هر Instance، نقشه‌ها، افزونه‌ها، لاگ‌ها و backup چقدر است؟

### 7.3 اولین سرور آزمایشی — هنوز مجاز به اجرا نیست

فقط پس از تأیید Storage، سازگاری Egg با CS2، محدودیت CPU/RAM/disk و طراحی Allocation/Firewall یک Instance آزمایشی کم‌بار می‌سازیم. سپس Start/Stop/Console/Files/SFTP، جدایی داده‌ها و baseline عملکرد را بررسی می‌کنیم. افزونه‌ها و نقشه‌ها باید مرحله‌ای اضافه شوند تا اثر هر تغییر قابل‌اندازه‌گیری باشد.

تا تکمیل مراحل قبل، هیچ Instance جدید نساز و به `/home/steam` دست نزن.


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
| مرحلهٔ جاری | Clone با IP `192.168.1.9` و hostname `fc-node-01` health check اولیهٔ 24 PASS / 1 WARN / 0 FAIL گرفت. Queue Worker و Scheduler طبق مرحلهٔ 3.4.1 با موفقیت روی Clone تأیید شدند (`pteroq.service` فعال/enabled؛ ورودی `schedule:run` در crontab ریشه وجود دارد). طبق تأیید کاربر در 2026-10-18، شبکه و پنل عملیاتی‌اند و بررسی شبکه/دسترسی برای این مرحله تکمیل‌شده است. Queue Worker/Scheduler هنوز باید جداگانه روی VMDK اصلی اجرا شوند. UFW پورت `29001/udp` برای CS2 آینده باز می‌ماند؛ تغییر نده. اکنون VMDK دادهٔ جدید را فقط به Clone اضافه کن و پیش از هر گونه فرمت، آن را با `lsblk` و `blkid` شناسایی کن. |
| مراحل پایه | 1.9–1.21 بررسی‌شده؛ inodeها 1% مصرف دارند؛ Snapshot 1.22 با نام `debian13-base-ready` طبق گزارش کاربر گرفته شده |
| Hostname | `fc-node-01` |
| Domain name / FQDN | `fragcity.ir` و `fc-node-01.fragcity.ir` |
| IP LAN / رزرو DHCP | Node اصلی 192.168.1.7؛ Clone فعلی 192.168.1.9 به دلیل MAC جدید. برای تست Clone، Port Forwardهای فعلی را به .9 تغییر بده و DHCP reservation بساز؛ برای بازگشت، Clone را خاموش و مقصدها را به .7 برگردان. |
| Panel FQDN هدف | `panel.fragcity.ir` |
| DNS / public IP | پیش از صدور/تمدید گواهی و پس از هر تغییر WAN، رکوردهای عمومی را طبق مرحلهٔ 3.7.2 با IPv4 فعلی تطبیق بده |
| SSH hardening | سرویس فعال، پیکربندی sshd معتبر، ورود root و احراز هویت با رمز غیرفعال، احراز هویت کلیدی فعال، و ورود واقعی از پنجرهٔ تازهٔ Windows PowerShell موفق است. |
| Firewall UFW | فعال؛ ورودی پیش‌فرض مسدود، خروجی مجاز، SSH محدود به LAN `192.168.1.0/24` و TCP پورت‌های 80/443 مجاز است. |
| Panel / Docker / Wings | Panel روی HTTPS تنظیم شده؛ Docker فعال است؛ `config.yml` از Auto-Deploy تولید شده؛ Wings از آزمون foreground عبور کرده و سرویس systemd فعال/enable است. اتصال Node با Port Forward و قوانین UFW برقرار شده است. لاگ systemd اخیر Wings و Docker هشدار/خطای جدید نشان نداد؛ پیام‌های قدیمی TLS مربوط به قبل از آماده‌شدن گواهی‌اند. SMTP باید پیش از Production تنظیم شود. |
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
