# Key Manager Replacement

基于 **AutoHotkey v2** 的 Windows 全局快捷键替代脚本，用于将小键盘按键映射为常用系统快捷键、鼠标操作、滚轮操作，以及 flomo、Cherry Studio、Everything 等应用的启动入口。

当前主程序：**`key-manager-replacement-v0.06.ahk`**。

## 功能概览

- 小键盘单键映射为 Windows 快捷键或常用应用启动键。
- 右 Shift + 方向键映射为窗口管理快捷键。
- 左 Ctrl + 小键盘组合键提供窗口切换、复制粘贴、鼠标点击及窗口操作。
- 左 Ctrl + 小键盘减号/加号发送 8 次滚轮事件。
- Shift + 小键盘减号/加号发送 18 次滚轮事件。
- 滚轮操作会暂存物理修饰键状态，并在滚轮发送后恢复仍实际按住的修饰键。
- 脚本退出时释放鼠标左键和逻辑修饰键，降低按键状态残留风险。

## 环境要求

- Windows
- **AutoHotkey v2.0**（不兼容 AutoHotkey v1）

脚本没有额外的第三方库依赖。

## 安装与启动

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 下载或克隆本仓库。
3. 双击根目录中的 `key-manager-replacement-v0.06.ahk`，或使用 AutoHotkey v2 打开该文件。
4. 脚本启动后会驻留在 Windows 系统托盘，快捷键映射随即生效。

```powershell
git clone https://github.com/LynFrost/Jianying.git
cd Jianying
```

暂停或退出：在系统托盘找到 AutoHotkey 脚本图标，使用托盘菜单中的 **Pause Script** 或 **Exit**。再次启动脚本即可重新启用映射。

## 快捷键映射

以下为当前 `key-manager-replacement-v0.06.ahk` 中实际定义的映射。

### 小键盘单键

| 按键 | 功能 |
| --- | --- |
| `Numpad 9` | `Win + 9` |
| `Numpad 8` | `Win + 8` |
| `Numpad 7` | `Win + 7` |
| `Numpad 6` | `Win + 6` |
| `Numpad 4` | `Win + 0` |
| `Numpad 5` | 启动 flomo |
| `Numpad 2` | 启动 Cherry Studio |
| `Numpad 1` | 启动 Everything |

应用启动时会依次检查脚本中列出的常见安装路径；若未找到，再尝试通过程序名启动。仍无法启动时会显示提示。若应用安装在其他位置，可编辑脚本中对应的路径列表。

### 其他单键

| 按键 | 功能 |
| --- | --- |
| 扫描码 `SC029` | 发送 `Right Alt + VK_BF` |

`SC029` 的物理位置会受键盘布局影响。脚本注释按常见美式键盘布局将其标记为反引号/波浪号键；`VK_BF` 对应 OEM `/ ?` 虚拟键。

### 右 Shift + 方向键

| 快捷键 | 功能 |
| --- | --- |
| `Right Shift + ↑` | `Win + ↑`（窗口最大化） |
| `Right Shift + ↓` | `Win + Tab`（任务视图） |
| `Right Shift + ←` | `Win + Shift + ←`（将窗口移至左侧显示器） |
| `Right Shift + →` | `Win + Shift + →`（将窗口移至右侧显示器） |

### 左 Ctrl + 小键盘

| 快捷键 | 功能 |
| --- | --- |
| `Left Ctrl + Numpad .` | Windows 原生 `Alt + Tab` 窗口切换 |
| `Left Ctrl + Numpad 1` | `Ctrl + X`（剪切） |
| `Left Ctrl + Numpad 2` | `Ctrl + C`（复制） |
| `Left Ctrl + Numpad 3` | `Ctrl + V`（粘贴） |
| `Left Ctrl + Numpad 4` | `Alt + F4`（关闭当前窗口） |
| `Left Ctrl + Numpad 5` | 鼠标左键单击 |
| `Left Ctrl + Numpad 6` | 鼠标右键单击 |
| `Left Ctrl + Numpad 7` | 释放鼠标左键（Left Button Up） |
| `Left Ctrl + Numpad 8` | 按下并保持鼠标左键（Left Button Down） |
| `Left Ctrl + Numpad 9` | `Ctrl + W`（关闭当前标签/文档） |
| `Left Ctrl + Numpad -` | 向上滚动 8 次 |
| `Left Ctrl + Numpad +` | 向下滚动 8 次 |
| `Left Ctrl + Numpad *` | 发送 `Right Alt + Space + N` 窗口菜单序列，尝试最小化窗口 |

