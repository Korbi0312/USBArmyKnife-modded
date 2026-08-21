Set fso = CreateObject("Scripting.FileSystemObject")
exe = "C:\AgentInstall\VncDirect\VncDirect.exe"
If fso.FileExists(exe) Then
    CreateObject("WScript.Shell").Run """" & exe & """ port=7002 cwd=C:\AgentInstall\VncDirect\vnc fps=240 scale=0", 0, False
End If
