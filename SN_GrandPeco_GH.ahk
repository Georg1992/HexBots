;STORAGE - ALT + 6

#Persistent
#include Lib\AutoHotInterception.ahk
#include OriginalMobColors.ahk
SetWorkingDir %A_ScriptDir%
global etc_img := "images\etc_img.bmp"
global use_img := "images\use_img.bmp"
global close_img := "images\close_img.bmp"
global cell1_img := "images\cell1_img.bmp"

global AHI := new AutoHotInterception()
global mouseId := AHI.GetMouseID(0x0B05, 0x1949)
global keyboardId := AHI.GetKeyboardID(0x0B05, 0x1866)
global breakLoop := false
global clicks :=0
global iterationsBeforeKafra := 20

global ws:=550  ;width and height 
global hs:=450  ;of search area 

global xs:=a_screenwidth//2 - ws//2
global ys:=a_screenheight//2 - hs//2


;MAIN
F12::
{
iterations := 0
	
	Loop {
		AHI.SendKeyEvent(keyboardId, 61, 1)
		sleep 50
		AHI.SendKeyEvent(keyboardId, 61, 0)
		sleep 500
		MoveToTheMap()
		breakLoop := false 
		SetTimer, BuffTimer, Off ; Stop the timer if running
		SetTimer, BuffTimer, 235000 ; Restart the timer for 4 minutes
		Hunt()
		if(mod(iterations,iterationsBeforeKafra) = 0){
			vKafru()
		}
		iterations++
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
	sleep 500
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

VKafru(){

	Send {Alt down}
    Send e
    Send {Alt up}
	sleep 500
	MoveCursorToImage(use_img,0,0)
	Sleep 100
	click

	MoveCursorToImage(cell1_img,0,20)
	
	Send {Alt down}
    Send 6
    Send {Alt up}
	
	AltClicks(5)
	sleep 50
	MoveCursorToImage(etc_img,0,0)
	click
	sleep 100
	MoveCursorToImage(cell1_img,0,20)
	AltClicks(5)
	sleep 100
	MoveCursorToImage(close_img,0,0)
	sleep 100
	click
	Send {Alt down}
    Send e
    Send {Alt up}
	sleep 500
	
	
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
			
		PixelSearch, x, y, xs, ys, xs+ws, ys+hs, 0xCD9CAC, 1, Fast RGB

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
			Teleport()
		}
	}

}
	
DetectCAPTCHA() {
    global xs, ys, ws, hs
    PixelSearch, x, y, xs, ys, xs + ws, ys + hs, 0xC50A0A, 1, Fast RGB 
    if (ErrorLevel = 0) {
        ; CAPTCHA detected
		Loop,8{
			SoundBeep, 750, 1000 ; Frequency: 750 Hz, Duration: 1s
			sleep 500
		}
		Pause, On
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
}

AltClicks(times){
	Send {Alt down}
	sleep 50
	Loop, %times%{
		click, right
		sleep 500
	}
	Send {Alt up}
}



^p::Pause

F11:: ExitApp