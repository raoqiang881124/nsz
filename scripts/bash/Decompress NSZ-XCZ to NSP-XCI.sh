#!/usr/bin/env bash
#
# Automates the decompression of Nintendo Switch NSZ/XCZ dumps back into
# NSP/XCI format respectively.
#
# IMPORTANT: Before proceeding, open this script in a text editor to adjust
# the settings below as needed.

set -u

# nsz executable path.
NszPath="$(dirname "$(readlink -f "$0")")/nsz"

# Source directory path where to search for NSZ/XCZ files.
SrcDirectoryPath="$HOME/dumps"

# Destination directory path where to save decompressed NSP/XCI files.
DstDirectoryPath="$SrcDirectoryPath"

# 'true' to enable recursive NSZ/XCZ file search on source directory, 'false' to disable it.
EnableRecursiveSearch=false

# Additional nsz parameters.
AdditionalParameters=(--alwaysParseCnmt --undupe-rename --titlekeys --quick-verify)

print_error_and_exit() {
	echo
	echo "ERROR OCCURRED: $*"
	echo
	exit 1
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║ TITLE   │ Decompress NSZ/XCZ to NSP/XCI Script                 ║"
echo "║_________│______________________________________________________║"
echo "║         │ Automates the decompression of Nintendo Switch       ║"
echo "║ PURPOSE │ NSZ/XCZ dumps back into NSP/XCI format respectively. ║"
echo "║_________│______________________________________________________║"
echo "║ VERSION │ ElektroStudios - Ver. 1.2 'keep it simple'           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo
echo "IMPORTANT: Before proceeding, open this script in a text editor to adjust the following script settings as needed."
echo
echo " o nsz path:"
echo "   $NszPath"
echo
echo " o Source directory path where to search for NSZ/XCZ files:"
echo "   $SrcDirectoryPath"
echo
echo " o Destination directory path where to save decompressed NSP/XCI files:"
echo "   $DstDirectoryPath"
echo
echo " o Enable recursive NSZ/XCZ file search on source directory:"
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

# Ensure the output directory can be created.
mkdir -p "$DstDirectoryPath" || print_error_and_exit "Output directory can't be created: \"$DstDirectoryPath\""

# Build file list.
if [[ "${EnableRecursiveSearch,,}" == "true" ]]; then
	mapfile -d '' -t Files < <(find "$SrcDirectoryPath" -type f \( -iname "*.nsz" -o -iname "*.xcz" \) -print0)
else
	mapfile -d '' -t Files < <(find "$SrcDirectoryPath" -maxdepth 1 -type f \( -iname "*.nsz" -o -iname "*.xcz" \) -print0)
fi

for File in "${Files[@]}"; do
	echo "Decompressing \"$File\"..."
	echo
	"$NszPath" -D "$File" --output "$DstDirectoryPath" "${AdditionalParameters[@]}" \
		|| print_error_and_exit "nsz failed to decompress file: \"$File\""
done

echo
echo "Operation Completed!"
echo
read -rp "Press [Enter] to exit..."
exit 0
