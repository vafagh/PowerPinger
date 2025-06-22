# 🚀 ڕێنمایی خێرای PowerPinger

[**کوردی**](QUICKSTART_KU.md) | [فارسی](QUICKSTART_FA.md) | [English](QUICKSTART.md)

## دەستپێکردن لە 5 خولەکدا

### 1. پشکنینی یەکەم
```powershell
.\powerPinger.ps1
```
ئەمە فایلی `ip_list.csv` دەخوێنێتەوە و ping دەکات.

### 2. پشکنینی زیرەک
```powershell
.\powerPinger.ps1 -ScanMode "smart" -Ports "80,443"
```
هەم ping و هەم پۆرتەکان پشکنین دەکات و فیلتەرکردن دەناسێتەوە.

### 3. ئامادەکردنی داتا
فایلێک دروست بکە بە ناوی `my_targets.csv`:
```csv
IP,Location,Region,City,PostalCode
8.8.8.8,Google DNS,US,Mountain View,94035
1.1.1.1,Cloudflare DNS,US,San Francisco,94107
```

### 4. پشکنینی ئامانجەکانت
```powershell
.\powerPinger.ps1 -InputFile "my_targets.csv" -ScanMode "smart"
```

## 📊 تێگەیشتن لە دەرئەنجامەکان

### دۆخی "smart" 
```
IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Filtering Detected
8.8.8.8,Google DNS,Success,15,53;443,Accessible,No
```

### واتای فیلتەرکردن
| دۆخ | مانا |
|-----|------|
| **No** | کێشە نییە - هەمووشت کار دەکات |
| **ICMP-Blocked** | ping ڕێگری لێکراوە بەڵام خزمەتگوزارییەکان کار دەکەن |
| **Service-Blocked** | ping کار دەکات بەڵام خزمەتگوزارییەکان ڕێگری لێکراون |
| **Likely-Filtered** | ئەگەری فیلتەرکردن هەیە |

## 🔧 ڕێکخستنە خێراکان

### کاتی چاوەڕوان زیاد بکە
```powershell
.\powerPinger.ps1 -Timeout 3000 -PortTimeout 5000
```

### پۆرتە تایبەتەکان
```powershell
.\powerPinger.ps1 -Ports "80,443,8080"
```

### بۆ تۆڕە گەورەکان
```powershell
.\powerPinger.ps1 -MaxFailures 3 -Jump 10
```

## 💡 ئامۆژگاری

- **بۆ تۆڕە هێواشەکان**: `-Timeout 5000` بەکاربهێنە
- **بۆ پشکنینی زۆر**: دۆخی `smart` بەکاربهێنە  
- **بۆ پۆرتی تایبەت**: لیستی پۆرتەکانت دیاری بکە
- **بۆ ئەنجامی خێرا**: دۆخی `ping` بەکاربهێنە

## 🎯 ئامانجەکانی باو

### بۆ شیکردنەوەی تۆڕ
```powershell
.\powerPinger.ps1 -ScanMode "smart" -Ports "80,443,22,53,8080"
```

### بۆ پشکنینی ڕاژەکار
```powershell
.\powerPinger.ps1 -ScanMode "port" -Ports "80,443,3389,22"
```

### بۆ پشکنینی ساکار
```powershell
.\powerPinger.ps1 -ScanMode "ping" -Timeout 1000
```
