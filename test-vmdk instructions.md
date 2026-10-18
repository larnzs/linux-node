# FragCity — Test VMDK / VM Clone Instructions

> **هدف:** ساخت یک کپی آزمایشگاهی مستقل از Debian Node فعلی FragCity، جداکردن هویت کپی از ماشین اصلی، و افزودن VMDK دوم فقط به کپی برای آزمون ذخیره‌سازی CS2 Shared Base.
>
> **قانون اصلی:** روی VM اصلی هیچ‌کدام از فرمان‌های مربوط به Clone، تغییر hostname، machine-id، SSH host keys، Wings، Nginx یا دیسک آزمایشی را اجرا نکن. تمام تغییرات این سند بعد از ساخت Full Clone و فقط در کپی انجام می‌شوند.
>
> این فایل Runbook است، نه گزارش لاگ. خروجی خام ترمینال، رمزها، tokenها، APP_KEY، محتویات /etc/pterodactyl/config.yml و کلیدهای خصوصی را در GitHub ثبت نکن.

## 1. وضعیت و مسیرهای شناسایی‌شده

اطلاعاتی که هنگام آماده‌سازی Clone مشخص شدند:

| مورد | وضعیت / مسیر |
|---|---|
| Windows host drive فضای آزاد D | حدود 301.8 GB در زمان بررسی؛ پیش از عملیات سنگین دوباره بررسی شود |
| VMDK ماشین اصلی | **D:\Debian 13.x 64 bit cmd.vmdk** |
| اندازهٔ فایل VMDK در زمان بررسی | حدود 2.67 GB؛ این عدد ظرفیت مجازی دیسک را نشان نمی‌دهد |
| VMX ماشین اصلی | **C:\Users\Elias\Documents\Virtual Machines\Debian 13.x 64 bit cmd\Debian 13.x 64 bit cmd.vmx** |
| نام پیشنهادی Clone | **fc-node-01-clone** |
| محل پیشنهادی Full Clone | **D:\FragCity-VMs\fc-node-01-clone\** |
| Hostname داخل Clone | **fc-node-01-test** |
| وضعیت Wings داخل Clone | کاربر تأیید کرده که متوقف شده؛ با دستور بررسی کن که disabled هم باشد |
| Network Adapter کلون | در اولین بوت قطع شد؛ برای SSH دوباره وصل شده و IP فعلی Clone برابر 192.168.1.9 است |
| VMDK دادهٔ دوم | هنوز اضافه نشده؛ در این مرحله دیسکی را فرمت یا mount نکن |

مسیر واقعی Clone را در VMware از تنظیمات همان VM بررسی کن. فایل‌های VM اصلی را به محل دیگری منتقل نکن و پوشهٔ قفل .lck را هنگام روشن‌بودن ماشین حذف نکن.

## 2. پیش‌بررسی فضای میزبان Windows

این دستور در Windows PowerShell فضای آزاد هر درایو را نشان می‌دهد:

~~~powershell
Get-PSDrive -PSProvider FileSystem |
    Select-Object Name, Root,
        @{Name='FreeGB'; Expression={[math]::Round($_.Free / 1GB, 1)}},
        @{Name='UsedGB'; Expression={[math]::Round($_.Used / 1GB, 1)}}
~~~

در زمان بررسی، D حدود 301.8 GB فضای آزاد داشت. این مقدار ممکن است تغییر کرده باشد. برای Full Clone و یک VMDK دادهٔ جدید باید فضای رشد احتمالی دیسک‌های thin/growable نیز در نظر گرفته شود؛ فضای آزاد فعلی مهم‌تر از اندازهٔ کم فایل VMDK در Explorer است.

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
5. نام VM را **fc-node-01-clone** بگذار.
6. محل را **D:\FragCity-VMs** انتخاب کن. اگر پوشه وجود ندارد، ابتدا آن را در File Explorer ایجاد کن. فایل‌های Clone باید زیر پوشهٔ مستقل خودشان باشند.
7. تنظیمات را بازبینی کن و **Finish** را بزن. منتظر پایان کامل Clone بمان.

