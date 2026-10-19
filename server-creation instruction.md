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

### تصمیم معماری — دانلود تازه از SteamCMD

- طبق تصمیم کاربر، **هیچ فایل بازی از Windows یا از Volume فعلی Pterodactyl به Shared Base کپی/Seed نمی‌شود**. پوشهٔ `/srv/cs2-shared` باید با `cs2node` و SteamCMD از ابتدا آماده شود.
- Instance فعلی `fc-cs2-test-01` را حذف نکن؛ در پنل Offline نگهش دار. Volume موجود صرفاً برای عیب‌یابی/بازیابی حفظ می‌شود و منبع Base مرکزی نیست.
- از Egg کامل **KitsuneLab CS2 Go @ K4ryuu** استفاده می‌کنیم؛ این Egg با پروتکل cs2node سازگار است. Egg standalone انتخاب نشود.
- `cs2node` روی Debian به‌عنوان سرویس host اجرا می‌شود؛ ماژول `vpksync` یک نصب مرکزی تولید می‌کند و VPKها را به‌شکل read-only از Base می‌دهد. configs و فایل‌های نوشتنی هر Instance خصوصی می‌مانند.
- PoC فعلاً روی فایل‌سیستم فعلی با حدود 182 GB فضای آزاد انجام می‌شود؛ VMDK دوم لازم نیست.
- مرحلهٔ فعلی فقط اثبات Fresh Base، اتصال Instance اول و بعد Instance دوم است. CounterStrikeSharp و پلاگین‌های FragCity را قبل از قبولی این آزمون نصب نکن.

### 8.1 — پیش‌بررسی قبل از نصب daemon

1. در پنل Pterodactyl مطمئن شو `fc-cs2-test-01` وضعیت **Offline** دارد. آن را Delete یا Reinstall نکن.
2. در SSH این بلوک فقط‌خواندنی را اجرا کن. اگر `/srv/cs2-shared` وجود دارد و خالی نیست، آن را پاک نکن و ادامه نده؛ خروجی را بفرست.

~~~bash
echo "=== Existing cs2node ==="
command -v cs2node || true
sudo systemctl is-active cs2node 2>/dev/null || true

echo
echo "=== Existing central base ==="
if sudo test -d /srv/cs2-shared; then
  sudo ls -lah /srv/cs2-shared
  sudo du -sh /srv/cs2-shared
  sudo find /srv/cs2-shared -mindepth 1 -maxdepth 1 -printf '%f\t%y\n' | head -n 30
else
  echo "/srv/cs2-shared does not exist"
fi

echo
echo "=== Free space and kernel ==="
df -hT /
uname -r
~~~

### 8.2 — دریافت باینری رسمی cs2node

پس از تأیید اینکه سرویس نصب نیست و Base قبلی/دادهٔ ناشناخته‌ای در مقصد وجود ندارد، این دستورها را اجرا کن:

~~~bash
curl -fsSL https://github.com/K4ryuu/CS2-Egg-Go/releases/latest/download/cs2node_linux_amd64 -o /tmp/cs2node
chmod +x /tmp/cs2node
file /tmp/cs2node
~~~

اگر `curl` یا `file` خطا داد، قبل از اجرا خروجی را بفرست.

### 8.3 — اجرای Wizard و تنظیم Fresh Base

حالا Installer را به‌شکل تعاملی اجرا کن؛ از `--yes` استفاده نکن، چون همهٔ پیش‌فرض‌های Moduleها را بدون پرسیدن می‌پذیرد:

~~~bash
sudo /tmp/cs2node install
~~~

مقادیر موردنظر FragCity:

- **Proceed:** `y`
- **Update channel:** `stable`
- **Auto-update:** `y`
- **Moduleها:** فقط `vpksync` را `y` کن؛ برای `guard`، `alerts`، `addoncache`، `workshop`، `backup`، `cleanup`، `crashes`، `consolelog` و `metrics` در این PoC مقدار `n` بده. Enter خالی نزن، چون بعضی پیش‌فرض‌ها ممکن است روشن باشند. ماژول Workshop را بعد از اثبات Base و Multi Instance جداگانه ارزیابی می‌کنیم.
- در تنظیمات `vpksync` این مقادیر را وارد کن:

| پرسش | مقدار |
|---|---|
| `steamcmd_dir` | `/root/steamcmd` |
| `cs2_dir` | `/srv/cs2-shared` |
| `push_method` | `symlink` |
| `max_workers` | `8` |
| `auto_restart` | `y` |
| `restart_policy` | `empty` |
| `max_delay_hours` | `12` |
| `warn_minutes` | `5` |
| `validate` | `n` |
| `check_minutes` | `60` |

`check_minutes=60` انتخاب FragCity برای بررسی ساعتی است؛ پیش‌فرض upstream یک دقیقه است. `restart_policy=empty` اجازه می‌دهد بعد از Update تا خالی‌شدن سرور یا رسیدن مهلت صبر شود.

**قبل از تأیید Summary** مطمئن شو فقط `vpksync` فعال است و `cs2_dir` برابر `/srv/cs2-shared` است. اگر prompt با جدول فرق داشت یا دربارهٔ overwrite/مهاجرت از نصب موجود پرسید، حدس نزن و همان prompt را بفرست.

پس از تکمیل Wizard، `cs2node` ممکن است SteamCMD را به‌صورت خودکار اجرا و نصب مرکزی را از نو دانلود کند. این بار حجم و مدت دانلود را از لاگ واقعی ثبت می‌کنیم؛ هیچ فایل بازی از Windows یا Volume فعلی برای کوتاه‌کردن دانلود استفاده نمی‌شود.

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

### پنج گام بعدی — Fresh Download و نصب cs2node

بازرسی read-only انجام‌شده در 2026-10-19 ثبت شد: `game/csgo` حدود 61 GB، `game/csgo/maps` حدود 9.6 GB، `game/csgo_community_addons` حدود 6.4 GB، و 739 فایل VPK با مجموع 67.75 GiB؛ حجم 69 GB را خطا فرض نمی‌کنیم. طبق تصمیم جدید کاربر، این فایل‌ها نه از Windows و نه از Volume موجود Seed نمی‌شوند؛ Base مرکزی باید با SteamCMD تازه دانلود شود.

1. سرور `fc-cs2-test-01` را در پنل Offline نگه دار و حذف نکن.
2. فرمان پیش‌بررسی بخش 8.1 را اجرا کن؛ اگر `/srv/cs2-shared` از قبل non-empty است، هیچ چیز پاک نکن.
3. باینری رسمی cs2node را طبق بخش 8.2 بگیر و `file /tmp/cs2node` را بررسی کن.
4. Wizard را طبق بخش 8.3 اجرا کن: فقط `vpksync`، مسیر `/srv/cs2-shared` و روش `symlink`.
5. بعد از تمام‌شدن Wizard، سرور را Start نکن؛ خروجی تنظیمات/وضعیت سرویس را بفرست تا دانلود مرکزی را با `journalctl` و `cs2node doctor/status` بررسی کنیم.

### منابع رسمی

- Egg installation: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md
- Node daemon: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md
- Panel variables: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/panel-variables.md
- VPK sync: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md
- Egg JSON: https://raw.githubusercontent.com/K4ryuu/CS2-Egg-Go/main/pterodactyl/kitsunelab-cs2-go-egg.json
