 #!/bin/bash

# Set the framework name
FRAMEWORK_NAME="Paddle.framework"

# Array to store unique app names
APP_NAMES=()

# Function to search for the framework in an app
search_framework() {
    local APP_PATH="$1"
    local APP_NAME=$(basename "$APP_PATH" .app)
   
    if [ -d "$APP_PATH/Contents/Frameworks/$FRAMEWORK_NAME" ]; then
        # Check if the app name already exists in the array
        if [[ ! " ${APP_NAMES[@]} " =~ " ${APP_NAME} " ]]; then
            APP_NAMES+=("$APP_NAME")
        fi
    fi
}

# Common folders to search within
COMMON_FOLDERS=(
    "/Applications"
    "/Users/$(whoami)/Applications"
    # Add more directories as needed
)

# Search for apps containing the framework in common folders
for FOLDER in "${COMMON_FOLDERS[@]}"; do
    echo "Searching in: $FOLDER"
    while IFS= read -r -d '' FILE; do
        if [[ "$FILE" == *.app ]]; then
            search_framework "$FILE"
        fi
    done < <(find "$FOLDER" -name "*.app" -print0 2>/dev/null)
done

# Check if any apps containing the framework were found
if [ ${#APP_NAMES[@]} -eq 0 ]; then
    echo "No apps containing the framework $FRAMEWORK_NAME were found in the specified folders."
else
    echo "Apps containing the framework $FRAMEWORK_NAME in the specified folders:"
    for APP_NAME in "${APP_NAMES[@]}"; do
        echo "$APP_NAME"
    done
fi