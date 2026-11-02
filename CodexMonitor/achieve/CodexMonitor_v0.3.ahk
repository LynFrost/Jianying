#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2

; ChatGPT Windows Desktop monitoring v0.3
; Ctrl+Shift+F12 = toggle monitor; Ctrl+Shift+F11 = toggle test-only mode.
; Scheme A: one click per confirmed stop; re-arm only after >=500ms stable square.

CoordMode("Mouse", "Screen")

global gActive := false
global gTarget := 0
global gEpoch := 0
global gChecking := false
global gLocked := false
global gRecovery := BlankProgress()
global gFastMode := ""
global gFastUntil := 0
global gTestOnly := false
global gIndicator := 0
global gIndicatorText := 0
global gLastToggle := 0
global gLog := A_ScriptDir "\CodexMonitor_v0.3.log"

if (A_Args.Length && A_Args[1] = "--self-test") {
    TestHelpers()
    ExitApp(0)
}

; GDI path smoke test: 16x16 pixels, no timers/hotkeys/mouse operations.
if (A_Args.Length && A_Args[1] = "--capture-test") {
    try {
        tiny := Capture(0, 0, 16, 16)
        if (tiny.buffer.Size != 1024)
            throw Error("图像 Buffer 尺寸错误")
        FileAppend("PASS v0.3: GDI BitBlt screenshot memory buffer`n", "*")
    } catch as err {
        FileAppend("FAIL v0.3: " err.Message "`n", "*")
        ExitApp(1)
    }
    ExitApp(0)
}

; Read-only live screenshot test: NEVER starts the timer and NEVER clicks.
if (A_Args.Length && A_Args[1] = "--screen-test") {
    hwnd := WinExist("A")
    if !TargetIsActive(hwnd) {
        FileAppend("SKIP: ChatGPT.exe is not the active window in this session`n", "*")
        ExitApp(0)
    }
    try {
        t := A_TickCount
        sample := Inspect(hwnd)
        FileAppend("SCREEN: " sample.state ", " sample.x "," sample.y
            ", " sample.note ", " (A_TickCount - t) "ms`n", "*")
    } catch as e {
        FileAppend("FAIL: " e.Message "`n", "*")
        ExitApp(1)
    }
    ExitApp(0)
}

^+F12::ToggleMonitor()
^+F11::ToggleTestMode()

ToggleMonitor(*) {
    global gActive, gTarget, gEpoch, gLocked, gRecovery, gFastMode, gFastUntil, gLastToggle
    if (A_TickCount - gLastToggle < 350)
        return
    gLastToggle := A_TickCount
    if gActive {
        StopMonitor("用户按快捷键停止")
        return
    }

    hwnd := WinExist("A")
    if !TargetIsActive(hwnd) {
        StopMonitor("启动拒绝：前台不是 ChatGPT.exe")
        MsgBox("当前不是 ChatGPT Windows 桌面版窗口。`n监控没有启动，也不会点击鼠标。", "Codex 监控错误", "Iconx")
        return
    }

    gEpoch += 1
    gTarget := hwnd
    gActive := true
    gLocked := false
    gRecovery := BlankProgress()
    gFastMode := ""
    gFastUntil := 0
    ShowIndicator()
    WriteLog("启动 hwnd=" hwnd "; mode=" (gTestOnly ? "测试" : "自动"))

    ; Unlike v0.1, DO NOT call Poll() inside the hotkey thread.
    SetTimer(MonitorTick, 10000)
    SetTimer(InitialTick, -650)
}

InitialTick(*) {
    MonitorTick()
}

ToggleTestMode(*) {
    global gTestOnly, gActive, gLocked, gRecovery
    gTestOnly := !gTestOnly
    if gActive && gTestOnly {
        gRecovery := BlankProgress()
        EndFast("测试模式：取消高频检测，仍保持锁定")
    }
    WriteLog("模式切换=" (gTestOnly ? "测试（绝不点击）" : "自动")
        "; lock=" gLocked)
    if gActive
        UpdateIndicator(gTestOnly ? "已切换测试模式" : "已切换自动模式")
}

TargetIsActive(hwnd) {
    if !hwnd
        return false
    try {
        return (StrLower(WinGetProcessName("ahk_id " hwnd)) = "chatgpt.exe"
            && WinActive("ahk_id " hwnd) != 0
            && WinGetMinMax("ahk_id " hwnd) != -1)
    } catch {
        return false
    }
}

