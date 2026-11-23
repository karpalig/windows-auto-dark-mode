# install.ps1
# Устанавливает автопереключение темы Windows через Планировщик заданий.
# Права администратора не нужны. Запускать из папки проекта:
#   .\install.ps1
#
# Можно задать своё время:
#   .\install.ps1 -DarkTime "22:00" -LightTime "07:30"

param(
    [string]$DarkTime = "20:00",
    [string]$LightTime = "08:00"
)

$ErrorActionPreference = "Stop"
$taskName = "Theme Switcher"

function ConvertTo-TimeOfDay([string]$text, [string]$paramName) {
    $parsed = [datetime]::MinValue
    $ok = [datetime]::TryParseExact(
        $text.Trim(), "H:mm",
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None, [ref]$parsed)
    if (-not $ok) {
        throw "Неверное время в -${paramName}: '$text'. Нужен формат ЧЧ:ММ, например 20:00."
    }
    return $parsed.TimeOfDay
}

try {
    $root = $PSScriptRoot
    $themeScript = Join-Path $root "theme.ps1"
    if (-not (Test-Path $themeScript)) {
        throw "theme.ps1 не найден рядом с install.ps1. Запускайте install.ps1 из папки проекта со всеми файлами."
    }

    $dark  = ConvertTo-TimeOfDay $DarkTime  "DarkTime"
    $light = ConvertTo-TimeOfDay $LightTime "LightTime"
    if ($dark -eq $light) {
        throw "DarkTime и LightTime совпадают ($DarkTime) - задайте разное время."
    }
    $darkText  = "{0:hh\:mm}" -f $dark
    $lightText = "{0:hh\:mm}" -f $light

    # Убираем прежнюю установку, включая задачи старых версий.
    & (Join-Path $root "uninstall.ps1") -Quiet

    # conhost --headless запускает PowerShell совсем без окна (замена прежнему run_theme.vbs).
    $conhost    = Join-Path $env:SystemRoot "System32\conhost.exe"
    $powershell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $arguments  = "--headless `"$powershell`" -NoProfile -NonInteractive -ExecutionPolicy Bypass " +
                  "-File `"$themeScript`" -Mode auto -DarkTime $darkText -LightTime $lightText"

    $action = New-ScheduledTaskAction -Execute $conhost -Argument $arguments

    $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Limited

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    $timeTriggers = @(
        (New-ScheduledTaskTrigger -Daily -At ([datetime]::Today + $dark)),
        (New-ScheduledTaskTrigger -Daily -At ([datetime]::Today + $light))
    )

    # Триггер "при входе в систему" сразу ставит нужную тему после включения компьютера.
    # Если Windows не разрешает создать его без прав администратора - обходимся без него:
    # пропущенный запуск всё равно выполнится благодаря StartWhenAvailable.
    $logonTrigger = $true
    try {
        $triggers = $timeTriggers + (New-ScheduledTaskTrigger -AtLogOn -User $me)
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers `
            -Principal $principal -Settings $settings -Force | Out-Null
    } catch {
        $logonTrigger = $false
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $timeTriggers `
            -Principal $principal -Settings $settings -Force | Out-Null
    }

    # Сразу применяем тему, подходящую для текущего времени.
    Start-ScheduledTask -TaskName $taskName

    Write-Host ""
    Write-Host "Готово! Задача '$taskName' создана:" -ForegroundColor Green
    Write-Host "  тёмная тема  - с $darkText"
    Write-Host "  светлая тема - с $lightText"
    if ($logonTrigger) {
        Write-Host "  плюс проверка при входе в систему"
    }
    Write-Host ""
    Write-Host "Тема для текущего времени применяется прямо сейчас."
    Write-Host "Не перемещайте и не удаляйте эту папку: задача запускает theme.ps1 отсюда."
    Write-Host "Удалить: .\uninstall.ps1"
} catch {
    Write-Host ""
    Write-Host "Ошибка установки: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
