# 🚀 راهنمای سریع PowerPinger

[کوردی](QUICKSTART_KU.md) | [**فارسی**](QUICKSTART_FA.md) | [English](QUICKSTART.md)

## شروع در 5 دقیقه

### 1. اولین اسکن
```powershell
.\powerPinger.ps1
```
این فایل `ip_list.csv` را می‌خواند و ping می‌کند.

### 2. اسکن هوشمند
```powershell
.\powerPinger.ps1 -ScanMode "smart" -Ports "80,443"
```
هم ping و هم پورت‌ها را اسکن می‌کند و فیلترینگ را تشخیص می‌دهد.

### 3. آماده‌سازی داده
فایلی با نام `my_targets.csv` ایجاد کنید:
```csv
IP,Location,Region,City,PostalCode
8.8.8.8,Google DNS,US,Mountain View,94035
1.1.1.1,Cloudflare DNS,US,San Francisco,94107
```

### 4. اسکن اهدافتان
```powershell
.\powerPinger.ps1 -InputFile "my_targets.csv" -ScanMode "smart"
```

## 📊 درک نتایج

### حالت "smart"
```
IP,Location,Ping Result,Ping Time (ms),Ports Open,Service Status,Filtering Detected
8.8.8.8,Google DNS,Success,15,53;443,Accessible,No
```

### معنی فیلترینگ
| وضعیت | معنی |
|-------|------|
| **No** | مشکلی نیست - همه چیز کار می‌کند |
| **ICMP-Blocked** | ping مسدود شده اما سرویس‌ها کار می‌کنند |
| **Service-Blocked** | ping کار می‌کند اما سرویس‌ها مسدودند |
| **Likely-Filtered** | احتمال فیلترینگ وجود دارد |

## 🔧 تنظیمات سریع

### افزایش زمان انتظار
```powershell
.\powerPinger.ps1 -Timeout 3000 -PortTimeout 5000
```

### پورت‌های خاص
```powershell
.\powerPinger.ps1 -Ports "80,443,8080"
```

### برای شبکه‌های بزرگ
```powershell
.\powerPinger.ps1 -MaxFailures 3 -Jump 10
```

## 💡 نکات

- **برای شبکه‌های کند**: از `-Timeout 5000` استفاده کنید
- **برای اسکن کامل**: از حالت `smart` استفاده کنید
- **برای پورت خاص**: لیست پورت‌هایتان را مشخص کنید
- **برای نتیجه سریع**: از حالت `ping` استفاده کنید

## 🎯 اهداف متداول

### برای تحلیل شبکه
```powershell
.\powerPinger.ps1 -ScanMode "smart" -Ports "80,443,22,53,8080"
```

### برای بررسی سرور
```powershell
.\powerPinger.ps1 -ScanMode "port" -Ports "80,443,3389,22"
```

### برای اسکن سریع
```powershell
.\powerPinger.ps1 -ScanMode "ping" -Timeout 1000
```