StopMonitor(why := "") {
    global gActive, gTarget, gEpoch, gLocked, gRecovery, gFastMode, gFastUntil, gIndicator, gIndicatorText
    ; Increment epoch FIRST: a suspended or in-flight detection must never click.
    gEpoch += 1
    gActive := false
    SetTimer(InitialTick, 0)
    SetTimer(MonitorTick, 0)
    gTarget := 0
    gLocked := false
    gRecovery := BlankProgress()
    gFastMode := ""
    gFastUntil := 0
    if IsObject(gIndicator) {
        try gIndicator.Destroy()
        gIndicator := 0
        gIndicatorText := 0
    }
    if why != ""
        WriteLog("停止：" why)
}

ShowIndicator() {
    global gIndicator, gIndicatorText, gTarget
    WinGetPos(&x, &y, &w, &h, "ahk_id " gTarget)
    gIndicator := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "Codex v0.3")
    gIndicator.BackColor := "17324B"
    gIndicator.SetFont("s10 cFFFFFF", "Microsoft YaHei UI")
    gIndicatorText := gIndicator.AddText("x10 y8 w330 h43", "")
    gIndicator.Show("NoActivate x" (x + w - 355) " y" (y + 59) " w350 h58")
    UpdateIndicator("等待首次检测")
}

UpdateIndicator(detail := "") {
    global gIndicatorText, gActive, gTestOnly, gLocked
    if !gActive || !IsObject(gIndicatorText)
        return
    main := gTestOnly ? "● 测试中（不点击）" : "● 监控中"
    second := detail != "" ? detail : (gLocked ? "已点击，等待方形解锁" : "每10秒检测；F12启停/F11测试")
    try gIndicatorText.Text := main "  |  Ctrl+Shift+F12 停止`n" second
}

MonitorTick(*) {
    global gActive, gTarget, gEpoch, gChecking, gLocked, gRecovery, gFastMode, gFastUntil, gTestOnly
    if !gActive || gChecking
        return
    gChecking := true
    generation := gEpoch
    startMs := A_TickCount
    try {
        if !TargetIsActive(gTarget) {
            StopMonitor("窗口不在前台/关闭/最小化")
            MsgBox("ChatGPT 桌面版不在前台，监控已停止。`n没有执行自动点击。", "Codex 监控错误", "Iconx")
            return
        }

        if (gFastMode != "" && A_TickCount >= gFastUntil)
            EndFast("高频窗口到期，无稳定方形，保持锁定")

        first := Inspect(gTarget)
        if !StillCurrent(generation)
            return
        elapsed := A_TickCount - startMs
        WriteLog("检测1=" first.state "; 坐标=" first.x "," first.y
            "; 耗时=" elapsed "ms; 详情=" first.note
            "; lock=" gLocked "; fast=" (gFastMode = "" ? "off" : gFastMode)
            "; squareSamples=" gRecovery.samples
            "; mode=" (gTestOnly ? "test" : "auto"))
        UpdateIndicator("检测=" first.state "，耗时=" elapsed "ms"
            (gLocked ? " [锁定" (gFastMode != "" ? "·快速检测" : "") "]" : ""))

        if gTestOnly {
            ; Test mode is read-only. It never unlocks/re-arms or clicks.
            return
        }

        if gLocked {
            ; Real square samples: at least 3 across >=500ms.
            ; Any triangle or unknown resets this candidate.
            gRecovery := AdvanceRecovery(first.state, A_TickCount, gRecovery)
            if gRecovery.done {
                gLocked := false
                gRecovery := BlankProgress()
                EndFast("稳定方形已确认，允许下一次中断点击")
                WriteLog("锁定解除：方形连续3次且跨度>=500ms")
                UpdateIndicator("方形稳定，已解除锁定")
            } else if (gFastMode = "" && first.state = "square") {
                ; After 15s, a later low-rate square still deserves verification.
                ArmFast("verify", 2000)
                WriteLog("低频检测到方形，快速核验2秒；仍锁定")
            } else if (gFastMode = "verify" && first.state != "square") {
                EndFast("方形快速核验被三角形/未知状态打断，保持锁定")
            }
            return
        }

        if first.state != "triangle"
            return

        Sleep(320)
        if !StillCurrent(generation) || !TargetIsActive(gTarget)
            return
        second := Inspect(gTarget)
        WriteLog("检测2=" second.state "; 坐标=" second.x "," second.y "; 详情=" second.note)
        if (second.state != "triangle" || !SamePoint(first, second)) {
            WriteLog("放弃点击：第二次识别/坐标不一致")
            return
        }

        Sleep(320)
        if !StillCurrent(generation) || !TargetIsActive(gTarget)
            return
        third := Inspect(gTarget)
        WriteLog("检测3=" third.state "; 坐标=" third.x "," third.y "; 详情=" third.note)
        if (third.state != "triangle" || !SamePoint(second, third)) {
            WriteLog("放弃点击：第三次识别/坐标不一致")
            return
        }

        if !StillCurrent(generation) || !TargetIsActive(gTarget)
            return
        if gTestOnly {
            WriteLog("放弃点击：已切换测试模式")
            return
        }
        if (GetKeyState("Control", "P") || GetKeyState("Shift", "P")
            || GetKeyState("Alt", "P") || GetKeyState("LButton", "P")) {
            WriteLog("放弃点击：修饰键或鼠标左键仍处于按下状态")
            return
        }

        ; Atomic final validation and ONE click. Never repeat by timeout.
        Critical("On")
        try {
            if !StillCurrent(generation) || gTestOnly || !TargetIsActive(gTarget)
                return
            gLocked := true
            gRecovery := BlankProgress()
            MouseGetPos(&oldX, &oldY)
            try {
                Click(third.x, third.y)
            } finally {
                MouseMove(oldX, oldY, 0)
            }
            WriteLog("确认三角形三次，点击一次：" third.x "," third.y "; 已锁定")
            ArmFast("postclick", 15000)
            UpdateIndicator("已点击一次并锁定，快速检查方形（15秒）")
        } finally {
            Critical("Off")
        }
    } catch as err {
        if gActive {
            StopMonitor("错误：" err.Message)
            MsgBox("监控出错并已停止：`n" err.Message, "Codex 监控错误", "Iconx")
        }
    } finally {
        WriteLog("本周期结束，总耗时=" (A_TickCount - startMs) "ms")
        gChecking := false
    }
}

