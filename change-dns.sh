#!/usr/bin/env bash
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

get_active_nm_connection() {
  # Returns active connection NAME (best method)
  nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | head -n1 | cut -d: -f1
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
    exit 1
  fi

  local CONN
  CONN="$(get_active_nm_connection)"

  if [[ -z "${CONN// /}" ]]; then
    print_err "No active NetworkManager connection found."
    print_warn "Check with: nmcli connection show --active"
    exit 1
  fi

  print_header "Set custom DNS (auto-detected active connection)"
  print_ok "Active connection detected: ${CONN}"

  read -rp "Enter DNS servers (comma separated) e.g. 1.1.1.1,8.8.8.8 : " DNS
  read -rp "Optional: DNS search domain (leave empty if none): " SEARCH

  print_ok "Applying DNS to: $CONN"
  nmcli connection modify "$CONN" ipv4.ignore-auto-dns yes
  nmcli connection modify "$CONN" ipv4.dns "$DNS"

  if [[ -n "${SEARCH// /}" ]]; then
    nmcli connection modify "$CONN" ipv4.dns-search "$SEARCH"
  fi

  print_ok "Reconnecting..."
  nmcli connection down "$CONN" >/dev/null 2>&1 || true
  nmcli connection up "$CONN" >/dev/null 2>&1 || true

  print_ok "Done. Current DNS:"
  show_active_dns
}

nm_reset_dns_auto() {
  if ! command -v nmcli >/dev/null 2>&1; then
    print_err "nmcli not found."
    exit 1
  fi

  local CONN
  CONN="$(get_active_nm_connection)"

  if [[ -z "${CONN// /}" ]]; then
    print_err "No active NetworkManager connection found."
    exit 1
  fi

  print_header "Reset DNS back to automatic (DHCP)"
  print_ok "Active connection: $CONN"

  nmcli connection modify "$CONN" ipv4.ignore-auto-dns no
  nmcli connection modify "$CONN" ipv4.dns ""
  nmcli connection modify "$CONN" ipv4.dns-search ""

  print_ok "Reconnecting..."
  nmcli connection down "$CONN" >/dev/null 2>&1 || true
  nmcli connection up "$CONN" >/dev/null 2>&1 || true

  print_ok "Reset done."
}

hosts_add_entry() {
  print_header "Add custom domain -> IP entry (/etc/hosts)"

  read -rp "Enter IP address (example 127.0.0.1): " IP
  read -rp "Enter domain name (example example.local): " DOMAIN

  if [[ -z "${IP// /}" || -z "${DOMAIN// /}" ]]; then
    print_err "IP and DOMAIN cannot be empty."
    exit 1
  fi

  if grep -qE "^[[:space:]]*${IP}[[:space:]]+${DOMAIN}([[:space:]]|\$)" /etc/hosts; then
    print_warn "Entry already exists."
    exit 0
  fi

  print_ok "Adding: $IP $DOMAIN"
  echo "$IP $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
  print_ok "Added!"
}

menu() {
  echo
  echo -e "${CYAN}DNS Tool (CachyOS)${RESET}"
  echo "1) Show DNS provider + resolv.conf"
  echo "2) Show active DNS servers"
  echo "3) Set custom DNS (auto active connection)"
  echo "4) Reset DNS to automatic (auto active connection)"
  echo "5) Add custom domain->IP entry (/etc/hosts)"
  echo "0) Exit"
  echo
  read -rp "Choose: " CHOICE

  case "$CHOICE" in
  1) show_dns_provider ;;
  2) show_active_dns ;;
  3) nm_set_dns_auto ;;
  4) nm_reset_dns_auto ;;
  5) hosts_add_entry ;;
  0) exit 0 ;;
  *) print_err "Invalid option" ;;
  esac
}

while true; do
  menu
done
