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
  #
  # This class configure the needed variables used by application. See
  # Config::DEFAULTS for the values will be initialized by default.
  # 
  # Basically, the +default+ attribute set the values that will be necessary
  # by all applications.
  #
  # The HTTP-Backend application is configured by +http_backend+ attribute
  # to set the Git RCP CLI. More details about this feature, see the
  # {git-http-backend official
  # page}[http://www.kernel.org/pub/software/scm/git/docs/git-http-backend.html]
  #
  # For tree view (JSON API) just use the attribute +tree_view+.
  #
  # [*default*]
  #   Default configuration. All attributes will be used by all modular
  #   applications.
  #
  #   *project_root* ::
  #     Sets the root directory where repositories have been
  #     placed.
  #   *git_path* ::
  #     Path to the git command line.
  #
  # [*treeish*]
  #   Configuration for Treeish JSON API.
  #
  #   *authenticate* ::
  #     Sets if the tree view server requires authentication.
  #
  # [*http_backend*]
  #   HTTP-Backend configuration.
  #
  #   *authenticate* ::
  #     Sets if authentication is required.
  #
  #   *get_any_file* ::
  #     Like +http.getanyfile+.
  #
  #   *upload_pack*  ::
  #     Like +http.uploadpack+.
  #
  #   *receive_pack* ::
  #     Like +http.receivepack+.
  module Webby

    class ProjectHandler #:nodoc:

      # Path to git comamnd
      attr_reader :path

      attr_reader :project_root

      attr_reader :repository

      def initialize(project_root, path = "/usr/bin/git")
        @repository   = nil
        @path         = check_path(File.expand_path(path))
        @project_root = check_path(File.expand_path(project_root))
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
            object = {
              :ftype => ftype[$1],
              :fperm => "#{fperm[$2.to_i]}#{fperm[$3.to_i]}#{fperm[$4.to_i]}",
              :otype => $5.to_sym,
              :ohash => $6,
              :fsize => fsize($7, 2),
              :fname => $8
            }
            object[:objects] = nil if object[:otype] == :tree
            tree << object
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

      def find(username) #:yield: password, salt
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

    module GitHelpers #:nodoc:

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

    module AuthenticationHelpers #:nodoc:

      def htpasswd
        @htpasswd ||= Htpasswd.new(git.path_to("htpasswd"))
      end

      def authentication
        @authentication ||= Rack::Auth::Basic::Request.new request.env
      end

      def authenticated?
        request.env["REMOTE_USER"] && request.env["git.webby.authenticated"]
      end

      def authenticate(username, password)
        checked   = [ username, password ] == authentication.credentials
        validated = authentication.provided? && authentication.basic?
        granted   = htpasswd.authenticated? username, password
        if checked and validated and granted
          request.env["git.webby.authenticated"] = true
          request.env["REMOTE_USER"] = authentication.username
        else
          nil
        end
      end

      def unauthorized!(realm = Git::Webby::info)
        headers "WWW-Authenticate" => %(Basic realm="#{realm}")
        throw :halt, [ 401, "Authorization Required" ]
      end

      def bad_request!
        throw :halt, [ 400, "Bad Request" ]
      end

      def authenticate!
        return if authenticated?
        unauthorized! unless authentication.provided?
        bad_request!  unless authentication.basic?
        unauthorized! unless authenticate(*authentication.credentials)
        request.env["REMOTE_USER"] = authentication.username
      end

      def access_granted?(username, password)
        authenticated? || authenticate(username, password)
      end

    end # AuthenticationHelpers

    # Servers
    autoload :HttpBackend, "git/webby/http_backend"
    autoload :Treeish,     "git/webby/treeish"

    class << self

      def config
        @config ||= {
          :default => {
            :project_root => "/home/git",
            :git_path     => "/usr/bin/git"
          },
          :treeish => {
            :authenticate => false
          },
          :http_backend => {
            :authenticate => true,
            :get_any_file => true,
            :upload_pack  => true,
            :receive_pack => false
          }
        }.to_struct
      end

      # Configure Git::Webby modules using keys. See Config for options.
      def configure(&block)
        yield config
        config
      end

      def load_config_file(file)
        @config = CONFIGURATION.update(YAML.load_file(file).symbolize_keys).to_struct
      end

      #def apply_to_class(klass, key = klass.name.to_attr_name.to_sym, &block)
    end

    class Application < Sinatra::Base #:nodoc:

      def self.configure!
        [:default, config_name].each do |key|
          Git::Webby.config[key].each_pair do |option, value|
            set option, value
          end if Git::Webby.config.respond_to? key
        end
        self
      end

      def configure!
        settings.configure!
      end

      def self.inherited(base)
        base.configure!
        super
      end

      def self.config_name
        self.name.to_attr_name.to_sym
      end

      mime_type :json, "application/json"

    end

  end

end
