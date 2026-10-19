# راهنمای آموزشی Full Clone و VMDK در VMware Workstation

این راهنما نحوهٔ ساخت Full Clone آزمایشی از یک Debian Node موجود، تست شبکه و Wings، افزودن دیسک مجزا به Clone و بازگشت امن به VM اصلی را آموزش می‌دهد.

**قانون ایمنی:** همهٔ تغییراتی که در این سند برای Clone نوشته شده‌اند فقط روی Clone اجرا می‌شوند. VM اصلی و Clone با هویت مشترک نباید هم‌زمان روشن باشند. قبل از Partition/Format/Mount هر دیسک، هویت آن را از روی lsblk و blkid تأیید کن؛ هیچ‌وقت اسم /dev/sdb یا هر دستگاه دیگری را حدس نزن.

این سند شامل مقادیر مرجع FragCity است. اگر از آن برای محیط دیگری استفاده می‌کنی، ابتدا جدول بخش 1 را با مقادیر واقعی خودت تنظیم کن؛ نام دامنه، IP، نام VM، پورت‌ها و مسیر VMX باید با محیط تو سازگار باشند. راهنمای CS2/cs2node در فایل اختصاصی K4ryuu قرار دارد و در این سند فقط به آن ارجاع داده می‌شود.

## 1. مقادیر محیطی و شناسایی VM اصلی

قبل از Clone این موارد را از VMware، Debian و روتر یادداشت کن. ستون آخر نمونهٔ فعلی FragCity است؛ اگر محیط دیگری داری، فقط از مقادیر واقعی خودت استفاده کن.

| مورد | روش شناسایی | نمونهٔ FragCity |
|---|---|---|
| فایل VMX اصلی | VM Settings / Open VM directory در VMware | زیر %USERPROFILE%\\Documents\\Virtual Machines\\... |
| محل فایل VMDK اصلی | از فایل VMX و مسیر Hard Disk در تنظیمات VMware | یک مسیر اختصاصی روی درایو D |
| نام Clone | نام یکتا در VMware | fc-node-01-clone |
| محل Clone | پوشهٔ جدا از VM اصلی با فضای آزاد کافی | D:\\FragCity-VMs\\fc-node-01-clone\\ |
| Hostname مورد انتظار Node | نامی که در سرویس‌ها و DNS فعلی تنظیم شده | fc-node-01 |
| IP داخلی VM اصلی | DHCP reservation و IP داخل Debian | 192.168.1.7 |
| IP داخلی Clone | DHCP reservation برای MAC جدید Clone | 192.168.1.9 |
| Node FQDN | DNS و TLS موجود | fc-node-01.fragcity.ir |
| دیسک دادهٔ جدید | ابتدا در VMware اضافه شود، سپس داخل Debian شناسایی شود | هنوز اختیاری/اضافه‌نشده |

**پیش از ادامه:** مشخص کن هدفت کدام است:
- **Clone موقت جایگزین اصلی:** VM اصلی خاموش می‌ماند؛ Clone هویت سرویس‌های اصلی را نگه می‌دارد و مقصد Port Forward موقتاً به IP Clone می‌رود.
- **Node دوم مستقل:** نباید هویت‌های Panel/Wings، Hostname، DNS، Tokenها یا آدرس‌های سرویس‌های اصلی کپی و هم‌زمان استفاده شوند؛ این سناریو طراحی جداگانه می‌خواهد و دستورالعمل جایگزینی موقت این سند را عیناً اجرا نکن.

فایل VMDK را دستی از Explorer کپی نکن؛ VMware را برای ساخت Full Clone به‌کار ببر. اندازهٔ فایل VMDK روی میزبان لزوماً ظرفیت مجازی آن نیست.

## 2. پیش‌بررسی فضای میزبان Windows

این دستور در Windows PowerShell فضای آزاد هر درایو را نشان می‌دهد:

~~~powershell
Get-PSDrive -PSProvider FileSystem |
    Select-Object Name, Root,
        @{Name='FreeGB'; Expression={[math]::Round($_.Free / 1GB, 1)}},
        @{Name='UsedGB'; Expression={[math]::Round($_.Used / 1GB, 1)}}
~~~

پیش از ساخت Full Clone، فضای آزاد واقعی درایوی را که مقصد Clone و VMDK داده روی آن قرار می‌گیرند بررسی کن. برای دیسک‌های thin/growable، فضای مصرفی فعلی VMDK در Explorer با ظرفیت مجازی آن برابر نیست؛ فضای آزاد میزبان باید برای رشد آینده کافی باشد.

برای پیدا کردن فایل‌های مرتبط در ریشهٔ D:

