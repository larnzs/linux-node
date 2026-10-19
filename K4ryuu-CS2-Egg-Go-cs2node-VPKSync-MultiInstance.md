# FragCity — K4ryuu CS2 Egg-Go، cs2node، VPK Sync و Multi Instance

> **هدف این فصل:** روی Clone آزمایشگاهی FragCity، Egg رسمی **KitsuneLab CS2 Go** متعلق به K4ryuu را وارد Pterodactyl کنیم، یک سرور پایه بسازیم و پیش از فعال‌کردن Shared Base، خود Egg را به‌تنهایی آزمایش کنیم.
>
> **وضعیت مستندات (2026-10-19، به‌روزرسانی مرحله‌ای):** پنل و شبکه طبق تأیید کاربر عملیاتی‌اند؛ Clone با hostname برابر `fc-node-01` و IP برابر `192.168.1.9` فعال است؛ Queue Worker و Scheduler روی Clone تنظیم شده‌اند. اولین Instance به نام `fc-cs2-test-01` ساخته شده و کاربر گزارش کرده دانلود اولیهٔ بازی پایان یافته است. بررسی فقط‌خواندنی روی Clone کرنل `6.12.113+deb13-amd64` و حدود `182 GB` فضای آزاد در فایل‌سیستم ریشه نشان داده است. در خروجی `lsblk` فعلی VMDK ثانویه‌ای دیده نشده، اما این مانع تست نیست: فعلاً Shared Base روی فایل‌سیستم فعلی در مسیر پیش‌فرض `/srv/cs2-shared` قرار می‌گیرد؛ حدود `182 GB` فضای آزاد مشاهده شده است. VMDK دوم فقط گزینهٔ جداسازی Storage برای فاز بعد/Production است. `cs2node` نصب شده و Installer گزارش کرده سرویس فعال و اجرا شده است؛ تکمیل دانلود و آماده‌بودن Shared Base در `/srv/cs2-shared` هنوز تأیید نشده است. VM اصلی با IP `192.168.1.7` باید خاموش بماند.
>
> **منبع اصلی:** https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md  
> راهنمای Node daemon: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md

---

## 0. تصمیم‌های این تست

- ابتدا فقط **یک سرور آزمایشی** می‌سازیم و آن را بدون Node daemon اجرا می‌کنیم. این همان اولین گام پیشنهادی مستندات K4ryuu است؛ Egg بدون daemon هم با SteamCMD فایل‌های بازی را دریافت می‌کند.
- از Egg اصلیِ قابل‌استفاده با Node daemon استفاده می‌کنیم: **KitsuneLab CS2 Go @ K4ryuu**. فعلاً Image نسخهٔ `stable` را انتخاب می‌کنیم، نه `beta`.
- نخستین دانلود CS2 حدود 35 GB است؛ طبق راهنمای K4ryuu برای تست بدون VPK sync، سقف دیسک سرور را **40 GB** در نظر می‌گیریم. این فایل‌ها داخل Volume معمول سرور Pterodactyl قرار می‌گیرند. قبل از ساخت سرور، فضای آزاد میزبان Volume را دوباره بررسی کن.
- VMDK دادهٔ دوم برای اجرای آزمایشی `cs2node`/`vpksync` الزامی نیست. با حدود `182 GB` فضای آزاد گزارش‌شده، فعلاً از فایل‌سیستم فعلی و مسیر پیش‌فرض `/srv/cs2-shared` استفاده می‌کنیم. قبل از Production می‌توان Storage جداگانه انتخاب کرد؛ این تصمیم نباید تست فعلی را مسدود کند.
- فقط روی Clone کار کن؛ VM اصلی باید خاموش بماند. این راهنما ریپوی `cs2-kus-addons` را تغییر نمی‌دهد و قانون UFW مربوط به `29001/udp` را دست‌نخورده نگه می‌دارد.
- GSLT، رمزها و tokenها را داخل GitHub، README، اسکرین‌شات عمومی یا چت ثبت نکن؛ در صورت نیاز فقط در فیلد امن پنل وارد کن.

## 1. تأیید Clone و فضای دیسک

از Windows با SSH به Clone وصل شو و این بررسی فقط‌خواندنی را اجرا کن:

~~~bash
echo "=== Hostname ==="
hostnamectl --static

echo
echo "=== IPv4 addresses ==="
ip -o -4 address show

echo
echo "=== Root filesystem ==="
df -hT /

echo
echo "=== Pterodactyl volumes filesystem ==="
df -hT /var/lib/pterodactyl/volumes

echo
echo "=== Block devices ==="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
~~~

شرایط ادامه:

- hostname باید `fc-node-01` و IP مربوط به Clone باید `192.168.1.9` باشد.
- مطمئن شو VM اصلی خاموش است؛ Clone یک جایگزین آزمایشی موقت است، نه Node دومی برای اجرای هم‌زمان.
- روی filesystem میزبان Volume سرور حداقل 40 GB فضای آزاد داشته باش. اگر خروجی مسیر Volume واضح نیست یا فضای کافی نداری، سرور را Create/Start نکن و خروجی را برای بررسی بفرست.
- اگر VMDK دادهٔ دوم را همین تازگی اضافه کرده‌ای، نام دستگاه را از روی خروجی‌های `lsblk` و `blkid` شناسایی کن؛ نامی مثل `/dev/sdb` را حدس نزن و قبل از تأیید، دیسک را فرمت نکن.

## 2. واردکردن Egg رسمی K4ryuu

این مرحله فقط Egg را به Panel اضافه می‌کند؛ بازی دانلود نمی‌شود و هیچ Instanceای ساخته نمی‌شود.

1. وارد https://panel.fragcity.ir شو.
2. مسیر **Admin → Nests → Import Egg** را باز کن.
3. URL زیر را در فیلد Import قرار بده:

   ~~~text
   https://raw.githubusercontent.com/K4ryuu/CS2-Egg-Go/main/pterodactyl/kitsunelab-cs2-go-egg.json
   ~~~

