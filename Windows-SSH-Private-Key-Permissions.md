# راهنمای رفع خطای SSH Private Key در ویندوز پس از نصب مجدد Windows

این راهنما برای زمانی است که بعد از نصب مجدد ویندوز یا انتقال فایل‌های `.ssh`، اتصال SSH به Linux با خطای زیر رد می‌شود:

```text
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions for '...id_ed25519...' are too open.
This private key will be ignored.
Load key "...": bad permissions
user@server: Permission denied (publickey).
```

در این وضعیت ممکن است کلید خصوصی سالم باشد، اما فایل هنوز مالک یا Permissionهای حساب ویندوز قبلی را داشته باشد. **ابتدا دسترسی فایل را اصلاح کن؛ کلید جدید نساز و تنظیمات SSH سرور را بی‌دلیل تغییر نده.**

## 1. مقادیر و مسیر کلید را بررسی کن

PowerShell را با همان حساب ویندوزی باز کن که قرار است از آن SSH بزند:

```powershell
$keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519_fragcity"

if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
    throw "SSH private key not found: $keyPath"
}

Write-Host "Windows user:"
whoami

Write-Host "`nKey file:"
Get-Item -LiteralPath $keyPath | Select-Object FullName, Length, Attributes

Write-Host "`nOwner:"
(Get-Acl -LiteralPath $keyPath).Owner

Write-Host "`nPermissions:"
icacls.exe $keyPath

Write-Host "`nDetailed access rules:"
(Get-Acl -LiteralPath $keyPath).Access |
    Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited -AutoSize
```

نشانهٔ مهم این است که مالک فایل یک SID ناشناس از ویندوز قبلی باشد یا ACL شامل SID قدیمی، گروه Administrators، یا SYSTEM با دسترسی گسترده باشد.

> هرگز محتوای فایل Private Key را در چت، تیکت یا GitHub قرار نده. برای عیب‌یابی، نام فایل و خروجی Permissionها کافی است.

## 2. روش تأییدشده برای اصلاح Permission فایل کلید در Windows

در ویندوز تازه‌نصب‌شده ممکن است فایل کلید خصوصی مالک و ACL ویندوز قبلی را نگه داشته باشد. در این حالت فقط عوض‌کردن Owner یا حذف چند SID به‌صورت جداگانه کافی نیست. روش زیر ACL همان فایل را از نو تنظیم می‌کند؛ این روش در محیط FragCity آزمایش شد و مشکل را برطرف کرد.

**محل اجرا:** Windows PowerShell با همان حساب ویندوزی که برای SSH استفاده می‌کنی. اگر دسترسی لازم را نداری، PowerShell را با گزینهٔ **Run as administrator** و همان حساب کاربری باز کن؛ مسیر USERPROFILE باید همچنان پوشهٔ کاربر اصلی را نشان دهد.

~~~powershell
$keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519_fragcity"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
    throw "SSH private key not found: $keyPath"
}

Write-Host "Key path: $keyPath"
Write-Host "Windows user: $currentUser"

# Transfer ownership to the current Windows user
icacls.exe $keyPath /setowner "$currentUser"
if ($LASTEXITCODE -ne 0) { throw "Failed to set owner." }

# Reset this file's ACL to inherited defaults
icacls.exe $keyPath /reset
if ($LASTEXITCODE -ne 0) { throw "Failed to reset ACL." }

# Remove inherited permissions from the private-key file
icacls.exe $keyPath /inheritance:r
if ($LASTEXITCODE -ne 0) { throw "Failed to disable inheritance." }

# Grant read access to the current Windows user
icacls.exe $keyPath /grant:r "$($currentUser):(R)"
if ($LASTEXITCODE -ne 0) { throw "Failed to grant read permission." }

Write-Host ""
Write-Host "========== FINAL OWNER =========="
(Get-Acl -LiteralPath $keyPath).Owner

Write-Host ""
Write-Host "========== FINAL PERMISSIONS =========="
icacls.exe $keyPath
~~~

### خروجی مورد انتظار

مالک باید حساب ویندوز فعلی باشد و ACL مؤثر فایل کلید باید فقط حساب فعلی را با مجوز خواندن نشان دهد. در نمونهٔ حل‌شده، ورودی‌های اضافی مانند Administrators، SYSTEM و SID باقی‌مانده از ویندوز قبلی پس از این روش دیگر در ACL فایل دیده نمی‌شدند.

اگر هر دستور خطا داد، ادامه نده؛ خروجی خطا و نتیجهٔ زیر را بررسی کن:

~~~powershell
icacls.exe $keyPath
(Get-Acl -LiteralPath $keyPath).Access |
    Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited -AutoSize
~~~

**هشدار:** این فرمان‌ها فقط روی فایل کلید خصوصی اجرا شوند، نه روی کل پوشهٔ .ssh و نه روی فایل عمومی به‌جای آن. محتوای کلید خصوصی را هیچ‌وقت در چت یا GitHub قرار نده.

## 3. اتصال SSH را آزمایش کن

به PowerShell همان حساب ویندوز برگرد و مقادیر کاربر و IP را با مشخصات سرور خودت جایگزین کن:

```powershell
$keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519_fragcity"
ssh -o IdentitiesOnly=yes -i $keyPath sv1@192.168.1.11
```

- اگر خطای `UNPROTECTED PRIVATE KEY FILE` دیگر دیده نشد، مشکل Permission فایل برطرف شده است.
- اگر اکنون فقط `Permission denied (publickey)` می‌بینی، کلید از سمت کلاینت دیگر به‌دلیل Permission رد نشده؛ باید بررسی شود کلید عمومی متناظر در `~/.ssh/authorized_keys` کاربر Linux نصب شده باشد و نام کاربر و آدرس سرور درست باشند.
- برای اطلاعات بیشتر از مذاکرهٔ SSH می‌توان از دستور زیر استفاده کرد:

```powershell
ssh -vvv -o IdentitiesOnly=yes -i "$env:USERPROFILE\.ssh\id_ed25519_fragcity" sv1@192.168.1.11
```

## 4. پیام host key با خطای Private Key فرق دارد

پیام `The authenticity of host ... can't be established` دربارهٔ **کلید میزبان سرور** است؛ با Permission فایل کلید خصوصی کاربر فرق دارد. تنها پس از اطمینان از هویت سرور، Fingerprint را تأیید کن. پس از نصب مجدد یا تغییر VM/IP، دربارهٔ تغییر Fingerprint از قبل فرض نساز.