~~~powershell
Get-ChildItem D:\ -Force |
    Where-Object {
        $_.Name -like '*Debian 13*' -or
        $_.Extension -in '.vmx', '.vmdk', '.nvram', '.vmxf', '.vmsd', '.vmsn'
    } |
    Select-Object Mode, Name,
        @{Name='SizeGB'; Expression={
            if ($_.PSIsContainer) { '<DIR>' }
            else { [math]::Round($_.Length / 1GB, 2) }
        }},
        FullName |
    Format-Table -AutoSize
~~~

فایل تنظیمات .vmx در این نصب روی C قرار دارد و فایل VMDK در D؛ بنابراین از Explorer فقط فایل VMDK را کپی نکن. از قابلیت Full Clone خود VMware استفاده کن.

## 3. خاموش‌کردن تمیز VM اصلی

این مرحله فقط هنگام آماده‌سازی اولیهٔ Clone انجام می‌شود. از SSH متصل به **VM اصلی**، در زمان مناسب اجرا کن:

~~~bash
sudo systemctl poweroff
~~~

اتصال SSH قطع می‌شود؛ این طبیعی است. در VMware وضعیت ماشین را بررسی کن و فقط وقتی ادامه بده که دقیقاً **Powered Off** است، نه Suspended.

- VMDK در حالت Running یا Suspended کپی نشود.
- هیچ فایل اصلی را rename، move یا delete نکن.
- پوشهٔ .lck را دستی پاک نکن؛ VMware خودش وضعیت قفل را مدیریت می‌کند.

اگر Clone قبلاً ساخته شده و ماشین اصلی دوباره در حال اجراست، برای ادامهٔ آماده‌سازی لازم نیست بی‌دلیل ماشین اصلی را دوباره خاموش کنی.

## 4. ایجاد Full Clone در VMware Workstation

در VMware Workstation:

1. VM اصلی **Debian 13.x 64 bit cmd** را انتخاب کن.
2. از مسیر **VM → Manage → Clone** وارد Clone Wizard شو.
3. در منبع، **The current state in the virtual machine** را انتخاب کن.
4. در نوع Clone، حتماً **Create a full clone** را انتخاب کن؛ **Linked Clone** مناسب این آزمون نیست، چون به دیسک مبدأ وابسته می‌ماند.
5. نام Clone را یکتا انتخاب کن؛ برای محیط مرجع این ریپو، **fc-node-01-clone** است.
6. محل را **D:\FragCity-VMs** انتخاب کن. اگر پوشه وجود ندارد، ابتدا آن را در File Explorer ایجاد کن. فایل‌های Clone باید زیر پوشهٔ مستقل خودشان باشند.
7. تنظیمات را بازبینی کن و **Finish** را بزن. منتظر پایان کامل Clone بمان.

Full Clone باید تمام دیسک‌ها و تنظیمات لازم VM را در نسخهٔ مستقل کپی کند. پس از ساخت، فایل‌های VM اصلی و Clone را از هم جدا نگه دار.

## 5. اولین بوت و هدف این Clone

در اولین بوت، Network Adapter را قطع کن و اگر VMware پرسید، گزینهٔ **I Copied It** را انتخاب کن. بعد از اینکه Debian بالا آمد، شبکه را دوباره متصل کن و برای MAC جدید Clone یک DHCP reservation اختصاصی بساز. در نمونهٔ FragCity، IP آن 192.168.1.9 است؛ برای محیط خودت IP ثبت‌شده در جدول بخش 1 را استفاده کن.

**تصمیم این سناریو:** این Clone یک Node آزمایشی تازه و مستقل در Pterodactyl نیست؛ قرار است موقتاً جای VM اصلی را بگیرد. تا پایان تست، VM اصلی کاملاً خاموش می‌ماند و فقط Clone روشن خواهد بود. بنابراین باید همان Panel، پایگاه‌داده، تنظیمات Wings، Nginx، PHP-FPM، MariaDB، Redis و گواهی‌های فعلی در Clone کار کنند.

**اسکریپت قبلی که Wings، Nginx، PHP-FPM، MariaDB، Redis، Certbot و cron را disable می‌کرد اجرا نکن.** برای این سناریو هم machine-id و SSH host keys را بازتولید نکن؛ چون Clone موقتاً جایگزین همان VM است، نه Node دومی که هم‌زمان اجرا شود. MAC و IP جدید به‌خودی‌خود مشکلی ایجاد نمی‌کنند.

## 6. قوانین ایمنی تا پایان تست

