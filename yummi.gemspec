# -*- encoding: utf-8 -*-
require File.expand_path('../lib/yummi/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ataxexe"]
  gem.email         = ["ataxexe@gmail.com"]
  gem.description   = "A tool to colorize your console application."
  gem.summary       = "A tool to colorize your console application."
  gem.homepage      = "https://github.com/ataxexe/yummi"

  gem.add_dependency 'term-ansicolor', '>=1.1.5'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "yummi"
  gem.require_paths = ["lib"]
  gem.version       = Yummi::VERSION
end
