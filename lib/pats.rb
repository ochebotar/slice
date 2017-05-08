# frozen_string_literal: true

require 'pats/consented'
require 'pats/data_quality'
require 'pats/demographics'
require 'pats/eligibility_status'
require 'pats/eligible'
require 'pats/grades'
require 'pats/randomized'
require 'pats/screened'

# Helps export data from PATS project for display on patstrial.org.
module Pats
  include Pats::Consented
  include Pats::DataQuality
  include Pats::Demographics
  include Pats::EligibilityStatus
  include Pats::Eligible
  include Pats::Grades
  include Pats::Randomized
  include Pats::Screened
end
