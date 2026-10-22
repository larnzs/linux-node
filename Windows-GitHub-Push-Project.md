# آموزش Push کردن پروژه از ویندوز به GitHub با Git

این راهنما روش ارسال سورس پروژه از Windows به یک Repository در GitHub را با **Git + GitHub CLI (gh)** و آدرس HTTPS توضیح می‌دهد. برای Push کردن، رمز معمولی حساب GitHub را در دستورهای Git وارد نکن.

مثال مسیر پروژه:

~~~powershell
D:\fragcity2\app\FragCity-OfflineLauncher
~~~

مسیر و نام Repository را متناسب با پروژهٔ خودت تغییر بده.

---

## 1. پیش‌نیازها

در PowerShell بررسی کن که Git نصب است:

~~~powershell
git --version
~~~

اگر دستور شناخته نشد، Git for Windows را از منبع رسمی نصب کن: https://git-scm.com/download/win

GitHub CLI را نصب کن:

~~~powershell
winget install --id GitHub.cli --source winget
~~~

پس از نصب، PowerShell را ببند و دوباره باز کن. سپس:

~~~powershell
git --version
gh --version
~~~

اگر GitHub CLI از قبل نصب است، نصب مجدد لازم نیست.

## 2. ورود امن به GitHub

در PowerShell اجرا کن:

~~~powershell
gh auth login
~~~

در پرسش‌های تعاملی این گزینه‌ها را انتخاب کن:

1. حساب میزبان: **GitHub.com**
2. روش انتقال Git: **HTTPS**
3. استفاده از GitHub credentials برای Git: **Yes**
4. روش ورود: **Login with a web browser** (اگر نمایش داده شد)

کد یک‌بارمصرفی را که CLI نمایش می‌دهد در صفحهٔ رسمی GitHub وارد کن و با همان حسابی وارد شو که اجازهٔ نوشتن در Repository مقصد را دارد. کد یا توکن را در چت، فایل یا اسکرین‌شات عمومی منتشر نکن.

بعد از ورود، اجرا کن:

~~~powershell
gh auth setup-git
gh auth status
~~~

در خروجی دستور دوم باید حساب موردنظر به‌عنوان حساب واردشده دیده شود.

## 3. رفتن به پوشهٔ پروژه

مسیر نمونهٔ FragCity:

~~~powershell
cd "D:\fragcity2\app\FragCity-OfflineLauncher"
~~~

مطمئن شو مسیر درست است:

~~~powershell
Get-Location
Get-ChildItem
~~~

## 4. بررسی وضعیت Git و Remote

قبل از تغییر چیزی، اجرا کن:

~~~powershell
git status
git remote -v
~~~

- اگر Git اطلاعات Branch و فایل‌ها را نشان می‌دهد، پوشه از قبل Git Repository است.
- اگر پیام شبیه **not a git repository** می‌بینی، Git هنوز در این پوشه راه‌اندازی نشده است.
- اگر دستور دوم آدرسی نشان می‌دهد، بررسی کن همان Repository مقصد موردنظرت باشد.

**کورکورانه Git را دوباره راه‌اندازی نکن، Remote را حذف نکن و پوشهٔ .git را پاک نکن.** برای Push عادی نیازی به این کارها نیست و حذف .git می‌تواند تاریخچهٔ محلی را از بین ببرد.

## 5. بررسی فایل‌های حساس و Build

پیش از اضافه کردن فایل‌ها، آن‌ها را بررسی کن. این موارد را در Repository ثبت نکن:

- رمز عبور، API key، Steam Web API key، GSLT، access token یا private key
- فایل‌های .env و تنظیمات حاوی Secret
- فایل‌های Log که ممکن است توکن یا دادهٔ خصوصی داشته باشند
- اطلاعات شخصی یا تنظیمات حساس مخصوص دستگاه خودت

