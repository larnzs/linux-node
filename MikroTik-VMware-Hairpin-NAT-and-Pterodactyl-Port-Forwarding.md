# MikroTik در VMware: عیب‌یابی Hairpin NAT و اصلاح Firewall برای Pterodactyl

> **هدف این راهنما:** مستندسازی دو خطای مرتبط با NAT در RouterOS 7.24.4 داخل VMware: (۱) Drop شدن Hairpin DNAT در Firewall Filter؛ و (۲) گسترده‌بودن Ruleهای Hairpin، به‌طوری که HTTPS خروجی به مقصدهای خارجی مثل Steam/Google به‌جای آن‌ها به پنل FragCity هدایت می‌شد. راه‌حل‌ها به‌ترتیب، افزودن Rule مجازکنندهٔ LAN Hairpin و محدودکردن Ruleهای Hairpin به IP عمومی خودمان هستند؛ فایروال نباید برای رفع این خطاها خاموش بماند.
>
> این Runbook بر پایهٔ عیب‌یابی RouterOS 7.24.4 در محیط VMware نوشته شده است. IPهای خصوصی و رابط‌های زیر مقادیر محیط مرجع‌اند؛ در شبکهٔ دیگر ابتدا توپولوژی واقعی را بررسی کنید. IP عمومی واقعی در لاگ اصلی از مستند حذف شده و در دستور نمونه با آدرس مستندی `203.0.113.10` جایگزین شده است. **این آدرس نمونه را اجرا نکنید؛ قبل از اجرا با IPv4 عمومی واقعی خودتان عوض کنید.** MACهای حاضر در لاگ اصلی نیز بازنشر نشده‌اند.

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

## 5. راه‌حل تأییدشده: اجازهٔ Hairpin DNAT از LAN

در کنار Rule موجود برای DNAT از WAN، یک Rule جدا اضافه شد تا اتصال DNAT‌شده‌ای را قبول کند که از LAN وارد می‌شود. **این همان تغییر Firewall بود که دسترسی را برگرداند**؛ Rule نهایی Drop لازم نبود خاموش بماند.

ابتدا مطمئن شوید Rule مشابهی از قبل وجود ندارد. سپس در RouterOS Terminal اجرا کنید:

```routeros
/ip firewall filter add \
    chain=forward \
    action=accept \
    connection-state=new \
    connection-nat-state=dstnat \
    in-interface-list=LAN \
    comment="FORWARD - allow hairpin dstnat" \
    place-before=[find where comment="FORWARD - drop everything else"]
```

اگر Terminal اجرای فرمان چندخطی را نپذیرفت، از نسخهٔ یک‌خطی استفاده کنید:

```routeros
/ip firewall filter add chain=forward action=accept connection-state=new connection-nat-state=dstnat in-interface-list=LAN comment="FORWARD - allow hairpin dstnat" place-before=[find where comment="FORWARD - drop everything else"]
```

این Rule از روی سه شرط تصمیم می‌گیرد: اتصال جدید باشد، Connection Tracking آن را DNAT‌شده تشخیص دهد و پکت از Interface List به نام `LAN` وارد شده باشد. این موضوع با لاگ `in:ether2 out:ether2` مطابقت داشت، چون `ether2` عضو `LAN` بود.

### محدودسازی اختیاری به مقصد Node

برای کاهش دامنهٔ Rule می‌توان شرط مقصد را نیز به Node فعلی محدود کرد. در `forward`, آدرس مقصد پس از DNAT برابر `192.168.2.3` است. **این محدودسازی یک Hardening اضافی است؛ تغییر تأییدشدهٔ اولیه همان Rule بدون شرط مقصد بود.** پیش از انجام آن، تأیید کنید همهٔ سرویس‌هایی که این Rule باید اجازه دهد به همین IP هدایت می‌شوند؛ سپس:

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

## 9. حادثهٔ دوم: Hairpin DNAT بیش‌ازحد گسترده، خطای TLS و خرابی Steam SDR

پس از اصلاح Firewall Filter، مشکل دیگری مشاهده شد: هنگام استفاده از اینترنت از مسیری که از MikroTik می‌گذشت، Firefox برای `www.google.com` خطای `MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE` می‌داد و CS2 روی Debian خطاهای SDR/Auth نشان می‌داد. اتصال مستقیم به Wi-Fi مودم سالم بود.

