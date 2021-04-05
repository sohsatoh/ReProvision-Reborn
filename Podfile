post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
         target.build_settings(configuration.name)['ARCHS'] = 'armv7 arm64 arm64e'
         target.build_settings(configuration.name)['VALID_ARCHS'] = 'armv7 arm64 arm64e' 
        end
      end
    end

target 'iOS' do
platform :ios, '9.0'
pod 'OpenSSL-Universal', '1.1.180'
pod 'MBCircularProgressBar', '0.3.5'
pod 'MarqueeLabel', '3.1.4'
pod 'TORoundedTableView', '0.1.3'
pod 'RMessage', '2.1.5'
pod 'CocoaLumberjack'
end

target 'macOS' do
platform :osx, '10.10'
pod 'OpenSSL-Universal', '1.1.180'
end

target 'tvOS' do
platform :tvos, '9.0'
pod 'MarqueeLabel', '3.1.4'
end
