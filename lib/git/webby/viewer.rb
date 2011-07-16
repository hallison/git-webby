module Git::Webby

  module ViewerHelpers

    include GitHelpers

  end

  class Viewer < Controller

    require "json"

    helpers ViewerHelpers

    set :project_root, File.expand_path("#{File.dirname(__FILE__)}/git")

    mime_type :json, "application/json"

    get %r{/(.*?)/(.*?/{0,1}.*)$} do |name, path|
      content_type :json
      path = path.split("/")
      ref  = path.shift
      tree = repository.tree(ref, path.join("/"))
      tree.to_json(:max_nesting => tree.size*6)
    end

  end

end