### 9.1 شواهدی که علت را مشخص کردند

در Debian Node، نام `api.steampowered.com` به IPهای خارجی `2.19.193.x` resolve شد. اما تست زیر:

```bash
curl -v --connect-timeout 10 \
  'https://api.steampowered.com/ISteamApps/GetSDRConfig/v1/?appid=730' \
  -o /tmp/cs2-sdr-config.json
```

این خطا را نشان داد:

```text
Server certificate:
subject: CN=panel.fragcity.ir
subjectAltName does not match hostname api.steampowered.com
curl: (60) SSL: no alternative certificate subject name matches target hostname 'api.steampowered.com'
```

این مدرک نشان داد اتصال TLS به‌جای دریافت گواهی معتبر برای Steam، به HTTPS سرویس FragCity روی Node رسیده است. این مشکل با غیرفعال‌کردن بررسی گواهی یا نصب گواهی ناشناس نباید دور زده شود.

### 9.2 علت: NAT Rule فقط پورت و رابط را بررسی می‌کرد

Ruleهای Hairpin موجود شرایطی شبیه این داشتند:

```routeros
chain=dstnat
action=dst-nat
protocol=tcp
in-interface=ether2
dst-port=443
to-addresses=192.168.2.3
to-ports=443
```

قانون پورت 80/443 و قانون UDP بازی هم روی پورت/محدودهٔ پورت Match می‌کردند و مقصد اولیهٔ عمومی را محدود نکرده بودند. چون `ether2` رابط LAN/Host-Only است، ترافیک خروجی کلاینت یا Debian نیز ابتدا از همین رابط **وارد** MikroTik می‌شود. بنابراین Ruleهایی با `in-interface=ether2` و `dst-port=443`، حتی اتصال LAN به سرور خارجی مثل `api.steampowered.com:443` را هم Match می‌کردند و مقصدش را به `192.168.2.3:443` تغییر می‌دادند.

همین رفتار می‌تواند باعث شود:
- Firefox به‌جای Google گواهی `panel.fragcity.ir` دریافت کند.
- `curl` به Steam با TLS hostname mismatch شکست بخورد.
- ارتباط‌های خروجی دیگر که پورتشان در Ruleهای گستردهٔ Hairpin قرار دارد، از جمله برخی UDPها، به Node برگردانده شوند و قابلیت‌هایی مانند Steam SDR از کار بیفتند.

**نکتهٔ اصلی:** `in-interface=ether2` به‌تنهایی قانون را به دسترسی داخلی به سرویس عمومی خودمان محدود نمی‌کند. باید مقصد اصلی پکت هم Match شود.

### 9.3 Fix تأییدشده: Address List برای IP عمومی خودمان

در این محیط، IP عمومی‌ای که برای دسترسی به FragCity استفاده می‌شد از لاگ اتصال استخراج شده بود. پیش از اجرا، آدرس فعلی را از وضعیت مودم/ISP یا تست معتبر IP عمومی تأیید کنید. نمونهٔ زیر از مقدار ثبت‌شده در محیط عیب‌یابی استفاده می‌کند؛ آن را کورکورانه در شبکهٔ دیگر کپی نکنید.

ابتدا از تنظیمات نسخهٔ پشتیبان بگیرید:

```routeros
/export file=before-nat-scope-fix
```

سپس Address List مخصوص مقصد عمومی خود بسازید (فقط یک بار):

```routeros
/ip firewall address-list add list=FRAGCITY_HAIRPIN_PUBLIC address=203.0.113.10 comment="Public IP used for FragCity services"
```

اگر لیست با همین نام و آدرس از قبل وجود دارد، Entry تکراری ایجاد نکنید؛ آن را با `/ip firewall address-list print detail where list=FRAGCITY_HAIRPIN_PUBLIC` بررسی کنید.

اکنون در هر Rule مخصوص Hairpin، مقصد اصلی را هم به همین Address List محدود کنید. در محیط عیب‌یابی Commentها دقیقاً این‌ها بودند:

