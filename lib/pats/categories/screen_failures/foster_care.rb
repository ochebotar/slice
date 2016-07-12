# frozen_string_literal: true

require 'pats/categories/default'

module Pats
  module Categories
    module ScreenFailures
      # Defines foster care variable and associated subquery.
      class FosterCare < Default
        def label
          'Child is in foster care'
        end

        def variable_name
          'ciw_foster_care'
        end

        def subquery
          "NULLIF(response, '')::numeric = 1"
        end
      end
    end
  end
end