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


; Win + F 窗口最大化
#f::
{
    hwnd := WinExist("A")
    if !hwnd
        return

    if WinGetMinMax(hwnd) = -1
        WinRestore(hwnd)

    hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")

    mi := Buffer(40, 0)
    NumPut("uint", 40, mi, 0)

    DllCall("GetMonitorInfo", "ptr", hMon, "ptr", mi)

    left   := NumGet(mi, 20, "int")
    top    := NumGet(mi, 24, "int")
    right  := NumGet(mi, 28, "int")
    bottom := NumGet(mi, 32, "int")

    x := left + margin
    y := top + margin
    w := (right - left) - margin * 2
    h := (bottom - top) - margin * 2

    if WinGetMinMax(hwnd) = 1
        WinRestore(hwnd)

    WinMove(x, y, w, h, hwnd)
}


; Win + C 窗口居中
#c::
{
    hwnd := WinGetID("A")
    WinGetPos(&x, &y, &w, &h, hwnd)

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

    WinMove(newX, newY, , , hwnd)
}


; Win + ← → 窗口左半屏，窗口右半屏

SnapLeft() {
    global margin

    MonitorGetWorkArea(, &l, &t, &r, &b)

    l += margin
    t += margin
    r -= margin
    b -= margin

    w := (r - l) // 2
    h := b - t

    WinRestore("A")
    Sleep 30
    WinMove(l, t, w, h, "A")
}

SnapRight() {
    global margin

    MonitorGetWorkArea(, &l, &t, &r, &b)

    l += margin
    t += margin
    r -= margin
    b -= margin

    w := (r - l) // 2
    h := b - t
    x := l + w

    WinRestore("A")
    Sleep 30
    WinMove(x, t, w, h, "A")
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

    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)

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

    WinMove(x, newY,,, "ahk_id " hwnd)
}


; Win + R 切换窗口 1/3 1/2 2/3
global sizeState := 0  ; 0=1/3, 1=1/2, 2=2/3

#r::
{
    global sizeState, margin

    MonitorGetWorkArea(, &l, &t, &r, &b)

    l += margin
    t += margin
    r -= margin
    b -= margin

    totalW := r - l
    totalH := b - t

    WinGetPos(&wx, &wy, &ww, &wh, "A")

    center := l + totalW // 2
    isLeft := (wx + ww / 2 < center)

    if (sizeState = 0)
        w := totalW // 3
    else if (sizeState = 1)
        w := totalW // 2
    else
        w := (totalW * 2) // 3

    h := totalH
    y := t

    if isLeft
        x := l
    else
        x := l + totalW - w

    if (WinGetMinMax("A") = 1)
        WinRestore("A")

    Sleep 20
    WinMove(x, y, w, h, "A")

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

    WinGetPos(&x, &y, &w, &h, hwnd)

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

    WinMove(newX, newY, newW, newH, hwnd)
}


; Win + [ ] 使窗口移动到左侧虚拟桌面、右侧虚拟桌面，如果右侧虚拟桌面不存在则自动创建
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
    Send "!{F4}"
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


; Win + T 打开终端
#t::
{
    target := "wt.exe" 
    Run A_ComSpec ' /c "runas /trustlevel:0x20000 ' . target . '"', , "Hide"
}


; Win + Shift + T 以管理员方式打开终端
#+t::
{
    Run('*RunAs wt.exe')
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