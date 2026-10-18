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
| Network Adapter کلون | در اولین بوت disconnect نگه داشته شده است |
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

## 5. اولین بوت: شبکه قطع و UUID/MAC جدید

پیش از روشن‌کردن Clone:

1. آن را انتخاب کن و وارد **VM → Settings → Network Adapter** شو.
2. تیک **Connect at power on** را بردار. آداپتور را حذف نکن.
3. Clone را روشن کن.
4. اگر VMware پرسید ماشین جابه‌جا شده یا کپی شده است، گزینهٔ **I Copied It** را انتخاب کن تا VMware هویت مجازی جدیدی برای آن بسازد.
5. اجازه بده Debian تا صفحهٔ Login بالا بیاید.

Clone هویت‌های سطح سیستم‌عامل را هم از VM اصلی به ارث برده است؛ انتخاب **I Copied It** به‌تنهایی machine-id یا کلیدهای SSH را تغییر نمی‌دهد. تا وقتی مراحل بعد تمام نشده، Network Adapter را قطع نگه دار.

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

## 8. جداسازی یک‌جای هویت محلی Clone

**این مرحله در گفت‌وگو پیشنهاد شده، اما اجرای موفق آن هنوز تأیید نشده است.** آن را یک‌بار و فقط بعد از تأیید hostname روی Clone اجرا کن. آداپتور شبکه باید همچنان قطع باشد.

این اسکریپت از فایل‌های اصلی هویت پشتیبان محلی می‌گیرد، سرویس‌های بالقوهٔ متداخل را تا زمان پیکربندی مستقل متوقف و disable می‌کند، hostname و mapping محلی را تأیید می‌کند، machine-id جدید می‌سازد و SSH host keys را بازتولید می‌کند. فایل‌های پشتیبان حاوی دادهٔ حساس هستند و فقط در /root ماشین آزمایشگاهی می‌مانند؛ آن‌ها را upload یا ارسال نکن.

~~~bash
sudo bash <<'SCRIPT'
set -Eeuo pipefail

EXPECTED_HOST="fc-node-01-test"
TARGET_HOST="fc-node-01-test"

if [[ "$(hostnamectl --static)" != "$EXPECTED_HOST" ]]; then
    echo "ERROR: Hostname mismatch. Nothing changed."
    echo "Expected: $EXPECTED_HOST"
    echo "Actual:   $(hostnamectl --static)"
    exit 1
fi

echo "This script must run ONLY on the isolated Clone."
read -r -p "Type PREPARE-CLONE to continue: " confirmation

if [[ "$confirmation" != "PREPARE-CLONE" ]]; then
    echo "Cancelled. Nothing changed."
    exit 1
fi

BACKUP="/root/fc-clone-prep-$(date +%Y%m%d-%H%M%S)"
install -d -m 700 "$BACKUP"

echo
echo "=== 1. Backing up identity files ==="

cp -a /etc/hostname /etc/hosts "$BACKUP/"

if [[ -e /etc/machine-id || -L /etc/machine-id ]]; then
    cat /etc/machine-id > "$BACKUP/original-machine-id.txt" || true
    chmod 600 "$BACKUP/original-machine-id.txt"
fi

if [[ -e /var/lib/dbus/machine-id || -L /var/lib/dbus/machine-id ]]; then
    cat /var/lib/dbus/machine-id \
        > "$BACKUP/original-dbus-machine-id.txt" || true
    chmod 600 "$BACKUP/original-dbus-machine-id.txt"
fi

find /etc/ssh -maxdepth 1 -type f -name 'ssh_host_*' \
    -exec cp -a {} "$BACKUP/" \;

echo "Backup directory: $BACKUP"

echo
echo "=== 2. Keeping conflicting services disabled ==="

for unit in wings.service nginx.service certbot.timer pteroq.service; do
    if systemctl cat "$unit" >/dev/null 2>&1; then
        systemctl disable --now "$unit" >/dev/null 2>&1 || {
            systemctl stop "$unit" || true
        }
        echo "Stopped/disabled where applicable: $unit"
    else
        echo "Not installed: $unit"
    fi
done

echo
echo "=== 3. Updating hostname and local host mappings ==="

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
            "127.0.1.1\t" + target
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
            "\t".join(fields)
            + ((" #" + comment) if marker else "")
        )
    else:
        output.append(line)

if not has_local_entry:
    output.append("127.0.1.1\t" + target)

path.write_text("\n".join(output) + "\n")
PY

echo
echo "=== 4. Regenerating machine-id ==="

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
echo "machine-id generated and validated (value hidden)."

echo
echo "=== 5. Regenerating SSH host keys ==="

find /etc/ssh -maxdepth 1 -type f -name 'ssh_host_*' -delete
ssh-keygen -A