1. VM اصلی روشن نشود؛ هیچ‌وقت دو کپی را هم‌زمان روشن نکن.
2. در نمونهٔ FragCity، 192.168.1.9 آدرس Clone و 192.168.1.7 آدرس اصلی است؛ در محیط دیگر فقط آدرس‌های تأییدشده در جدول بخش 1 را استفاده کن.
3. تنظیمات Panel و Wings در Clone را نگه می‌داریم؛ فقط hostname را به مقدار اصلی برمی‌گردانیم و Wings را پس از اصلاح Port Forwardها دوباره فعال می‌کنیم.
4. DNS عمومی و گواهی‌های فعلی را تغییر نده، مگر اینکه IP عمومی WAN واقعاً عوض شده باشد.
5. Port Forwardهای موجود را duplicate نکن. در زمان استفاده از Clone، مقصد قوانین مربوط به این VM را از IP اصلی به IP Clone تغییر بده؛ در پایان تست مقصدها را برگردان. از جدول مقادیر بخش 1 استفاده کن.
6. برای این مرحله فقط پورت‌های فعلی را مدیریت کن: TCP 80/443 برای Panel، TCP 8080 برای Wings API، TCP 2022 برای SFTP. چون هنوز CS2 Instance نداریم، پورت بازی اضافه نکن.
7. برای MAC جدید Clone در روتر DHCP reservation بساز؛ IP باید با جدول بخش 1 و قواعد شبکهٔ خودت سازگار باشد.

## 7. تنظیم Hostname برای سناریوی Clone جایگزین

این بخش فقط وقتی کاربرد دارد که **Clone موقتاً جای VM اصلی را می‌گیرد** و VM اصلی خاموش خواهد ماند. اگر Node مستقل دوم می‌سازی، این بخش را اجرا نکن؛ Node مستقل باید Hostname، FQDN، TLS و هویت Wings اختصاصی خودش را داشته باشد.

### 7.1 مقادیر را برای نصب خودت مشخص کن

مقادیر زیر نمونهٔ FragCity هستند؛ پیش از اجرای اسکریپت آن‌ها را با مقادیر واقعی جدول بخش 1 هماهنگ کن.

~~~bash
TARGET_IP="192.168.1.9"                     # IP فعلی Clone
TARGET_HOST="fc-node-01"                    # Hostname نهایی
TARGET_FQDN="fc-node-01.fragcity.ir"        # FQDN نهایی
CLONE_OLD_HOST="fc-node-01-test"             # Hostname موقتی Clone
CLONE_OLD_FQDN="fc-node-01-test.fragcity.ir" # FQDN قبلی، اگر در /etc/hosts وجود دارد

printf 'Clone IP: %s\nTarget hostname: %s\nTarget FQDN: %s\n' \
  "$TARGET_IP" "$TARGET_HOST" "$TARGET_FQDN"
echo
hostnamectl --static
ip -o -4 address show
grep -nE '127[.]0[.]1[.]1|fc-node|test' /etc/hosts || true
~~~

مطمئن شو IP نشان‌داده‌شده متعلق به Clone است و VM اصلی خاموش است. اگر مقدارها با محیط تو مطابقت ندارند، آن‌ها را اصلاح کن و تا آن زمان چیزی را تغییر نده.

### 7.2 پشتیبان‌گیری و تغییر کنترل‌شدهٔ Hostname

اسکریپت بعدی:
- IP را پیش از تغییر بررسی می‌کند.
- فقط Hostnameهای مورد انتظار را می‌پذیرد.
- از فایل‌های /etc/hostname و /etc/hosts نسخهٔ پشتیبان root-only می‌سازد.
- hostnamectl را اجرا می‌کند و Aliasهای 127.0.1.1 را برای Hostname/FQDN نهایی تنظیم می‌کند.
- هیچ سرویس، IP شبکه، machine-id، SSH host key یا Wings config را تغییر نمی‌دهد.

**پیش از اجرا، متغیرهای ابتدای بلوک را با مقادیر تأییدشدهٔ بخش 7.1 هماهنگ کن.**

~~~bash
sudo bash <<'SCRIPT'
set -Eeuo pipefail

TARGET_IP="192.168.1.9"
TARGET_HOST="fc-node-01"
TARGET_FQDN="fc-node-01.fragcity.ir"
CLONE_OLD_HOST="fc-node-01-test"
CLONE_OLD_FQDN="fc-node-01-test.fragcity.ir"

if ! ip -o -4 address show |
     awk '{split($4,a,"/"); print a[1]}' |
     grep -Fxq "$TARGET_IP"; then
    echo "ERROR: this machine does not currently have IP $TARGET_IP."
    echo "Nothing changed. Check that this is the intended Clone."
    exit 1
fi

CURRENT_HOST="$(hostnamectl --static)"
if [[ "$CURRENT_HOST" != "$CLONE_OLD_HOST" &&
      "$CURRENT_HOST" != "$TARGET_HOST" ]]; then
    echo "ERROR: unexpected hostname: $CURRENT_HOST"
    echo "Nothing changed."
    exit 1
fi

echo "Clone IP: $TARGET_IP"
echo "Current hostname: $CURRENT_HOST"
echo "Target hostname: $TARGET_HOST"
echo "Target FQDN: $TARGET_FQDN"
echo "Keep the original VM powered off."
read -r -p "Type ACTIVATE-CLONE to continue: " confirmation </dev/tty