```routeros
/ip firewall nat set [find where comment="29000 > 192.168.2.3"] dst-address-list=FRAGCITY_HAIRPIN_PUBLIC
/ip firewall nat set [find where comment="80 > 192.168.2.3"] dst-address-list=FRAGCITY_HAIRPIN_PUBLIC
/ip firewall nat set [find where comment="443 > 192.168.2.3"] dst-address-list=FRAGCITY_HAIRPIN_PUBLIC
/ip firewall nat set [find where comment="8080 > 192.168.2.3"] dst-address-list=FRAGCITY_HAIRPIN_PUBLIC
/ip firewall nat set [find where comment="2022 > 192.168.2.3"] dst-address-list=FRAGCITY_HAIRPIN_PUBLIC
```

در نتیجه، Ruleهای LAN Hairpin فقط زمانی Match می‌شوند که پکت از `ether2` وارد شود **و مقصد اصلی‌اش IP عمومی ثبت‌شده برای FragCity باشد**. اتصال به IPهای واقعی Google، Steam یا دیگر مقصدهای خارجی دیگر صرفاً به‌دلیل داشتن مقصد TCP/443 یا پورت UDP داخل محدودهٔ بازی به Node ترجمه نمی‌شود.

> اگر IP عمومی عوض شود، باید Entry در `FRAGCITY_HAIRPIN_PUBLIC` را با IP فعلی جایگزین کنید. در معماری مودم Router Mode + DMZ، آدرس IP خصوصی سمت WAN روتر با IP عمومی‌ای که کلاینت‌ها به آن وصل می‌شوند یکسان نیست؛ بنابراین آدرس عمومی درست را جداگانه تأیید کنید.

پس از تغییر، Ruleها را بررسی کنید:

```routeros
/ip firewall nat print detail without-paging
/ip firewall address-list print detail where list=FRAGCITY_HAIRPIN_PUBLIC
```

### 9.4 معیار تست موفق

از Debian میزبان اجرا کنید:

```bash
curl -v --connect-timeout 10 \
  'https://api.steampowered.com/ISteamApps/GetSDRConfig/v1/?appid=730' \
  -o /tmp/cs2-sdr-config.json
```

معیار قبولی:
- اتصال HTTPS با اعتبارسنجی عادی گواهی کامل شود (بدون `curl: (60)`).
- گواهی دریافت‌شده برای `api.steampowered.com` معتبر باشد؛ نباید `CN=panel.fragcity.ir` یا نام سرویس FragCity را به‌عنوان پاسخ درخواست Steam ببینیم.
- وب‌سایت‌ها از مسیر MikroTik باز شوند.
- پس از Restart سرور CS2 برای اجرای تلاش جدید، خطاهای SDR/Auth مجدداً بررسی شوند. Fix کردن DNAT بیش‌ازحد گسترده علت TLS را برطرف کرد، اما اگر پیام `Bad cert: CA key ... is not known to us` پس از آن باقی بماند، باید به‌عنوان مسئلهٔ جداگانهٔ Steam Networking بررسی شود، نه اینکه خودکار آن را حل‌شده فرض کنیم.

**به‌روزرسانی امنیتی:** گواهی TLS را غیرفعال اعتبارسنجی نکنید، `curl -k` را راه‌حل ندانید و Firewall/NAT را برای دورزدن هشدارهای مرورگر خاموش نکنید. اگر یک مقصد HTTPS گواهی متعلق به سرویس دیگری می‌دهد، ابتدا با بررسی مسیر NAT و Proxy علت را پیدا کنید.

## 10. مودم، DMZ و PPPoE — زمینهٔ تصمیم معماری

برای جداکردن مشکل NAT از PPPoE، مودم موقتاً در Router Mode قرار گرفت و Port Forward تا MikroTik آزمایش شد. معماری بررسی‌شده امکان نگه‌داشتن Wi-Fi مودم را بدون وابسته‌کردن آن به Windows Hotspot می‌دهد:

- مودم اینترنت را دریافت می‌کند و Wi-Fi خودش را ارائه می‌دهد.
- DMZ مودم به IP سمت مودمِ MikroTik اشاره می‌کند؛ ترجیحاً برای آن IP ثابت یا DHCP Reservation تنظیم شود.
- MikroTik ترافیک ورودی‌ای را که مودم به آن می‌فرستد، با Firewall و DNAT خودش کنترل می‌کند.
- Node روی LAN/Host-Only با آدرس `192.168.2.3` قرار دارد.