## 5. چک‌لیست نهایی

- [ ] فایل Private Key در مسیر مورد انتظار وجود دارد.
- [ ] مالک فایل، حساب فعلی ویندوز است.
- [ ] ACL فایل، دسترسی اضافی حساب یا SID قدیمی ندارد.
- [ ] خطای `UNPROTECTED PRIVATE KEY FILE` رفع شده است.
- [ ] اگر `Permission denied (publickey)` باقی ماند، کلید عمومی مجاز، نام کاربر و IP بررسی شده‌اند.
- [ ] هیچ Private Key یا Webhook/Token محرمانه‌ای در مستندات یا GitHub قرار نگرفته است.

## 6. روش موقت بازیابی دسترسی: غیرفعال‌کردن SSH Key و ورود با رمز در Debian

این روش زمانی است که نمی‌توانی با کلید وارد شوی و موقتاً می‌خواهی با رمز عادی حساب Linux وصل شوی. منظور «غیرفعال‌کردن SSH Key authentication» است، نه خاموش‌کردن سرویس SSH. این تنظیم به‌صورت سراسری روی اتصال‌های SSH جدید اثر می‌گذارد.

**پیش از شروع**
- ترجیحاً از کنسول VMware وارد Debian شو؛ یا نشست SSH مدیریتی فعلی را باز نگه دار.
- مطمئن شو حساب عادی، در این مثال sv1، وجود دارد و دسترسی sudo دارد.
- رمز حساب را در چت یا فایل مستندات ننویس.
- پس از اتمام عیب‌یابی، ورود کلیدی را دوباره فعال کن؛ ورود با رمز را به‌عنوان حالت دائمی ترجیح نده.

### 6.1 تنظیم رمز حساب Linux

روی کنسول Debian یا نشست مدیریتی فعلی اجرا کن:

~~~bash
sudo passwd sv1
~~~

رمز جدید را دو بار وارد کن. هنگام تایپ رمز در ترمینال کاراکترها نمایش داده نمی‌شوند؛ این رفتار طبیعی است.

