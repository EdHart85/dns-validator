# DNS Domain Validator

<div align="center">

![Bash](https://img.shields.io/badge/Bash-5.1+-green?style=flat-square&logo=gnu-bash)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux%2FmacOS-orange?style=flat-square)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square)

A lightweight and efficient Bash script for batch DNS domain validation with comprehensive reporting.

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Examples](#examples) • [Contributing](#contributing)

</div>

---

## Overview

**DNS Domain Validator** is a powerful Bash utility that reads a list of domains from a text file and validates each one against a specified DNS server. It provides a detailed, color-coded summary report showing which domains resolve successfully and their corresponding IP addresses.

Perfect for:
- 🔍 Validating domain configurations
- 📋 Batch checking DNS propagation
- 🔧 Network troubleshooting
- 📊 Infrastructure monitoring
- ✅ Migration verification

---

## Features

✨ **Core Functionality:**
- ✔ Batch validation of domains from a text file
- ✔ DNS resolution using `dig` command
- ✔ Support for custom DNS servers
- ✔ Configurable query timeout
- ✔ Domain format validation before processing

📊 **Reporting:**
- ✔ Color-coded categorized results (Valid/Invalid/Timeout)
- ✔ Resolved IP addresses displayed alongside domains
- ✔ Detailed execution summary with timestamps
- ✔ Clear status indicators (✔ ✘ ⚠)

🎨 **User Experience:**
- ✔ Beautiful terminal output with colors and emojis
- ✔ Progress indication during validation
- ✔ Helpful error messages and diagnostics
- ✔ Comprehensive help documentation (-h flag)
- ✔ Support for comments and blank lines in input files

⚡ **Performance:**
- ✔ Lightweight and fast
- ✔ Minimal dependencies (only `dig`, `awk`, `grep`)
- ✔ Efficient parallel-ready design
- ✔ Low resource consumption

---

## Requirements

### Dependencies

The script requires the following tools to be installed:

| Tool | Purpose | Package |
|------|---------|---------|
| `dig` | DNS lookups | `dnsutils` (Debian/Ubuntu) / `bind-utils` (RHEL/CentOS) |
| `awk` | Text processing | Usually pre-installed |
| `grep` | Pattern matching | Usually pre-installed |

### System Requirements

- **OS:** Linux or macOS
- **Shell:** Bash 4.0+
- **Permissions:** Standard user permissions (no sudo required)

---

## Installation

### Quick Start

#### 1. Clone the repository:
```bash
git clone https://github.com/yourusername/dns-validator.git
cd dns-validator
```

#### 2. Make the script executable:
```bash
chmod +x dns_validator.sh
```

#### 3. Install dependencies (if needed):

**Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install dnsutils
```

**RHEL/CentOS/Fedora:**
```bash
sudo yum install bind-utils
```

**macOS (using Homebrew):**
```bash
brew install bind
```

#### 4. Verify installation:
```bash
./dns_validator.sh -h
```

### Alternative: Direct Download

```bash
# Download the script
wget https://raw.githubusercontent.com/yourusername/dns-validator/main/dns_validator.sh

# Make it executable
chmod +x dns_validator.sh

# Run it
./dns_validator.sh -h
```

---

## Usage

### Basic Syntax

```bash
./dns_validator.sh -f <file> [options]
```

### Parameters

#### Required:
- **`-f <file>`** - Path to the input file with domain list

#### Optional:
- **`-s <dns_server>`** - DNS server IP or hostname (default: `8.8.8.8`)
- **`-t <seconds>`** - Query timeout in seconds (default: `10`)
- **`-h`** - Display help message and exit

### Examples

#### Basic usage (Google DNS):
```bash
./dns_validator.sh -f domains.txt
```

#### Using Cloudflare DNS with 5-second timeout:
```bash
./dns_validator.sh -f domains.txt -s 1.1.1.1 -t 5
```

#### Using Quad9 DNS:
```bash
./dns_validator.sh -f domains.txt -s 9.9.9.9
```

#### Using a local DNS server:
```bash
./dns_validator.sh -f domains.txt -s 192.168.1.1 -t 15
```

---

## Input File Format

The input file should contain one domain per line. Comments and blank lines are automatically ignored.

### Example: `domains.txt`

```
# Main company domains
example.com
mail.example.com
www.example.com

# Partner domains
partner.com
api.partner.com

# Public services
github.com
google.com
```

### Rules:
- One domain per line
- Lines starting with `#` are treated as comments
- Blank lines are ignored
- Domains must be in valid FQDN format
- Leading/trailing whitespace is automatically trimmed

### Validation:
The script validates domain format before processing:
- ✅ Valid: `example.com`, `mail.example.com`, `api.v2.example.co.uk`
- ❌ Invalid: `example`, `example..com`, `-example.com`

---

## Output

### Real-time Processing

As the script runs, you'll see real-time progress for each domain:

```
[14:23:45] ℹ  Domain #1: example.com
[14:23:45] ℹ  Performing DNS lookup: dig example.com @8.8.8.8 +short
[14:23:45] ✔  Domain validated successfully: example.com
  Resolved IPs:
    ●  93.184.216.34

[14:23:46] ℹ  Domain #2: invalid-domain-xyz.com
[14:23:46] ✘  Domain could not be resolved: invalid-domain-xyz.com
  Status: No records found
```

### Summary Report

After completion, you'll see a comprehensive colored summary:

```
╔══════════════════════════════════════════════════════════════════╗
║                      EXECUTION SUMMARY                          ║
╠══════════════════════════════════════════════════════════════════╣
║  Date/Time    : 15/03/2026 14:24:10
║  DNS Server   : 8.8.8.8
║  Timeout      : 10s
╠══════════════════════════════════════════════════════════════════╣
║  TOTAL PROCESSED  : 5
║  ✔  VALID         : 3
║  ✘  INVALID       : 1
║  ⚠  TIMEOUT       : 1
╠══════════════════════════════════════════════════════════════════╣
║  ✔  VALID DOMAINS
║
║    ●  example.com - 93.184.216.34
║    ●  github.com - 140.82.113.3
║    ●  google.com - 142.250.185.46
╠══════════════════════════════════════════════════════════════════╣
║  ✘  INVALID DOMAINS (could not be resolved)
║
║    ●  invalid-domain-xyz.com
╠══════════════════════════════════════════════════════════════════╣
║  ⚠  TIMEOUT DOMAINS (query exceeded time limit)
║
║    ●  slowdns.example.com
╚══════════════════════════════════════════════════════════════════╝

[14:24:10] ✔  Execution completed successfully! All domains are valid.
```

### Exit Codes

- **`0`** - Success (all domains validated)
- **`1`** - Failure (some domains invalid or timeout)

Use exit codes for automation and scripting:
```bash
./dns_validator.sh -f domains.txt && echo "All domains valid!" || echo "Some domains failed"
```

---

## Advanced Usage

### Scripting and Automation

#### Check domains in a cron job:
```bash
0 */4 * * * /home/user/dns-validator/dns_validator.sh -f /home/user/domains.txt -s 8.8.8.8 >> /var/log/dns_validator.log 2>&1
```

#### Save results to a file:
```bash
./dns_validator.sh -f domains.txt 2>&1 | tee results_$(date +%Y%m%d_%H%M%S).txt
```

#### Process multiple domain lists:
```bash
for file in domains_*.txt; do
    echo "Processing $file..."
    ./dns_validator.sh -f "$file" -s 1.1.1.1
done
```

#### Check domains and send email on failure:
```bash
if ! ./dns_validator.sh -f domains.txt; then
    echo "Domain validation failed" | mail -s "DNS Alert" admin@example.com
fi
```

### Custom DNS Servers

Use different DNS servers for testing:

```bash
# Google DNS
./dns_validator.sh -f domains.txt -s 8.8.8.8

# Cloudflare DNS
./dns_validator.sh -f domains.txt -s 1.1.1.1

# Quad9 DNS
./dns_validator.sh -f domains.txt -s 9.9.9.9

# OpenDNS
./dns_validator.sh -f domains.txt -s 208.67.222.222

# Your local DNS server
./dns_validator.sh -f domains.txt -s 192.168.1.1
```

### Timeout Scenarios

Adjust timeout for slow networks or slow DNS servers:

```bash
# Fast networks (5 second timeout)
./dns_validator.sh -f domains.txt -t 5

# Normal networks (10 second timeout - default)
./dns_validator.sh -f domains.txt -t 10

# Slow networks or slow DNS (20 second timeout)
./dns_validator.sh -f domains.txt -t 20

# Very slow/unreliable networks (30 second timeout)
./dns_validator.sh -f domains.txt -t 30
```

---

## Examples

### Example 1: Basic Domain Validation

**Input file: `example_domains.txt`**
```
github.com
google.com
invalid-example-domain.com
```

**Command:**
```bash
./dns_validator.sh -f example_domains.txt
```

**Output:**
Successfully validates the domains and shows which ones resolved and their IPs.

---

### Example 2: Company Internal Domains

**Input file: `company_domains.txt`**
```
# Company domains
mail.company.com
www.company.com
api.company.com
intranet.company.com
```

**Command:**
```bash
./dns_validator.sh -f company_domains.txt -s 192.168.1.1 -t 15
```

**Use case:** Validate internal company domains against your local DNS server with a longer timeout.

---

### Example 3: Post-Migration Verification

**Input file: `migration_domains.txt`**
```
# Previously hosted domains
old-service-1.example.com
old-service-2.example.com
old-service-3.example.com

# Migrated domains
new-service-1.example.com
new-service-2.example.com
```

**Command:**
```bash
./dns_validator.sh -f migration_domains.txt -s 8.8.8.8
```

**Use case:** Verify that all domains are properly configured after migration.

---

### Example 4: CI/CD Pipeline Integration

**Bash script: `validate_domains.sh`**
```bash
#!/bin/bash
set -e

DOMAINS_FILE="domains.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Validating domains..."
"$SCRIPT_DIR/dns_validator.sh" -f "$DOMAINS_FILE" -s 8.8.8.8

if [ $? -eq 0 ]; then
    echo "✅ All domains validated successfully!"
    exit 0
else
    echo "❌ Domain validation failed!"
    exit 1
fi
```

**Use case:** Add domain validation to your CI/CD pipeline to ensure DNS is properly configured before deployment.

---

## Troubleshooting

### Common Issues

#### Error: "dig: command not found"
**Solution:** Install `dnsutils` (Debian/Ubuntu) or `bind-utils` (RHEL/CentOS)
```bash
# Debian/Ubuntu
sudo apt install dnsutils

# RHEL/CentOS
sudo yum install bind-utils
```

#### Error: "File not found: domains.txt"
**Solution:** Make sure the file exists and the path is correct
```bash
ls -la domains.txt
./dns_validator.sh -f ./domains.txt
```

#### Error: "File has no read permission"
**Solution:** Check file permissions
```bash
chmod 644 domains.txt
```

#### All domains show as timeout
**Possible causes:**
- DNS server is unreachable
- Network connectivity issue
- Timeout too short for your network
- Try increasing timeout: `-t 20` or `-t 30`
- Try a different DNS server: `-s 8.8.8.8`

#### Some domains show as invalid but they should be valid
**Possible causes:**
- DNS server doesn't have records for those domains
- Try a different DNS server (e.g., `-s 8.8.8.8`)
- Check domain format (must be valid FQDN)
- Domain might be newly created (DNS propagation delay)

#### Script permission denied
**Solution:** Make script executable
```bash
chmod +x dns_validator.sh
./dns_validator.sh -f domains.txt
```

---

## Performance Tips

1. **Parallel Processing:** Process multiple files in background
   ```bash
   ./dns_validator.sh -f list1.txt &
   ./dns_validator.sh -f list2.txt &
   wait
   ```

2. **Optimize Timeout:** Use shorter timeout for faster networks
   ```bash
   ./dns_validator.sh -f domains.txt -t 5
   ```

3. **Use Fast DNS Server:** Google (8.8.8.8) or Cloudflare (1.1.1.1)
   ```bash
   ./dns_validator.sh -f domains.txt -s 1.1.1.1
   ```

4. **Batch Large Lists:** Split into smaller files if processing thousands
   ```bash
   split -l 100 large_list.txt list_
   for file in list_*; do
       ./dns_validator.sh -f "$file"
   done
   ```

---

## Security Considerations

✅ **What's safe:**
- No credentials or sensitive data stored
- Read-only file operations
- Standard Bash security practices
- No external API calls
- No data transmission beyond DNS queries

⚠️ **Best practices:**
- Keep domains list in a secure location
- Review input file for unexpected entries
- Use trusted DNS servers
- Audit logs if running in production
- Run with minimal required privileges

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. **Fork** the repository
2. **Create** your feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Guidelines

- Keep code style consistent with existing script
- Test thoroughly before submitting
- Update documentation if needed
- Follow Bash best practices
- Add comments for complex logic

### Areas for Contribution

- 🎨 Enhanced output formatting
- 📊 Additional reporting options
- 🚀 Performance improvements
- 🌍 Multi-language support
- 📚 Documentation improvements
- 🐛 Bug fixes
- ✨ New features (while keeping it lightweight)

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

MIT License allows you to:
- ✅ Use commercially
- ✅ Modify the code
- ✅ Distribute the software
- ✅ Use privately

The only requirement is to include the original license and copyright notice.

---

## Changelog

### Version 1.0.0 (2026-03-26)
- ✨ Initial release
- ✔ Batch domain validation from file
- ✔ DNS resolution with dig
- ✔ Custom DNS server support
- ✔ Configurable timeout
- ✔ Color-coded summary reports
- ✔ IP address display in results

---

### Reporting Issues

Found a bug? Please open an issue with:
- Description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, Bash version)
- Relevant command and input file

---

## Author

**Eduardo Hartmann** - [GitHub Profile](https://github.com/EdHart85)

---

<div align="center">

**[⬆ Back to top](#dns-domain-validator)**

Made with ☕ by DevOps Engineers for DevOps Engineers

</div>
