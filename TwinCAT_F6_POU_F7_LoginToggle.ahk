#Requires AutoHotkey v2.0
#SingleInstance Force

; Use the UI Access build so the hotkeys also work when XAE Shell is elevated.
if !InStr(A_AhkPath, "_UIA.exe") {
    uiAccessExe := A_ProgramFiles "\AutoHotkey\v2\AutoHotkey64_UIA.exe"
    if FileExist(uiAccessExe) {
        Run('"' uiAccessExe '" "' A_ScriptFullPath '"')
        ExitApp()
    }
}

CoordMode("Mouse", "Screen")
SendMode("Input")

if A_Args.Length && A_Args[1] = "--login-probe" {
    try {
        loginContext := GetPlcLoginContext()
        loginState := GetPlcLoginState(loginContext)
        FileAppend(
            "OK state=" loginState
            " login=" loginContext["loginAvailable"]
            " logout=" loginContext["logoutAvailable"] "`n",
            "*"
        )
        ExitApp(0)
    } catch Error as errorInfo {
        FileAppend("ERROR: " errorInfo.Message "`n", "*")
        ExitApp(5)
    }
}

if A_Args.Length && A_Args[1] = "--probe" {
    probeMain := FindXaeMainWindow()
    probeSplitter := A_Args.Length >= 2
        ? Integer(A_Args[2])
        : (probeMain ? FindVisiblePouSplitter(probeMain) : 0)
    probeInfo := probeSplitter ? GetSplitterInfo(probeSplitter) : false
    if probeInfo {
        FileAppend(
            "OK state=" probeInfo["state"]
            " hwnd=" probeSplitter
            " x=" probeInfo["rect"]["x"]
            " y=" probeInfo["splitY"]
            " width=" probeInfo["rect"]["w"] "`n",
            "*"
        )
        ExitApp(0)
    }
    FileAppend(
        "ERROR: no visible TwinCAT POU splitter found; main=" probeMain "`n",
        "*"
    )
    ExitApp(2)
}

if A_Args.Length && A_Args[1] = "--cycle-test" {
    testMain := FindXaeMainWindow()
    if !testMain {
        FileAppend("ERROR: XAE Shell main window not found`n", "*")
        ExitApp(2)
    }

    WinActivate("ahk_id " testMain)
    if !WinWaitActive("ahk_id " testMain, , 2) {
        FileAppend("ERROR: XAE Shell could not be activated`n", "*")
        ExitApp(3)
    }

    Loop 3 {
        CyclePouPaneView()
        Sleep(250)
        testSplitter := FindVisiblePouSplitter(testMain)
        testInfo := testSplitter ? GetSplitterInfo(testSplitter) : false
        if !testInfo {
            FileAppend("ERROR: splitter lost after step " A_Index "`n", "*")
            ExitApp(4)
        }
        FileAppend("step" A_Index "=" testInfo["state"] "`n", "*")
    }
    ExitApp(0)
}

#HotIf WinActive("ahk_exe TcXaeShell.exe")
$F6::CyclePouPaneView()
$F7::{
    TogglePlcLogin()
    KeyWait("F7")
}
#HotIf

TogglePlcLogin() {
    try {
        loginContext := GetPlcLoginContext()
        loginState := GetPlcLoginState(loginContext)

        switch loginState {
            case "logged_in":
                loginContext["dte"].ExecuteCommand("PLC.Logoutfromnone")

            case "logged_out":
                loginContext["dte"].ExecuteCommand("PLC.Logintonone")

            default:
                ShowTransientTip("PLC login/logout is temporarily unavailable.")
        }
    } catch Error {
        ShowTransientTip("Unable to access the TwinCAT PLC command interface.")
    }
}