### 6.2 ساخت تنظیم موقت Password-only

در Debian فایل موقتی با نامی می‌سازیم که پیش از فایل سخت‌سازی معمول ما یعنی 00-fragcity-hardening.conf خوانده شود. در OpenSSH معمولاً اولین مقدار خوانده‌شده برای هر گزینه تعیین‌کننده است؛ بنابراین به نام فایل و بررسی خروجی مؤثر دقت کن.

~~~bash
sudo tee /etc/ssh/sshd_config.d/00-00-fragcity-password-only.conf >/dev/null <<'EOF'
PasswordAuthentication yes
KbdInteractiveAuthentication no
PubkeyAuthentication no
AuthenticationMethods password
EOF
~~~

پیش از Reload حتماً نحو و تنظیمات مؤثر را بررسی کن:

~~~bash
sudo sshd -t || exit 1

sudo sshd -T | grep -E '^(authenticationmethods|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin) '
~~~

برای این حالت، خروجی مربوط به گزینه‌های احراز هویت باید مشابه این باشد:

~~~text
authenticationmethods password
passwordauthentication yes
kbdinteractiveauthentication no
pubkeyauthentication no
~~~

اگر مقادیر بالا با خروجی واقعی فرق داشتند، **SSH را Reload نکن**. ممکن است فایل دیگری زودتر خوانده شود یا تنظیمات دیگری وجود داشته باشد؛ ابتدا فهرست و محتوای فایل‌های /etc/ssh/sshd_config.d/ را بررسی کن.

اگر خروجی صحیح بود، اعمال کن:

~~~bash
sudo systemctl reload ssh
sudo systemctl is-active ssh
~~~

سرویس باید active باشد. کنسول VMware یا نشست مدیریتی فعلی را نبند.

### 6.3 اتصال از Windows با رمز

در یک پنجرهٔ تازهٔ Windows PowerShell اجرا کن و نام کاربر و IP را با مقادیر Node خودت جایگزین کن:

~~~powershell
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password sv1@192.168.1.11
~~~

باید رمز Linux کاربر sv1 را بخواهد. اگر ورود رد شد، کنسول را باز نگه دار و لاگ را در Debian بررسی کن:

~~~bash
sudo journalctl -u ssh -n 60 --no-pager
~~~

این تنظیم احراز هویت با کلید عمومی را برای SSH غیرفعال می‌کند، اما خود SSH خاموش نمی‌شود. سیاستی مانند PermitRootLogin no از فایل سخت‌سازی قبلی همچنان باید مانع ورود مستقیم root شود.

## 7. بازگشت از Password-only به ورود امن با SSH Key

پس از آن‌که مشکل Permission فایل کلید ویندوز را با روش بخش 2 حل کردی، بهتر است ورود کلیدی را به حالت عادی برگردانی. تا زمانی که فایل موقت Password-only وجود دارد، آزمون ورود کلیدی از سمت سرور عمداً رد خواهد شد.

**از کنسول VMware یا نشست مدیریتی باز** این کار را انجام بده:

~~~bash
sudo rm /etc/ssh/sshd_config.d/00-00-fragcity-password-only.conf

sudo sshd -t || exit 1

sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication) '
~~~

پیش از Reload، بررسی کن مقادیر با سیاست سخت‌سازی معمول ما هم‌خوان باشند:

~~~text
permitrootlogin no
passwordauthentication no
kbdinteractiveauthentication no
pubkeyauthentication yes
~~~

اگر خروجی همین مقادیر را نشان نمی‌دهد، Reload نکن و فایل‌های تنظیمات SSH را بررسی کن. اگر درست بود:

~~~bash
sudo systemctl reload ssh
sudo systemctl is-active ssh
~~~

حالا از **یک پنجرهٔ تازهٔ Windows PowerShell** ورود فقط با کلید را دوباره تست کن:

~~~powershell
$keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519_fragcity"
ssh -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -i $keyPath sv1@192.168.1.11 "hostname; id"
~~~

اگر تست موفق شد، روش کلیدی برقرار است. نشست کنسول یا مدیریتی را تا زمان تأیید این اتصال جدید باز نگه دار. اگر ناموفق بود، قبل از بستن دسترسی مدیریتی، خطا و لاگ SSH را بررسی کن.


