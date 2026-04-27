# AutoHotKey Shortcut

让 Windows 接近 niri 的窗口快捷键和其他方便的快捷键

- 禁止单个 Win 键
- Win + F 窗口最大化
- Win + C 窗口居中
- Win + R 切换窗口 1/3 1/2 2/3
- Win + ← → 窗口左半屏，窗口右半屏
- Win + ↑ ↓ 窗口向上移动到边缘，窗口向下移动到边缘
- Win + [ ] 使窗口移动到左侧虚拟桌面、右侧虚拟桌面，如果右侧虚拟桌面不存在则自动创建
- Win + 滚轮上 切换到左侧虚拟桌面
- Win + 滚轮下 切换到右侧虚拟桌面
- Win + 9 关闭当前虚拟桌面
- Win + 0 创建新的虚拟桌面
- Win + Q 关闭窗口
- Win + T 打开终端
- Win + Shift + T 以管理员方式打开终端
- Win + Space 打开开始菜单
- Win + + 使窗口向预期一侧增加水平方向
- Win + - 使窗口向预期一侧缩小水平方向
- Win + Shift + + 使窗口增加垂直方向
- Win + Shift + - 使窗口缩小垂直方向
- Alt + Space 切换输入法
- 禁止 CapsLock 键切换大小写
- CapsLock 映射为右 Shift（第三方中文输入法设置为 右Shift 切换中英文）
- Win + F11 重载脚本
- Win + F12 退出脚本

## 使用方法

1. 安装 [AutoHotKey v2.0](https://www.autohotkey.com/)
2. `shortcut.ahk` 以管理员方式运行

⚠️ 注意：Win + 滚轮 以及 [ ] 功能需要 [VirtualDesktopAccessor.dll](https://github.com/ciantic/virtualdesktopAccessor) 下载后放到 `shortcut.ahk` 同级目录即可

设置开机自启：

1. 修改 `create_task_scheduler.ps1` 中的 `$Arguments` 修改为 `shortcut.ahk` 的路径
2. 以管理员方式运行 `create_task_scheduler.ps1`，这个脚本会创建开机自启的计划任务