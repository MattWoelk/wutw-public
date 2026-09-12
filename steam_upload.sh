#/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOCAL_CONFIG=".env.local"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
else
    read -p "Please enter your Steam account name: " STEAM_ACCOUNT
fi

if [ $# -eq 0 ]; then
    VDF="$SCRIPT_DIR/wutw.vdf"
else
    VDF="`pwd`/${1}"
fi

if [ "$(uname)" == "Darwin" ]; then
    steamworks_sdk/tools/ContentBuilder/builder_osx/steamcmd +login "$STEAM_ACCOUNT" +run_app_build "$VDF" +quit
else
    "$SCRIPT_DIR/steamworks_sdk/tools/ContentBuilder/builder/steamcmd.exe" +login "$STEAM_ACCOUNT" +run_app_build "$VDF" +quit
fi
