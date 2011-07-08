rdocs = FileList["README.rdoc", "lib/git/webby.rb"]

desc "API Documentation (RDoc)"
task :doc => rdocs do
  %x[rdoc -o doc/api -H -f hanna -m README.rdoc]
end

desc "Run tests"
task :test, [:file] do |spec, args|
  Dir["test/#{args.file}*_test.rb"].each do |file|
    sh %[ruby #{file} -v]
  end
end
