module Git::Webby

  class Treeish < Application

    set :authenticate, false
    
    helpers GitHelpers

    before do
      authenticate! if settings.authenticate
    end

    get %r{/(.*?)/(.*?/{0,1}.*)$} do |name, path|
      content_type :json
      path = path.split("/")
      ref  = path.shift
      tree = repository.tree(ref, path.join("/"))
      tree.to_json(:max_nesting => tree.size*6)
    end

  private

    helpers AuthenticationHelpers

  end

end

