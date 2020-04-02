# MagicPageBase

# 封装完成版H5需要额外配置的内容

> 个推暂时需额外自行添加。（待更新）

>  白名单添加

```swift
fbapi，fb-messenger-share-api，fbauth2，fbshareextension，paytm
```

> google登录部分：

* GoogleService-Info.plist文件放到工程目录下
* 配置URL scheme（REVERSED_CLIENT_ID）

> facebook分享部分：

* info.plist 文件里加上

```swift
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fb{your-app-id}</string>
    </array>
  </dict>
</array>
<key>FacebookAppID</key>
<string>{your-app-id}</string>
<key>FacebookDisplayName</key>
<string>{your-app-name}</string>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fb-messenger-share-api</string>
  <string>fbauth2</string>
  <string>fbshareextension</string>
</array>
```

> branch部分：

* 配置Associated Domains

* build phases 里 copy bundle resources 里加上 example.entitlements

* 配置Info.plist

  在Info.plist中添加如下的字段：

  branch_app_domain

  branch_key 

  URL Schemes

  此3个字段的值要与DashBoard中设置的内容一致

* appdelegate 类的方法里加上：

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { 
      
    Branch.getInstance().initSession(launchOptions: launchOptions) { (param, error) in
        }
      
      return true
  }
```

> 个推部分

需要在桥接文件里导入头文件

```swift
#import <GTSDK/GeTuiSdk.h>
```

> paytm部分

URL Schemes 填写 "paytm"+"mid"(mid是dokypay 在paytm的唯一商户 id)

> 综合部分

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
        ApplicationDelegate.shared.application(app, open: url, options: options)
        GIDSignIn.sharedInstance()?.handle(url)
        return true
    }

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { 
      
    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    Branch.getInstance().initSession(launchOptions: launchOptions) { (param, error) in
        }     
      return true
  }
```
