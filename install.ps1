[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# 添加以下代码到脚本开头
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}
# 获取当前用户
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# 设置执行策略
Set-ExecutionPolicy Bypass -Scope Process -Force


# 设置工作目录为脚本所在位置
$workDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = "`"" + (Join-Path $workDir "UnbanPluginsCN.exe") + "`""

# 创建任务动作
$Action = New-ScheduledTaskAction -Execute $exePath -WorkingDirectory $workDir

# 创建登录触发器 - 所有用户
$Trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay (New-TimeSpan -Minutes 1)

# 设置运行权限 - 系统管理员
$Principal = New-ScheduledTaskPrincipal -UserId $currentUser `
    -LogonType ServiceAccount `
    -RunLevel Highest


# 配置任务设置
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 72) `
    -MultipleInstances IgnoreNew `
    -Priority 7
    
# 注册计划任务并捕获结果
try {
    $result = Register-ScheduledTask -TaskName "UnbanCNplugins-service" `
        -TaskPath "\" `
        -Description "Remove CN plugin ban list" `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Force

    if ($result) {
        Write-Host "计划任务创建成功!" -ForegroundColor Green
        Write-Host "任务信息:"
        Write-Host "- 名称: $($result.TaskName)"
        Write-Host "- 状态: $($result.State)"
        Write-Host "- 下次运行时间: $($result.NextRunTime)"
    }
} catch {
    Write-Host "创建计划任务时出错:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# 暂停让用户查看结果
Write-Host "`n按任意键继续..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")