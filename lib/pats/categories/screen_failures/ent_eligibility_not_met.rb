# frozen_string_literal: true

require 'pats/categories/default'

module Pats
  module Categories
    module ScreenFailures
      # Defines ent requirement not met variable and associated subquery.
      class EntEligibilityNotMet < Default
        def label
          'ENT requirement not met'
        end

        # 'ciw_ent_eligibility_not_met'
        def variable_id
          14304
        end

        def subquery
          "#{database_value} = 1"
        end
      end
    end
  end
end
