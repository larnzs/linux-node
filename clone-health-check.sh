#!/usr/bin/env bash
# FragCity read-only health check for the temporary Clone replacement.
# This script collects status only. It does not restart services, change files,
# modify firewall/router rules, or display application secrets.
#
# Run on the Clone while the original VM is powered off:
#   sudo bash clone-health-check.sh
#
# Expected temporary Clone identity:
#   hostname: fc-node-01
#   LAN IPv4: 192.168.1.9

set -uo pipefail
export LC_ALL=C

EXPECTED_HOST="fc-node-01"
EXPECTED_IP="192.168.1.9"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { printf '[PASS] %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '[WARN] %s\n' "$1"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
section() { printf '\n===== %s =====\n' "$1"; }

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this read-only checker as root:"
    echo "  sudo bash clone-health-check.sh"
    exit 1
fi

section "1. Host identity and time"

CURRENT_HOST="$(hostnamectl --static 2>/dev/null || hostname)"
printf 'Hostname: %s\n' "$CURRENT_HOST"
printf 'Date:     %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
printf 'Uptime:   %s\n' "$(uptime -p 2>/dev/null || uptime)"

if [[ "$CURRENT_HOST" == "$EXPECTED_HOST" ]]; then
    pass "Hostname matches expected temporary replacement name."
else
    warn "Hostname differs from expected $EXPECTED_HOST; confirm which VM is running."
fi

if [[ -r /etc/machine-id ]] && grep -Eq '^[0-9a-f]{32}$' /etc/machine-id; then
    pass "machine-id file exists and has valid format (value hidden)."
else
    warn "machine-id is missing or has an unexpected format."
fi

if getent hosts "$CURRENT_HOST" >/dev/null 2>&1; then
    printf 'Local hostname mapping: '
    getent hosts "$CURRENT_HOST" | head -n 1
    pass "Current hostname resolves."
else
    fail "Current hostname does not resolve; check /etc/hosts."
fi

section "2. Network and routes"

ip -br address 2>/dev/null || true
ip route 2>/dev/null || true

if ip -o -4 address show | grep -Fq "$EXPECTED_IP/"; then
    pass "Expected Clone IPv4 $EXPECTED_IP is assigned."
else
    warn "Expected Clone IPv4 $EXPECTED_IP is not assigned; DHCP/IP may have changed."
fi

if ip route show default | grep -q '^default'; then
    pass "A default route exists."
else
    fail "No default route found."
fi

printf '\nDNS resolution for panel.fragcity.ir:\n'
if getent ahosts panel.fragcity.ir >/dev/null 2>&1; then
    getent ahosts panel.fragcity.ir | head -n 3
    pass "Panel domain resolves through the system resolver."
else
    fail "panel.fragcity.ir did not resolve from this VM."
fi

section "3. Main systemd services"

for unit in \
    nginx.service \
    php8.3-fpm.service \
    mariadb.service \
    redis-server.service \
    docker.service \
    wings.service \
    pteroq.service
do
    active="$(systemctl is-active "$unit" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "$unit" 2>/dev/null || true)"
    [[ -n "$active" ]] || active="unknown"
    [[ -n "$enabled" ]] || enabled="unknown"
    printf '%-24s active=%-12s enabled=%s\n' "$unit" "$active" "$enabled"

    case "$unit" in
        nginx.service|php8.3-fpm.service|mariadb.service|redis-server.service|docker.service|wings.service)
            if [[ "$active" == "active" ]]; then
                pass "$unit is active."
            else
                fail "$unit is not active (state: $active)."
            fi
            ;;
        pteroq.service)
            if [[ "$active" == "active" ]]; then
                pass "pteroq.service is active."
            elif [[ "$enabled" == "not-found" ]] || ! systemctl cat "$unit" >/dev/null 2>&1; then
                warn "pteroq.service unit was not found; inspect available queue/worker units before changing anything."
            else
                warn "pteroq.service exists but is not active."
            fi
            ;;
    esac
done

echo
echo "Related queue/worker services (if any):"
systemctl list-units --all --type=service --no-legend 2>/dev/null \
    | grep -Ei 'pteroq|pterodactyl|queue|horizon|supervisor' \
    | head -n 20 || echo "No matching loaded services found."

section "4. Web configuration and local HTTPS"

if command -v nginx >/dev/null 2>&1; then
    if nginx -t 2>&1; then
        pass "Nginx configuration test succeeded."
    else
        fail "Nginx configuration test failed."
    fi
else
    fail "nginx executable not found."
fi

