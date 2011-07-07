Git = Module.new unless defined? Git

module Git::Webby

  module RepositoryUtils

    def project_path_to(*args)
      File.join(settings.config.project_root.to_s, *(args.map(&:to_s)))
    end

    def git_dir(name)
      unless name =~ /\w\.git/ # not bare directory
        File.join(name, ".git")
      else
        name
      end
    end

    def path_to(name, *args)
      project_path_to(git_dir(name), *args)
    end

    def read_file(dirname, *file)
      File.read(path_to(dirname, *file))
    end

    def chdir(dirname, &block)
      Dir.chdir(path_to(dirname), &block)
    end

    def git_cli(command, *args)
      %Q[#{settings.config.git_path} #{args.unshift(command.to_s.gsub("_","-")).compact.join(" ")}]
    end

    def git_run(command, *args)
      %x[#{git_cli command, *args}]
    end

  end # RepositoryUtils

  class Config

    attr_accessor :project_root

    attr_accessor :git_path

    attr_accessor :get_any_file

    attr_accessor :upload_pack

    attr_accessor :receive_pack

    def initialize(attributes = {})
      defaults = { :project_root    => ".",
                  :git_path        => "/usr/bin/git",
                  :get_any_file    => true,
                  :upload_pack     => true,
                  :receive_pack    => false }
      defaults.update(attributes).each do |key, value|
        self.send("#{key}=", value) if self.respond_to? key
      end
    end

  end

  autoload :HttpBackend, "git/webby/http_backend"

end # Git::Webby

