#
# Be sure to run `pod lib lint MagicPageBase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MagicPageBase'
  s.version          = '1.0'
  s.summary          = 'Amazing MagicPageBase.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  this is Amazing page. you unknowed what you see.
                       DESC

  s.homepage         = 'https://github.com/zhuyitian/MagicPageBase'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Talan' => '16657120403@163.com' }
  s.source           = { :git => 'https://github.com/zhuyitian/MagicPageBase.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'MagicPageBase/Classes/**/*'
  s.requires_arc = true
  
  # s.resource_bundles = {
  #   'MagicPageBase' => ['MagicPageBase/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'SafariServices', 'SystemConfiguration', 'LocalAuthentication', 'iAd', 'AdSupport'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Alamofire'
  s.dependency 'Moya/RxSwift'
  s.dependency 'Kingfisher'
  s.dependency 'WebViewJavascriptBridge'
  s.dependency 'SnapKit'
  s.dependency 'GTSDK'
  s.dependency 'GoogleSignIn'
  s.dependency 'FBSDKCoreKit'
  s.dependency 'FBSDKLoginKit'
  s.dependency 'FBSDKShareKit'
  s.dependency 'FBSDKPlacesKit'
  s.dependency 'Adjust'
  s.dependency 'Branch'
  s.dependency 'RxSwift'
  s.dependency 'SwifterSwift'
  s.dependency 'SwiftyJSON'
  
  
end
