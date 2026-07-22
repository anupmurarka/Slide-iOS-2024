# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'
inhibit_all_warnings!
target 'Slide for Reddit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Slide for Reddit

  # reddift (+ its HTMLSpecialCharacters & MiniKeychain deps) migrated to a
  # local Swift Package at LocalPackages/Reddift (see MIGRATION.md, Phase 2).
  pod 'MKColorPicker', :git => 'https://github.com/ccrama/MKColorPicker'
  # LicensesViewController vendored to LocalPackages/VendoredUI (Phase 3).
  pod 'OpalImagePicker'
  pod 'MaterialComponents/ActivityIndicator'
  pod 'MaterialComponents/ProgressView'
  # SwiftEntryKit migrated to upstream huri000/SwiftEntryKit 2.x via SPM (Phase 3).
  pod 'SDCAlertView', '~> 12.0'
  # SwiftLinkPreview migrated to official LeonardoCardoso/SwiftLinkPreview via SPM (Phase 3).
  # DTCoreText migrated to Cocoanetics/DTCoreText via SPM (Phase 3).
  pod 'RLBAlertsPickers', :git => 'https://github.com/ccrama/Alerts-Pickers'
  pod 'Alamofire', '~> 4.3'
  # SwiftyJSON migrated to the official SwiftyJSON via SPM (see MIGRATION.md, Phase 3).
  pod "YoutubePlayer-in-WKWebView", "~> 0.3.0"
  # SubtleVolume, TGPControls and MTColorDistance (Swift port) migrated to the
  # local Swift Package at LocalPackages/VendoredUI (see MIGRATION.md, Phase 2).

  target 'Slide for RedditTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Slide for RedditUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
    	target.build_configurations.each do |config|
     	 config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    	end
        if [
          'HTMLSpecialCharacters',
          'MiniKeychain',
          'RLBAlertsPickers',
          'SwiftLinkPreview'
        ].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
    end
  end

end

pod 'SwiftLint'
