#Requires AutoHotkey v2
#SingleInstance Force
#UseHook


; 必须要以管理员方式运行
if !A_IsAdmin
{
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}


; 屏蔽左 Win 键
~LWin::Send("{Blind}{vkE8}")


; 屏蔽右 Win 键
~RWin::Send("{Blind}{vkE8}")

; 窗口对于桌面边缘的边距
global margin := 16


; [新增后台辅助函数] 获取窗口隐形边框在 左右、上、下 三个维度的真实差值
; 这样可以保证你下方每一个独立功能的内部代码逻辑清晰完整=
GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom) {
    try {
        FrameRect := Buffer(16)
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", FrameRect, "uint", 16)
        fLeft   := NumGet(FrameRect, 0, "int")
        fTop    := NumGet(FrameRect, 4, "int")
        fBottom := NumGet(FrameRect, 12, "int")
        
        WinGetPos(&wX, &wY, &wW, &wH, "ahk_id " hwnd)
        
        offsetX      := fLeft - wX
        offsetY      := fTop - wY
        offsetBottom := (wY + wH) - fBottom
    } catch {
        offsetX := 0, offsetY := 0, offsetBottom := 0
    }
}


; Win + F 窗口最大化
#f::
{
    hwnd := WinExist("A")
    if !hwnd
        return

    if WinGetMinMax(hwnd) = -1
        WinRestore(hwnd)

    ; 1. 获取当前显示器的工作区信息
    hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")
    mi := Buffer(40, 0)
    NumPut("uint", 40, mi, 0)
    DllCall("GetMonitorInfo", "ptr", hMon, "ptr", mi)

    left   := NumGet(mi, 20, "int")
    top    := NumGet(mi, 24, "int")
    right  := NumGet(mi, 28, "int")
    bottom := NumGet(mi, 32, "int")

    ; 2. 基础的留边位置计算（假设无边框时的理想状态）
    x := left + margin
    y := top + margin
    w := (right - left) - margin * 2
    h := (bottom - top) - margin * 2

    ; 3. 核心：分别计算当前窗口【左、上、底】三边的隐形边框补偿量
    GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)

    ; 4. 将不对称的补偿量精准应用到坐标和宽高上
    x := x - offsetX
    y := y - offsetY
    w := w + (offsetX * 2) 
    h := h + offsetY + offsetBottom 

    ; 5. 执行移动
    if WinGetMinMax(hwnd) = 1
        WinRestore(hwnd)

    WinMove(x, y, w, h, hwnd)
}


; Win + C 窗口居中
#c::
{
    hwnd := WinGetID("A")
    
    ; 获取 DWM 视觉大小来进行更精准的居中计算，防止传统 WinGetPos 算偏
    try {
        FrameRect := Buffer(16)
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", FrameRect, "uint", 16)
        w := NumGet(FrameRect, 8, "int") - NumGet(FrameRect, 0, "int")
        h := NumGet(FrameRect, 12, "int") - NumGet(FrameRect, 4, "int")
    } catch {
        WinGetPos(, , &w, &h, hwnd)
    }

    hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")

    mi := Buffer(40, 0)
    NumPut("uint", 40, mi, 0)

    DllCall("GetMonitorInfo", "ptr", hMon, "ptr", mi)

    left   := NumGet(mi, 20, "int") + margin
    top    := NumGet(mi, 24, "int") + margin
    right  := NumGet(mi, 28, "int") - margin
    bottom := NumGet(mi, 32, "int") - margin

    workW := right - left
    workH := bottom - top

    newX := left + (workW - w) // 2
    newY := top + (workH - h) // 2

    ; 智能补偿隐形边框
    GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)
    newX := newX - offsetX
    newY := newY - offsetY

    WinMove(newX, newY, , , hwnd)
}


; Win + ← → 窗口左半屏，窗口右半屏

