Pod::Spec.new do |s|
  s.name             = "LIYDateTimePicker"
  s.version          = "0.1.9"
  s.summary          = "iOS view controller for picking a date and time."
  s.description      = <<-DESC
                       An iOS view controller for picking a date and time in way that doesn't suck
                       DESC
  s.homepage         = "https://github.com/lyahdav/LIYDateTimePicker"
  s.screenshots      = "https://raw.githubusercontent.com/lyahdav/LIYDateTimePicker/master/Screens/Screen1.png"
  s.license          = 'MIT'
  s.author           = { "Liron Yahdav" => "lyahdav@users.noreply.github.com" }
  s.source           = { :git => "https://github.com/lyahdav/LIYDateTimePicker.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/lyahdav'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Classes/**/*.{h,m}'
  s.dependency 'MSCollectionViewCalendarLayout'
  s.dependency 'UIColor-HexString'
  s.dependency 'Masonry'
  s.dependency 'ObjectiveSugar'
  s.dependency 'PureLayout'
end
