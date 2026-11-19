#NoEnv






; 创建启动时的欢迎GUI
Gui, 2:+AlwaysOnTop -Caption +ToolWindow
Gui, 2:Color, 00FF00  ; 设置背景色为绿色
Gui, 2:+LastFound     ; 获取当前GUI的句柄
WinSet, TransColor, 00FF00 255  ; 将绿色背景设为透明
Gui, 2:Font, s60 cFF8000 Bold    ; 设置字体
Gui, 2:Add, Text, vWelcomeText w1000 h100 Center, 王五杂货铺 制作
; 添加ElectrumCertificate信息行
Gui, 2:Font, s30 cFF8000 Bold    ; 为证书信息设置较小的字体
Gui, 2:Add, Text, w1000 h120 y+10 Center, Electrum Certificate: bc1qnvk39frv3yu6l40d7gyjdfneu3xne88t4u230y

; 获取屏幕尺寸以计算中心位置
SysGet, MonitorWorkArea, MonitorWorkArea
WelcomeWidth := 1200
WelcomeHeight := 400  ; 增加高度以容纳额外的文本行
WelcomeX := (MonitorWorkAreaRight - WelcomeWidth) / 2
WelcomeY := (MonitorWorkAreaBottom - WelcomeHeight) / 2

; 显示欢迎信息
Gui, 2:Show, x%WelcomeX% y%WelcomeY% w%WelcomeWidth% h%WelcomeHeight% NA

; 3秒后关闭欢迎界面
SetTimer, CloseWelcome, -3000






#SingleInstance Force
SetTitleMatchMode, 2
DetectHiddenWindows, Off

;--------------- 自定义区域 ---------------
; 启动时获取窗口句柄（确保精准匹配）
WinGet, hWindowA, ID, ahk_exe Chatbox.exe
WinGet, hWindowB, ID, ahk_exe Cherry Studio.exe
WindowA_Title := "ahk_id " hWindowA
WindowB_Title := "ahk_id " hWindowB
;------------------------------------------

SetTimer, SyncWindows, 300
LastStateA := ""
LastStateB := ""
isProcessing := false

SyncWindows:
    if (isProcessing)
        return
    
    WinGet, StateA, MinMax, %WindowA_Title%
    WinGet, StateB, MinMax, %WindowB_Title%
    
    ; 同步A→B
    if (StateA != LastStateA) {
        isProcessing := true
        tooltip 窗口A状态：%StateA%
        SetTimer, RemoveToolTip, 1000
        
        if (StateA = -1) {
            if WinExist(WindowB_Title)
                WinMinimize, %WindowB_Title%
        }
        
        LastStateA := StateA
        Sleep 300
        isProcessing := false
    }
    
    ; 同步B→A
    if (StateB != LastStateB) {
        isProcessing := true
        tooltip 窗口B状态：%StateB%
        SetTimer, RemoveToolTip, 1000
        
        if (StateB = -1) {
            if WinExist(WindowA_Title)
                WinMinimize, %WindowA_Title%
        }
        
        LastStateB := StateB
        Sleep 300
        isProcessing := false
    }
Return

RemoveToolTip:
    ToolTip
Return

^!r::Reload
^!q::ExitApp




; 添加关闭欢迎界面的标签（在现有代码的末尾添加）
CloseWelcome:
    Gui, 2:Destroy
return