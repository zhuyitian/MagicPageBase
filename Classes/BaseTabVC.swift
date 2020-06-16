import UIKit
import WebKit
import Alamofire
import AdSupport
import Adjust
import FBSDKShareKit
import FBSDKLoginKit
import GoogleSignIn
import WKSimpleBridge
import RxSwift
import RxCocoa
import FirebaseAnalytics

public class BaseTabVC: UIViewController {

    let noti_jumpUrl = NSNotification.Name.init("jumpUrl")

    private let bag = DisposeBag()
    // Progress Flag
    private let kEstimatedProgress = "estimatedProgress"
    private var isStatusBarDefault = true {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    // Google, Facebook SignIn
    private var sign = ""
    private var host = ""
    // Facebook Share
    var inviteCode = ""
    var domainUrl = ""
    // 个推clientid
    var gtClientId = ""
    
    var isFirstOpen = true
    let sysVersion = UIDevice.current.systemVersion
    // Widget
    private lazy var bridge: WKWebViewJavascriptBridge? = {
        let bridge = WKWebViewJavascriptBridge(for: self.webView)
        bridge?.setWebViewDelegate(self)
        return bridge
    }()
    private lazy var stateView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: kStatusBarColor)
        return view
    }()
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: UIProgressView.Style.default)
        view.progressTintColor = .yellow
        return view
    }()
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .white
        webView.allowsLinkPreview = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView
    }()
    private let tempWebView = WKWebView()
    
    deinit {
        debugPrint("deinit - \(type(of:self))")
        if self.webView.uiDelegate != nil {
            self.webView.scrollView.delegate = nil
            self.webView.uiDelegate = nil
            self.webView.navigationDelegate = nil
            self.webView.configuration.userContentController.removeAllUserScripts()
            self.webView.removeObserver(self, forKeyPath: kEstimatedProgress)
        }
    }
    public init(data: [String: Any], GTClientID: String) {
        gtClientId = GTClientID
        super.init(nibName: nil, bundle: nil)
        setupConfig(data: data)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupSubscribe()
        self.setupUserAgent()
        self.setupGoogleSignInInit()
        self.setupFacebookSignInNotificationSubscribe()
        self.setupRegisterHandler()
    }
    
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if self.isStatusBarDefault == true {
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        } else {
            return .lightContent
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == kEstimatedProgress {
            if let obj = object as? WKWebView, obj == self.webView {
                self.progressView.alpha = 1
                self.progressView.setProgress(Float(self.webView.estimatedProgress), animated: true)
                if self.webView.estimatedProgress >= 1.0 {
                    UIView.animate(withDuration: 0.3, delay: 0.3, options: UIView.AnimationOptions.curveEaseOut, animations: { [weak self] () in
                        self?.progressView.alpha = 0
                        }, completion: {[weak self] (finish) in
                            self?.progressView.setProgress(0, animated: true)
                    })
                }
            }
        }
    }
}

// MARK: ———————————————————— Private Methods ————————————————————
private extension BaseTabVC {
    
    private func setupConfig(data: [String: Any]) {
        if let gtId = data["gtId"] as? String {
            kGtId = gtId
        }
        if let gtKey = data["gtKey"] as? String {
            kGtKey = gtKey
        }
        if let gtSecert = data["gtSecert"] as? String {
            kGtSecret = gtSecert
        }
        if let h5Url = data["h5Url"] as? String {
            kUrl = h5Url
        }
        if let um = data["umKey"] as? String {
            kUmKey = um
        }
        if let backgroundCol = data["backgroundCol"] as? String {
            kStatusBarColor = backgroundCol
        }
        if let fieldCol = data["fieldCol"] as? String {
            kStatusBarLabelColor = fieldCol
        }
        if let adjustToken = data["adjustToken"] as? String {
            kAdjToken = adjustToken
        }
        AdjustManager.manager.setup()
        
        if let advOn = data["advOn"] as? Int {
            let adManager = AdManager.manager
            if advOn == 1 {
                if let advImg = data["advImg"] as? String, advImg.count != 0 {
                    adManager.storeCacheAdImg(advImg)
                } else {
                    adManager.clearCacheAdImg()
                }
                if let advUrl = data["advUrl"] as? String, advUrl.count != 0 {
                    adManager.storeCacheAdUrl(advUrl)
                } else {
                    adManager.clearCacheAdUrl()
                }
            } else {
                adManager.clear()
            }
        }
        AdManager.manager.show()
    }
    
