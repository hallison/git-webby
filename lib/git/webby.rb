# Standard requirements
require "yaml"

# 3rd part requirements
require "sinatra/base"
require "json"

# Internal requirements
require "git/webby/extensions"
require "git/webby/version"

# See <b>Git::Webby</b> for documentation.
module Git

  # The main goal of the <b>Git::Webby</b> is implement the following useful
  # features.
  #
  # - Smart-HTTP, based on _git-http-backend_.
  # - Authentication flexible based on database or configuration file like <tt>.htpasswd</tt>.
  # - API to get information about repository.
  module Webby

    class ProjectHandler #:nodoc:

      # Path to git comamnd
      attr_reader :path

      attr_reader :project_root

      attr_reader :repository

      def initialize(project_root, path = "/usr/bin/git", options = {})
        @config       = {
          :get_any_file => true,
          :upload_pack  => true,
          :receive_pack => false
        }.update(options)
        @repository   = nil
        @path         = File.expand_path(path)
        @project_root = File.expand_path(project_root)
        check_path @path
        check_path @project_root
      end

      def path_to(*args)
        File.join(@repository || @project_root, *(args.compact.map(&:to_s)))
      end

      def repository=(name)
        @repository = check_path(path_to(name))
      end

      def cli(command, *args)
        %Q[#{@path} #{args.unshift(command.to_s.gsub("_","-")).compact.join(" ")}]
      end

      def run(command, *args)
        chdir{ %x[#{cli command, *args}] }
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

      def tree(ref = "HEAD", path = "")
        list = run("ls-tree --abbrev=6 --full-tree --long #{ref}:#{path}")
        if list
          tree = []
          list.scan %r{^(\d{3})(\d)(\d)(\d) (\w.*?) (.{6})[ \t]{0,}(.*?)\t(.*?)\n}m do
            tree << {
              :ftype => ftype[$1],
              :fperm => "#{fperm[$2.to_i]}#{fperm[$3.to_i]}#{fperm[$4.to_i]}",
              :otype => $5,
              :ohash => $6,
              :fsize => fsize($7, 2),
              :fname => $8
            }
          end
          tree
        else
          nil
        end
      end

      private

      def repository_path(name)
        bare = name =~ /\w\.git/ ? name : %W[#{name} .git]
        check_path(path_to(*bare))
      end

      def check_path(path)
        path && !path.empty? && File.ftype(path) && path
      end

      def chdir(&block)
        Dir.chdir(@repository || @project_root, &block)
      end

      def ftype
        { "120" => "l", "100" => "-", "040" => "d" }
      end

      def fperm
        [ "---", "--x", "-w-", "-wx", "r--", "r-x", "rw-", "rwx"  ]
      end

      def fsize(str, scale = 1)
        units = [ :b, :kb, :mb, :gb, :tb ]
        value = str.to_f
        size  = 0.0
        units.each_index do |i|
          size = value / 1024**i
          return [format("%.#{scale}f", size).to_f, units[i].to_s.upcase] if size <= 10
        end
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

      DEFAULTS = {
        :repository => {
          :project_root => "/home/git",
          :git_path     => "/usr/bin/git",
          :authenticate => false
        },
        :http_backend => {
          :get_any_file => true,
          :upload_pack  => true,
          :receive_pack => false
        }
      }

      DEFAULTS.keys.map do |attribute|
        attr_reader attribute
      end

      def initialize(attributes = {}) # :yields: config
        DEFAULTS.update(attributes.symbolize_keys).map do |attrib, values|
          self.instance_variable_set("@#{attrib}", values.to_struct)
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

      def repository
        git.repository ||= (params[:repository] || params[:captures].first)
        git
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
    autoload :Viewer,      "git/webby/viewer"

  end

end
