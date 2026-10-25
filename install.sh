#!/bin/sh
# Installs mnem0nic, persistent memory for Claude Code and Codex.
#   curl -fsSL https://raw.githubusercontent.com/datashard-ai/mnem0nic/main/install.sh | sh
# MNEM0NIC_VERSION pins a version (for example 0.1.1).
# MNEM0NIC_INSTALL_DIR sets the folder (default: ~/.local/bin).
set -eu

REPO="datashard-ai/mnem0nic"
DIR="${MNEM0NIC_INSTALL_DIR:-$HOME/.local/bin}"

say() { printf '%s\n' "$*"; }
fail() {
  printf 'mnem0nic: %s\n' "$*" >&2
  exit 1
}

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
  *) fail "$os on $arch is not supported yet. mnem0nic runs on Macs with Apple silicon." ;;
esac

command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v shasum >/dev/null 2>&1 || fail "shasum is required."

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
(cd "$tmp" && shasum -a 256 -c "$asset.sha256" >/dev/null 2>&1) \
  || fail "the checksum does not match: the download is not the published file."
tar -xzf "$tmp/$asset" -C "$tmp" mnem0nic || fail "could not unpack $asset."

mkdir -p "$DIR"
install -m 0755 "$tmp/mnem0nic" "$DIR/mnem0nic"
version=$("$DIR/mnem0nic" --version 2>/dev/null) || fail "the installed program does not run."

say "Installed $version in $DIR"
case ":$PATH:" in
  *":$DIR:"*) ;;
  *)
    say ""
    say "$DIR is not on your PATH. Add it, then open a new terminal:"
    say "  echo 'export PATH=\"$DIR:\$PATH\"' >> ~/.zshrc"
    ;;
esac
say ""
say "Next, set it up for Claude Code and Codex:"
say "  mnem0nic install"
say ""
say "mnem0nic is proprietary software. Use is subject to its licence:"
say "  https://github.com/$REPO/blob/main/LICENSE.md"
