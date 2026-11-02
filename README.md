# Jianying

这是一个面向 **Windows** 的 **AutoHotkey v2** 脚本仓库，包含三个相互独立的小工具：

- **CodexMonitor**：监控 ChatGPT Windows 桌面客户端的按钮状态，并在满足条件时尝试自动恢复。
- **TwinCAT_F6F7**：为 TwinCAT XAE Shell 增加 POU 编辑区视图切换与 PLC 登录/退出快捷键。
- **key-manager-replacement**：用小键盘及组合键实现全局快捷键、应用启动、鼠标与滚轮操作。

各工具独立运行，没有统一安装程序；**按需启动对应子目录下的脚本即可**。

## 项目一览

| 目录 | 当前入口 | 主要用途 |
| --- | --- | --- |
| [CodexMonitor/](CodexMonitor/) | [`CodexMonitor.ahk`](CodexMonitor/CodexMonitor.ahk) | ChatGPT 桌面客户端状态检测、条件性恢复操作（v0.4） |
| [TwinCAT_F6F7/](TwinCAT_F6F7/) | [`TwinCAT_F6_POU_F7_LoginToggle.ahk`](TwinCAT_F6F7/TwinCAT_F6_POU_F7_LoginToggle.ahk) | TwinCAT XAE Shell 的 F6 / F7 快捷键（v0.01） |
| [key-manager-replacement/](key-manager-replacement/) | [`key-manager-replacement.ahk`](key-manager-replacement/key-manager-replacement.ahk) | Windows 全局按键映射（v0.06） |

> **注意文件路径**：以上入口均在各自的子目录中。旧版资料可能使用带版本号的脚本文件名，运行时请以本表列出的**仓库实际文件名**为准。

## 环境与启动

