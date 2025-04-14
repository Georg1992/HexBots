LogToFile(message) {
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] %message%`n, bot_log.txt
}

SetDefaultKeyboardLayout(layout)
{
    DllCall("LoadKeyboardLayout", Str, layout, UInt, 1)
    DllCall("ActivateKeyboardLayout", UInt, DllCall("LoadKeyboardLayout", Str, layout, UInt, 1), UInt, 0)
}

AHIclick(){
    AHI.SendMouseButtonEvent(mouseId, 0, 1)
    sleep 50
    AHI.SendMouseButtonEvent(mouseId, 0, 0)
}

AltClicks(times){
    AHI.SendKeyEvent(keyboardId,56 , 1)
    sleep 50
    Loop, %times%{
        AHI.SendMouseButtonEvent(mouseId, 1, 1)
        sleep 50
        AHI.SendMouseButtonEvent(mouseId, 1, 0)
        sleep 50
    }
    AHI.SendKeyEvent(keyboardId,56 , 0)
}

SkillClick(KeySC){
    sleep 50
    AHI.SendKeyEvent(keyboardId, KeySC, 1)
    sleep 50
    AHI.SendKeyEvent(keyboardId, KeySC, 0)
    AHI.SendMouseButtonEvent(mouseId, 0, 1)
    sleep 50
    AHI.SendMouseButtonEvent(mouseId, 0, 0)
}

CheckImageOnScreen(image){
    ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, %image%
    if (ErrorLevel = 0) {
        return true
    }
    return false
}

MoveCursorToImage(image, xOffset, yOffset){
    ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, %image%
    if (ErrorLevel = 0) {
        ; Image found, move the cursor
        MouseMove, FoundX + xOffset, FoundY + yOffset
    } else if (ErrorLevel = 1) {
        MsgBox, Image was not found or an error occurred.
        Pause, On
    }
    sleep 200
}

ZoomOut(){
    Loop 30{
        AHI.SendMouseButtonEvent(mouseId, 5, 1)
        sleep 10
    }
}

ParseKeyCombo(keyCombo, ByRef scKey, ByRef scModifier) {
    scKey := 0
    scModifier := 0
    keyCombo := Trim(StrReplace(keyCombo, " ", ""))

    ; Check for modifiers
    if (InStr(keyCombo, "!") && InStr(keyCombo, "+")) { ; Alt+Shift+Key
        scModifier := GetKeySC("LAlt") || GetKeySC("LShift")
        keyCombo := RegExReplace(keyCombo, "[!\+]")
    } else if (InStr(keyCombo, "!")) { ; Alt+Key
        scModifier := GetKeySC("LAlt")
        keyCombo := StrReplace(keyCombo, "!")
    } else if (InStr(keyCombo, "+")) { ; Shift+Key
        scModifier := GetKeySC("LShift")
        keyCombo := StrReplace(keyCombo, "+")
    } else if (InStr(keyCombo, "^")) { ; Ctrl+Key
        scModifier := GetKeySC("LCtrl")
        keyCombo := StrReplace(keyCombo, "^")
    }

    ; Get SC for the main key
    if (keyCombo != "") {
        scKey := GetKeySC(keyCombo) + 0
    }

    return (scKey != 0)
}

SendKeyCombo(rawKeyCombo, pressDuration := 50, holdDuration := 300) {
    static keyParser := Func("ParseKeyCombo") ; Cache the function reference

    ; Parse the key combination
    scKey := 0, scModifier := 0
    if !%keyParser%(rawKeyCombo, scKey, scModifier) {
        MsgBox, Failed to parse key combination: %rawKeyCombo%
        return false
    }

    ; Clear any stuck modifiers first
    ClearModifiers()

    ; Press modifiers if needed
    if (scModifier) {
        if (scModifier & GetKeySC("LAlt"))
            AHI.SendKeyEvent(keyboardId, GetKeySC("LAlt"), 1)
        if (scModifier & GetKeySC("LShift"))
            AHI.SendKeyEvent(keyboardId, GetKeySC("LShift"), 1)
        if (scModifier & GetKeySC("LCtrl"))
            AHI.SendKeyEvent(keyboardId, GetKeySC("LCtrl"), 1)
        Sleep holdDuration
    }

    ; Press and release main key
    AHI.SendKeyEvent(keyboardId, scKey, 1)
    Sleep pressDuration
    AHI.SendKeyEvent(keyboardId, scKey, 0)
    Sleep holdDuration

    ; Release modifiers
    ClearModifiers()
    return true
}

ClearModifiers() {
    static modifiers := [GetKeySC("LAlt"), GetKeySC("LShift"), GetKeySC("LCtrl")]
    for each, modSC in modifiers {
        AHI.SendKeyEvent(keyboardId, modSC, 0)
    }
    Sleep 30
}