4. اگر پنل Nest مقصد می‌خواهد، از Nest موجود و مناسب Source/CS2 استفاده کن تا Nest تکراری بی‌دلیل ساخته نشود.
5. عملیات Import را کامل کن.

Egg واردشده باید این مشخصات را داشته باشد:

| گزینه | مقدار |
|---|---|
| Name | `KitsuneLab CS2 Go @ K4ryuu` |
| Stable image | `ghcr.io/k4ryuu/cs2-egg-go:stable` |
| Beta image | `ghcr.io/k4ryuu/cs2-egg-go:beta` |

**Egg اصلی را Import کن، نه فایل standalone.** نسخهٔ اصلی برای استفادهٔ آتی از Node daemon هم متغیرهای لازم را دارد. وجود daemon فعلاً اجباری نیست؛ Egg بدون آن هم باید بتواند سرور را با SteamCMD اجرا کند.

برای این تست فایل JSON را دستی تغییر نده و فایل خام Egg را به ریپوی FragCity کپی نکن. پس از Import، وجود نام بالا را در لیست Eggها تأیید کن.

## 3. بررسی Allocation قبل از ساخت Server

پورت برنامه‌ریزی‌شدهٔ CS2 برای این تست برابر `29001/udp` است.

1. به **Admin → Nodes → fc-node-01 → Allocations** برو.
2. بررسی کن Allocation مربوط به IP/Bind مورد استفادهٔ Node و پورت `29001` وجود داشته باشد و به سرور دیگری اختصاص نیافته باشد.
3. هنگام ساخت سرور، همان Allocation آزاد را انتخاب کن.

اگر `29001` در Allocationهای آزاد دیده نمی‌شود، **سرور را با پورت حدسی نساز**. ابتدا وضعیت Allocationهای Node را بررسی کن. بازبودن قانون UFW برای UDP 29001 به‌تنهایی ثابت نمی‌کند که پورت در Panel به‌عنوان Allocation تعریف شده یا از اینترنت به Clone فوروارد می‌شود. برای این تست Additional Allocation یا SourceTV لازم نیست.

## 4. ساخت سرور در پنل

به مسیر **Admin → Servers → Create Server** برو.

### 4.1 Core Details

| فیلد | مقدار پیشنهادی |
|---|---|
| Server Name | `fc-cs2-test-01` |
| Server Owner | حساب مدیریتی/آزمایشی موجود در پنل |
| Server Description | `FragCity CS2 Egg-Go baseline test on Clone` |
| Start Server when Installed | **خاموش / تیک‌نخورده** |

Start خودکار را خاموش می‌گذاریم تا پیش از دانلود بازی، Allocation، Resource limits و متغیرها را بررسی کنیم. اسکریپت Installation موجود در Egg یک placeholder است؛ دانلود واقعی CS2 در نخستین **Start** انجام می‌شود.

### 4.2 Allocation Management

| فیلد | مقدار |
|---|---|
| Node | `fc-node-01`؛ در این تست همان Clone فعال |
| Default Allocation | Allocation آزاد و تأییدشدهٔ UDP `29001` |
| Additional Allocation(s) | خالی |

اگر Node دیگری یا IP مقصد غیرمنتظره دیدی، ادامه نده؛ این تست باید روی Clone باشد.

### 4.3 Application Feature Limits

برای Instance آزمایشی:

| فیلد | مقدار |
|---|---:|
| Database Limit | `0` |
| Allocation Limit | `0` |
| Backup Limit | `0` |

این مقادیر قابلیت ساخت Database/Allocation اضافی و Backup از طرف این سرور را محدود می‌کنند؛ اجرای خود CS2 به Database پنل نیاز ندارد. پیش از ارائهٔ محصول به مشتری، Limitها و سیاست Backup را جداگانه طراحی می‌کنیم.

### 4.4 Resource Management

راهنمای K4ryuu حدود 2 GB RAM را برای Casual بدون افزونه و حدود 4 GB را برای افزونه‌ها و Workshop سنگین پیشنهاد می‌کند. برای یک تست پایه، از این مقادیر شروع کن:

| فیلد | مقدار شروع | توضیح |
|---|---:|---|
| CPU Limit | `200` % | سقف معادل دو Thread |
| CPU Pinning | خالی | فعلاً CPU خاصی را Pin نمی‌کنیم |
| Memory | `3072` MiB | 3 GiB؛ تست پایه بدون افزونهٔ سنگین |
| Swap | `0` MiB | Swap داخل Container غیرفعال |
| Disk Space | `40960` MiB | 40 GiB برای دانلود مستقل بازی بدون VPK sync |
| Block IO Weight | `500` | مقدار میانی در محدودهٔ 10 تا 1000 |
| Enable OOM Killer | فعال | از کل Node در برابر مصرف بیش از سقف حافظه محافظت می‌کند؛ RAM را پایش کن |

این اعداد برای **یک سرور آزمایشی** هستند، نه ظرفیت تضمین‌شدهٔ Production. پیش از Start، فضای آزاد واقعی را از مرحلهٔ 1 بررسی کن؛ پس از بوت، مصرف CPU/RAM را در Statistics پنل پایش کن.

> بعد از نصب و تأیید VPK sync روی Node، راهنمای K4ryuu سقف دیسک حدود 5 GB برای هر سرور را پیشنهاد می‌کند. تا وقتی daemon و Shared Base آماده نشده‌اند، عدد 5 GB را انتخاب نکن.

### 4.5 Nest Configuration

| فیلد | انتخاب |
|---|---|
| Nest | همان Nest انتخاب‌شده هنگام Import |
| Egg | `KitsuneLab CS2 Go @ K4ryuu` |
| Skip Egg Install Script | تیک نزن |

اسکریپت Installation داخل Egg placeholder است؛ دریافت واقعی فایل‌های بازی در شروع اولیه انجام می‌شود.