### Shift + 小键盘滚轮

| 快捷键 | 功能 |
| --- | --- |
| `Shift + Numpad -` | 向上滚动 18 次 |
| `Shift + Numpad +` | 向下滚动 18 次 |

这里的滚轮次数指发送的标准滚轮事件数量。不同应用对滚轮步进、页面滚动和平滑滚动的处理不同，因此实际滚动距离可能不同。

## 输入状态与使用注意

- 这是全局热键脚本，映射会影响当前活动应用，不限于某一个软件。
- `Left Ctrl + Numpad 8` 和 `Left Ctrl + Numpad 7` 是鼠标左键按下/释放的一组操作；使用后应确保最终释放左键。脚本退出时也会尝试释放左键。
- 滚轮函数会记录左、右 Ctrl、Shift、Alt、Win 的物理按键状态，发送滚轮事件前暂时释放修饰键，再按执行结束时的物理状态恢复仍被按住的键。
- `Right Shift` 方向键映射只针对右 Shift；左 Shift 不触发这组映射。
- `Left Ctrl` 小键盘映射只针对左 Ctrl；右 Ctrl 不触发这组映射。
- `Right Alt + Space + N` 的最小化行为依赖 Windows 窗口系统菜单对该按键的解释；不同系统语言或应用可能表现不同。
- 管理员权限窗口、远程桌面、虚拟机、游戏或使用特殊输入处理的软件，可能对模拟按键/鼠标事件有不同处理。若目标程序以管理员身份运行，可能需要以相同权限启动脚本。
- 首次使用或修改映射后，建议逐项验证快捷键，避免与当前软件自身的快捷键冲突。

## 配置与维护

当前版本的应用程序路径和滚轮参数直接写在脚本顶部及对应函数中：

| 配置项 | 当前值 | 说明 |
| --- | --- | --- |
| `Version` | `V0.06` | 托盘提示中的版本标识 |
| `WheelSteps` | `8` | 左 Ctrl + 小键盘减号/加号的滚轮事件数量 |
| `ShiftWheelSteps` | `18` | Shift + 小键盘减号/加号的滚轮事件数量 |
| `WheelDelayMs` | `15` | 相邻滚轮事件之间的延迟（毫秒） |

应用路径可在 `Numpad5`、`Numpad2`、`Numpad1` 对应的 `RunFirstExisting()` 参数中调整。

## 版本与文档

- 当前版本脚本：[`key-manager-replacement-v0.06.ahk`](key-manager-replacement-v0.06.ahk)
- v0.06 升级方案：[`docs/key-manager-replacement-v0.06-upgrade-plan.txt`](docs/key-manager-replacement-v0.06-upgrade-plan.txt)
- v0.05 升级方案：[`docs/key-manager-replacement-v0.05-upgrade-plan.txt`](docs/key-manager-replacement-v0.05-upgrade-plan.txt)
- v0.04 升级方案：[`docs/key-manager-replacement-v0.04-upgrade-plan.txt`](docs/key-manager-replacement-v0.04-upgrade-plan.txt)
- v0.03 升级方案：[`docs/key-manager-replacement-v0.03-upgrade-plan.txt`](docs/key-manager-replacement-v0.03-upgrade-plan.txt)

历史脚本保存在 [`achieve/`](achieve/) 目录中。当前根目录的 v0.06 脚本为主版本；历史文件用于回溯，不应与当前版本同时运行。

## 仓库结构

```text
Jianying/
├── key-manager-replacement-v0.06.ahk
├── docs/
│   ├── key-manager-replacement-v0.03-upgrade-plan.txt
│   ├── key-manager-replacement-v0.04-upgrade-plan.txt
│   ├── key-manager-replacement-v0.05-upgrade-plan.txt
│   └── key-manager-replacement-v0.06-upgrade-plan.txt
└── achieve/
    └── 历史版本脚本
```

