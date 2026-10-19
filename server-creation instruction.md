# FragCity — ساخت اولین سرور آزمایشی با KitsuneLab CS2 Go

> **هدف این فصل:** روی Clone آزمایشگاهی FragCity، Egg رسمی **KitsuneLab CS2 Go** متعلق به K4ryuu را وارد Pterodactyl کنیم، یک سرور پایه بسازیم و پیش از فعال‌کردن Shared Base، خود Egg را به‌تنهایی آزمایش کنیم.
>
> **وضعیت مستندات (2026-10-19، به‌روزرسانی مرحله‌ای):** پنل و شبکه طبق تأیید کاربر عملیاتی‌اند؛ Clone با hostname برابر `fc-node-01` و IP برابر `192.168.1.9` فعال است؛ Queue Worker و Scheduler روی Clone تنظیم شده‌اند. اولین Instance به نام `fc-cs2-test-01` ساخته شده و کاربر گزارش کرده دانلود اولیهٔ بازی پایان یافته است. بررسی فقط‌خواندنی روی Clone کرنل `6.12.113+deb13-amd64` و حدود `182 GB` فضای آزاد در فایل‌سیستم ریشه نشان داده است. در خروجی `lsblk` فعلی VMDK ثانویه‌ای دیده نشده، اما این مانع تست نیست: فعلاً Shared Base روی فایل‌سیستم فعلی در مسیر پیش‌فرض `/srv/cs2-shared` قرار می‌گیرد؛ حدود `182 GB` فضای آزاد مشاهده شده است. VMDK دوم فقط گزینهٔ جداسازی Storage برای فاز بعد/Production است. `cs2node` و `vpksync` هنوز نصب/فعال نشده‌اند. VM اصلی با IP `192.168.1.7` باید خاموش بماند.
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

## 8. تبدیل دانلود فعلی به Shared Base و فعال‌کردن VPK Sync

این فصل با مستندات رسمی K4ryuu تطبیق داده شده است: [Install](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md)، [Node daemon](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md)، [VPK Sync](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md)، [Node config](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/node-config.md)، [Protocol](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/protocol.md)، [Security](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/security.md) و [Troubleshooting](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/troubleshooting.md).

### تصمیم معماری

- Egg رسمی **KitsuneLab CS2 Go @ K4ryuu** انتخاب درستی است؛ این Egg/image کلاینت پروتکل cs2node را دارد و هنگام boot منتظر نتیجهٔ VPK Sync می‌ماند. Egg standalone فقط برای حالتی است که اصلاً daemon نمی‌خواهیم؛ برای Multi Instance ما همان Egg کامل لازم است.
- cs2node روی خود Debian اجرا می‌شود. ماژول vpksync فایل‌های مرکزی بازی را با Volume هر Instance همگام می‌کند. در روش symlink، VPKها به Base مرکزی read-only لینک می‌شوند؛ فایل‌های عادی لازم نیز sync می‌شوند و cfg/gameinfo برای هر Instance طبق منطق Egg محافظت می‌شوند.
- برای PoC از فایل‌سیستم فعلی استفاده می‌کنیم؛ حدود 182 GB فضای آزاد root گزارش شده است. VMDK دوم شرط لازم نیست.
- پیش از دانلود دوبارهٔ کامل، بررسی می‌کنیم آیا نصب فعلی می‌تواند seed نسخهٔ مرکزی /srv/cs2-shared شود. این seed کردن، مرحلهٔ بهینه‌سازی محلی FragCity است (نه روال اصلی‌ای که مستندات K4ryuu به‌صورت خودکار انجام می‌دهند)؛ فقط وقتی manifest و فایل‌های نصب کامل باشند انجام می‌شود. اگر بررسی شکست بخورد، از نصب مرکزی معمول SteamCMD استفاده می‌کنیم.
- فایل‌های نصب فعلی را Move نمی‌کنیم. ابتدا با rsync یک کپی مستقل می‌سازیم تا اگر seed یا SteamCMD ناموفق بود، Volume فعلی قابل بازیابی بماند.

