require "test/unit"
require "test/helpers"
require "git/webby"

class ConfigTest < Test::Unit::TestCase

  def setup
    @attributes = {
      :repository => {
        :project_root => "/var/git",
        :git_path     => "/usr/bin/git",
        :authenticate => true
      },
      :http_backend => {
        :get_any_file => true,
        :upload_pack  => true,
        :receive_pack => false
      }
    }
    @config = Git::Webby::Config.new @attributes
  end

  should "config by hash" do
    @attributes.keys.each do |method|
      @attributes[method].each do |key, value|
        assert_equal value, @config.send(method).send(key)
      end
    end
  end

  should "load from YAML file" do
    yaml   = YAML.load_file(fixtures("config.yml"))
    config = Git::Webby::Config.load_file(fixtures("config.yml"))
    yaml.keys.each do |method|
      yaml[method].each do |key, value|
        assert_equal value, @config.send(method).send(key)
      end
    end
  end

end
