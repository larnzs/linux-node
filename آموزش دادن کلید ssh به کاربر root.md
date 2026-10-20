# آموزش دادن کلید SSH به کاربر Root

**هدف:** تنظیم Debian برای اینکه بتوان با WinSCP از طریق SFTP و کلید SSH وارد حساب Root شد و فایل‌های سیستمی را مدیریت کرد؛ بدون فعال‌کردن ورود Root با رمز SSH.

این آموزش بر اساس مراحل اجراشده و تست‌شده روی Node با کاربر مدیریتی `sv1` نوشته شده است. در Node دیگری، نام کاربر، مسیر کلید، نام فایل‌های تنظیمات و IP/FQDN را با وضعیت واقعی همان سیستم تطبیق بده.

> **هشدار امنیتی:** SFTP با دسترسی Root می‌تواند فایل‌های سیستمی و داده‌های سرویس‌ها را بخواند، آپلود یا بازنویسی کند و حذف کند. نشست SSH فعلی کاربر عادی را در تمام مراحل باز نگه دار. فقط روی Node خودت انجام بده و پیش از Reload کردن SSH، حتماً اعتبارسنجی تنظیمات را اجرا کن.

## 1. بررسی نشست و کلید SSH کاربر عادی

در SSH با کاربر عادی‌ای که دسترسی sudo دارد وارد شو؛ در این مثال نام کاربر `sv1` است.

~~~bash
sudo -v

if ! sudo test -s /home/sv1/.ssh/authorized_keys; then
    echo "ERROR: کلید مجاز sv1 پیدا نشد؛ فعلاً ادامه نده."
else
    echo "OK: کلید SSH کاربر sv1 موجود است."
fi
~~~

اگر پیغام OK ندیدی، ادامه نده؛ ابتدا باید مشخص شود کلید عمومی صحیح برای حساب کاربر عادی کجا ثبت شده است.

## 2. ایجاد محل کلیدهای Root و کپی کلید مجاز

روی Node مورد آزمایش، کلیدهای مجاز کاربر `sv1` به فایل مجاز Root کپی شدند. این روش باعث می‌شود همان کلید خصوصی Windows بتواند با نام کاربری Root نیز احراز هویت کند.

~~~bash
sudo install -d -o root -g root -m 700 /root/.ssh
sudo touch /root/.ssh/authorized_keys

sudo sh -c '
while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    grep -Fqx -- "$line" /root/.ssh/authorized_keys ||
        printf "%s\n" "$line" >> /root/.ssh/authorized_keys
done < /home/sv1/.ssh/authorized_keys
'

sudo chown root:root /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys

sudo ls -ld /root/.ssh
sudo ls -l /root/.ssh/authorized_keys
~~~

مجوزهای مورد انتظار:

- مسیر /root/.ssh باید متعلق به root باشد و مجوز 700 داشته باشد.
- فایل /root/.ssh/authorized_keys باید متعلق به root باشد و مجوز 600 داشته باشد.

**ملاحظه امنیتی:** این روش همه کلیدهای ثبت‌شده برای sv1 را به Root نیز مجاز می‌کند. برای امنیت بهتر در نصب جدید، یک کلید SSH جداگانه و اختصاصی Root بساز و فقط کلید عمومی همان را در /root/.ssh/authorized_keys اضافه کن. هرگز فایل کلید خصوصی را به Debian منتقل نکن.

## 3. بررسی تنظیمات فعلی SSH

ابتدا مطمئن شو فایل تنظیمات اصلی، فایل‌های داخل sshd_config.d را بارگذاری می‌کند:

~~~bash
sudo grep -n '^[[:space:]]*Include.*sshd_config.d' /etc/ssh/sshd_config
sudo ls -lah /etc/ssh/sshd_config.d/
~~~

سپس تنظیمات مؤثر مرتبط با احراز هویت را بررسی کن:

~~~bash
sudo grep -HniE '^[[:space:]]*(Include|Match|AuthenticationMethods|PasswordAuthentication|KbdInteractiveAuthentication|ChallengeResponseAuthentication|PermitRootLogin|PubkeyAuthentication|AllowUsers|DenyUsers|AuthorizedKeysFile)([[:space:]]|$)' \
    /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf
~~~

در نصب این Node، دو فایل با هم ناسازگار بودند:

- /etc/ssh/sshd_config.d/00-fragcity-hardening.conf
- /etc/ssh/sshd_config.d/00-fragcity-password-only.conf

فایل password-only شامل PasswordAuthentication yes، PubkeyAuthentication no و AuthenticationMethods password بود؛ در حالی که فایل hardening احراز هویت رمز را غیرفعال می‌کرد. این تناقض باعث خطای زیر هنگام اعتبارسنجی/Reload شد:

~~~text
Disabled method "password" in AuthenticationMethods list "password"
AuthenticationMethods cannot be satisfied by enabled authentication methods
~~~

نام و محتوای فایل‌ها در Nodeهای دیگر ممکن است متفاوت باشد؛ قبل از تغییر، همیشه خروجی بررسی بالا را بخوان.

## 4. گرفتن نسخه پشتیبان و خارج‌کردن تنظیم متعارض از مسیر بارگذاری

در Node مورد آزمایش، فایل password-only ابتدا پشتیبان‌گیری شد و سپس از پوشه sshd_config.d خارج شد. نسخه پشتیبان و فایل غیرفعال‌شده در /etc/ssh نگه داشته شدند.

~~~bash
set -eu

STAMP=$(date +%Y%m%d-%H%M%S)
HARDENING=/etc/ssh/sshd_config.d/00-fragcity-hardening.conf
PASSWORD_ONLY=/etc/ssh/sshd_config.d/00-fragcity-password-only.conf

# توقف امن اگر فایل‌ها مطابق انتظار وجود ندارند
sudo test -f "$HARDENING"
sudo test -f "$PASSWORD_ONLY"

# نسخه‌های پشتیبان
sudo cp -a "$HARDENING" "/etc/ssh/00-fragcity-hardening.conf.bak-$STAMP"
sudo cp -a "$PASSWORD_ONLY" "/etc/ssh/00-fragcity-password-only.conf.saved-$STAMP"

# بیرون بردن فایل متعارض از پوشه‌ای که sshd بارگذاری می‌کند
sudo mv "$PASSWORD_ONLY" "/etc/ssh/00-fragcity-password-only.conf.disabled-$STAMP"
~~~

این فرمان فایل غیرفعال‌شده را حذف نمی‌کند؛ آن را در مسیر دیگری نگه می‌دارد. فایل‌های داخل /etc/ssh/sshd_config.d که پسوند .conf دارند، بر اساس تنظیم Include بارگذاری می‌شوند.

## 5. فعال‌کردن ورود Root با کلید و غیرفعال نگه‌داشتن رمز

در این Node، فایل hardening پس از پشتیبان‌گیری به تنظیم زیر تغییر یافت:

~~~bash
HARDENING=/etc/ssh/sshd_config.d/00-fragcity-hardening.conf

sudo sed -i -E \
  's/^[[:space:]]*PermitRootLogin[[:space:]]+no[[:space:]]*$/PermitRootLogin prohibit-password/' \
  "$HARDENING"

sudo tee /etc/ssh/sshd_config.d/00-fragcity-root-key-only.conf >/dev/null <<'EOF'
PermitRootLogin prohibit-password
PubkeyAuthentication yes
EOF

sudo cat "$HARDENING"
sudo cat /etc/ssh/sshd_config.d/00-fragcity-root-key-only.conf
~~~

فایل hardening نهایی روی Node آزمایش‌شده این محتوا را داشت:

~~~text
PubkeyAuthentication yes
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
~~~

تنظیمات نهایی یعنی:

- احراز هویت با کلید عمومی فعال است.
- Root می‌تواند با کلید SSH وارد شود.
- ورود Root با رمز SSH مجاز نیست.
- PasswordAuthentication همچنان no باقی می‌ماند.

