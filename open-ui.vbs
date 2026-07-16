Option Explicit
Dim fso, sh, portFile, port, f
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
port = "8501"
portFile = sh.ExpandEnvironmentStrings("%ProgramData%") & "\RuGrammarCheck\port"
If fso.FileExists(portFile) Then
    Set f = fso.OpenTextFile(portFile, 1)
    If Not f.AtEndOfStream Then port = Trim(f.ReadAll)
    f.Close
End If
sh.Run "explorer.exe ""http://127.0.0.1:" & port & "/""", 1, False
