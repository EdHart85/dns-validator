#!/bin/bash
# =============================================================================
# DNS Domain Validation Script
# =============================================================================
# Description:
#   Reads a TXT file with a list of domains and validates each one against
#   a specified DNS server using the dig command. Provides a comprehensive
#   summary report with colored output.
#
# Input file format (one entry per line):
#   subdomain.fqdn
#   Example:
#   mail.example.com
#   www.example.com
#   ftp.example.com
#
# Usage:
#   ./dns_validator.sh -f domains.txt [-s 8.8.8.8] [-t 10]
#
# Dependencies:
#   - dig (bind-utils / dnsutils)
#   - awk, grep (typically already present in the system)
# =============================================================================

# ---------------------------------------------------------------------------
# Color definitions for terminal output
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ---------------------------------------------------------------------------
# Summary control variables
# ---------------------------------------------------------------------------
TOTAL_DOMAINS=0
VALID_DOMAINS=0
INVALID_DOMAINS=0
TIMEOUT_DOMAINS=0

# Arrays to store summary details with IPs
declare -a VALID_LIST=()
declare -a VALID_IPS=()
declare -a INVALID_LIST=()
declare -a TIMEOUT_LIST=()

# ---------------------------------------------------------------------------
# Function: usage
# Displays the help message for the script
# ---------------------------------------------------------------------------
usage() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║           DNS Domain Validation Script                       ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${WHITE}USAGE:${RESET}"
    echo -e "  $0 ${YELLOW}-f <file>${RESET} [options]"
    echo ""
    echo -e "${WHITE}REQUIRED PARAMETERS:${RESET}"
    echo -e "  ${YELLOW}-f <file>${RESET}         TXT file with a list of domains to validate"
    echo ""
    echo -e "${WHITE}OPTIONAL PARAMETERS:${RESET}"
    echo -e "  ${YELLOW}-s <dns_server>${RESET}   DNS server IP or hostname (default: 8.8.8.8)"
    echo -e "  ${YELLOW}-t <seconds>${RESET}     Timeout for dig queries in seconds (default: 10)"
    echo -e "  ${YELLOW}-h${RESET}               Display this help message"
    echo ""
    echo -e "${WHITE}INPUT FILE FORMAT:${RESET}"
    echo -e "  ${DIM}# Lines starting with # are comments and will be ignored${RESET}"
    echo -e "  ${DIM}# Blank lines will also be ignored${RESET}"
    echo -e "  domain.name.tld"
    echo -e "  mail.example.com"
    echo -e "  www.example.com"
    echo ""
    echo -e "${WHITE}EXAMPLES:${RESET}"
    echo -e "  $0 -f domains.txt"
    echo -e "  $0 -f domains.txt -s 1.1.1.1 -t 5"
    echo -e "  $0 -f domains.txt -s 8.8.8.8"
    echo ""
    exit 1
}

# ---------------------------------------------------------------------------
# Function: log_info
# Displays informational messages with timestamp
# ---------------------------------------------------------------------------
log_info() {
    echo -e "${DIM}[$(date '+%H:%M:%S')]${RESET} ${BLUE}ℹ${RESET}  $1"
}

# ---------------------------------------------------------------------------
# Function: log_ok
# Displays success messages with timestamp
# ---------------------------------------------------------------------------
log_ok() {
    echo -e "${DIM}[$(date '+%H:%M:%S')]${RESET} ${GREEN}✔${RESET}  $1"
}

# ---------------------------------------------------------------------------
# Function: log_error
# Displays error messages with timestamp
# ---------------------------------------------------------------------------
log_error() {
    echo -e "${DIM}[$(date '+%H:%M:%S')]${RESET} ${RED}✘${RESET}  $1"
}

# ---------------------------------------------------------------------------
# Function: log_warning
# Displays warning messages with timestamp
# ---------------------------------------------------------------------------
log_warning() {
    echo -e "${DIM}[$(date '+%H:%M:%S')]${RESET} ${YELLOW}⚠${RESET}  $1"
}

# ---------------------------------------------------------------------------
# Function: check_dependencies
# Verifies if the required tools are installed
# ---------------------------------------------------------------------------
check_dependencies() {
    local deps=("dig" "awk" "grep")
    local missing=0

    log_info "Checking dependencies..."

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "Dependency not found: ${BOLD}$dep${RESET}"
            missing=1
        else
            log_ok "Dependency found: ${BOLD}$dep${RESET}"
        fi
    done

    if [ "$missing" -eq 1 ]; then
        echo ""
        log_error "Please install the missing dependencies and run the script again."
        echo -e "  ${DIM}Debian/Ubuntu: sudo apt install dnsutils${RESET}"
        echo -e "  ${DIM}RHEL/CentOS:   sudo yum install bind-utils${RESET}"
        exit 1
    fi
    echo ""
}