در پروژه‌های .NET/C# معمولاً خروجی Build نباید ثبت شود. در صورت مناسب‌بودن برای پروژه، می‌توانی موارد زیر را در فایل .gitignore قرار بدهی:

~~~gitignore
**/bin/
**/obj/
.vs/
*.user
*.suo
.env
.env.*
!.env.example
secrets/
logs/
~~~

این نمونه را بدون بررسی به پروژهٔ موجود اضافه نکن: ممکن است بعضی پوشه‌ها یا فایل‌ها عمداً بخشی از سورس باشند. همچنین .gitignore فایل‌هایی را که قبلاً Track شده‌اند به‌طور خودکار از Git خارج نمی‌کند.

## 6. اگر پوشه هنوز Git Repository نیست

**فقط اگر** دستور git status گفته بود پوشه Git Repository نیست، اجرا کن:

~~~powershell
git init
git branch -M main
~~~

اگر Git از قبل در این پوشه تنظیم است، از این مرحله بگذر.

## 7. آماده‌کردن فایل‌ها برای Commit

~~~powershell
git add .
git status
git diff --cached --stat
~~~

برای مرور تغییرات آمادهٔ ثبت:

~~~powershell
git diff --cached
~~~

قبل از ادامه، مطمئن شو Secret، فایل Log حساس، خروجی حجیم و ناخواسته یا فایل خصوصی Stage نشده باشد. اگر فایل اشتباهی اضافه شده، فقط همان فایل را از Stage خارج کن:

~~~powershell
git restore --staged "path\to\file"
~~~

این دستور فایل محلی را حذف نمی‌کند؛ فقط آن را از فهرست آمادهٔ Commit خارج می‌کند.

## 8. ساخت Commit

اگر هویت Commit هنوز تنظیم نشده است، نام و ایمیل خودت را تنظیم کن. از ایمیلی استفاده کن که با تنظیمات GitHub تو سازگار باشد؛ می‌توانی در صورت نیاز ایمیل خصوصی noreply نمایش‌داده‌شده در تنظیمات GitHub را انتخاب کنی.

~~~powershell
git config --global user.name "Your Name"
git config --global user.email "YOUR_VERIFIED_EMAIL"
~~~

اکنون Commit بساز:

~~~powershell
git commit -m "Initial commit"
~~~

اگر پیام **nothing to commit** دیدی، ابتدا git status را بررسی کن؛ ممکن است تغییرات قبلاً Commit شده باشند.

## 9. ساخت Repository مقصد و تنظیم Remote

در GitHub یک Repository جدید بساز: https://github.com/new

اگر می‌خواهی Commitهای محلی را به‌عنوان اولین تاریخچه بفرستی، بهتر است Repository جدید را خالی بسازی؛ هنگام ساخت، README، .gitignore یا License ایجاد نکن. مثال نام Repository:

~~~text
larnzs/FragCity-OfflineLauncher
~~~

آدرس HTTPS مقصد را از صفحهٔ Repository بردار. شکل کلی:

~~~text
https://github.com/USERNAME/REPOSITORY.git
~~~

اگر هنوز Remote با نام origin وجود ندارد:

~~~powershell
git remote add origin https://github.com/USERNAME/REPOSITORY.git
~~~

اگر origin وجود دارد ولی آدرس آن اشتباه است، به‌جای افزودن Remote تکراری آدرسش را اصلاح کن:

~~~powershell
git remote set-url origin https://github.com/USERNAME/REPOSITORY.git
~~~

سپس مقصد و Branch را کنترل کن:

~~~powershell
git remote -v
git branch --show-current
~~~

اگر تصمیم داری Branch فعلی main باشد، می‌توانی نام آن را تنظیم کنی:

~~~powershell
git branch -M main
~~~

## 10. Push کردن

پس از تأیید حساب، Remote و Branch اجرا کن:

~~~powershell
git push -u origin main
~~~

