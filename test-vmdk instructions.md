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
| Hostname فعلی Clone | fc-node-01-test؛ اسکریپت بخش 7 آن را برای حالت جایگزین موقت به fc-node-01 برمی‌گرداند |
| وضعیت Wings داخل Clone | قبلاً متوقف/disable شده؛ پس از اصلاح Port Forwardها در بخش 9 دوباره enable/start می‌شود |
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

## 5. اولین بوت و هدف این Clone

در اولین بوت، Network Adapter را قطع کن و اگر VMware پرسید، گزینهٔ **I Copied It** را انتخاب کن. بعد از اینکه Debian بالا آمد، برای دسترسی SSH شبکه را دوباره متصل کردی و مودم IP **192.168.1.9** را به MAC جدید Clone داده است.

**تصمیم این فاز:** این Clone یک Node آزمایشی تازه و مستقل در Pterodactyl نیست؛ فعلاً قرار است موقتاً جای VM اصلی را بگیرد. تا پایان تست، VM اصلی کاملاً خاموش می‌ماند و فقط Clone روشن خواهد بود. بنابراین باید همان Panel، پایگاه‌داده، تنظیمات Wings، Nginx، PHP-FPM، MariaDB، Redis و گواهی‌های فعلی در Clone کار کنند.

**اسکریپت قبلی که Wings، Nginx، PHP-FPM، MariaDB، Redis، Certbot و cron را disable می‌کرد اجرا نکن.** برای این سناریو هم machine-id و SSH host keys را بازتولید نکن؛ چون Clone موقتاً جایگزین همان VM است، نه Node دومی که هم‌زمان اجرا شود. MAC و IP جدید به‌خودی‌خود مشکلی ایجاد نمی‌کنند.

## 6. قوانین ایمنی تا پایان تست

1. VM اصلی روشن نشود؛ هیچ‌وقت دو کپی را هم‌زمان روشن نکن.
2. Clone فعلی IP برابر **192.168.1.9** دارد؛ IP اصلی **192.168.1.7** را در روتر حفظ کن.
3. تنظیمات Panel و Wings در Clone را نگه می‌داریم؛ فقط hostname را به مقدار اصلی برمی‌گردانیم و Wings را پس از اصلاح Port Forwardها دوباره فعال می‌کنیم.
4. DNS عمومی و گواهی‌های فعلی را تغییر نده، مگر اینکه IP عمومی WAN واقعاً عوض شده باشد.
5. Port Forwardهای موجود را duplicate نکن. در زمان استفاده از Clone، مقصد قوانین مربوط به این VM را از 192.168.1.7 به 192.168.1.9 تغییر بده؛ در پایان تست مقصدها را برگردان.
6. برای این مرحله فقط پورت‌های فعلی را مدیریت کن: TCP 80/443 برای Panel، TCP 8080 برای Wings API، TCP 2022 برای SFTP. چون هنوز CS2 Instance نداریم، پورت بازی اضافه نکن.
7. برای MAC جدید Clone در مودم DHCP reservation برابر 192.168.1.9 بساز.

## 7. برگرداندن نام میزبان به نام اصلی

hostname فعلی Clone به fc-node-01-test تغییر داده شده است. چون این VM فعلاً جایگزین VM اصلی است و اصلی خاموش می‌ماند، hostname را در Clone به fc-node-01 برمی‌گردانیم تا با تنظیمات سرویس‌های کپی‌شده هم‌خوان باشد.

این اسکریپت فقط hostname و /etc/hosts را اصلاح می‌کند. machine-id، SSH host keys، گواهی‌ها، Wings config یا وضعیت سرویس‌ها را تغییر نمی‌دهد. آن را فقط از SSH به Clone با IP فعلی 192.168.1.9 اجرا کن.

~~~bash
sudo bash <<'SCRIPT'
set -Eeuo pipefail

TARGET_IP="192.168.1.9"
TARGET_HOST="fc-node-01"

if ! ip -o -4 address show | grep -q '192\.168\.1\.9/'; then
    echo "ERROR: This machine does not currently have 192.168.1.9."
    echo "Nothing changed. Verify that this is the Clone."
    exit 1
fi

