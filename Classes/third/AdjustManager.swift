import Adjust

class AdjustManager {
    
    static let manager = AdjustManager()
    private init() {}
    
    public func setup() {
        guard kAdjToken.isEmpty == false else {
            return
        }
        let config = ADJConfig(appToken: kAdjToken, environment: ADJEnvironmentProduction)
        Adjust.appDidLaunch(config)
    }
}
