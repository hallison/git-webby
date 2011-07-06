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

  def read_file(repository, *pathtofile)
    File.read(path_to("#{repository}.git", pathtofile))
  end

  def chdir(repository, &block)
    Dir.chdir(path_to("#{repository}.git"), &block)
  end

  def service_requested?
    not params[:service].nil?
  end

  def service
    @service = params[:service]
    return false if @service.nil?
    return false if @service[0, 4] != 'git-'
    @service = @service.gsub('git-', '')
  end

  def content_type_for_git(name, *suffixes)
    content_type("application/x-git-#{name}-#{suffixes.compact.join('-')}")
  end

  def packet_line
    line = "# service=git-#{service}\n"
    (line.size + 4).to_s(base=16).rjust(4, '0') + line
  end

  def packet_flush
    "0000"
  end

  # only long arguments
  def git(command, *args)
    %x[git #{command.to_s.gsub("_","-")} #{args.join(" ")}]
  end

  before do
    response["Cache-Control"] = "no-cache, max-age=0, must-revalidate"
    response["Pragma"] = "no-cache"
  end

  get "/:repository.git/HEAD" do |repository|
    content_type "text/plain"
    read_file(repository, "HEAD")
  end

  get "/:repository.git/info/refs" do |repository|
    if service_requested?
      chdir repository do
        content_type_for_git service, :advertisement
        response.body  = ""
        response.body += packet_line
        response.body += packet_flush
        response.body += git(service, "--stateless-rpc --advertise-refs .")
        response.finish
      end
    else
      content_type "text/plain"
      read_file(repository, "info", "refs")
    end
  end

  get %r{/(.*?\.git)/objects/([0-9a-f]{2})/([0-9a-f]{38})$} do |repository, prefix, suffix|
    content_type_for_git :loose, :object
    send_file(path_to(repository, "objects", prefix, suffix))
  end

  get %r{/(.*?\.git)/objects/pack/(pack-[0-9a-f]{40}.(pack|idx))$} do |repository, pack, ext|
    content_type_for_git :packed, :objects, (ext == "idx" ? :toc : nil)
    send_file(path_to(repository, "objects", "pack", pack))
  end

end # SmartHttp

end # Webby

end # Git

