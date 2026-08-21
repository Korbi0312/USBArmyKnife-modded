Set fso = CreateObject("Scripting.FileSystemObject")
exe = "C:\AgentInstall\AgentLauncher.exe"
If fso.FileExists(exe) Then
    CreateObject("WScript.Shell").Run """" & exe & """ vid=cafe pid=403f cwd=C:\AgentInstall", 0, False
End If
