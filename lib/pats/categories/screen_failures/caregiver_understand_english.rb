# frozen_string_literal: true

require 'pats/categories/default'

module Pats
  module Categories
    module ScreenFailures
      # Defines caregiver language variable and associated subquery.
      class CaregiverUnderstandEnglish < Default
        def label
          'Caregiver is not able to read and write in English'
        end

        def variable_name
          'ciw_caregiver_understand_english'
        end

        def subquery
          "NULLIF(response, '')::numeric = 0"
        end
      end
    end
  end
end
