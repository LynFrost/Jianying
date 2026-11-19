#NoEnv
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
        } else if (StateA = 0) {
            if WinExist(WindowB_Title)
                WinRestore, %WindowB_Title%
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
        } else if (StateB = 0) {
            if WinExist(WindowA_Title)
                WinRestore, %WindowA_Title%
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
