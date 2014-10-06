#
# Be sure to run `pod lib lint EDHFinder.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "EDHFinder"
  s.version          = "0.1.0"
  s.summary          = "File management interface for iOS."
  s.description      = <<-DESC
                       Accessing file system with table view, developed for Edhita.
                       
                       # Features

                       * Exprole documents
                       * Create file or directory
                       * Destroy, rename, duplicate, move
                       * Download with URL
                       DESC
  s.homepage         = "https://github.com/tnantoka/EDHFinder"
  s.screenshots      = "https://raw.githubusercontent.com/tnantoka/EDHFinder/master/screenshot.png"
  s.license          = 'MIT'
  s.author           = { "tnantoka" => "tnantoka@bornneet.com" }
  s.source           = { :git => "https://github.com/tnantoka/EDHFinder.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tnantoka'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'EDHFinder' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'FCFileManager', '~> 1.0'
  s.dependency 'FontAwesomeKit', '~> 2.1'
  s.dependency 'MGSwipeTableCell', '~> 1.1'
end
