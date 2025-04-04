#include ../lib/class_memory.ahk
#include ../utils/client_config.ahk


StrToHex(hexStr) {
    return Format("0x{:X}", hexStr)
}

class Character {
    __clientMemory := null
    __memoryConfig := null
    
    __timerFn := null
    
    currentWeight := 0
	maxWeight := 0
	currentHp := 0
	currentSp := 0
	maxSp := 0
	currentLocation := ""
    
    __New(clientMemory, memoryConfig) {
        this.__clientMemory := clientMemory
        this.__memoryConfig := memoryConfig
    }

    Update() {
        this.currentWeight := this.__clientMemory.read(this.__memoryConfig.currentWeightAddress, "UInt")
        this.maxWeight := this.__clientMemory.read(this.__memoryConfig.maxWeightAddress, "UInt")
        this.currentHp := this.__clientMemory.read(this.__memoryConfig.currentHpAddress, "UInt")
        this.currentSp := this.__clientMemory.read(StrToHex(this.__memoryConfig.currentHpAddress)+8, "UInt")
        this.maxSp := this.__clientMemory.read(StrToHex(this.__memoryConfig.currentHpAddress)+12, "UInt")
        this.currentLocation := this.__clientMemory.readString(this.__memoryConfig.currentLocationAddress, 0, "utf-8")
    }
    
    StartBackgroundUpdate(interval := 100) {
        this.__timerFn := Func("Character.Update").Bind(this)
        fn := this.__timerFn
        SetTimer, % fn, %interval%
        Return
    }
    
    StopBackgroundUpdate() {
        fn := this.__timerFn
        SetTimer, % fn, Off
    }
}

class Client {
    __clientMemory := null
    __config := null
    __character := null
       
    __New(config) {
        this.__config := config
        this.__clientMemory := new _ClassMemory("ahk_exe " . config.exeName, "", hProcessCopy)
        this.__character := new Character(this.__clientMemory, config.memory.character)
        this.__character.StartBackgroundUpdate()
    }
    
    GetCharacter() {
        return this.__character
    }
}

;
; Usage
;

config := new ClientConfig("config/client.json").Get()
global client := new Client(config)
global character := client.GetCharacter()

End::
    Loop {
        MsgBox % character.currentSp
        Sleep, 1000
    }
    
    Return

F1::
    character.StartBackgroundUpdate()
    Return
  
F2::
    character.StopBackgroundUpdate()
    Return
    