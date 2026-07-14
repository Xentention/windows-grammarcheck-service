; hotkeys.ahk
#Requires AutoHotkey v2.0
#SingleInstance Force
#NoEnv

; Resolve directory where the installer put the scripts
InstallDir := "C:\ProgramData\RuGrammarCheck\clipboard"
CorrectVbs := InstallDir "\correct-clipboard.vbs"
RevertVbs  := InstallDir "\revert-clipboard.vbs"

; Correct: Ctrl+Win+Shift+Alt+C
^#+!c::
    Run '"' CorrectVbs '"', , "Hide"
    return

; Revert: Ctrl+Shift+Alt+Z
^+!z::
    Run '"' RevertVbs '"', , "Hide"
    return