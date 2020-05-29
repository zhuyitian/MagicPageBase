import UIKit
import SnapKit

class AdNavigationBar: UIView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(hexString: "#333333")!
        return label
    }()
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "global_back_icon"), for: .normal)
        button.addTarget(self, action: #selector(self.backAction), for: .touchUpInside)
        return button
    }()
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#EEEEEE")!
        return view
    }()
    
    var backClosure: (() -> Void)?
    var title: String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createWidget()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createWidget() {
        self.backgroundColor = .white
        self.addSubview(self.titleLabel)
        self.addSubview(self.backButton)
        self.addSubview(self.lineView)
        self.backButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15.bt_scale)
            make.bottom.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        self.titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(self.backButton.snp.centerY)
        }
        self.lineView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    @objc private func backAction() {
        self.backClosure?()
    }
}