; 250ms timer only while confirming recovery; normal interval stays 10s.
BlankProgress() {
    return {since:-1, samples:0, done:false}
}

AdvanceRecovery(state, nowMs, prior) {
    if state != "square"
        return BlankProgress()
    if prior.samples = 0
        return {since:nowMs, samples:1, done:false}
    count := prior.samples + 1
    return {since:prior.since, samples:count,
        done:(count >= 3 && nowMs - prior.since >= 500)}
}

ArmFast(reason, durationMs) {
    global gActive, gLocked, gTestOnly, gFastMode, gFastUntil
    if !gActive || !gLocked || gTestOnly
        return
    gFastMode := reason
    gFastUntil := A_TickCount + durationMs
    SetTimer(MonitorTick, 250)
    WriteLog("快速检测开始：" reason "；250ms；最长" durationMs "ms")
}

EndFast(reason) {
    global gActive, gFastMode, gFastUntil, gRecovery
    if gFastMode = ""
        return
    lastMode := gFastMode
    gFastMode := ""
    gFastUntil := 0
    gRecovery := BlankProgress()
    if gActive
        SetTimer(MonitorTick, 10000)
    WriteLog("快速检测结束：" lastMode "；" reason)
}

StillCurrent(generation) {
    global gActive, gEpoch
    return gActive && generation = gEpoch
}

SamePoint(a, b) {
    return (Abs(a.x - b.x) <= 4 && Abs(a.y - b.y) <= 4)
}

Inspect(hwnd) {
    unknown := {state:"unknown", x:0, y:0, note:"未检测到唯一有效按钮"}
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    if (ww < 680 || wh < 350)
        return {state:"unknown", x:0, y:0, note:"窗口过小"}
    ; Search near the bottom composer only; dimensions follow window position.
    x := wx + Round(ww * 0.30)
    y := wy + wh - 160
    right := wx + Round(ww * 0.90)
    bottom := wy + wh - 8
    if (right <= x || bottom <= y)
        return unknown

    screenshot := Capture(x, y, right - x + 1, bottom - y + 1)
    result := ClassifyScreenshot(screenshot)
    if result.state != "unknown" {
        result.x += x
        result.y += y
    }
    return result
}