### 4.6 Docker Configuration

در فیلد **Docker Image** این Image را انتخاب یا دقیقاً وارد کن:

~~~text
ghcr.io/k4ryuu/cs2-egg-go:stable
~~~

برای این تست از `stable` استفاده کن. Imageهای Java 8/11/17/21/25 که در فرم عمومی ممکن است ببینی متعلق به Eggهای دیگری مثل Minecraft هستند؛ برای CS2 از آن‌ها استفاده نکن.

### 4.7 Startup Configuration

**Startup Command** را همان مقدار پیش‌فرض Egg نگه دار؛ با فرمان Egg دیگری جایگزینش نکن. مقدار پیش‌فرض شامل اجرای `./game/cs2.sh` و متغیرهای Map، Port، Game Type و Max Players است.

سرور را Create کن، ولی هنوز Start نزن.

## 5. مرور Variables قبل از اولین Start

پس از ساخت سرور، به تب **Startup** برو و این مقادیر را مرور کن:

| Variable | مقدار شروع | نکته |
|---|---|---|
| `STEAM_ACC` (GSLT) | برای تست LAN می‌تواند خالی بماند | برای دسترسی عمومی و Listing سرور، GSLT معتبر توصیه می‌شود. بدون Token، مستندات Egg حالت LAN-only را ذکر می‌کنند مگر `ALLOW_TOKENLESS` فعال شده باشد. Token را در README ثبت نکن. |
| `SRCDS_MAP` | `de_dust2` | مقدار پیش‌فرض |
| `GAME_TYPE` | `0` | Casual |
| `GAME_MODE` | `0` | Casual |
| `INSTALL_METAMOD` | `0` | در تست اول خاموش |
| `INSTALL_CSS` | `0` | ابتدا بازی پایه بدون افزونه |
| `INSTALL_SWIFTLY` | `0` | فعلاً لازم نیست |
| `INSTALL_MODSHARP` | `0` | فعلاً لازم نیست |
| `PRERELEASE` | `0` | نسخه‌های پیش‌انتشار افزونه‌ها را نمی‌گیریم |
| `ENABLE_FILTER` | `0` | فعلاً خاموش |
| `ENABLE_GUARD` | `0` | بعداً جداگانه تست می‌شود |
| `CLEANUP_ENABLED` | `0` | فعلاً خاموش |
| `ENABLE_LOG_FILES` | `0` | به ماژول `consolelog` در Node daemon نیاز دارد؛ فعلاً چیزی به ما اضافه نمی‌کند |

متغیرهای داخلی `SRCDS_APPID` و `ALLOW_TOKENLESS` را دست‌کاری نکن. در JSON رسمی فعلی، `SRCDS_MAXPLAYERS` نیز مقدار پیش‌فرض `32` دارد و از دید مشتری مخفی/قفل شده است؛ در اولین تست همین رفتار Egg upstream را حفظ می‌کنیم. اگر برای محصول FragCity می‌خواهیم مشتری تعداد Slot را انتخاب کند یا سقف تست را به 16 تغییر دهیم، بعد از قبولی Baseline یک نسخهٔ سفارشی و تحت مالکیت FragCity از Egg می‌سازیم و متغیر را به‌شکل کنترل‌شده قابل‌ویرایش می‌کنیم؛ فایل/UUID رسمی K4ryuu را مستقیم دست‌کاری نکن.

اگر بعداً CounterStrikeSharp لازم شد، طبق مستند K4ryuu متغیر `INSTALL_CSS=1` را انتخاب کن؛ MetaMod نیز به‌صورت خودکار فعال می‌شود. ابتدا بازی پایه را سالم بالا بیاور و افزونه‌ها را در مرحلهٔ جداگانه اضافه کن.

## 6. اولین Start و دانلود بازی

پس از بررسی موارد بالا، از صفحهٔ سرور روی **Start** بزن و تب Console را باز نگه دار.

در اولین بوت Egg فایل‌های CS2 را با SteamCMD دانلود/آماده می‌کند؛ این کار ممکن است طول بکشد. خروجی باید مراحلی مشابه این‌ها داشته باشد:

~~~text
KitsuneLab | INFO  | Starting KitsuneLab CS2 Egg
KitsuneLab | RUN   | Checking for daemon-managed game files...
KitsuneLab | RUN   | Updating server files via SteamCMD...
~~~

چون فعلاً Node daemon نصب نشده، انتظار داریم Egg از مسیر عادی SteamCMD استفاده کند؛ پیام بررسی daemon در هر بوت طبیعی است. اگر Console خطای `ERROR` داد، Egg را دوباره Import نکن و سرور را حذف نکن؛ بخش مربوط از Console و چند خط قبل/بعدش را برای عیب‌یابی بفرست و Token/اطلاعات حساس را حذف کن.

**هنگام دانلود اولیه Start/Stop را پشت‌سرهم نزن.** پس از تکمیل دانلود، Console باید پیام راه‌اندازی Source 2 را نشان دهد و سرور در پنل Running شود.

## 7. معیارهای قبولی سرور پایه

این موارد را یکی‌یکی بررسی کن:

- [ ] سرور بعد از دانلود به وضعیت Running می‌رسد و Console وارد چرخهٔ خطا/Restart تکراری نمی‌شود.
- [ ] Map پیش‌فرض `de_dust2` بارگذاری می‌شود.
- [ ] در Console پنل می‌توان یک فرمان معمول CS2 را ارسال کرد و پاسخ آن را دید.
- [ ] اگر GSLT خالی است، تست اتصال را از LAN انجام بده. برای Listing/اتصال اینترنتی، GSLT و مسیر UDP را جداگانه تأیید کن.
- [ ] از Client مجاز به IP و Allocation تخصیص‌یافته متصل شو؛ پورت برنامه‌ریزی‌شده `29001/udp` است، به شرط آنکه همان Allocation واقعاً به این سرور اختصاص یافته باشد.
- [ ] از دکمهٔ **Stop** پنل استفاده کن؛ بعد از توقف کامل دوباره Start کن و ماندگاری فایل‌ها را بررسی کن.
- [ ] مصرف CPU/RAM و فضای Volume پس از دانلود بررسی شود؛ خروجی خام یا Token را در GitHub ننویس.

