platform :ios, '14.5'

target 'OCR-Comparison' do
  use_frameworks!

  pod 'GoogleMLKit/TextRecognition'

  target 'Tests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end