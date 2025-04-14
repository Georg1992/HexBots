SendMode Input
CoordMode, Mouse, Screen

global etc_img := "images\etc_img.bmp"
global eqp_img := "images\eqp_img.bmp"
global use_img := "images\use_img.bmp"
global close_img := "images\close_img.bmp"
global cell1_img := "images\cell1_img.bmp"
global flywing_img := "images\wing_img.bmp"
global ok_img := "images\ok_img.bmp"
global empty_cell_img := "images\empty_cell_img.bmp"

global cellSize = 50
global wingcount := 0

; Game variables
global maxSp := 0
global currentSp := 0
global currentWeight := 0
global totalWeight := 0
global currentLocation := 0

StartBot(){
    InitializeMemoryOperations()
    totalWeight := ReadMemoryUInt(gameProcess,totalWeightAddress)
    ; Wait until critical variables are initialized
    checkcount := 0
    while ((currentLocation == 0 || maxSp == 0 || totalWeight == 0) && checkcount <= 10) { ; Wait max 10 checks
        Sleep 100
        checkcount++
    }

    if (currentLocation == 0 || totalWeight == 0 || maxSp == 0) {
        MsgBox % "Failed to initialize game variables!`n"
        return false
    }

    ZoomOut() 
    skillSC := GetKeySC(SkillButtonKey) + 0
    teleportSC := GetKeySC(TeleportButtonKey) + 0
    sleep 500
    while(botRunning) {
        if (!botRunning || botPaused) ; Double-check flag
            break
        currentLocation := ReadMemoryUInt(gameProcess,currentLocationAddress)
        if(warperCoordsSet && (currentLocation == warperLocation)){ 
            MoveToTheMap(warperX, warperY)
        } 
        if(currentLocation != warperLocation){
            Hunt(skillSC, teleportSC) 
        }
        iterations++
    }
}

Hunt(skillSC, teleportSC) {
    lastWarpTime := 0
    ws := SearchRange * cellSize
    hs := SearchRange * cellSize
    xs := A_ScreenWidth // 2 - ws // 2
    ys := A_ScreenHeight // 2 - hs // 2 
    ; Settings
    attackCount := 2 ; Number of skill uses per monster
    if (lastWarpTime == 0){
        lastWarpTime := A_TickCount
    }


    while(botRunning && !botPaused) {
        if (warperCoordsSet && SavePointButtonKey != "" && (A_TickCount - lastWarpTime) >= (TimeOnLocation * 1000)) {
            WarpToSavePoint()
            lastWarpTime := A_TickCount  ; Reset timer
            Sleep 2000 ; Brief pause after warp
            break  ; Restart hunting loop
        }

        if (WeightModifier >= 50 && currentWeight >= (totalWeight * WeightModifier / 100)) {
            ItemsToStorage()
        }

        if(wingcount <= 0 && TakeFlyWings){
            GetFlyWings()
        }

        PixelSearch, firstX, firstY, xs, ys, xs + ws, ys + hs, targetColor, 1, Fast RGB
        if (ErrorLevel) {
            ; No monsters found - teleport immediately
            Teleport(teleportSC)
            continue
        }

        ; Monster found - attack it
        MouseMove, firstX, firstY
        Loop %attackCount% {
            SkillClick(skillSC)
            Sleep, SkillDelay
        }

        ; Now search for other monsters while ignoring this one
        ignoreX := firstX - 30
        ignoreY := firstY - 30
        ignoreW := 60
        ignoreH := 120

        PixelSearch, otherX, otherY, xs, ys, xs + ws, ys + hs, targetColor, 1, Fast RGB
        while (!ErrorLevel) {
            ; Check if this monster is outside our ignore area
            if (otherX < ignoreX 
                || otherX > ignoreX + ignoreW
            || otherY < ignoreY 
            || otherY > ignoreY + ignoreH) 
            {
                ; Attack the new monster twice
                MouseMove, otherX, otherY
                Loop %attackCount% {
                    SkillClick(skillSC)
                    Sleep, SkillDelay
                }

                ; Update ignore area to include this monster
                ignoreX := Min(ignoreX, otherX - 30)
                ignoreY := Min(ignoreY, otherY - 30)
                ignoreW := Max(ignoreX + ignoreW, otherX + 30) - ignoreX
                ignoreH := Max(ignoreY + ignoreH, otherY + 60) - ignoreY
            }

            ; Search next monster (skip already checked area)
            PixelSearch, otherX, otherY, otherX + 10, otherY, xs + ws, ys + hs, targetColor, 1, Fast RGB
        }

        ; No more monsters found - teleport
        Teleport(teleportSC)
    }
}