پس از دانلود، روی Clone این دستورات فقط‌خواندنی را اجرا کن:

~~~bash
echo "=== Root filesystem ==="
df -hT /

echo
echo "=== Pterodactyl volumes filesystem ==="
df -hT /var/lib/pterodactyl/volumes

echo
echo "=== Docker disk usage ==="
sudo docker system df

echo
echo "=== Running containers ==="
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
~~~

اگر Start شکست خورد، اول Console/Activity و وضعیت سرویس را بررسی کن؛ Panel را reinstall نکن و سرور را عجولانه حذف نکن.

## 8. نصب cs2node، راه‌اندازی Shared Base و فعال‌کردن VPK Sync

این فصل با مستندات رسمی K4ryuu تطبیق داده شده است: [Install](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md)، [Node daemon](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md)، [VPK Sync](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md)، [Node config](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/node-config.md)، [Protocol](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/protocol.md)، [Security](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/security.md) و [Troubleshooting](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/troubleshooting.md).

### تصمیم معماری — تعمیر SteamCMD و سپس انتقال کنترل‌شدهٔ VPKها

- طبق آخرین تصمیم کاربر، ابتدا باید SteamCMD روی Debian درست اجرا شود. پس از شروع موفق دانلود، کاربر می‌خواهد بازی را موقتاً متوقف کند و از طریق WinSCP فایل‌های بازی/Workshop موجود روی Windows را منتقل کند.
- **هیچ‌وقت فایل‌های Windows را کورکورانه روی کل Shared Base کپی نکن.** manifest لینوکسی، پوشه‌های `.steam`، `Steam`، `steamapps`، خود SteamCMD و فایل‌های اجرایی/کتابخانه‌های ویندوز نباید جایگزین ساختار Linux شوند. برای Seed احتمالی، فقط VPKهای asset با مسیر نسبی درست منتقل می‌شوند؛ سپس SteamCMD باید دوباره اجرا شود تا depots لینوکسی را بررسی و فایل‌های لازم را اصلاح/دانلود کند. صرف کپی فایل تضمین نمی‌کند SteamCMD همهٔ دانلود را حذف کند.
- Instance فعلی `fc-cs2-test-01` را حذف نکن؛ در پنل Offline نگهش دار. Volume آن منبع Shared Base نخواهد بود.
- از Egg کامل **KitsuneLab CS2 Go @ K4ryuu** استفاده می‌کنیم؛ این Egg با پروتکل cs2node سازگار است.
- `cs2node` روی Debian به‌عنوان سرویس host اجرا می‌شود؛ `vpksync` یک نصب مرکزی تولید می‌کند و VPKها را به‌شکل read-only به Instanceها می‌دهد. configs و فایل‌های نوشتنی هر Instance خصوصی می‌مانند.
- Workshop ساختار جداگانه‌ای دارد: Cache ماژول در `/srv/cs2-workshop/730/<item-id>/<manifest>/` قرار می‌گیرد و به `meta.json` نیاز دارد. فایل‌های Workshop ویندوز را مستقیم و خام داخل `/srv/cs2-workshop` نریز. اول SteamCMD/Base را سالم می‌کنیم، بعد مسیر منبع Workshop و metadata را مشخص و Seed آن را جداگانه انجام می‌دهیم.
- PoC فعلاً روی فایل‌سیستم فعلی با حدود 182 GiB فضای آزاد انجام می‌شود؛ VMDK دوم لازم نیست.
- CounterStrikeSharp و پلاگین‌های FragCity را قبل از قبولی VPK Sync و Multi Instance نصب نکن.

### 8.0 — پیش‌نیاز اجباری Debian amd64: فعال‌سازی i386 (قبل از نصب cs2node)

**این مرحله را قبل از دریافت/اجرای Installer و قبل از `sudo /tmp/cs2node install` انجام بده.** میزبان amd64 است، اما SteamCMD از یک باینری 32-bit در مسیر `linux32/steamcmd` هم استفاده می‌کند. در نصب آزمایشگاهی FragCity، نبود Runtime سازگار باعث خطای `cannot execute: required file not found` و exit 127 شد؛ بعد از نصب بسته‌های i386، آزمون `steamcmd.sh +quit` موفق شد.

~~~bash
set -eu

ARCH="$(dpkg --print-architecture)"
echo "Host architecture: $ARCH"
if [ "$ARCH" != "amd64" ]; then
  echo "STOP: this block is written for Debian amd64; review before proceeding."
  exit 1
fi

echo
echo "=== Enable i386 multiarch ==="
sudo dpkg --add-architecture i386
sudo apt-get update

echo
echo "=== Install SteamCMD 32-bit runtime libraries ==="
sudo apt-get install -y libc6:i386 libstdc++6:i386 libgcc-s1:i386

echo
echo "=== Confirm foreign architecture ==="
dpkg --print-foreign-architectures
~~~

این پیش‌نیاز فقط معماری و کتابخانه‌های سازگار را آماده می‌کند؛ CS2 را دانلود نمی‌کند و هیچ فایل بازی را تغییر نمی‌دهد.

در نصب تازه ممکن است `/root/steamcmd/steamcmd.sh` تا اولین تلاش daemon ساخته نشده باشد؛ پس `+quit` را در همین نقطه اجباری اجرا نکن. Installer را پس از آماده‌سازی i386 ادامه بده. اگر SteamCMD قبلاً نصب شده یا اولین تلاش daemon خطا داد، از آزمون بازیابی بخش 8.2.1 استفاده کن.

