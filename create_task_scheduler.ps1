# 用户配置
$TaskName = "AHKShortcut"
$ProgramPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$Arguments = "`"C:\Users\meld\Documents\AutoHotkey\shortcut.ahk`""

# 启动时机选择: "AtLogon" (登录即启), "DelayedLogon" (登录后延迟), "AtStartup" (开机即启)
$TriggerType = "AtLogon" 
$DelayMinutes = 1 # 仅在 DelayedLogon 时生效
# ==========================================

# 检查管理员权限
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    return
}

# 检查重名，避免覆盖
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    return
}

# 定义触发器
$Trigger = switch ($TriggerType) {
    "AtLogon"      { New-ScheduledTaskTrigger -AtLogon }
    "DelayedLogon" { New-ScheduledTaskTrigger -AtLogon -Delay (New-TimeSpan -Minutes $DelayMinutes) }
    "AtStartup"    { New-ScheduledTaskTrigger -AtStartup }
    default        { New-ScheduledTaskTrigger -AtLogon }
}

# 定义动作
$Action = New-ScheduledTaskAction -Execute $ProgramPath -Argument $Arguments

# 定义设置
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0)

# 注册任务
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -RunLevel Highest
