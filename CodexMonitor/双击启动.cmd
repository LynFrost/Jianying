@echo off
set "AHK=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if not exist "%AHK%" (
    echo AutoHotkey v2 not found. Install from https://www.autohotkey.com/
    pause
    exit /b 1
)
start "" "%AHK%" "%~dp0CodexMonitor.ahk"
