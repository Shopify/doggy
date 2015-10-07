# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'doggy/version'

Gem::Specification.new do |spec|
  spec.name          = "doggy"
  spec.version       = Doggy::VERSION
  spec.authors       = ["Vlad Gorodetsky", "Andre Medeiros"]
  spec.email         = ["v@gor.io", "me@andremedeiros.info"]

  spec.summary       = %q{Syncs DataDog dashboards, alerts, screenboards, and monitors.}
  spec.description   = %q{Syncs DataDog dashboards, alerts, screenboards, and monitors.}
  spec.homepage      = "http://github.com/bai/doggy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "json",     "~> 1.8.3"
  spec.add_dependency "parallel", "~> 1.6.1"
  spec.add_dependency "thor",     "~> 0.19.1"
  spec.add_dependency "virtus",   "~> 1.0.5"
  spec.add_dependency "rugged",   "~> 0.23.2"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
