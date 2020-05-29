import Foundation
import Kingfisher
import SwiftyUserDefaults

class AdManager {
    
    static let manager = AdManager()
    private init() {}
    
    public func show() {
        self.getCacheAdImg { (image) in
            DispatchQueue.main.async {
                if (image != nil) && (self.checkCacheAdImg() == true) {
                    let adView = AdView()
                    adView.show()
                    adView.skipClosure = { () in
                    }
                    adView.endCountDownClosure = { () in
                    }
                    adView.tapClosure = { () in
                        if let naviVC = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController {
                            naviVC.pushViewController(AdH5VC(), animated: true)
                        }
                    }
                }
            }
        }
    }
    
    public func clear() {
        self.clearCacheAdImg()
        self.clearCacheAdUrl()
    }
}

// MARK: - advImg
extension AdManager {
    
    func checkCacheAdImg() -> Bool {
        let result = ImageCache.default.imageCachedType(forKey: "advImg").cached
        print("Check cache advImg - \(result)")
        return result
    }
    
    func getCacheAdImg(completion: @escaping ((UIImage?) -> Void)) {
        ImageCache.default.retrieveImageInDiskCache(forKey: "advImg") { (result) in
            switch result {
            case .success(let image):
                completion(image)
            case .failure(let error):
                completion(nil)
                print("Get cache advImg error - \(error)")
            }
        }
    }
    
    func storeCacheAdImg(_ advImg: String) {
        if let url = URL(string: advImg) {
            ImageDownloader.default.downloadImage(with: url, options: [.forceRefresh]) { (result) in
                switch result {
                case .success(let resource):
                    ImageCache.default.store(resource.image, forKey: "advImg")
                    print("Download and store advImg success")
                case .failure(let error):
                    print("Download advImg error - \(error)")
                }
            }
        }
    }
    
    func clearCacheAdImg() {
        ImageCache.default.removeImage(forKey: "advImg")
    }
}

// MARK: - adUrl
extension AdManager {
    
    func checkCacheAdUrl() -> Bool {
        let result = Defaults.hasKey(.AdvUrl)
        print("Cache advUrl - \(result)")
        return result
    }
    
    func getCacheAdUrl() -> URL? {
        if let advUrl = Defaults[.AdvUrl] {
            return URL(string: advUrl)
        }
        return nil
    }
    
    func storeCacheAdUrl(_ advUrl: String) {
        Defaults[.AdvUrl] = advUrl
    }
    
    func clearCacheAdUrl() {
        Defaults.remove(.AdvUrl)
    }
}
