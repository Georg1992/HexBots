; Memory addresses
global maxSpAddress := 0x010DCE1C
global currentSpAddress := 0x010DCE18
global currentWeightAddress := 0x010D94B0
global totalWeightAddress := 0x010D94AC
global currentLocationAddress := 0x010D856C

; State control
global botRunning := false
global memoryOpsInitialized := false


; Initialize timers
InitializeMemoryOperations() {
    if (memoryOpsInitialized)
        return
    
    memoryOpsInitialized := true
    UpdateGameStats()
    SetTimer, CheckBotState, 300
}

CheckBotState() {
    static lastBotState := false
    
    if (botRunning == lastBotState)
        return
    
    if (botRunning) {
        SetTimer, UpdateGameStats, 500
    } else {
        SetTimer, UpdateGameStats, Off
    }
    lastBotState := botRunning
}

UpdateGameStats(){
    Critical
    maxSp := ReadMemoryUInt(gameProcess, maxSpAddress)
    currentSp := ReadMemoryUInt(gameProcess, currentSpAddress)
    currentWeight := ReadMemoryUInt(gameProcess, currentWeightAddress)
    currentLocation := ReadMemoryUInt(gameProcess, currentLocationAddress)
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

