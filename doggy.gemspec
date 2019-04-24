# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "doggy"
  spec.version       = "3.0.0-beta1"
  spec.authors       = ["Vlad Gorodetsky", "Andre Medeiros"]
  spec.email         = ["v@gor.io", "me@andremedeiros.info"]

  spec.summary       = 'Syncs DataDog dashboards, alerts, screenboards, and monitors.'
  spec.description   = 'Syncs and manages DataDog dashboards, alerts, screenboards, and monitors.'
  spec.homepage      = "http://github.com/shopify/doggy"
  spec.license       = "MIT"

  spec.files         = %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.5'

  spec.add_runtime_dependency("parallel")
  spec.add_runtime_dependency("thor")
  spec.add_runtime_dependency("rugged")
  spec.add_runtime_dependency("activesupport")

  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("minitest")
  spec.add_development_dependency("pry")
  spec.add_development_dependency("rubocop")
end