; One BitBlt per poll. All other pixel reads use an in-memory Buffer.
Capture(screenX, screenY, width, height) {
    desktop := 0, memory := 0, bitmap := 0, old := 0, bits := 0
    try {
        desktop := DllCall("GetDC", "Ptr", 0, "Ptr")
        if !desktop
            throw Error("GetDC 失败")
        memory := DllCall("gdi32\CreateCompatibleDC", "Ptr", desktop, "Ptr")
        if !memory
            throw Error("CreateCompatibleDC 失败")

        header := Buffer(40, 0)
        NumPut("UInt", 40, header, 0)
        NumPut("Int", width, header, 4)
        NumPut("Int", -height, header, 8) ; top-down image
        NumPut("UShort", 1, header, 12)
        NumPut("UShort", 32, header, 14)
        bitmap := DllCall("gdi32\CreateDIBSection", "Ptr", desktop,
            "Ptr", header.Ptr, "UInt", 0, "Ptr*", &bits,
            "Ptr", 0, "UInt", 0, "Ptr")
        if !bitmap || !bits
            throw Error("CreateDIBSection 失败")
        old := DllCall("gdi32\SelectObject", "Ptr", memory, "Ptr", bitmap, "Ptr")
        if !old
            throw Error("SelectObject 失败")
        if !DllCall("gdi32\BitBlt", "Ptr", memory, "Int", 0, "Int", 0,
            "Int", width, "Int", height, "Ptr", desktop,
            "Int", screenX, "Int", screenY, "UInt", 0x00CC0020, "Int")
            throw Error("BitBlt 失败")

        result := Buffer(width * height * 4)
        DllCall("RtlMoveMemory", "Ptr", result.Ptr, "Ptr", bits,
            "UPtr", result.Size)
        return {w:width, h:height, buffer:result}
    } finally {
        if old && memory
            DllCall("gdi32\SelectObject", "Ptr", memory, "Ptr", old)
        if bitmap
            DllCall("gdi32\DeleteObject", "Ptr", bitmap)
        if memory
            DllCall("gdi32\DeleteDC", "Ptr", memory)
        if desktop
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", desktop)
    }
}

ReadPixel(image, x, y) {
    if x < 0 || y < 0 || x >= image.w || y >= image.h
        return 0
    return NumGet(image.buffer, (y * image.w + x) * 4, "UInt") & 0xFFFFFF
}

IsBlue(rgb) {
    r := (rgb >> 16) & 255, g := (rgb >> 8) & 255, b := rgb & 255
    return (r >= 25 && r <= 100 && g >= 70 && g <= 170
        && b >= 140 && b <= 245 && b > g + 28)
}

IsWhite(rgb) {
    return (((rgb >> 16) & 255) > 215
        && ((rgb >> 8) & 255) > 215 && (rgb & 255) > 215)
}

ClassifyScreenshot(image) {
    ; Sample every 2px and cluster 8-connected blue pixels.
    stride := 2
    cols := Ceil(image.w / stride), rows := Ceil(image.h / stride)
    blue := Map(), visited := Map()
    Loop rows {
        gy := A_Index - 1
        Loop cols {
            gx := A_Index - 1
            if IsBlue(ReadPixel(image, gx * stride, gy * stride))
                blue[gy * cols + gx] := true
        }
    }

    matches := []
    for startKey, _ in blue {
        if visited.Has(startKey)
            continue
        queue := [startKey], head := 1
        visited[startKey] := true
        count := 0
        minX := cols, minY := rows, maxX := -1, maxY := -1
        while head <= queue.Length {
            key := queue[head++]
            px := Mod(key, cols), py := key // cols
            count += 1
            minX := Min(minX, px), maxX := Max(maxX, px)
            minY := Min(minY, py), maxY := Max(maxY, py)
            Loop 3 {
                ny := py + A_Index - 2
                if ny < 0 || ny >= rows
                    continue
                Loop 3 {
                    nx := px + A_Index - 2
                    if nx < 0 || nx >= cols
                        continue
                    neighbor := ny * cols + nx
                    if blue.Has(neighbor) && !visited.Has(neighbor) {
                        visited[neighbor] := true
                        queue.Push(neighbor)
                    }
                }
            }
        }

        width := (maxX - minX) * stride + 1
        height := (maxY - minY) * stride + 1
        if (count < 38 || width < 17 || width > 76 || height < 17
            || height > 76 || Abs(width - height) > Max(width, height) * 0.24)
            continue

        centerX := Round((maxX + minX) * stride / 2)
        centerY := Round((maxY + minY) * stride / 2)
        radius := (width + height) / 4
        if !IsBlue(ReadPixel(image, centerX + Round(radius * .62), centerY))
            continue

        kind := IconKind(image, centerX, centerY, radius)
        if kind != "unknown"
            matches.Push({state:kind, x:centerX, y:centerY, note:"蓝色圆形匹配; 直径=" width "/" height})
    }

    if matches.Length = 1
        return matches[1]
    return {state:"unknown", x:0, y:0,
        note:matches.Length ? "多个匹配按钮（拒绝点击）" : "无有效蓝色圆形或图标"}
}

