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
# Expected temporary Clone identity:
#   hostname: fc-node-01
#   LAN IPv4: 192.168.1.9

set -uo pipefail
export LC_ALL=C

EXPECTED_HOST="fc-node-01"
EXPECTED_IP="192.168.1.9"

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
echo "  - Router Port Forward rules really target 192.168.1.9 during this test."
echo "  - The Panel shows the Node online in its UI."
echo "  - The original VM remains powered off."
echo "  - CS2 Base/instances are not installed yet; identify the second VMDK before formatting."
echo
echo "This script is read-only; it does not fix any reported issue."

SCRIPT
~~~

### تفسیر نتیجه

### نتیجهٔ آخرین اجرای health check — 2026-10-18

- نتیجهٔ اسکریپت: **24 PASS / 1 WARN / 0 FAIL**.
- Hostname برابر `fc-node-01` و IP برابر `192.168.1.9` است؛ `/etc/hosts` نام میزبان را resolve می‌کند.
- Nginx، PHP 8.3-FPM، MariaDB، Redis، Docker و Wings فعال بودند. تست Nginx موفق بود، HTTPS محلی `panel.fragcity.ir` پاسخ HTTP 200 داد، و گواهی‌های Panel/Node بیش از 14 روز تا انقضا داشتند.
- پورت‌های TCP 80، 443، 8080 و 2022 در حالت LISTEN بودند. MariaDB socket ping و Redis PING موفق بودند. Root filesystem تقریباً 1% مصرف و حدود 253 GB آزاد داشت. خطای سطح بالا در سرویس‌های پایش‌شده طی 15 دقیقهٔ اخیر دیده نشد.
- تنها WARN اسکریپت این بود که واحد systemd به نام pteroq.service پیدا نشد. بررسی بعدی نیز هیچ Queue Worker در حال اجرا، هیچ systemd unit مرتبط و هیچ cron entry برای artisan schedule:run پیدا نکرد. این یعنی Queue/Scheduler به‌احتمال زیاد هنوز پیکربندی نشده‌اند؛ قبل از ساخت سرویس جدید، مسیر واقعی Panel و مقدار غیرمحرمانه QUEUE_CONNECTION را تأیید می‌کنیم. طبق راهنمای رسمی Pterodactyl v1، نصب استاندارد به queue worker و cron برای اجرای schedule:run نیاز دارد: https://docs.pterodactyl.io/v1/panel/getting-started
- قانون ورودی `29001/udp` در UFW عمداً برای سرور CS2 آینده باز نگه داشته شده است؛ بنا به تصمیم کاربر، آن را حذف، تغییر یا دوباره عیب‌یابی نکن.
- اسکریپت نتوانسته مقصد Port Forward روتر یا وضعیت Online نود در UI پنل را اثبات کند. این دو مورد هنوز باید دستی تأیید شوند. خروجی خام ترمینال در این سند ذخیره نشده است.

### راه‌اندازی Queue Worker و Scheduler — منبع واحد در README

پیش‌بررسی 2026-10-18 تأیید کرد PHP CLI برابر 8.3.35 است، Artisan با کاربر www-data اجرا می‌شود، نسخهٔ Laravel برابر 12.64.0 است، QUEUE_CONNECTION=redis تنظیم شده و Redis/Cron فعال‌اند؛ اما pteroq.service و cron entry مربوط به schedule:run پیدا نشدند.

راه‌حل استاندارد نصب اکنون به‌عنوان مرحلهٔ ضروری **3.4.1** در README اصلی قرار دارد، بر اساس راهنمای رسمی Pterodactyl 1.x:

[README.md — مرحلهٔ 3.4.1: راه‌اندازی اجباری Queue Worker و Scheduler](https://github.com/larnzs/linux-node/blob/main/README.md)

**این دستورها را اکنون روی Clone فعال با IP 192.168.1.9 اجرا کن.** اسکریپت قبل از تغییر، hostname، IP مجاز، مسیر Panel، QUEUE_CONNECTION=redis، Redis، Cron و فرمان‌های Artisan را بررسی می‌کند؛ اگر Unit متفاوتی از قبل وجود داشته باشد بازنویسی نمی‌کند؛ از crontab root نسخهٔ پشتیبان می‌گیرد؛ سپس pteroq.service و scheduler cron را آماده و وضعیتشان را بررسی می‌کند.

این اصلاح در نصب اولیه جا افتاده بود؛ این مرحله حالا در ترتیب نصب اصلی، پیش از پیکربندی NGINX، ثبت شده است. چون هر VM دیسک جدا دارد، هنگام بازگشت از Clone به VMDK اصلی همین مرحلهٔ README را جداگانه روی VM اصلی نیز اجرا کن. هرگز دو VM را هم‌زمان روشن نکن.

**پورت 29001/udp** برای CS2 آینده عمداً باز است و در مراحل Queue/Scheduler نباید تغییر کند.

پس از اجرای موفق، معیار قبولی این است که pteroq.service هم active و هم enabled باشد و خط /var/www/pterodactyl/artisan schedule:run در crontab ریشه وجود داشته باشد. خروجی نهایی را برای تأیید بفرست.

## 11. پایان تست و بازگشت به VM اصلی

وقتی تست تمام شد:

1. در Clone دستور sudo systemctl poweroff را اجرا کن و در VMware مطمئن شو وضعیت **Powered Off** است.
2. مقصد Port Forwardهای 80، 443، 8080 و 2022 را از 192.168.1.9 به 192.168.1.7 برگردان.
3. فقط پس از خاموش‌شدن کامل Clone، VM اصلی را روشن کن.
4. روی VM اصلی IP برابر 192.168.1.7 و کارکرد Panel/Wings را بررسی کن.

هرگز دو VM را هم‌زمان روشن نکن. اگر در آینده نیاز به اجرای هم‌زمان دو Node باشد، باید یک Node آزمایشی مستقل با هویت، دامنه و config اختصاصی طراحی شود.

## 12. افزودن VMDK دادهٔ دوم — فقط به Clone

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

## 13. محدودهٔ PoC مربوط به CS2 Shared Base

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

## 14. چک‌لیست مرحلهٔ جاری

- [x] فضای آزاد Windows host بررسی شد؛ D در زمان بررسی حدود 301.8 GB آزاد داشت.
- [x] مسیر VMX روی C و فایل VMDK روی D پیدا شد.
- [x] Full Clone ساخته شد؛ VMware گزینهٔ I Copied It را در اولین بوت انتخاب کرد.
- [x] MAC کلون جدید است و DHCP فعلاً IP برابر 192.168.1.9 داده است.
- [x] hostname داخل Clone به fc-node-01 برگردانده شد؛ /etc/hosts نام میزبان را resolve می‌کند.
- [x] Health check فقط‌خواندنی نتیجهٔ 24 PASS / 1 WARN / 0 FAIL داد.
- [x] Nginx، PHP 8.3-FPM، MariaDB، Redis، Docker و Wings فعال گزارش شده‌اند؛ Nginx test و HTTPS محلی Panel موفق بودند.
- [x] مسیر Panel برابر /var/www/pterodactyl، نسخه Laravel برابر 12.64.0، QUEUE_CONNECTION برابر redis و Cron فعال است.
- [x] PHP CLI در /usr/bin/php نسخه 8.3.35 است؛ www-data می‌تواند Artisan را اجرا کند و queue:work و schedule:run موجودند.
- [x] هیچ Queue Worker در حال اجرا و هیچ Scheduler cron entry برای artisan schedule:run پیدا نشد.
- [x] قانون UFW ورودی 29001/udp عمداً برای سرور CS2 آینده باز است؛ طبق تصمیم کاربر آن را تغییر نده.
- [ ] بلوک استاندارد README بخش 3.4.1 روی Clone اجرا شود تا pteroq.service و Scheduler cron ایجاد و تأیید شوند.
- [ ] تأیید شود pteroq.service فعال/enabled است و خط schedule:run در crontab root وجود دارد.
- [ ] مقصد Port Forwardهای موجود TCP 80/443/8080/2022 در روتر به 192.168.1.9 تأیید شود؛ health check این مورد را اثبات نمی‌کند.
- [ ] دسترسی بیرونی Panel و Online بودن Node در UI پنل جداگانه تأیید شود.
- [ ] VMDK دادهٔ دوم فقط به Clone اضافه شود.
- [ ] دیسک تازه با lsblk و blkid شناسایی شود؛ تا قبل از تأیید فرمت نشود.
- [ ] آزمون CS2-Egg-Go و Shared Base روی Clone اجرا شود.
- [ ] هنگام بازگشت، ابتدا Clone خاموش، سپس Port Forwardها به 192.168.1.7 برگردانده شوند و بعد VM اصلی روشن شود؛ سپس مرحله 3.4.1 README روی VMDK اصلی هم اجرا شود.

**آخرین checkpoint:** Clone موقتاً جای VM اصلی را می‌گیرد، با IP برابر 192.168.1.9 و hostname برابر fc-node-01. Health check محلی موفق بود (24 PASS / 1 WARN / 0 FAIL). PHP CLI/Artisan پیش‌بررسی شدند؛ مسیر Panel و QUEUE_CONNECTION=redis مشخص است، Redis و Cron فعال‌اند، اما Queue Worker و Scheduler cron هنوز باید با بلوک استاندارد مرحلهٔ 3.4.1 README روی Clone راه‌اندازی و تأیید شوند. پورت 29001/udp بنا به تصمیم کاربر برای CS2 آینده باز می‌ماند و نباید تغییر کند. مقصد Port Forward و Online بودن Node در UI پنل باید دستی تأیید شوند. هنوز هیچ CS2 Base/Instance نصب نشده و دیسک تازه نباید پیش از شناسایی با lsblk/blkid فرمت شود. VM اصلی تا پایان تست خاموش بماند؛ machine-id و SSH host keys تغییر داده نشده‌اند. هر تغییری که روی Clone اعمال می‌شود، قبل از بازگشت باید جداگانه روی VM اصلی نیز اعمال شود، چون این دو دیسک مستقل‌اند.
