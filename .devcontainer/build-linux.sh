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

if $build_cli; then
	rm -rf dist/linux/nsz
	pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/linux dev/nsz-cli.spec
	echo "Linux CLI binary: dist/linux/nsz"
fi

if $build_gui; then
	rm -rf build dist/linux/nsz-gui
	# Kivy provider discovery can touch X11 paths during analysis; run under a
	# virtual display so headless container builds are consistent.
	xvfb-run -a pyinstaller --log-level "$PYI_LOG_LEVEL" --distpath dist/linux dev/nsz-gui.spec
	echo "Linux GUI binary: dist/linux/nsz-gui"
fi
