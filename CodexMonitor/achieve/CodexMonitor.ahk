#Requires AutoHotkey v2.0
#SingleInstance Force

; ChatGPT Desktop Codex monitor (Windows, AutoHotkey v2).
; Hotkey: Ctrl + Shift + F12. Default: monitoring OFF.
; Fail-closed: if detection is ambiguous, NEVER click.

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

global gMonitoring := false
global gWindow := 0
global gIndicator := 0
global gBusy := false
global gLocked := false
global gSquareStreak := 0
global gLastState := ""
global gLogPath := A_ScriptDir "\CodexMonitor.log"

; Safe non-interactive smoke test: no hotkey, no GUI, no mouse click.
if (A_Args.Length > 0 && A_Args[1] = "--self-test") {
    if (!IsButtonBlue(0x2C67C5) || IsButtonBlue(0xFFFFFF)
        || !IsWhite(0xFFFFFF) || IsWhite(0x2C67C5)
        || !SamePoint({x: 10, y: 10}, {x: 13, y: 14})
        || SamePoint({x: 10, y: 10}, {x: 20, y: 20})) {
        FileAppend("FAIL: color/position helpers`n", "*")
        ExitApp(1)
    }
    FileAppend("PASS: CodexMonitor helper smoke test`n", "*")
    ExitApp(0)
}

^+F12::ToggleMonitoring()

ToggleMonitoring(*) {
    global gMonitoring, gWindow, gLocked, gSquareStreak, gLastState

    if gMonitoring {
        StopMonitoring("用户关闭监控")
        return
    }

    hwnd := WinExist("A")
    if !IsTargetWindow(hwnd) {
        StopMonitoring("启动失败：当前前台窗口不是 ChatGPT 桌面版")
        MsgBox("无法启动监控。`n`n请先切换到 ChatGPT Windows 桌面版，再按 Ctrl + Shift + F12。`n不会点击任何按钮。", "Codex 监控错误", "Iconx")
        return
    }

    gWindow := hwnd
    gMonitoring := true
    gLocked := false
    gSquareStreak := 0
    gLastState := ""
    ShowIndicator(hwnd)
    Log("监控启动，窗口 hwnd=" hwnd)
    SetTimer(Poll, 10000)
    Poll()  ; 启动立即检查一次；之后每 10 秒检查一次
}

IsTargetWindow(hwnd) {
    if !hwnd
        return false
    try {
        if (StrLower(WinGetProcessName("ahk_id " hwnd)) != "chatgpt.exe")
            return false
        if (WinGetMinMax("ahk_id " hwnd) = -1)
            return false
        return WinActive("ahk_id " hwnd) != 0
    } catch {
        return false
    }
}

ShowIndicator(hwnd) {
    global gIndicator
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    gIndicator := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "Codex 监控")
    gIndicator.BackColor := "17324B"
    gIndicator.SetFont("s11 Bold cFFFFFF", "Microsoft YaHei UI")
    gIndicator.AddText("x12 y9", "● 监控中  |  Ctrl+Shift+F12 停止")
    ; NoActivate + click-through: don't steal focus or cover the send button.
    gIndicator.Show("NoActivate AutoSize x" (wx + ww - 315) " y" (wy + 64))
}

StopMonitoring(reason := "", displayError := false) {
    global gMonitoring, gWindow, gIndicator, gBusy, gLocked, gSquareStreak, gLastState
    SetTimer(Poll, 0)
    gMonitoring := false
    gWindow := 0
    gLocked := false
    gSquareStreak := 0
    gLastState := ""
    if IsObject(gIndicator) {
        try gIndicator.Destroy()
        gIndicator := 0
    }
    if (reason != "")
        Log(reason)
    if displayError
        MsgBox(reason "`n`n监控已停止；未执行自动点击。", "Codex 监控错误", "Iconx")
}

Poll(*) {
    global gMonitoring, gWindow, gBusy, gLocked, gSquareStreak, gLastState
    if !gMonitoring || gBusy
        return
    gBusy := true
    try {
        ; Current foreground window must still be the original ChatGPT.exe window.
        if !IsTargetWindow(gWindow) {
            StopMonitoring("ChatGPT 桌面版不再是前台窗口（或已最小化/关闭）")
            MsgBox("监控已停止：当前不再显示原来的 ChatGPT 桌面版窗口。`n不会执行自动点击。", "Codex 监控错误", "Iconx")
            return
        }

        first := InspectButton(gWindow)
        if (first.state != gLastState) {
            Log("识别状态：" first.state (gLocked ? "（点击锁定中）" : ""))
            gLastState := first.state
        }

        if gLocked {
            ; Two independent 10-second samples of the square are needed to re-arm.
            if (first.state = "square") {
                gSquareStreak += 1
                if (gSquareStreak >= 2) {
                    gLocked := false
                    gSquareStreak := 0
                    Log("连续确认方形，允许下一次中断恢复")
                }
            } else {
                gSquareStreak := 0
            }
            return
        }

        if (first.state != "triangle")
            return

        ; Two more independent confirmations before a single click.
        Sleep(350)
        if !gMonitoring || !IsTargetWindow(gWindow)
            return
        second := InspectButton(gWindow)
        if (second.state != "triangle" || !SamePoint(first, second))
            return

        if !gMonitoring || !IsTargetWindow(gWindow)
            return
        third := InspectButton(gWindow)
        if (third.state != "triangle" || !SamePoint(second, third))
            return

        ; Don't send a modified click while the Ctrl+Shift+F12 hotkey is still held.
        ; Defer to a later cycle instead of sending Ctrl/Shift/Alt + Click.
        if (GetKeyState("Control", "P") || GetKeyState("Shift", "P")
            || GetKeyState("Alt", "P") || GetKeyState("LButton", "P"))
            return

        ; Lock BEFORE touching the mouse, even if Click fails.
        gLocked := true
        gSquareStreak := 0
        Log("三次确认三角形；单击一次 (" third.x ", " third.y ")；进入锁定")
        MouseGetPos(&oldX, &oldY)
        try {
            Click(third.x, third.y)
        } finally {
            MouseMove(oldX, oldY, 0)
        }
    } catch as err {
        ; Errors always fail closed: stop, don't retry blindly.
        StopMonitoring("监控发生异常：" err.Message)
        MsgBox("监控发生异常并已停止：`n" err.Message "`n`n不会继续自动点击。", "Codex 监控错误", "Iconx")
    } finally {
        gBusy := false
    }
}