Full Clone باید تمام دیسک‌ها و تنظیمات لازم VM را در نسخهٔ مستقل کپی کند. پس از ساخت، فایل‌های VM اصلی و Clone را از هم جدا نگه دار.

## 5. اولین بوت: UUID/MAC جدید و مسیر جایگزین برای SSH

پیش از اولین بوت، در VMware مسیر **VM → Settings → Network Adapter** را باز کن و تیک **Connect at power on** را بردار. Clone را روشن کن و اگر پرسیده شد **I Copied It** را انتخاب کن تا VMware UUID/MAC مجازی تازه‌ای بسازد.

بهترین حالت برای اولین بوت، شبکهٔ جدا است؛ اما اگر برای انتقال دستورها نیاز به SSH داری، **لازم نیست اینترنت را قطع نگه داری**. در وضعیت فعلی Clone آدرس DHCP برابر **192.168.1.9** دارد و Node اصلی آدرس **192.168.1.7** را استفاده می‌کند. تا پیش از اجرای مرحلهٔ 8:

- حتماً Wings روی Clone متوقف باشد؛ در این محیط قبلاً متوقف شده است.
- هیچ Port Forward عمومی را به 192.168.1.9 تغییر نده. قوانین فعلی سرویس اصلی باید به IP اصلی 192.168.1.7 اشاره کنند.
- از SSH به IP آزمایشگاهی Clone وصل شو و اسکریپت مرحلهٔ 8 را بلافاصله اجرا کن؛ اسکریپت Nginx و سرویس‌های کپی‌شدهٔ پنل را پیش از تغییر هویت متوقف می‌کند.
- شبکه و SSH را داخل اسکریپت قطع نمی‌کنیم؛ ارتباط فعلی باید برای پایان کار و دیدن خروجی حفظ شود.

**I Copied It فقط هویت مجازی VMware را تغییر می‌دهد؛ machine-id، SSH host keys، نام میزبان یا Node ID مربوط به Wings را به‌تنهایی جدا نمی‌کند.**

راهنمای VMware/Broadcom: https://knowledge.broadcom.com/external/article/310359/copy-workstation-virtual-machine-from-on.html

## 6. غیرفعال‌کردن Wings فقط روی Clone

در کنسول VMware مطمئن شو واقعاً داخل **fc-node-01-clone** هستی، نه SSH یا کنسول VM اصلی. دستور زیر را فقط در Clone اجرا کن:

~~~bash
sudo systemctl disable --now wings
~~~

بررسی:

~~~bash
echo "=== Wings active state ==="
systemctl is-active wings || true

echo
echo "=== Wings enabled state ==="
systemctl is-enabled wings || true
~~~

انتظار می‌رود Wings فعال نباشد و برای بوت‌های بعدی هم disabled باشد. هدف این است که Clone با UUID/تنظیمات قبلی Wings به Panel اصلی متصل نشود.

**هرگز این مرحله را روی VM اصلی اجرا نکن.** روی Clone نیز تا زمانی که یک Node مستقل در Panel ساخته نشده و پیکربندی جدید Wings تهیه نشده، Wings را اجرا یا enable نکن.

## 7. نام‌گذاری Clone

در کنسول Clone، hostname آزمایشگاهی را تنظیم کن:

~~~bash
sudo hostnamectl set-hostname fc-node-01-test
~~~

بررسی:

~~~bash
hostnamectl --static
cat /etc/hostname
cat /etc/hosts
~~~

نام مورد انتظار **fc-node-01-test** است. فایل /etc/hosts را هم بررسی کن تا ارجاع‌های محلی قدیمی به fc-node-01 برای نام میزبان خود سیستم اصلاح شوند. اگر هنوز نام قدیمی در فایل وجود دارد، قبل از وصل‌کردن شبکه اصلاحش کن.

## 8. اسکریپت کامل جداسازی هویت — حتی با شبکه و SSH متصل

