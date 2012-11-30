module Slice
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 11
    TINY = 1
    BUILD = "pre" # nil, "pre", "beta1", "beta2", "rc", "rc2"

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.')
  end
end
