import Foundation

class UMManager {
    
    static let manager = UMManager()
    private init() {}
    
    func setup() {
        UMConfigure.initWithAppkey(kUmKey, channel: "App Store")
        UMConfigure.setLogEnabled(false)
        MobClick.setScenarioType(eScenarioType.E_UM_NORMAL)
        MobClick.setCrashReportEnabled(true)
    }
}