CURRENT_HOST="$(hostnamectl --static)"
if [[ "$CURRENT_HOST" != "fc-node-01-test" && "$CURRENT_HOST" != "fc-node-01" ]]; then
    echo "ERROR: Unexpected hostname: $CURRENT_HOST"
    echo "Nothing changed."
    exit 1
fi

echo "Clone IP: $TARGET_IP"
echo "Current hostname: $CURRENT_HOST"
echo "Target hostname: $TARGET_HOST"
echo "Original VM must remain powered off."
read -r -p "Type ACTIVATE-CLONE to continue: " confirmation </dev/tty

if [[ "$confirmation" != "ACTIVATE-CLONE" ]]; then
    echo "Cancelled. No changes made."
    exit 1
fi

BACKUP="/root/fc-clone-activate-$(date +%Y%m%d-%H%M%S)"
install -d -m 700 "$BACKUP"
cp -a /etc/hostname /etc/hosts "$BACKUP/"
chmod -R go-rwx "$BACKUP"

hostnamectl set-hostname "$TARGET_HOST"

python3 - "$TARGET_HOST" <<'PY'
import sys
from pathlib import Path

target = sys.argv[1]
old_names = {"fc-node-01-test", "fc-node-01-test.fragcity.ir"}

path = Path("/etc/hosts")
lines = path.read_text().splitlines()
output = []
has_local_entry = False

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
        aliases = []
        for item in fields[1:]:
            if item in old_names:
                continue
            aliases.append(item)
        if "fc-node-01" not in aliases:
            aliases.insert(0, "fc-node-01")
        if "fc-node-01.fragcity.ir" not in aliases:
            aliases.append("fc-node-01.fragcity.ir")
        output.append(
            fields[0] + "\t" + " ".join(dict.fromkeys(aliases))
            + ((" #" + comment) if marker else "")
        )
        has_local_entry = True
        continue

    changed = False
    for index in range(1, len(fields)):
        if fields[index] in old_names:
            fields[index] = (
                "fc-node-01.fragcity.ir"
                if fields[index].endswith(".fragcity.ir")
                else "fc-node-01"
            )
            changed = True

    output.append(
        "\t".join(fields) + ((" #" + comment) if marker else "")
        if changed else line
    )

if not has_local_entry:
    output.append("127.0.1.1\tfc-node-01 fc-node-01.fragcity.ir")

path.write_text("\n".join(output) + "\n")
PY

echo
echo "=== Hostname ==="
hostnamectl --static
cat /etc/hostname

echo
echo "=== Local host mappings ==="
grep -nE 'fc-node-01|127[.]0[.]1[.]1' /etc/hosts || true

echo
echo "=== Current service states; this script does not change them ==="
for unit in nginx.service php8.3-fpm.service mariadb.service redis-server.service pteroq.service wings.service; do
    printf '%s active=' "$unit"
    systemctl is-active "$unit" 2>/dev/null || true
    printf '%s enabled=' "$unit"
    systemctl is-enabled "$unit" 2>/dev/null || true
done

echo
echo "Hostname restoration complete."
echo "No service was started or stopped."
echo "Backup directory: $BACKUP"
SCRIPT
~~~

اسکریپت بالا سرویس‌ها را روشن نمی‌کند. ابتدا Port Forwardهای روتر را به 192.168.1.9 تغییر بده؛ سپس Wings را فعال می‌کنیم.

## 8. تغییر Port Forwardها برای استفاده از Clone

در روتر، در حالی که VM اصلی خاموش است، قوانین موجود را ویرایش کن:

| پورت ورودی | پروتکل | مقصد قبلی | مقصد زمان تست |
|---|---|---|---|
| 80 | TCP | 192.168.1.7 | 192.168.1.9 |
| 443 | TCP | 192.168.1.7 | 192.168.1.9 |
| 8080 | TCP | 192.168.1.7 | 192.168.1.9 |
| 2022 | TCP | 192.168.1.7 | 192.168.1.9 |

قبل از تغییر، جدول واقعی روتر را ببین و فقط قوانین همین سرویس‌ها را ویرایش کن. قوانین دیگری را که مربوط به میزبان دیگرند تغییر نده.

