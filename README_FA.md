# 🎯 PowerPinger - اسکنر شبکه برای محیط‌های محدود

<div dir="rtl">

## 🌍 زبان‌ها
[کوردی](README_KU.md) | [**فارسی**](README_FA.md) | [English](README.md)

## 📚 لینک‌های سریع
- 📖 [شروع سریع](docs/QUICKSTART.md) - راه‌اندازی 5 دقیقه‌ای
- 🚀 [ویژگی‌های پیشرفته](docs/ENHANCED_FEATURES.md) - فقط انگلیسی
- 📋 [تغییرات](docs/CHANGELOG.md) - تاریخچه نسخه‌ها

---

## 🎯 خلاصه

PowerPinger سرورها و خدمات قابل دسترس را در محیط‌های شبکه محدود پیدا می‌کند. محدوده‌های IP را اسکن می‌کند تا میزبان‌های در دسترس و پورت‌های باز را کشف کند.

**ویژگی‌های کلیدی:**
- ✅ **بدون نصب** - از PowerShell داخلی Windows استفاده می‌کند
- 📦 **فوق‌العاده قابل حمل** - ~15KB زیپ شده (قابل ایمیل)
- 🌐 **پشتیبانی کامل IPv4/IPv6** - مدیریت هوشمند محدوده
- ⚡ **چند حالت اسکن** - ping/port/both/parallel
- 🛡️ **بررسی شبکه قبل از اسکن** - اعتبارسنجی اتصال
- 🎯 **محدودیت نرخ هوشمند** - جلوگیری از شناسایی DDoS
- 📊 **خروجی CSV** - نتایج ساختاریافته

## ⚠️ هشدارهای مهم

**قانونی و امنیتی:**
- فقط شبکه‌هایی را اسکن کنید که مالک آن هستید یا مجوز دارید
- مدیران شبکه می‌توانند فعالیت اسکن شما را رصد کنند
- به قوانین محلی و سیاست‌های شبکه احترام بگذارید
- اسکن شبکه‌های تولید (Cloudflare، AWS) ممکن است IP شما را مسدود کند

## 📦 شروع سریع

### برای شبکه‌های محدود (پیشنهادی)
1. 2 فایل دانلود کنید: `powerPinger.ps1` + `ip_list.csv`
2. از طریق USB/ایمیل انتقال دهید (< 15KB زیپ)
3. استخراج و اجرا:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\powerPinger.ps1
```

### از مخزن Git
```bash
git clone https://github.com/vafagh/PowerPinger.git
cd PowerPinger
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\powerPinger.ps1
```

## 🎮 مثال‌های استفاده

```powershell
# حالت تعاملی
.\powerPinger.ps1

# اسکن پایه
.\powerPinger.ps1 -InputFile "targets.csv" -OutputFile "results.csv"

# اسکن پیشرفته با تشخیص پورت
.\powerPinger.ps1 -ScanMode "both" -Ports "80,443,22" -MaxResponses 10

# حالت موازی برای سرعت
.\powerPinger.ps1 -ScanMode "parallel" -Timeout 1000
```

## 🛠️ ابزارهای توسعه

**Minifier** - کاهش اندازه اسکریپت:
```powershell
.\Minifier.ps1
# ایجاد powerPinger_min.ps1 (~23% کوچکتر)
# ایجاد powerPinger.zip (~85% فشرده‌سازی)
```

## 📊 پارامترها

| پارامتر | توضیحات | پیش‌فرض |
|---------|---------|---------|
| `-InputFile` | فایل ورودی CSV/TXT | ip_list.csv |
| `-OutputFile` | فایل خروجی CSV | ping_results.csv |
| `-Timeout` | تایم‌اوت پینگ (ms) | 1500 |
| `-MaxFailures` | شکست قبل از پرش | 4 |
| `-Jump` | IPهای پرش | 16 |
| `-Skip` | پرش قبل از حذف محدوده | 3 |
| `-ScanMode` | ping/port/both/parallel | ping |
| `-Ports` | پورت‌های اسکن | 80,443,22,53 |
| `-MaxResponses` | محدودیت هر محدوده | 0 (نامحدود) |

## 📝 فرمت فایل ورودی

**CSV:**
```csv
IP,Location,Region,City,PostalCode
192.168.1.0/24,Office,US,NYC,10001
8.8.8.8,Google DNS,US,Mountain View,94043
2001:4860:4860::8888,Google DNS IPv6,US,,
```

**TXT:**
```
192.168.1.0/24
10.0.0.0/16
8.8.8.8
```

## ⚖️ مجوز و سلب مسئولیت

**مجوز MIT** - [LICENSE](docs/LICENSE) را ببینید

**استفاده با مسئولیت خودتان.** فقط شبکه‌هایی را اسکن کنید که مالک آن هستید یا مجوز دارید. نویسنده مسئولیتی برای سوء استفاده یا خسارت ندارد.

---

ساخته شده برای محیط‌های شبکه محدود 🌐

</div>
