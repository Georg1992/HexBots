#include %A_LineFile%/../../../interfaces/mouse.ahk
#include %A_LineFile%/../../../../lib/AutoHotInterception.ahk
#include %A_LineFile%/../../../../lib/config_loader.ahk
#include %A_LineFile%/../../../../lib/formatter.ahk
#include %A_LineFile%/../../../../lib/random_sleep.ahk

class MouseAHI extends IMouse {
    AHI := null
    id := null

    __New() {
        config := new ConfigLoader("config/mouse.json").Get()
        this.AHI := new AutoHotInterception()
        this.id = this.AHI.GetMouseID(StrToHex(config.ahi.vid), StrToHex(config.ahi.pid))
    }

    RightBtnClick() {
        this.AHI.SendMouseButtonEvent(this.id, 1, 1)
        RandSleep(30, 50)
        this.AHI.SendMouseButtonEvent(this.id, 1, 0)
    }

    LeftBtnClick() {
        this.AHI.SendMouseButtonEvent(this.id, 0, 1)
	    RandSleep(30, 50)
	    this.AHI.SendMouseButtonEvent(this.id, 0, 0)
    }

    Move(x, y) { 
        this.AHI.MoveCursor(x, y, "Window",this.id)
    }

    MoveAbsolute(x, y) {
        this.AHI.SendMouseButtonEventAbsolute(this.id, 1, 1, x, y)
        RandSleep(30, 50)
        this.AHI.SendMouseButtonEventAbsolute(this.id, 1, 0, x, y)
    }
}