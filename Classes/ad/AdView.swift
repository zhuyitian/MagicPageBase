import UIKit

class AdView: UIView {

    private var timer: DispatchSourceTimer?
    private var waitTime: Int = 5
    var tapClosure: (() -> Void)?
    var skipClosure: (() -> Void)?
    var endCountDownClosure: (() -> Void)?
    
    private lazy var adImageView: UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        AdManager.manager.getCacheAdImg(completion: { (image) in
            DispatchQueue.main.async {
                imageView.image = image
            }
        })
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.tapAction))
        imageView.addGestureRecognizer(tapGR)
        return imageView
    }()
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: UIScreen.bt_screenWidth-70, y: UIScreen.bt_statusBarHeight+20, width: 60, height: 30)
        button.setTitle("\(self.waitTime) \("theme_ad_skip".bt_localized)", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13.bt_scale)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.backgroundColor = UIColor(white: 0, alpha: 0.3)
        button.addTarget(self, action: #selector(self.skipAction), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        self.createWidget()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit - \(type(of:self))")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.setupsTimer()
    }
}

extension AdView {
    
    func show() {
        UIApplication.shared.delegate?.window??.addSubview(self)
    }
    func remove() {
        if self.timer?.isCancelled == false { self.timer?.cancel() }
        self.removeFromSuperview()
    }
}

private extension AdView {
    
    func createWidget() {
        self.backgroundColor = .white
        self.addSubview(self.adImageView)
        self.addSubview(self.skipButton)
    }
    func setupsTimer() {
        var duration: Int = waitTime
        self.timer = DispatchSource.makeTimerSource(flags: [], queue: .global())
        self.timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(duration))
        self.timer?.setEventHandler {
            if duration == 0 {
                DispatchQueue.main.async {
                    self.remove()
                    self.endCountDownClosure?()
                }
            }
            duration -= 1
            DispatchQueue.main.async {
                self.skipButton.setTitle("\(duration) \("theme_ad_skip".bt_localized)", for: .normal)
            }
        }
        self.timer?.resume()
    }
    @objc func skipAction() {
        self.remove()
        self.skipClosure?()
    }
    @objc func tapAction() {
        let adManager = AdManager.manager
        if adManager.checkCacheAdUrl() == true, adManager.getCacheAdUrl() != nil {
            self.remove()
            self.tapClosure?()
        }
    }
}