if [[ "$confirmation" != "ACTIVATE-CLONE" ]]; then
    echo "Cancelled. No changes made."
    exit 1
fi

BACKUP="/root/clone-hostname-backup-$(date +%Y%m%d-%H%M%S)"
install -d -m 700 "$BACKUP"
cp -a /etc/hostname /etc/hosts "$BACKUP/"
chmod -R go-rwx "$BACKUP"

export TARGET_HOST TARGET_FQDN CLONE_OLD_HOST CLONE_OLD_FQDN
hostnamectl set-hostname "$TARGET_HOST"

python3 <<'PY'
import os
from pathlib import Path

target_host = os.environ["TARGET_HOST"]
target_fqdn = os.environ["TARGET_FQDN"]
old_host = os.environ["CLONE_OLD_HOST"]
old_fqdn = os.environ["CLONE_OLD_FQDN"]
old_names = {old_host, old_fqdn}
target_names = [target_host, target_fqdn]

path = Path("/etc/hosts")
lines = path.read_text().splitlines()
output = []
found_local = False

for line in lines:
    body, marker, comment = line.partition("#")
    fields = body.split()
    if not fields or line.lstrip().startswith("#"):
        output.append(line)
        continue

    if fields[0] == "127.0.1.1":
        aliases = [name for name in fields[1:] if name not in old_names]
        for name in target_names:
            if name not in aliases:
                aliases.append(name)
        output.append(fields[0] + "\t" + " ".join(dict.fromkeys(aliases)) +
                      ((" #" + comment) if marker else ""))
        found_local = True
        continue

    changed = False
    new_fields = fields[:]
    for i in range(1, len(new_fields)):
        if new_fields[i] == old_host:
            new_fields[i] = target_host
            changed = True
        elif new_fields[i] == old_fqdn:
            new_fields[i] = target_fqdn
            changed = True
    output.append("\t".join(new_fields) + ((" #" + comment) if marker else "")
                  if changed else line)

if not found_local:
    output.append("127.0.1.1\t" + " ".join(target_names))

path.write_text("\n".join(output) + "\n")
PY

echo
echo "=== Result ==="
hostnamectl --static
cat /etc/hostname
grep -n '127.0.1.1' /etc/hosts || true
getent hosts "$TARGET_HOST" || true
getent hosts "$TARGET_FQDN" || true

echo
echo "Backup directory: $BACKUP"
echo "No services were started or stopped."
SCRIPT
~~~

برای محیط دیگر، مقدارهای TARGET_IP، TARGET_HOST، TARGET_FQDN، CLONE_OLD_HOST و CLONE_OLD_FQDN داخل بلوک را حتماً تغییر بده. اگر Clone از ابتدا Hostname درست دارد و سرویس‌ها با همان Hostname ساخته شده‌اند، این تغییر را بی‌دلیل اجرا نکن.

## 8. تغییر Port Forwardها برای استفاده از Clone

در روتر، در حالی که VM اصلی خاموش است، قوانین موجود را ویرایش کن. جدول زیر نمونهٔ FragCity است؛ در محیط دیگر از IPهای تأییدشدهٔ بخش 1 و مقصدهای واقعی روترت استفاده کن.

| پورت ورودی | پروتکل | مقصد قبلی در نمونه | مقصد Clone در نمونه |
|---|---|---|---|
| 80 | TCP | 192.168.1.7 | 192.168.1.9 |
| 443 | TCP | 192.168.1.7 | 192.168.1.9 |
| 8080 | TCP | 192.168.1.7 | 192.168.1.9 |
| 2022 | TCP | 192.168.1.7 | 192.168.1.9 |

قبل از تغییر، جدول واقعی روتر را ببین و فقط قوانین همین سرویس‌ها را ویرایش کن. قوانین مربوط به میزبان دیگر را تغییر نده و Rule تکراری برای همان پورت عمومی نساز.

- برای MAC جدید Clone، DHCP reservation مطابق IP انتخابی بساز.
- به DNS عمومی دست نزن، مگر اینکه IP عمومی WAN تغییر کرده باشد.
- SSH معمولاً از LAN کافی است؛ لازم نیست TCP 22 را به اینترنت عمومی باز کنی.
- پورت‌های CS2 را فعلاً اضافه نکن.

## 9. برگرداندن Wings و بررسی سرویس‌ها

بعد از اصلاح Port Forwardها، از SSH به IP Clone که در بخش 1 تعیین کرده‌ای وصل شو و بلوک بعدی را اجرا کن:

~~~bash
echo "=== IP and route ==="
ip -br address
ip route

echo
echo "=== Main stack states ==="
for unit in nginx.service php8.3-fpm.service mariadb.service redis-server.service pteroq.service wings.service; do
    printf '%s active=' "$unit"
    systemctl is-active "$unit" 2>/dev/null || true
    printf '%s enabled=' "$unit"
    systemctl is-enabled "$unit" 2>/dev/null || true
