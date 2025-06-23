# MaxResponses Feature Added

## 📚 Navigation
[🏠 Main README](README.md) | [🚀 Quick Start](QUICKSTART.md) | [🔧 Enhanced Features](ENHANCED_FEATURES.md) | [📋 Changelog](CHANGELOG.md) | [🤝 Contributing](CONTRIBUTING.md)

**Languages**: [کوردی](README_KU.md) | [فارسی](README_FA.md) | [English](README.md)

---

## Summary
Added a new `-MaxResponses` parameter to PowerPinger that allows users to limit the number of successful responses before skipping to the next range.

## Key Features
- **Default Value**: 10 successful responses per range
- **Disable Option**: Set to 0 to disable the feature
- **Interactive Configuration**: Available in interactive mode setup
- **Command-line Support**: Can be set via `-MaxResponses` parameter

## Use Cases
- **Dense Networks**: Stop scanning after finding enough responsive IPs to avoid unnecessary scanning
- **Time Optimization**: Quickly identify active networks without exhaustive scanning  
- **Resource Management**: Reduce network load by limiting scan depth per range

## Implementation Details
- Counts successful responses based on scan mode:
  - **ping mode**: Successful ICMP responses
  - **port mode**: IPs with open ports  
  - **both/smart modes**: Either ping success OR open ports
- Displays "Response limit enabled" message during scanning
- Shows "Reached maximum responses" message when limit is hit
- Properly saves all results before stopping range scan

## Usage Examples
```powershell
# Stop after 5 successful responses per range
.\powerPinger.ps1 -MaxResponses 5

# Disable the feature (scan all IPs in range)
.\powerPinger.ps1 -MaxResponses 0

# Combine with other features
.\powerPinger.ps1 -InputFile "ranges.csv" -MaxResponses 3 -ScanMode smart
```

## Configuration Display
- Shows in interactive mode configuration summary
- Displays current setting: "X per range (enabled)" or "Disabled"  
- Included in final configuration summary before scanning

This feature provides better control over scan depth and helps optimize scanning time for large networks while ensuring sufficient coverage for network analysis.
