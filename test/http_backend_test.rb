require "test/unit"
require "test/helpers"
require "rack"
require "rack/test"
require "git/webby"

class HttpBackendTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @objects = [
      "02/83eb96425444e17b97182e1ba9f216cc67c132",
      "03/9927042df267a1bc606fc4485b7a79b6a9e3cd",
      "4b/825dc642cb6eb9a060e54bf8d69288fbee4904",
      "5e/54a0767e0c380f3baab17938d68c7f464cf171",
      "71/6e9568eed27d5ee4378b3ecf6dd095a547bde9",
      "be/118435b9d908fd4a689cd8b0cc98059911a31a",
      "db/aefcb5bde664671c73b99515c386dcbc7f22b6",
      "eb/669b878d2013ac70aa5dee75e6357ea81d16ea",
      "ed/10cfcf72862e140c97fe899cba2a55f4cb4c20"
    ]
  end

  def app
    @app = Git::Webby::HttpBackend.configure do |server|
      server.project_root = fixtures
      server.git_path     = "/usr/bin/git"
      server.get_any_file = true
      server.upload_pack  = true
      server.receive_pack = true
      server.authenticate = false
    end
    @app
  end

  should "get head" do
    get "/mycode.git/HEAD" do
      assert_equal 200, response.status
      assert_equal "ref: refs/heads/master\n", response.body
    end
  end

  should "get info refs" do
    get "/mycode.git/info/refs" do
      assert_equal 200, response.status
      assert_match "refs/heads/master", response.body
      assert_match "refs/tags/v0.1.0",  response.body
    end
  end

  should "get info alternates" do
    get "/mycode.git/objects/info/alternates" do
      assert_equal 500, response.status # fixtures without alternates
    end
  end

  should "get info http alternates" do
    get "/mycode.git/objects/info/http-alternates" do
      assert_equal 500, response.status # fixtures without http-alternates
    end
  end

  should "get object info packs" do
    get "/mycode.git/objects/info/packs" do
      assert_equal 200, response.status
      assert_equal "P pack-40a8636b62258fffd78ec1e8d254116e72d385a9.pack",
                   response.body.split("\n").first
    end
  end

  should "get loose objects" do
    @objects.each do |object|
      get "/mycode.git/objects/#{object}" do
        assert_equal 200, response.status
        assert_equal "application/x-git-loose-object", response.content_type
      end
    end
  end

  should "get pack file" do
    get "/mycode.git/objects/pack/pack-40a8636b62258fffd78ec1e8d254116e72d385a9.idx" do
      assert_equal 200, response.status
      assert_equal "application/x-git-packed-objects-toc", response.content_type
    end
  end

  should "get index file" do
    get "/mycode.git/objects/pack/pack-40a8636b62258fffd78ec1e8d254116e72d385a9.pack" do
      assert_equal 200, response.status
      assert_equal "application/x-git-packed-objects", response.content_type
    end
  end

  should "upload advertisement" do
    get "/mycode.git/info/refs", :service => "git-upload-pack" do
      assert_equal 200, response.status
      assert_equal "application/x-git-upload-pack-advertisement", response.content_type
      assert_equal "001e# service=git-upload-pack", response.body.split("\n").first
      assert_match 'multi_ack_detailed', response.body
    end
  end

  should "receive advertisement" do
    get "/mycode.git/info/refs", :service => "git-receive-pack" do
      assert_equal 200, response.status
      assert_equal "application/x-git-receive-pack-advertisement", response.content_type
      assert_equal "001f# service=git-receive-pack", response.body.split("\n").first
      assert_match "report-status", response.body
      assert_match "delete-refs",   response.body
      assert_match "ofs-delta",     response.body
    end
  end

  # this test use mock in IO.popen. See in test/helpers.rb.
  should "RPC for upload packets" do
    post "/mycode.git/git-upload-pack", {}, {"CONTENT_TYPE" => "application/x-git-upload-pack-request"}
    assert_equal 200, response.status
    assert_equal "application/x-git-upload-pack-result", response.content_type
  end

  # this test use mock in IO.popen. See in test/helpers.rb.
  should "RPC for receive packets" do
    post "/mycode.git/git-receive-pack", {}, {"CONTENT_TYPE" => "application/x-git-receive-pack-request"}
    assert_equal 200, response.status
    assert_equal "application/x-git-receive-pack-result", response.content_type
  end

  private

  def response
    last_response
  end

end
