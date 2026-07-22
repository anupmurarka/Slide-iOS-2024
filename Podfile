# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'
inhibit_all_warnings!
target 'Slide for Reddit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Slide for Reddit

  # reddift (+ its HTMLSpecialCharacters & MiniKeychain deps) migrated to a
  # local Swift Package at LocalPackages/Reddift (see MIGRATION.md, Phase 2).
  # MKColorPicker (embedded swatch grid, no native equivalent) vendored to
  # LocalPackages/VendoredUI (see MIGRATION.md, Phase 4).
  # LicensesViewController vendored to LocalPackages/VendoredUI (Phase 3).
  pod 'OpalImagePicker'
  # MaterialComponents (archived by Google) replaced by a native UIKit
  # MDCActivityIndicator shim at Slide for Reddit/Compat (see MIGRATION.md, Phase 4).
  # SwiftEntryKit migrated to upstream huri000/SwiftEntryKit 2.x via SPM (Phase 3).
  # SDCAlertView migrated to sberrevoets/SDCAlertView via SPM (Phase 3).
  # SwiftLinkPreview migrated to official LeonardoCardoso/SwiftLinkPreview via SPM (Phase 3).
  # DTCoreText migrated to Cocoanetics/DTCoreText via SPM (Phase 3).
  pod 'RLBAlertsPickers', :git => 'https://github.com/ccrama/Alerts-Pickers'
  # Alamofire migrated to 5.x via SPM (see MIGRATION.md, Phase 3).
  # SwiftyJSON migrated to the official SwiftyJSON via SPM (see MIGRATION.md, Phase 3).
  # YoutubePlayer-in-WKWebView (ObjC, unmaintained) vendored into the app target
  # (WKYTPlayerView.h/.m + HTML asset) via the bridging header (MIGRATION.md, Phase 4).
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
