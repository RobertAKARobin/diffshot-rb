# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "diffshot"
  spec.version       = "1.0.0"
  spec.authors       = ["RobertAKARobin"]
  spec.email         = ["robertgfthomas@gmail.com"]

  spec.summary       = %q{Screenshots every file diff throughout your entire commit history, and makes a handy "table of contents" markdown file.}
  spec.description   = %q{Screenshots every file diff throughout your entire commit history, and makes a handy "table of contents" markdown file.}
  spec.homepage      = "https://github.com/RobertAKARobin/diffshot"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["diffshot"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
