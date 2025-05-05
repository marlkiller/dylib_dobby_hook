
#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

current_path=$PWD
app_path="/Applications/Surge.app"


cp -f "$PWD/../tools/process_inject" "$app_path/Contents/MacOS/"
cp -f "$PWD/apps/surge/modules.json" "$app_path/Contents/MacOS/"
cp -f "$PWD/apps/surge/jsvm.js" "$app_path/Contents/MacOS/"
cp -f "$PWD/apps/surge/SurgeStarter_NE" "$app_path/Contents/MacOS/"
