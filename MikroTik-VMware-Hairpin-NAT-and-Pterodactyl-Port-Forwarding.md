# MikroTik در VMware: عیب‌یابی Hairpin NAT و اصلاح Firewall برای Pterodactyl

> **هدف این راهنما:** توضیح دقیق رخدادی که باعث می‌شد دسترسی به سرویس‌های Pterodactyl با فعال بودن Rule نهایی Drop قطع شود، حتی با اینکه NAT Counterها افزایش پیدا می‌کردند. راه‌حل، اضافه‌کردن یک قانون مجازکننده برای DNAT ورودی از LAN (Hairpin/NAT Loopback) است؛ نه خاموش‌گذاشتن فایروال.
>
> این Runbook بر پایهٔ عیب‌یابی RouterOS 7.24.4 در محیط VMware نوشته شده است. IPها و رابط‌های زیر مقادیر محیط مرجع‌اند؛ در شبکهٔ دیگری ابتدا توپولوژی واقعی را بررسی کنید. آدرس‌های عمومی و MACهای حاضر در لاگ اصلی عمداً در این سند بازنشر نشده‌اند.

## 1. توپولوژی بررسی‌شده

| جزء | مقدار محیط مرجع | نقش |
|---|---|---|
| MikroTik RouterOS | RouterOS 7.24.4 داخل VMware | NAT و Firewall |
| `Bridge` | کارت Ethernet اول VM؛ در این سناریو به مودم متصل است | سمت مودم/WAN در حالت Router Mode + DMZ |
| `ether2` | کارت Ethernet دوم VM، متصل به VMware VMnet1 Host-Only | شبکه LAN داخلی |
| IP سمت LAN روتر | `192.168.2.1/24` روی `ether2` | Gateway شبکه Host-Only |
| Pterodactyl Node | `192.168.2.3` | Debian/Linux؛ Panel/Wings و سرویس‌های بازی |
| کلاینت داخلی نمونه در لاگ | `192.168.2.2` | دستگاهی که درخواستش از LAN وارد شده بود |
| Interface List | `WAN = Bridge`, `LAN = ether2` | دسته‌بندی رابط‌ها برای Filter Rules |

**توجه به نام رابط:** نام `Bridge` در این VM نام رابط Ethernet اول است که در Export با `name=Bridge` دیده می‌شود؛ این نام به‌تنهایی به معنی وجود یک Software Bridge RouterOS نیست. قبل از کپی‌کردن فرمان‌ها، نام رابط واقعی را با `/interface print detail` تأیید کنید.

### مسیر دو نوع ترافیک را از ابتدا از هم جدا کنید

- **ترافیک واقعی اینترنت:** وارد MikroTik از سمت مودم/WAN می‌شود؛ در توپولوژی مودم Router Mode، رابط ورودی مورد انتظار `Bridge` است. پس از DNAT به Node هدایت می‌شود و از مسیر `ether2` خارج می‌شود.
- **ترافیک Hairpin از LAN:** کلاینت داخلی به IP عمومی یا دامنهٔ عمومی خود سرور وصل می‌شود. این پکت از `ether2` وارد می‌شود و پس از DNAT دوباره از `ether2` به Node خارج می‌شود. این مسیر همچنان از Firewall زنجیرهٔ `forward` عبور می‌کند.

این دو مسیر مشابه‌اند، اما رابط ورودی و قوانین لازم آن‌ها یکی نیست.

## 2. نشانهٔ اصلی مشکل

در زمان عیب‌یابی این رفتار مشاهده شد:

1. با خاموش‌کردن تمام Filter Rules، دسترسی به سرویس‌ها برقرار می‌شد.
2. پس از فعال‌کردن فایروال، دسترسی برخی سرویس‌ها قطع می‌شد.
3. خاموش‌کردن موقت Rule شمارهٔ 13 با توضیح `FORWARD - drop everything else` دسترسی را برمی‌گرداند.
4. شمارنده‌های بعضی از `dst-nat` Rules افزایش داشتند؛ بنابراین ترافیک مورد آزمایش به NAT رسیده بود.
5. با Logging روی Rule نهایی Drop، پکت‌هایی با `in:ether2 out:ether2` ثبت شدند.

**نتیجه:** در این رخداد، NAT لزوماً خراب نبود؛ Filter در زنجیرهٔ `forward` پکت‌های Hairpin را حذف می‌کرد. غیرفعال‌کردن Rule نهایی Drop صرفاً پنهان‌کردن مشکل بود و نباید راه‌حل دائمی بماند.

