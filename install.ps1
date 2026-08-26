# install.ps1
# Устанавливает автопереключение темы Windows через Планировщик заданий.
# Запускать из PowerShell от имени администратора, находясь в папке проекта:
#   .\install.ps1
#
# Можно задать своё время:
#   .\install.ps1 -DarkTime "22:00" -LightTime "07:30"

param(
    [string]$DarkTime = "20:00",
    [string]$LightTime = "08:00"
)

# Папка, где лежит сам install.ps1 - работает независимо от пользователя и диска
$root = $PSScriptRoot

if (-not (Test-Path "$root\run_dark.vbs") -or -not (Test-Path "$root\run_light.vbs")) {
    Write-Host "Ошибка: run_dark.vbs / run_light.vbs не найдены рядом с install.ps1." -ForegroundColor Red
    Write-Host "Убедитесь, что запускаете install.ps1 из папки проекта со всеми файлами." -ForegroundColor Red
    exit 1
}

$actionDark  = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$root\run_dark.vbs`""
$actionLight = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$root\run_light.vbs`""

$triggerDark  = New-ScheduledTaskTrigger -Daily -At $DarkTime
$triggerLight = New-ScheduledTaskTrigger -Daily -At $LightTime

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -RunOnlyIfNetworkAvailable:$false `
    -StartWhenAvailable

Register-ScheduledTask -TaskName "Theme Switcher - Dark"  -Action $actionDark  -Trigger $triggerDark  -Settings $settings -RunLevel Highest -Force | Out-Null
Register-ScheduledTask -TaskName "Theme Switcher - Light" -Action $actionLight -Trigger $triggerLight -Settings $settings -RunLevel Highest -Force | Out-Null

Write-Host ""
Write-Host "Готово! Задачи в Планировщике созданы:" -ForegroundColor Green
Write-Host "  Theme Switcher - Dark   -> каждый день в $DarkTime"
Write-Host "  Theme Switcher - Light  -> каждый день в $LightTime"
Write-Host ""
Write-Host "Проверить: Get-ScheduledTask -TaskName 'Theme Switcher*'"
Write-Host "Удалить:   .\uninstall.ps1"
