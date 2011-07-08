rdocs = FileList["README.rdoc", "lib/git/webby.rb"]

desc "API Documentation (RDoc)"
task :doc => rdocs do
  %x[rdoc --show-hash --verbose --format hanna --main README.rdoc]
end

desc "Run tests"
task :test, [:pattern] do |spec, args|
  Dir["test/#{args.pattern}*_test.rb"].each do |file|
    sh %[ruby #{file}]
  end
end
