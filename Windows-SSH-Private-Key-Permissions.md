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

## 2. اصلاح مالک و Permissionها

در ACL نمونه‌ای که عیب‌یابی شد، سه مجوز نامناسب باقی مانده بود: `BUILTIN\\Administrators:(F)`، `NT AUTHORITY\\SYSTEM:(F)` و SID حساب ویندوز قدیمی با دسترسی `(M)`. مالک فایل به حساب فعلی تغییر کرده بود، اما دستور حذف چند SID در یک فراخوانی اجرا نشد.

برای جلوگیری از این مشکل، Permissionها را **تک‌به‌تک** حذف کن:

1. PowerShell را با حساب ویندوزی که از آن SSH می‌زنی باز کن. اگر برای تغییر ACL نیاز به مجوز Administrator است، همان حساب را با **Run as administrator** اجرا کن.
2. مطمئن شو متغیر مسیر به همان private key اشاره می‌کند.
3. ابتدا این دستورات را اجرا کن. SID قدیمی در این نمونه مختص همان کامپیوتر است؛ آن را از خروجی `icacls` خودت بردار و کورکورانه SID نمونه را در سیستم دیگری استفاده نکن.

```powershell
$keyPath = Join-Path $env:USERPROFILE ".ssh\\id_ed25519_fragcity"

if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
    throw "SSH private key not found: $keyPath"
}

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Make the current account the owner
icacls.exe $keyPath /setowner "$currentUser"
if ($LASTEXITCODE -ne 0) { throw "Failed to set file owner." }

# Remove inherited permissions from the parent directory
icacls.exe $keyPath /inheritance:r
if ($LASTEXITCODE -ne 0) { throw "Failed to disable inheritance." }

# Remove each unwanted grant in a separate command.
# These three SIDs correspond to SYSTEM, local Administrators, and
# the stale SID seen on the original machine. Verify the actual ACL first.
icacls.exe $keyPath /remove:g "*S-1-5-32-544"
if ($LASTEXITCODE -ne 0) { throw "Failed to remove Administrators grant." }

icacls.exe $keyPath /remove:g "*S-1-5-18"
if ($LASTEXITCODE -ne 0) { throw "Failed to remove SYSTEM grant." }

# Replace this SID with the stale SID actually shown on your file,
# if one is present. Do not reuse this example on another computer.
icacls.exe $keyPath /remove:g "*S-1-5-21-3116789890-1268379209-2693843427-1001"
if ($LASTEXITCODE -ne 0) { throw "Failed to remove stale SID grant." }

# Ensure the current account retains read access
icacls.exe $keyPath /grant:r "$($currentUser):(R)"
if ($LASTEXITCODE -ne 0) { throw "Failed to grant read access." }

Write-Host "`n========== FINAL OWNER =========="
(Get-Acl -LiteralPath $keyPath).Owner

Write-Host "`n========== FINAL PERMISSIONS =========="
icacls.exe $keyPath
```

اگر SID قدیمی روی فایل تو با نمونهٔ بالا فرق دارد، ابتدا از روی `icacls.exe $keyPath` مشخصش کن؛ دستور حذف SID قدیمی فقط زمانی اجرا شود که مطمئن شده‌ای همان حساب قدیمی است. اجرای دستور حذف روی SID اشتباه می‌تواند مجوز حساب دیگری را تغییر دهد.

### خروجی مورد انتظار

ACL نهایی فایل کلید باید مالک فعلی را نشان دهد و تنها مجوز دسترسی فایل برای حساب فعلی ویندوز باشد؛ برای نمونه:

```text
C:\\Users\\<WindowsUser>\\.ssh\\id_ed25519_fragcity <ComputerName>\\<WindowsUser>:(R)
```

اگر هر فرمان `icacls` خطا داد، به فرمان بعدی نرو. خطا و خروجی فعلی `icacls.exe $keyPath` را بررسی کن.
 
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
