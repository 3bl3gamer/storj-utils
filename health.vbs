scriptDirectory = left(WScript.ScriptFullName,(Len(WScript.ScriptFullName))-(len(WScript.ScriptName)))
Set objShell = WScript.CreateObject("WScript.Shell")
'Wscript.Echo objShell.CurrentDirectory
objShell.CurrentDirectory = scriptDirectory

Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd /C ruby health.rb " & WScript.Arguments.Item(0), 0
Set WshShell = Nothing