**DMZ مودم کل شبکهٔ خانه را خودکار پشت MikroTik نمی‌برد.** فقط ترافیکی را که مودم به آدرس WAN میکروتیک تحویل می‌دهد به آن سمت هدایت می‌کند. کلاینت‌های متصل مستقیم به Wi-Fi مودم همچنان معمولاً از مسیر خود مودم خارج می‌شوند، نه از فایروال MikroTik.

اگر بعداً PPPoE مستقیماً روی MikroTik برقرار شد، رابط ورودی اینترنت ممکن است `pppoe-out1` باشد؛ آن را با معماری Router Mode + DMZ که در این Runbook توضیح داده شد اشتباه نگیرید. در هر دو حالت، رابط واقعی ورودی باید از وضعیت رابط و Sniffer تأیید شود. تا وقتی مسیر شبکه روشن نشده، هم‌زمان DHCP Client و PPPoE Client را بدون تصمیم مشخص روی یک رابط به‌عنوان دو Default Route هم‌اولویت نگه ندارید.

## 11. پورت‌های Pterodactyl و ملاحظات امنیتی

در نمونهٔ مشاهده‌شده، قوانین NAT برای این سرویس‌ها وجود داشتند:

- TCP 80 و 443 برای HTTP/HTTPS، در صورتی که این سرویس‌ها قرار است از اینترنت ارائه شوند.
- TCP 8080 برای Wings API در پیکربندی پیش‌فرض متداول؛ مقدار واقعی Node را بررسی کنید.
- TCP 2022 برای SFTP مربوط به Wings، اگر دسترسی خارجی به آن لازم باشد.
- UDP allocationهای CS2 طبق پورت‌هایی که واقعاً در Pterodactyl برای سرورها تعریف شده‌اند.

این فهرست به معنی توصیه به بازکردن بی‌قیدوشرط همهٔ پورت‌ها نیست. پورت‌هایی را از اینترنت در دسترس قرار دهید که سرویس واقعی، کاربرد و کنترل دسترسی آن‌ها مشخص است. SSH، دیتابیس، Redis، Winbox و API مدیریتی MikroTik را صرفاً برای درست‌شدن Port Forward عمومی نکنید.

## 12. چک‌لیست پذیرش نهایی

- [ ] رابط‌ها و Interface List با `/interface list member print detail` تأیید شده‌اند.
- [ ] Rule `FORWARD - allow dstnat` برای اتصال‌های DNAT‌شده از WAN حفظ شده است.
- [ ] Rule `FORWARD - allow hairpin dstnat` پیش از `FORWARD - drop everything else` قرار دارد؛ محدودکردن `dst-address` به Node فقط پس از بازبینی ترافیک مجاز انجام شده است.
- [ ] Ruleهای LAN Hairpin در زنجیرهٔ `dstnat` با `dst-address-list=FRAGCITY_HAIRPIN_PUBLIC` به مقصد عمومی FragCity محدود شده‌اند.
- [ ] درخواست HTTPS خروجی به یک مقصد خارجی واقعی مثل Steam، گواهی همان hostname را می‌گیرد و ناخواسته به سرویس Panel هدایت نمی‌شود.
- [ ] Rule نهایی Drop **فعال** است و Logging دائمی آن خاموش است.
- [ ] دسترسی داخلی با دامنه/IP عمومی تست شده و Log دیگر `FWD-DROP` برای این پکت‌ها ثبت نمی‌کند.
- [ ] دسترسی واقعی از اینترنت با یک شبکهٔ خارج از LAN (مثلاً دیتای موبایل) به‌صورت جداگانه تست شده است.
- [ ] اگر دسترسی داخلی و خارجی هر دو لازم‌اند، برای WAN DNAT و LAN Hairpin DNAT Ruleهای جدا و متناسب با رابط ورود تعریف شده‌اند.
- [ ] پورت‌های عمومی فقط برای سرویس‌های لازم باز هستند.

## منابع رسمی

- MikroTik RouterOS — NAT و Hairpin NAT: https://help.mikrotik.com/docs/spaces/ROS/pages/3211299/NAT
- MikroTik RouterOS — Filter: https://help.mikrotik.com/docs/spaces/ROS/pages/48660608/Filter
