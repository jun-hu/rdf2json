# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "rdf2json"
  gem.homepage = "http://github.com/joejimbo/rdf2json"
  gem.license = "MIT"
  gem.summary = %Q{RDF N-Triples and N-Quads to JSON-LD or JSON converter.}
  gem.description = %Q{Converts RDF N-Triples and N-Quads files to either JSON-LD or JSON. Supports minimization of long URIs to shorter descriptive key names.}
  gem.email = 'joachim.baran@gmail.com'
  gem.authors = [ 'Joachim Baran' ]
  gem.executable = 'rdf2json'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.read('VERSION')

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rdf2json #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
