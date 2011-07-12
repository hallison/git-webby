require "test/unit"
require "test/helpers"
require "lib/git/webby"

class HtpasswdTest < Test::Unit::TestCase

  def setup
    @passwords = {
      "matthew" => "zKOzsdCzE.mEE",
      "mark"    => "V5.e7XhcXHmQc",
      "luke"    => "1y687odVzuFJs",
      "john"    => "BInD5.JEyr5Ng"
    }
    @committers = Git::Webby::Htpasswd.new(fixtures("committers.htpasswd"))
  end

  def teardown
    File.delete fixtures("htpasswd") if File.exist? fixtures("htpasswd")
  end

  should "find user" do
    @passwords.each do |username, password|
      assert_equal password, @committers.find(username)
      @committers.find username do |pass, salt|
        assert_equal password, pass
        assert_equal password[0,2], salt
      end
    end
  end

  should "check authentication of the user" do
    @passwords.keys.each do |user|
      assert !@committers.authenticated?(user, "invalid") 
      assert  @committers.authenticated?(user, "s3kr3t") 
    end
  end

  should "create or update user" do
    htpasswd = Git::Webby::Htpasswd.new(fixtures("htpasswd"))
    htpasswd.create "judas", "hanged"
    assert htpasswd.include?("judas")
    assert htpasswd.authenticated?("judas", "hanged")
  end

  should "list users" do
    assert_equal 4, @committers.size
    @passwords.keys.each do |user|
      assert @committers.include?(user)
    end
  end

  should "destroy user" do
    htpasswd = Git::Webby::Htpasswd.new(fixtures("htpasswd"))
    htpasswd.create "judas", "hanged"
    assert htpasswd.include?("judas")
  end

end