SnapLeft() {
    global margin

    hwnd := WinExist("A")
    if !hwnd
        return

    MonitorGetWorkArea(, &l, &t, &r, &b)

    ; 1. 理想状态下的四边边界（预留外部边距）
    l += margin
    t += margin
    r -= margin
    b -= margin

    ; 2. 核心：计算扣除中间 16px 边距后的单窗口宽度
    ; 我们需要在总宽度里再扣掉一个 margin，然后平分
    w := ((r - l) - margin) // 2
    h := b - t

    WinRestore("A")
    Sleep 30

    ; 智能补偿隐形边框
    GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)
    realX := l - offsetX
    realY := t - offsetY
    realW := w + (offsetX * 2)
    realH := h + offsetY + offsetBottom

    WinMove(realX, realY, realW, realH, "A")
}

SnapRight() {
    global margin

    hwnd := WinExist("A")
    if !hwnd
        return

    MonitorGetWorkArea(, &l, &t, &r, &b)

    ; 1. 理想状态下的四边边界（预留外部边距）
    l += margin
    t += margin
    r -= margin
    b -= margin

    ; 2. 核心：计算单窗口宽度，并让右侧窗口的 X 轴加上（窗口宽 + 中间边距）
    w := ((r - l) - margin) // 2
    h := b - t
    x := l + w + margin  ; 右侧窗口的起点需要跨过左侧窗口和中间的 margin

    WinRestore("A")
    Sleep 30

    ; 智能补偿隐形边框
    GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)
    realX := x - offsetX
    realY := t - offsetY
    realW := w + (offsetX * 2)
    realH := h + offsetY + offsetBottom

    WinMove(realX, realY, realW, realH, "A")
}

#Left::SnapLeft()
#Right::SnapRight()


; Win + ↑ 窗口向上移动到边缘
#Up::MoveActiveWindowY(-1)

; Win + ↓ 窗口向下移动到边缘
#Down::MoveActiveWindowY(1)

MoveActiveWindowY(direction)
{
    global margin

    hwnd := WinExist("A")
    if !hwnd
        return

    ; 为了防止传统 WinGetPos 包含透明边框导致贴边不准，这里提取视觉高
    try {
        FrameRect := Buffer(16)
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", FrameRect, "uint", 16)
        h := NumGet(FrameRect, 12, "int") - NumGet(FrameRect, 4, "int")
    } catch {
        WinGetPos(, , , &h, "ahk_id " hwnd)
    }

    WinGetPos(&x, &y, &w, , "ahk_id " hwnd)

    ; 获取工作区
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)

    ; 可移动范围（上下都保留 margin）
    minY := top + margin
    maxY := bottom - h - margin

    ; 直接贴边移动
    if (direction < 0)
        newY := minY      ; 上移到底
    else
        newY := maxY      ; 下移到底

    ; 智能补偿隐形边框
    GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)
    realY := newY - offsetY

    WinMove(x, realY,,, "ahk_id " hwnd)
}


; Win + R 切换窗口 1/3 1/2 2/3
global sizeState := 0  ; 0=1/3, 1=1/2, 2=2/3

#r::
{
    global sizeState, margin

    hwnd := WinExist("A")
    if !hwnd
        return

    MonitorGetWorkArea(, &l, &t, &r, &b)

    ; 1. 预留最外圈的 16px 边距
    l += margin
    t += margin
    r -= margin
    b -= margin

    totalW := r - l
    totalH := b - t

    ; 获取当前真实的视觉左侧位置与大小
    try {
        FrameRect := Buffer(16)
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", FrameRect, "uint", 16)
        wx := NumGet(FrameRect, 0, "int")
        ww := NumGet(FrameRect, 8, "int") - NumGet(FrameRect, 0, "int")
    } catch {
        WinGetPos(&wx, , &ww, , "A")
    }

    center := l + totalW // 2
    isLeft := (wx + ww / 2 < center)

    ; 2. 核心：扣除中间缝隙，精准计算理想的视觉宽度
    if (sizeState = 0) {
        ; 1/3 状态：三等分有 2 条缝，单格宽 = (总宽 - 2个缝) // 3
        w := (totalW - margin * 2) // 3
    }
    else if (sizeState = 1) {
        ; 1/2 状态：二等分有 1 条缝，单格宽 = (总宽 - 1个缝) // 2
        w := (totalW - margin) // 2
    }
    else {
        ; 2/3 状态：单格宽乘以 2，再加上跨过的那条缝隙宽度
        oneThirdW := (totalW - margin * 2) // 3
        w := (oneThirdW * 2) + margin
    }

    h := totalH
    y := t

    ; 3. 精准计算理想的视觉 X 坐标
    if isLeft {
        x := l
    }
    else {
        x := l + totalW - w
    }

    if (WinGetMinMax("A") = 1)
        WinRestore("A")

    Sleep 20

    ; 4. 智能补偿隐形边框
    GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)
    realX := x - offsetX
    realY := y - offsetY
    realW := w + (offsetX * 2)
    realH := h + offsetY + offsetBottom

    WinMove(realX, realY, realW, realH, "A")

    sizeState := Mod(sizeState + 1, 3)
}