SamePoint(a, b) {
    return (Abs(a.x - b.x) <= 5 && Abs(a.y - b.y) <= 5)
}

InspectButton(hwnd) {
    none := {state: "unknown", x: 0, y: 0}
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    if (ww < 680 || wh < 350)
        return none

    ; The ChatGPT send/continue button is near the bottom of the composer,
    ; NOT necessarily the far-right edge of the whole application window.
    left := wx + Round(ww * 0.30)
    right := wx + Round(ww * 0.88)
    top := wy + wh - 130
    bottom := wy + wh - 8

    ; Screenshot-calibrated blue RGB ~ #2C67C5. An unmatched pixel => no action.
    if !PixelSearch(&sx, &sy, left, top, right, bottom, 0x2C67C5, 24)
        return none

    ; Determine the circle's bounding box from its actual blue pixels.
    minX := 2147483647, maxX := -2147483647
    minY := 2147483647, maxY := -2147483647
    count := 0
    y := Max(top, sy - 5)
    while (y <= Min(bottom, sy + 80)) {
        x := Max(left, sx - 55)
        while (x <= Min(right, sx + 65)) {
            if IsButtonBlue(PixelGetColor(x, y)) {
                count += 1
                minX := Min(minX, x), maxX := Max(maxX, x)
                minY := Min(minY, y), maxY := Max(maxY, y)
            }
            x += 2
        }
        y += 2
    }

    bw := maxX - minX + 1
    bh := maxY - minY + 1
    if (count < 38 || bw < 22 || bw > 76 || bh < 22 || bh > 76)
        return none
    if (Abs(bw - bh) > Max(bw, bh) * 0.24)
        return none

    cx := Round((minX + maxX) / 2)
    cy := Round((minY + maxY) / 2)
    radius := (bw + bh) / 4
    if !IsButtonBlue(PixelGetColor(cx + Round(radius * 0.60), cy))
        return none

    kind := IconShape(cx, cy, radius)
    return {state: kind, x: cx, y: cy}
}

IsButtonBlue(rgb) {
    r := (rgb >> 16) & 255
    g := (rgb >> 8) & 255
    b := rgb & 255
    return (r >= 28 && r <= 83 && g >= 78 && g <= 151
        && b >= 152 && b <= 243 && b > g + 36)
}

IsWhite(rgb) {
    return (((rgb >> 16) & 255) > 215
        && ((rgb >> 8) & 255) > 215 && (rgb & 255) > 215)
}

IconShape(cx, cy, radius) {
    ; Shape detection, not just a white-pixel existence check:
    ; square = nearly identical row widths; right-pointing triangle =
    ; narrow top/bottom rows, widest center, stable left edge.
    rows := []
    y := Round(cy - radius * 0.58)
    while (y <= Round(cy + radius * 0.58)) {
        whiteCount := 0
        firstX := 2147483647
        lastX := -2147483647
        x := Round(cx - radius * 0.65)
        while (x <= Round(cx + radius * 0.65)) {
            if IsWhite(PixelGetColor(x, y)) {
                whiteCount += 1
                firstX := Min(firstX, x)
                lastX := Max(lastX, x)
            }
            x += 1
        }
        if (whiteCount > 0)
            rows.Push({width: whiteCount, left: firstX, right: lastX})
        y += 1
    }

    n := rows.Length
    if (n < 5 || n > Round(radius * 1.35))
        return "unknown"

    peak := 0
    narrowest := 2147483647
    minLeft := 2147483647
    maxLeft := -2147483647
    for item in rows {
        peak := Max(peak, item.width)
        narrowest := Min(narrowest, item.width)
        minLeft := Min(minLeft, item.left)
        maxLeft := Max(maxLeft, item.left)
    }
    if (peak < 5)
        return "unknown"

    edgeMean := (rows[1].width + rows[2].width
        + rows[n - 1].width + rows[n].width) / 4.0
    taper := peak - edgeMean
    if (taper >= Max(2.0, peak * 0.28)
        && maxLeft - minLeft <= Max(2, Round(radius * 0.22)))
        return "triangle"
    if (taper <= Max(1.0, peak * 0.18)
        && narrowest >= peak * 0.72)
        return "square"
    return "unknown"
}

Log(message) {
    global gLogPath
    try {
        FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "  " message "`r`n", gLogPath, "UTF-8")
    } catch {
        ; Logging failure must never cause extra clicking.
    }
}
