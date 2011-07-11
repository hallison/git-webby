#:nopkg:
ENV["RUBYLIB"] = "#{File.dirname(__FILE__)}/lib"
ENV["RUBYOPT"] = "-rubygems"
#:

require "git/webby"

def spec
  @spec ||= Gem::Specification.load("git-webby.gemspec")
end

desc "Run tests"
task :test, [:file] do |spec, args|
  Dir["test/#{args.file}*_test.rb"].each do |file|
    sh "ruby #{file} -v"
  end
end

desc "API Documentation (RDoc)"
task :doc do
  sh "rdoc -o doc/api -H -f hanna -m README.rdoc"
end

desc "Build #{spec.file_name}"
task :build => "#{spec.name}.gemspec" do
  sh "gem build #{spec.name}.gemspec"
end

desc "Release #{spec.file_name}"
task :release do
  sh "gem push #{spec.file_name}"
end

desc "Install gem file #{spec.file_name}"
task :install => :build do
  sh "gem install -l #{spec.file_name}"
end

desc "Uninstall gem #{spec.name} v#{spec.version}"
task :uninstall do
  puts "gem uninstall -l #{spec.name} -v #{spec.version}"
end

