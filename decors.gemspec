lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'decors'

Gem::Specification.new do |gem|
    gem.name          = "decors"
    gem.version       = ::Decors::VERSION
    gem.licenses      = ['MIT']
    gem.authors       = ['Vivien Meyet']
    gem.email         = ['vivien@getbannerman.com']
    gem.description   = "Ruby implementation of Python method decorators / Java annotations"
    gem.summary       = gem.description
    gem.homepage      = 'https://github.com/getbannerman/decors'

    gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
    gem.test_files    = gem.files.grep(%r{^spec/})
    gem.require_paths = ['lib']

    gem.add_development_dependency 'pry', '~> 0'
    gem.add_development_dependency 'rspec', '~> 0'
end