# ---------------------------------------------------------------------------
# Function: validate_domain_format
# Validates if a string is a valid domain format
# Parameters: $1 = domain to validate
# Return: 0 (valid) or 1 (invalid)
# ---------------------------------------------------------------------------
validate_domain_format() {
    local domain="$1"
    local regex='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'

    if [[ "$domain" =~ $regex ]]; then
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Function: validate_input_file
# Validates the format of the input file line by line
# Parameters: $1 = file path
# Return: 0 (ok) or 1 (error found)
# ---------------------------------------------------------------------------
validate_input_file() {
    local file="$1"
    local line_num=0
    local errors=0

    log_info "Validating input file format: ${BOLD}$file${RESET}"

    while IFS= read -r line || [ -n "$line" ]; do
        line_num=$((line_num + 1))

        # Ignores blank lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Removes leading and trailing whitespace
        line=$(echo "$line" | xargs)

        # Validates domain format
        if ! validate_domain_format "$line"; then
            log_error "Line $line_num: Invalid domain format '${BOLD}$line${RESET}'"
            errors=$((errors + 1))
        fi

    done < "$file"

    if [ "$errors" -gt 0 ]; then
        log_error "Found $errors error(s) in the file. Please correct before proceeding."
        return 1
    fi

    log_ok "Input file validated successfully."
    return 0
}

# ---------------------------------------------------------------------------
# Function: validate_dns
# Performs DNS validation for a single domain
# Parameters:
#   $1 = domain to validate
#   $2 = line number (for log)
# ---------------------------------------------------------------------------
validate_dns() {
    local domain="$1"
    local line_num="$2"

    TOTAL_DOMAINS=$((TOTAL_DOMAINS + 1))

    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  Domain #${line_num}: ${WHITE}${domain}${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    log_info "Performing DNS lookup: ${DIM}dig ${domain} @${DNS_SERVER} +short${RESET}"

    # Execute dig query with timeout
    local dig_output
    local dig_exit_code

    dig_output=$(timeout "${DIG_TIMEOUT}" dig "${domain}" "@${DNS_SERVER}" +short +time="${DIG_TIMEOUT}" 2>/dev/null)
    dig_exit_code=$?

    # Check for timeout
    if [ $dig_exit_code -eq 124 ]; then
        log_warning "Query timeout for domain ${BOLD}${domain}${RESET}"
        TIMEOUT_DOMAINS=$((TIMEOUT_DOMAINS + 1))
        TIMEOUT_LIST+=("${domain}")
        echo -e "  ${DIM}Status: ${YELLOW}Query timeout (${DIG_TIMEOUT}s)${RESET}"
        return 2
    fi

    # Check if domain resolves
    if [ -z "$dig_output" ]; then
        log_error "Domain could not be resolved: ${BOLD}${domain}${RESET}"
        INVALID_DOMAINS=$((INVALID_DOMAINS + 1))
        INVALID_LIST+=("${domain}")
        echo -e "  ${DIM}Status: ${RED}No records found${RESET}"
        return 1
    fi

    # Domain resolved successfully - get first IP for summary
    local first_ip
    first_ip=$(echo "$dig_output" | head -1)

    log_ok "Domain validated successfully: ${BOLD}${GREEN}${domain}${RESET}"
    VALID_DOMAINS=$((VALID_DOMAINS + 1))
    VALID_LIST+=("${domain}")
    VALID_IPS+=("${first_ip}")

    echo -e "  ${DIM}Resolved IPs:${RESET}"
    echo "$dig_output" | while read -r ip; do
        echo -e "    ${GREEN}●${RESET}  $ip"
    done

    return 0
}

# ---------------------------------------------------------------------------
# Function: display_summary
# Displays a colored summary at the end of execution with all results
# ---------------------------------------------------------------------------
display_summary() {
    local execution_time
    execution_time=$(date '+%d/%m/%Y %H:%M:%S')

    echo ""
    echo ""
    echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${MAGENTA}║                      EXECUTION SUMMARY                          ║${RESET}"
    echo -e "${BOLD}${MAGENTA}╠══════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${DIM}Date/Time    : ${WHITE}${execution_time}${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${DIM}DNS Server   : ${WHITE}${DNS_SERVER}${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${DIM}Timeout      : ${WHITE}${DIG_TIMEOUT}s${RESET}"
    echo -e "${BOLD}${MAGENTA}╠══════════════════════════════════════════════════════════════════╣${RESET}"

    # Total by category
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${WHITE}TOTAL PROCESSED  : ${BOLD}${WHITE}${TOTAL_DOMAINS}${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${GREEN}✔  VALID         : ${BOLD}${GREEN}${VALID_DOMAINS}${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${RED}✘  INVALID       : ${BOLD}${RED}${INVALID_DOMAINS}${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${YELLOW}⚠  TIMEOUT       : ${BOLD}${YELLOW}${TIMEOUT_DOMAINS}${RESET}"

    # Details of valid domains with IPs
    if [ ${#VALID_LIST[@]} -gt 0 ]; then
        echo -e "${BOLD}${MAGENTA}╠══════════════════════════════════════════════════════════════════╣${RESET}"
        echo -e "${BOLD}${MAGENTA}║${RESET}  ${GREEN}${BOLD}✔  VALID DOMAINS${RESET}"
        echo -e "${BOLD}${MAGENTA}║${RESET}"
        for i in "${!VALID_LIST[@]}"; do
            domain="${VALID_LIST[$i]}"
            ip="${VALID_IPS[$i]}"
            echo -e "${BOLD}${MAGENTA}║${RESET}    ${GREEN}●${RESET}  $domain ${DIM}- ${ip}${RESET}"
        done
    fi

    # Details of invalid domains
    if [ ${#INVALID_LIST[@]} -gt 0 ]; then
        echo -e "${BOLD}${MAGENTA}╠══════════════════════════════════════════════════════════════════╣${RESET}"
        echo -e "${BOLD}${MAGENTA}║${RESET}  ${RED}${BOLD}✘  INVALID DOMAINS (could not be resolved)${RESET}"
        echo -e "${BOLD}${MAGENTA}║${RESET}"
        for item in "${INVALID_LIST[@]}"; do
            echo -e "${BOLD}${MAGENTA}║${RESET}    ${RED}●${RESET}  $item"
        done
    fi

    # Details of timeout domains
    if [ ${#TIMEOUT_LIST[@]} -gt 0 ]; then
        echo -e "${BOLD}${MAGENTA}╠══════════════════════════════════════════════════════════════════╣${RESET}"
        echo -e "${BOLD}${MAGENTA}║${RESET}  ${YELLOW}${BOLD}⚠  TIMEOUT DOMAINS (query exceeded time limit)${RESET}"
        echo -e "${BOLD}${MAGENTA}║${RESET}"
        for item in "${TIMEOUT_LIST[@]}"; do
            echo -e "${BOLD}${MAGENTA}║${RESET}    ${YELLOW}●${RESET}  $item"
        done
    fi

    echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${RESET}"

    # Exit code: 0 if all valid, 1 if there are any failures
    if [ $((INVALID_DOMAINS + TIMEOUT_DOMAINS)) -gt 0 ]; then
        echo ""
        log_warning "Execution completed with issues. Please review the items above."
        exit 1
    else
        echo ""
        log_ok "Execution completed successfully! All domains are valid."
        exit 0
    fi
}

# ===========================================================================
# SCRIPT START — Command line argument processing
# ===========================================================================

# Default variables
INPUT_FILE=""
DNS_SERVER="8.8.8.8"
DIG_TIMEOUT=10

# Parse command line arguments
while getopts "f:s:t:h" opt; do
    case "$opt" in
        f) INPUT_FILE="$OPTARG" ;;        # Input file with domain list
        s) DNS_SERVER="$OPTARG" ;;        # DNS server IP or hostname
        t) DIG_TIMEOUT="$OPTARG" ;;       # Timeout in seconds for dig queries
        h) usage ;;                        # Display help and exit
        *) usage ;;
    esac
done

# ---------------------------------------------------------------------------
# Script header
# ---------------------------------------------------------------------------
clear
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║            DNS Domain Validation Tool                            ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# ---------------------------------------------------------------------------
# Validate required parameters
# ---------------------------------------------------------------------------
PARAM_ERROR=0

if [ -z "$INPUT_FILE" ]; then
    log_error "Required parameter missing: -f <file>"
    PARAM_ERROR=1
fi

[ $PARAM_ERROR -ne 0 ] && usage

# Validate if file exists and is readable
if [ ! -f "$INPUT_FILE" ]; then
    log_error "File not found: ${BOLD}$INPUT_FILE${RESET}"
    exit 1
fi

if [ ! -r "$INPUT_FILE" ]; then
    log_error "File has no read permission: ${BOLD}$INPUT_FILE${RESET}"
    exit 1
fi

echo ""

# ---------------------------------------------------------------------------
# Check dependencies before starting
# ---------------------------------------------------------------------------
check_dependencies

# ---------------------------------------------------------------------------
# Validate input file format
# ---------------------------------------------------------------------------
validate_input_file "$INPUT_FILE" || exit 1
echo ""

# ---------------------------------------------------------------------------
# Display execution configuration
# ---------------------------------------------------------------------------
log_info "Execution configuration:"
echo -e "  ${DIM}Input File : ${WHITE}${INPUT_FILE}${RESET}"
echo -e "  ${DIM}DNS Server : ${WHITE}${DNS_SERVER}${RESET}"
echo -e "  ${DIM}Timeout    : ${WHITE}${DIG_TIMEOUT}s${RESET}"
echo ""

log_info "Starting DNS domain validation..."
echo ""

# ===========================================================================
# MAIN LOOP — Reads the file line by line and validates each domain
# ===========================================================================
line_count=0

while IFS= read -r line || [ -n "$line" ]; do

    # Ignores blank lines and comment lines (starting with #)
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Remove leading and trailing whitespace
    line=$(echo "$line" | xargs)

    # Increment line counter
    line_count=$((line_count + 1))

    # Perform DNS validation for this domain
    validate_dns "$line" "$line_count"

done < "$INPUT_FILE"

# ---------------------------------------------------------------------------
# Display the final colored summary with all results
# ---------------------------------------------------------------------------
display_summary