; - win + + 使窗口向预期一侧增加水平方向
; - win + - 使窗口向预期一侧缩小水平方向
; - win + shift + + 使窗口增加垂直方向
; - win + shift + - 使窗口缩小垂直方向

global resizeStep := 0.10

#=::ResizeActiveWindow(1)
#+=::ResizeActiveWindow(1)

#NumpadAdd::ResizeActiveWindow(1)
#+NumpadAdd::ResizeActiveWindow(1)

#-::ResizeActiveWindow(-1)
#+-::ResizeActiveWindow(-1)

#NumpadSub::ResizeActiveWindow(-1)
#+NumpadSub::ResizeActiveWindow(-1)

ResizeActiveWindow(dir) {
    global margin, resizeStep

    hwnd := WinExist("A")
    if !hwnd
        return

    if (WinGetMinMax(hwnd) = 1)
        WinRestore(hwnd)

    ; 提取当前视觉尺寸进行无缝无差缩放
    try {
        FrameRect := Buffer(16)
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", FrameRect, "uint", 16)
        x := NumGet(FrameRect, 0, "int")
        y := NumGet(FrameRect, 4, "int")
        w := NumGet(FrameRect, 8, "int") - NumGet(FrameRect, 0, "int")
        h := NumGet(FrameRect, 12, "int") - NumGet(FrameRect, 4, "int")
    } catch {
        WinGetPos(&x, &y, &w, &h, hwnd)
    }

    hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")

    mi := Buffer(40, 0)
    NumPut("uint", 40, mi, 0)
    DllCall("GetMonitorInfo", "ptr", hMon, "ptr", mi)

    left   := NumGet(mi, 20, "int") + margin
    top    := NumGet(mi, 24, "int") + margin
    right  := NumGet(mi, 28, "int") - margin
    bottom := NumGet(mi, 32, "int") - margin

    areaW := right - left
    areaH := bottom - top
    center := left + areaW / 2

    isShift := GetKeyState("Shift", "P")

    if isShift {
        ; 高度缩放
        delta := Round(h * resizeStep * dir)
        newH := h + delta
        newW := w
        newX := x

        ; 默认顶部固定
        newY := y

        ; 如果放大后底部超界，则底部固定，向上扩展
        if (dir > 0 && y + newH > bottom)
            newY := bottom - newH
    }
    else {
        ; 宽度缩放
        newW := w + Round(w * resizeStep * dir)
        newH := h
        newY := y

        if (x + w / 2 < center)
            newX := x
        else
            newX := x + w - newW
    }

    ; 最小尺寸
    if (newW < 200)
        newW := 200
    if (newH < 120)
        newH := 120

    ; 最大尺寸
    if (newW > areaW)
        newW := areaW
    if (newH > areaH)
        newH := areaH

    ; 边界修正
    if (newX < left)
        newX := left
    if (newX + newW > right)
        newX := right - newW

    if (newY < top)
        newY := top
    if (newY + newH > bottom)
        newY := bottom - newH

    ; 智能补回隐形边框
    GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)
    realX := newX - offsetX
    realY := newY - offsetY
    realW := newW + (offsetX * 2)
    realH := newH + offsetY + offsetBottom

    WinMove(realX, realY, realW, realH, hwnd)
}


; Win + [ ] 使窗口移动 to 左侧虚拟桌面、右侧虚拟桌面，如果右侧虚拟桌面不存在则自动创建
dllPath := A_ScriptDir "\VirtualDesktopAccessor.dll"
global vdMoveReady := false

