#/bin/bash

# Print usage if run with no args.
if [ $# -eq 0 ]; then
    echo "Usage: $0 [--win_demo] [--win_full] [--linux_demo] [--linux_full] [--all] [--debug] [--nobuild]"
    exit
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GODOT_EXE="/d/Godot/Godot_4.7/Godot_v4.7-stable_win64.exe"
PROJECT_DIR="$SCRIPT_DIR/wutw"
EXTENSION_DIR="$SCRIPT_DIR/wutw-gdext"

# Choose tasks.
DO_WIN_DEMO=false
DO_WIN_FULL=false
DO_LINUX_DEMO=false
DO_LINUX_FULL=false
BUILD_WIN_EXT=false
BUILD_LINUX_EXT=false
SKIP_BUILD=false
EXPORT_TYPE_FLAG='--export-release'
for arg in "$@"; do
  case $arg in
    --win_demo)
      DO_WIN_DEMO=true
      BUILD_WIN_EXT=true
      ;;
    --win_full)
      DO_WIN_FULL=true
      BUILD_WIN_EXT=true
      ;;
    --linux_demo)
      DO_LINUX_DEMO=true
      BUILD_LINUX_EXT=true
      ;;
    --linux_full)
      DO_LINUX_FULL=true
      BUILD_LINUX_EXT=true
      ;;
    --debug)
      EXPORT_TYPE_FLAG='--export-debug'
      ;;
    --nobuild)
      SKIP_BUILD=true
      ;;
    --all)
      DO_WIN_DEMO=true
      DO_WIN_FULL=true
      DO_LINUX_DEMO=true
      DO_LINUX_FULL=true
      BUILD_WIN_EXT=true
      BUILD_LINUX_EXT=true
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

if $SKIP_BUILD; then
  BUILD_WIN_EXT=false
  BUILD_LINUX_EXT=false
fi

# Define tasks.
build_win_lib() {
  cd "$EXTENSION_DIR"
  cmd.exe //c "build_win.bat"
  cd - > /dev/null
}
build_linux_lib() {
  cd "$EXTENSION_DIR"
  wsl.exe scons platform=linux target=template_release -j 16
  wsl.exe scons platform=linux target=template_debug -j 16
  cd - > /dev/null
}
export_binary() {
  local export_preset="$1"
  local export_dir="$2"
  local export_extension="$3"
  rm -r "$SCRIPT_DIR/builds/$export_dir"
  mkdir -p "$SCRIPT_DIR/builds/$export_dir"
  "$GODOT_EXE" \
      --headless \
      --path "$PROJECT_DIR" \
      $EXPORT_TYPE_FLAG "$export_preset" \
      "$SCRIPT_DIR/builds/$export_dir/Worlds Upon the Wind.$export_extension"

  if [[ "$export_dir" == linux_* ]]; then
      cp -r "$SCRIPT_DIR/default_steam_deck_input_config.vdf" "$SCRIPT_DIR/builds/$export_dir/default_steam_deck_input_config.vdf"
      cp -r "$SCRIPT_DIR/steam_deck_input_manifest.vdf" "$SCRIPT_DIR/builds/$export_dir/steam_deck_input_manifest.vdf"
  fi
}

# Run tasks.
{ $BUILD_WIN_EXT && build_win_lib; } || :
{ $BUILD_LINUX_EXT && build_linux_lib; } || :
{ $DO_WIN_DEMO && export_binary 'Windows Demo' win_demo exe; } || :
{ $DO_WIN_FULL && export_binary 'Windows' win_full exe; } || :
{ $DO_LINUX_DEMO && export_binary 'Linux Demo' linux_demo x86_64; } || :
{ $DO_LINUX_FULL && export_binary 'Linux' linux_full x86_64; } || :
