#/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "$SCRIPT_DIR/builds/win_demo/Worlds Upon the Wind.exe" -nt "$SCRIPT_DIR/builds/win_full/Worlds Upon the Wind.exe" ]]; then
    "$SCRIPT_DIR/builds/win_demo/Worlds Upon the Wind.console.exe" --remote-debug tcp://127.0.0.1:6007
else
    "$SCRIPT_DIR/builds/win_full/Worlds Upon the Wind.console.exe" --remote-debug tcp://127.0.0.1:6007
fi

