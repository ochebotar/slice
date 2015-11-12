# Handles authentication for filling out a series of designs on an event
class Handoff < ActiveRecord::Base
  # Callbacks
  after_create :set_token

  # Model Validation
  validates :user_id, :project_id, :subject_event_id, presence: true
  validates :token, uniqueness: { scope: :project_id }, allow_nil: true
  validates :subject_event_id, uniqueness: { scope: :project_id }

  # Model Relationships
  belongs_to :user
  belongs_to :project
  belongs_to :subject_event

  # Model Methods

  def to_param
    "#{id}-#{token}"
  end

  def self.find_by_param(input)
    clean_input = input.to_param.to_s
    handoff_id = clean_input.split('-').first
    handoff_token = clean_input.gsub(/^#{handoff_id}-/, '')
    handoff = Handoff.find_by_id handoff_id
    # Use Devise.secure_compare to mitigate timing attacks
    handoff if handoff && Devise.secure_compare(handoff.token, handoff_token)
  end

  def next_design(design)
    number = handoff_enabled_event_designs.pluck(:design_id).index(design.id)
    event_design = handoff_enabled_event_designs[number + 1] if number
    event_design.design if event_design
  end

  def handoff_enabled_event_designs
    subject_event.event.event_designs.where(handoff_enabled: true)
  end

  def remaining_handoff_event_designs
    handoff_enabled_event_designs
  end

  def set_token
    return unless token.blank?
    update token: SecureRandom.hex(8)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    retry
  end
end