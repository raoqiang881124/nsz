#!/usr/bin/env bash
#
# Automates the extraction of title keys for Nintendo Switch
# NSP/NSZ/XCI/XCZ dumps.
#
# IMPORTANT: Before proceeding, open this script in a text editor to adjust
# the settings below as needed.

set -u

# nsz executable path.
NszPath="$(dirname "$(readlink -f "$0")")/nsz"

# Source directory path where to search for NSP/XCI files.
SrcDirectoryPath="$HOME/dumps"

# 'true' to enable recursive NSP/XCI file search on source directory, 'false' to disable it.
EnableRecursiveSearch=false

# Additional nsz parameters.
AdditionalParameters=(--alwaysParseCnmt)

print_error_and_exit() {
	echo
	echo "ERROR OCCURRED: $*"
	echo
	exit 1
}

echo "╔══════════════════════════════════════════════════════╗"
echo "║ TITLE   │ Extract title keys Script                  ║"
echo "║_________│____________________________________________║"
echo "║         │ Automates the extraction of title keys for ║"
echo "║ PURPOSE │ Nintendo Switch NSP/NSZ/XCI/XCZ dumps.     ║"
echo "║_________│____________________________________________║"
echo "║ VERSION │ ElektroStudios - Ver. 1.2 'keep it simple' ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "IMPORTANT: Before proceeding, open this script in a text editor to adjust the following script settings as needed."
echo
echo " o nsz path:"
echo "   $NszPath"
echo
echo " o Source directory path where to search for NSP/NSZ/XCI/XCZ files:"
echo "   $SrcDirectoryPath"
echo
echo " o Enable recursive NSP/NSZ/XCI/XCZ file search on source directory:"
echo "   $EnableRecursiveSearch"
echo
echo " o Additional nsz parameters:"
echo "   ${AdditionalParameters[*]}"
echo
read -rp "Press [Enter] to continue..."

# Ensure nsz exists.
if ! command -v "$NszPath" >/dev/null 2>&1 && [[ ! -x "$NszPath" ]]; then
	print_error_and_exit "nsz file does not exist: \"$NszPath\""
fi

# Ensure the source directory exists.
if [[ ! -d "$SrcDirectoryPath" ]]; then
	print_error_and_exit "Source directory does not exist: \"$SrcDirectoryPath\""
fi

# Build file list.
if [[ "${EnableRecursiveSearch,,}" == "true" ]]; then
	mapfile -d '' -t Files < <(find "$SrcDirectoryPath" -type f \( -iname "*.nsp" -o -iname "*.xci" \) -print0)
else
	mapfile -d '' -t Files < <(find "$SrcDirectoryPath" -maxdepth 1 -type f \( -iname "*.nsp" -o -iname "*.xci" \) -print0)
fi

for File in "${Files[@]}"; do
	echo "Extracting title keys for \"$File\"..."
	echo
	"$NszPath" --info "$File" --titlekeys "${AdditionalParameters[@]}" \
		|| print_error_and_exit "nsz failed to parse file: \"$File\""
done

echo
echo "Operation Completed!"
echo
read -rp "Press [Enter] to exit..."
exit 0
