; hotkeys.ahk
#Requires AutoHotkey v2.0
#SingleInstance Force

; Resolve directory where the installer put the scripts
InstallDir := "C:\ProgramData\RuGrammarCheck\clipboard"
CorrectVbs := InstallDir "\correct-clipboard.vbs"
RevertVbs  := InstallDir "\revert-clipboard.vbs"

; Correct: Ctrl+Win+Shift+Alt+C
^#+!c::
{
    Run('"' CorrectVbs '"', , "Hide")
}

; Revert: Ctrl+Win+Shift+Alt+Z
^#+!z::
{
    Run('"' RevertVbs '"', , "Hide")
}