### 8.0.1 — نصب cs2node (پس از تکمیل پیش‌نیاز i386)

فقط بعد از اجرای موفق مرحلهٔ 8.0، باینری رسمی را دریافت کن و Wizard را اجرا کن:

~~~bash
curl -fsSL \
  https://github.com/K4ryuu/CS2-Egg-Go/releases/latest/download/cs2node_linux_amd64 \
  -o /tmp/cs2node
chmod +x /tmp/cs2node
file /tmp/cs2node
sudo /tmp/cs2node install
~~~

از `--yes` استفاده نکن؛ Wizard تعاملی را با دقت کامل کن. مسیر مرکزی `cs2_dir` در PoC برابر `/srv/cs2-shared` و روش `push_method` برابر `symlink` است. گزینه‌های واقعاً انتخاب‌شده در نصب فعلی، بعد از اجرای Wizard، در بخش 8.1 ثبت شده‌اند. در نصب تازه، بخش i386 باید قبل از این فرمان‌ها اجرا شود تا نخستین Update مرکزی با Runtime ناقص 32-bit شکست نخورد.

### 8.1 — وضعیت نصب واقعی cs2node

طبق لاگ ارسالی در 2026-10-19، Installer اجرای موفق را گزارش کرده است:
- باینری در `/usr/local/bin/cs2node` قرار گرفته است.
- پیکربندی در `/etc/cs2node/config.json` نوشته شده است.
- واحد `/etc/systemd/system/cs2node.service` ساخته شده و نصب‌کننده گزارش کرده سرویس enable و start شده است.
- کانال `stable` و self-update روشن است.
- این خروجی به‌تنهایی ثابت نمی‌کند که Shared Base دانلود شده یا فایل‌های بازی در مسیر مرکزی قرار گرفته‌اند؛ برای آن بررسی بخش 8.2 لازم است.

**ماژول‌هایی که در Wizard واقعاً روشن انتخاب شدند:**

| Module | وضعیت |
|---|---|
| `vpksync` | روشن |
| `guard` | خاموش |
| `alerts` | روشن |
| `addoncache` | روشن |
| `workshop` | روشن |
| `backup` | روشن |
| `cleanup` | روشن |
| `crashes` | روشن |
| `consolelog` | روشن |
| `metrics` | روشن |

**تنظیمات ثبت‌شدهٔ vpksync:**

| گزینه | مقدار ثبت‌شده |
|---|---|
| `steamcmd_dir` | `/root/steamcmd` |
| `cs2_dir` | `/srv/cs2-shared` |
| `push_method` | `symlink` |
| `max_workers` | `8` |
| `auto_restart` | `true` |
| `restart_policy` | `empty` |
| `max_delay_hours` | `2` |
| `warn_minutes` | `10` |
| `validate` | `false` |
| `check_minutes` | `30` |

`restart_policy=empty` یعنی پس از Update تا خالی‌شدن سرور یا رسیدن مهلت اجباری صبر شود. بررسی Update مرکزی هر 30 دقیقه تنظیم شده است؛ این مقدار با برنامهٔ اولیهٔ یک‌ساعته متفاوت است و همین مقدار واقعی را فعلاً ثبت می‌کنیم.

**تنظیمات ماژول‌های دیگر:**

- `addoncache`: مسیر `/var/lib/cs2node/addoncache`، تازه‌سازی هر 30 دقیقه، نگهداری 30 روز، قفل نسخه‌ها خاموش.
- `workshop`: مسیر `/srv/cs2-workshop`، `seed=true`، نگهداری نسخهٔ بلااستفاده نامحدود (`keep_days=0`)، بررسی هر 360 دقیقه.
- `backup`: مسیر `/srv/cs2-backups`، اجرای روزانه ساعت 05:00، 14 روز نگهداری و حداکثر 7 نسخه برای هر سرور.
- `cleanup`: هر 6 ساعت و هنگام Start اجرا می‌شود؛ فایل‌های باز نگه داشته می‌شوند.
- `crashes`: مسیر `/var/lib/cs2node/crashes`، حداکثر 20 بسته برای هر سرور و 30 روز نگهداری.
- `consolelog`: مسیر `/var/lib/cs2node/logs`، نگهداری 30 روز.
- `metrics`: فقط روی `127.0.0.1:9151` گوش می‌دهد؛ نمونه‌برداری هر 10 ثانیه.
- `alerts`: فعال است. URL وب‌هوک در مستندات و ریپو ثبت نمی‌شود؛ چون URL واقعی در لاگ چت افشا شده، آن را در Discord باطل و یک Webhook تازه بساز. قبل از اتکا به Alerts، وب‌هوک جدید را در پیکربندی جایگزین کن.

### 8.2 — بررسی read-only سرویس و مسیر واقعی Shared Base

این دستورها چیزی را حذف، کپی یا تغییر نمی‌دهند. آن‌ها را اجرا کن تا تشخیص دهیم سرویس بالا است و آیا SteamCMD واقعاً فایل‌های مرکزی را در مسیر درست نوشته است یا نه:

~~~bash
echo "=== cs2node service enabled/active ==="
sudo systemctl is-enabled cs2node || true
sudo systemctl is-active cs2node || true
sudo systemctl status cs2node --no-pager

echo
echo "=== cs2node version ==="
sudo cs2node version

echo
echo "=== cs2node status ==="
sudo cs2node status

echo
echo "=== cs2node doctor ==="
sudo cs2node doctor

echo
echo "=== Central directory ==="
if sudo test -d /srv/cs2-shared; then
  sudo ls -lah /srv/cs2-shared
  sudo du -sh /srv/cs2-shared
  echo
  echo "=== Root-level entries ==="
  sudo find /srv/cs2-shared -mindepth 1 -maxdepth 2 -printf '%y %p\n' | head -n 80
  echo
  echo "=== Manifest ==="
  if sudo test -f /srv/cs2-shared/steamapps/appmanifest_730.acf; then
    sudo grep -E '"(appid|buildid|StateFlags)"' /srv/cs2-shared/steamapps/appmanifest_730.acf
  else
    echo "Manifest not present yet"
  fi
  echo
  echo "=== VPK count ==="
  sudo find /srv/cs2-shared/game -type f -name '*.vpk' 2>/dev/null | wc -l
