# theme.ps1
# Переключает тему Windows (система + приложения) для текущего пользователя.
#
#   .\theme.ps1                 - выбрать тему по текущему времени (режим auto)
#   .\theme.ps1 -Mode dark      - принудительно тёмная
#   .\theme.ps1 -Mode light     - принудительно светлая
#
# В режиме auto тёмная тема действует с DarkTime до LightTime, светлая - в остальное время.

param(
    [ValidateSet("auto", "dark", "light")]
    [string]$Mode = "auto",
    [string]$DarkTime = "20:00",
    [string]$LightTime = "08:00"
)

$ErrorActionPreference = "Stop"

$useDark = ($Mode -eq "dark")

if ($Mode -eq "auto") {
    $inv = [Globalization.CultureInfo]::InvariantCulture
    $dark  = [datetime]::ParseExact($DarkTime,  "H:mm", $inv).TimeOfDay
    $light = [datetime]::ParseExact($LightTime, "H:mm", $inv).TimeOfDay

    # Запас в 30 секунд: Планировщик может запустить задачу чуть раньше границы.
    $now = (Get-Date).AddSeconds(30).TimeOfDay

    if ($dark -gt $light) {
        # Обычный случай: тёмная вечером и ночью, через полночь (20:00 -> 08:00)
        $useDark = ($now -ge $dark) -or ($now -lt $light)
    } else {
        # Тёмный интервал внутри одних суток (например, 01:00 -> 08:00)
        $useDark = ($now -ge $dark) -and ($now -lt $light)
    }
}

$value = if ($useDark) { 0 } else { 1 }
$key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

if (-not (Test-Path $key)) {
    New-Item -Path $key -Force | Out-Null
}

# Если нужная тема уже стоит - ничего не трогаем.
$current = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
if ($current.AppsUseLightTheme -eq $value -and $current.SystemUsesLightTheme -eq $value) {
    exit 0
}

Set-ItemProperty -Path $key -Name "AppsUseLightTheme"    -Value $value -Type DWord
Set-ItemProperty -Path $key -Name "SystemUsesLightTheme" -Value $value -Type DWord

# Сообщаем системе об изменении, иначе панель задач и "Пуск" могут остаться в старом цвете.
try {
    Add-Type -Namespace ThemeSwitcher -Name Native -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    $HWND_BROADCAST   = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x001A
    $SMTO_ABORTIFHUNG = 0x0002
    $result = [UIntPtr]::Zero
    [void][ThemeSwitcher.Native]::SendMessageTimeout(
        $HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "ImmersiveColorSet",
        $SMTO_ABORTIFHUNG, 1000, [ref]$result)
} catch {
    # Тема в реестре уже изменена; без рассылки часть интерфейса обновится позже.
}