این نسخه برای همین وضعیت طراحی شده است: Clone با hostname برابر **fc-node-01-test** و IP فعلی **192.168.1.9** به شبکه متصل است تا بتوان با SSH فرمان را فرستاد. اسکریپت **شبکه، route یا SSH را خاموش نمی‌کند**؛ ابتدا سرویس‌های کپی‌شده‌ای را که ممکن است با Node/Panel اصلی تداخل کنند، متوقف و disable می‌کند.

پیش‌شرط‌ها:
1. فرمان را فقط در SSH یا کنسول VM کلون اجرا کن. hostname باید fc-node-01-test باشد.
2. قبل از شروع مطمئن شو این IP متعلق به Clone است و Port Forwardهای عمومی هنوز به IP اصلی 192.168.1.7 اشاره می‌کنند، نه .9.
3. Wings باید در Clone از قبل متوقف باشد؛ اسکریپت دوباره آن را متوقف و disable می‌کند.
4. پنجرهٔ SSH را نبند و تا پایان اسکریپت سیستم را reboot نکن.
5. وقتی prompt نمایش داده شد، دقیقاً PREPARE-CLONE را وارد کن. تأیید از /dev/tty خوانده می‌شود؛ بنابراین با heredoc با متن اسکریپت تداخل ندارد.

اسکریپت از فایل‌های هویت قبلی در /root پشتیبان می‌گیرد، Wings/Nginx/Certbot/Pterodactyl queue worker و سرویس‌های پنل محلی را روی Clone خاموش می‌کند، سپس hostname mapping، machine-id و SSH host keys را جدا می‌کند. سرویس SSH و شبکه را خاموش یا restart نمی‌کند. مقادیر شناسه‌ها چاپ نمی‌شوند.

~~~bash
sudo bash <<'SCRIPT'
set -Eeuo pipefail

EXPECTED_HOST="fc-node-01-test"
TARGET_HOST="fc-node-01-test"

if [[ "$(hostnamectl --static)" != "$EXPECTED_HOST" ]]; then
    echo "ERROR: Hostname mismatch. Nothing changed."
    echo "Expected hostname: $EXPECTED_HOST"
    echo "Actual hostname:   $(hostnamectl --static)"
    exit 1
fi

if [[ ! -r /dev/tty ]]; then
    echo "ERROR: An interactive terminal is required."
    echo "Run this from a normal interactive SSH session or the VMware console."
    exit 1
fi

echo "Target host: $(hostnamectl --static)"
echo "Network will remain connected; SSH will not be stopped."
echo "Do NOT run this on the original VM."
IFS= read -r -p "Type PREPARE-CLONE to continue: " confirmation </dev/tty

if [[ "$confirmation" != "PREPARE-CLONE" ]]; then
    echo "Cancelled. No changes made."
    exit 1
fi

BACKUP="/root/fc-clone-prep-$(date +%Y%m%d-%H%M%S)"
install -d -m 700 "$BACKUP"

echo
echo "=== 1. Stop/disable services copied from the original VM ==="
echo "Network and SSH are intentionally left running."

for unit in \
    wings.service \
    nginx.service \
    certbot.timer \
    pteroq.service \
    php8.3-fpm.service \
    mariadb.service \
    redis-server.service \
    cron.service
do
    if systemctl cat "$unit" >/dev/null 2>&1; then
        if systemctl disable --now "$unit" >/dev/null 2>&1; then
            echo "Stopped and disabled: $unit"
        else
            systemctl stop "$unit" >/dev/null 2>&1 || true
            systemctl disable "$unit" >/dev/null 2>&1 || true
            echo "Stop/disable attempted: $unit"
        fi
    else
        echo "Not installed: $unit"
    fi
done

echo
echo "=== 2. Back up local identity files ==="

cp -a /etc/hostname /etc/hosts "$BACKUP/"

OLD_MACHINE_ID=""
if [[ -r /etc/machine-id ]]; then
    OLD_MACHINE_ID="$(tr -d '\n' < /etc/machine-id || true)"
    cp -a /etc/machine-id "$BACKUP/machine-id-file"
