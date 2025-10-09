#!/usr/bin/env bash
set -euo pipefail

# Allow overrides: PREFIX=/usr/local BIN_DIR=/usr/local/bin ./install.sh
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"

ROOT="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$BIN_DIR"

chmod +x "$ROOT/bin/samplem" "$ROOT/repack_interactive.zsh"

ln -sf "$ROOT/bin/samplem" "$BIN_DIR/samplem"
ln -sf "$ROOT/repack_interactive.zsh" "$BIN_DIR/repack_interactive.zsh"

echo "Installed: $BIN_DIR/samplem"
echo "If not found, add $BIN_DIR to your PATH."


