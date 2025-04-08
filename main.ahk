#SingleInstance Force
#Persistent
#include Lib\AutoHotInterception.ahk
#include MobData.ahk
#include BotLogic.ahk

global gameWindowID := 0 ; Initialize as 0 (numeric)
global gameWindowTitle := ""
global gameProcess := ""
global windowIDs := {} ; Using object/dictionary for reliable storage
global titleToIndex := {} ; Maps dropdown item text -> index

global botRunning := false

; 1. CONFIGURATION CHECK
if (FileExist("config.ini")) {
    IniRead, mouseVID, config.ini, Devices, mouseVID
    IniRead, mousePID, config.ini, Devices, mousePID
    IniRead, keyboardVID, config.ini, Devices, keyboardVID
    IniRead, keyboardPID, config.ini, Devices, keyboardPID

    if (mouseVID != "ERROR" && mousePID != "ERROR") {
        MsgBox, 4,, Found existing configuration:`nMouse: %mouseVID% %mousePID%`nKeyboard: %keyboardVID% %keyboardPID%`n`nReconfigure devices?
        IfMsgBox Yes
        {
            RunWait, DeviceDetector.ahk
            IniRead, mouseVID, config.ini, Devices, mouseVID
            IniRead, mousePID, config.ini, Devices, mousePID
            IniRead, keyboardVID, config.ini, Devices, keyboardVID
            IniRead, keyboardPID, config.ini, Devices, keyboardPID
        }
    }
    else {
        RunWait, DeviceDetector.ahk
    }
}
else {
    RunWait, DeviceDetector.ahk
}

; 2. HEX CONVERSION 
mouseVID := mouseVID + 0
mousePID := mousePID + 0
keyboardVID := keyboardVID + 0
keyboardPID := keyboardPID + 0

; 3. DEVICE INITIALIZATION
global AHI := new AutoHotInterception()
global mouseId := AHI.GetMouseID(mouseVID, mousePID)
global keyboardId := AHI.GetKeyboardID(keyboardVID, keyboardPID)

