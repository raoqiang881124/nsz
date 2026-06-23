#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

build_cli=true
build_gui=true
case "${1:-}" in
	--cli) build_gui=false ;;
	--gui) build_cli=false ;;
	"") ;;
	*) echo "Usage: $0 [--cli|--gui]" >&2; exit 1 ;;
esac

source /opt/venv-linux/bin/activate
PYI_LOG_LEVEL="${PYI_LOG_LEVEL:-WARN}"

case "$(uname -m)" in
	x86_64) arch=x64 ;;
	aarch64 | arm64) arch=arm64 ;;
	*) echo "Error: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac
distpath="dist/linux-$arch"

if $build_cli; then
	rm -rf "$distpath/nsz"
	pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath "$distpath" dev/nsz-cli.spec
	echo "Linux CLI binary: $distpath/nsz"
fi

if $build_gui; then
	rm -rf build "$distpath/nsz-gui"
	# Kivy provider discovery can touch X11 paths during analysis; run under a
	# virtual display so headless container builds are consistent.
	xvfb-run -a pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath "$distpath" dev/nsz-gui.spec
	echo "Linux GUI binary: $distpath/nsz-gui"
fi
