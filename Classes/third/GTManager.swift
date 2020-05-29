import Foundation
import UserNotifications

let noti_jumpUrl = NSNotification.Name.init("jumpUrl")

class GTManager: NSObject {
    
    static let manager = GTManager()
    private override init() {}
    
    public func setup() {
        self.setupGT()
        self.registerForRemoteNotifications()
    }

    private func setupGT() {
        GeTuiSdk.setChannelId("GT-Channel");
        GeTuiSdk.start(withAppId: kGtId, appKey: kGtKey, appSecret: kGtSecret, delegate: self)
    }
    
    private func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {result, error in
            print("requestAuthorization - \(result)")
            if error != nil {
                print("requestAuthorization error - \(error.debugDescription)")
            }
        })
        UIApplication.shared.registerForRemoteNotifications()
    }
}

extension GTManager: GeTuiSdkDelegate {
    
    func geTuiSdkDidRegisterClient(_ clientId: String!) {
        print("SDK login success and return clientId - \(clientId ?? "null")")
    }
    
    func geTuiSdkDidReceivePayloadData(_ payloadData: Data!, andTaskId taskId: String!, andMsgId msgId: String!, andOffLine offLine: Bool, fromGtAppId appId: String!) {
        GeTuiSdk.sendFeedbackMessage(90001, andTaskId: taskId, andMsgId: msgId)
        let payloadMsg = String(data: payloadData, encoding: String.Encoding.utf8)
        print("SDK received push-through messages - payloadMsg:\(payloadMsg ?? ""), taskId:\(taskId ?? ""), messageId:\(msgId ?? ""), offLine:\(offLine)")
        guard offLine == false else {
            print("SDK receive offline passthrough message")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: payloadData, options: JSONSerialization.ReadingOptions.allowFragments)
            if let dic = json as? [String: Any] {
                self.addLocationNotification(dic, msgId)
            }
        } catch  {
            print("SDK receive push-through passthrough message, but JSONSerialization fail")
        }
    }
}

private extension GTManager {
    
    func addLocationNotification(_ userInfo: Dictionary<String, Any>, _ messageId: String) {
        print(userInfo)
        let content = UNMutableNotificationContent()
        content.body = (userInfo["pushContent"] as? String) ?? ""
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 0)
        content.userInfo = userInfo
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: messageId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            print("localNotification error -  \(error.debugDescription)")
        }
    }

    func jumpVC(userInfo: Dictionary<String, Any>?) {
        guard userInfo != nil else { return }
        guard userInfo?.count != 0 else { return }
        if let url = userInfo!["url"] as? String {
            if url.contains("http") {
                NotificationCenter.default.post(name: noti_jumpUrl, object: url)
            }
        }
    }
}

extension GTManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge,.sound,.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo as? Dictionary<String, Any>
        GTManager.manager.jumpVC(userInfo: userInfo)
        GeTuiSdk.handleRemoteNotification(response.notification.request.content.userInfo);
        completionHandler();
    }
}

extension AppDelegate {

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        GeTuiSdk.registerDeviceTokenData(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("register deviceToken fail - \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        GeTuiSdk.handleRemoteNotification(userInfo)
        if UIApplication.shared.applicationState == .inactive {
            GTManager.manager.jumpVC(userInfo:userInfo as? Dictionary<String, Any>)
        }
        completionHandler(.newData)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        application.applicationIconBadgeNumber = 0
        if UIApplication.shared.applicationState != .active {
            GTManager.manager.jumpVC(userInfo:userInfo as? Dictionary<String, Any>)
        }
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        GeTuiSdk.resume()
        completionHandler(.newData)
    }
}

extension GTManager {
    
    func gt_applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        GeTuiSdk.setBadge(0)
    }
}