- DHCP reservation برای MAC جدید Clone را روی 192.168.1.9 ثبت کن.
- به DNS عمومی دست نزن، مگر اینکه IP عمومی WAN تغییر کرده باشد.
- پورت SSH 22 لازم نیست به اینترنت عمومی باز شود؛ SSH از LAN به 192.168.1.9 کار می‌کند.
- پورت‌های CS2 را فعلاً اضافه نکن.

## 9. برگرداندن Wings و بررسی سرویس‌ها

بعد از اصلاح Port Forwardها، از SSH به 192.168.1.9 اجرا کن:

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

## 10. پایان تست و بازگشت به VM اصلی

وقتی تست تمام شد:

1. در Clone دستور sudo systemctl poweroff را اجرا کن و در VMware مطمئن شو وضعیت **Powered Off** است.
2. مقصد Port Forwardهای 80، 443، 8080 و 2022 را از 192.168.1.9 به 192.168.1.7 برگردان.
3. فقط پس از خاموش‌شدن کامل Clone، VM اصلی را روشن کن.
4. روی VM اصلی IP برابر 192.168.1.7 و کارکرد Panel/Wings را بررسی کن.

هرگز دو VM را هم‌زمان روشن نکن. اگر در آینده نیاز به اجرای هم‌زمان دو Node باشد، باید یک Node آزمایشی مستقل با هویت، دامنه و config اختصاصی طراحی شود.

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
- [x] Full Clone ساخته شد.
- [x] در بوت اول Clone گزینهٔ I Copied It انتخاب شد.
- [x] MAC کپی مستقل است و DHCP فعلاً IP برابر 192.168.1.9 داده است.
- [x] hostname داخل Clone به fc-node-01 برگردانده شد؛ mapping محلی /etc/hosts نیز به نام اصلی اشاره می‌کند.
- [x] Nginx، PHP 8.3-FPM، MariaDB و Redis روی Clone فعال گزارش شده‌اند.
- [x] Wings روی Clone دوباره enable و start شد و از بارگذاری config و درخواست فهرست سرورها شروع کرده است.
- [ ] در اجرای قبلی sudo ابتدا هشدار unable to resolve host fc-node-01-test دیده شد؛ پس از تغییر hostname و /etc/hosts، با getent hosts fc-node-01 و sudo -v بررسی نهایی شود.
- [ ] وضعیت pteroq بررسی شود؛ خروجی فعلی نشان می‌دهد pteroq.service به‌صورت واحد systemd قابل یافتن نیست. فعلاً سرویس دیگری را نصب/تغییر نده.
- [ ] تأیید کن Port Forwardهای موجود TCP 80/443/8080/2022 اکنون به 192.168.1.9 اشاره می‌کنند؛ این تغییر هنوز در گفت‌وگو صریحاً تأیید نشده است.
- [ ] در صورت تأیید مقصد Port Forward، دسترسی https://panel.fragcity.ir و وضعیت Node داخل Panel بررسی شود.
- [ ] VMDK دادهٔ دوم فقط به Clone اضافه شود.
- [ ] دیسک تازه با lsblk و blkid شناسایی شود؛ تا قبل از تأیید فرمت نشود.
- [ ] آزمون CS2-Egg-Go و Shared Base روی Clone اجرا شود.
- [ ] در بازگشت، ابتدا Clone خاموش، بعد Port Forwardها به 192.168.1.7 برگردانده شوند و سپس VM اصلی روشن شود.

**آخرین checkpoint:** Clone با IP داخلی 192.168.1.9 روشن است. hostname به fc-node-01 برگشته است. Nginx، PHP-FPM، MariaDB و Redis فعال گزارش شده‌اند؛ Wings نیز فعال/enable شده است. pteroq.service در خروجی به‌صورت واحد موجود شناخته نشده و باید جداگانه بررسی شود. وضعیت مقصد Port Forwardها هنوز تأیید نشده است. Clone موقتاً جای VM اصلی را می‌گیرد؛ VM اصلی باید تا پایان تست خاموش بماند. machine-id و SSH host keys عمداً تغییر داده نشده‌اند و باید همین‌طور باقی بمانند. تا قبل از شناسایی دیسک تازه، هیچ فرمان formatting اجرا نشود.