; 4. VERIFICATION
if (!mouseId || !keyboardId) {
    MsgBox Device initialization failed!`n`nMouse: %mouseVID% %mousePID%`nKeyboard: %keyboardVID% %keyboardPID%
    ExitApp
}

; --------------------------
; GUI Setup (Cleaned & Spaced)
; --------------------------
Gui, Font, s10, Segoe UI

; Title
Gui, Add, Text, x10 y15 w700 h30 Center, Hex Bot
Gui, Add, Text, x10 y50 w700 h2 0x10 ; Divider

; Window Selection
Gui, Add, Text, x20 y70 w280 h30, Select Game Window:
Gui, Add, DropDownList, x20 y100 w200 h25 r10 vSelectedWindow gOnWindowSelect, || 
Gui, Add, Button, x230 y100 w70 h25 gRefreshWindows, Refresh
Gui, Add, Text, x20 y130 w280 h25 vWindowInfo, No window selected

; Bot Status
Gui, Add, Text, x500 y70 w150 h30 vBotStatus, Status: Offline
Gui, Add, Progress, x500 y+3 w150 h12 cRed vStatusLight, 100

; Device Info

Gui, Add, Text, x500 y170 w150 h40 vMouseStatus, % "MouseIDs: " Format("0x{:04X}", mouseVID) ", " Format("0x{:04X}", mousePID)
Gui, Add, Text, x500 y+15 w150 h40 vKeyboardStatus, % "KeyboardIDs: " Format("0x{:04X}", keyboardVID) ", " Format("0x{:04X}", keyboardPID)

; Monster Type
monsterStartY := 170
Gui, Add, Text, x20 y%monsterStartY% w120 h30, Monster Type:
yPos := monsterStartY + 30
Gui, Add, Radio, x20 y%yPos% vSelectedMonster Checked, % MobNames[1]
yPos += 35
Loop % MobNames.MaxIndex() - 1
{
    Gui, Add, Radio, x20 y%yPos%, % MobNames[A_Index + 1]
    yPos += 35
}

; Keybindings
Gui, Add, Text, x160 y200 w130 h25, Attack Skill Button:
Gui, Add, Hotkey, x300 yp w55 vSkillButtonKey

Gui, Add, Text, x160 y+10 w130 h25, Teleport Button:
Gui, Add, Hotkey, x300 yp w55 vTeleportButtonKey

Gui, Add, Text, x160 y+10 w130 h25, To Save Point Button:
Gui, Add, Hotkey, x300 yp w55 vSavePointButtonKey

Gui, Add, Text, x160 y+10 w130 h25, SP Item Button:
Gui, Add, Hotkey, x300 yp w55 vSPButtonKey

Gui, Add, Text, x160 y+10 w130 h25, Open Storage Button:
Gui, Add, Hotkey, x300 yp w55 vOpenStorageButtonKey

; Slider Controls - Matching Original Input Field Positions
inputStartY := yPos + 30

; Search Range Slider (9-16 cells) - Same position as original Edit field
Gui, Add, Text, x20 y%inputStartY% w120 h40, Search Range (9-16 Cells):
Gui, Add, Slider, x150 yp w200 h25 vSearchRange Range9-16 TickInterval1 ToolTip, 10
Gui, Add, Text, x+5 yp w30 h25 vSearchRangeText Center, 10

; Time on Location Slider (20-240s) - Same position as original Edit field
Gui, Add, Text, x20 y+20 w120 h40, Time on Location (s):
Gui, Add, Slider, x150 yp w200 h25 vTimeOnLocation Range20-240 TickInterval20 ToolTip, 60
Gui, Add, Text, x+5 yp w30 h25 vTimeOnLocationText Center, 60

; Items to Kafra After - Same position as original Edit field
Gui, Add, Text, x20 y+20 w120 h40, Items To Kafra after (iterations):
Gui, Add, Slider, x150 yp w200 h25 vIterations Range0-20 TickInterval1 ToolTip, 20
Gui, Add, Text, x+5 yp w30 h25 vIterationsText Center, 20

; Update slider values in real-time
GuiControl +gUpdateSliderValues, SearchRange
GuiControl +gUpdateSliderValues, TimeOnLocation
GuiControl +gUpdateSliderValues, Iterations

; Checkbox Options
Gui, Add, CheckBox, x20 y600 vTakeFlyWings, Take Fly Wings
Gui, Add, CheckBox, x20 y+30 vDetectCaptcha, Detect Captcha (HoneyRO)

; Control Buttons
buttonStartY := inputStartY + 300
; Place the hotkey reminder just above the buttons:
reminderY := buttonStartY - 40
Gui, Add, Text, x220 y%reminderY% w280 h30 Center, Press F12 to quickly toggle bot

Gui, Add, Button, x220 y%buttonStartY% w120 h40 gToggleBot vBotButton, Start Bot
Gui, Add, Button, x360 y%buttonStartY% w120 h40 gExitBot, Exit

; Final GUI Show
Gui, Show, w700 h800, Hex Bot
GuiControl,, StatusLight, 100
Gosub, RefreshWindows
return

UpdateSliderValues:
    Gui, Submit, NoHide
    GuiControl,, SearchRangeText, %SearchRange%
    GuiControl,, TimeOnLocationText, %TimeOnLocation%
    GuiControl,, IterationsText, %Iterations%
return

RefreshWindows:
    GuiControl,, SelectedWindow, |
    windowList := ""
    windowIDs := {}
    titleToIndex := {}

    DetectHiddenWindows, On
    WinGet, windows, List
    DetectHiddenWindows, Off

    itemCount := 0
    Loop, %windows%
    {
        id := windows%A_Index%
        WinGetTitle, title, ahk_id %id%
        WinGet, process, ProcessName, ahk_id %id%

        if (title = "" || process = "")
            continue

        WinGet, guiID, ID, Monster Hunter Bot ahk_class AutoHotkeyGUI
        if (id = guiID)
            continue

        itemCount += 1
        WinGet, minMaxStatus, MinMax, ahk_id %id%
        stateSymbol := (minMaxStatus = -1) ? "[MIN] " : ""
            displayText := stateSymbol title " (" process ")"

            windowList .= "|" displayText
            windowIDs[itemCount] := id
            titleToIndex[displayText] := itemCount
        }

        GuiControl,, SelectedWindow, %windowList%

        ; Attempt to auto-select previously used window
        IniRead, lastTitle, config.ini, LastSession, GameTitle, ERROR
        IniRead, lastProcess, config.ini, LastSession, GameProcess, ERROR

        if (lastTitle != "ERROR" && lastProcess != "ERROR") {
            for index, id in windowIDs {
                WinGetTitle, tTitle, ahk_id %id%
                WinGet, tProcess, ProcessName, ahk_id %id%
                if (tTitle = lastTitle && tProcess = lastProcess) {
                    WinGet, minMaxStatus, MinMax, ahk_id %id%
                    stateSymbol := (minMaxStatus = -1) ? "[MIN] " : ""
                        selectedDisplay := stateSymbol tTitle " (" tProcess ")"
                        GuiControl, ChooseString, SelectedWindow, %selectedDisplay%
                        Gosub, OnWindowSelect
                    return
                }
            }
        }

        ; If nothing selected, pick the first one (if any)
        if (windowList != "") {
            GuiControl, Choose, SelectedWindow, 1
            Gosub, OnWindowSelect
        }
        return

        OnWindowSelect:
            GuiControlGet, selectedText,, SelectedWindow

            if (!selectedText || !titleToIndex.HasKey(selectedText)) {
                GuiControl,, WindowInfo, No window selected
                gameWindowID := 0
                return
            }

            selectedIndex := titleToIndex[selectedText]
            gameWindowID := windowIDs[selectedIndex]

            if (!gameWindowID || !WinExist("ahk_id " gameWindowID)) {
                GuiControl,, WindowInfo, Window not found! Refresh list.
                gameWindowID := 0
                return
            }

            WinGetTitle, gameWindowTitle, ahk_id %gameWindowID%
            WinGet, gameProcess, ProcessName, ahk_id %gameWindowID%
            GuiControl,, WindowInfo, % "SELECTED: " gameProcess

            WinSet, Transparent, 150, ahk_id %gameWindowID%
            Sleep, 300
            WinSet, Transparent, Off, ahk_id %gameWindowID%
        return

        ToggleBot:
            Gui, Submit, NoHide
            IniWrite, %gameProcess%, config.ini, LastSession, GameProcess
            IniWrite, %gameWindowTitle%, config.ini, LastSession, GameTitle

            ; STRICT verification
            if (!gameWindowID || gameWindowID = 0) {
                MsgBox, 16, Error, Please select a valid game window first!
                return
            }

            ; ENHANCED existence check
            if !WinExist("ahk_id " gameWindowID) {
                MsgBox, 16, Error, The game window doesn't exist!`nPlease refresh and select again.
                Gosub, RefreshWindows
                return
            }

            if (!botRunning) {
                ; RESTORE MINIMIZED WINDOW
                WinGet, minMaxStatus, MinMax, ahk_id %gameWindowID%
                if (minMaxStatus = -1) {
                    WinRestore, ahk_id %gameWindowID%
                    Sleep, 1000 ; Give time to restore
                }

                ; ACTIVATE WINDOW 

                WinActivate, ahk_id %gameWindowID%
                WinWaitActive, ahk_id %gameWindowID%, , 2

                ; FINAL VERIFICATION
                WinGet, activeID, ID, A
                if (activeID != gameWindowID) {
                    ; LAST RESORT - remove disabled style
                    WinSet, Style, -0x8000000, ahk_id %gameWindowID%
                    WinActivate, ahk_id %gameWindowID%
                    WinWaitActive, ahk_id %gameWindowID%, , 3
                    if ErrorLevel {
                        MsgBox, 16, Error, Failed to activate game window!`nTry running as Administrator.
                        return
                    }
                }

                ; Read hotkey inputs
                GuiControlGet, skillKey,, SkillButtonKey
                GuiControlGet, teleportKey,, TeleportButtonKey
                GuiControlGet, savePointKey,, SavePointButtonKey
                GuiControlGet, spKey,, SPButtonKey
                GuiControlGet, storageKey,, OpenStorageButtonKey

                ; Convert keys to scan codes (decimal)
                skillSC := GetKeySC(skillKey) + 0
                teleportSC := GetKeySC(teleportKey) + 0
                savePointSC := GetKeySC(savePointKey) + 0
                spSC := GetKeySC(spKey) + 0
                storageSC := GetKeySC(storageKey) + 0

                ; Save to INI
                IniWrite, %skillSC%, config.ini, Keys, Skill
                IniWrite, %teleportSC%, config.ini, Keys, Teleport
                IniWrite, %savePointSC%, config.ini, Keys, SavePoint
                IniWrite, %spSC%, config.ini, Keys, SPItem
                IniWrite, %storageSC%, config.ini, Keys, OpenStorage
                ; Save sliders
                IniWrite, %SearchRange%, config.ini, Settings, SearchRange
                IniWrite, %TimeOnLocation%, config.ini, Settings, TimeOnLocation
                IniWrite, %Iterations%, config.ini, Settings, Iterations

                ; Save checkboxes (1 = checked, 0 = unchecked)
                IniWrite, %TakeFlyWings%, config.ini, Settings, TakeFlyWings
                IniWrite, %DetectCaptcha%, config.ini, Settings, DetectCaptcha

                botRunning := true
                GuiControl,, BotButton, Stop Bot
                GuiControl,, BotStatus, Status: ONLINE
                GuiControl, +cGreen, StatusLight
                GuiControl,, StatusLight, 100

                targetColor := MobColors[SelectedMonster]
                StartBot(targetColor)

            } else {
                ; Stop the bot
                botRunning := false
                GuiControl,, BotButton, Start Bot
                GuiControl,, BotStatus, Status: Offline
                GuiControl, +cRed, StatusLight
                GuiControl,, StatusLight, 100
            }
        return

        RemoveToolTip:
            ToolTip ; This clears any active tooltip
            SetTimer, RemoveToolTip, Off ; Turn off the timer
        return

        ^p::Pause

        ExitBot:
        ExitApp
        return

        GuiClose:
        ExitApp
