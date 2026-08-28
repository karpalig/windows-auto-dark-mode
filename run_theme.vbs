' run_theme.vbs
' Запускает dark.ps1 или light.ps1 полностью скрыто, без мелькания окна PowerShell.
' Путь вычисляется автоматически относительно этого файла.
' Использование: wscript.exe run_theme.vbs dark
'                wscript.exe run_theme.vbs light

Set objArgs = WScript.Arguments
If objArgs.Count < 1 Then
    WScript.Quit 1
End If

mode = LCase(objArgs(0))
If mode <> "dark" And mode <> "light" Then
    WScript.Quit 1
End If

Set objFSO = CreateObject("Scripting.FileSystemObject")
strFolder = objFSO.GetParentFolderName(WScript.ScriptFullName)
strScript = strFolder & "\" & mode & ".ps1"

Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & strScript & """", 0, False