    func setupUI() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.navigationBar.isHidden = true
        self.isStatusBarDefault = (kStatusBarLabelColor == "white") ? false : true
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.view.backgroundColor = .white
        self.view.addSubview(self.stateView)
        self.view.addSubview(self.progressView)
        self.view.addSubview(self.webView)
        self.stateView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(UIApplication.shared.statusBarFrame.height)
        }
        self.progressView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(2)
        }
        self.webView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.stateView.snp.bottom)
        }
    }
    func setupSubscribe() {
        // Notification Jump
        NotificationCenter.default.rx.notification(noti_jumpUrl).subscribe { [weak self] (event) in
            switch event {
            case .next(let notification):
                if let jumpUrl = notification.object as? String {
                    self?.loadURL(jumpUrl)
                }
            case .error(let error):
                print("error - \(error)")
            case .completed:
                print("completed")
            }
        }.disposed(by: self.bag)
        // UIApplication.didBecomeActiveNotification
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).subscribe { [weak self] (event) in
            self?.webView.evaluateJavaScript("webViewCallUp()", completionHandler: { (result, error) in
                if error != nil {
                    print(error!)
                }
            })
        }.disposed(by: self.bag)
        // Progress
        self.webView.addObserver(self, forKeyPath: kEstimatedProgress, options: NSKeyValueObservingOptions.new, context: nil)
    }
    func setupUserAgent() {
        self.tempWebView.evaluateJavaScript("navigator.userAgent") { [weak self] (res, err) in
            var uaStr = res as? String
            guard uaStr != nil else { return }
            uaStr = "IOS_AGENT/2.0\(uaStr ?? "")"
            UserDefaults.standard.register(defaults: ["UserAgent" : uaStr ?? "IOS_AGENT/2.0"])
            UserDefaults.standard.synchronize()
            self?.webView.customUserAgent = uaStr
            self?.loadURL(kUrl)
        }
    }
    func loadURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            self.webView.load(request)
        }
    }
    func reload() {
        if Double(UIDevice.current.systemVersion) ?? 0 > 9.0 , Double(UIDevice.current.systemVersion) ?? 0 < 10.0 {
            self.loadURL(kUrl)
        }else {
            self.webView.reload()
        }
    }
}

// MARK: ———————————————————— SignIn With Our Server ————————————————————
private extension BaseTabVC {

    // type: 1 - Google, 0 - Facebook
    func signInToOurServer(_ dic: [String: Any]) {
        AF.request("\(self.host)/user/google/doLogin2.do", method: .get, parameters: dic, encoding: URLEncoding.default, headers: nil).responseJSON {[weak self] (response) in
            if response.error == nil {
                if let reslut = response.value as? [String: Any] {
                    if let data = reslut["data"] as? [String: Any] {
                        if let url = data["url"] as? String {
                            let token1 = "\(data["token1"] ?? "")"
                            let token2 = "\(data["token2"] ?? "")"
                            if !token1.isEmpty, !token2.isEmpty {
                                let dic = [
                                    "token1": token1,
                                    "token2": token2
                                ]
                                UserDefaults.standard.set(dic, forKey: "WKWebViewKCookieKey")
                                UserDefaults.standard.synchronize()
                            }
                            self?.loadURL(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
                        }
                    }
                }
            }
        }
    }
}

// MARK: ———————————————————— Share With Our Server ————————————————————
private extension BaseTabVC {
    
