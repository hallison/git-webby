# See <b>Git::Webby</b> for documentation.
module Git

  # Internal requirements
  require "git/webby/version"

  # The main goal of the <b>Git::Webby</b> is implement the following useful
  # features.
  #
  # - Smart-HTTP, based on _git-http-backend_.
  # - Authentication flexible based on database or configuration file like <tt>.htpasswd</tt>.
  # - API to get information about repository.
  module Webby

    module RepositoryUtils # :nodoc:
      def project_path_to(*args)
        File.join(settings.project_root.to_s, *(args.map(&:to_s)))
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
        %Q[#{settings.git_path} #{args.unshift(command.to_s.gsub("_","-")).compact.join(" ")}]
      end

      def git_run(command, *args)
        %x[#{git_cli command, *args}]
      end

    end

    # This class configure the needed variables used by application.
    # 
    # For HTTP-Backend configuration
    #
    # The following attributes was necessary by +http_backend+:
    #
    # *project_root*  :: Directory that contains all git repositories.
    # *git_path*      :: Path to git command line program.
    # *get_any_file*  :: Like <tt>http.getanyfile</tt> configuration.
    # *upload_pack*   :: Like <tt>http.uploadpack</tt> configuration.
    # *receive_pack*  :: Like <tt>http.receivepack</tt> configuration.
    class Config

      # Configuration for HTTP Backend variables
      attr_accessor :http_backend

      def initialize(attributes = {}) # :yields: config
        attributes.each do |key, value|
          self.send("#{key}=", value) if self.respond_to? key
        end
        yield self if block_given?
      end

      def self.load_file(file)
        require "yaml"
        new(YAML.load_file(file))
      end

    end

    class Htpasswd
      require "webrick/httpauth/htpasswd"

      attr_reader :users

      def initialize(file)
        @handler = WEBrick::HTTPAuth::Htpasswd.new(file)
        yield self if block_given?
      end

      def find(username)
        password = @handler.get_passwd(nil, username, false)
        if block_given?
          yield [ password, password[0,2] ]
        else
          password
        end
      end

      def authenticated?(username, password)
        self.find username do |crypted, salt|
          crypted == password.crypt(salt)
        end
      end

      def create(username, password)
        @handler.set_passwd(nil, username, password)
      end
      alias update create

      def destroy(username)
        @handler.delete_passwd(nil, username)
      end

      def include?(username)
        users.include? username
      end

      def size
        users.size
      end

      def write!
        @handler.flush
      end

      private

      def users
        @handler.each{|username, password| username }
      end
    end

    # Applications
    autoload :HttpBackend, "git/webby/http_backend"

  end

end
