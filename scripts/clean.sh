#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

rm -rf build \
       dist \
       .devcontainer/devcontainer.env \
       nsz/__pycache__ \
       nsz/Fs/__pycache__ \
       nsz/gui/__pycache__ \
       nsz/Nut/__pycache__
