# The objective of this class is to implement various ideas proposed by the
# Semantic Versioning Specification (see reference[http://semver.org/]).
module Git::Webby #:nodoc:

  VERSION   = "0.1.0"
  RELEASE   = "2011-07-13"
  TIMESTAMP = "2011-07-05 12:32:36 -04:00"

  def self.info
    "#{name} v#{VERSION} (#{RELEASE})"
  end

end

