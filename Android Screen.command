#!/bin/bash
# Double-click in Finder, or run from Terminal with --help.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
cd "$(dirname "$0")"
CONFIG_FILE="$HOME/Library/Application Support/Android Screen/phone-address"
fail() { echo "$*" >&2; exit 1; }
help() {
cat <<'HELP'
Android Screen.command [usb|prepare|remote|stop|devices|configure] [phone-IP:port]
Mouse and keyboard use physical input simulation. Left Option releases the mouse.
  usb      Mirror the single USB phone (default quality, mouse and keyboard).
  prepare  Enable ADB on port 5555 through an authorized USB connection.
  remote   Connect and mirror a phone using its Tailscale or local Wi-Fi IP.
  stop     Return the connected remote phone to USB-only debugging.
  devices  Show devices and their authorization status.
  configure  Save or change this Mac's phone address.
The first wireless connection asks for an address and saves it in:
  ~/Library/Application Support/Android Screen/phone-address
Later connections reuse it. Command-line addresses are temporary overrides.
For remote: enable Tailscale on both devices or use trusted local Wi-Fi.
Prepare requires USB debugging and approval on the phone. Repeat after reboot.
Port 5555 may also be reachable on the phone's local network. Use stop when done.
For Android Wireless debugging with pairing, use adb pair IP:PAIRING_PORT first,
then use remote with IP:CONNECTION_PORT (the two ports are different).
HELP
}
normalize_endpoint() {
  local value="$1" port
  [[ "$value" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*(:[0-9]+)?$ ]] || fail "Enter a phone IPv4 address or hostname, optionally followed by :port."
  if [[ "$value" == *:* ]]; then
    port="${value##*:}"
    [[ ${#port} -le 5 ]] || fail "Port must be between 1 and 65535."
    (( 10#$port >= 1 && 10#$port <= 65535 )) || fail "Port must be between 1 and 65535."
  else
    value="$value:5555"
  fi
  printf '%s' "$value"
}
save_endpoint() {
  local value="$1"
  (
    umask 077
    mkdir -p "$(dirname "$CONFIG_FILE")" || exit 1
    printf '%s\n' "$value" > "$CONFIG_FILE" || exit 1
    chmod 600 "$CONFIG_FILE"
  ) || fail "Could not save the phone address to $CONFIG_FILE"
}
configure_endpoint() {
  local value="${1:-}"
  if [[ -z "$value" ]]; then
    read -r -p "Phone Tailscale IP or hostname (optionally :port): " value || fail "No address entered."
  fi
  value=$(normalize_endpoint "$value") || return $?
  save_endpoint "$value" || return $?
  printf '%s' "$value"
}
endpoint() {
  local value="${1:-}"
  if [[ -n "$value" ]]; then
    # A command-line override applies only to this connection.
    normalize_endpoint "$value"
  elif [[ -f "$CONFIG_FILE" ]]; then
    value=$(cat "$CONFIG_FILE") || fail "Could not read $CONFIG_FILE"
    normalize_endpoint "$value"
  else
    configure_endpoint
  fi
}
connect_phone() {
  local result
  result=$(adb connect "$1" 2>&1) || fail "$result"
  echo "$result"
  [[ "$(adb -s "$1" get-state 2>/dev/null)" == device ]] || fail "Phone unavailable. Check Tailscale and the saved address (option 6). After a phone restart, reconnect USB and choose option 2, then option 3."
}
main() {
  local mode="${1:-}" target
  case "$mode" in --help|-h) help; return;; esac
  command -v adb >/dev/null || fail "Android tools missing. Install: brew install --cask android-platform-tools"
  command -v scrcpy >/dev/null || fail "scrcpy missing. Install: brew install scrcpy"
  if [[ -z "$mode" ]]; then
    echo "Android Screen"
    echo "Press left Option to release the mouse back to your Mac."
    echo "1) Mirror via USB"
    echo "2) Enable wireless access via USB (port 5555)"
    echo "3) Mirror via Tailscale or Wi-Fi"
    echo "4) Turn off wireless ADB (return to USB)"
    echo "5) Show connected phones"
    echo "6) Set or change saved phone address"
    read -r -p "Choose [1]: " mode
  fi
  case "$mode" in
    1|usb|'') scrcpy --select-usb --mouse=uhid --keyboard=uhid --max-size=1280 --max-fps=30 --video-bit-rate=3M ;;
    2|prepare)
      echo "Unlock your phone and approve USB debugging."
      adb -d get-state >/dev/null || fail "Connect exactly one authorized USB phone first."
      adb -d tcpip 5555 || return $?
      echo "Wireless ADB enabled on port 5555. You can unplug USB."
      echo "Turn on Tailscale on the phone for remote access, then choose option 3."
      echo "Choose option 4 when finished to disable wireless ADB."
      ;;
    3|remote)
      target=$(endpoint "${2:-}") || return $?
      connect_phone "$target"
      scrcpy --serial="$target" --mouse=uhid --keyboard=uhid --max-size=1280 --max-fps=30 --video-bit-rate=3M
      ;;
    4|stop)
      target=$(endpoint "${2:-}") || return $?
      connect_phone "$target"
      adb -s "$target" usb || return $?
      adb disconnect "$target" || true
      ;;
    5|devices) adb devices -l ;;
    6|configure)
      target=$(configure_endpoint "${2:-}") || return $?
      echo "Phone address saved on this Mac."
      ;;
    *) help; return 1 ;;
  esac
}
# Finder launches .command files in Terminal. Leave errors visible there.
if [[ $# -eq 0 ]]; then
  if main; then status=0; else status=$?; fi
  read -r -p "Press Return to close…" ignored || true
  exit "$status"
else
  main "$@"
fi
