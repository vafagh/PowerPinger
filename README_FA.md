# 🎯 PowerPinger - ابزار تحلیل شبکه

[کوردی](README_KU.md) | [**فارسی**](README_FA.md) | [English](README.md)

ابزاری سبک و مستقل بر پایه PowerShell برای اسکن شبکه و تشخیص الگوهای فیلترینگ شبکه از طریق ping و port scanning هوشمند. **بدون نیاز به نصب نرم‌افزار اضافی روی Windows 10+ اجرا می‌شود** - مناسب برای استفاده در شبکه‌های محدود.

## 🌟 ویژگی‌های کلیدی

- 🛡️ **تشخیص فیلترینگ شبکه**: تحلیل پیشرفته برای شناسایی انواع مختلف محدودیت‌ها و مکانیزم‌های فیلترینگ
- 🚀 **بدون وابستگی**: هیچ نرم‌افزار اضافی لازم نیست - فقط PowerShell
- ⚡ **سریع و کارآمد**: ~1000 خط کد + لیست IP = مجموعه کامل تحلیل شبکه
- 🎯 **چندین حالت اسکن**: ping/port/both/smart
- 📊 **گزارش تفصیلی**: نتایج در فرمت CSV

## 🚀 شروع سریع

### پیش‌نیازها
- Windows 10 یا بالاتر
- PowerShell 5.1+ (به طور پیش‌فرض نصب شده)

### 1. دانلود
```bash
git clone https://github.com/vafagh/PowerPinger.git
cd PowerPinger
```

### 2. اولین اسکن
```powershell
# اسکن ساده
.\powerPinger.ps1

# اسکن هوشمند
.\powerPinger.ps1 -ScanMode "smart" -Ports "80,443,22,53"
```

## 📋 حالت‌های اسکن

- **`ping`** - فقط اسکن ping
- **`port`** - فقط اسکن port
- **`both`** - ping و port با هم
- **`smart`** - تشخیص هوشمند فیلترینگ شبکه

## 🛡️ تشخیص فیلترینگ شبکه

این ابزار می‌تواند این نوع فیلترها را شناسایی کند:

### مسدودیت ICMP
- **نشانه**: سرویس‌ها کار می‌کنند اما ping نه
- **رایج در**: شبکه‌های شرکتی، محیط‌های محدود

### مسدودیت سرویس
- **نشانه**: ping کار می‌کند اما سرویس‌ها نه
- **رایج در**: فیلترینگ پیشرفته، نظارت امنیتی

### بدون فیلترینگ
- **نشانه**: هم ping و هم سرویس‌ها کار می‌کنند

## 📁 فرمت فایل ورودی

### CSV برای IP های منفرد
```csv
IP,Location,Region,City,PostalCode
8.8.8.8,Google DNS,US,Mountain View,94035
1.1.1.1,Cloudflare DNS,US,San Francisco,94107
```

### TXT برای محدوده‌ها
```
192.168.1.0/24
10.0.0.0/16
172.16.0.0/12
```

## 🔧 پیکربندی

```powershell
# زمان انتظار
.\powerPinger.ps1 -Timeout 2000 -PortTimeout 5000

# پورت‌های خاص
.\powerPinger.ps1 -Ports "80,443,8080,8443"

# حالت پرش بعد از شکست
.\powerPinger.ps1 -MaxFailures 3 -Jump 5
```

## 📊 نمونه نتیجه

```csv
IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Filtering Detected
8.8.8.8,Google DNS,Success,15,53;443,Accessible,No
1.1.1.1,Cloudflare DNS,Success,12,53;443,Accessible,No
```

## 🔍 انواع تشخیص فیلترینگ

| وضعیت | توضیح |
|-------|-------|
| **No** | هم ping و هم پورت‌ها کار می‌کنند |
| **ICMP-Blocked** | سرویس‌ها کار می‌کنند، ping نه |
| **Service-Blocked** | ping کار می‌کند، سرویس‌ها رد می‌شوند |
| **Likely-Filtered** | الگوی مختلط، نیاز به بررسی بیشتر |
| **Unassigned-Range** | هیچ پاسخی نیست، احتمال IP تخصیص نیافته |

## 💡 نکات

### برای شبکه‌های محدود
- فقط فایل powerPinger.ps1 را کپی کنید
- هیچ نصبی لازم نیست
- از USB یا شبکه اجرا کنید

### برای تحلیل کارایی
- از حالت "smart" استفاده کنید
- زمان انتظار را برای شبکه‌های کند افزایش دهید
- حالت Jump را برای محدوده‌های بزرگ فعال کنید

## 🤝 مشارکت

برای مشارکت در توسعه این پروژه:

1. Fork کنید
2. شاخه جدید ایجاد کنید (`git checkout -b feature/amazing-feature`)
3. تغییراتتان را commit کنید (`git commit -m 'Add amazing feature'`)
4. شاخه را push کنید (`git push origin feature/amazing-feature`)
5. Pull Request ایجاد کنید

## 📄 مجوز

این پروژه تحت مجوز MIT منتشر شده است. برای اطلاعات بیشتر [LICENSE](LICENSE) را ببینید.

## 🔗 لینک‌های مفید

- [مستندات کامل](README.md)
- [راهنمای سریع](QUICKSTART.md)
- [تغییرات](CHANGELOG.md)
