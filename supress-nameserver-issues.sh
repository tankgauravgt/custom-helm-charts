#!/bin/bash
set -euo pipefail

# --- 1️⃣ Create custom resolv.conf ---
echo "🚀 Creating /etc/kubernetes/resolv.conf with IPv4 + IPv6 nameservers..."
mkdir -p /etc/kubernetes

cat <<EOF >/etc/kubernetes/resolv.conf
# IPv6 DNS servers
nameserver 2001:4860:4860::8888     # Google IPv6
# nameserver 2606:4700:4700::1111     # Cloudflare IPv6
# nameserver 2620:fe::fe              # Quad9 IPv6

# IPv4 DNS servers
nameserver 8.8.8.8                  # Google IPv4
nameserver 1.1.1.1                  # Cloudflare IPv4
# nameserver 9.9.9.9                  # Quad9 IPv4

options ndots:5
EOF

echo "✅ /etc/kubernetes/resolv.conf created."

# --- 2️⃣ Configure kubelet to use the new resolv.conf ---
KUBELET_DEFAULT_FILE="/etc/default/kubelet"

if [ -f "$KUBELET_DEFAULT_FILE" ]; then
    echo "🚀 Updating kubelet to use /etc/kubernetes/resolv.conf..."
    if grep -q "KUBELET_EXTRA_ARGS" "$KUBELET_DEFAULT_FILE"; then
        sed -i 's|KUBELET_EXTRA_ARGS=.*|KUBELET_EXTRA_ARGS="--resolv-conf=/etc/kubernetes/resolv.conf"|' "$KUBELET_DEFAULT_FILE"
    else
        echo 'KUBELET_EXTRA_ARGS="--resolv-conf=/etc/kubernetes/resolv.conf"' >>"$KUBELET_DEFAULT_FILE"
    fi
    echo "✅ kubelet configured."
else
    echo "⚠️ /etc/default/kubelet not found — skipping configuration."
fi

# --- 3️⃣ Restart kubelet ---
if systemctl list-units --type=service | grep -q kubelet; then
    echo "🚀 Restarting kubelet..."
    systemctl daemon-reload
    systemctl restart kubelet
    echo "✅ kubelet restarted successfully."
else
    echo "⚠️ kubelet service not found or managed externally. You may need to recycle the node (e.g. CloudFleet)."
fi

echo "🎉 Done! Custom DNS configuration applied system-wide."
