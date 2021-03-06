# frozen_string_literal: true

# Represents a single cell response for a grid variable. Defines the position
# (row), parent grid variable, and child variable.
class Grid < ApplicationRecord
  # Concerns
  include Formattable
  include Valuable

  # Scopes
  scope :with_files, -> { file_variables.where.not(response_file: [nil, ""]) }

  # Validations
  validates :sheet_variable_id, :position, presence: true

  # Relationships
  belongs_to :sheet_variable, touch: true
  belongs_to :user, optional: true
  belongs_to :domain_option, optional: true

  delegate :sheet_id, to: :sheet_variable
  delegate :sheet, to: :sheet_variable

  # Methods
  def self.file_variables
    joins(:variable).where(variables: { variable_type: "file" })
  end
end
