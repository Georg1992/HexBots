#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

#include utils/client_memory.ahk
#include lib/config_loader.ahk
;#include controllers/implementations/ahi/keyboard.ahk


;
; Usage
;


config := new ConfigLoader("config\client.json").Get()
global client := new Client(config)
global character := client.GetCharacter()


End::
    Loop {
        MsgBox % character.currentSp
        Sleep, 1000
    }
    
    Return

F1::
    character.StartBackgroundUpdate()
    Return
  
F2::
    character.StopBackgroundUpdate()
    Return

F3::
    ahi := new KeyboardAHI()
    ahi.ButtonDown("f1")
    Return

Esc::
    ExitApp