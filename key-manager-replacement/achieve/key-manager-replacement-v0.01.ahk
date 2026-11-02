#Requires AutoHotkey v2.0
#SingleInstance Force

Version := "V0.01"
WheelSteps := 8
WheelDelayMs := 15

A_IconTip := "Key Manager replacement " Version
SendMode "Input"
SetMouseDelay -1
OnExit ReleaseAllKeys

; Replacement for the reduced Key Manager profile shown in Snipaste_2026-07-04_11-48-21.png.
; Double-click this file to enable the mappings. Use the tray icon to pause or exit.

; ----------------------------
; Single-key mappings
; ----------------------------

Numpad9::SafeSend("{LWin down}9{LWin up}")
Numpad8::SafeSend("{LWin down}8{LWin up}")
Numpad7::SafeSend("{LWin down}7{LWin up}")
Numpad6::SafeSend("{LWin down}6{LWin up}")
Numpad4::SafeSend("{LWin down}0{LWin up}")

Numpad5::{
    ReleaseModifiers()
    RunFirstExisting("flomo", [
        EnvGet("LOCALAPPDATA") "\Programs\flomo\flomo.exe",
        EnvGet("LOCALAPPDATA") "\Programs\Flomo\flomo.exe",
        "C:\Program Files\flomo\flomo.exe",
        "C:\Program Files\Flomo\flomo.exe",
        "C:\Program Files (x86)\flomo\flomo.exe"
    ], ["flomo.exe"])
    ReleaseModifiers()
}

Numpad2::{
    ReleaseModifiers()
    RunFirstExisting("Cherry Studio", [
        EnvGet("LOCALAPPDATA") "\Programs\Cherry Studio\Cherry Studio.exe",
        EnvGet("LOCALAPPDATA") "\Programs\cherry-studio\Cherry Studio.exe",
        "C:\Program Files\Cherry Studio\Cherry Studio.exe",
        "C:\Program Files (x86)\Cherry Studio\Cherry Studio.exe"
    ], ["Cherry Studio.exe", "CherryStudio.exe"])
    ReleaseModifiers()
}

Numpad1::{
    ReleaseModifiers()
    RunFirstExisting("Everything", [
        "C:\Program Files\Everything\Everything64.exe",
        "C:\Program Files\Everything\Everything.exe",
        "C:\Program Files (x86)\Everything\Everything.exe",
        EnvGet("ProgramData") "\Microsoft\Windows\Start Menu\Programs\Everything.lnk"
    ], ["Everything64.exe", "Everything.exe"])
    ReleaseModifiers()
}

; OEM 3 is usually the `~ key. OEM 2 is usually the /? key on a US keyboard.
SC029::SafeSend("{RAlt down}{vkBF}{RAlt up}")

; ----------------------------
; Double-key mappings
; ----------------------------

>+Up::SafeSend("{LWin down}{Up}{LWin up}")
>+Down::SafeSend("{LWin down}{Tab}{LWin up}")
>+Left::SafeSend("{LShift down}{LWin down}{Left}{LWin up}{LShift up}")
>+Right::SafeSend("{LShift down}{LWin down}{Right}{LWin up}{LShift up}")

; ----------------------------
; Left Ctrl + numeric keypad mappings
; ----------------------------

<^NumpadDot::SafeSend("{LAlt down}{Tab}{LAlt up}", "NumpadDot")
<^Numpad1::SafeSend("{LCtrl down}x{LCtrl up}", "Numpad1")
<^Numpad2::SafeSend("{LCtrl down}c{LCtrl up}", "Numpad2")
<^Numpad3::SafeSend("{LCtrl down}v{LCtrl up}", "Numpad3")
<^Numpad4::SafeSend("{LAlt down}{F4}{LAlt up}", "Numpad4")
<^Numpad5::SafeClick("Left", "Numpad5")
<^Numpad6::SafeClick("Right", "Numpad6")
<^Numpad7::MouseLeftUp("Numpad7")
<^Numpad8::MouseLeftDown("Numpad8")
<^Numpad9::SafeSend("{LCtrl down}w{LCtrl up}", "Numpad9")
<^NumpadSub::StableWheel("Up", "NumpadSub")
<^NumpadAdd::StableWheel("Down", "NumpadAdd")
<^NumpadMult::SafeSend("{RAlt down}{Space down}n{Space up}{RAlt up}", "NumpadMult")

SafeSend(keys, waitKey := "") {
    ReleaseModifiers()
    Send keys
    ReleaseModifiers()
    if waitKey {
        KeyWait waitKey
    }
}

SafeClick(button, waitKey := "") {
    ReleaseModifiers()
    Click button
    ReleaseModifiers()
    if waitKey {
        KeyWait waitKey
    }
}

MouseLeftDown(waitKey := "") {
    ReleaseModifiers()
    SendEvent "{LButton down}"
    ReleaseModifiers()
    if waitKey {
        KeyWait waitKey
    }
}

MouseLeftUp(waitKey := "") {
    SendEvent "{LButton up}"
    ReleaseModifiers()
    if waitKey {
        KeyWait waitKey
    }
}

StableWheel(direction, waitKey := "") {
    ReleaseModifiers()
    event := direction = "Up" ? "{WheelUp}" : "{WheelDown}"
    Loop WheelSteps {
        SendEvent event
        Sleep WheelDelayMs
    }
    ReleaseModifiers()
    if waitKey {
        KeyWait waitKey
    }
}

ReleaseModifiers() {
    SendEvent "{LCtrl up}{RCtrl up}{LShift up}{RShift up}{LAlt up}{RAlt up}{LWin up}{RWin up}"
}

ReleaseAllKeys(*) {
    SendEvent "{LButton up}"
    ReleaseModifiers()
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

    MsgBox "Cannot find " displayName ".`n`nOpen this script in Notepad and update the path list for " displayName ".", "Key Manager replacement " Version, "Icon!"
}
