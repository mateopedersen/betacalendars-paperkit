Pod::Spec.new do |s|
  s.name = 'BetaCalendarsPaperKit'
  s.version = '0.1.1'
  s.summary = 'Deterministic Swift toolkit for printable calendar grids and paper layout geometry.'
  s.description = <<-DESC
    A timezone-independent Gregorian month-grid engine with printable paper
    geometry, blank planning grids, SwiftUI views and vector PDF rendering.
    Includes offline reference metadata and has no runtime third-party dependencies.
  DESC
  s.homepage = 'https://www.betacalendars.com/'
  s.documentation_url = 'https://mateopedersen.github.io/betacalendars-paperkit/documentation/betacalendarspaperkit/'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = 'Mateo Pedersen'
  s.source = { :git => 'https://github.com/mateopedersen/betacalendars-paperkit.git', :tag => s.version.to_s }
  s.readme = 'https://raw.githubusercontent.com/mateopedersen/betacalendars-paperkit/0.1.1/README.md'
  s.changelog = 'https://raw.githubusercontent.com/mateopedersen/betacalendars-paperkit/0.1.1/CHANGELOG.md'
  s.module_name = 'BetaCalendarsPaperKit'
  s.swift_versions = ['5.9', '6.0']
  s.ios.deployment_target = '15.0'
  s.macos.deployment_target = '12.0'
  s.static_framework = true
  s.source_files = 'Sources/BetaCalendarsPaperKit/**/*.swift'
  s.requires_arc = true
end
