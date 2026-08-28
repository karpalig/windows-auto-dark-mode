' run_dark.vbs
' Запускает dark.ps1 полностью скрыто, без мелькания окна PowerShell.
' Путь вычисляется автоматически относительно этого файла.

Set objFSO = CreateObject("Scripting.FileSystemObject")
strFolder = objFSO.GetParentFolderName(WScript.ScriptFullName)

Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & strFolder & "\dark.ps1""", 0, False
