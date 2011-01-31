# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
#require 'faker/version'
 
Gem::Specification.new do |s|
  s.name        = "geo_convert"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chuck Taylor", "Jordan Brock"]
  s.email       = ["jordan@brock.id.au"]
  s.homepage    = "http://github.com/jordanbrock/geo_convert.git"
  s.summary     = "A port of Chuck Taylor's JavaScript converter. http://home.hiwaay.net/~taylorc/toolbox/geography/geoutm.html"
  s.description = "Converts from UTM to LatLong and back "
 
  s.required_rubygems_version = ">= 1.3.6"
  #s.rubyforge_project         = "faker"
 
  #s.add_development_dependency "rspec"
 
  s.files        = Dir.glob("{config,lib,tasks,test}/**/*") + %w(License.txt README.txt Manifest.txt)
  #s.executables  = ['faker']
  s.require_path = 'lib'
end