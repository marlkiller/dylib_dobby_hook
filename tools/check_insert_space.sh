#!/bin/bash

# ============================================================
#  check_insert_space.sh
#  Check if a Mach-O binary has enough space for insert_dylib injection
#
#  Usage:
#    ./check_insert_space.sh <binary_path> [dylib_path]
#
#  Arguments:
#    binary_path   Absolute path to the target binary (required)
#    dylib_path    Path to the dylib to be injected (optional, used for precise space calculation)
#
#  Examples:
#    ./check_insert_space.sh '/usr/bin/zip'
#    ./check_insert_space.sh '/Applications/App.app/Contents/MacOS/App' '@rpath/libdylib_dobby_hook.dylib'
# ============================================================


BINARY="$1"
DYLIB_PATH="${2:-@rpath/libdylib_dobby_hook.dylib}"

# ── ANSI COLORS ───────────────────────────────
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'

# ── argument check ────────────────────────────
[ -z "$BINARY" ] && echo "Usage: $0 <binary> [dylib_path]" && exit 1
[ ! -f "$BINARY" ] && echo "File not found" && exit 1

# ── dylib name validation ─────────────────────
DYLIB_NAME=$(basename "$DYLIB_PATH")
if [[ ! "$DYLIB_NAME" == *.dylib ]]; then
    echo -e "${RED}Error: Dylib name must end with .dylib${NC}"
    echo "  Got: $DYLIB_NAME"
    exit 1
fi

PAD=34

print_kv() {
    printf "  ${BLUE}│${NC}  %-${PAD}s %b\n" "$1" "$2"
}

# ── size calculation ──────────────────────────
LC_HEADER_BYTES=24
PATH_LEN=${#DYLIB_PATH}
RAW_SIZE=$((LC_HEADER_BYTES + PATH_LEN + 1))
REQUIRED_SIZE=$(( (RAW_SIZE + 7) / 8 * 8 ))

# ── arch detection ────────────────────────────
ARCHES=$(lipo -info "$BINARY" 2>/dev/null | grep -oE 'arm64|x86_64' || echo "native")

echo ""
echo -e "${BOLD}Binary:${NC} $BINARY"
echo -e "${BOLD}Dylib:${NC}  $DYLIB_PATH"
echo -e "${BOLD}Required space:${NC} $REQUIRED_SIZE bytes"
echo ""

OVERALL_STATUS="INJECTABLE"

for ARCH in $ARCHES; do
    echo -e "${BLUE}  ┌─ Arch: $ARCH ─────────────────────────────────${NC}"

    HEADER_LINE=$(otool -h -arch "$ARCH" "$BINARY" | grep -E '^[[:space:]]*0x')
    SIZEOFCMDS=$(echo "$HEADER_LINE" | awk '{print $7}')
    HEADER_SIZE=32

    FIRST=$(otool -l -arch "$ARCH" "$BINARY" | awk '/offset/ {print $2; exit}')

    LC_END=$((HEADER_SIZE + SIZEOFCMDS))
    AVAILABLE=$((FIRST - LC_END))

    # ── path support detection ─────────────────
    HAS_RPATH=false
    HAS_LOADER=false
    HAS_EXEC=false

    otool -l -arch "$ARCH" "$BINARY" | grep -q LC_RPATH && HAS_RPATH=true
    otool -L -arch "$ARCH" "$BINARY" | grep -q "@loader_path" && HAS_LOADER=true
    otool -L -arch "$ARCH" "$BINARY" | grep -q "@executable_path" && HAS_EXEC=true

    echo ""

    print_kv "Mach-O Header" "${HEADER_SIZE} bytes"
    print_kv "sizeofcmds" "${SIZEOFCMDS} bytes"
    print_kv "LC end offset" "fat+${LC_END}"
    print_kv "First section offset" "fat+${FIRST}"

    echo ""

    print_kv "Available space" "${AVAILABLE} bytes"
    print_kv "Required space" "${REQUIRED_SIZE} bytes"

    echo ""

    echo -e "  ${BLUE}│${NC}  ${BOLD}Path support (actual check):${NC}"

    if $HAS_RPATH; then
        print_kv "@rpath" "${GREEN}YES (LC_RPATH exists)${NC}"
    else
        print_kv "@rpath" "${RED}NO (missing LC_RPATH)${NC}"
    fi

    if $HAS_LOADER; then
        print_kv "@loader_path usage" "${GREEN}FOUND${NC}"
    else
        print_kv "@loader_path usage" "${YELLOW}not used${NC}"
    fi

    if $HAS_EXEC; then
        print_kv "@executable_path usage" "${GREEN}FOUND${NC}"
    else
        print_kv "@executable_path usage" "${YELLOW}not used${NC}"
    fi

    echo ""

    # ── usage examples (using actual dylib name) ──
    echo -e "  ${BLUE}│${NC}  ${BOLD}Usage examples:${NC}"

    print_kv "@loader_path" "@loader_path/${DYLIB_NAME}"
    print_kv "@executable_path" "@executable_path/../Frameworks/${DYLIB_NAME}"

    if $HAS_RPATH; then
        print_kv "@rpath" "@rpath/${DYLIB_NAME}"
    else
        print_kv "@rpath" "${RED}NOT available${NC}"
    fi

    echo ""

    # ── per-arch conclusion ────────────────────
    if [ "$AVAILABLE" -ge "$REQUIRED_SIZE" ]; then
        print_kv "Space check" "${GREEN}PASS${NC}"
    else
        print_kv "Space check" "${RED}FAIL (missing $((REQUIRED_SIZE-AVAILABLE)) bytes)${NC}"
        OVERALL_STATUS="NOT INJECTABLE"
    fi

    echo -e "${BLUE}  └────────────────────────────────────────────────${NC}"
    echo ""
done

# ── FINAL CONCLUSION ───────────────────────────
echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
if [ "$OVERALL_STATUS" == "INJECTABLE" ]; then
    echo -e "  ${GREEN}✓ CONCLUSION:${NC} ${BOLD}INJECTABLE${NC} — Sufficient space available for all architectures."
else
    echo -e "  ${RED}✗ CONCLUSION:${NC} ${BOLD}NOT INJECTABLE${NC} — At least one architecture lacks required space."
fi
echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
echo ""