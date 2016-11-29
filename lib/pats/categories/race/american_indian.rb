# frozen_string_literal: true

require 'pats/categories/default'

module Pats
  module Categories
    module Race
      # Defines American Indian / Native Alaskan race variable.
      class AmericanIndian < Default
        def label
          'American Indian / Native Alaskan'
        end

        def variable_name
          'ciw_race_cat_single'
        end

        def subquery
          "NULLIF(response, '')::numeric = 3"
        end
      end
    end
  end
end