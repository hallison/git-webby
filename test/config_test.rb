require "test/unit"
require "test/helpers"
require "git/webby"

class ConfigTest < Test::Unit::TestCase

  def setup
    @config = {
      :default => {
        :project_root => "/var/git/repos",
        :git_path     => "/usr/local/bin/git"
      },
      :treeish => {
        :authenticate => true
      },
      :http_backend => {
        :authenticate => true,
        :get_any_file => true,
        :upload_pack  => true,
        :receive_pack => false,
      }
    }
  end

  should "configure by application" do
    Git::Webby.configure do |app|
      app.default.project_root = "/var/git/repos"
      app.default.git_path = "/usr/local/bin/git"
      app.treeish.authenticate = true
    end

    @config.keys.each do |app|
      @config[app].each do |option, value|
        assert_equal value, Git::Webby.config[app][option]
      end
    end
  end

  should "load from YAML file" do
    yaml   = YAML.load_file(fixtures("config.yml")).symbolize_keys
    config = Git::Webby.load_config_file(fixtures("config.yml"))
    yaml.keys.each do |app|
      yaml[app].each do |option, value|
        assert_equal value, config[app][option]
      end
    end
  end

end

