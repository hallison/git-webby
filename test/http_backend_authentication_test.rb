require "test/unit"
require "test/helpers"
require "rack"
require "rack/test"
require "git/webby"

class HttpBackendAuthenticationTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    # return 500 objects/info/http-alternates
    #            objects/info/alternates
    @paths = [
      [ :get,  "HEAD" ],
      [ :get,  "info/refs" ],
      [ :get,  "objects/info/packs" ],
      [ :get,  "objects/02/83eb96425444e17b97182e1ba9f216cc67c132" ],
      [ :get,  "objects/03/9927042df267a1bc606fc4485b7a79b6a9e3cd" ],
      [ :get,  "objects/4b/825dc642cb6eb9a060e54bf8d69288fbee4904" ],
      [ :get,  "objects/5e/54a0767e0c380f3baab17938d68c7f464cf171" ],
      [ :get,  "objects/71/6e9568eed27d5ee4378b3ecf6dd095a547bde9" ],
      [ :get,  "objects/be/118435b9d908fd4a689cd8b0cc98059911a31a" ],
      [ :get,  "objects/db/aefcb5bde664671c73b99515c386dcbc7f22b6" ],
      [ :get,  "objects/eb/669b878d2013ac70aa5dee75e6357ea81d16ea" ],
      [ :get,  "objects/ed/10cfcf72862e140c97fe899cba2a55f4cb4c20" ],
      [ :get,  "objects/pack/pack-40a8636b62258fffd78ec1e8d254116e72d385a9.idx" ],
      [ :get,  "objects/pack/pack-40a8636b62258fffd78ec1e8d254116e72d385a9.pack" ],
      [ :get,  "info/refs", { :service => "git-upload-pack"  } ],
      [ :get,  "info/refs", { :service => "git-receive-pack" } ],
      [ :post, "git-upload-pack",  {}, { "CONTENT_TYPE" => "application/x-git-upload-pack-request"  } ],
      [ :post, "git-receive-pack", {}, { "CONTENT_TYPE" => "application/x-git-receive-pack-request" } ]
    ]
  end

  def app
    @app = Git::Webby::HttpBackend.configure do |server|
      server.project_root = fixtures
      server.git_path     = "/usr/bin/git"
      server.authenticate = true
    end
    @app
  end

  should "unauthorize repository paths" do
    @paths.each do |params|
      verb = params.shift
      path = params.shift
      send verb, "/mycode.git/#{path}", *params
      assert_equal 401, response.status
    end
  end

  should "authorize repository paths" do
    authorize("john", "s3kr3t")
    @paths.each do |params|
      verb = params.shift
      path = params.shift
      send verb, "/mycode.git/#{path}", *params
      assert_equal 200, response.status
    end
  end

  private

  def response
    last_response
  end

end