if command -v curl >/dev/null 2>&1; then
    panel_code="$(curl --resolve panel.fragcity.ir:443:127.0.0.1 \
        --connect-timeout 4 --max-time 10 \
        --silent --show-error --output /dev/null \
        --write-out '%{http_code}' \
        https://panel.fragcity.ir/ 2>/dev/null || true)"

    if [[ "$panel_code" =~ ^[23][0-9][0-9]$ ]]; then
        pass "Local HTTPS virtual host for panel.fragcity.ir replied with HTTP $panel_code."
    elif [[ "$panel_code" =~ ^[45][0-9][0-9]$ ]]; then
        warn "Local HTTPS virtual host replied with HTTP $panel_code; inspect the Panel response."
    else
        warn "Local HTTPS probe failed; check Nginx listener, TLS certificate, and virtual-host config."
    fi
else
    warn "curl is not installed; local HTTPS probe skipped."
fi

section "5. TLS certificate files"

for cert in \
    /etc/letsencrypt/live/panel.fragcity.ir/fullchain.pem \
    /etc/letsencrypt/live/fc-node-01.fragcity.ir/fullchain.pem
do
    if [[ -r "$cert" ]] && command -v openssl >/dev/null 2>&1; then
        printf '%s: ' "$cert"
        openssl x509 -in "$cert" -noout -enddate 2>/dev/null || true

        if openssl x509 -in "$cert" -noout -checkend 1209600 >/dev/null 2>&1; then
            pass "Certificate has more than 14 days remaining: $cert"
        else
            warn "Certificate expires within 14 days or could not be validated: $cert"
        fi
    else
        warn "Certificate file missing/unreadable or openssl unavailable: $cert"
    fi
done

section "6. Local listening TCP ports"

ss -lntp 2>/dev/null || true
echo
echo "Expected service ports:"
for port in 80 443 8080 2022; do
    if ss -lnt 2>/dev/null | awk -v p=":$port" '$4 ~ (p "$") {found=1} END {exit !found}'; then
        pass "A TCP listener exists on port $port."
    else
        warn "No local TCP listener detected on port $port."
    fi
done

section "7. Database and Redis basic checks"

if command -v mariadb-admin >/dev/null 2>&1; then
    if mariadb-admin --protocol=socket --connect-timeout=3 ping >/dev/null 2>&1; then
        pass "MariaDB socket ping succeeded."
    else
        warn "MariaDB socket ping did not succeed; service state was shown above. No credentials were read or printed."
    fi
else
    warn "mariadb-admin is unavailable; database ping skipped."
fi

if command -v redis-cli >/dev/null 2>&1; then
    redis_reply="$(redis-cli ping 2>/dev/null || true)"
    if [[ "$redis_reply" == "PONG" ]]; then
        pass "Redis replied PONG."
    else
        warn "Redis ping did not return PONG (possibly authentication or local policy); no credentials were read or printed."
    fi
else
    warn "redis-cli is unavailable; Redis ping skipped."
fi

section "8. Docker and Pterodactyl storage"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker_root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || true)"
    [[ -n "$docker_root" ]] || docker_root="unknown"
    printf 'Docker root: %s\n' "$docker_root"
    pass "Docker daemon responds."
    echo
    echo "Containers (metadata only; no environment variables/secrets):"
    docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' 2>/dev/null || true
    echo
    docker system df 2>/dev/null || true
else
    warn "Docker daemon is unavailable or Docker CLI is not installed."
fi

for path in \
    /var/lib/pterodactyl/volumes \
    /var/lib/pterodactyl/archives \
    /var/lib/pterodactyl/backups
do
    if [[ -d "$path" ]]; then
        printf '\n%s\n' "$path"
        find "$path" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null | head -n 30
    else
        printf '\n%s: not created yet\n' "$path"
    fi
done

section "9. Disk capacity and attached devices"

df -hT / 2>/dev/null || true
echo
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS 2>/dev/null || true

if df -P / | awk 'NR==2 {gsub("%","",$5); if ($5+0 < 90) exit 0; exit 1}'; then
    pass "Root filesystem usage is below 90%."
else
    warn "Root filesystem usage is 90% or higher; review disk capacity."
fi

section "10. Firewall status (read-only)"

if command -v ufw >/dev/null 2>&1; then
    ufw status verbose 2>/dev/null || true
else
    warn "UFW command not found."
fi

section "11. Recent high-priority service failures (summary only)"

for unit in nginx.service php8.3-fpm.service mariadb.service redis-server.service docker.service wings.service; do
    count="$(journalctl -u "$unit" --since '-15 minutes' -p err..emerg --no-pager -q 2>/dev/null | wc -l | tr -d ' ')"
    [[ -n "$count" ]] || count="0"
    printf '%-24s errors-in-last-15m=%s\n' "$unit" "$count"
done
echo "Raw logs are intentionally not printed or saved."

section "12. Final summary"

printf 'PASS: %s\nWARN: %s\nFAIL: %s\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
echo
echo "Important manual checks this script cannot prove:"
echo "  - Router Port Forward rules really target 192.168.1.9 during this test."
echo "  - The Panel shows the Node online in its UI."
echo "  - The original VM remains powered off."
echo "  - CS2 Base/instances are not installed yet; identify the second VMDK before formatting."
echo
echo "This script is read-only; it does not fix any reported issue."
