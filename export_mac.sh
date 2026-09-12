#/bin/bash

# Print usage if run with no args.
if [ $# -eq 0 ]; then
    echo "Usage: $0 [--demo] [--full] [--all] [--debug]"
    exit
fi


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GODOT_EXE=~/Godot.app/Contents/MacOS/Godot
PROJECT_DIR="$SCRIPT_DIR/wutw"
EXTENSION_DIR="$SCRIPT_DIR/wutw-gdext"

ACCOUNT_EMAIL=max99x@gmail.com
TEAM_ID=DN45U265PJ
APPLE_PWD=$(cat $SCRIPT_DIR/wutw/.godot/export_credentials.cfg | grep -o -E '[a-z]{4}-[a-z]{4}-[a-z]{4}-[a-z]{4}' | head -n 1)

# Choose tasks.
DO_DEMO=false
DO_FULL=false
BUILD_EXT=false
EXPORT_TYPE_FLAG='--export-release'
for arg in "$@"; do
  case $arg in
    --demo)
      DO_DEMO=true
      BUILD_EXT=true
      ;;
    --full)
      DO_FULL=true
      BUILD_EXT=true
      ;;
    --all)
      DO_DEMO=true
      DO_FULL=true
      BUILD_EXT=true
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

# Define tasks.
build_lib() {
  cd "$EXTENSION_DIR"
  scons platform=macos target=template_release -j 16
  scons platform=macos target=template_debug -j 16
  cd - > /dev/null
}
export_binary() {
  local export_preset="$1"
  local export_dir="$2"
  rm -r "$SCRIPT_DIR/builds/$export_dir"
  mkdir -p "$SCRIPT_DIR/builds/$export_dir"
  $GODOT_EXE \
      --headless \
      --path "$PROJECT_DIR" \
      $EXPORT_TYPE_FLAG "$export_preset" \
      "$SCRIPT_DIR/builds/$export_dir/Worlds Upon the Wind.app"
  if [ $? -ne 0 ]; then
    echo "Godot export command failed."
    exit 1
  fi
  LATEST_UUID=$(xcrun notarytool history \
      --apple-id "$ACCOUNT_EMAIL" \
      --team-id "$TEAM_ID" \
      --password "$APPLE_PWD" \
         | grep -o -E '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' \
         | head -n 1)
  xcrun notarytool wait "$LATEST_UUID" \
      --apple-id "$ACCOUNT_EMAIL" \
      --password "$APPLE_PWD" \
      --team-id "$TEAM_ID"

  if [ $? -ne 0 ]; then
      echo "Notarization failed or was rejected."
      xcrun notarytool log "$LATEST_UUID" \
          --apple-id "$ACCOUNT_EMAIL" \
          --password "$APPLE_PWD" \
          --team-id "$TEAM_ID"
      exit 1
  fi

  xcrun stapler staple "$SCRIPT_DIR/builds/$export_dir/Worlds Upon the Wind.app"
}

# Run tasks.
{ $BUILD_EXT && build_lib; } || :
{ $DO_DEMO && export_binary 'macOS Demo' mac_demo; } || :
{ $DO_FULL && export_binary 'macOS' mac_full; } || :
