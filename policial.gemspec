# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'policial/version'

Gem::Specification.new do |spec|
  spec.name          = 'policial'
  spec.version       = Policial::VERSION
  spec.authors       = ['Volmer Campos Soares']
  spec.email         = ['rubygems@radicaos.com']
  spec.summary       = 'Review pull requests for style guide violations'
  spec.description   = 'Review pull requests for style guide violations.'
  spec.homepage      = 'https://github.com/volmer/policial'
  spec.license       = 'MIT'

  spec.files = Dir['lib/**/*'] + ['LICENSE.txt', 'Rakefile', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'coffeelint', '~> 1.16'
  spec.add_dependency 'eslintrb', '~> 2.1'
  spec.add_dependency 'octokit', '~> 4.12'
  spec.add_dependency 'rubocop', '~> 0.59'
end