GetPlcLoginContext() {
    dte := ComObjActive("TcXaeShell.DTE.17.0")
    loginCommand := dte.Commands.Item("PLC.Logintonone", 0)
    logoutCommand := dte.Commands.Item("PLC.Logoutfromnone", 0)

    return Map(
        "dte", dte,
        "loginAvailable", !!loginCommand.IsAvailable,
        "logoutAvailable", !!logoutCommand.IsAvailable
    )
}

GetPlcLoginState(loginContext) {
    canLogin := loginContext["loginAvailable"]
    canLogout := loginContext["logoutAvailable"]

    if canLogout && !canLogin
        return "logged_in"

    if canLogin && !canLogout
        return "logged_out"

    return "unavailable"
}

ShowTransientTip(message) {
    ToolTip(message)
    SetTimer(ClearTransientTip, -1600)
}

ClearTransientTip() {
    ToolTip()
}

CyclePouPaneView() {
    mainHwnd := WinExist("A")
    focusHwnd := GetThreadFocus(mainHwnd)
    splitterHwnd := FindPouSplitter(focusHwnd, mainHwnd)
    if !splitterHwnd
        splitterHwnd := FindVisiblePouSplitter(mainHwnd)

    if !splitterHwnd {
        Send("{F6}")
        return
    }

    info := GetSplitterInfo(splitterHwnd)
    if !info {
        Send("{F6}")
        return
    }

    switch info["state"] {
        case "split":
            ; Hide the implementation pane, leaving the declaration full-height.
            ClickSplitterArrow(info, "panel2")

        case "declaration":
            ; Hide the declaration pane. Some builds restore the split view first,
            ; so inspect the result and click once more when necessary.
            ClickSplitterArrow(info, "panel1")
            Sleep(80)
            after := GetSplitterInfo(splitterHwnd)
            if after && after["state"] = "split"
                ClickSplitterArrow(after, "panel1")

        case "implementation":
            ; The down arrow restores the split view from implementation-only mode.
            ClickSplitterArrow(info, "panel2")

        default:
            Send("{F6}")
    }
}

GetThreadFocus(mainHwnd) {
    processId := 0
    threadId := DllCall(
        "GetWindowThreadProcessId",
        "ptr", mainHwnd,
        "uint*", &processId,
        "uint"
    )
    if !threadId
        return 0

    infoSize := 8 + (6 * A_PtrSize) + 16
    guiInfo := Buffer(infoSize, 0)
    NumPut("uint", infoSize, guiInfo, 0)

    if !DllCall("GetGUIThreadInfo", "uint", threadId, "ptr", guiInfo.Ptr)
        return 0

    return NumGet(guiInfo, 8 + A_PtrSize, "ptr")
}

FindPouSplitter(focusHwnd, mainHwnd) {
    hwnd := focusHwnd

    Loop 24 {
        if !hwnd
            break

        if GetSplitterInfo(hwnd)
            return hwnd

        if hwnd = mainHwnd
            break

        hwnd := DllCall("GetParent", "ptr", hwnd, "ptr")
    }

    return 0
}

FindVisiblePouSplitter(mainHwnd) {
    global PouSplitterCandidates := []
    callback := CallbackCreate(CollectPouSplitter)
    DllCall(
        "EnumChildWindows",
        "ptr", mainHwnd,
        "ptr", callback,
        "ptr", 0
    )
    CallbackFree(callback)

    bestHwnd := 0
    bestArea := 0
    for candidate in PouSplitterCandidates {
        area := candidate["area"]
        if area > bestArea {
            bestArea := area
            bestHwnd := candidate["hwnd"]
        }
    }

    return bestHwnd
}

FindXaeMainWindow() {
    bestHwnd := 0
    bestArea := 0

    for hwnd in WinGetList("ahk_exe TcXaeShell.exe") {
        if !DllCall("IsWindowVisible", "ptr", hwnd)
            continue

        rect := GetRect(hwnd)
        if !rect
            continue

        area := rect["w"] * rect["h"]
        if area > bestArea {
            bestArea := area
            bestHwnd := hwnd
        }
    }

    return bestHwnd
}

