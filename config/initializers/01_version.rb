# frozen_string_literal: true

module Slice
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 36
    TINY = 2
    BUILD = nil # 'pre', 'beta1', 'beta2', 'rc', 'rc2', nil

    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.').freeze
  end
end
