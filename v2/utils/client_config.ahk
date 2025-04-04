#Include ../lib/JSON.ahk

class ClientConfig {
    __config := null
    
    __New(configPath) {
        FileRead, jsonStr, %configPath%
        this.__config := JSON.Load(jsonStr)
    }
    
    Get() {
        return this.__config
    }
}