if systemctl cat ssh.service >/dev/null 2>&1; then
    sshd -t
    systemctl restart ssh.service
fi

echo
echo "=== 6. Final local checks ==="

printf 'Hostname: '
hostnamectl --static

printf 'machine-id format: '
if [[ "$machine_id" =~ ^[0-9a-f]{32}$ ]]; then
    echo "OK (value hidden)"
else
    echo "INVALID"
    exit 1
fi

printf 'Wings state: '
systemctl is-active wings 2>/dev/null || true

printf 'Nginx state: '
systemctl is-active nginx 2>/dev/null || true

printf 'Backup: %s\n' "$BACKUP"

echo
echo "Preparation complete."
echo "Keep the network adapter disconnected."
echo "Reboot this Clone before reconnecting its network."
SCRIPT
~~~

### کار اسکریپت و محدودیت‌های آن

- hostname را به fc-node-01-test تنظیم می‌کند و /etc/hosts را برای نام محلی اصلاح می‌کند.
- machine-id و SSH host keys را برای کپی جدید تولید می‌کند.
- Wings، Nginx، Certbot timer و در صورت وجود Pterodactyl queue worker را روی Clone متوقف و disable می‌کند تا قبل از پیکربندی جدید، سرویس‌های کپی‌شده ناخواسته اجرا نشوند.
- از فایل‌های هویت کپی‌شده در مسیر پشتیبان محلی محافظت‌شده استفاده می‌کند. این پشتیبان برای rollback دستی است؛ اسکریپت rollback خودکار کامل نیست.
- **این اسکریپت شناسهٔ Node ذخیره‌شده در /etc/pterodactyl/config.yml، Domain، DNS یا گواهی TLS را به Node آزمایشی تبدیل نمی‌کند.** فایل Wings قدیمی باقی می‌ماند، ولی سرویس آن disabled است؛ تا وقتی config تازه‌ای از Node مستقل Panel تولید نکرده‌ایم، Wings را روشن نکن.
- اگر هر مرحله با خطا متوقف شد، شبکه را وصل نکن و فرمان‌های پاک‌سازی را حدس نزن؛ خروجی غیرحساس خطا را بررسی کن و از پشتیبان محلی بازیابی کنترل‌شده انجام بده.

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

## 10. چه زمانی شبکه را وصل کنیم؟

شبکه را فقط پس از تکمیل موفق مرحله‌های 8 و 9 وصل کن. این ترتیب عمداً محافظه‌کارانه است: Clone هنوز config قدیمی Wings و TLS را روی دیسک دارد و سرویس‌ها خاموش مانده‌اند.

1. در VMware، فقط روی fc-node-01-clone به **VM → Settings → Network Adapter** برو و Connect at power on را فعال کن یا اتصال شبکه را برقرار کن.
2. پس از بوت، IP جدید را پیدا کن؛ MAC جدید ممکن است باعث شود DHCP آدرس دیگری بدهد:

   ~~~bash
   ip -br address
   ip route
   ~~~

3. IP آزمایشگاهی را در روتر بررسی کن؛ در صورت نیاز DHCP reservation مجزا بساز. فرض نکن Clone همان IP ماشین اصلی را خواهد داشت.
4. برای دریافت بسته‌ها و انجام تست‌های اینترنتی، اتصال LAN/NAT معمولاً کافی است. اما **Wings و Nginx را هنوز enable یا start نکن** و Port Forward عمومی برای Clone نساز.
5. در Panel اصلی، یک Node آزمایشی مستقل بساز و برای آن FQDN، SSL و پورت‌های مناسب مستقل تنظیم کن. سپس config تازهٔ Wings را از همان Node آزمایشی بگیر و قبل از فعال‌کردن Wings، allowed_mounts و مسیرهای آزمایش را بررسی کن. config قدیمی را به‌عنوان config نهایی استفاده نکن.
6. گواهی کپی‌شده متعلق به نام قبلی است؛ پیش از راه‌اندازی HTTPS آزمایشگاهی، نام دامنه و گواهی صحیح Clone را جداگانه تنظیم کن. Certbot timer تا زمان تعیین دامنه/گواهی آزمایشگاهی disabled بماند.
7. اگر قرار است Clone در همان LAN کار کند، SSH را فقط با روش امن موجود و از کنسول تست کن. پورت SSH یا MariaDB/Redis را به اینترنت عمومی باز نکن.

**مهم:** تا زمانی که Node آزمایشی مستقل در Panel پیکربندی نشده، اجرای Wings روی Clone می‌تواند با هویت Node اصلی تداخل کند. این کار حتی پس از تغییر hostname و machine-id هم مجاز نیست.

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