CollectPouSplitter(hwnd, lParam) {
    global PouSplitterCandidates

    if !DllCall("IsWindowVisible", "ptr", hwnd)
        return true

    info := GetSplitterInfo(hwnd)
    if info {
        rect := info["rect"]
        PouSplitterCandidates.Push(
            Map("hwnd", hwnd, "area", rect["w"] * rect["h"])
        )
    }

    return true
}

GetSplitterInfo(hwnd) {
    parent := GetRect(hwnd)
    if !parent || parent["w"] < 300 || parent["h"] < 200
        return false

    panes := []
    child := 0

    while child := DllCall(
        "FindWindowExW",
        "ptr", hwnd,
        "ptr", child,
        "ptr", 0,
        "ptr", 0,
        "ptr"
    ) {
        className := GetClassName(child)
        if !InStr(className, "WindowsForms10.Window", true)
            continue

        rect := GetRect(child)
        if !rect
            continue

        if Abs(rect["x"] - parent["x"]) <= 2
            && rect["w"] >= parent["w"] - 2
            && rect["h"] >= 2 {
            panes.Push(rect)
        }
    }

    if panes.Length = 2 {
        top := panes[1]
        bottom := panes[2]
        if top["y"] > bottom["y"] {
            swap := top
            top := bottom
            bottom := swap
        }

        gap := bottom["y"] - (top["y"] + top["h"])
        if Abs(top["y"] - parent["y"]) <= 2
            && Abs((bottom["y"] + bottom["h"]) - (parent["y"] + parent["h"])) <= 2
            && gap >= 2 && gap <= 12 {
            return Map(
                "hwnd", hwnd,
                "state", "split",
                "rect", parent,
                "splitY", top["y"] + top["h"],
                "splitWidth", gap
            )
        }
    }

    if panes.Length = 1 {
        pane := panes[1]
        topGap := pane["y"] - parent["y"]
        bottomGap := (parent["y"] + parent["h"]) - (pane["y"] + pane["h"])

        if topGap >= 2 && topGap <= 12 && Abs(bottomGap) <= 2 {
            return Map(
                "hwnd", hwnd,
                "state", "implementation",
                "rect", parent,
                "splitY", parent["y"],
                "splitWidth", topGap
            )
        }

        if bottomGap >= 2 && bottomGap <= 12 && Abs(topGap) <= 2 {
            return Map(
                "hwnd", hwnd,
                "state", "declaration",
                "rect", parent,
                "splitY", parent["y"] + parent["h"] - bottomGap,
                "splitWidth", bottomGap
            )
        }
    }

    return false
}

ClickSplitterArrow(info, panel) {
    rect := info["rect"]
    xOffset := panel = "panel1" ? -8 : 8
    clickX := rect["x"] + Floor(rect["w"] / 2) + xOffset
    clickY := info["splitY"] + Floor(info["splitWidth"] / 2)

    MouseGetPos(&oldX, &oldY)
    MouseMove(clickX, clickY, 0)
    Sleep(25)
    Click()
    Sleep(40)
    MouseMove(oldX, oldY, 0)
}

GetRect(hwnd) {
    rectBuffer := Buffer(16, 0)
    if !DllCall("GetWindowRect", "ptr", hwnd, "ptr", rectBuffer.Ptr)
        return false

    left := NumGet(rectBuffer, 0, "int")
    top := NumGet(rectBuffer, 4, "int")
    right := NumGet(rectBuffer, 8, "int")
    bottom := NumGet(rectBuffer, 12, "int")

    return Map(
        "x", left,
        "y", top,
        "w", right - left,
        "h", bottom - top
    )
}

GetClassName(hwnd) {
    classBuffer := Buffer(512, 0)
    length := DllCall(
        "GetClassNameW",
        "ptr", hwnd,
        "ptr", classBuffer.Ptr,
        "int", 256,
        "int"
    )
    return length ? StrGet(classBuffer, length, "UTF-16") : ""
}
