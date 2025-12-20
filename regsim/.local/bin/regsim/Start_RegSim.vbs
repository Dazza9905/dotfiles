Set oShell = CreateObject ("Wscript.Shell") 
Dim strArgs
strArgs = "cmd /c Starter.bat"
oShell.Run strArgs, 0, false