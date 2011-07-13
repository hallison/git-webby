require "test/unit"
require "test/helpers"
require "git/webby"

class HtpasswdTest < Test::Unit::TestCase

  def setup
    @passwords = {
      "matthew" => "zKOzsdCzE.mEE",
      "mark"    => "V5.e7XhcXHmQc",
      "luke"    => "1y687odVzuFJs",
      "john"    => "BInD5.JEyr5Ng"
    }
    @htpasswd = Git::Webby::Htpasswd.new(fixtures("htpasswd"))
  end

  def teardown
    File.delete fixtures("htpasswd.tmp") if File.exist? fixtures("htpasswd.tmp")
  end

  should "find user" do
    @passwords.each do |username, password|
      assert_equal password, @htpasswd.find(username)
      @htpasswd.find username do |pass, salt|
        assert_equal password, pass
        assert_equal password[0,2], salt
      end
    end
  end

  should "check authentication of the user" do
    @passwords.keys.each do |user|
      assert !@htpasswd.authenticated?(user, "invalid")
      assert  @htpasswd.authenticated?(user, "s3kr3t")
    end
  end

  should "create or update user" do
    Git::Webby::Htpasswd.new fixtures("htpasswd.tmp") do |htpasswd|
      htpasswd.create "judas", "hanged"
      assert htpasswd.include?("judas")
      assert htpasswd.authenticated?("judas", "hanged")
    end
  end

  should "list users" do
    assert_equal 4, @htpasswd.size
    @passwords.keys.each do |user|
      assert @htpasswd.include?(user)
    end
  end

  should "destroy user" do
    Git::Webby::Htpasswd.new fixtures("htpasswd.tmp") do |htpasswd|
      htpasswd.create "judas", "hanged"
      assert htpasswd.include?("judas")

      htpasswd.destroy "judas"

      assert !htpasswd.include?("judas")
    end
  end

  should "check invalid user" do
    assert !@htpasswd.authenticated?("nobody", "empty")
  end

end
