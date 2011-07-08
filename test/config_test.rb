require "test/unit"
require "test/helpers"
require "git/webby"

class ConfigTest < Test::Unit::TestCase

  def setup
    @http_backend = {
      :project_root => "/var/git",
      :git_path     => "/usr/bin/git",
      :get_any_file => true,
      :upload_pack  => true,
      :receive_pack => false
    }
    @config = Git::Webby::Config.new do |config|
      config.http_backend = @http_backend
    end
  end

  should "config for HTTP backend" do
    assert_hash_equal @http_backend, @config.http_backend
  end

  should "load from YAML file" do
    config = Git::Webby::Config.load_file(fixtures("config.yml"))
    assert_not_nil config.http_backend
    assert_hash_equal @http_backend, config.http_backend
  end

end