### 8.1 — تفسیر نصب موجود و آماده‌کردن منبع ویندوز

بازرسی انجام‌شده در 2026-10-19 کامل است؛ حجم 69 GB یک خطا محسوب نمی‌شود و دیگر لازم نیست برای توضیح آن اسکن جداگانه اجرا شود. خروجی گزارش‌شده:

- `game/csgo`: حدود 61 GB؛ `game/csgo/maps`: حدود 9.6 GB.
- `game/csgo_community_addons`: حدود 6.4 GB؛ این مسیر محتوای Community/Workshop را نگه می‌دارد.
- کل فایل‌های VPK داخل `game/`: تعداد 739 و مجموع 67.75 GiB؛ تعداد symlink برابر صفر بود.
- Manifest لینوکسی موجود در `$VOL/steamapps/appmanifest_730.acf`: appid=730، StateFlags=4 و buildid=25966348.
- `/srv/cs2-shared` هنوز ساخته نشده و `cs2node` هنوز نصب نیست.

**روش انتخاب‌شده:** نصب فعلیِ دانلودشده روی Debian پایهٔ مورداعتماد برای فایل‌های بازی و manifest باقی می‌ماند؛ فایل‌های Windows برای اضافه‌کردن Library کامل Workshop استفاده می‌شوند. این کار از جایگزین‌شدن تصادفی runtime/باینری‌های لینوکس با فایل‌های ویندوز جلوگیری می‌کند. `steamapps`، `Steam`، `.steam`، `steamcmd` یا فایل‌های اجرایی/کتابخانه‌های Windows را از نصب Windows به Shared Base کپی نکن. پس از آماده‌شدن Base، `cs2node`/SteamCMD مسئول بررسی و تکمیل فایل‌های نصب مرکزی خواهد بود.

### 8.2 — اشتراک‌گذاری فقط‌خواندنی نصب Windows و بررسی محتوای Workshop

در Windows، از Steam روی Counter-Strike 2 برو به **Properties → Installed Files → Browse** تا مسیر واقعی نصب را ببینی. در تنظیمات همان Clone در VMware Workstation، بخش **Options → Shared Folders** را باز کن، Shared Folders را روی **Always enabled** بگذار و ریشهٔ نصب بازی را به‌عنوان Folder جدید با نام `CS2WIN` اضافه کن. گزینهٔ **Read-only** را فعال کن؛ لازم نیست کل Steam Library یا کل درایو Windows را Share کنی.

در SSH روی Debian فقط بررسی کن که Share و ساختار آن دیده می‌شوند؛ هنوز هیچ کپی‌ای انجام نده:

~~~bash
set -eu
WINROOT="/mnt/hgfs/CS2WIN"
VOL="/var/lib/pterodactyl/volumes/e098c53f-c207-46fd-b782-866c45a4e86b"

echo "=== VMware shared folders ==="
ls -lah /mnt/hgfs 2>/dev/null || true
findmnt -t fuse.vmhgfs-fuse || true

echo
echo "=== Windows CS2 source root ==="
if [ ! -d "$WINROOT/game" ]; then
  echo "STOP: $WINROOT/game not found; do not copy anything."
  exit 1
fi
ls -lah "$WINROOT"
echo
echo "=== Windows game folders ==="
for p in "$WINROOT/game/csgo" "$WINROOT/game/csgo_community_addons" "$WINROOT/game/csgo/maps"; do
  if [ -d "$p" ]; then
    sudo du -sh "$p"
    sudo find "$p" -maxdepth 2 -type d | head -n 25
  else
    echo "MISSING: $p"
  fi
done

echo
echo "=== Windows Workshop VPK count and total bytes ==="
if [ -d "$WINROOT/game/csgo_community_addons" ]; then
  sudo find "$WINROOT/game/csgo_community_addons" -type f -name '*.vpk' -printf '%s\n' |
    awk '{bytes += $1; count++} END {printf "count=%d total_GiB=%.2f\n", count, bytes/1024/1024/1024}'
