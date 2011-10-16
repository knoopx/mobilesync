# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "mobilesync"
  s.version = "0.1.0"
  s.authors = ["Víctor Martínez"]
  s.email = ["knoopx@gmail.com"]
  s.homepage = ""
  s.summary = %q{Mount MobileSync backups}
  s.description = s.summary

  s.rubyforge_project = "mobilesync"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "thor"
  s.add_runtime_dependency "bindata"
  s.add_runtime_dependency "fusefs"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "i18n"
end
