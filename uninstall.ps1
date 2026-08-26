# uninstall.ps1
# Удаляет задачи, созданные install.ps1.
# Запускать из PowerShell от имени администратора:
#   .\uninstall.ps1

Unregister-ScheduledTask -TaskName "Theme Switcher - Dark"  -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Theme Switcher - Light" -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "Задачи удалены (если существовали)." -ForegroundColor Green
