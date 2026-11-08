#!/bin/sh
# Installs mnem0nic, persistent memory for Claude Code and Codex.
#   curl -fsSL https://raw.githubusercontent.com/datashard-ai/mnem0nic/main/install.sh | sh
# MNEM0NIC_VERSION pins a version (for example 0.1.1).
# MNEM0NIC_INSTALL_DIR sets the folder (default: ~/.local/bin).
# --system (Linux on aarch64 or x86_64, as root) installs the systemd service instead:
#   curl -fsSL https://raw.githubusercontent.com/datashard-ai/mnem0nic/main/install.sh | sudo sh -s -- --system
set -eu

REPO="datashard-ai/mnem0nic"
DIR="${MNEM0NIC_INSTALL_DIR:-$HOME/.local/bin}"

say() { printf '%s\n' "$*"; }
fail() {
  printf 'mnem0nic: %s\n' "$*" >&2
  exit 1
}

system=0
case "${1:-}" in
  --system) system=1 ;;
  "") ;;
  *) fail "unknown option: $1 (only --system is supported)." ;;
esac

os=$(uname -s)
arch=$(uname -m)
case "$os/$arch" in
  Darwin/arm64) target="aarch64-apple-darwin" ;;
  Darwin/x86_64)
    # A Terminal running under Rosetta reports x86_64 on Apple silicon.
    if [ "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" = "1" ]; then
      target="aarch64-apple-darwin"
    else
      fail "Intel Macs are not supported yet. mnem0nic needs a Mac with Apple silicon."
    fi
    ;;
  Linux/aarch64) target="aarch64-unknown-linux-gnu" ;;
  Linux/x86_64) target="x86_64-unknown-linux-gnu" ;;
  Linux/*) fail "Linux on $arch is not supported yet. mnem0nic on Linux needs aarch64 or x86_64." ;;
  *) fail "$os on $arch is not supported yet. mnem0nic runs on Macs with Apple silicon, or on Linux on aarch64 or x86_64." ;;
esac

if [ "$target" = "x86_64-unknown-linux-gnu" ] && [ "$system" != 1 ]; then
  fail "on Linux x86_64 only the memory service is supported: install it with --system (curl -fsSL <url> | sudo sh -s -- --system). The personal tool needs a Mac with Apple silicon."
fi

if [ "$system" = 1 ]; then
  [ "$os" = Linux ] || fail "--system needs Linux on aarch64 or x86_64; on a Mac install per user."
  [ "$(id -u)" = 0 ] || fail "--system must run as root: curl -fsSL <url> | sudo sh -s -- --system"
  DIR="/usr/local/bin"
fi

command -v curl >/dev/null 2>&1 || fail "curl is required."
case "$os" in
  Darwin)
    command -v shasum >/dev/null 2>&1 || fail "shasum is required."
    sha_cmd="shasum -a 256"
    ;;
  Linux)
    command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required."
    sha_cmd="sha256sum"
    ;;
esac

asset="mnem0nic-$target.tar.gz"
if [ -n "${MNEM0NIC_VERSION:-}" ]; then
  url="https://github.com/$REPO/releases/download/v${MNEM0NIC_VERSION#v}/$asset"
else
  url="https://github.com/$REPO/releases/latest/download/$asset"
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

say "Downloading $asset"
curl -fsSL --proto '=https' --tlsv1.2 -o "$tmp/$asset" "$url" \
  || fail "the download failed: $url"
curl -fsSL --proto '=https' --tlsv1.2 -o "$tmp/$asset.sha256" "$url.sha256" \
  || fail "the checksum download failed: $url.sha256"
(cd "$tmp" && $sha_cmd -c "$asset.sha256" >/dev/null 2>&1) \
  || fail "the checksum does not match: the download is not the published file."
tar -xzf "$tmp/$asset" -C "$tmp" mnem0nic || fail "could not unpack $asset."

mkdir -p "$DIR"
install -m 0755 "$tmp/mnem0nic" "$DIR/mnem0nic"
version=$("$DIR/mnem0nic" --version 2>/dev/null) || fail "the installed program does not run."

if [ "$system" = 1 ]; then
  # The unit below mirrors public/systemd/mnem0nic.service; install.sh stays
  # self-contained so the release tarball keeps holding only the binary.
  id -u mnem0nic >/dev/null 2>&1 \
    || useradd --system --home /var/lib/mnem0nic --shell /usr/sbin/nologin mnem0nic
  # useradd makes no home folder: the store's folder must exist, and be the service user's, before
  # the search model is downloaded as that user (step 3 below).
  install -d -m 0700 -o mnem0nic /var/lib/mnem0nic
  mkdir -p /etc/mnem0nic
  if [ ! -f /etc/mnem0nic/env ]; then
    (
      umask 077
      {
        echo "# mnem0nic daemon environment: uncomment and fill, then start (or restart) the service."
        echo "#MNEM0NIC_HTTP_TOKEN="
        echo "#MNEM0NIC_OBSERVER_API_KEY="
        echo "#MNEM0NIC_OBSERVER_API_BASE_URL="
      } > /etc/mnem0nic/env
    )
  fi
  # An upgrade of a running service is restarted on the new binary; a fresh install is enabled but
  # not started, so it does not run unconfigured now. It is enabled, though: after a reboot it
  # starts whether or not /etc/mnem0nic/env is filled in; with the door configured and no token
  # the daemon exits, and systemd restarts it every 5 s (RestartSec) until the token is set.
  was_active=0
  if systemctl is-active --quiet mnem0nic 2>/dev/null; then
    was_active=1
  fi
  cat > "$tmp/mnem0nic.service" <<'UNIT'
[Unit]
Description=mnem0nic memory daemon
After=network-online.target
Wants=network-online.target

[Service]
User=mnem0nic
StateDirectory=mnem0nic
EnvironmentFile=/etc/mnem0nic/env
ExecStart=/usr/local/bin/mnem0nic --home /var/lib/mnem0nic daemon serve
# Always: the daemon exits 0 even after a worker error, and when a client replaces a build.
Restart=always
RestartSec=5
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/lib/mnem0nic
ProtectHome=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
UNIT
  install -m 0644 "$tmp/mnem0nic.service" /etc/systemd/system/mnem0nic.service
  systemctl daemon-reload
  systemctl enable mnem0nic

  if [ "$was_active" = 1 ]; then
    systemctl restart mnem0nic
    say "Installed $version in $DIR; the running mnem0nic service was restarted on it."
  else
    say "Installed $version in $DIR, with the mnem0nic systemd service (enabled, not started)."
    say ""
    say "Next:"
    say "  1. Fill /etc/mnem0nic/env (door token, observer key) - it is mode 0600."
    say "  2. Configure /var/lib/mnem0nic/config.toml: [http] listen and project, [observer] api_base_url and model."
    say "  3. Download the search model, as the service user:"
    say "       sudo -u mnem0nic /usr/local/bin/mnem0nic --home /var/lib/mnem0nic embed"
    say "  4. systemctl start mnem0nic"
  fi
  say ""
  say "mnem0nic is proprietary software. Use is subject to its licence:"
  say "  https://github.com/$REPO/blob/main/LICENSE.md"
  exit 0
fi

say "Installed $version in $DIR"
case ":$PATH:" in
  *":$DIR:"*) ;;
  *)
    say ""
    say "$DIR is not on your PATH. Add it, then open a new terminal:"
    if [ "$os" = Darwin ]; then
      say "  echo 'export PATH=\"$DIR:\$PATH\"' >> ~/.zshrc"
    else
      say "  echo 'export PATH=\"$DIR:\$PATH\"' >> ~/.profile"
    fi
    ;;
esac
say ""
say "Next, set it up for Claude Code and Codex:"
say "  mnem0nic install"
say ""
say "mnem0nic is proprietary software. Use is subject to its licence:"
say "  https://github.com/$REPO/blob/main/LICENSE.md"
