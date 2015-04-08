#
# Be sure to run `pod lib lint WLXBluetoothDevice.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "WLXBluetoothDevice"
  s.version          = "0.2.0-alpha4"
  s.summary          = "A block-based wrapper of CoreBluetooth"
  s.description      = <<-DESC
                       WLXBluetoothDevice provides a better, more modular
                       API on top of CoreBluetooth. Reposabilities are separated
                       in different classes and the API is block-based.

                       WLXBluetoothDevice extracts common patterns that have been
                       identified while developing Bluetooth 4.0 apps at
                       [Wolox](http://www.wolox.com.ar).
                       DESC
  s.homepage         = "https://github.com/Wolox/WLXBluetoothDevice"
  s.license          = 'MIT'
  s.author           = { "Guido Marucci Blas" => "guidomb@wolox.com.ar" }
  s.source           = { :git => "https://github.com/Wolox/WLXBluetoothDevice.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.subspec 'Core' do |cs|
    cs.source_files = 'Pod/Classes/Core'
    cs.resource_bundles = {
      'WLXBluetoothDevice' => ['Pod/Assets/*.png']
    }

    cs.frameworks = 'CoreBluetooth'
    cs.dependency 'CocoaLumberjack', '~>2.0.0-rc'
  end

  s.subspec 'ReactiveCocoa' do |cs|
    cs.source_files = 'Pod/Classes/ReactiveCocoa'
    cs.dependency 'WLXBluetoothDevice/Core'
    cs.dependency 'ReactiveCocoa', '2.4.4'
  end

end
