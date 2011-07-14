# See <b>Git::Webby</b> for documentation.
module Git

  # 3rd part requirements
  require "sinatra/base"

  # Internal requirements
  require "git/webby/version"

  # The main goal of the <b>Git::Webby</b> is implement the following useful
  # features.
  #
  # - Smart-HTTP, based on _git-http-backend_.
  # - Authentication flexible based on database or configuration file like <tt>.htpasswd</tt>.
  # - API to get information about repository.
  module Webby

    class ProjectHandler #:nodoc:

      # Path to git comamnd
      attr_reader :git_path

      attr_reader :project_root

      def initialize(project_root, git_path = "/usr/bin/git", options = {})
        @config       = {
          :get_any_file => true,
          :upload_pack  => true,
          :receive_pack => false
        }.update(options)
        @git_path     = File.expand_path(git_path)
        @project_root = File.expand_path(project_root)
        check_path @git_path
        check_path @project_root
      end

      def cli(command, *args)
        %Q[#{@git_path} #{args.unshift(command.to_s.gsub("_","-")).compact.join(" ")}]
      end

      def run(command, *args)
        %x[#{cli command, *args}]
      end

      def repository_path(name)
        bare = name =~ /\w\.git/ ? name : %W[#{name} .git]
        check_path(path_to(*bare))
      end

      def path_to(*args)
        File.join(@project_root, *(args.map(&:to_s)))
      end

      private

      def check_path(path)
        path && !path.empty? && File.ftype(path) && path
      end

    end

    class Repository #:nodoc:

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def path_to(*file)
        File.join(@path, *(file.map(&:to_s)))
      end

      def chdir(&block)
        Dir.chdir(@path, &block)
      end

      def read_file(*file)
        File.read(path_to(*file))
      end

      def loose_object_path(*hash)
        path_to(:objects, *hash)
      end

      def pack_idx_path(pack)
        path_to(:objects, :pack, pack)
      end

      def info_packs_path
        path_to(:objects, :info, :packs)
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

    class Htgroup #:nodoc:

      def initialize(file)
        require "webrick/httpauth/htgroup"
        @handler = WEBrick::HTTPAuth::Htgroup.new(file)
        yield self if block_given?
      end
    end

    class Htpasswd #:nodoc:

      def initialize(file)
        require "webrick/httpauth/htpasswd"
        @handler = WEBrick::HTTPAuth::Htpasswd.new(file)
        yield self if block_given?
      end

      def find(username)
        password = @handler.get_passwd(nil, username, false)
        if block_given?
          yield password ? [password, password[0,2]] : [nil, nil]
        else
          password
        end
      end

      def authenticated?(username, password)
        self.find username do |crypted, salt|
          crypted && salt && crypted == password.crypt(salt)
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

    module GitHelpers

      def git
        @git ||= ProjectHandler.new(settings.project_root, settings.git_path)
      end

      def content_type_for_git(name, *suffixes)
        content_type("application/x-git-#{name}-#{suffixes.compact.join("-")}")
      end

    end

    class Controller < Sinatra::Base

      set :project_root, "/home/git"
      set :git_path,     "/usr/bin/git"
      set :authenticate, false

      def self.configure(*envs, &block)
        super(*envs, &block)
        self
      end
    end

    # Applications
    autoload :HttpBackend, "git/webby/http_backend"

  end

end
