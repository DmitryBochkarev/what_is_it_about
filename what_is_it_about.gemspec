# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'what_is_it_about/version'

Gem::Specification.new do |spec|
  spec.name          = "what_is_it_about"
  spec.version       = WhatIsItAbout::VERSION
  spec.authors       = ["Dmitry Bochkarev"]
  spec.email         = ["dimabochkarev@gmail.com"]

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/DmitryBochkarev/what_is_it_about"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'bundler', '1.15.4'
  spec.add_dependency 'octokit', '4.7.0'
  spec.add_dependency 'thor', '0.20.0'

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