    func shareSuccess(type: String) {
        let dic = [
            "inviteCode": self.inviteCode,
            "type": type
        ]
        AF.request("\(self.domainUrl)/user/userTask/dailyFaceAndWhats.do", method: .get, parameters: dic, encoding: URLEncoding.default, headers: nil).responseJSON {[weak self] (response) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self?.webView.reload()
            }
        }
    }
}

// MARK: ———————————————————— Whatsapp Customer Service & Share ————————————————————
extension BaseTabVC {
    
    // Customer Service
    private func registerWhatsappChatCustomerService() {
        self.bridge?.registerHandler("openURL", handler: { (data, responseCallback) in
            if let content = data as? String {
                let url = URL(string: "\(content)")
                if UIApplication.shared.canOpenURL(url!) {
                    UIApplication.shared.open(url!, options: [:]) { (finish) in }
                } else {
                    responseCallback?("You haven't installed this app yet.")
                }
            }
        })
    }
    // Share
    private func registerWhatsappChatShare() {
        self.bridge?.registerHandler("shareWhatsapp", handler: { [weak self] (data, responseCallback) in
            if let dic = data as? [String : String] {
                let content = dic["content"] ?? ""
                self?.inviteCode = dic["inviteCode"] ?? ""
                self?.domainUrl = dic["domainUrl"] ?? ""
                let bodyurl = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let hosturl = URL.init(string: "whatsapp://send?text=\(bodyurl!)")
                if UIApplication.shared.canOpenURL(hosturl!) {
                    self?.shareSuccess(type: "2")
                    UIApplication.shared.open(hosturl!, options: [:]) { (finish) in }
                } else {
                    responseCallback?("You haven't installed this app yet.")
                }
            }
        })
    }
}

// MARK: ———————————————————— Facebook Share ————————————————————
extension BaseTabVC: SharingDelegate {
    
    private func registerFacebookShare() {
        self.bridge?.registerHandler("shareFacebook", handler: {[weak self] (data, responseCallback) in
            if let dic = data as? [String: String] {
                self?.shareFacebookAction(dic)
            }
        })
    }
    private func shareFacebookAction(_ data: [String : String]) {
        let url = data["url"] ?? ""
        let content = data["content"] ?? ""
        self.inviteCode = data["inviteCode"] ?? ""
        self.domainUrl = data["domainUrl"] ?? ""
        self.shareLinkToFacebook(url: url, quote: content)
    }
    private func shareLinkToFacebook(url: String!, quote: String?) {
        let content = ShareLinkContent()
        if url.starts(with: "http") {
            content.contentURL = URL(string: url) ?? URL(fileURLWithPath: "")
        }
        content.quote = quote
        let dialog = ShareDialog(fromViewController: self, content: content, delegate: self)
        dialog.show()
    }
    public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        self.shareSuccess(type: "1")
    }
    public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        print("Facebook share did fail, error - \(error)")
    }
    public func sharerDidCancel(_ sharer: Sharing) {
        print("Facebook share did cancel")
    }
}

// MARK: ———————————————————— Facebook SignIn ————————————————————
extension BaseTabVC {
    
    private func registerFacebookSignIn() {
        self.bridge?.registerHandler("loginFacebook", handler: { (data, responseCallback) in
            if let dic: [String : String] = data as? [String : String] {
                self.sign = "\(dic["sign"] ?? "")"
                self.host = "\(dic["host"] ?? "")"
                
                Profile.enableUpdatesOnAccessTokenChange(true)
                AccessToken.current = nil
                let manager = LoginManager()
                manager.logOut()
                manager.logIn(permissions: ["public_profile"], from: self) { (result, error) in
                    if error != nil {
                        print("Facebook sign in process error")
                    } else if result?.isCancelled ?? false {
                        print("Facebook sign in cancelled")
                    } else {
                        print("Facebook sign in success")
                    }
                }
            }
        })
    }
    private func setupFacebookSignInNotificationSubscribe() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.ProfileDidChange, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            if Profile.current != nil {
                Profile.loadCurrentProfile { (profile, error) in
                    let accessToken =  AccessToken.current?.tokenString ?? ""
                    let sign = self?.sign ?? ""
                    let name = profile?.firstName ?? ""
                    let dic = [
                        "id": accessToken,
                        "name": name,
                        "sign": sign,
                        "type": "0"
                    ]
                    self?.signInToOurServer(dic)
                }
            } else {
                print("Profile.current == nil")
            }
        }
    }
}