done
~~~

اگر Nginx، PHP-FPM، MariaDB، Redis و pteroq فعال هستند، آن‌ها را تغییر نده. چون Wings قبلاً روی Clone غیرفعال شده بود، بعد از تأیید Port Forwardهای 8080 و 2022 آن را فعال کن:

~~~bash
sudo systemctl enable --now wings
sudo systemctl status wings --no-pager
~~~

سپس از https://panel.fragcity.ir وارد Panel شو و وضعیت Node را بررسی کن. برای بررسی پاسخ HTTPS:

~~~bash
curl -sS -o /dev/null -w 'Panel HTTP status: %{http_code}\\n' https://panel.fragcity.ir/
~~~

پاسخ 200 یا redirect مانند 301/302 می‌تواند نشان دهد وب‌سرور پاسخ داده است؛ وضعیت Node را جداگانه در Panel بررسی کن. اگر Panel باز نشد، قبل از reinstall کردن سرویس‌ها مقصد Port Forward، Nginx و PHP-FPM را بررسی کن. لاگ‌ها را در README ذخیره نکن.

به دلیل اینکه این Clone، نسخهٔ کامل همان VM است، Panel و Wings config موجود با هم کپی شده‌اند. چون VM اصلی خاموش است، برای همین دورهٔ تست نیازی به ساخت Node مستقل یا تولید config تازهٔ Wings نیست. **هیچ‌وقت هر دو VM را هم‌زمان روشن نکن.**

## 10. بررسی جامع سلامت قبل از افزودن VMDK

کد کامل بررسی سلامت مستقیماً در همین راهنما قرار دارد؛ برای این مرحله نیازی به Clone کردن ریپو یا دانلود فایل اسکریپت جداگانه نیست. اسکریپت فقط‌خواندنی است و هیچ سرویس، فایل تنظیمات، فایروال یا تنظیمات شبکه را تغییر نمی‌دهد.

بررسی‌ها شامل hostname و IP، مسیر پیش‌فرض، سرویس‌های systemd، syntax تنظیمات Nginx، پاسخ HTTPS محلی Panel، اعتبار زمانی گواهی‌ها، پورت‌های TCP در حال Listen، بررسی پایه MariaDB و Redis، وضعیت Docker و مصرف دیسک، وضعیت UFW و تعداد خطاهای سطح بالا در ۱۵ دقیقه اخیر است. لاگ خام و credentialها چاپ یا ذخیره نمی‌شوند.

در SSH متصل به Clone، کل بلوک زیر را یک‌جا کپی و اجرا کن. متن طولانی است؛ مطمئن شو خط آخر `SCRIPT` هم کپی شده است:

~~~bash
sudo bash <<'SCRIPT'
#!/usr/bin/env bash
# FragCity read-only health check for the temporary Clone replacement.
# This script collects status only. It does not restart services, change files,
# modify firewall/router rules, or display application secrets.
#
# Run on the Clone while the original VM is powered off:
#   sudo bash clone-health-check.sh
#
# Set these values to the temporary Clone identity in section 1 before running.
# The shown values in EXPECTED_HOST and EXPECTED_IP below are examples only.

set -uo pipefail
export LC_ALL=C