در OpenSSH ممکن است مقدار مؤثر PermitRootLogin در خروجی به شکل `without-password` نمایش داده شود؛ این نام قدیمی/معادل همان رفتار prohibit-password است.

## 6. اعتبارسنجی پیش از Reload

این مرحله الزامی است. ابتدا نحو تنظیمات را بررسی کن:

~~~bash
sudo /usr/sbin/sshd -t
~~~

اگر دستور خطا چاپ کرد، **SSH را Reload یا Restart نکن** و خطا را بررسی کن.

اگر اعتبارسنجی موفق بود، تنظیمات مؤثر Root را ببین:

~~~bash
sudo /usr/sbin/sshd -T -C user=root,host=localhost,addr=127.0.0.1 \
  | grep -E '^(permitrootlogin|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|authenticationmethods|authorizedkeysfile)'
~~~

روی Node مورد آزمایش، خروجی مؤثر شامل این موارد بود:

~~~text
permitrootlogin without-password
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
authorizedkeysfile .ssh/authorized_keys .ssh/authorized_keys2
authenticationmethods any
~~~

ممکن است خروجی دقیق با نسخه یا تنظیمات سیستم متفاوت باشد. مطمئن شو Root فقط با کلید مجاز است و هیچ تنظیم متعارضی باقی نمانده است.

## 7. Reload کردن SSH

فقط پس از موفقیت هر دو بررسی بالا اجرا کن:

~~~bash
sudo systemctl reload ssh
sudo systemctl status ssh --no-pager
~~~

وضعیت سرویس باید active (running) باشد و Reload نباید خطا بدهد. نشست فعلی SSH را نبند؛ تا وقتی ورود جدید با Root واقعاً آزمایش نشده، آن نشست را برای بازیابی نگه دار.

## 8. آزمایش ورود Root از PowerShell

روی Windows یک پنجره PowerShell جدید باز کن. آدرس مورد استفاده باید IP یا FQDN خود Debian Node باشد، نه IP کامپیوتر Windows.

در Node مورد آزمایش، کلید خصوصی موجود در مسیر زیر استفاده شد:

~~~text
%USERPROFILE%\.ssh\id_ed25519_fragcity
~~~

برای جلوگیری از استفاده اشتباه از IP، آدرس Node را وارد کن:

~~~powershell
$Node = Read-Host "Debian Node IP or FQDN"
ssh -i "$env:USERPROFILE\.ssh\id_ed25519_fragcity" -o IdentitiesOnly=yes "root@$Node"
~~~

پس از ورود موفق، در ترمینال Debian اجرا کن:

~~~bash
whoami
id
~~~

خروجی whoami باید root باشد.

اگر ورود ناموفق شد، نشست sv1 را نبند. لاگ‌ها را بررسی کن:

~~~bash
sudo journalctl -u ssh -n 80 --no-pager
sudo passwd -S root
~~~

خطای Permission denied را با فعال‌کردن ورود Root با رمز دور نزن؛ مسیر کلید، مجوزهای فایل‌ها، IP/پورت و تنظیمات مؤثر را بررسی کن.

## 9. تنظیم WinSCP

پس از موفقیت تست PowerShell، در WinSCP یک Session جدید بساز تا Session معمولی sv1 دست‌نخورده باقی بماند.

| گزینه | مقدار |
|---|---|
| File protocol | SFTP |
| Host name | IP یا FQDN خود Debian Node |
| Port number | پورت SSH؛ معمولاً 22 |
| User name | root |
| Password | خالی؛ احراز هویت با کلید انجام می‌شود |
| Private key file | همان کلید خصوصی Windows که در تست SSH استفاده شد |

در Advanced → SSH → Authentication کلید خصوصی صحیح را انتخاب کن. اگر WinSCP قالب OpenSSH را نپذیرفت، از PuTTYgen نسخه .ppk بساز و همان فایل .ppk را انتخاب کن. فایل کلید خصوصی را به سرور کپی نکن.

