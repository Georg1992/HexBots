#Include %A_LineFile%/../JSON.ahk

class ConfigLoader {
    __config := null
    
    __New(configPath) {
        FileRead, jsonStr, %configPath%
        this.__config := JSON.Load(jsonStr)
    }
    
    Get() {
        return this.__config
    }
}