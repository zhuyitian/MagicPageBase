import UIKit
import WebKit
import SwiftyUserDefaults
import SnapKit

class AdH5VC: UIViewController {
    
    private var isStatusBarDefault = true {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    private lazy var stateView: UIView = {
        let view = UIView.init()
        view.backgroundColor = UIColor(hexString: kStatusBarColor)
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
    private lazy var navigationBar: AdNavigationBar = {
        let view = AdNavigationBar(frame: .zero)
        view.backClosure = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return view
    }()
    
    deinit {
        debugPrint("deinit - \(type(of:self))")
        if self.webView.uiDelegate != nil {
            self.webView.scrollView.delegate = nil
            self.webView.uiDelegate = nil
            self.webView.navigationDelegate = nil
            self.webView.configuration.userContentController.removeAllUserScripts()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.loadURL(Defaults[.AdvUrl] ?? "")
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
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
}

// MARK: ———————————————————— Private Methods ————————————————————
private extension AdH5VC {
    
    func setupUI() {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.navigationBar.isHidden = true
        self.isStatusBarDefault = (kStatusBarLabelColor == "white") ? false : true
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.view.backgroundColor = .white
        self.view.addSubview(self.stateView)
        self.view.addSubview(self.webView)
        self.view.addSubview(self.navigationBar)
        self.stateView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(UIApplication.shared.statusBarFrame.height)
        }
        self.navigationBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.stateView.snp.bottom)
            make.height.equalTo(44)
        }
        self.webView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.navigationBar.snp.bottom)
        }
    }
    func loadURL(_ urlString: String) {
        if let url = URL.init(string: urlString) {
            let request = URLRequest.init(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            self.webView.load(request)
        }
    }
    func reload() {
        if Double(UIDevice.current.systemVersion) ?? 0 > 9.0 , Double(UIDevice.current.systemVersion) ?? 0 < 10.0 {
            self.loadURL(Defaults[.AdvUrl] ?? "")
        }else {
            self.webView.reload()
        }
    }
}

// MARK: ———————————————————— UIGestureRecognizerDelegate ————————————————————
extension AdH5VC: UIGestureRecognizerDelegate {
    
    @objc private func rightswipe(_ sender: UIButton) {
        self.webView.scrollView.scrollsToTop = false;
        self.webView.goBack()
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        self.reload()
        return true
    }
}

// MARK: ———————————————————— WKUIDelegate, WKNavigationDelegate ————————————————————
extension AdH5VC: WKUIDelegate, WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.title != "undefined" {
            self.title = webView.title
            self.navigationBar.title = webView.title
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "theme_h5_prompt".bt_localized, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "theme_h5_ok".bt_localized, style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "theme_h5_prompt".bt_localized, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "theme_h5_cancel".bt_localized, style: UIAlertAction.Style.cancel, handler: { (action) in
            completionHandler(false)
        }))
        alert.addAction(UIAlertAction(title: "theme_h5_ok".bt_localized, style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler(true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: prompt, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textField) in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "theme_h5_done".bt_localized, style: UIAlertAction.Style.default, handler: { (action) in
            completionHandler(alert.textFields?.first?.text)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
