# Contributing to PowerPinger

## 📚 Navigation
[🏠 Main README](README.md) | [🚀 Quick Start](QUICKSTART.md) | [🔧 Enhanced Features](ENHANCED_FEATURES.md) | [📋 Changelog](CHANGELOG.md)

**Languages**: [کوردی](README_KU.md) | [فارسی](README_FA.md) | [English](README.md)

---

Thank you for your interest in contributing to PowerPinger! This guide will help you get started.

## 🚀 Getting Started

### Prerequisites
- PowerShell 5.1 or later
- Git for version control
- Basic understanding of networking concepts

### Development Setup
1. Fork the repository
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/PowerPinger.git
   cd PowerPinger
   ```
3. Create a branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📋 Contribution Guidelines

### Code Style
- Use clear, descriptive variable names
- Include comprehensive comments for complex logic
- Follow PowerShell best practices and conventions
- Maintain compatibility with PowerShell 5.1+

### Testing
- Test your changes with various input formats
- Verify compatibility across different PowerShell versions
- Include sample data for testing new features
- Document any new parameters or functionality

### Documentation
- Update README.md for new features
- Add inline comments for complex functions
- Include usage examples for new functionality
- Update help text and parameter descriptions

## 🐛 Bug Reports

When reporting bugs, please include:
- PowerShell version (`$PSVersionTable.PSVersion`)
- Operating system
- Input file format and sample data (anonymized)
- Expected vs actual behavior
- Error messages or logs

## 💡 Feature Requests

For new features, please:
- Describe the use case and problem being solved
- Provide examples of desired functionality
- Consider backward compatibility
- Discuss implementation approach

## 🔍 Code Review Process

1. Submit a pull request with clear description
2. Include tests and documentation updates
3. Respond to review feedback promptly
4. Ensure all checks pass before merging

## 📝 Commit Guidelines

Use clear, descriptive commit messages:
- `feat: add smart detection for DNS filtering`
- `fix: resolve timeout issue with large ranges`
- `docs: update README with new examples`
- `refactor: improve port scanning performance`

## 🛡️ Security

- Report security vulnerabilities privately
- Follow responsible disclosure practices
- Consider privacy implications of new features
- Avoid including sensitive data in commits

## 📞 Getting Help

- Check existing issues and discussions
- Join our community discussions
- Ask questions in pull request comments
- Contact maintainers for significant contributions

## 📦 Recent Features (v2.1.0)
- **MaxResponses Parameter**: Limits successful responses per range for performance optimization
- **Enhanced Exit Logic**: Proper flag-based mechanism for range scanning termination
- **Interactive Configuration**: Extended configuration options in interactive mode
- **Multilingual Documentation**: Support for Kurdish, Farsi, and English documentation

Thank you for helping make PowerPinger better! 🎉
