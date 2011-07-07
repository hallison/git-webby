module Git

module Webby

module RepositoryUtils

  def project_path_to(*args)
    File.join(settings.config.project_root.to_s, *(args.map(&:to_s)))
  end

  def git_dir(name)
    unless name =~ /\w\.git/ # not bare directory
      File.join(name, ".git")
    else
      name
    end
  end

  def path_to(name, *args)
    project_path_to(git_dir(name), *args)
  end

  def read_file(dirname, *file)
    File.read(path_to(dirname, *file))
  end

  def chdir(dirname, &block)
    Dir.chdir(path_to(dirname), &block)
  end

  def git_cli(command, *args)
    %Q[#{settings.config.git_path} #{args.unshift(command.to_s.gsub("_","-")).compact.join(" ")}]
  end

  def git_run(command, *args)
    %x[#{git_cli command, *args}]
  end

end

module BackendUtils

  include RepositoryUtils

  def content_type_for_git(name, *suffixes)
    content_type("application/x-git-#{name}-#{suffixes.compact.join('-')}")
  end

  def service_request?
    not params[:service].nil?
  end

  # select_service feature
  def service
    @service = params[:service]
    return false if @service.nil?
    return false if @service[0, 4] != 'git-'
    @service = @service.gsub('git-', '')
  end

  # pkt_write feature
  def packet_write(line)
    (line.size + 4).to_s(base=16).rjust(4, '0') + line
  end

  # pkt_flush feature
  def packet_flush
    "0000"
  end

  # hdr_nocache feature
  def header_nocache
    headers "Expires"       => "Fri, 01 Jan 1980 00:00:00 GMT",
            "Pragma"        => "no-cache",
            "Cache-Control" => "no-cache, max-age=0, must-revalidate"
  end

  # hdr_cache_forever feature
  def header_cache_forever
    now = Time.now
    headers "Date"          => now.to_s,
            "Expires"       => (now + 31536000).to_s,
            "Cache-Control" => "public, max-age=31536000"
  end

  # select_getanyfile feature
  def read_any_file
    unless settings.config.get_any_file
      halt 403, "Unsupported service: getanyfile"
    end
  end

  # get_text_file feature
  def read_text_file(repository, *file)
    read_any_file
    header_nocache
    content_type "text/plain"
    read_file(repository, *file)
  end

  # get_loose_object feature
  def send_loose_object(repository, hash_prefix, hash_suffix)
    read_any_file
    header_cache_forever
    content_type_for_git :loose, :object
    send_file(path_to(repository, "objects", hash_prefix, hash_suffix))
  end

  # get_pack_file and get_idx_file
  def send_pack_idx_file(repository, pack, idx = false)
    read_any_file
    header_cache_forever
    content_type_for_git :packed, :objects, (idx ? :toc : nil)
    send_file(path_to(repository, "objects", "pack", pack))
  end

  def send_info_packs(repository)
    read_any_file
    header_nocache
    content_type "text/plain; charset=utf-8"
    send_file(path_to(repository, "objects", "info", "packs"))
  end

  # run_service feature
  def run_advertisement(repository, service)
    header_nocache
    content_type_for_git service, :advertisement
    chdir repository do
      response.body  = ""
      response.body += packet_write("# service=git-#{service}\n")
      response.body += packet_flush
      response.body += git_run(service, "--stateless-rpc --advertise-refs .")
      response.finish
    end
  end

  def run_process(repository, service)
    content_type_for_git service, :result
    input   = request.body.read
    command = git_cli(service, "--stateless-rpc .")
    chdir repository do
      # This source has extracted from Grack written by Scott Chacon.
      IO.popen(command, File::RDWR) do |pipe|
        pipe.write(input)
        while !pipe.eof?
          block = pipe.read(8192) # 8M at a time
          response.write block    # steam it to the client
        end
      end # IO
      response.finish
    end
  end
end

class Config
  attr_accessor :project_root

  attr_accessor :git_path

  attr_accessor :get_any_file

  attr_accessor :upload_pack

  attr_accessor :receive_pack

  def initialize(attributes = {})
    defaults = { :project_root    => ".",
                 :git_path        => "/usr/bin/git",
                 :get_any_file    => true,
                 :upload_pack     => true,
                 :receive_pack    => false }
    defaults.update(attributes).each do |key, value|
      self.send("#{key}=", value) if self.respond_to? key
    end
  end

end

require "sinatra/base"

class HttpBackend < Sinatra::Base

  include BackendUtils

  set :config, Config.new

  # Services:
  #
  # {"GET", "/HEAD$", get_text_file},
  # {"GET", "/info/refs$", get_info_refs},
  # {"GET", "/objects/info/alternates$", get_text_file},
  # {"GET", "/objects/info/http-alternates$", get_text_file},
  # {"GET", "/objects/info/packs$", get_info_packs},
  # {"GET", "/objects/[0-9a-f]{2}/[0-9a-f]{38}$", get_loose_object},
  # {"GET", "/objects/pack/pack-[0-9a-f]{40}\\.pack$", get_pack_file},
  # {"GET", "/objects/pack/pack-[0-9a-f]{40}\\.idx$", get_idx_file},
  # 
  # {"POST", "/git-upload-pack$", service_rpc},
  # {"POST", "/git-receive-pack$", service_rpc}

  # implements the get_text_file function
  get "/:repository/HEAD" do |repository|
    read_text_file(repository, "HEAD")
  end

  # implements the get_info_refs function
  get "/:repository/info/refs" do |repository|
    if service_request? # by URL query parameters
      run_advertisement repository, service
    else
      read_text_file(repository, :info, :refs)
    end
  end

  # implements the get_text_file and get_info_packs functions
  get %r{/(.*?)/objects/info/(packs|alternates|http-alternates)$} do |repository, file|
    if file == "packs"
      send_info_packs(repository)
    else
      read_text_file(repository, :objects, :info, file)
    end
  end

  # implements the get_loose_object function
  get %r{/(.*?)/objects/([0-9a-f]{2})/([0-9a-f]{38})$} do |repository, prefix, suffix|
    send_loose_object(repository, prefix, suffix)
  end

  # implements the get_pack_file and get_idx_file functions
  get %r{/(.*?)/objects/pack/(pack-[0-9a-f]{40}.(pack|idx))$} do |repository, pack, ext|
    send_pack_idx_file(repository, pack, ext == "idx")
  end

  # implements the service_rpc function
  post "/:repository/:service" do |repository, rpc|
    run_process repository, service
  end

end # Backend

end # Webby

end # Git