پیش از تأیید نخستین اتصال، اثر انگشت میزبان SSH را از کنسول یا منبع قابل‌اعتماد بررسی کن.

با ورود Root در WinSCP می‌توانی فایل‌ها را در مسیرهای سیستمی آپلود یا جایگزین کنی، اما پیش از هر تغییر مسیر مقصد و مالکیت موردنیاز سرویس را بررسی کن. آپلود فایل به‌عنوان Root معمولاً مالک فایل را root می‌کند؛ این ممکن است برای فایل‌هایی که Pterodactyl یا سرویس دیگری باید بنویسد مناسب نباشد.

## 10. عیب‌یابی خطاهای رایج

### خطای AuthenticationMethods cannot be satisfied

تنظیمات متعارضی مانند AuthenticationMethods password همراه با PasswordAuthentication no را پیدا کن. فایل متعارض را فقط پس از گرفتن نسخه پشتیبان و بررسی محتوا از مسیر بارگذاری خارج کن؛ فایل را بدون بررسی حذف نکن.

### خطای Permission denied (publickey)

- مطمئن شو کلید خصوصی انتخاب‌شده با کلید عمومی ثبت‌شده در /root/.ssh/authorized_keys متناظر است.
- مالکیت و مجوزها را بررسی کن:

  ~~~bash
  sudo ls -ld /root /root/.ssh
  sudo ls -l /root/.ssh/authorized_keys
  ~~~

- لاگ SSH را بخوان:

  ~~~bash
  sudo journalctl -u ssh -n 80 --no-pager
  ~~~

### sshd -t ناموفق است

تا رفع خطا، Reload یا Restart نکن. تنظیمات اصلی و تمام فایل‌های داخل sshd_config.d را بررسی کن.

## 11. بازگرداندن عدم دسترسی SSH مستقیم برای Root

اگر خواستی ورود Root از طریق SSH را دوباره غیرفعال کنی، ابتدا از نشست sv1 اجرا کن:

~~~bash
sudo sed -i -E \
  's/^[[:space:]]*PermitRootLogin[[:space:]]+prohibit-password[[:space:]]*$/PermitRootLogin no/' \
  /etc/ssh/sshd_config.d/00-fragcity-hardening.conf

sudo rm -f /etc/ssh/sshd_config.d/00-fragcity-root-key-only.conf

sudo /usr/sbin/sshd -t
sudo systemctl reload ssh
sudo systemctl status ssh --no-pager
~~~

فقط بعد از موفقیت اعتبارسنجی و Reload، دسترسی Root از SSH را آزمایش کن. این روش ورود Root را می‌بندد اما کلید را از authorized_keys پاک نمی‌کند. اگر می‌خواهی کلید را هم حذف کنی، فقط خط کلید افزوده‌شده را از /root/.ssh/authorized_keys پاک کن؛ اگر فایل از قبل کلیدهای دیگری داشته، کل فایل را حذف نکن.

فایل غیرفعال‌شده password-only را بدون بررسی دوباره به sshd_config.d برنگردان؛ آن فایل عامل تعارض بود و بازگرداندنش ممکن است دوباره اعتبارسنجی SSH را خراب کند.

## 12. نکات نهایی

- نشست SSH کاربر عادی را تا پایان آزمایش حفظ کن.
- قبل از هر تغییر پیکربندی از فایل موجود نسخه پشتیبان بگیر.
- پیش از هر Reload، دستور /usr/sbin/sshd -t باید موفق شود.
- رمز SSH برای Root را فعال نکن.
- از chmod -R 777 استفاده نکن.
- کلید خصوصی را در GitHub، چت یا سرور قرار نده؛ فقط کلید عمومی روی Debian قرار می‌گیرد.
- ورود Root در WinSCP را فقط وقتی لازم داری استفاده کن و پس از پایان کار، در صورت عدم نیاز، دسترسی را غیرفعال کن.