EXPECTED_HOST="fc-node-01"  # Replace with the actual Clone hostname
EXPECTED_IP="192.168.1.9"    # Replace with the actual Clone LAN IPv4

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { printf '[PASS] %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$1"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
section() { printf '\n===== %s =====\n' "$1"; }

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this read-only checker as root:"
    echo "  sudo bash clone-health-check.sh"
    exit 1
fi

section "1. Host identity and time"

CURRENT_HOST="$(hostnamectl --static 2>/dev/null || hostname)"
printf 'Hostname: %s\n' "$CURRENT_HOST"
printf 'Date:     %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
printf 'Uptime:   %s\n' "$(uptime -p 2>/dev/null || uptime)"

if [[ "$CURRENT_HOST" == "$EXPECTED_HOST" ]]; then
    pass "Hostname matches expected temporary replacement name."
else
    warn "Hostname differs from expected $EXPECTED_HOST; confirm which VM is running."
fi

if [[ -r /etc/machine-id ]] && grep -Eq '^[0-9a-f]{32}$' /etc/machine-id; then
    pass "machine-id file exists and has valid format (value hidden)."
else
    warn "machine-id is missing or has an unexpected format."
fi

if getent hosts "$CURRENT_HOST" >/dev/null 2>&1; then
    printf 'Local hostname mapping: '
    getent hosts "$CURRENT_HOST" | head -n 1
    pass "Current hostname resolves."
else
    fail "Current hostname does not resolve; check /etc/hosts."
fi

section "2. Network and routes"

ip -br address 2>/dev/null || true
ip route 2>/dev/null || true

if ip -o -4 address show | grep -Fq "$EXPECTED_IP/"; then
    pass "Expected Clone IPv4 $EXPECTED_IP is assigned."
else
    warn "Expected Clone IPv4 $EXPECTED_IP is not assigned; DHCP/IP may have changed."
fi

if ip route show default | grep -q '^default'; then
    pass "A default route exists."
else
    fail "No default route found."
fi

printf '\nDNS resolution for panel.fragcity.ir:\n'
if getent ahosts panel.fragcity.ir >/dev/null 2>&1; then
    getent ahosts panel.fragcity.ir | head -n 3
    pass "Panel domain resolves through the system resolver."
else
    fail "panel.fragcity.ir did not resolve from this VM."
fi

section "3. Main systemd services"

for unit in \
    nginx.service \
    php8.3-fpm.service \
    mariadb.service \
    redis-server.service \
    docker.service \
    wings.service \
    pteroq.service
do
    active="$(systemctl is-active "$unit" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "$unit" 2>/dev/null || true)"
    [[ -n "$active" ]] || active="unknown"
    [[ -n "$enabled" ]] || enabled="unknown"
    printf '%-24s active=%-12s enabled=%s\n' "$unit" "$active" "$enabled"

    case "$unit" in
        nginx.service|php8.3-fpm.service|mariadb.service|redis-server.service|docker.service|wings.service)
            if [[ "$active" == "active" ]]; then
                pass "$unit is active."
            else
                fail "$unit is not active (state: $active)."
            fi
            ;;
        pteroq.service)
            if [[ "$active" == "active" ]]; then
                pass "pteroq.service is active."
            elif [[ "$enabled" == "not-found" ]] || ! systemctl cat "$unit" >/dev/null 2>&1; then
                warn "pteroq.service unit was not found; inspect available queue/worker units before changing anything."
            else
                warn "pteroq.service exists but is not active."
            fi
            ;;
    esac
done

echo
echo "Related queue/worker services (if any):"
systemctl list-units --all --type=service --no-legend 2>/dev/null \
    | grep -Ei 'pteroq|pterodactyl|queue|horizon|supervisor' \
    | head -n 20 || echo "No matching loaded services found."

section "4. Web configuration and local HTTPS"

if command -v nginx >/dev/null 2>&1; then
    if nginx -t 2>&1; then
        pass "Nginx configuration test succeeded."
    else
        fail "Nginx configuration test failed."
    fi
else
    fail "nginx executable not found."
fi

if command -v curl >/dev/null 2>&1; then
    panel_code="$(curl --resolve panel.fragcity.ir:443:127.0.0.1 \
        --connect-timeout 4 --max-time 10 \
        --silent --show-error --output /dev/null \
        --write-out '%{http_code}' \
        https://panel.fragcity.ir/ 2>/dev/null || true)"

    if [[ "$panel_code" =~ ^[23][0-9][0-9]$ ]]; then
        pass "Local HTTPS virtual host for panel.fragcity.ir replied with HTTP $panel_code."
    elif [[ "$panel_code" =~ ^[45][0-9][0-9]$ ]]; then
        warn "Local HTTPS virtual host replied with HTTP $panel_code; inspect the Panel response."
    else
        warn "Local HTTPS probe failed; check Nginx listener, TLS certificate, and virtual-host config."
    fi
else
    warn "curl is not installed; local HTTPS probe skipped."
fi

section "5. TLS certificate files"

for cert in \
    /etc/letsencrypt/live/panel.fragcity.ir/fullchain.pem \
    /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem
do
    if [[ -r "$cert" ]] && command -v openssl >/dev/null 2>&1; then
        printf '%s: ' "$cert"
        openssl x509 -in "$cert" -noout -enddate 2>/dev/null || true

        if openssl x509 -in "$cert" -noout -checkend 1209600 >/dev/null 2>&1; then
            pass "Certificate has more than 14 days remaining: $cert"
        else
            warn "Certificate expires within 14 days or could not be validated: $cert"
        fi
    else
        warn "Certificate file missing/unreadable or openssl unavailable: $cert"
    fi
done

section "6. Local listening TCP ports"

ss -lntp 2>/dev/null || true
echo
echo "Expected service ports:"
for port in 80 443 8080 2022; do
    if ss -lnt 2>/dev/null | awk -v p=":$port" '$4 ~ (p "$") {found=1} END {exit !found}'; then
        pass "A TCP listener exists on port $port."
    else
        warn "No local TCP listener detected on port $port."
    fi
done

section "7. Database and Redis basic checks"

if command -v mariadb-admin >/dev/null 2>&1; then
    if mariadb-admin --protocol=socket --connect-timeout=3 ping >/dev/null 2>&1; then
        pass "MariaDB socket ping succeeded."
    else
        warn "MariaDB socket ping did not succeed; service state was shown above. No credentials were read or printed."
    fi
