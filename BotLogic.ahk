SendMode Input

etc_img := "images\etc_img.bmp"
use_img := "images\use_img.bmp"
close_img := "images\close_img.bmp"
cell1_img := "images\cell1_img.bmp"


StartBot(targetColor){
    IniRead, skillSC, config.ini, Keys, Skill, 0
    IniRead, teleportSC, config.ini, Keys, Teleport, 0
    IniRead, savepointSC, config.ini, Keys, SavePoint, 0
    IniRead, SPItemSC, config.ini, Keys, SPItem, 0

    ; Read search range from config or pass it from GUI
    IniRead, searchRange, config.ini, Settings, SearchRange, 16 ; Default to 16 if not found

    Hunt(targetColor,skillSC,teleportSC,searchRange)

}

Hunt(targetColor,skillSC,teleportSC,searchRange) {
    cellSize := 50 ;aproximately 50pixels
    ; Calculate search window size
    ws := searchRange * cellSize
    hs := searchRange * cellSize

    ; Calculate screen position (centered)
    xs := A_ScreenWidth // 2 - ws // 2
    ys := A_ScreenHeight // 2 - hs // 2 
    Loop {
        PixelSearch, x, y, xs, ys, xs + ws, ys + hs, targetColor, 1, Fast RGB

        if (ErrorLevel = 0) {
            MouseMove x, y
            SkillClick(skillSC)
            sleep 100
        }
        else if (ErrorLevel = 1) {
            Teleport(teleportSC)
        }
    }
}

Teleport(teleportSC){
    AHI.SendKeyEvent(keyboardId, teleportSC, 1)
    sleep 50
    AHI.SendKeyEvent(keyboardId, teleportSC, 0)
    sleep 1000
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

SkillClick(KeySC){
    sleep 50
    AHI.SendKeyEvent(keyboardId, KeySC, 1)
    sleep 50
    AHI.SendKeyEvent(keyboardId, KeySC, 0)
    AHI.SendMouseButtonEvent(mouseId, 0, 1)
    sleep 50
    AHI.SendMouseButtonEvent(mouseId, 0, 0)
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