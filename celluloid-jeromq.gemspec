# -*- encoding: utf-8 -*-
require File.expand_path('../lib/celluloid/jeromq/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tony Arcieri", "Jonas Nicklas"]
  gem.email         = ["tony.arcieri@gmail.com", "jonas.nicklas@gmail.com"]
  gem.description   = "Celluloid bindings to the jeromq library"
  gem.summary       = "Celluloid::JeroMQ provides concurrent Celluloid actors that can listen for 0MQ events"
  gem.homepage      = "http://github.com/celluloid/celluloid-jeromq"
  gem.platform      = 'java'

  gem.name          = "celluloid-jeromq"
  gem.version       = Celluloid::JeroMQ::VERSION

  gem.add_dependency "celluloid", ">= 0.15.0"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "ffi-rzmq"

  # Files
  ignores = File.read(".gitignore").split(/\r?\n/).reject{ |f| f =~ /^(#.+|\s*)$/ }.map {|f| Dir[f] }.flatten
  gem.files = (Dir['**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.test_files = (Dir['spec/**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  # gem.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  gem.require_paths = ['lib']
end