if FileExist(dllPath)
{
    try
    {
        DllCall("LoadLibrary", "Str", dllPath, "Ptr")
        vdMoveReady := true
    }
}

#]::MoveWindowDesktop(1)
#[::MoveWindowDesktop(-1)

MoveWindowDesktop(offset)
{
    global vdMoveReady

    ; 没有 DLL 就直接忽略
    if !vdMoveReady
        return

    hwnd := WinExist("A")
    if !hwnd
        return

    current := DllCall("VirtualDesktopAccessor\GetCurrentDesktopNumber", "Int")
    count   := DllCall("VirtualDesktopAccessor\GetDesktopCount", "Int")

    target := current + offset

    ; 右边没有就创建
    if (target >= count)
    {
        DllCall("VirtualDesktopAccessor\CreateDesktop")
        Sleep 100
    }

    ; 左边没有就退出
    if (target < 0)
        return

    ; 移动窗口
    DllCall("VirtualDesktopAccessor\MoveWindowToDesktopNumber"
        , "Ptr", hwnd
        , "Int", target)

    ; 切换过去
    DllCall("VirtualDesktopAccessor\GoToDesktopNumber"
        , "Int", target)
}


; Win + 0 创建新的虚拟桌面
#0::Send("^#d")


; Win + 9 关闭当前虚拟桌面
#9::Send("^#{F4}")


; Win + Q 关闭窗口
#q::
{
    ; 如果检测到是全屏，直接返回，不做任何事情（从而屏蔽了该按键）
    if IsFullScreen("A") {
        return
    }
    
    ; 否则，执行正常的关闭指令
    Send "!{F4}"
}

; 全屏检测核心函数（高精度版）
IsFullScreen(winTitle) {
    try {
        if !(hWnd := WinExist(winTitle))
            return false
        
        ; 检查样式：有标题栏的通常不是全屏
        style := WinGetStyle(hWnd)
        if (style & 0x00C00000) 
            return false

        WinGetPos(&winX, &winY, &winW, &winH, hWnd)
        
        ; 获取当前窗口所在显示器的物理区域
        monitorIndex := DllCall("MonitorFromWindow", "Ptr", hWnd, "UInt", 0x2)
        NumPut("UInt", 40, (info := Buffer(40)))
        if DllCall("GetMonitorInfo", "Ptr", monitorIndex, "Ptr", info) {
            monLeft   := NumGet(info, 4, "Int")
            monTop    := NumGet(info, 8, "Int")
            monRight  := NumGet(info, 12, "Int")
            monBottom := NumGet(info, 16, "Int")
            
            ; 判断窗口是否完全覆盖了显示器
            return (winX <= monLeft && winY <= monTop && winX + winW >= monRight && winY + winH >= monBottom)
        }
    }
    return false
}


; Win + Space 打开开始菜单
#Space::
{
    ; Send("!q")
    Send("^{Esc}")
}


; 禁止 CapsLock 键切换大小写
SetCapsLockState "AlwaysOff"


; CapsLock 映射为右 Shift
CapsLock::RShift


; Alt + Space 切换输入法
$!Space::
{
    Send "#{Space}"
}


; Win + T 打开终端（普通权限，非管理员）
#t::
{
    target := "wt.exe" 
    ; 隐藏运行 cmd 中转启动，避免弹窗闪烁
    Run A_ComSpec ' /c "runas /trustlevel:0x20000 ' . target . '"', , "Hide"
    
    ; 等待窗口出现（最多等3秒，防止死锁），然后强行激活聚焦
    if WinWait("ahk_exe wt.exe", , 3)
        WinActivate("ahk_exe wt.exe")
}

; Win + Shift + T 以管理员方式打开终端
#+t::
{
    Run('*RunAs wt.exe')
    
    ; 管理员权限窗口同样等待并强行激活
    if WinWait("ahk_exe wt.exe", , 3)
        WinActivate("ahk_exe wt.exe")
}


; Win + 滚轮上 切换到左侧虚拟桌面
; Win + 滚轮下 切换到右侧虚拟桌面
dllPath := A_ScriptDir "\VirtualDesktopAccessor.dll"
global vdReady := false

