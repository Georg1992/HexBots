; Memory addresses
global maxSpAddress := 0x010DCE1C
global currentSpAddress := 0x010DCE18
global currentWeightAddress := 0x010D94B0
global totalWeightAddress := 0x010D94AC
global currentLocationAddress := 0x010D856C


UpdateGameStats() {
    Critical
    ; Read memory values
    maxSp := ReadMemoryUInt(gameProcess, maxSpAddress)
    currentSp := ReadMemoryUInt(gameProcess, currentSpAddress)
    currentWeight := ReadMemoryUInt(gameProcess, currentWeightAddress)
    currentLocation := ReadMemoryUInt(gameProcess, currentLocationAddress)
    
    ; Get current mouse position
    MouseGetPos, mouseX, mouseY
    
    ; Create the tooltip text with basic formatting
    ToolTip, 
    (
    SP: %currentSp%/%maxSp%
    Weight: %currentWeight%/%totalWeight%
    Location: %currentLocation%
    ), mouseX + 20, mouseY + 20
    
    ; Make tooltip disappear after 2 seconds
    SetTimer, RemoveToolTip, -5000
    return
    
}


ReadMemoryUInt(processName, address) {
    Process, Exist, %processName%
    pid := ErrorLevel
    if (!pid)
        return 0

    hProcess := DllCall("OpenProcess", "UInt", 0x10, "Int", 0, "UInt", pid, "Ptr")
    if (!hProcess)
        return 0

    VarSetCapacity(buffer, 4, 0)
    success := DllCall("ReadProcessMemory", "Ptr", hProcess, "Ptr", address, "Ptr", &buffer, "UInt", 4, "UInt*", 0)
    DllCall("CloseHandle", "Ptr", hProcess)

    return (success) ? NumGet(&buffer, 0, "UInt") : 0
}

