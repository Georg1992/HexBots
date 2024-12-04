#include %A_LineFile%/../../../interfaces/keyboard.ahk
#include %A_LineFile%/../../../../lib/AutoHotInterception.ahk
#include %A_LineFile%/../../../../lib/config_loader.ahk
#include %A_LineFile%/../../../../lib/formatter.ahk
#include %A_LineFile%/../../../../lib/random_sleep.ahk

class KeyboardAHI extends IKeyboard {
    AHI := null
    id := null

    __New() {
        config := new ConfigLoader("config/keyboard.json").Get()
        this.AHI := new AutoHotInterception()
        this.id = this.AHI.GetKeyboardId(StrToHex(config.ahi.vid), StrToHex(config.ahi.pid))
    }

    ; Set button as pressed
    ButtonDown(keyName) {
        this.AHI.SendKeyEvent(this.id, GetKeySC(keyName), 1)
    }

    ; Release button
    ButtonUp(keyName) {
        this.AHI.SendKeyEvent(this.id, GetKeySC(keyName), 0)
    }

    ; Send button
    ButtonPress(keyName) {
        this.AHI.SendKeyEvent(this.id, GetKeySC(btn), 1)
        RandSleep(30, 50)
        this.AHI.SendKeyEvent(this.id, GetKeySC(btn), 0)
    }
}