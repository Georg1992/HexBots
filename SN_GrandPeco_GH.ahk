#Persistent
#include Lib\AutoHotInterception.ahk
#include OriginalMobColors.ahk
SetWorkingDir %A_ScriptDir%

global AHI := new AutoHotInterception()
global mouseId := AHI.GetMouseID(0x09DA, 0x9090)
global keyboardId := AHI.GetKeyboardID(0x0B05, 0x194B)
global breakLoop := false
global clicks :=0

global ws:=550  ;width and height 
global hs:=450  ;of search area 

global xs:=a_screenwidth//2 - ws//2
global ys:=a_screenheight//2 - hs//2


;MAIN
F12::
{
	
	Loop {
		AHI.SendKeyEvent(keyboardId, 61, 1)
		sleep 50
		AHI.SendKeyEvent(keyboardId, 61, 0)
		sleep 500
		MoveToTheMap()
		breakLoop := false 
		SetTimer, BuffTimer, Off ; Stop the timer if running
		SetTimer, BuffTimer, 238000 ; Restart the timer for 4 minutes
		Hunt()
	}
}
return



;SUBROUTINES

BuffTimer:
	x := (A_ScreenWidth // 2)
	y := (A_ScreenHeight // 2)
	mousemove, x, y
	breakLoop := true
	AHI.SendMouseButtonEvent(mouseId, 0, 0)
	sleep 500
	Send {Alt down}
	Send 0
	Send {Alt up}
	wingcount := 0
	sleep 1500
return



;FUNCTIONS

Teleport(){
	AHI.SendKeyEvent(keyboardId, 59, 1)
	sleep 50
	AHI.SendKeyEvent(keyboardId, 59, 0)
	sleep 1000
	AHI.SendKeyEvent(keyboardId, 62, 1)
	sleep 50
	AHI.SendKeyEvent(keyboardId, 62, 0)
	s:=0

}

MoveToTheMap() {
	x := (A_ScreenWidth // 2)
	y := (A_ScreenHeight // 2)

	mousemove, x, y
	Sleep 200
	MouseGetPos, PosX, PosY
	mousemove, x + 125, y - 220
	Sleep 500
	AHI.SendMouseButtonEvent(mouseId, 0, 1)
	sleep 50
	AHI.SendMouseButtonEvent(mouseId, 0, 0)
	Sleep 500
	Send {Enter}
	Sleep 1500
}

Hunt() {
	
	Loop {
			
		if (DetectCAPTCHA()) {
            breakLoop := true
            return
        }
		if (breakLoop) {
				break
			}
			
		PixelSearch, x, y, xs, ys, xs+ws, ys+hs, GrandPeco, 1, Fast RGB

		if (ErrorLevel = 0) {
			MouseMove x, y
			sleep 50
			AHI.SendKeyEvent(keyboardId, 60, 1)
			sleep 50
			AHI.SendKeyEvent(keyboardId, 60, 0)
			AHI.SendMouseButtonEvent(mouseId, 0, 1)
			sleep 50
			AHI.SendMouseButtonEvent(mouseId, 0, 0)
			sleep 500
			clicks++
			if(clicks>8){
				Teleport()
			}
			}
			else if (ErrorLevel = 1) {
				PixelSearch, x, y, xs, ys, xs+ws, ys+hs, 0xFDE2B0, 1, Fast RGB
				if(ErrorLevel = 0)
				{
					MouseMove x, y
					sleep 50
					AHI.SendKeyEvent(keyboardId, 60, 1)
					sleep 50
					AHI.SendKeyEvent(keyboardId, 60, 0)
					AHI.SendMouseButtonEvent(mouseId, 0, 1)
					sleep 50
					AHI.SendMouseButtonEvent(mouseId, 0, 0)
					sleep 500
				}else{
					Teleport()
				}
			}
		}

	}
	
DetectCAPTCHA() {
    global xs, ys, ws, hs
    PixelSearch, x, y, xs, ys, xs + ws, ys + hs, 0xC40909, 1, Fast RGB 
    if (ErrorLevel = 0) {
        ; CAPTCHA detected
        SoundBeep, 750, 500 ; Frequency: 750 Hz, Duration: 500 ms
        MsgBox, CAPTCHA suka!
        Pause, On 
        return true
    }
    return false
}


^p::Pause

F11:: ExitApp