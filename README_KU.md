# 🎯 PowerPinger - سکانەری تۆڕ بۆ ژینگەی سنووردار

<div dir="rtl">

## 🌍 زمانەکان
[**کوردی**](README_KU.md) | [فارسی](README_FA.md) | [English](README.md)

## 📚 لینکە خێراکان
- 📖 [دەستپێکردنی خێرا](docs/QUICKSTART.md) - دامەزراندنی 5 خولەکی
- 🚀 [تایبەتمەندییە پێشکەوتووەکان](docs/ENHANCED_FEATURES.md) - تەنها ئینگلیزی
- 📋 [گۆڕانکارییەکان](docs/CHANGELOG.md) - مێژووی وەشانەکان

---

## 🎯 پوختە

PowerPinger سێرڤەر و خزمەتگوزارییە دەستڕاگەیشتووەکان دەدۆزێتەوە لە ژینگەی تۆڕی سنووردار. مەودای IP سکان دەکات بۆ دۆزینەوەی میوانە دەستڕاگەیشتووەکان و پۆرتە کراوەکان.

**تایبەتمەندییە سەرەکییەکان:**
- ✅ **دامەزراندنی سفر** - PowerShell ی ناوخۆیی Windows بەکاردێنێت
- 📦 **زۆر گواستراوە** - ~15KB زیپ کراوە (بۆ ئیمەیڵ گونجاوە)
- 🌐 **پشتگیری تەواوی IPv4/IPv6** - بەڕێوەبردنی زیرەکانەی مەودا
- ⚡ **چەند دۆخی سکان** - ping/port/both/parallel
- 🛡️ **پشکنینی تۆڕ پێش سکان** - پشتڕاستکردنەوەی پەیوەندی
- 🎯 **سنووردانانی ڕێژەی زیرەک** - ڕێگری لە ناسینەوەی DDoS
- 📊 **دەرچوونی CSV** - ئەنجامە ساختارکراوەکان

## ⚠️ ئاگادارییە گرنگەکان

**یاسایی و ئاسایشی:**
- تەنها ئەو تۆڕانە سکان بکە کە خاوەنی یان مۆڵەتت هەیە
- بەڕێوەبەرانی تۆڕ دەتوانن چالاکی سکانەکەت بچاودێری بکەن
- ڕێزی یاساکان و سیاسەتەکانی تۆڕ بگرە
- سکانکردنی تۆڕەکانی بەرهەمهێنان (Cloudflare، AWS) لەوانەیە IP ەکەت بلۆک بکات

## 📦 دەستپێکردنی خێرا

### بۆ تۆڕە سنووردارەکان (پێشنیارکراو)
1. 2 فایل دابەزێنە: `powerPinger.ps1` + `ip_list.csv`
2. لە ڕێگەی USB/ئیمەیڵ بگوێزەوە (< 15KB زیپ)
3. دەری بهێنە و ڕایبکە:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\powerPinger.ps1
```

### لە کۆگای Git
```bash
git clone https://github.com/vafagh/PowerPinger.git
cd PowerPinger
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\powerPinger.ps1
```

## 🎮 نموونەی بەکارهێنان

```powershell
# دۆخی کارلێککردن
.\powerPinger.ps1

# سکانی بنەڕەتی
.\powerPinger.ps1 -InputFile "targets.csv" -OutputFile "results.csv"

# سکانی پێشکەوتوو لەگەڵ ناسینەوەی پۆرت
.\powerPinger.ps1 -ScanMode "both" -Ports "80,443,22" -MaxResponses 10

# دۆخی هاوتەریب بۆ خێرایی
.\powerPinger.ps1 -ScanMode "parallel" -Timeout 1000
```

## 🛠️ ئامرازەکانی گەشەپێدان

**Minifier** - کەمکردنەوەی قەبارەی سکریپت:
```powershell
.\Minifier.ps1
# دروستکردنی powerPinger_min.ps1 (~23% بچووکتر)
# دروستکردنی powerPinger.zip (~85% پەستاوکردن)
```

## 📊 پارامێتەرەکان

| پارامێتەر | وەسف | بنەڕەت |
|-----------|------|--------|
| `-InputFile` | فایلی هاتوو CSV/TXT | ip_list.csv |
| `-OutputFile` | فایلی دەرچوو CSV | ping_results.csv |
| `-Timeout` | کات بەسەرچوونی پینگ (ms) | 1500 |
| `-MaxFailures` | شکستەکان پێش بازدان | 4 |
| `-Jump` | IPەکانی بازدان | 16 |
| `-Skip` | بازەکان پێش لابردنی مەودا | 3 |
| `-ScanMode` | ping/port/both/parallel | ping |
| `-Ports` | پۆرتەکانی سکان | 80,443,22,53 |
| `-MaxResponses` | سنوور بۆ هەر مەودا | 0 (بێسنوور) |

## 📝 شێوازی فایلی هاتوو

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

## ⚖️ مۆڵەت و لابردنی بەرپرسیارێتی

**مۆڵەتی MIT** - [LICENSE](docs/LICENSE) ببینە

**بەکارهێنان بە بەرپرسیارێتی خۆت.** تەنها ئەو تۆڕانە سکان بکە کە خاوەنی یان مۆڵەتت هەیە. نووسەر بەرپرسیارێتی هیچ نییە بۆ بەکارهێنانی هەڵە یان زیان.

---

دروستکراوە بۆ ژینگەی تۆڕی سنووردار 🌐

</div>
