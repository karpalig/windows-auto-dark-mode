# windows-auto-dark-mode

Автоматическое переключение системной темы Windows (светлая/тёмная) по расписанию
через встроенный Планировщик заданий — без сторонних программ.

Работает на Windows 10 и Windows 11. Не требует установки PowerToys или
Auto Dark Mode — использует только штатные средства ОС.

## Как это работает

- `dark.ps1` / `light.ps1` — меняют значения темы в реестре текущего пользователя.
- `run_dark.vbs` / `run_light.vbs` — запускают соответствующий `.ps1` полностью
  скрыто, без мелькания окна PowerShell.
- `install.ps1` — регистрирует две задачи в Планировщике заданий Windows
  (переключение вечером и утром). Пути вычисляются автоматически
  (`$PSScriptRoot`), поэтому скрипт работает в любой папке и под любым
  пользователем без правок.

## Установка

1. Скачайте или клонируйте репозиторий в любую папку:
   ```powershell
   git clone https://github.com/karpalig/windows-auto-dark-mode.git
   cd windows-auto-dark-mode
   ```
2. Откройте **PowerShell от имени администратора**.
3. Разрешите выполнение локальных скриптов (если ещё не разрешено):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
4. Запустите установку из папки проекта:
   ```powershell
   .\install.ps1
   ```
   По умолчанию: тёмная тема в 20:00, светлая — в 08:00.

   Своё время:
   ```powershell
   .\install.ps1 -DarkTime "22:00" -LightTime "07:30"
   ```

## Проверка

```powershell
Get-ScheduledTask -TaskName "Theme Switcher*"
```

Принудительно запустить задачу сразу (не дожидаясь времени):
```powershell
Start-ScheduledTask -TaskName "Theme Switcher - Dark"
```

## Удаление

```powershell
.\uninstall.ps1
```

## Примечания

- Темы применяются только к текущему пользователю Windows (`HKCU`).
- Если нужна привязка к реальному восходу/закату с учётом геолокации,
  для этого лучше подходит [PowerToys Light Switch](https://learn.microsoft.com/windows/powertoys/)
  или [Auto Dark Mode](https://github.com/AutoDarkMode/Windows-Auto-Night-Mode) —
  этот проект сознательно ограничен фиксированным расписанием и минимумом
  зависимостей.
