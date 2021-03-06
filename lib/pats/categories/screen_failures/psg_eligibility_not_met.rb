# frozen_string_literal: true

require 'pats/categories/default'

module Pats
  module Categories
    module ScreenFailures
      # Defines psg requirement not met variable and associated subquery.
      class PsgEligibilityNotMet < Default
        def label
          'PSG requirement not met'
        end

        # 'ciw_psg_eligibility_not_met'
        def variable_id
          14306
        end

        def subquery
          "#{database_value} = 1"
        end
      end
    end
  end
end
