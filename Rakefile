require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "mega_mutex"
    gem.summary = %Q{Cross-process mutex using MemCache}
    gem.description = %Q{Cross-process mutex using MemCache}
    gem.email = "developers@songkick.com"
    gem.homepage = "http://github.com/songkick/mega_mutex"
    gem.authors = ["Matt Johnson", "Matt Wynne"]
    gem.add_dependency 'memcache-client'
    gem.add_dependency 'logging', '>= 1.1.4'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

task :default => :build

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mega_mutex #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