// MARK: ———————————————————— Google SignIn ————————————————————
extension BaseTabVC: GIDSignInDelegate {
    
    private func setupGoogleSignInInit() {
        GIDSignIn.sharedInstance()?.clientID = GID_clientID
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    private func registerGoogleSignIn() {
        self.bridge?.registerHandler("openGoogle", handler: { [weak self] (data, responseCallback) in
            if let dic: [String : String] = data as? [String : String] {
                self?.sign = "\(dic["sign"] ?? "")"
                self?.host = "\(dic["host"] ?? "")"
                GIDSignIn.sharedInstance()?.signIn()
            }
        })
    }
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let dic = [
                "id": user.userID ?? "",
                "name": user.profile.name ?? "",
                "sign": "\(self.sign)",
                "type": "1"
                ] as [String : String]
            self.signInToOurServer(dic)
        } else {
            print("Google sign in error - \(error.localizedDescription)")
        }
    }
}

// MARK: ———————————————————— Paytm ————————————————————
private extension BaseTabVC {
 
    private func registerPaytm() {
        self.bridge?.registerHandler("jumpPay", handler: { [weak self] (data, responseCallback) in
            if let dic = data as? [String : String] {
                self?.tokenFetched(textToken: dic["textToken"] ?? "", orderId: dic["orderId"] ?? "", mid: dic["mid"] ?? "", amount: dic["amount"] ?? "")
            }
        })
    }
    func tokenFetched(textToken: String, orderId: String, mid: String, amount: String) {
        if let payUrl = URL(string: "paytm://merchantpayment?txnToken=\(textToken)&orderId=\(orderId)&mid=\(mid)&amount=\(amount)") {
            if UIApplication.shared.canOpenURL(payUrl) {
                UIApplication.shared.open(payUrl, options: [:]) { (finish) in }
            } else {
                let dic = [UIApplication.OpenExternalURLOptionsKey(rawValue: "txnToken"): textToken,
                           UIApplication.OpenExternalURLOptionsKey(rawValue: "ORDER_ID"): orderId,
                           UIApplication.OpenExternalURLOptionsKey(rawValue: "MID"): mid]
                UIApplication.shared.open(URL(string: "https://securegw.paytm.in/theia/api/v1/showPaymentPage?mid=\(mid)&orderId=\(orderId)&txnToken=\(textToken)")!, options: dic) { (finish) in }
            }
        }
    }
}

// MARK: ———————————————————— WebViewJavascriptBridge ————————————————————
private extension BaseTabVC {
    
