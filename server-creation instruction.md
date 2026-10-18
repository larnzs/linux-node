# FragCity — ساخت اولین سرور آزمایشی با KitsuneLab CS2 Go

> **هدف این فصل:** روی Clone آزمایشگاهی FragCity، Egg رسمی **KitsuneLab CS2 Go** متعلق به K4ryuu را وارد Pterodactyl کنیم، یک سرور پایه بسازیم و پیش از فعال‌کردن Shared Base، خود Egg را به‌تنهایی آزمایش کنیم.
>
> **وضعیت شروع (2026-10-19):** پنل و شبکه طبق تأیید کاربر عملیاتی‌اند؛ Clone با hostname برابر `fc-node-01` و IP برابر `192.168.1.9` فعال است؛ Queue Worker و Scheduler روی Clone تنظیم شده‌اند. VM اصلی با IP `192.168.1.7` باید خاموش بماند. هنوز CS2 Instance ساخته نشده و VMDK دادهٔ دوم هنوز باید جداگانه اضافه و شناسایی شود.
>
> **منبع اصلی:** https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md  
> راهنمای Node daemon: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md

---

## 0. تصمیم‌های این تست

- ابتدا فقط **یک سرور آزمایشی** می‌سازیم و آن را بدون Node daemon اجرا می‌کنیم. این همان اولین گام پیشنهادی مستندات K4ryuu است؛ Egg بدون daemon هم با SteamCMD فایل‌های بازی را دریافت می‌کند.
- از Egg اصلیِ قابل‌استفاده با Node daemon استفاده می‌کنیم: **KitsuneLab CS2 Go @ K4ryuu**. فعلاً Image نسخهٔ `stable` را انتخاب می‌کنیم، نه `beta`.
- نخستین دانلود CS2 حدود 35 GB است؛ طبق راهنمای K4ryuu برای تست بدون VPK sync، سقف دیسک سرور را **40 GB** در نظر می‌گیریم. این فایل‌ها داخل Volume معمول سرور Pterodactyl قرار می‌گیرند. قبل از ساخت سرور، فضای آزاد میزبان Volume را دوباره بررسی کن.
- VMDK دادهٔ دوم هنوز آماده و mount نشده است. بنابراین **Node daemon، VPK sync و Shared Base را تا آماده‌شدن Storage مستقل نصب یا فعال نکن**؛ مسیر پیش‌فرض فایل‌های مشترک Node برابر `/srv/cs2-shared` است و باید به‌درستی روی Storage طراحی‌شده قرار بگیرد.
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

### 7.1 مرحلهٔ ضروری FragCity — نصب CounterStrikeSharp و پلاگین‌های Fun Mode

**سرور Vanilla تنها Baseline فنی است؛ تحویل آزمایشی FragCity بدون پلاگین‌های موردنیاز و Fun Modeها کامل نیست.** این مرحله بعد از آن انجام می‌شود که بازی پایه بدون افزونه به‌درستی Boot، Map، Console و Stop/Start را پاس کرده باشد.

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

**این نسخه زمانی برای آزمایش FragCity قبول می‌شود که هم Baseline بازی و هم Plugin/Fun Modeهای منتخب پاس شوند.** تا زمان آماده‌شدن VMDK داده، پلاگین‌ها و configs داخل Volume مستقل همان Instance باقی می‌مانند؛ Shared Base برای فایل‌های بازی طراحی می‌شود، نه برای اشتراک‌گذاری writable پلاگین‌ها یا configs بین مشتریان.

## 8. Node daemon و Shared Base — مرحلهٔ بعد، نه الان

پس از موفقیت اولین سرور مستقل، مرحلهٔ بعد از راهنمای [Install the node daemon](https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md) پیروی می‌کند. تا آماده‌شدن Storage مستقل، `cs2node install` را اجرا نکن:

1. VMDK داده فقط به Clone اضافه شود و دستگاه واقعی با `lsblk` و `blkid` شناسایی گردد.
2. Mount دائمی Storage مشترک طراحی شود. مسیر پیش‌فرض K4ryuu برای Base برابر `/srv/cs2-shared` است؛ اگر هدف جداسازی Storage بازی از دیسک سیستم است، آن را به Storage طراحی‌شده منتقل می‌کنیم.
3. پس از mount و بررسی ظرفیت، نصب `cs2node` از منبع رسمی و تنظیم `vpksync` انجام شود.
4. `sudo cs2node doctor` و `sudo cs2node status` بررسی شوند؛ سپس یک Restart کنترل‌شده از پنل انجام شود.
5. Console باید تشخیص دهد فایل‌های بازی تحت مدیریت Node هستند و در این حالت SteamCMD در هر سرور تکرار نشود. تنها پس از تأیید این رفتار، سقف دیسک حدود 5 GB برای Instanceهای بعدی اعمال شود.

چند سرور را به یک Volume نوشتنیِ مشترک با Mount دستی وصل نکن؛ VPK sync روش مدیریت‌شدهٔ خودش را دارد و نباید با طرح آزمایش‌نشده ترکیب شود.

## 9. Checkpoint فعلی

**گام بعدی:** Egg را از URL رسمی بخش 2 وارد کن و تأیید کن `KitsuneLab CS2 Go @ K4ryuu` در لیست Eggها دیده می‌شود.

بعد از Import، پیش از Create/Start، مراحل 1 و 3 را بررسی کن: Clone فعال باشد، فضای آزاد کافی باشد و Allocation پورت `29001` واقعاً قابل‌استفاده باشد. پس از ساخت و اولین Start موفق، Checklist بخش 7 را تکمیل می‌کنیم؛ سپس سراغ VMDK دوم و `cs2node` می‌رویم.

### منابع رسمی

- Egg installation: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/install.md
- Node daemon: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/node.md
- Panel variables: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/reference/panel-variables.md
- VPK sync: https://github.com/K4ryuu/CS2-Egg-Go/blob/main/docs/modules/vpk-sync.md
- Egg JSON: https://raw.githubusercontent.com/K4ryuu/CS2-Egg-Go/main/pterodactyl/kitsunelab-cs2-go-egg.json