else
  echo "/srv/cs2-shared does not exist"
fi

echo
echo "=== Recent node logs ==="
sudo journalctl -u cs2node -n 120 --no-pager

echo
echo "=== Disk space ==="
df -hT / /srv /var/lib/pterodactyl/volumes 2>/dev/null
~~~

لاگ ممکن است نشان بدهد SteamCMD هنوز در حال دانلود یا Update است؛ اگر بله، به آن فرصت بده و فعلاً از Restart کردن سرویس یا Start کردن Instance خودداری کن. خروجی کامل را بفرست، اما اگر در هر مرحله URL محرمانه‌ای دیدی آن را قبل از ارسال حذف کن.

### 8.2.1 — بازیابی خطای SteamCMD و وضعیت اجرای فعلی

اولین تلاش روی Debian amd64 با این خطا مواجه شد:

```text
/root/steamcmd/steamcmd.sh: line 37: /root/steamcmd/linux32/steamcmd: cannot execute: required file not found
central update failed err=steamcmd: exit status 127
```

سپس بسته‌های `libc6:i386`، `libstdc++6:i386` و `libgcc-s1:i386` نصب شدند. آزمون واقعی `sudo /root/steamcmd/steamcmd.sh +quit` اکنون با پیام‌های `Loading Steam API...OK` و `Unloading Steam API...OK` موفق شده است. این فقط ثابت می‌کند SteamCMD قابل اجراست؛ هنوز کامل‌شدن دانلود CS2 را ثابت نمی‌کند.

کد نسخهٔ فعلی K4ryuu اولین تلاش مرکزی را حدود **10 ثانیه بعد از شروع سرویس** اجرا می‌کند و سپس طبق `check_minutes` تکرار می‌کند. خروجی اصلی SteamCMD برای `app_update` به Journal فرستاده نمی‌شود؛ بنابراین درصد دانلود ممکن است تا پایان کار در لاگ دیده نشود. نتیجه را با پردازش زنده، رشد فایل‌ها و سپس Build ID/VPK count بررسی کن.

برای بررسی فقط‌خواندنی:

~~~bash
echo "=== Latest cs2node logs ==="
sudo journalctl -u cs2node -n 80 --no-pager -o short-iso

echo
echo "=== SteamCMD processes ==="
ps -eo pid,etime,stat,args |
  grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true

echo
echo "=== Current disk usage ==="
sudo du -sh /root/steamcmd /srv/cs2-shared 2>/dev/null || true

echo
echo "=== Files in central directory ==="
sudo find /srv/cs2-shared -maxdepth 3 -type f -printf '%s\t%p\n' 2>/dev/null | head -n 40

echo
echo "=== Current VPK count ==="
sudo find /srv/cs2-shared/game -type f -name '*.vpk' 2>/dev/null | wc -l
~~~

**وضعیت ثبت‌شده در اجرای 2026-10-19:** بعد از Restart در `09:03:51 UTC`، `vpksync up ... build=0` گزارش شد؛ بررسی بعدی Manifest مرکزی پیدا نکرد و VPK count برابر صفر بود. در خروجی فرستاده‌شده، نتیجهٔ نهایی تلاش جدید `app_update` دیده نشده؛ بنابراین نه دانلود کامل تأیید شده و نه شکست قطعی تلاش پس از نصب Runtime.

اگر پردازش SteamCMD هنوز زنده است و برای WinSCP می‌خواهی آن را متوقف کنی، ابتدا وضعیت را از بلوک بالا ثبت کن، سپس:

~~~bash
sudo systemctl stop cs2node
sleep 2
echo "=== Service ==="
sudo systemctl is-active cs2node || true
echo
echo "=== Any remaining SteamCMD ==="
ps -eo pid,etime,stat,args |
  grep -E '[s]teamcmd\.sh|[l]inux32/steamcmd|[l]inux64/steamcmd' || true
~~~

فقط وقتی فایل منتقل کن که دیگر پردازش SteamCMD وجود نداشته باشد. اگر اصلاً پردازشی پیدا نشد، لاگ جدید را بررسی کن تا معلوم شود Update شکست خورده یا موعد تلاش بعدی نرسیده است.

### 8.2.2 — طرح انتقال فایل‌های بازی با WinSCP

این کار را فقط پس از رفع خطای SteamCMD و تأیید شروع دانلود انجام بده. مقصد اصلی بازی `/srv/cs2-shared` است و محتوای بازی باید در زیرپوشهٔ `game/` آن قرار بگیرد. برای اینکه باینری‌های Linux خراب یا با فایل‌های Windows جایگزین نشوند، فایل‌ها را ابتدا به یک پوشهٔ staging زیر Home کاربر منتقل می‌کنیم؛ سپس با `rsync` کنترل‌شده فقط VPKها را در مسیر نسبی درست ادغام می‌کنیم و SteamCMD را دوباره اجرا می‌کنیم تا depots را reconcile کند. برای این مرحله، فایل‌های `steamapps/appmanifest_730.acf`، `.steam`، `Steam`، `steamcmd` و executable/libraryهای Windows را از منبع Windows جایگزین نکن.

Workshop جداست: مسیر ورودی‌ای که ماژول از داخل Volume هر سرور می‌خواند `game/bin/linuxsteamrt64/steamapps/workshop/content/730/<item-id>/` به‌همراه `appworkshop_730.acf` است. Node cache خودش را با ساختار `/srv/cs2-workshop/730/<item-id>/<manifest>/meta.json` می‌سازد. **فایل‌های Workshop را مستقیماً در `/srv/cs2-workshop` قرار نده**؛ در قدم Workshop، ابتدا مسیر واقعی فایل‌های Windows و ACF موجود را فقط بررسی می‌کنیم، سپس آن‌ها را به Volume سرور آزمایشی وارد و از مسیر sync رسمی ماژول عبور می‌دهیم.