    func setupRegisterHandler() {
        self.registerGetCookie()
        self.registerSaveCookie()
        self.registerPushId()
        self.registerUMStatistical()
        self.registerStateStyle()
        self.registerIsHiddenNavi()
        self.registerOpenUrl()
        self.registerGetIDFA()
        self.registerGetIDFV()
        // Whatsapp
        self.registerWhatsappChatCustomerService()
        self.registerWhatsappChatShare()
        // Google
        self.registerGoogleSignIn()
        // Adjust
        self.registerAdjustEvent()
        // Firebase
        self.registerFirebaseEvent()
        // Facebook
        self.registerFacebookShare()
        self.registerFacebookSignIn()
        // Paytm
        self.registerPaytm()
        self.registerIsContainsName()
    }
    func registerGetCookie() {
        self.bridge?.registerHandler("getCookie", handler: { (data, responseCallback) in
            let cookie = UserDefaults.standard.value(forKey: "WKWebViewKCookieKey")
            responseCallback?(cookie)
        })
    }
    func registerSaveCookie() {
        self.bridge?.registerHandler("saveCookie", handler: { (data, responseCallback) in
            if let cookie = data {
                UserDefaults.standard.set(cookie, forKey: "WKWebViewKCookieKey")
                UserDefaults.standard.synchronize()
            }
        })
    }
    func registerPushId() {
        self.bridge?.registerHandler("getPushId", handler: {[weak self] (data, responseCallback) in
            responseCallback?(self?.gtClientId)
        })
    }
    func registerUMStatistical() {
        self.bridge?.registerHandler("umConfig", handler: { (data, responseCallback) in
            if let event = data as? String {
                
                responseCallback?(event)
            }
        })
    }
    func registerStateStyle() {
        self.bridge?.registerHandler("setStateColor", handler: {[weak self] (data, responseCallback) in
            if let color = data as? String {
                if color == "black" {
                    self?.isStatusBarDefault = true
                } else if color == "white" {
                    self?.isStatusBarDefault = false
                }
            }
        })
    }
    func registerIsHiddenNavi() {
        self.bridge?.registerHandler("isHiddenNavi", handler: { (data, responseCallback) in
        })
    }
    func registerOpenUrl() {
        self.bridge?.registerHandler("openUrl", handler: { (data, responseCallback) in
            if let urlString = data as? String {
                if let url = URL(string: urlString) {
                    if UIApplication.shared.canOpenURL(url) == true {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: { (result) in })
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    } else {
                    }
                }
            }
        })
    }
    // IDFA
    func registerGetIDFA() {
        self.bridge?.registerHandler("getIDFA", handler: { (data, responseCallback) in
            let IDFA = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            responseCallback?(IDFA)
        })
    }
    // IDFV
    func registerGetIDFV() {
        self.bridge?.registerHandler("getIDFV", handler: { (data, responseCallback) in
            let idfv = UIDevice.current.identifierForVendor?.uuidString
            responseCallback?(idfv)
        })
    }
    // Adjust
    func registerAdjustEvent() {
        self.bridge?.registerHandler("adjustTrackEvent", handler: { (data, responseCallback) in
            if let token = data as? String {
                let event = ADJEvent(eventToken: token)
                Adjust.trackEvent(event)
            }
        })
    }
    // Firebase
    func registerFirebaseEvent() {
        self.bridge?.registerHandler("firebaseTrackEvent", handler: { (data, responseCallback) in
            if let event = data as? String {
                Analytics.logEvent(event, parameters: nil)
            }
        })
    }
    func registerIsContainsName() {
        self.bridge?.registerHandler("isContainsName", handler: { [weak self] (data, responseCallback) in
            if let name = data as? String {
                responseCallback?(self?.bridge?.isContainsHandler(name))
            }
        })
    }
}

// MARK: ———————————————————— UIGestureRecognizerDelegate ————————————————————
extension BaseTabVC: UIGestureRecognizerDelegate {
    
    @objc private func rightswipe(_ sender: UIButton) {
        self.webView.scrollView.scrollsToTop = false;
        self.webView.goBack()
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        self.reload()
        return true
    }
}

// MARK: ———————————————————— WKUIDelegate, WKNavigationDelegate ————————————————————
extension BaseTabVC: WKUIDelegate, WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.title != "undefined" {
            self.title = webView.title
        }
        if isFirstOpen && sysVersion.starts(with: "12.") {
            isFirstOpen = false
            webView.reload()
        }
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let openurl = navigationAction.request.url {
            print(openurl)
            if "\(openurl)".contains("https://itunes.apple.com") {
                UIApplication.shared.open(openurl, options: [:]) { (result) in }
            } else if !"\(openurl)".hasPrefix("http") {
                UIApplication.shared.open(openurl, options: [:]) { (result) in }
            }
        }
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Prompt", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Prompt", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) in
            completionHandler(false)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler(true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: prompt, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textField) in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "done", style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler(alert.textFields?.first?.text)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
