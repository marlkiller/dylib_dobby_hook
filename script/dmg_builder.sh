#!/bin/bash

# --- Configuration Variables ---
APP_NAME_ARG="$1" # Application name or path passed as a script argument
LINK_TARGET="/Applications" # Target path for the shortcut
LINK_NAME="Applications" # Shortcut name displayed inside the DMG

# --- Check if the argument is provided ---
if [ -z "$APP_NAME_ARG" ]; then
    echo "❌ Application name or path is required. Usage: ./dmg_builder.sh <APP_NAME_OR_PATH>"
    exit 1
fi

# --- Determine source path ---
if [[ "$APP_NAME_ARG" == *".app" ]]; then
    # User provided a full path to .app bundle
    APP_SOURCE_PATH="$APP_NAME_ARG"
    APP_NAME=$(basename "$APP_NAME_ARG" .app)
else
    # User provided just the application name
    APP_NAME="$APP_NAME_ARG"
    APP_SOURCE_PATH="/Applications/${APP_NAME}.app"
fi
DMG_VOLNAME="${APP_NAME}" # Volume name for the mounted DMG

# --- Check dependencies ---
if ! command -v hdiutil &> /dev/null; then
    echo "❌ 'hdiutil' is not installed. Please ensure this script is run on macOS."
    exit 1
fi

# --- Check if the application path exists ---
if [ ! -d "$APP_SOURCE_PATH" ]; then
    echo "❌ Application path does not exist: $APP_SOURCE_PATH"
    exit 1
fi

# --- Get application version ---
APP_VERSION=$(defaults read "${APP_SOURCE_PATH}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
if [ -z "$APP_VERSION" ]; then
    echo "❌ Failed to retrieve application version. Ensure the Info.plist file exists and is valid."
    exit 1
fi
echo "📦 Application: $APP_NAME | Version: $APP_VERSION | Source: $APP_SOURCE_PATH"

# --- Set DMG file names ---
DMG_OUTPUT_DIR=~/Downloads
DMG_TEMP_NAME="${DMG_OUTPUT_DIR}/${APP_NAME}_temp.dmg"
DMG_FINAL_NAME="${DMG_OUTPUT_DIR}/${APP_NAME}_${APP_VERSION}.dmg"

# --- Check if the target DMG file already exists ---
if [ -f "$DMG_FINAL_NAME" ]; then
    echo "⚠️ Target DMG file already exists: $DMG_FINAL_NAME"
    read -p "Do you want to overwrite it? (Y/N): " user_input
    if [[ "$user_input" != "Y" && "$user_input" != "y" ]]; then
        echo "❌ Operation canceled."
        exit 1
    fi
    echo "🗑️ Deleting existing DMG file: $DMG_FINAL_NAME"
    rm -f "$DMG_FINAL_NAME"
fi

# --- Automatically calculate DMG size ---
APP_SIZE=$(du -sh "$APP_SOURCE_PATH" | awk '{print $1}')
APP_SIZE_MB=$(du -sm "$APP_SOURCE_PATH" | awk '{print $1}')
DMG_SIZE=$(echo "$APP_SIZE_MB + 50" | bc)m # Add an extra 50MB of space
echo "📏 Application size: $APP_SIZE, calculated DMG size: $DMG_SIZE"

# --- Create temporary DMG ---
echo "📦 Creating temporary DMG file: $DMG_TEMP_NAME"
hdiutil create -size "$DMG_SIZE" -fs HFS+ -volname "$DMG_VOLNAME" "$DMG_TEMP_NAME" -ov

# --- Mount temporary DMG ---
echo "🔗 Mounting temporary DMG file: $DMG_TEMP_NAME"
MOUNT_DIR=$(hdiutil attach "$DMG_TEMP_NAME" | grep -o '/Volumes/.*')
if [ -z "$MOUNT_DIR" ]; then
    echo "❌ Failed to mount temporary DMG file."
    exit 1
fi
echo "📂 Mount point: $MOUNT_DIR"

# --- Copy application to DMG ---
echo "📂 Copying application to DMG: $APP_SOURCE_PATH -> $MOUNT_DIR"
cp -R "$APP_SOURCE_PATH" "$MOUNT_DIR"

# --- Create shortcut ---
echo "🔗 Creating shortcut: $LINK_NAME -> $LINK_TARGET"
ln -s "$LINK_TARGET" "$MOUNT_DIR/$LINK_NAME"

# --- Unmount temporary DMG ---
echo "🔒 Unmounting temporary DMG file: $MOUNT_DIR"
hdiutil detach "$MOUNT_DIR"
if [ $? -ne 0 ]; then
    echo "❌ Failed to unmount. Please manually unmount: $MOUNT_DIR"
    exit 1
fi

# --- Convert to final DMG ---
echo "🚀 Converting to final DMG file: $DMG_FINAL_NAME"
hdiutil convert "$DMG_TEMP_NAME" -format UDZO -o "$DMG_FINAL_NAME"

# --- Clean up temporary files ---
echo "🧹 Cleaning up temporary files: $DMG_TEMP_NAME"
rm -f "$DMG_TEMP_NAME"

echo "✅ DMG packaging completed: $DMG_FINAL_NAME"