### 8.3 — معیار قبولی Shared Base

قبل از Start کردن `fc-cs2-test-01` این شروط باید تأیید شوند:
1. `cs2node status` و `cs2node doctor` خطای بحرانیِ حل‌نشده نداشته باشند.
2. `/srv/cs2-shared/steamapps/appmanifest_730.acf` وجود داشته باشد و Build ID آن قابل مشاهده باشد.
3. `/srv/cs2-shared/game` وجود داشته باشد و VPK count صفر نباشد.
4. لاگ نشان دهد عملیات SteamCMD/Shared Base با خطای حل‌نشده متوقف نشده است.

تنها وجود دایرکتوری یا ثبت `cs2_dir` در config برای اعلام موفقیت کافی نیست.

### 8.4 — اتصال سرور اول به Base

فقط وقتی Base مرکزی تأیید شد:
1. از پنل fc-cs2-test-01 را Start کن.
2. در Console انتظار این پیام موفق را داشته باش:

~~~text
KitsuneLab | OK | Daemon-managed game files, SteamCMD skipped
~~~

3. اگر KL-DMN-03 یا KL-DMN-04 دیده شد، موفقیت حسابش نکن؛ احتمال fallback به SteamCMD محلی وجود دارد. doctor/status و journal را بررسی کن.
4. بارگذاری Map و پاسخ Console را تأیید کن.
5. پس از موفقیت، مصرف واقعی Volume و فضای دیسک را بررسی کن. تا پیش از تأیید VPK Sync، Limit دیسک را 40 GB نگه دار.

### 8.5 — ساخت Instance دوم

بعد از تأیید سرور اول، یک سرور دیگر با همان Egg کامل KitsuneLab CS2 Go @ K4ryuu و Image برابر ghcr.io/k4ryuu/cs2-egg-go:stable بساز. Allocation آزاد و جداگانه برای آن انتخاب کن؛ پورت جدید را حدس نزن. بعد از Start باید پیام Daemon-managed game files, SteamCMD skipped ظاهر شود و cs2node status باید Instance دوم را بشناسد. Disk Limit حدود 5 GB را تنها پس از اندازه‌گیری مصرف واقعی Volume و تأیید موفقیت Shared Base تنظیم کن.

VMDK دوم برای این PoC لازم نیست. هیچ دو Instanceای را به یک Volume نوشتنی مشترک وصل نکن؛ اشتراک فایل بازی باید از مسیر مدیریت‌شدهٔ vpksync انجام شود.

## 9. نصب CounterStrikeSharp و پلاگین‌های Fun Mode — پس از قبولی Multi Instance

**طبق ترتیب مورد توافق، تا وقتی VPK Sync و دو Instance مستقل تأیید نشده‌اند، سراغ پلاگین‌ها و ریپوی KUS نمی‌رویم.** این مرحله فقط پس از قبولی Shared Base و Instance دوم اجرا می‌شود.

#### A. فعال‌کردن Framework

1. سرور را از پنل Stop کن و منتظر بمان وضعیت آن کاملاً متوقف شود.
2. در **Startup** مقدار `INSTALL_CSS` را به `1` تغییر بده.
3. `INSTALL_METAMOD` را همان مقدار پیش‌فرض نگه دار؛ طبق مستند K4ryuu، وقتی CounterStrikeSharp انتخاب شود MetaMod به‌صورت خودکار فعال می‌شود.
4. `INSTALL_SWIFTLY` و `INSTALL_MODSHARP` را برای این تست روی `0` نگه دار. فعلاً چند Framework را در یک Instance مخلوط نمی‌کنیم.
5. سرور را Start کن و بگذار Egg، Framework را دریافت/به‌روزرسانی کند. طبق مستند Egg، تا وقتی متغیر فعال است، updater مربوط به Framework هنگام راه‌اندازی اجرا می‌شود.

#### B. استقرار پلاگین‌های FragCity

پلاگین‌های Fun Mode و سایر افزونه‌های منتخب بخشی از نیاز اصلی محصول هستند. پس از فعال‌شدن CSS، فایل‌های **کامپایل‌شده و سازگار با CS2/نسخهٔ CSS** را به Volume همان سرور آزمایشی منتقل کن؛ از File Manager پنل یا SFTP همان Instance استفاده کن.

| محتوا | مسیر داخل Container |
|---|---|
| پلاگین‌های CounterStrikeSharp | `/home/container/game/csgo/addons/counterstrikesharp/plugins/` |
| تنظیمات CSS/Pluginها | `/home/container/game/csgo/addons/counterstrikesharp/configs/` |
| فایل‌های cfg بازی/Mode | `/home/container/game/csgo/cfg/` |

نکات استقرار:

- ساختار پوشهٔ هر Plugin را مطابق بستهٔ رسمی‌اش حفظ کن؛ DLL، dependency، gamedata و فایل‌های جانبی را کورکورانه در یک پوشه نریز.
- فایل‌های cfg و configs خصوصی هر Instance را مستقل نگه دار. **پلاگین مشترک به معنی تنظیمات یا پوشهٔ writable مشترک نیست.**
- از کپی کامل Repo/پوشهٔ build یا اجرای اسکریپت نصب Windows/KUS داخل Container خودداری کن. فقط فهرست تأییدشدهٔ پلاگین‌ها و artifactهای موردنیازشان را مستقر کن.
- محتوای VIP که قبلاً تصمیم گرفته شد از مجموعه حذف شود نباید به Manifest یا Deployment برگردد.
- افزونه‌ها را یک یا دو مورد در هر نوبت اضافه کن؛ پس از هر دسته، سرور را Restart و Console، بارگذاری Plugin، cfg، وابستگی‌ها و عملکرد Mode را بررسی کن. در صورت خطا همان دستهٔ آخر را بررسی/برگردان؛ کل پوشه‌ها را پاک نکن.
- اگر Plugin خطای dependency یا gamedata داد، پیش از کپی فایل بیشتر، نسخهٔ دقیق Plugin، پیش‌نیازهای رسمی و پیام Console را تطبیق بده.

