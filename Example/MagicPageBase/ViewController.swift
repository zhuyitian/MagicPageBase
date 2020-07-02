//
//  ViewController.swift
//  MagicPageBase
//
//  Created by 359079097@qq.com on 03/30/2020.
//  Copyright (c) 2020 359079097@qq.com. All rights reserved.
//

import UIKit
import MagicPageBase
import AdSupport
import Alamofire


public struct LuckyMallKeys {
    
    static let host = "h5Url"
    static let isVest = "status"
    static let gtid = "gtId"
    static let gtkey = "gtKey"
    static let gtsecret = "gtSecert"
    static let adjust = "adjustToken"
}

class ViewController: UIViewController {
    
    var serviceStr : String = "https://d2d0drb98uxrz0.cloudfront.net"
    let lemon_interface = "/admin/client/vestSign.do"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func getHost() {
        let device = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let infoDictionary = Bundle.main.infoDictionary!
        let ver = infoDictionary["CFBundleShortVersionString"] as? String ?? "1.0.4"
        let timestamp = Date.init().timeIntervalSince1970
        let requestDic = [
            "vestCode" : "P8RDBU4X",
            "channelCode" : "iOS",
            "version" : ver,
            "deviceId" : device,
            "timestamp": timestamp
            ] as [String : Any]
        let lemonUrl = String.init(format: "%@%@", serviceStr,lemon_interface)
        AF.request(lemonUrl, method: .get, parameters: requestDic, encoding: URLEncoding.default, headers: nil).responseJSON {[weak self] (response) in
            if response.error == nil {
                if let reslut = response.value as? [String: Any] {
                    if let data = reslut["data"] as? [String : Any]  {
                        UIApplication.shared.keyWindow?.rootViewController = BaseTabVC.init(data: data, GTClientID: "")
                    }
                }
            } else {
                self?.view.addSubview(LuckyMallEmptyView())
            }
        }
    }

}

class LuckyMallEmptyView: UIView {
    
    var retry:(()->Void)?
    
    
    lazy var tipLabel: UILabel = {
        let label = UILabel.init()
        label.text = "暂无网络\n如网络良好，请检查设置，是否允许网络访问！"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    lazy var btn: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.backgroundColor = UIColor.init(red: 74/255, green: 153/255, blue: 207/255, alpha: 1)
        btn.layer.cornerRadius = 4
        btn.clipsToBounds = true
        btn.setTitle("重试", for: .normal)
        btn.addTarget(self, action: #selector(clickAction), for: .touchUpInside)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        creatUI()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func creatUI() {
        backgroundColor = .white
        addSubview(tipLabel)
        addSubview(btn)
        
        tipLabel.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
        
        btn.snp.makeConstraints { (make) in
            make.top.equalTo(tipLabel.snp.bottom).offset(15)
            make.width.equalTo(200)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
    }
    
    @objc func clickAction() {
        retry?()
    }
    
    
}
