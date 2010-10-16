# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ar_to_html_table/version"

Gem::Specification.new do |s|
  s.name        = "ar_to_html_table"
  s.version     = ArToHtmlTable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kip Cole"]
  s.email       = ["kipcole9@gmail.com"]
  s.homepage    = "http://github.com/kipcole9/ar_to_html_table"
  s.summary     = %q{Render and ActiveRecord result set as an HTML table}
  s.description = <<-EOF
    Defines Array#to_table that will render an ActiveRecord result set
    as an HTML table.
  EOF

  #s.rubyforge_project = "ar_to_html_table"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency('builder')
end