#### C. معیار قبولی برای نسخهٔ Fun Mode

- [ ] CounterStrikeSharp و MetaMod بدون خطای startup بارگذاری شوند.
- [ ] فهرست Pluginها، نسخه‌ها و dependencyهای لازم ثبت شود.
- [ ] هر Fun Mode منتخب به‌صورت جداگانه بارگذاری شود و cfg خودش را بخواند.
- [ ] تغییر Map/Mode و بازگشت به حالت پیش‌فرض تست شود.
- [ ] Restart و Stop/Start پنل، فایل‌های Plugin و configs همان Instance را حفظ کنند.
- [ ] مصرف RAM/CPU در حالت Vanilla و در حالت Pluginها جداگانه مقایسه شود.
- [ ] هیچ فایل VIP ناخواسته‌ای در Manifest یا Instance وجود نداشته باشد.

**Shared Base فقط برای فایل‌های بازی است؛ پلاگین‌ها و configs نوشتنی هر Instance خصوصی می‌مانند.**

## 10. وضعیت واقعی و ادامهٔ مرحله‌ای — بررسی 2026-10-19

این بخش فقط آنچه را واقعاً گزارش شده ثبت می‌کند؛ نصب‌کننده اعلام کرده سرویس شروع شده، اما آماده‌بودن Base هنوز با `doctor/status` و فایل‌های مسیر مرکزی تأیید نشده است.

### موارد تأییدشده
- [x] کاربر پایان دانلود اولیهٔ بازی را برای `fc-cs2-test-01` گزارش کرده است.
- [x] Clone با کرنل `6.12.113+deb13-amd64` و حدود 182 GB فضای آزاد گزارش شده؛ kernel با روش `symlink` سازگار است.
- [x] Volume سرور شناسایی شده است: `/var/lib/pterodactyl/volumes/e098c53f-c207-46fd-b782-866c45a4e86b/`.
- [x] Manifest Volume موجود با `appid=730`، `StateFlags=4` و `buildid=25966348` مشاهده شده است. طبق تصمیم کاربر، این Volume منبع Seed نیست.
- [x] فایل‌سیستم موجود برای PoC انتخاب شده؛ VMDK دوم الزامی نیست.
- [x] باینری رسمی `cs2node` دریافت شده و `file` آن را ELF 64-bit x86-64 و statically linked گزارش کرده است.
- [x] Installer گزارش کرده config در `/etc/cs2node/config.json` نوشته، باینری را در `/usr/local/bin/cs2node` قرار داده، فایل systemd را ساخته و سرویس را enable/start کرده است.
- [x] تنظیم `vpksync` شامل `cs2_dir=/srv/cs2-shared` و `push_method=symlink` است؛ `check_minutes=30`، `restart_policy=empty`، `max_delay_hours=2` و `warn_minutes=10` ثبت شده است.
- [x] ماژول‌های `alerts`، `addoncache`، `workshop`، `backup`، `cleanup`، `crashes`، `consolelog` و `metrics` نیز در Wizard روشن شده‌اند؛ `guard` خاموش است.
- [ ] Running کامل سرور، بارگذاری Map، اتصال و Stop/Start هنوز به‌طور صریح تأیید نشده است.
- [x] `cs2node status/doctor` اجرا شد؛ daemon فعال است، اما Central Build برابر خالی است و `doctor` در VPK Sync خطا دارد.
- [x] پس از نصب `libc6:i386`, `libstdc++6:i386`, `libgcc-s1:i386` آزمون `sudo /root/steamcmd/steamcmd.sh +quit` موفق شد و Steam API با موفقیت Load/Unload شد.
- [x] پس از Restart سرویس، `vpksync up ... build=0` گزارش شد؛ بررسی بعدی Manifest مرکزی پیدا نکرد و VPK count صفر بود.
- [ ] باید از روی `ps`, Journal و رشد اندازهٔ `/srv/cs2-shared` مشخص شود تلاش مرکزی هنوز در حال دانلود است یا با خطای جدیدی شکست خورده.
- [ ] پس از افشای URL وب‌هوک Discord در لاگ چت، Webhook قبلی باید باطل و جایگزین شود؛ URL محرمانه در GitHub ثبت نشود.

### پنج گام بعدی — رفع SteamCMD و شروع دانلود

1. `fc-cs2-test-01` را Offline نگه دار و Clone را روشن بگذار.
2. دستور بخش 8.2.1 را اجرا کن تا i386 multiarch و Runtimeهای لازم نصب شوند.
3. `sudo /root/steamcmd/steamcmd.sh +quit` را آزمایش کن؛ اگر شکست خورد، خروجی را بفرست.
4. فقط پس از موفقیت تست، `sudo systemctl restart cs2node` و `sudo journalctl -u cs2node -f` را اجرا کن و شروع `app_update 730` را بررسی کن.
5. بعد از شروع واقعی دانلود، پیش از WinSCP ابتدا daemon و SteamCMD را با روش ثبت‌شده در بخش 8.2.2 متوقف می‌کنیم؛ انتقال VPK و Workshop مراحل جداگانه دارند. تا آن موقع سرور را Start نکن.

### منابع رسمی
- Egg installation: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md
- Node daemon: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md
- Panel variables: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/panel-variables.md
- VPK sync: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md
- Egg JSON: https://raw.githubusercontent.com/K4ryuu/CS2-Egg-Go/main/pterodactyl/kitsunelab-cs2-go-egg.json
