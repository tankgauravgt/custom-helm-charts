#!/bin/bash
# =============================================================================
# Kubernetes DNS Configuration Script
# =============================================================================
# This script configures custom DNS nameservers for Kubernetes to suppress
# nameserver-related issues. It creates a custom resolv.conf and configures
# kubelet to use it.
# =============================================================================

set -euo pipefail

# Configuration
readonly KUBE_RESOLV_CONF="/etc/kubernetes/resolv.conf"
readonly KUBELET_CONFIG_FILE="/etc/default/kubelet"

# =============================================================================
# Step 1: Create Custom DNS Configuration
# =============================================================================
create_custom_resolv_conf() {
    echo "🚀 Creating custom DNS configuration..."
    mkdir -p /etc/kubernetes

    cat <<EOF >"${KUBE_RESOLV_CONF}"
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

    echo "✅ Custom DNS configuration created at ${KUBE_RESOLV_CONF}"
}

# =============================================================================
# Step 2: Configure Kubelet
# =============================================================================
configure_kubelet() {
    if [ ! -f "${KUBELET_CONFIG_FILE}" ]; then
        echo "⚠️  Kubelet config file not found at ${KUBELET_CONFIG_FILE}"
        echo "    Skipping kubelet configuration."
        return
    fi

    echo "🚀 Configuring kubelet to use custom DNS configuration..."
    
    local kubelet_args="KUBELET_EXTRA_ARGS=\"--resolv-conf=${KUBE_RESOLV_CONF}\""
    
    if grep -q "KUBELET_EXTRA_ARGS" "${KUBELET_CONFIG_FILE}"; then
        # Update existing configuration
        sed -i "s|KUBELET_EXTRA_ARGS=.*|${kubelet_args}|" "${KUBELET_CONFIG_FILE}"
    else
        # Add new configuration
        echo "${kubelet_args}" >> "${KUBELET_CONFIG_FILE}"
    fi
    
    echo "✅ Kubelet configuration updated"
}

# =============================================================================
# Step 3: Restart Kubelet Service
# =============================================================================
restart_kubelet() {
    if ! systemctl list-units --type=service | grep -q kubelet; then
        echo "⚠️  Kubelet service not found or managed externally"
        echo "    You may need to manually recycle the node (e.g., in CloudFleet)"
        return
    fi

    echo "🚀 Restarting kubelet service..."
    systemctl daemon-reload
    systemctl restart kubelet
    echo "✅ Kubelet restarted successfully"
}

# =============================================================================
# Main Execution
# =============================================================================
main() {
    echo "=================================="
    echo "Kubernetes DNS Configuration"
    echo "=================================="
    echo ""
    
    create_custom_resolv_conf
    configure_kubelet
    restart_kubelet
    
    echo ""
    echo "🎉 DNS configuration completed successfully!"
}

main
