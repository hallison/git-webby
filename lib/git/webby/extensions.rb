class Object
  # Set instance variables by key and value only if object respond
  # to access method for variable.
  def instance_variables_set_from(hash)
    hash.collect do |variable, value|
      self.instance_variable_set("@#{variable}", value) if self.respond_to? variable
    end
    self
  end

end

class Symbol

  # Method for comparison between symbols.
  def <=>(other)
    self.to_s <=> other.to_s
  end

  # Parse the symbol name to constant name. Example:
  #
  #   $ :http_backend.to_const_name
  #   => "HttpBackend"
  def to_const_name
    n = self.to_s.split(/_/).map(&:capitalize).join
    RUBY_VERSION =~ /1\.8/ ? n : n.to_sym
  end

end

class Hash

  # Only symbolize all keys, including all key in sub-hashes. 
  def symbolize_keys
    return self.clone if self.empty?
    self.inject({}) do |h, (k, v)|
      h[k.to_sym] = (v.kind_of? Hash) ? v.symbolize_keys : v
      h
    end
  end

  # Convert to Struct including all values that are Hash class.
  def to_struct
    keys    = self.keys.sort
    members = keys.map(&:to_sym)
    Struct.new(*members).new(*keys.map do |key|
      (self[key].kind_of? Hash) ?  self[key].to_struct : self[key]
    end) unless self.empty?
  end

end

class String

  def to_semver_h
    tags   = [:major, :minor, :patch, :status]
    values = self.split(".").map do |key|
      # Check pre-release status
      if key.match(/^(\d{1,})([a-z]+[\d\w]{1,}.*)$/i)
        [ $1.to_i, $2 ]
      else
        key.to_i
      end
    end.flatten
    Hash[tags.zip(values)]
  end

  def to_attr_name
    self.split("::").last.gsub(/(.)([A-Z])/){"#{$1}_#{$2.downcase}"}.downcase
  end

end