else
    warn "mariadb-admin is unavailable; database ping skipped."
fi

if command -v redis-cli >/dev/null 2>&1; then
    redis_reply="$(redis-cli ping 2>/dev/null || true)"
    if [[ "$redis_reply" == "PONG" ]]; then
        pass "Redis replied PONG."
    else
        warn "Redis ping did not return PONG (possibly authentication or local policy); no credentials were read or printed."
    fi
else
    warn "redis-cli is unavailable; Redis ping skipped."
fi

section "8. Docker and Pterodactyl storage"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker_root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || true)"
    [[ -n "$docker_root" ]] || docker_root="unknown"
    printf 'Docker root: %s\n' "$docker_root"
    pass "Docker daemon responds."
    echo
    echo "Containers (metadata only; no environment variables/secrets):"
    docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' 2>/dev/null || true
    echo
    docker system df 2>/dev/null || true
else
    warn "Docker daemon is unavailable or Docker CLI is not installed."
fi

for path in \
    /var/lib/pterodactyl/volumes \
    /var/lib/pterodactyl/archives \
    /var/lib/pterodactyl/backups
do
    if [[ -d "$path" ]]; then
        printf '\n%s\n' "$path"
        find "$path" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null | head -n 30
    else
        printf '\n%s: not created yet\n' "$path"
    fi
done

section "9. Disk capacity and attached devices"

df -hT / 2>/dev/null || true
echo
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS 2>/dev/null || true

if df -P / | awk 'NR==2 {gsub("%","",$5); if ($5+0 < 90) exit 0; exit 1}'; then
    pass "Root filesystem usage is below 90%."
else
    warn "Root filesystem usage is 90% or higher; review disk capacity."
fi

section "10. Firewall status (read-only)"

if command -v ufw >/dev/null 2>&1; then
    ufw status verbose 2>/dev/null || true
else
    warn "UFW command not found."
fi

section "11. Recent high-priority service failures (summary only)"

for unit in nginx.service php8.3-fpm.service mariadb.service redis-server.service docker.service wings.service; do
    count="$(journalctl -u "$unit" --since '-15 minutes' -p err..emerg --no-pager -q 2>/dev/null | wc -l | tr -d ' ')"
    [[ -n "$count" ]] || count="0"
    printf '%-24s errors-in-last-15m=%s\n' "$unit" "$count"
done
echo "Raw logs are intentionally not printed or saved."

section "12. Final summary"

printf 'PASS: %s\nWARN: %s\nFAIL: %s\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
echo
echo "Important manual checks this script cannot prove:"
echo "  - Router Port Forward rules target the Clone IP entered in section 1."
echo "  - The Panel shows the Node online in its UI."
echo "  - The original VM remains powered off."
echo "  - CS2 Base/instances are not installed yet; identify the second VMDK before formatting."
echo
echo "This script is read-only; it does not fix any reported issue."

SCRIPT
~~~

### تفسیر نتیجهٔ health check

اسکریپت فقط‌خواندنی است؛ PASS یعنی فرمان بررسی‌شده پاسخ مورد انتظار داده، WARN یعنی نیاز به بررسی دستی باقی است و FAIL یعنی شرط مورد انتظار برقرار نیست. خروجی اسکریپت به‌تنهایی وضعیت DNS، Port Forward روتر یا Online بودن Node در UI را اثبات نمی‌کند؛ این موارد را جداگانه بررسی کن.