fi

echo
echo "=== Current free space ==="
df -hT /
echo
echo "=== Current server workshop folder ==="
sudo du -sh "$VOL/game/csgo_community_addons" 2>/dev/null || true
~~~

اگر Share مسیر متفاوتی دارد، `game/` پیدا نمی‌شود یا `csgo_community_addons` روی Windows وجود ندارد، متوقف شو و خروجی را بفرست. مسیر را حدس نزن و هنوز `rsync`، نصب `cs2node` یا ایجاد Base را اجرا نکن.

### 8.2.1 — روش Seed پس از تأیید خروجی Share

فقط پس از اینکه مسیر Windows و حجم واقعی Workshop را دیدیم، کار کپی انجام می‌شود. سرور `fc-cs2-test-01` باید کاملاً **Offline** باشد و `/srv/cs2-shared` نباید قبلاً دادهٔ ناشناخته داشته باشد.

ابتدا نسخهٔ مستقل Base را از نصب Linux فعلی و manifest خودش بساز؛ Volume اصلی را Move/Delete نکن:

~~~bash
set -eu
VOL="/var/lib/pterodactyl/volumes/e098c53f-c207-46fd-b782-866c45a4e86b"
BASE="/srv/cs2-shared"

sudo test -d "$VOL/game/csgo" || { echo "STOP: Linux source game missing"; exit 1; }
sudo test -f "$VOL/steamapps/appmanifest_730.acf" || { echo "STOP: Linux appmanifest missing"; exit 1; }
if sudo test -d "$BASE" && [ -n "$(sudo find "$BASE" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "STOP: $BASE is non-empty; inspect it before copying"
  exit 1
fi

sudo mkdir -p "$BASE/game" "$BASE/steamapps"
sudo rsync -a --chown=root:root --info=progress2 "$VOL/game/" "$BASE/game/"
sudo rsync -a --chown=root:root --info=progress2 "$VOL/steamapps/" "$BASE/steamapps/"
~~~

بعد از تأیید مسیر و موجودبودن کامل Workshop روی Windows، محتوای پوشهٔ Workshop را با Merge غیرحذفی به Base اضافه کن. **از `--delete` استفاده نکن** و پوشهٔ `game/` را از Windows به‌صورت کامل روی نسخهٔ Linux جایگزین نکن:

~~~bash
set -eu
WINROOT="/mnt/hgfs/CS2WIN"
BASE="/srv/cs2-shared"
SRC="$WINROOT/game/csgo_community_addons"
DST="$BASE/game/csgo_community_addons"

sudo test -d "$SRC" || { echo "STOP: Windows Workshop source missing"; exit 1; }
sudo test -f "$BASE/steamapps/appmanifest_730.acf" || { echo "STOP: Linux appmanifest missing from Base"; exit 1; }

sudo mkdir -p "$DST"
sudo rsync -a --chown=root:root --info=progress2 "$SRC/" "$DST/"

echo
echo "=== Shared Base result ==="
sudo grep -E '"(appid|buildid|StateFlags)"' "$BASE/steamapps/appmanifest_730.acf"
sudo du -sh "$BASE/game" "$BASE/game/csgo_community_addons" "$BASE/steamapps"
sudo find "$BASE/game/csgo_community_addons" -type f -name '*.vpk' | wc -l
df -hT /
~~~

این Merge فایل‌های موجود روی Base را که در Share ویندوز نیستند حذف نمی‌کند. قبل از نصب daemon، Build ID و تعداد/حجم Workshop نهایی باید ثبت شود. در اولین راه‌اندازی central SteamCMD ممکن است دانلود افزایشی/اصلاح فایل‌ها انجام دهد؛ جلوگیری از هرگونه دانلود تضمین‌شده نیست.

### 8.3 گام سوم — نصب رسمی cs2node

فقط پس از بررسی 8.1 و در صورت امکان تکمیل seed مرحلهٔ 8.2، Installer رسمی را اجرا کن:

~~~bash
curl -fsSL https://github.com/K4ryuu/CS2-Egg-Go/releases/latest/download/cs2node_linux_amd64 -o /tmp/cs2node
chmod +x /tmp/cs2node
sudo /tmp/cs2node install
~~~

در پرسش Proceed? پاسخ y بده؛ سپس:
- Update channel: stable
- Auto-update: y
- فقط vpksync را فعال کن (y).
- برای guard، alerts، addoncache، workshop، backup، cleanup، crashes، consolelog و metrics فعلاً n بزن. در نصب تازه پیش‌فرض فعال‌سازی Moduleها ممکن است Yes باشد؛ Enter خالی نزن.

تنظیمات vpksync:

| پرسش | مقدار FragCity |
|---|---|
| steamcmd_dir | /root/steamcmd |
| cs2_dir | /srv/cs2-shared |
| push_method | symlink |
| max_workers | 8 |
| auto_restart | y |
| restart_policy | empty |
| max_delay_hours | 12 |
| warn_minutes | 5 |
| validate | n |
| check_minutes | 60 |

check_minutes برابر 60 تنظیم FragCity برای بررسی ساعتی است؛ پیش‌فرض upstream یک دقیقه است. restart_policy روی empty می‌ماند تا سرور ترجیحاً هنگام خالی بودن restart شود. پیش از نصب نهایی، Summary را چک کن: فقط vpksync روشن باشد و Base دقیقاً /srv/cs2-shared باشد. اگر prompt متفاوت بود، حدس نزن؛ همان prompt را بفرست.

### 8.4 گام چهارم — بررسی daemon و Base مرکزی

پس از نصب، اولین Update مرکزی ممکن است خودکار شروع شود. لاگ زنده:

~~~bash
sudo journalctl -u cs2node -f
~~~

بعد از پایان کار، با Ctrl+C فقط از دنبال‌کردن لاگ خارج شو (این کار سرویس را متوقف نمی‌کند)، و اجرا کن:

~~~bash
echo "=== Service ==="
sudo systemctl status cs2node --no-pager

echo
echo "=== Version ==="
sudo cs2node version

echo
echo "=== Doctor ==="
sudo cs2node doctor

echo
echo "=== Status ==="
sudo cs2node status

echo
echo "=== Central build and VPK count ==="
sudo grep -E '"(appid|buildid|StateFlags)"' /srv/cs2-shared/steamapps/appmanifest_730.acf
sudo find /srv/cs2-shared/game -type f -name '*.vpk' | wc -l
df -hT / /srv /var/lib/pterodactyl/volumes 2>/dev/null
~~~

اگر doctor می‌گوید Base وجود ندارد، Build ID ندارد یا تعداد VPK صفر است، سرور را Start نکن. خروجی doctor/status و لاگ مربوطه را بفرست.

### 8.5 گام پنجم — اتصال سرور اول به Base

فقط وقتی Base مرکزی تأیید شد:
1. از پنل fc-cs2-test-01 را Start کن.
2. در Console انتظار این پیام موفق را داشته باش:

~~~text
KitsuneLab | OK | Daemon-managed game files, SteamCMD skipped
~~~

3. اگر KL-DMN-03 یا KL-DMN-04 دیده شد، موفقیت حسابش نکن؛ احتمال fallback به SteamCMD محلی وجود دارد. doctor/status و journal را بررسی کن.
4. بارگذاری Map و پاسخ Console را تأیید کن.
5. پس از موفقیت، مصرف واقعی Volume و فضای دیسک را بررسی کن. تا پیش از تأیید VPK Sync، Limit دیسک را 40 GB نگه دار.

### 8.6 گام ششم — ساخت Instance دوم

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

این بخش فقط نتیجه‌هایی را ثبت می‌کند که کاربر واقعاً اجرا/گزارش کرده است؛ نصب‌های آینده را Completed فرض نکن.

### موارد تأییدشده

- [x] کاربر گزارش کرده دانلود اولیهٔ بازی برای `fc-cs2-test-01` تمام شده است.
- [x] کرنل Clone از خروجی `uname -r`: `6.12.113+deb13-amd64`. این نسخه برای روش `symlink` موردنیاز K4ryuu (Linux kernel 5.2+) جدیدتر است.
- [x] فایل‌سیستم ریشه از خروجی `df -hT`: اندازهٔ حدود `268G`، مصرف `73G` و فضای آزاد حدود `182G`.
- [x] خروجی فعلی `lsblk` فقط دیسک `sda` با اندازهٔ `300G` (پارتیشن Boot، پارتیشن LVM، Logical Volume ریشه و Swap) و درایو نوری `sr0` را نشان داده است؛ هیچ دیسک دیتای ثانویه در آن خروجی مشاهده نشده.
- [x] Volume سرور در میزبان شناسایی شده است: `/var/lib/pterodactyl/volumes/e098c53f-c207-46fd-b782-866c45a4e86b/`.
- [x] Manifest در مسیر صحیح $VOL/steamapps/appmanifest_730.acf وجود دارد؛ خروجی شامل appid=730، StateFlags=4 و buildid=25966348 بود.
- [ ] آزمون کامل Vanilla (Running، بارگذاری Map، اتصال و Stop/Start) هنوز به‌طور صریح تأیید نشده است.
- [x] تصمیم گرفته شد برای PoC فعلی از فایل‌سیستم موجود استفاده کنیم؛ VMDK دوم پیش‌نیاز `cs2node`/`vpksync` نیست.
- [ ] `cs2node`، ماژول `vpksync` و Shared Base هنوز نصب/فعال نشده‌اند؛ در اولین Update مرکزی ممکن است SteamCMD دانلود افزایشی یا فایل‌های مخصوص پلتفرم را دریافت کند. میزان واقعی را از لاگ و Build ID ثبت می‌کنیم و دانلودنشدن کامل را تضمین نمی‌کنیم.

### پنج گام بعدی — اتصال منبع Windows و بررسی Workshop

خروجی فقط‌خواندنیِ ارسال‌شده در 2026-10-19 نشان داد حجم 69 GB قابل توضیح است: `game/csgo` حدود 61 GB، `game/csgo/maps` حدود 9.6 GB و `game/csgo_community_addons` حدود 6.4 GB است. در مجموع 739 فایل VPK برابر با 67.75 GiB دیده شده و Symlink فعلی صفر است. این عدد را نقص فرض نکنیم؛ مرحلهٔ بعد استفاده از محتوای Windows برای کامل‌کردن Workshop است.

1. در Steam روی Windows از **Counter-Strike 2 → Properties → Installed Files → Browse** مسیر واقعی بازی را پیدا کن.
2. تنظیمات VMware مربوط به **Clone** را باز کن: Options → Shared Folders → Always enabled → Add؛ ریشهٔ نصب بازی را با نام `CS2WIN` اضافه کن و حتماً Read-only را فعال کن. کل درایو را Share نکن.
3. داخل Debian، ابتدا `/mnt/hgfs/CS2WIN/game` را بررسی کن. اگر مسیر پیدا نشد، هیچ کپی‌ای انجام نده.
4. فرمان بازرسی read-only بخش 8.2 را اجرا کن تا ساختار `csgo_community_addons`، حجم آن، تعداد VPKها و فضای آزاد دیسک مشخص شود.
5. خروجی را بفرست. فعلاً `/srv/cs2-shared` را نساز، `rsync` اجرا نکن و `cs2node` را نصب نکن؛ پس از تأیید ساختار و فضای لازم، Seed لینوکسی و Merge محتوای Workshop را مرحله‌ای انجام می‌دهیم.

### منابع رسمی

- Egg installation: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md
- Node daemon: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md
- Panel variables: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/panel-variables.md
- VPK sync: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md
- Egg JSON: https://raw.githubusercontent.com/K4ryuu/CS2-Egg-Go/main/pterodactyl/kitsunelab-cs2-go-egg.json