1. 在 Windows 上安装 [AutoHotkey v2](https://www.autohotkey.com/)（**不兼容 v1**）。
2. 下载本仓库，或使用 Git 克隆：

   ```powershell
   git clone https://github.com/LynFrost/Jianying.git
   cd Jianying
   ```

3. 双击需要的 `.ahk` 主脚本（确保文件关联到 AutoHotkey v2），脚本将运行并通常驻留在系统托盘。
4. 不再使用时，通过系统托盘中对应的 AutoHotkey 图标退出脚本。

也可以使用 AutoHotkey v2 解释器显式运行脚本，例如：

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\CodexMonitor\CodexMonitor.ahk"
```

其中解释器路径是常见的 64 位默认安装位置；若安装位置不同，请调整路径。CodexMonitor 另提供 [`双击启动.cmd`](CodexMonitor/双击启动.cmd)，它使用上述**固定解释器路径**，并非自动搜索安装位置。

## CodexMonitor：ChatGPT 桌面客户端监控

**主程序：** [`CodexMonitor/CodexMonitor.ahk`](CodexMonitor/CodexMonitor.ahk)  
**详细说明：** [`CodexMonitor/docs/README_v0.4.md`](CodexMonitor/docs/README_v0.4.md)

该脚本面向 Windows 版 **ChatGPT 桌面客户端（`ChatGPT.exe`）**，通过 Windows UI Automation（UIA）检查界面下部按钮；当 ChatGPT 窗口位于前台且 UIA 不能可靠识别时，才使用屏幕图像识别作为回退方案。

| 快捷键 | 功能 |
| --- | --- |
| `Ctrl + Shift + F12` | 启动或停止监控 |
| `Ctrl + Shift + F11` | 在自动模式与**测试模式（只检测，绝不点击）**之间切换 |
| `Ctrl + Shift + F10` | 只读 UIA 诊断；将候选按钮的标签、坐标、可调用性写入日志 |

**工作逻辑与保护措施：**

- 启动后约每 **10 秒**检查一次；目标窗口暂时不存在时继续等待，不强行操作。
- 只有连续 **3 次**将同一按钮识别为“继续/发送”类三角形状态，才允许尝试一次操作；操作前先锁定。
- 操作后会在短时间内进行较高频率的恢复检测；必须连续观察到至少 **3 次**方形状态，且时间跨度至少 **500 毫秒**，才能解除锁定，防止重复点击。
- 后台窗口只尝试使用 **UIA InvokePattern**；普通鼠标点击仅允许在 ChatGPT 本身处于前台时进行。
- 如果目标窗口最小化、存在多个无法区分的候选、识别不可靠或按钮不可调用，选择**不点击**，不会为了点击而主动切换窗口焦点。

**推荐首次使用方式：** 启动脚本后，先按 `Ctrl + Shift + F11` 切换为测试模式，再按 `Ctrl + Shift + F12` 开始监控；查看悬浮状态及日志，确认识别符合预期后再考虑自动模式。默认启动时为**自动模式**，监控本身默认关闭。

日志路径：`CodexMonitor/CodexMonitor_v0.4.log`（运行时生成）。

### 可选自检

以下参数由当前脚本支持，均不会执行自动点击：

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\CodexMonitor\CodexMonitor.ahk" --self-test
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\CodexMonitor\CodexMonitor.ahk" --uia-test
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\CodexMonitor\CodexMonitor.ahk" --capture-test
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\CodexMonitor\CodexMonitor.ahk" --screen-test
```

UIA 依赖库已包含在 [`CodexMonitor/vendor/UIA-v2/`](CodexMonitor/vendor/UIA-v2/) 中，无需单独下载；其第三方许可证和来源信息分别见 [`LICENSE`](CodexMonitor/vendor/UIA-v2/LICENSE) 与 [`SOURCE.txt`](CodexMonitor/vendor/UIA-v2/SOURCE.txt)。

**适用边界：** 后台控制能力取决于当前 ChatGPT 版本是否提供可识别、可调用的 UIA 按钮；不保证在所有版本或窗口布局下成功。脚本不通过 ChatGPT API 判断任务是否真正中断，也不支持操作浏览器版 ChatGPT。首次使用请人工核验识别结果，勿直接用于无人值守的关键任务。

## TwinCAT_F6F7：POU 视图与 PLC 登录切换

**主程序：** [`TwinCAT_F6F7/TwinCAT_F6_POU_F7_LoginToggle.ahk`](TwinCAT_F6F7/TwinCAT_F6_POU_F7_LoginToggle.ahk)

快捷键**仅在 `TcXaeShell.exe`（TwinCAT XAE Shell）为活动窗口时生效**，不会覆盖其他程序的 F6 / F7。

| 快捷键 | 功能 |
| --- | --- |
| `F6` | 在 POU 编辑器的“声明 + 实现”→“仅声明”→“仅实现”三种布局间循环切换 |
| `F7` | 根据 PLC 当前命令可用性，在登录（Login）和退出（Logout）之间切换 |

- F6 通过识别当前 POU 分隔区域并操作其控制箭头完成切换；识别不到合适的分隔区域时，会回退发送原始 `F6`。
- F6 操作会**短暂移动鼠标并点击界面**，完成后尝试恢复原鼠标位置；切换前请确认目标 POU 编辑器已打开。
- F7 使用 TwinCAT XAE Shell 的 DTE COM 命令接口（`PLC.Logintonone` / `PLC.Logoutfromnone`）；如果接口不可访问或状态无法判断，会显示短暂提示，而不盲目执行。
- 脚本检测到标准安装路径中的 `AutoHotkey64_UIA.exe` 时，会尝试用 UI Access 版本重新启动，以适配提权运行的 XAE Shell；具体效果仍取决于本机安装和权限。

脚本还支持 `--probe`、`--login-probe` 只读检查参数，以及会**实际切换编辑区布局**的 `--cycle-test`。建议先在非关键工程窗口中验证 F6/F7 行为。

## key-manager-replacement：全局快捷键映射

**主程序：** [`key-manager-replacement/key-manager-replacement.ahk`](key-manager-replacement/key-manager-replacement.ahk)  
**当前版本：** v0.06；[升级方案记录](key-manager-replacement/docs/key-manager-replacement-v0.06-upgrade-plan.txt)

这是一个**全局热键脚本**，启动后快捷键会影响当前活动应用。

### 小键盘单键

| 按键 | 动作 |
| --- | --- |
| `Numpad 9 / 8 / 7 / 6` | 分别发送 `Win + 9 / 8 / 7 / 6` |
| `Numpad 4` | 发送 `Win + 0` |
| `Numpad 5` | 启动 flomo |
| `Numpad 2` | 启动 Cherry Studio |
| `Numpad 1` | 启动 Everything |

应用启动会先尝试脚本中的常见安装路径，再尝试程序名；如果安装位置不同，可修改 `Numpad5`、`Numpad2`、`Numpad1` 对应的 `RunFirstExisting()` 路径列表。

### 组合键

| 快捷键 | 动作 |
| --- | --- |
| `右 Shift + ↑` | `Win + ↑`（最大化窗口） |
| `右 Shift + ↓` | `Win + Tab`（任务视图） |
| `右 Shift + ← / →` | `Win + Shift + ← / →`（在显示器间移动窗口） |
| `左 Ctrl + Numpad .` | `Alt + Tab` 窗口切换 |
| `左 Ctrl + Numpad 1 / 2 / 3` | 剪切 / 复制 / 粘贴 |
| `左 Ctrl + Numpad 4` | `Alt + F4`（关闭当前窗口） |
| `左 Ctrl + Numpad 5 / 6` | 鼠标左键 / 右键单击 |
| `左 Ctrl + Numpad 7 / 8` | 释放 / 按住鼠标左键 |
| `左 Ctrl + Numpad 9` | `Ctrl + W`（关闭标签页或文档） |
| `左 Ctrl + Numpad - / +` | 向上 / 向下发送 **8 次**滚轮事件 |
| `Shift + Numpad - / +` | 向上 / 向下发送 **18 次**滚轮事件 |
| `左 Ctrl + Numpad *` | 发送 `右 Alt + Space + N` 窗口菜单序列，尝试最小化 |

另有扫描码 `SC029` → `右 Alt + VK_BF` 的映射，其物理键位置因键盘布局而异。

滚轮间隔由 `WheelDelayMs := 15`（毫秒）控制；滚轮操作会暂时释放逻辑修饰键，并根据执行结束时的实际物理按键状态恢复。**滚轮次数不等于固定的页面滚动距离**，实际效果取决于应用。

特别注意：`左 Ctrl + Numpad 8` 会按住鼠标左键，需用 `左 Ctrl + Numpad 7` 释放；脚本退出时也会尝试释放。快捷键可能与软件原生操作冲突，管理员窗口、远程桌面及特殊输入程序对模拟事件的响应可能不同。

## 目录结构

```text
Jianying/
├── README.md
├── CodexMonitor/
│   ├── CodexMonitor.ahk
│   ├── 双击启动.cmd
│   ├── VERSION_v0.4.txt
│   ├── docs/
│   ├── vendor/UIA-v2/
│   └── achieve/
├── TwinCAT_F6F7/
│   ├── TwinCAT_F6_POU_F7_LoginToggle.ahk
│   ├── VERSION_v0.01.txt
│   └── achieve/
└── key-manager-replacement/
    ├── key-manager-replacement.ahk
    ├── VERSION_v0.06.txt
    ├── docs/
    └── achieve/
```

- 各子目录的 `achieve/` 保存历史脚本，当前使用请优先选择上文的主程序，避免新旧版本同时运行造成热键冲突。
- `docs/` 包含版本说明、使用记录或升级方案。部分历史文档中的脚本文件名、操作限制可能与当前主程序不同，应以**当前代码**为准。
- 本仓库只提供脚本及随附资源；各工具需要的第三方桌面应用（ChatGPT、TwinCAT、flomo 等）须按实际用途自行安装。