## 3. لاگ تعیین‌کننده چگونه خوانده می‌شود؟

در لاگ واقعی، نمونه‌هایی با این ساختار دیده شدند (IP عمومی به‌صورت placeholder آمده است):

```text
FWD-DROP forward: in:ether2 out:ether2,
connection-state=new,dnat,
proto TCP (SYN),
192.168.2.2:14444 -> 192.168.2.3:8080,
NAT (PUBLIC_IP:8080 -> 192.168.2.3:8080)
```

همچنین نمونه‌هایی برای TCP/80 و UDP پورت‌های بازی ثبت شده بودند.

معنی فیلدهای مهم:

- `chain=forward`: پکت از روتر عبور می‌کند و مقصدش خود سرویس مدیریتی MikroTik نیست.
- `in:ether2`: پکت از شبکهٔ LAN/Host-Only وارد روتر شده است.
- `out:ether2`: بعد از تصمیم مسیریابی/NAT، پکت از همان رابط به سمت شبکهٔ داخلی خارج می‌شود.
- `connection-state=new,dnat`: اتصال جدید است و Connection Tracking آن را DNAT‌شده تشخیص داده است.
- `PUBLIC_IP:8080 -> 192.168.2.3:8080`: مقصد عمومی اولیه به IP داخلی Node تبدیل شده است.

این الگو مشخصهٔ درخواست داخلی به IP عمومی/دامنهٔ عمومی است؛ به آن **Hairpin NAT** یا **NAT Loopback** گفته می‌شود. یعنی کلاینت داخلی از نام/آدرس عمومی استفاده می‌کند، ولی مقصد واقعی سرویس در همان LAN قرار دارد.

## 4. چرا Ruleهای قبلی آن را قبول نمی‌کردند؟

قواعد مهم زنجیرهٔ `forward` در زمان بررسی این‌ها بودند:

| ترتیب | Comment | شرط/کارکرد |
|---:|---|---|
| 1 | `FORWARD - fasttrack established/related` | FastTrack برای اتصال‌های established/related |
| 2 | `FORWARD - established/related` | اجازه به ترافیک اتصال‌های برقرارشده |
| 3 | `FORWARD - drop invalid` | حذف اتصال‌های invalid |
| 4 | `FORWARD - LAN to Internet` | اجازهٔ ترافیک خروجی از LAN به WAN |
| 5 | `FORWARD - allow dstnat` | اجازهٔ DNAT جدیدی که از Interface List به نام WAN وارد شده |
| 6 | `FORWARD - drop unsolicited WAN` | حذف اتصال‌های جدید ناخواسته از WAN که DNAT نشده‌اند |
| 7 | `FORWARD - drop everything else` | حذف همهٔ پکت‌هایی که به قواعد قبلی نخورده‌اند |

Rule مجازکنندهٔ DNAT روی WAN چنین شرط‌هایی داشت:

```routeros
chain=forward
action=accept
connection-state=new
connection-nat-state=dstnat
in-interface-list=WAN
```

این شرط برای بسته‌ای که از WAN وارد می‌شود مناسب است. اما پکت ثبت‌شده در لاگ از `ether2` وارد شده بود و `ether2` عضو `LAN` است؛ بنابراین `in-interface-list=WAN` با آن تطبیق نمی‌کرد.

قانون `FORWARD - LAN to Internet` هم کمکی نمی‌کرد، چون این پکت از LAN به WAN خارج نمی‌شد؛ بعد از DNAT از `ether2` به `ether2` می‌رفت. قانون `FORWARD - drop unsolicited WAN` نیز شرط ورودی WAN داشت، پس برای این پکت LAN قانون مجازکننده نبود. در نهایت پکت به Rule نهایی Drop می‌رسید.

در RouterOS، Filter Rules به ترتیب از بالا به پایین ارزیابی می‌شوند؛ اولین قانونِ منطبق روی پکت تصمیم می‌گیرد و دیگر قوانین همان زنجیره بررسی نمی‌شوند. پس Rule نهایی Drop باید فعال بماند، اما ترافیک مجاز باید پیش از رسیدن به آن Rule اجازهٔ عبور بگیرد.

## 5. راه‌حل تأییدشده: اجازهٔ محدود برای Hairpin DNAT از LAN

