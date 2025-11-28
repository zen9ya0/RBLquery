#!/bin/sh

PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Get last nameserver from /etc/resolv.conf
DNS=$(awk '/^nameserver/ {ip=$2} END {if (ip) print ip}' /etc/resolv.conf)

if [ -z "$DNS" ]; then
    echo "No nameserver found in /etc/resolv.conf"
    exit 1
fi

# RBL list
RBL_LIST="\
bl.spamcop.net \
cbl.abuseat.org \
cbl.anti-spam.org.cn \
dnsbl.sorbs.net \
pbl.spamhaus.org \
psbl.surriel.com \
rbl.softsqr.com"

# Function: validate IP and check against RBLs
check_ip_in_rbl() {
    ip="$1"

    # Basic IPv4 format validation
    case "$ip" in
        [0-9]*.[0-9]*.[0-9]*.[0-9]*) ;;
        *)
            echo "[SKIP] Invalid IPv4 address: $ip" >&2
            return
            ;;
    esac

    # Reverse IP for RBL lookup
    RBLIP=$(printf '%s\n' "$ip" | awk -F. '{print $4"."$3"."$2"."$1}')

    hit=0

    for RBL in $RBL_LIST; do
        # Get all A records
        raw_result=$(dig +short A "$RBLIP.$RBL" @"$DNS")

        # Only treat 127.0.0.x as valid RBL hit
        listed_result=$(printf '%s\n' "$raw_result" | awk '/^127\.0\.0\./ {print}')

        if [ -n "$listed_result" ]; then
            if [ "$hit" -eq 0 ]; then
                echo "=== HIT for IP: $ip (reverse: $RBLIP) ==="
                hit=1
            fi

            # Print each 127.0.0.x line
            printf '%s\n' "$listed_result" | while IFS= read -r line; do
                echo "[LISTED] $ip in $RBL ($RBLIP.$RBL -> $line)"
            done
        fi
    done

    if [ "$hit" -eq 1 ]; then
        echo ""
    fi
}

# Main logic: if arguments are provided, use them as IP list;
# otherwise, read IPs from stdin (one per line).
if [ "$#" -gt 0 ]; then
    # IPs from command-line arguments
    for ip in "$@"; do
        check_ip_in_rbl "$ip"
    done
else
    echo "Enter IPs to check (one per line). Press Ctrl+D when done."
    while IFS= read -r ip; do
        # Skip empty lines
        [ -z "$ip" ] && continue
        # Skip lines starting with '#'
        case "$ip" in
            \#*) continue ;;
        esac

        check_ip_in_rbl "$ip"
    done
fi
