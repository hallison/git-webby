require "test/unit"
require "test/helpers"
require "git/webby"

class ProjectHandlerTest < Test::Unit::TestCase

  def setup
    @git = Git::Webby::ProjectHandler.new(fixtures, "/usr/bin/git")
    @objects = [
      "HEAD",
      "info/refs",
      "objects/info/packs",
      "objects/02/83eb96425444e17b97182e1ba9f216cc67c132",
      "objects/03/9927042df267a1bc606fc4485b7a79b6a9e3cd",
      "objects/4b/825dc642cb6eb9a060e54bf8d69288fbee4904",
      "objects/5e/54a0767e0c380f3baab17938d68c7f464cf171",
      "objects/71/6e9568eed27d5ee4378b3ecf6dd095a547bde9",
      "objects/be/118435b9d908fd4a689cd8b0cc98059911a31a",
      "objects/db/aefcb5bde664671c73b99515c386dcbc7f22b6",
      "objects/eb/669b878d2013ac70aa5dee75e6357ea81d16ea",
      "objects/ed/10cfcf72862e140c97fe899cba2a55f4cb4c20",
      "objects/pack/pack-40a8636b62258fffd78ec1e8d254116e72d385a9.idx",
      "objects/pack/pack-40a8636b62258fffd78ec1e8d254116e72d385a9.pack"
    ]
    @git.repository = "mycode.git"
  end

  should "check basic attributes" do
    assert_equal fixtures, @git.project_root
    assert_equal "/usr/bin/git", @git.path
  end

  should "config repository path" do
    assert_equal fixtures("mycode.git"), @git.repository
  end

  should "find repository objects" do
    @objects.each do |object|
      assert_equal fixtures("mycode.git", object), @git.path_to(object)
      assert File.exist?(@git.path_to(object))
    end
  end

  should "list tree files" do
    assert_equal 3, @git.tree.size
    assert_equal "README.txt", @git.tree[1][:fname]
    assert_equal "lib", @git.tree.last[:fname]
    assert_equal "mycode.rb", @git.tree("HEAD", "lib").first[:fname]
  end

end
