# uninstall.ps1
# Удаляет задачи, созданные install.ps1.
# Запускать из PowerShell от имени администратора:
#   .\uninstall.ps1

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = ([Security.Principal.WindowsPrincipal]$currentIdentity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Нужны права администратора, запрашиваю..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath) -Verb RunAs | Out-Null
    } catch {
        Write-Host "Не удалось получить права администратора (запрос был отклонён?)." -ForegroundColor Red
        Read-Host "Нажмите Enter для выхода"
        exit 1
    }
    exit
}

Unregister-ScheduledTask -TaskName "Theme Switcher - Dark"  -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Theme Switcher - Light" -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "Задачи удалены (если существовали)." -ForegroundColor Green

if ($Host.Name -eq "ConsoleHost") {
    Write-Host ""
    Read-Host "Нажмите Enter для выхода"
}
