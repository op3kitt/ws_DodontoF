# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "ws_DodontoF"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["kitt"]
  s.email       = ["yosshi1123@gmail.com"]
  s.homepage    = "http://htmlddf.cry-kit.com/"
  s.summary     = %q{htmlddf WebSocket server}
  s.description = %q{htmlddf WebSocket server}
  s.license     = 'MIT'

  s.rubyforge_project = "ws_DodontoF"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency("em-websocket", ">= 0.5.1")
  s.add_dependency("hashie", ">= 3.5.7")
  s.add_dependency("fssm", ">= 0.2.10")
  s.add_dependency("filelist", ">= 0.0.1")
end
