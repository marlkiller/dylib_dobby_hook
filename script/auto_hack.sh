#!/bin/bash

if command -v python3 &>/dev/null; then
    echo "[*] Running auto_hack.py"
    python3 auto_hack.py
else
    echo "[*] Running Swift version auto_hack"
    chmod a+x auto_hack
    ./auto_hack
fi
