; 在屏幕右下角显示按键状态
#NoEnv
#SingleInstance Force
SetBatchLines, -1

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

; 创建GUI
Gui, +AlwaysOnTop -Caption +ToolWindow
Gui, Color, 00FF00  ; 设置背景色为绿色
Gui, +LastFound     ; 获取当前GUI的句柄
WinSet, TransColor, 00FF00 255  ; 将绿色背景设为透明
Gui, Font, s36 cFF8000 Bold    ; 设置字体大小为原来的30%(120*0.3=36)
Gui, Add, Text, vKeyDisplay w800 h300 Center  ; 文本控件

; 获取屏幕尺寸
SysGet, MonitorWorkArea, MonitorWorkArea
GuiWidth := 650
GuiHeight := 150

; 确保GUI完全在工作区内
ScreenX := MonitorWorkAreaRight - GuiWidth - 20  ; 额外留出20像素的边距
ScreenY := MonitorWorkAreaBottom - GuiHeight - 20  ; 额外留出20像素的边距
Gui, Show, x%ScreenX% y%ScreenY% w%GuiWidth% h%GuiHeight% NA

; 安装键盘钩子以确保捕获所有按键
#InstallKeybdHook

; 为所有按键创建通用处理器
#If true  ; 应用于所有情况
~*a up::
~*b up::
~*c up::
~*d up::
~*e up::
~*f up::
~*g up::
~*h up::
~*i up::
~*j up::
~*k up::
~*l up::
~*m up::
~*n up::
~*o up::
~*p up::
~*q up::
~*r up::
~*s up::
~*t up::
~*u up::
~*v up::
~*w up::
~*x up::
~*y up::
~*z up::
~*0 up::
~*1 up::
~*2 up::
~*3 up::
~*4 up::
~*5 up::
~*6 up::
~*7 up::
~*8 up::
~*9 up::
~*Space up::
~*Tab up::
~*Enter up::
~*Escape up::
~*Backspace up::
~*Delete up::
~*Insert up::
~*Home up::
~*End up::
~*PgUp up::
~*PgDn up::
~*Up up::
~*Down up::
~*Left up::
~*Right up::
~*CapsLock up::
~*NumLock up::
~*ScrollLock up::
~*LControl up::
~*RControl up::
~*LShift up::
~*RShift up::
~*LAlt up::
~*RAlt up::
~*LWin up::
~*RWin up::
~*AppsKey up::
~*F1 up::
~*F2 up::
~*F3 up::
~*F4 up::
~*F5 up::
~*F6 up::
~*F7 up::
~*F8 up::
~*F9 up::
~*F10 up::
~*F11 up::
~*F12 up::
~*Numpad0 up::
~*Numpad1 up::
~*Numpad2 up::
~*Numpad3 up::
~*Numpad4 up::
~*Numpad5 up::
~*Numpad6 up::
~*Numpad7 up::
~*Numpad8 up::
~*Numpad9 up::
~*NumpadDot up::
~*NumpadDiv up::
~*NumpadMult up::
~*NumpadAdd up::
~*NumpadSub up::
~*NumpadEnter up::
~*PrintScreen up::
~*Pause up::
~*[ up::
~*] up::
~*\ up::
~*; up::
~*' up::
~*, up::
~*. up::
~*/ up::
~*- up::
~*= up::
~*` up::
    ; 修改所有按键显示为"功德+1"
    keyName := "功德+1"
    
    ; 设置字体大小为原来的30%
    fontSize := 36  ; 120 * 0.3 = 36
    
    ; 更新字体大小
    Gui, Font, s%fontSize% cFF8000 Bold
    GuiControl, Font, KeyDisplay
    
    ; 确保显示窗口大小适合当前文本
    Gui, Show, x%ScreenX% y%ScreenY% w%GuiWidth% h%GuiHeight% NoActivate
    
    ; 更新显示
    GuiControl,, KeyDisplay, %keyName%
    SetTimer, ClearDisplay, -100  ; 显示时间缩短到0.01秒(10毫秒)
return

ClearDisplay:
    GuiControl,, KeyDisplay, 
    ; 恢复默认GUI大小和位置
    Gui, Show, x%ScreenX% y%ScreenY% w%GuiWidth% h%GuiHeight% NoActivate
return

; 添加关闭欢迎界面的标签
CloseWelcome:
    Gui, 2:Destroy
return
