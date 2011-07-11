require "git/webby"

Gem::Specification.new do |spec|
  spec.platform          = Gem::Platform::RUBY
  spec.name              = "git-webby"
  spec.summary           = "Git Web implementation of the Smart HTTP and other features"
  spec.authors           = ["Hallison Batista"]
  spec.email             = "hallison@codigorama.com"
  spec.homepage          = "http://github.com/codigorama/git-webby"
  spec.rubyforge_project = spec.name
  spec.version           = Git::Webby::VERSION
  spec.date              = Git::Webby::RELEASE
  spec.test_files        = spec.files.select{ |path| path =~ /^test\/.*/ }
  spec.require_paths     = ["lib"]
  spec.files             = %x[git ls-files].split.reject do |out|
    out =~ %r{^\.} || out =~ %r{/^doc/api/}
  end
  spec.description       = <<-end.gsub /^    /,''
    Git::Webby is a implementation of the several features:
    - Smart HTTP which works like as git-http-backend.
    - Show info pages about the projects.
  end
  spec.post_install_message = <<-end.gsub(/^[ ]{4}/,'')
    #{'-'*78}
    Git::Webby v#{spec.version}

    Thanks for use Git::Webby.
    #{'-'*78}
  end
  spec.add_dependency "sinatra", ">= 1.0"
end