گزینهٔ -u باعث می‌شود Branch محلی به Branch متناظر origin وصل شود؛ دفعات بعد معمولاً فقط git push کافی است.

برای ارسال تغییرات آینده:

~~~powershell
git status
git add .
git diff --cached --stat
git commit -m "Describe your changes"
git push
~~~

فهرست فایل‌های Stage‌شده را قبل از هر Commit بررسی کن.

---

## عیب‌یابی

### خطا: Invalid username or token. Password authentication is not supported

GitHub رمز معمولی حساب را برای Git over HTTPS نمی‌پذیرد. اول این دستورات را اجرا کن:

~~~powershell
gh auth login
gh auth setup-git
gh auth status
git push -u origin main
~~~

اگر خطا ادامه داشت، ممکن است ویندوز اعتبارنامهٔ قدیمی را ذخیره کرده باشد:

1. از Start برنامهٔ **Credential Manager** را باز کن.
2. وارد **Windows Credentials** شو.
3. فقط ورودی مربوط به **git:https://github.com** یا اعتبارنامهٔ GitHub قدیمی که متعلق به حساب اشتباه است را پیدا و حذف کن. ورودی‌های نامرتبط را حذف نکن.
4. دوباره اجرا کن:

~~~powershell
gh auth login
gh auth setup-git
gh auth status
git push -u origin main
~~~

اگر چند حساب GitHub داری، مطمئن شو حساب فعلی به Repository مقصد دسترسی Write دارد.

### خطا: Repository not found یا 403

- آدرس origin و نام کاربری/Repository را دوباره بررسی کن.
- خروجی gh auth status را بررسی کن تا حساب درست وارد شده باشد.
- مطمئن شو حساب واردشده اجازهٔ نوشتن در Repository را دارد.

### خطا: src refspec main does not match any

ممکن است هنوز Commit نساخته باشی یا Branch محلی نام دیگری داشته باشد:

~~~powershell
git status
git branch --show-current
git log -1 --oneline
~~~

اگر Commit وجود ندارد، فایل‌ها را بررسی و سپس Commit بساز. اگر Branch متفاوت است، نام آن را بررسی کن و بر اساس قصدت ادامه بده.

### خطا: remote origin already exists

origin از قبل ثبت شده است. ابتدا بررسی کن:

~~~powershell
git remote -v
~~~

اگر آدرس اشتباه است:

~~~powershell
git remote set-url origin https://github.com/USERNAME/REPOSITORY.git
~~~

### خطا: rejected یا non-fast-forward

ممکن است Repository مقصد خالی نباشد و Commitهایی در GitHub داشته باشد که در تاریخچهٔ محلی وجود ندارند. **فوراً git push --force اجرا نکن.** ابتدا تاریخچهٔ محلی و مقصد را بررسی کن؛ اگر روی GitHub یک README یا Commit اولیه ساخته‌ای، ادغام تاریخچه‌ها باید آگاهانه انجام شود.

---

## چک‌لیست نهایی

- [ ] Git و GitHub CLI نصب هستند.
- [ ] gh auth status حساب درست را نشان می‌دهد.
- [ ] فایل‌های حساس و خروجی‌های ناخواسته Stage نشده‌اند.
- [ ] git remote -v مقصد درست را نشان می‌دهد.
- [ ] Branch و Commit محلی بررسی شده‌اند.
- [ ] دستور git push -u origin main موفق شده است.
- [ ] فایل‌های موردنظر در Repository مقصد دیده می‌شوند.

## مراجع رسمی

- Git for Windows: https://git-scm.com/download/win
- GitHub CLI: https://cli.github.com/
- ورود GitHub CLI: https://cli.github.com/manual/gh_auth_login
- تنظیم Git برای استفاده از GitHub CLI: https://cli.github.com/manual/gh_auth_setup-git
- مستندات Push کردن Branch: https://docs.github.com/en/get-started/using-git/pushing-commits-to-a-remote-repository
