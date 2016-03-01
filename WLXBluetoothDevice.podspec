#
#  Be sure to run `pod spec lint WLXBluetoothDevice.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "WLXBluetoothDevice"
  s.version      = "0.6.1"
  s.summary      = "A block-based wrapper of CoreBluetooth"

  s.description  = <<-DESC
                       WLXBluetoothDevice provides a better, more modular
                       API on top of CoreBluetooth. Reposabilities are separated
                       in different classes and the API is block-based.

                       WLXBluetoothDevice extracts common patterns that have been
                       identified while developing Bluetooth 4.0 apps at
                       [Wolox](http://www.wolox.com.ar).
                   DESC

  s.homepage     = "http://www.wolox.com.ar"
  s.license      = "MIT"
  s.author       = { "Wolox" => "contact@wolox.com.ar" }
  s.platform     = :ios, "5.0"
  s.source       = { :git => "https://github.com/Wolox/WLXBluetoothDevice.git", :tag => s.version }
  s.source_files  = "WLXBluetoothDevice", "WLXBluetoothDevice/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.subspec "CocoaLumberjack" do |ss|
      ss.dependency "CocoaLumberjack", "~> 2.2.0"
      ss.xcconfig = { "FRAMEWORK_SEARCH_PATHS" => "$(PODS_ROOT)/CocoaLumberjack"}
  end
end
