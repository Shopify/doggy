# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'doggy/version'

Gem::Specification.new do |spec|
  spec.name          = "doggy"
  spec.version       = Doggy::VERSION
  spec.authors       = ["Vlad Gorodetsky"]
  spec.email         = ["v@gor.io"]

  spec.summary       = %q{Syncs DataDog dashboards, alerts, screenboards, and monitors.}
  spec.description   = %q{Syncs DataDog dashboards, alerts, screenboards, and monitors.}
  spec.homepage      = "http://github.com/bai/doggy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "dogapi", "~> 1.17"
  spec.add_dependency "thread", "~> 0.2"
  spec.add_dependency "ejson", "~> 1.0"
end
