Pod::Spec.new do |spec|
  spec.platform       = :ios, "7.0"
  spec.name           = 'ZLRevealViewController'
  spec.version        = '0.1'
  spec.homepage       = 'https://github.com/Ilushkanama/ZLRevealViewController'
  spec.authors        = { 'Ilya Dyakonov' => 'ilya@zappylab.com' }
  spec.summary        = 'Reveal view controller'
  spec.source         = { :git => 'https://github.com/Ilushkanama/ZLRevealViewController.git', :branch => "dev" }
  spec.source_files   = 'RevealViewController/*.{h,m}'
  spec.requires_arc   = true
end