fi

if [[ -e /var/lib/dbus/machine-id || -L /var/lib/dbus/machine-id ]]; then
    cat /var/lib/dbus/machine-id > "$BACKUP/original-dbus-machine-id.txt" || true
    chmod 600 "$BACKUP/original-dbus-machine-id.txt"
    cp -a /var/lib/dbus/machine-id "$BACKUP/dbus-machine-id-file" || true
fi

find /etc/ssh -maxdepth 1 -type f -name 'ssh_host_*' \
    -exec cp -a {} "$BACKUP/" \;

chmod -R go-rwx "$BACKUP"
echo "Local backup directory: $BACKUP"

echo
echo "=== 3. Set clone hostname and local host mapping ==="

hostnamectl set-hostname "$TARGET_HOST"

python3 - "$TARGET_HOST" <<'PY'
import sys
from pathlib import Path

target = sys.argv[1]
path = Path("/etc/hosts")
lines = path.read_text().splitlines()
output = []
has_local_entry = False

replacements = {
    "fc-node-01": target,
    "fc-node-01.fragcity.ir": target + ".fragcity.ir",
}

for line in lines:
    stripped = line.strip()

    if not stripped or stripped.startswith("#"):
        output.append(line)
        continue

    body, marker, comment = line.partition("#")
    fields = body.split()

    if not fields:
        output.append(line)
        continue

    if fields[0] == "127.0.1.1":
        output.append(
            "127.0.1.1\\t" + target
            + ((" #" + comment) if marker else "")
        )
        has_local_entry = True
        continue

    changed = False
    for i in range(1, len(fields)):
        if fields[i] in replacements:
            fields[i] = replacements[fields[i]]
            changed = True

    if changed:
        output.append(
            "\\t".join(fields)
            + ((" #" + comment) if marker else "")
        )
    else:
        output.append(line)

if not has_local_entry:
    output.append("127.0.1.1\\t" + target)

path.write_text("\\n".join(output) + "\\n")
PY

echo
echo "=== 4. Generate a new machine-id ==="

mkdir -p /var/lib/dbus
rm -f /etc/machine-id /var/lib/dbus/machine-id
install -m 0444 /dev/null /etc/machine-id
systemd-machine-id-setup
ln -s /etc/machine-id /var/lib/dbus/machine-id

machine_id="$(tr -d '\n' < /etc/machine-id)"
if [[ ! "$machine_id" =~ ^[0-9a-f]{32}$ ]]; then
    echo "ERROR: machine-id validation failed."
    exit 1
fi
if [[ -n "$OLD_MACHINE_ID" && "$machine_id" == "$OLD_MACHINE_ID" ]]; then
    echo "ERROR: machine-id did not change. Stop here and do not reboot/connect any extra network."
    exit 1
fi
echo "New machine-id generated and validated (value hidden)."

echo
echo "=== 5. Regenerate SSH host keys ==="

find /etc/ssh -maxdepth 1 -type f -name 'ssh_host_*' -delete
ssh-keygen -A

if [[ ! -s /etc/ssh/ssh_host_ed25519_key.pub ]]; then
    echo "ERROR: SSH host public key was not generated."
    exit 1
fi

echo "New SSH host keys generated."
echo "The current SSH session is left running; new keys will be loaded on the next reboot."

echo
echo "=== 6. Final local checks ==="

printf 'Hostname: '
hostnamectl --static

printf 'machine-id: '
if [[ "$machine_id" =~ ^[0-9a-f]{32}$ ]]; then
    echo "OK (value hidden)"
else
    echo "INVALID"
    exit 1
fi

for unit in wings.service nginx.service certbot.timer pteroq.service; do
    printf '%s: ' "$unit"
    systemctl is-active "$unit" 2>/dev/null || true
done

echo
echo "Current network addresses (no changes made to network):"
ip -br address || true

echo
echo "Preparation complete. Network and SSH remain available."
echo "Keep Wings/Nginx disabled and review the output before rebooting."
echo "Backup directory: $BACKUP"
SCRIPT
~~~

