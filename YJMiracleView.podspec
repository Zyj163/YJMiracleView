#
# Be sure to run `pod lib lint YJMiracleView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YJMiracleView'
  s.version          = '0.3.0'
  s.summary          = 'YJMiracleView.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
YJMiracleView无法描述，miracle.
                       DESC

  s.homepage         = 'https://github.com/Zyj163/YJMiracleView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Zyj163' => 'zyj194250@163.com' }
  s.source           = { :git => 'https://github.com/Zyj163/YJMiracleView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.swift_version = '5.0'
  s.source_files = 'YJMiracleView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'YJMiracleView' => ['YJMiracleView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
