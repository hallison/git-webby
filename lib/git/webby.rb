module Git

module Webby

class Config
  attr_accessor :project_root

  attr_accessor :upload_pack

  attr_accessor :receive_pack

  def initialize(attributes = {})
    defaults = { :project_root    => ".",
                 :upload_pack     => true,
                 :receive_pack    => true }
    defaults.update(attributes).each do |key, value|
      self.send("#{key}=", value) if self.respond_to? key
    end
  end
end

require "sinatra/base"

class SmartHttp < Sinatra::Base

  set :config, Config.new(:project_root => "test/fixtures")

  def path_to(*args)
    File.join(settings.config.project_root, *args)
  end

  def read_file(repository, name)
    File.read(path_to("#{repository}.git", name))
  end

  mime_type :text,   "text/plain"
  mime_type :loose,  "application/x-git-loose-object"
  mime_type :packed, "application/x-git-packed-objects"

  get "/:repository.git/HEAD" do |repository|
    content_type :text
    read_file(repository, "HEAD")
  end
  
  get %r{/(.*?\.git)/objects/([0-9a-f]{2})/([0-9a-f]{38})$} do |repository, prefix, sufix|
    content_type :loose
    send_file(path_to(repository, "objects", prefix, sufix))
  end

  get %r{/(.*?\.git)/objects/pack/(pack-[0-9a-f]{40}.(pack|idx))$} do |repository, pack, ext|
    content_type :packed
    send_file(path_to(repository, "objects", "pack", pack))
  end

end # SmartHttp

end # Webby

end # Git