### این اسکریپت چه چیزهایی را تغییر نمی‌دهد؟

- آداپتور شبکه، IP، DHCP، route و SSH را قطع نمی‌کند.
- Port Forward روتر، UFW، DNS، تنظیمات TLS و فایل /etc/pterodactyl/config.yml را بازنویسی نمی‌کند.
- فایل‌های خصوصی SSH کاربر را تغییر نمی‌دهد؛ فقط SSH **host keys** را در Clone بازتولید می‌کند.
- هویت Node داخل config قدیمی Wings را به Node جدید تبدیل نمی‌کند. Wings خاموش و disabled باقی می‌ماند تا بعداً در Panel یک Node مستقل تعریف کنیم و config تازهٔ همان Node را دریافت کنیم.
- Nginx، Certbot timer، php-fpm، MariaDB، Redis و cron را در صورت وجود روی **Clone** متوقف/disable می‌کند تا پنل کپی‌شده و کارهای زمان‌بندی‌شده‌اش با محیط اصلی رقابت نکنند. این سرویس‌ها بعداً، در صورت نیاز، به‌صورت آگاهانه و جداگانه پیکربندی می‌شوند.
- این نسخه reboot خودکار نمی‌کند؛ ابتدا خروجی را بازبینی کن.

اگر فرمان به خطا رسید، شبکه را قطع نکن و مراحل را کورکورانه تکرار نکن. خروجی غیرحساس را بررسی کن؛ پوشهٔ پشتیبان فقط برای بازیابی کنترل‌شده روی Clone است و نباید به GitHub ارسال شود.

## 9. Reboot و تأیید هویت Clone

اگر اسکریپت بدون خطا به پیام پایان رسید، آداپتور شبکه را قطع نگه دار و داخل Clone اجرا کن:

~~~bash
sudo reboot
~~~

بعد از بوت، این بررسی‌ها را اجرا کن:

~~~bash
echo "=== Clone hostname ==="
hostnamectl --static

echo
echo "=== Host mapping ==="
grep -nE 'fc-node-01|fc-node-01-test' /etc/hosts || true

echo
echo "=== machine-id validation (value hidden) ==="
if sudo test "$(sudo cat /etc/machine-id | wc -c)" -ge 32; then
    echo "machine-id file is populated"
else
    echo "ERROR: machine-id file is missing or empty"
fi

echo
echo "=== SSH host public key fingerprints ==="
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null || true

echo
echo "=== Service states ==="
systemctl is-active wings nginx 2>/dev/null || true
systemctl is-enabled wings nginx certbot.timer 2>/dev/null || true
~~~

خروجی باید hostname آزمایشگاهی را نشان بدهد و Wings فعال نباشد. اثر انگشت SSH عمومی است؛ کلیدهای خصوصی را نمایش یا ارسال نکن. چون SSH host key جدید شده، کلاینت Windows در اتصال‌های بعدی ممکن است هشدار host key بدهد؛ فقط پس از اطمینان از IP و هویت Clone، اثر انگشت جدید را تأیید کن.

## 10. تأیید هویت و کار با شبکهٔ متصل

**برخلاف نسخهٔ اولیهٔ این راهنما، پس از قطع سرویس‌های حساس لازم نیست شبکه را برای اجرای اسکریپت جدا کنی.** چون برای انتقال فرمان از SSH استفاده می‌کنیم، شبکه می‌تواند فعال بماند؛ خود اسکریپت در مرحلهٔ 8 سرویس‌های زیر را متوقف/disable می‌کند و به SSH دست نمی‌زند.

پس از پایان اسکریپت، در همان کنسول یا SSH این بررسی‌ها را اجرا کن:

~~~bash
echo "=== Clone hostname ==="
hostnamectl --static

echo
echo "=== Host mapping ==="
grep -nE 'fc-node-01|fc-node-01-test' /etc/hosts || true

