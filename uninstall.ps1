# uninstall.ps1
# Удаляет задачи, созданные install.ps1 (включая задачи старых версий).
#   .\uninstall.ps1

param(
    [switch]$Quiet
)

# "Theme Switcher - Dark/Light" - задачи старых версий, созданные с правами администратора.
$names = @("Theme Switcher", "Theme Switcher - Dark", "Theme Switcher - Light")

function Get-RemainingTasks {
    @(Get-ScheduledTask -TaskPath "\" -ErrorAction SilentlyContinue |
        Where-Object { $names -contains $_.TaskName })
}

foreach ($task in Get-RemainingTasks) {
    try {
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
    } catch {
        # Нет прав - попробуем ниже с повышением.
    }
}

$left = Get-RemainingTasks
if ($left.Count -gt 0) {
    # Задачи старой версии обычному процессу не удалить - один раз просим права администратора.
    Write-Host "Удаляю задачи старой версии, нужны права администратора..." -ForegroundColor Yellow
    $command = ($left | ForEach-Object {
        "Unregister-ScheduledTask -TaskName '$($_.TaskName)' -Confirm:`$false"
    }) -join "; "
    try {
        Start-Process -FilePath "powershell.exe" -Verb RunAs -Wait -WindowStyle Hidden `
            -ArgumentList "-NoProfile -Command `"$command`""
    } catch {
        # Запрос UAC отклонён.
    }
    $left = Get-RemainingTasks
}

if ($left.Count -gt 0) {
    $list = ($left | ForEach-Object { $_.TaskName }) -join ", "
    Write-Host "Не удалось удалить: $list." -ForegroundColor Red
    Write-Host "Удалите их вручную в Планировщике заданий (taskschd.msc)." -ForegroundColor Red
    if (-not $Quiet) { exit 1 }
} elseif (-not $Quiet) {
    Write-Host "Задачи удалены (если существовали)." -ForegroundColor Green
}