در کنار Rule موجود برای DNAT از WAN، یک Rule جدا اضافه شد تا اتصال DNAT‌شده‌ای را قبول کند که از LAN وارد می‌شود.

### فرمان پیشنهادی با محدودکردن مقصد به Node

ابتدا مطمئن شوید Rule مشابهی از قبل وجود ندارد. سپس در RouterOS Terminal اجرا کنید:

```routeros
/ip firewall filter add \
    chain=forward \
    action=accept \
    connection-state=new \
    connection-nat-state=dstnat \
    in-interface-list=LAN \
    dst-address=192.168.2.3 \
    comment="FORWARD - allow hairpin dstnat" \
    place-before=[find where comment="FORWARD - drop everything else"]
```

اگر RouterOS/Terminal شما اجرای فرمان چندخطی را نپذیرفت، همین فرمان را یک‌خطی وارد کنید:

```routeros
/ip firewall filter add chain=forward action=accept connection-state=new connection-nat-state=dstnat in-interface-list=LAN dst-address=192.168.2.3 comment="FORWARD - allow hairpin dstnat" place-before=[find where comment="FORWARD - drop everything else"]
```

**چرا `dst-address=192.168.2.3`؟** در زنجیرهٔ `forward`، مقصدِ پکت پس از اعمال DNAT، آدرس Node است. محدودکردن مقصد باعث می‌شود این Rule فقط ترافیک Hairpin DNAT‌شده‌ای را بپذیرد که به Node موردنظر هدایت شده؛ نه هر DNAT به هر مقصدی.

اگر هنوز Rule را بدون محدودیت مقصد ساخته‌اید، می‌توانید آن را با این دستور محدود کنید:

```routeros
/ip firewall filter set [find where comment="FORWARD - allow hairpin dstnat"] dst-address=192.168.2.3
```

### Rule نهایی Drop را خاموش نگه ندارید

پس از افزودن Rule مجازکننده، Rule نهایی Drop باید فعال باشد و Logging دائمی آن خاموش باشد:

```routeros
/ip firewall filter set [find where comment="FORWARD - drop everything else"] log=no log-prefix=""
/ip firewall filter enable [find where comment="FORWARD - drop everything else"]
```

اگر Comment در محیط دیگری متفاوت است، ابتدا با `/ip firewall filter print detail without-paging` قانون درست را پیدا کنید. از شمارهٔ ثابت Rule استفاده نکنید؛ شماره‌ها با اضافه یا حذف قانون تغییر می‌کنند.

## 6. روند عیب‌یابی قابل تکرار

### 6.1 قوانین و Interface List را مشاهده کنید

```routeros
/interface print detail
/interface list member print detail
/ip firewall filter print detail without-paging where chain=forward
/ip firewall filter print stats detail without-paging where chain=forward
/ip firewall nat print stats detail without-paging
```

در توپولوژی این سند، انتظار می‌رود `Bridge` عضو `WAN` و `ether2` عضو `LAN` باشد. این عضویت را از خروجی واقعی تأیید کنید.

### 6.2 فقط برای تشخیص، Rule نهایی Drop را موقتاً Log کنید

```routeros
/ip firewall filter set [find where comment="FORWARD - drop everything else"] log=yes log-prefix="FWD-DROP "
```

یک بار درخواست مشکل‌دار را تکرار کنید، سپس لاگ‌های مربوطه را بخوانید:

```routeros
/log print where message~"FWD-DROP"
```

پس از اتمام تشخیص، حتماً Logging را خاموش کنید و Rule Drop را فعال نگه دارید:

```routeros
/ip firewall filter set [find where comment="FORWARD - drop everything else"] log=no log-prefix=""
/ip firewall filter enable [find where comment="FORWARD - drop everything else"]
```

Logging روی ترافیک پرتعداد می‌تواند حجم لاگ را زیاد کند؛ آن را برای عیب‌یابی کوتاه‌مدت استفاده کنید، نه به‌طور دائمی.

### 6.3 نتیجه را از روی لاگ تعیین کنید

