# frozen_string_literal: true

module Slice
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 39
    TINY = 0
    BUILD = 'beta1' # 'pre', 'beta1', 'beta2', 'rc', 'rc2', nil

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.').freeze
  end
end