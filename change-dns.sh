#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -euo pipefail

GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

print_header() { echo -e "${CYAN}==> $1${RESET}"; }
print_ok() { echo -e "${GREEN}[OK]${RESET} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
print_err() { echo -e "${RED}[ERR]${RESET} $1"; }

# Check for root privileges up front for commands that need it
ensure_sudo() {
    if ! sudo -v &>/dev/null; then
        print_err "This script requires sudo privileges to modify network settings."
        exit 1
    fi
}

get_active_nm_connection() {
    # Better method: Find the interface handling the default internet route
    local default_iface
    default_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)

    if [[ -n "$default_iface" ]]; then
        # Grab the active connection explicitly tied to that interface
        nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep ":${default_iface}$" | cut -d: -f1 | head -n1
    else
        # Fallback: get first active connection that is NOT loopback
        nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -v 'loopback' | head -n1 | cut -d: -f1
    fi
}

show_dns_provider() {
    print_header "DNS Provider / Manager Detection"

    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        print_ok "systemd-resolved is ACTIVE"
    else
        print_warn "systemd-resolved is NOT active"
    fi

    if systemctl is-active --quiet NetworkManager 2>/dev/null; then
        print_ok "NetworkManager is ACTIVE"
    else
        print_warn "NetworkManager is NOT active"
    fi

    echo
    print_header "/etc/resolv.conf status"
    if [ -L /etc/resolv.conf ]; then
        echo "Symlink: /etc/resolv.conf -> $(readlink -f /etc/resolv.conf)"
    else
        echo "/etc/resolv.conf is a regular file"
    fi

    echo
    print_header "Current resolv.conf contents"
    echo "----------------------------"
    cat /etc/resolv.conf || true
    echo "----------------------------"
}

show_active_dns() {
    print_header "Active DNS (per interface)"

    if command -v resolvectl >/dev/null 2>&1; then
        resolvectl status || true
        return
    fi

    print_warn "resolvectl not found, showing /etc/resolv.conf:"
    cat /etc/resolv.conf || true
}

nm_set_dns_auto() {
    if ! command -v nmcli >/dev/null 2>&1; then
        print_err "nmcli not found. Install NetworkManager."
        return
    fi

    local CONN
    CONN="$(get_active_nm_connection)"

    if [[ -z "${CONN// /}" ]]; then
        print_err "No active internet connection found."
        print_warn "Check with: nmcli connection show --active"
        return
    fi

    print_header "Set custom DNS"
    print_ok "Active connection detected: ${CONN}"

    read -rp "Enter DNS servers (comma separated) e.g. 1.1.1.1,8.8.8.8 : " DNS
    read -rp "Optional: DNS search domain (leave empty if none): " SEARCH

    # Replace commas with spaces as nmcli prefers space-separated lists
    DNS_FORMATTED="${DNS//,/ }"

    if [[ -z "${DNS_FORMATTED// /}" ]]; then
        print_err "DNS input cannot be empty."
        return
    fi

    ensure_sudo
    print_ok "Applying DNS to: $CONN"
    sudo nmcli connection modify "$CONN" ipv4.ignore-auto-dns yes
    sudo nmcli connection modify "$CONN" ipv4.dns "$DNS_FORMATTED"

    if [[ -n "${SEARCH// /}" ]]; then
        sudo nmcli connection modify "$CONN" ipv4.dns-search "$SEARCH"
    fi

    print_ok "Reconnecting..."
    sudo nmcli connection down "$CONN" >/dev/null 2>&1 || true
    sudo nmcli connection up "$CONN" >/dev/null 2>&1 || true

    print_ok "Done. Current DNS:"
    show_active_dns
}

nm_reset_dns_auto() {
    if ! command -v nmcli >/dev/null 2>&1; then
        print_err "nmcli not found."
        return
    fi

    local CONN
    CONN="$(get_active_nm_connection)"

    if [[ -z "${CONN// /}" ]]; then
        print_err "No active NetworkManager connection found."
        return
    fi

    ensure_sudo
    print_header "Reset DNS back to automatic (DHCP)"
    print_ok "Active connection: $CONN"

    sudo nmcli connection modify "$CONN" ipv4.ignore-auto-dns no
    sudo nmcli connection modify "$CONN" ipv4.dns ""
    sudo nmcli connection modify "$CONN" ipv4.dns-search ""

    print_ok "Reconnecting..."
    sudo nmcli connection down "$CONN" >/dev/null 2>&1 || true
    sudo nmcli connection up "$CONN" >/dev/null 2>&1 || true

    print_ok "Reset done."
}

hosts_add_entry() {
    print_header "Add custom domain -> IP entry (/etc/hosts)"

    read -rp "Enter IP address (example 127.0.0.1): " IP
    read -rp "Enter domain name (example example.local): " DOMAIN

    if [[ -z "${IP// /}" || -z "${DOMAIN// /}" ]]; then
        print_err "IP and DOMAIN cannot be empty."
        return
    fi

    # Basic IP validation (IPv4)
    if [[ ! $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_warn "The IP provided does not look like a standard IPv4 address. Proceeding anyway."
    fi

    if grep -qE "^[[:space:]]*${IP}[[:space:]]+${DOMAIN}([[:space:]]|\$)" /etc/hosts; then
        print_warn "Entry already exists in /etc/hosts."
        return
    fi

    ensure_sudo
    print_ok "Adding: $IP $DOMAIN"
    echo "$IP $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
    print_ok "Added!"
}

menu() {
    clear
    echo -e "${CYAN}===================================${RESET}"
    echo -e "${CYAN}       DNS Tool (Linux)     ${RESET}"
    echo -e "${CYAN}===================================${RESET}"
    echo "1) Show DNS provider + resolv.conf"
    echo "2) Show active DNS servers"
    echo "3) Set custom DNS (auto active connection)"
    echo "4) Reset DNS to automatic (auto active connection)"
    echo "5) Add custom domain->IP entry (/etc/hosts)"
    echo "0) Exit"
    echo
    read -rp "Choose an option: " CHOICE
    echo

    case "$CHOICE" in
        1) show_dns_provider ;;
        2) show_active_dns ;;
        3) nm_set_dns_auto ;;
        4) nm_reset_dns_auto ;;
        5) hosts_add_entry ;;
        0) echo "Exiting..."; exit 0 ;;
        *) print_err "Invalid option" ;;
    esac

    echo
    read -rp "Press Enter to return to the menu..."
}

# Main Loop
while true; do
    menu
done
