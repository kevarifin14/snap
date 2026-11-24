#!/bin/bash
set -euo pipefail

source_app=$1
installed=/Applications/Snap.app
requirement=$2

verify() { codesign --verify --strict -R="$requirement" "$1"; }
code_hash() { codesign -dv --verbose=4 "$1" 2>&1 | sed -n 's/^CDHash=//p'; }
designated_requirement() { codesign -d -r- "$1" 2>&1 | sed -n 's/^designated => //p'; }

verify "$source_app"
stage=$(mktemp -d /Applications/.snap-install.XXXXXXXX)
cleanup() {
    if [[ -d "$stage/Previous.app" && ! -e "$installed" ]]; then
        mv "$stage/Previous.app" "$installed" || return 1
    fi
    rm -rf "$stage"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

ditto "$source_app" "$stage/Snap.app"
verify "$stage/Snap.app"

if [[ -e "$installed" ]]; then
    if verify "$installed" 2>/dev/null; then
        if [[ $(code_hash "$installed") == "$(code_hash "$stage/Snap.app")" ]]; then
            echo "Verified unchanged $installed."
            exit 0
        fi
        if [[ $(designated_requirement "$installed") != "$(designated_requirement "$stage/Snap.app")" ]]; then
            echo 'The Snap update has a different designated requirement.' >&2
            exit 1
        fi
    fi
    if pgrep -f '^/Applications/Snap\.app/Contents/MacOS/Snap( |$)' >/dev/null; then
        echo 'Quit Snap before installing an update.' >&2
        exit 1
    fi
    mv "$installed" "$stage/Previous.app"
fi

mv "$stage/Snap.app" "$installed"
echo "Installed $installed."
