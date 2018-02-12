#
# Be sure to run `pod lib lint RFDuino.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RFDuino"
  s.version          = "0.2.1"
  s.summary          = "The RFDuino library allows you to easily communicate with RFDuino's, but also other devices, over Bluetooth."

  s.description      = "This library allows you to easily get started with communicating between an iOS device and Bluetooth Smart devices like RFDuinos. More info will be added soon."


  s.homepage         = "https://github.com/Kukiwon/rfduino-swift"
  s.license          = 'MIT'
  s.author           = { "Jordy van Kuijk" => "jordy@kineticvision.nl" }
  s.source           = { :git => "https://github.com/Kukiwon/rfduino-swift.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'RFDuino' => ['Pod/Assets/*.png']
  }
end