برای بررسی Queue Worker یا Scheduler، بلوک‌های تأیید در [راهنمای نصب Debian و Pterodactyl](https://github.com/larnzs/linux-node/blob/main/Debian-PHP-Composer-Docker-Firewall-Pterodactyl-Wings-Installation.md) را اجرا کن. اگر آزمونی شکست خورد، خروجی همان فرمان را بررسی کن؛ به‌خاطر یک WARN به‌تنهایی سرویس‌ها را reinstall نکن.

## 11. پایان تست و بازگشت به VM اصلی

وقتی تست تمام شد:

1. در Clone دستور sudo systemctl poweroff را اجرا کن و در VMware مطمئن شو وضعیت **Powered Off** است.
2. مقصد Port Forwardهای سرویس‌هایی را که در بخش 8 به Clone منتقل کرده‌ای، از آدرس Clone به IP اصلی ثبت‌شده در جدول بخش 1 برگردان. در نمونهٔ FragCity، 192.168.1.9 آدرس Clone و 192.168.1.7 آدرس اصلی است.
3. فقط پس از خاموش‌شدن کامل Clone، VM اصلی را روشن کن.
4. روی VM اصلی، IP واقعی آن و دسترسی SSH/Panel/Wings را بررسی کن.

هرگز دو VM را هم‌زمان روشن نکن. اگر در آینده نیاز به اجرای هم‌زمان دو Node باشد، باید یک Node آزمایشی مستقل با هویت، دامنه و config اختصاصی طراحی شود.

## 12. افزودن VMDK دادهٔ دوم — فقط به Clone

پس از آماده‌شدن Clone و شناسایی درست آن:

1. VM آزمایشگاهی را در VMware کاملاً خاموش کن.
2. از مسیر **VM → Settings → Add → Hard Disk** یک دیسک مجازی کاملاً جدید به Clone که در بخش 1 نام‌گذاری کرده‌ای اضافه کن. دیسک موجود ماشین اصلی را انتخاب یا attach نکن.
3. ظرفیت جدید را بر اساس فضای آزاد واقعی Windows host انتخاب کن؛ ظرفیت مجازی بزرگ لزوماً به معنی تخصیص فوری همان مقدار فضا نیست، اما دیسک growable نیز می‌تواند با نوشتن داده رشد کند.
4. Clone را روشن کن. در Debian فقط دستگاه‌ها را فهرست کن:

   ~~~bash
   lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
   sudo blkid
   ~~~

5. دیسک تازه را با تطبیق اندازه، type، filesystem و mountpoint شناسایی کن. نام دستگاه را حدس نزن؛ ممکن است /dev/sdb باشد اما تضمینی نیست.
6. تا وقتی دیسک جدید با اطمینان از دیسک root جدا تشخیص داده و تأیید نشده، هیچ mkfs، partitioning، mount یا ویرایش /etc/fstab اجرا نکن. دستورات formatting عمداً در این سند نیامده‌اند؛ بعد از ارائهٔ خروجی lsblk و blkid دربارهٔ دستگاه واقعی تصمیم می‌گیریم.

## 13. اتصال CS2 Node و Shared Base

ساخت Instance CS2، نصب cs2node، Runtimeهای i386، VPK Sync، Workshop Cache و Multi Instance در این سند تکرار نمی‌شود؛ برای آن مراحل به [راهنمای آموزشی K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Workshop](https://github.com/larnzs/linux-node/blob/main/K4ryuu-CS2-Egg-Go-cs2node-VPKSync-MultiInstance.md) برو.

پیش از افزودن VMDK اختیاری:
1. CS2 Shared Base را روی فایل‌سیستم موجود با معیارهای آن راهنما تأیید کن.
2. در صورت نیاز واقعی به جداسازی Storage، فقط به Clone دیسک مجزا اضافه کن.
3. پس از بوت، با lsblk و blkid دیسک جدید را شناسایی کن؛ تا قبل از تأیید، هیچ Partition/Format/Mount انجام نده.
4. Mount point جدید باید با مقدار cs2_dir در /etc/cs2node/config.json هماهنگ باشد.
5. برای انتقال فایل‌های بازی/Workshop با WinSCP، مسیرها و پردازش‌های فعال را طبق راهنمای CS2 بررسی کن؛ هیچ‌وقت در زمان نوشتن SteamCMD آپلود انجام نده.

## 14. چک‌لیست پایان عملیات Clone

- [ ] VM اصلی قبل از روشن‌کردن Clone کاملاً خاموش شده است.
- [ ] Full Clone با نام و مسیر مجزا ساخته شده و فایل‌های VM اصلی جابه‌جا یا overwrite نشده‌اند.
- [ ] پیش از اجرای اسکریپت تغییر hostname، TARGET_HOST، TARGET_IP و نام‌های DNS با محیط خود تطبیق داده شده‌اند.
- [ ] هر Port Forward فقط یک مقصد فعال دارد و به IP فعلی Clone اشاره می‌کند.
- [ ] Health check روی Clone اجرا شده و WARN/FAILها به‌صورت مستقل بررسی شده‌اند.
- [ ] اگر VMDK اضافه شده، دستگاه با lsblk و blkid تأیید شده و قبل از شناسایی دقیق Format نشده است.
- [ ] برای بازگشت، ابتدا Clone خاموش شده، سپس Port Forwardها به VM اصلی بازگردانده و بعد VM اصلی روشن شده است.
- [ ] دو VM با هویت فعلی هیچ‌وقت هم‌زمان روشن نبوده‌اند.

### بازگشت امن به VM اصلی

1. روی Clone اجرا کن: sudo systemctl poweroff.
2. در VMware صبر کن تا وضعیت Clone دقیقاً **Powered Off** شود.
3. مقصد Port Forwardهای فعلی را از IP Clone به IP اصلی برگردان.
4. فقط بعد از تأیید تغییر مقصدها، VM اصلی را روشن کن.
5. IP اصلی، SSH، Panel و Wings را بررسی کن. اگر در Clone تغییری مثل Queue Worker/Scheduler داده‌ای، وضعیت آن را روی VM اصلی نیز جداگانه بررسی کن؛ VMDKها فایل‌سیستم‌های مستقل‌اند.

