$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "hash_attributes/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "hash_attributes"
  s.platform    = Gem::Platform::RUBY
  s.version     = HashAttributes::VERSION
  s.authors     = ["Jacob Madsen", "Martin Thoegersen"]
  s.email       = ["hello@webnuts.com"]
  s.homepage    = "https://github.com/webnuts/hash_attributes"
  s.summary     = "Use a Hash column as backend for dynamic attributes"
  s.description = "Use a Hash column as backend for dynamic attributes. Dynamic attributes will act like table columns. Just include the HashAttributes module in your ActiveRecord::Base class."
  s.license     = 'MIT'

  s.files = Dir["{lib,spec}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].select{ |p| p.include?("spec/dummy/log") == false }

  s.add_dependency "activerecord", "~> 4.0.0"

  s.add_development_dependency "rails", "~> 4.0.0"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails", "~> 2.0"
end
