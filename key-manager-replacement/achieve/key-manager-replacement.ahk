#Requires AutoHotkey v2.0
#SingleInstance Force

; Replacement for the Key Manager profile shown in Snipaste_2026-07-03_16-36-36.png.
; Double-click this file to enable the mappings. Use the tray icon to pause or exit.

A_IconTip := "Key Manager replacement"
SendMode "Input"
SetKeyDelay -1, 20
SetMouseDelay -1

; ----------------------------
; Single-key mappings
; ----------------------------

Numpad9::Send "{LWin down}9{LWin up}"
Numpad8::Send "{LWin down}8{LWin up}"
Numpad7::Send "{LWin down}7{LWin up}"
Numpad6::Send "{LWin down}6{LWin up}"
Numpad4::Send "{LWin down}0{LWin up}"

Numpad5::{
    RunFirstExisting("flomo", [
        EnvGet("LOCALAPPDATA") "\Programs\flomo\flomo.exe",
        EnvGet("LOCALAPPDATA") "\Programs\Flomo\flomo.exe",
        "C:\Program Files\flomo\flomo.exe",
        "C:\Program Files\Flomo\flomo.exe",
        "C:\Program Files (x86)\flomo\flomo.exe"
    ], ["flomo.exe"])
}

Numpad2::{
    RunFirstExisting("Cherry Studio", [
        EnvGet("LOCALAPPDATA") "\Programs\Cherry Studio\Cherry Studio.exe",
        EnvGet("LOCALAPPDATA") "\Programs\cherry-studio\Cherry Studio.exe",
        "C:\Program Files\Cherry Studio\Cherry Studio.exe",
        "C:\Program Files (x86)\Cherry Studio\Cherry Studio.exe"
    ], ["Cherry Studio.exe", "CherryStudio.exe"])
}

Numpad1::{
    RunFirstExisting("Everything", [
        "C:\Program Files\Everything\Everything64.exe",
        "C:\Program Files\Everything\Everything.exe",
        "C:\Program Files (x86)\Everything\Everything.exe",
        EnvGet("ProgramData") "\Microsoft\Windows\Start Menu\Programs\Everything.lnk"
    ], ["Everything64.exe", "Everything.exe"])
}

; OEM 3 is usually the `~ key. OEM 2 is usually the /? key on a US keyboard.
SC029::Send "{RAlt down}{vkBF}{RAlt up}"

ScrollLock::Send "{WheelUp}"
Pause::Send "{WheelDown}"
PrintScreen::Send "{LWin down}d{LWin up}"

; ----------------------------
; Double-key mappings
; ----------------------------

>+Up::Send "{LWin down}{Up}{LWin up}"
>+Down::Send "{LWin down}{Tab}{LWin up}"
>+Left::Send "{LShift down}{LWin down}{Left}{LWin up}{LShift up}"
>+Right::Send "{LShift down}{LWin down}{Right}{LWin up}{LShift up}"

<#Left::Send "{RCtrl down}{PgUp}{RCtrl up}"
<#Right::Send "{RCtrl down}{PgDn}{RCtrl up}"
<#.::Send "{LWin down}d{LWin up}"
<#z::Send "{LWin down}d{LWin up}"
>^.::Send "{RCtrl down}t{RCtrl up}"

; ----------------------------
; Left Ctrl + numeric keypad mappings
; ----------------------------

<^NumpadDot::Send "{LAlt down}{Tab}{LAlt up}"
<^Numpad1::Send "{LCtrl down}x{LCtrl up}"
<^Numpad2::Send "{LCtrl down}c{LCtrl up}"
<^Numpad3::Send "{LCtrl down}v{LCtrl up}"
<^Numpad4::Send "{LAlt down}{F4}{LAlt up}"
<^Numpad5::Click "Left"
<^Numpad6::Click "Right"
<^Numpad7::Send "{LButton up}"
<^Numpad8::Send "{LButton down}"
<^Numpad9::Send "{LCtrl down}w{LCtrl up}"

<^NumpadSub::{
    Loop 5 {
        Send "{WheelUp}"
        Sleep 20
    }
}

<^NumpadAdd::{
    Loop 5 {
        Send "{WheelDown}"
        Sleep 20
    }
}

<^NumpadMult::{
    ; Original Key Manager sequence: RAlt down, Space down, tap N, release Space/RAlt.
    Send "{RAlt down}{Space down}n{Space up}{RAlt up}"
}

RunFirstExisting(displayName, paths, fallbackCommands := []) {
    for path in paths {
        if path && FileExist(path) {
            Run path
            return
        }
    }

    for command in fallbackCommands {
        try {
            Run command
            return
        }
    }

    MsgBox "Cannot find " displayName ".`n`nOpen this script in Notepad and update the path list for " displayName ".", "Key Manager replacement", "Icon!"
}
