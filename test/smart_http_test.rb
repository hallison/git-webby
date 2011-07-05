require "rubygems"
require "rack"
require "rack/test"
require "test/unit"
require "test/helpers"
require "lib/git/webby"

class SmartHttpTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @objects = [
      "03/9927042df267a1bc606fc4485b7a79b6a9e3cd",
      "4b/825dc642cb6eb9a060e54bf8d69288fbee4904",
      "71/6e9568eed27d5ee4378b3ecf6dd095a547bde9",
      "be/118435b9d908fd4a689cd8b0cc98059911a31a",
      "ed/10cfcf72862e140c97fe899cba2a55f4cb4c20"
    ]
  end

  def app
    config = {
      :project_root => fixtures,
      :upload_pack => true,
      :receive_pack => true
    }
    @app = Git::Webby::SmartHttp
    @app.set :config, Git::Webby::Config.new(config)
    @app
  end

  should "receive head" do
    get "/mycode.git/HEAD" do
      assert_equal 200, response.status
      assert_equal "ref: refs/heads/master\n", response.body
    end
  end

  should "receive objects" do
    @objects.each do |object|
      get "/mycode.git/objects/#{object}" do
        assert_equal 200, response.status
        assert_equal "application/x-git-loose-object", response.content_type
      end
    end
  end

  private

  def response
    last_response
  end

end
