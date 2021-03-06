# frozen_string_literal: true

require 'pats/characteristics/default'

module Pats
  module Characteristics
    # Defines eligibility and associated categories and subqueries.
    class Eligibility < Default
      def label
        'Eligibility Status'
      end

      # 'ciw_eligible_for_baseline'
      def variable_id
        14299
      end

      def categories
        [
          Pats::Categories.for('fully-eligible', project),
          Pats::Categories.for('ineligible', project),
          Pats::Categories.for('caregiver-not-interested', project),
          Pats::Categories.for('eligibility-unknown', project)
        ]
      end
    end
  end
end