Teleport(teleportSC){
    AHI.SendKeyEvent(keyboardId, teleportSC, 1)
    sleep 50
    AHI.SendKeyEvent(keyboardId, teleportSC, 0)
    sleep 800
    if(TakeFlyWings){
        wingcount--
    }
}

MoveToTheMap(posX, posY) {
    mousemove, posX, posY
    Sleep 500
    AHI.SendMouseButtonEvent(mouseId, 0, 1)
    sleep 50
    AHI.SendMouseButtonEvent(mouseId, 0, 0)
    Sleep 500
    Send {Enter}
    
    Sleep 1500
}

WarpToSavePoint() {
    SendKeyCombo(SavePointButtonKey)
    Sleep 2000  ; Wait for warp to complete
}

GetFlyWings() {
    if !SendKeyCombo(OpenStorageButtonKey) {
        return false
    }
    Sleep 800
    MoveCursorToImage(flywing_img,0,0)
    sleep 50
    AHI.SendMouseButtonEvent(mouseId, 0, 1)
    sleep 100
    ManageInventoryWindow()
    sleep 100
    MoveCursorToImage(etc_img,100,20)
    AHI.SendMouseButtonEvent(mouseId, 0, 0)
    sleep 200
    send %wingsTaken%
    sleep 200
    SendInput {Enter}

    ManageInventoryWindow()
    MoveCursorToImage(close_img,0,0)
    sleep 200
    AHI.SendMouseButtonEvent(mouseId, 0, 1)
    sleep 50
    AHI.SendMouseButtonEvent(mouseId, 0, 0)
    wingcount := wingsTaken
    sleep 200
}

ManageInventoryWindow(){
    action := "open"
    if(action = "close"){
        ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, etc_img

    }
    AHI.SendKeyEvent(keyboardId, 56, 1)
    sleep 50
    AHI.SendKeyEvent(keyboardId, 18, 1)
    sleep 50
    AHI.SendKeyEvent(keyboardId, 18, 0)
    sleep 50
    AHI.SendKeyEvent(keyboardId, 56, 0)
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

CheckInventoryCell(image) {
    ; Get current mouse position
    MouseGetPos, currentX, currentY

    cellSize := 40
    searchLeft := currentX - cellSize//2
    searchTop := currentY - cellSize//2
    searchRight := currentX + cellSize//2
    searchBottom := currentY + cellSize//2

    ; Search for image in this area
    ImageSearch, FoundX, FoundY, searchLeft, searchTop, searchRight, searchBottom, %image%

    if (ErrorLevel = 0) {
        if(image == flywing_img){
            ; Image found - move to next cell (right)
            nextCellX := currentX + cellSize
            nextCellY := currentY

            ; Ensure we stay within inventory bounds
            maxRight := A_ScreenWidth - cellSize//2
            if (nextCellX > maxRight) {
                nextCellX := cellSize//2 ; Wrap to first column
                nextCellY += cellSize ; Move down one row
            }
            MouseMove, nextCellX, nextCellY, 0
        }
        return true
    }

    ; Image not found in this cell
    return false
}

ItemsToStorage(){
    Sleep 500
    ManageInventoryWindow()
    sleep 500
    MoveCursorToImage(use_img,0,0)
    Sleep 100
    AHIclick()
    SendKeyCombo(OpenStorageButtonKey)
    MoveCursorToImage(cell1_img,0,40)
    while(!CheckInventoryCell(empty_cell_img)){
        CheckInventoryCell(flywing_img)
        AltClicks(1)
        sleep 50
    }
    sleep 100
    MoveCursorToImage(eqp_img,0,0)
    sleep 100
    AHIclick()
    sleep 50
    MoveCursorToImage(cell1_img,0,40)
    while(!CheckInventoryCell(empty_cell_img)){
        AltClicks(1)
        sleep 50
    }

    MoveCursorToImage(etc_img,0,0)
    sleep 100
    AHIclick()
    sleep 100
    MoveCursorToImage(cell1_img,0,40)
    while(!CheckInventoryCell(empty_cell_img)){
        sleep 50
        if(CheckImageOnScreen(ok_img)){
            AHI.SendKeyEvent(keyboardId, 284, 1)
            sleep 50
            AHI.SendKeyEvent(keyboardId, 284, 0)
            MouseGetPos, currentX, currentY
            MouseMove, currentX+40, currentY, 0
        }
        AltClicks(1)
    }
    sleep 100
    MoveCursorToImage(close_img,10,10)
    sleep 100
    AHIclick()
    ManageInventoryWindow()
    sleep 500
}