- `in:ether2 out:ether2` و `connection-state=new,dnat`: مسیر LAN-to-public-IP با Hairpin DNAT را بررسی کنید.
- `in:Bridge out:ether2` و `connection-nat-state=dstnat`: ترافیک ورودی WAN است؛ باید Rule مجازکنندهٔ DNAT از WAN و Rule NAT متناظر با رابط ورودی WAN آن را پوشش دهند.
- اگر پکت در WAN دیده نمی‌شود و Counter NAT نیز افزایش نمی‌یابد، مشکل پیش از Filter داخلی است یا Rule NAT با شرایط پکت مطابقت ندارد؛ وضعیت مودم/DMZ، IP عمومی، رابط ورودی، پروتکل و پورت را بررسی کنید.
- اگر پکت به LAN می‌رسد ولی سرویس پاسخ نمی‌دهد، Listener برنامه، فایروال خود سیستم‌عامل و مسیر پاسخ را جداگانه بررسی کنید.

## 7. نکتهٔ بسیار مهم دربارهٔ `in-interface` در NAT

`in-interface` **رابط ورود پکت به MikroTik** را نشان می‌دهد؛ رابط خروجی/مقصد نیست.

- برای پکت واقعاً ورودی از اینترنت در سناریوی مودم Router Mode، رابط ورودی معمولاً `Bridge` است؛ به شرط آنکه همین رابط واقعاً به مودم وصل باشد.
- برای درخواست داخلی که از LAN به IP عمومی خودتان می‌رود، رابط ورودی `ether2` است.
- `to-addresses=192.168.2.3` آدرس مقصد بعد از DNAT را تعیین می‌کند و `out-interface` را به معنی رابط ورودی تنظیم نمی‌کند.

بنابراین یک قانون DNAT که شرط `in-interface=ether2` دارد، برای پکت‌هایی که از `ether2` وارد می‌شوند (مانند مسیر Hairpin مورد مشاهده) تطبیق می‌یابد؛ اما به‌تنهایی اثبات نمی‌کند Port Forward ورودی از اینترنت درست تنظیم شده است. برعکس، تغییر همان Rule به `in-interface=Bridge` ممکن است تست داخلی Hairpin را که از `ether2` وارد می‌شود از تطبیق خارج کند.

اگر سرویس باید هم از اینترنت خارجی و هم از داخل شبکه با IP عمومی/دامنه قابل‌دسترسی باشد، دو مسیر را جدا طراحی و تست کنید:
1. **WAN DNAT:** قانون با رابط ورودی WAN (در این معماری `Bridge`) و مقصد Node.
2. **LAN Hairpin DNAT:** قانون محدودشده برای درخواست‌های داخلی به IP عمومی/نام عمومی موردنظر، به همراه Rule مجازکنندهٔ Hairpin در `forward`.

از ایجاد Rule بسیار گسترده‌ای که همهٔ درخواست‌های LAN به یک پورت را بدون بررسی آدرس مقصد DNAT می‌کند، خودداری کنید. اگر قانون Hairpin فقط با `in-interface=ether2` و `dst-port=80/443` محدود شود، ممکن است ترافیک LAN به مقاصد دیگری که روی همان پورت هستند هم ناخواسته به Node هدایت شود. در صورت امکان، مقصد عمومی را دقیقاً مشخص کنید یا از Split DNS استفاده کنید.

## 8. نکته دربارهٔ Hairpin Source NAT

Hairpin NAT در بعضی توپولوژی‌ها علاوه بر DNAT به یک قانون Source NAT برای مسیر Hairpin نیاز دارد تا پاسخ سرور حتماً از مسیر روتر برگردد. در اجرای عیب‌یابی‌شده، یک قانون عمومی `srcnat action=masquerade` بدون شرط محدودکننده وجود داشت و در نتیجه ممکن بود ترافیک Hairpin را هم پوشش دهد. این راه‌حلِ فعلی را هنگام اصلاح Filter تغییر ندادیم تا علت اصلی با چند تغییر هم‌زمان مخلوط نشود.

با این حال، یک Masquerade بدون محدودکردن رابط خروجی/محدودهٔ شبکه می‌تواند گسترده‌تر از لازم باشد. پیش از محدودکردن آن، تمام جریان‌های موردنیاز را بررسی کنید و برای Hairpin و خروجی LAN قوانین مشخص و آزموده‌شده طراحی کنید. در RouterOS، تغییر NAT ممکن است به‌علت Connection Tracking روی اتصال‌های موجود فوراً اثر نگذارد؛ در زمان عیب‌یابی از پاک‌کردن کورکورانهٔ همهٔ Connectionها خودداری کنید.

## 9. مودم، DMZ و PPPoE — زمینهٔ تصمیم معماری