IconKind(image, cx, cy, radius) {
    rowInfo := []
    top := Round(cy - radius * 0.58)
    bottom := Round(cy + radius * 0.58)
    Loop bottom - top + 1 {
        y := top + A_Index - 1
        width := 0, firstX := 2147483647
        left := Round(cx - radius * 0.65)
        right := Round(cx + radius * 0.65)
        Loop right - left + 1 {
            x := left + A_Index - 1
            if IsWhite(ReadPixel(image, x, y)) {
                width += 1
                firstX := Min(firstX, x)
            }
        }
        if width
            rowInfo.Push({width:width, left:firstX})
    }

    n := rowInfo.Length
    if (n < 5 || n > Round(radius * 1.35))
        return "unknown"
    peak := 0, narrowest := 2147483647
    minLeft := 2147483647, maxLeft := -2147483647
    for item in rowInfo {
        peak := Max(peak, item.width)
        narrowest := Min(narrowest, item.width)
        minLeft := Min(minLeft, item.left)
        maxLeft := Max(maxLeft, item.left)
    }
    if peak < 5
        return "unknown"

    edgeMean := (rowInfo[1].width + rowInfo[2].width
        + rowInfo[n-1].width + rowInfo[n].width) / 4.0
    taper := peak - edgeMean
    if (taper >= Max(2.0, peak * 0.28)
        && maxLeft - minLeft <= Max(2, Round(radius * 0.22)))
        return "triangle"
    if (taper <= Max(1.0, peak * 0.18)
        && narrowest >= peak * 0.72)
        return "square"
    return "unknown"
}

WriteLog(message) {
    global gLog
    try FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") " | "
        message "`r`n", gLog, "UTF-8")
}

TestHelpers() {
    if (!IsBlue(0x2C67C5) || IsBlue(0xFFFFFF)
        || !IsWhite(0xFFFFFF) || IsWhite(0x2C67C5)
        || !SamePoint({x:10,y:10}, {x:13,y:13})
        || SamePoint({x:10,y:10}, {x:20,y:20}))
        throw Error("颜色/坐标基础自检失败")

    square := SyntheticImage("square")
    triangle := SyntheticImage("triangle")
    if (ClassifyScreenshot(square).state != "square")
        throw Error("合成方形识别失败")
    if (ClassifyScreenshot(triangle).state != "triangle")
        throw Error("合成三角形识别失败")
    ; Recovery state is independent from clicking/UI.
    p := BlankProgress()
    p := AdvanceRecovery("square", 1000, p)
    p := AdvanceRecovery("square", 1250, p)
    if p.done
        throw Error("连续方形不足500ms却提前解锁")
    p := AdvanceRecovery("square", 1500, p)
    if !p.done
        throw Error("稳定方形未解锁")
    p := AdvanceRecovery("triangle", 1750, p)
    if p.done || p.samples != 0
        throw Error("三角形未清空候选方形")
    p := AdvanceRecovery("square", 2000, p)
    p := AdvanceRecovery("unknown", 2250, p)
    if p.done || p.samples != 0
        throw Error("unknown 未清空候选方形")
    FileAppend("PASS v0.3: colors / geometry / square / triangle / recovery`n", "*")
}

SyntheticImage(shape) {
    w := 80, h := 80, out := Buffer(w * h * 4, 0)
    ; Even coordinates ensure the 2px sample grid reaches the blue disk.
    cx := 40, cy := 40
    Loop h {
        y := A_Index - 1
        Loop w {
            x := A_Index - 1
            dx := x - cx, dy := y - cy
            if (dx*dx + dy*dy <= 12*12) {
                rgb := 0x2C67C5
                if shape = "square" {
                    if (dx >= -3 && dx <= 3 && dy >= -3 && dy <= 3)
                        rgb := 0xFFFFFF
                } else if (dy >= -3 && dy <= 3 && dx >= -2
                    && dx <= 4 - Abs(dy)) {
                    rgb := 0xFFFFFF
                }
                NumPut("UInt", rgb, out, (y*w+x)*4)
            }
        }
    }
    return {w:w, h:h, buffer:out}
}
