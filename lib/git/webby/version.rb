module Git

  # The objective of this class is to implement various ideas proposed by the
  # Semantic Versioning Specification (see reference[http://semver.org/]).
  module Webby #:nodoc:

    VERSION   = "0.2.0"
    RELEASE   = "2011-07-16"
    TIMESTAMP = "2011-07-05 12:32:36 -04:00"

    def self.info
      "#{name} v#{VERSION} (#{RELEASE})"
    end

    def self.to_h
      { :name      => name,
        :version   => VERSION,
        :semver    => VERSION.to_semver_h,
        :release   => RELEASE,
        :timestamp => TIMESTAMP }
    end

  end

end