برای جداکردن مشکل NAT از PPPoE، مودم موقتاً در Router Mode قرار گرفت و Port Forward تا MikroTik آزمایش شد. معماری بررسی‌شده امکان نگه‌داشتن Wi-Fi مودم را بدون وابسته‌کردن آن به Windows Hotspot می‌دهد:

- مودم اینترنت را دریافت می‌کند و Wi-Fi خودش را ارائه می‌دهد.
- DMZ مودم به IP سمت مودمِ MikroTik اشاره می‌کند؛ ترجیحاً برای آن IP ثابت یا DHCP Reservation تنظیم شود.
- MikroTik ترافیک ورودی‌ای را که مودم به آن می‌فرستد، با Firewall و DNAT خودش کنترل می‌کند.
- Node روی LAN/Host-Only با آدرس `192.168.2.3` قرار دارد.

**DMZ مودم کل شبکهٔ خانه را خودکار پشت MikroTik نمی‌برد.** فقط ترافیکی را که مودم به آدرس WAN میکروتیک تحویل می‌دهد به آن سمت هدایت می‌کند. کلاینت‌های متصل مستقیم به Wi-Fi مودم همچنان معمولاً از مسیر خود مودم خارج می‌شوند، نه از فایروال MikroTik.

اگر بعداً PPPoE مستقیماً روی MikroTik برقرار شد، رابط ورودی اینترنت ممکن است `pppoe-out1` باشد؛ آن را با معماری Router Mode + DMZ که در این Runbook توضیح داده شد اشتباه نگیرید. در هر دو حالت، رابط واقعی ورودی باید از وضعیت رابط و Sniffer تأیید شود. تا وقتی مسیر شبکه روشن نشده، هم‌زمان DHCP Client و PPPoE Client را بدون تصمیم مشخص روی یک رابط به‌عنوان دو Default Route هم‌اولویت نگه ندارید.

## 10. پورت‌های Pterodactyl و ملاحظات امنیتی

در نمونهٔ مشاهده‌شده، قوانین NAT برای این سرویس‌ها وجود داشتند:

- TCP 80 و 443 برای HTTP/HTTPS، در صورتی که این سرویس‌ها قرار است از اینترنت ارائه شوند.
- TCP 8080 برای Wings API در پیکربندی پیش‌فرض متداول؛ مقدار واقعی Node را بررسی کنید.
- TCP 2022 برای SFTP مربوط به Wings، اگر دسترسی خارجی به آن لازم باشد.
- UDP allocationهای CS2 طبق پورت‌هایی که واقعاً در Pterodactyl برای سرورها تعریف شده‌اند.

این فهرست به معنی توصیه به بازکردن بی‌قیدوشرط همهٔ پورت‌ها نیست. پورت‌هایی را از اینترنت در دسترس قرار دهید که سرویس واقعی، کاربرد و کنترل دسترسی آن‌ها مشخص است. SSH، دیتابیس، Redis، Winbox و API مدیریتی MikroTik را صرفاً برای درست‌شدن Port Forward عمومی نکنید.

## 11. چک‌لیست پذیرش نهایی

- [ ] رابط‌ها و Interface List با `/interface list member print detail` تأیید شده‌اند.
- [ ] Rule `FORWARD - allow dstnat` برای اتصال‌های DNAT‌شده از WAN حفظ شده است.
- [ ] Rule `FORWARD - allow hairpin dstnat` پیش از `FORWARD - drop everything else` قرار دارد و به مقصد Node محدود شده است.
- [ ] Rule نهایی Drop **فعال** است و Logging دائمی آن خاموش است.
- [ ] دسترسی داخلی با دامنه/IP عمومی تست شده و Log دیگر `FWD-DROP` برای این پکت‌ها ثبت نمی‌کند.
- [ ] دسترسی واقعی از اینترنت با یک شبکهٔ خارج از LAN (مثلاً دیتای موبایل) به‌صورت جداگانه تست شده است.
- [ ] اگر دسترسی داخلی و خارجی هر دو لازم‌اند، برای WAN DNAT و LAN Hairpin DNAT Ruleهای جدا و متناسب با رابط ورود تعریف شده‌اند.
- [ ] پورت‌های عمومی فقط برای سرویس‌های لازم باز هستند.

## منابع رسمی

- MikroTik RouterOS — NAT و Hairpin NAT: https://help.mikrotik.com/docs/spaces/ROS/pages/3211299/NAT
- MikroTik RouterOS — Filter: https://help.mikrotik.com/docs/spaces/ROS/pages/48660608/Filter