echo
echo "=== machine-id validation (value hidden) ==="
if sudo test "$(sudo cat /etc/machine-id | wc -c)" -ge 32; then
    echo "machine-id file is populated"
else
    echo "ERROR: machine-id file is missing or empty"
fi

echo
echo "=== SSH host public key fingerprint ==="
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

echo
echo "=== Service state ==="
for unit in wings.service nginx.service certbot.timer pteroq.service; do
    printf '%s active=' "$unit"
    systemctl is-active "$unit" 2>/dev/null || true
    printf '%s enabled=' "$unit"
    systemctl is-enabled "$unit" 2>/dev/null || true
done

echo
echo "=== Network ==="
ip -br address
ip route
~~~

خروجی باید hostname آزمایشگاهی را نشان دهد و Wings/Nginx غیرفعال باشند. اگر بررسی‌ها موفق‌اند، ماشین Clone را reboot کن:

~~~bash
sudo reboot
~~~

پس از بوت، اتصال SSH قطع می‌شود و SSH host key جدیدی استفاده خواهد شد. اگر Windows دربارهٔ SSH host key تغییرکرده هشدار داد، قبل از پاک‌کردن هر ورودی مطمئن شو IP مقصد **192.168.1.9 همان Clone** است و نه Node اصلی. فقط پس از تأیید این موضوع، در Windows PowerShell می‌توان ورودی قدیمی مربوط به IP آزمایشی را حذف کرد:

~~~powershell
ssh-keygen -R 192.168.1.9
~~~

سپس با دستور SSH همیشگی‌ات به IP آزمایشگاهی وصل شو و اثر انگشت جدید را با fingerprint نمایش‌داده‌شده از Clone مقایسه کن.

نکات شبکه:
1. DHCP به Clone در بررسی فعلی **192.168.1.9** داده است؛ بهتر است در روتر برای MAC جدید همین IP را رزرو کنی. IP اصلی **192.168.1.7** و رزرو آن را دست‌نخورده نگه دار.
2. برای دانلود بسته‌ها و استفاده از SSH خروجی اینترنت کافی است؛ Port Forward جدیدی لازم نیست.
3. Port Forwardهای عمومی را به .9 منتقل نکن و پورت‌های عمومی تازه‌ای برای Clone نساز. وقتی در آینده تست end-to-end لازم شد، ابتدا Node آزمایشی مستقل در Panel، FQDN و پیکربندی Wings اختصاصی‌اش را آماده می‌کنیم.
4. Nginx، Certbot timer و Wings روی Clone خاموش/disabled باقی می‌مانند تا نام/گواهی و هویت Node مستقل آماده شود. config فعلی Wings را به‌عنوان config نهایی آزمایشگاه استفاده نکن.
5. هیچ پورت SSH، MariaDB یا Redis را به اینترنت عمومی باز نکن. اگر دسترسی LAN یا outbound قطع شد، قبل از هر تغییر روتر، وضعیت IP و سرویس SSH را بررسی کن.

**مهم:** تغییر hostname، machine-id و SSH host keys به‌تنهایی هویت Node در Pterodactyl را مستقل نمی‌کند؛ تا وقتی Node آزمایشی مستقل ساخته و config تازهٔ Wings دریافت نشده، Wings را فعال نکن.

## 11. افزودن VMDK دادهٔ دوم — فقط به Clone

پس از آماده‌شدن Clone و شناسایی درست آن:

1. VM آزمایشگاهی را در VMware کاملاً خاموش کن.
2. از مسیر **VM → Settings → Add → Hard Disk** یک دیسک مجازی جدید به fc-node-01-clone اضافه کن. دیسک موجود ماشین اصلی را انتخاب یا attach نکن؛ دیسک کاملاً جدید بساز.
3. ظرفیت جدید را بر اساس فضای آزاد واقعی Windows host انتخاب کن؛ ظرفیت مجازی بزرگ لزوماً به معنی تخصیص فوری همان مقدار فضا نیست، اما دیسک growable نیز می‌تواند با نوشتن داده رشد کند.
4. Clone را روشن کن. در Debian فقط دستگاه‌ها را فهرست کن:

   ~~~bash
   lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
   sudo blkid
   ~~~

