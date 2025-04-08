#SingleInstance force
#Persistent
#include Lib\AutoHotInterception.ahk

; Initialize AHI
AHI := new AutoHotInterception()

; Get all devices
DeviceList := AHI.GetDeviceList()

; Find all mouse devices (IDs 11-20)
mouseDevices := []
for id, device in DeviceList {
    if (id >= 11 && id <= 20 && IsObject(device)) {
        mouseDevices.Push({id: id, VID: device.VID, PID: device.PID})
    }
}

; Find all keyboard devices (IDs 1-10)
keyboardDevices := []
for id, device in DeviceList {
    if (id >= 1 && id <= 10 && IsObject(device)) {
        keyboardDevices.Push({id: id, VID: device.VID, PID: device.PID})
    }
}

if (mouseDevices.Length() = 0) {
    MsgBox No mouse devices found!
    ExitApp
}

currentMouseIndex := 1
currentMouseDevice := mouseDevices[currentMouseIndex]
isMouseSubscribed := false

; Keyboard variables
currentKeyboardIndex := 1
isKeyboardSubscribed := false

; Create GUI for detection status
Gui, DetectGUI:New
Gui, DetectGUI:Add, Text, w300 Center, Device Detection
Gui, DetectGUI:Add, Text, y+10, Mouse Status: Detecting...
Gui, DetectGUI:Add, Text,, Keyboard Status: Waiting for mouse...
Gui, DetectGUI:Show, w320 h120, Device Detector

; Subscribe to first mouse device
SubscribeToMouseDevice(currentMouseDevice)
SetTimer, RotateMouseDevice, 2000

return

; --------------------------
; MOUSE DETECTION
; --------------------------
RotateMouseDevice:
    if (isMouseSubscribed) {
        AHI.UnsubscribeMouseButtons(currentMouseDevice.id)
        isMouseSubscribed := false
    }
    
    currentMouseIndex := Mod(currentMouseIndex, mouseDevices.Length()) + 1
    currentMouseDevice := mouseDevices[currentMouseIndex]
    
    SubscribeToMouseDevice(currentMouseDevice)
    
    GuiControl, DetectGUI:, Static2, % "Mouse Status: Testing ID " currentMouseDevice.id
    ToolTip % "Now monitoring mouse device ID: " currentMouseDevice.id
    SetTimer, RemoveToolTip, 2000
return

SubscribeToMouseDevice(device) {
    global AHI, isMouseSubscribed
    AHI.SubscribeMouseButtons(device.id, false, Func("MouseClickEvent").Bind(device))
    isMouseSubscribed := true
}

MouseClickEvent(device, code, state) {
    ; Left mouse button click (code 0)
    if (code = 0 && state = 1) {
        ; Save mouse detection in 0xXXXX format
        formattedVID := Format("0x{:04X}", device.VID)
        formattedPID := Format("0x{:04X}", device.PID)
        SaveConfig("mouse",formattedVID,formattedPID)
        
        GuiControl, DetectGUI:, Static2, % "Mouse Status: Detected! ID " device.id
        ToolTip % "Mouse click detected!`n" formattedVID ", " formattedPID
        SetTimer, RemoveToolTip, 2000
        
        ; Stop mouse rotation
        SetTimer, RotateMouseDevice, Off
        if (isMouseSubscribed) {
            AHI.UnsubscribeMouseButtons(currentMouseDevice.id)
            isMouseSubscribed := false
        }
        
        ; Start keyboard detection
        GuiControl, DetectGUI:, Static3, Keyboard Status: Detecting...
        StartKeyboardDetection()
    }
}

; --------------------------
; KEYBOARD DETECTION
; --------------------------
StartKeyboardDetection() {
    global
    if (keyboardDevices.Length() = 0) {
        MsgBox No keyboard devices found!
        return
    }
    
    currentKeyboardDevice := keyboardDevices[currentKeyboardIndex]
    SubscribeToKeyboardDevice(currentKeyboardDevice)
    SetTimer, RotateKeyboardDevice, 2000
    ToolTip Starting keyboard detection...
    SetTimer, RemoveToolTip, 2000
}

RotateKeyboardDevice:
    if (isKeyboardSubscribed) {
        AHI.UnsubscribeKeyboard(currentKeyboardDevice.id)
        isKeyboardSubscribed := false
    }
    
    currentKeyboardIndex := Mod(currentKeyboardIndex, keyboardDevices.Length()) + 1
    currentKeyboardDevice := keyboardDevices[currentKeyboardIndex]
    
    SubscribeToKeyboardDevice(currentKeyboardDevice)
    
    GuiControl, DetectGUI:, Static3, % "Keyboard Status: Testing ID " currentKeyboardDevice.id
    ToolTip % "Now monitoring keyboard device ID: " currentKeyboardDevice.id
    SetTimer, RemoveToolTip, 2000
return

SubscribeToKeyboardDevice(device) {
    global AHI, isKeyboardSubscribed
    AHI.SubscribeKeyboard(device.id, false, Func("KeyboardEvent").Bind(device))
    isKeyboardSubscribed := true
}

KeyboardEvent(device, code, state) {
    ; Only act on key presses (state = 1)
    if (state = 1) {
        ; Save keyboard detection in 0xXXXX format
        formattedVID := Format("0x{:04X}", device.VID)
        formattedPID := Format("0x{:04X}", device.PID)
        SaveConfig("keyboard",formattedVID,formattedPID)
        
        keyName := GetKeyName(Format("SC{:X}", code))
        GuiControl, DetectGUI:, Static3, % "Keyboard Status: Detected! ID " device.id
        ToolTip % "Keyboard detected!`n" formattedVID ", " formattedPID
        SetTimer, RemoveToolTip, 2000
        
        ; Stop everything after keyboard detection
        SetTimer, RotateKeyboardDevice, Off
        if (isKeyboardSubscribed) {
            AHI.UnsubscribeKeyboard(currentKeyboardDevice.id)
            isKeyboardSubscribed := false
        }
        
        ; Close after short delay
        SetTimer, CloseAfterDetection, -2000
    }
}

; --------------------------
; HELPER FUNCTIONS
; --------------------------
SaveConfig(deviceType, vid, pid) {
    IniWrite, % "0x" Format("{:04X}", vid), config.ini, Devices, % deviceType "VID"
    IniWrite, % "0x" Format("{:04X}", pid), config.ini, Devices, % deviceType "PID"
}

CloseAfterDetection:
    Gui, DetectGUI:Destroy
    Sleep 500
    ExitApp
return

RemoveToolTip:
    ToolTip
return

^Esc::
    ExitApp
