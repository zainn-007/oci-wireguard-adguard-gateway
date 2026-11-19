#!/usr/bin/env bash
# Hardens an Ubuntu OCI host acting as a WireGuard/OpenVPN + AdGuard Home gateway.
set -euo pipefail

VPN_SUBNET="10.8.0.0/24"
SSH_PORT="22"

echo "[+] Enabling kernel IPv4 packet forwarding..."
cat <<EOF > /etc/sysctl.d/99-vpn-gateway.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
EOF
sysctl --system >/dev/null

echo "[+] Configuring UFW default-deny perimeter policy..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH and encrypted VPN tunnel ports externally
ufw allow "${SSH_PORT}/tcp" comment "SSH Administrative Access"
ufw allow 51820/udp comment "WireGuard VPN Tunnel"
ufw allow 1194/udp comment "OpenVPN Fallback Tunnel"

# Restrict DNS (53) and Web Admin UIs (3000, 51821) strictly to VPN clients
ufw allow from "${VPN_SUBNET}" to any port 53 proto udp comment "AdGuard DNS UDP (VPN Only)"
ufw allow from "${VPN_SUBNET}" to any port 53 proto tcp comment "AdGuard DNS TCP (VPN Only)"
ufw allow from "${VPN_SUBNET}" to any port 3000 proto tcp comment "AdGuard Admin UI (VPN Only)"
ufw allow from "${VPN_SUBNET}" to any port 51821 proto tcp comment "WireGuard Admin UI (VPN Only)"

ufw --force enable
echo "[+] Gateway firewall and sysctl hardening complete."