if FileExist(dllPath)
{
    try
    {
        DllCall("LoadLibrary", "Str", dllPath, "Ptr")
        vdReady := true
    }
}

GetCurrentDesktopNumber() {
    return DllCall("VirtualDesktopAccessor.dll\GetCurrentDesktopNumber", "Int")
}

GetDesktopCount() {
    return DllCall("VirtualDesktopAccessor.dll\GetDesktopCount", "Int")
}

GoToDesktopNumber(num) {
    DllCall("VirtualDesktopAccessor.dll\GoToDesktopNumber", "Int", num)
}

#HotIf GetKeyState("LWin", "P")

*WheelUp::
{
    if vdReady
    {
        cur := GetCurrentDesktopNumber()
        if (cur > 0)
            GoToDesktopNumber(cur - 1)
    }
    else
    {
        SendInput "^#{Left}"
    }
}

*WheelDown::
{
    if vdReady
    {
        cur := GetCurrentDesktopNumber()
        count := GetDesktopCount()

        if (cur < count - 1)
            GoToDesktopNumber(cur + 1)
    }
    else
    {
        SendInput "^#{Right}"
    }
}

#HotIf

; 禁止单个 Win 键
~LWin Up::return


; Win + F11 重载脚本
#F11::Reload


; Win + F11 退出脚本
#F12::ExitApp


; 新窗口始终在边距内
; 注册 Shell 钩子监听窗口创建
DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), ShellMessage)

ShellMessage(wParam, lParam, *) {
    ; HSHELL_WINDOWCREATED = 1
    if (wParam = 1) {
        ; 延迟一小会儿，等待窗口完全初始化以获取正确的原始尺寸
        Sleep(100)
        AdjustWindow(lParam)
    }
}

AdjustWindow(hwnd) {
    try {
        style := WinGetStyle(hwnd)
        if !(style & 0x00C00000)
            return

        ; 1. 处理最大化：如果是最大化，必然需要调整，所以这里直接还原
        isMaximized := (WinGetMinMax(hwnd) = 1)
        if isMaximized {
            WinRestore(hwnd)
        }

        ; 为了计算绝对对齐，这里获取真实视觉尺寸和位置
        try {
            FrameRect := Buffer(16)
            DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", FrameRect, "uint", 16)
            winX := NumGet(FrameRect, 0, "int")
            winY := NumGet(FrameRect, 4, "int")
            winW := NumGet(FrameRect, 8, "int") - NumGet(FrameRect, 0, "int")
            winH := NumGet(FrameRect, 12, "int") - NumGet(FrameRect, 4, "int")
        } catch {
            WinGetPos(&winX, &winY, &winW, &winH, hwnd)
        }

        MonitorGetWorkArea(1, &left, &top, &right, &bottom)
        
        workW := right - left
        workH := bottom - top
        maxW := workW - (margin * 2)
        maxH := workH - (margin * 2)

        ; 3. 计算目标尺寸和位置
        targetW := (winW > maxW) ? maxW : winW
        targetH := (winH > maxH) ? maxH : winH
        
        targetX := Max(winX, left + margin)
        targetY := Max(winY, top + margin)

        if (targetX + targetW > right - margin)
            targetX := right - margin - targetW
        if (targetY + targetH > bottom - margin)
            targetY := bottom - margin - targetH

        ; 4. **核心优化：差异检查**
        ; 只有当 坐标 或 尺寸 发生变化，或者是从最大化还原回来的，才执行移动
        if (isMaximized || targetX != winX || targetY != winY || targetW != winW || targetH != winH) {
            ; 智能引入补偿
            GetWindowBorders(hwnd, &offsetX, &offsetY, &offsetBottom)
            realX := targetX - offsetX
            realY := targetY - offsetY
            realW := targetW + (offsetX * 2)
            realH := targetH + offsetY + offsetBottom
            
            WinMove(realX, realY, realW, realH, hwnd)
        }
    }
}


; PrintScreen 直接截取整个屏幕，Win + Shift + S 可以区域截取
PrintScreen::Send "#" . "{PrintScreen}"