5. دیسک تازه را با تطبیق اندازه، type، filesystem و mountpoint شناسایی کن. نام دستگاه را حدس نزن؛ ممکن است /dev/sdb باشد اما تضمینی نیست.
6. تا وقتی دیسک جدید با اطمینان از دیسک root جدا تشخیص داده و تأیید نشده، هیچ mkfs، partitioning، mount یا ویرایش /etc/fstab اجرا نکن. دستورات formatting عمداً در این سند نیامده‌اند؛ بعد از ارائهٔ خروجی lsblk و blkid دربارهٔ دستگاه واقعی تصمیم می‌گیریم.

## 12. محدودهٔ PoC مربوط به CS2 Shared Base

این Clone صرفاً محل آزمایش است. هیچ اسکریپت KUS یا Egg نصب بازی را اجرا نکن تا Layout ذخیره‌سازی مشخص شود.

ترتیب آزمون موردنظر:

1. تأیید دیسک داده و انتخاب filesystem/mountpoint.
2. ساخت Base مرکزی CS2 بدون نوشتن اطلاعات Instance روی آن.
3. آزمون read-only دسترسی یک Instance به Base.
4. افزودن فایل‌های خصوصی همان Instance و آزمایش Panel File Manager/SFTP.
5. ساخت Instance دوم با cfg و addon متفاوت و بررسی عدم نشت تنظیمات.
6. بررسی قفل Update، Stop/Start، حذف/بازسازی یک Instance، Backup/Restore و Recovery پس از خطا.
7. اندازه‌گیری فضای مصرفی و زمان نصب/Update؛ سپس تصمیم‌گیری دربارهٔ استفاده از CS2-Egg-Go.

مراجع فنی برای ادامه:
- معماری FragCity Multi-Instance: https://github.com/larnzs/FragCity-RawPHPbackend/blob/main/docs/CS2-MULTI-INSTANCE.md
- CS2-Egg-Go: https://github.com/K4ryuu/CS2-Egg-Go
- مستند Mountهای سفارشی Pterodactyl: https://docs.pterodactyl.io/v1/guides/configuration/mounts
- مستند Linux OverlayFS: https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html

## 13. چک‌لیست مرحلهٔ جاری

- [x] فضای آزاد Windows host بررسی شد؛ D در زمان بررسی حدود 301.8 GB آزاد داشت.
- [x] مسیر VMX روی C و فایل VMDK روی D پیدا شد.
- [x] Full Clone به‌عنوان روش مدنظر انتخاب شد.
- [x] روی Clone، Network Adapter برای اولین بوت قطع شد و I Copied It انتخاب شد.
- [x] Wings روی Clone متوقف شد.
- [x] hostname داخل Clone به fc-node-01-test تغییر داده شد.
- [ ] اسکریپت جداسازی machine-id و SSH host keys اجرا و تأیید شود.
- [ ] Clone پس از اسکریپت reboot و وضعیت محلی تأیید شود.
- [ ] شبکهٔ Clone پس از تأیید هویت وصل شود.
- [ ] Node آزمایشی مستقل در Panel و config تازهٔ Wings آماده شود.
- [ ] VMDK دادهٔ دوم فقط به Clone اضافه شود.
- [ ] دستگاه تازه با lsblk و blkid شناسایی شود؛ تا قبل از تأیید فرمت نشود.
- [ ] PoC مربوط به Base مرکزی و دو Instance مستقل انجام شود.

**آخرین checkpoint:** Clone ساخته شده، شبکه‌اش در شروع قطع بوده، Wings متوقف شده و hostname به fc-node-01-test تغییر داده شده است. اجرای اسکریپت کامل جداسازی هویت، اتصال مجدد شبکه و افزودن VMDK دوم هنوز باید تأیید شوند. VM اصلی، نصب CS2، ریپوهای KUS و config اصلی Wings نباید توسط مراحل آزمایش تغییر داده شوند.
