# frozen_string_literal: true

require 'pats/categories/default'

module Pats
  module Categories
    module Disinterested
      # Defines caregiver not interested in study participation.
      class CaregiverNotInterestedInStudyParticipation < Default
        def label
          'Caregiver not interested in study participation'
        end

        # 'ciw_caregiver_interested'
        def variable_id
          14300
        end

        def subquery
          "#{database_value} = 0"
        end
      end
    end
  end
end
