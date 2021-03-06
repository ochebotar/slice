# frozen_string_literal: true

# Allows site editors to request that an auto-locked sheet be unlocked. The
# unlock request also requires the reason behind the request.
class SheetUnlockRequest < ApplicationRecord
  # Triggers
  after_create_commit :send_unlock_request_emails_in_background, :create_notifications

  # Concerns
  include Deletable
  include Forkable

  # Validations
  validates :user_id, :sheet_id, :reason, presence: true

  # Relationships
  belongs_to :user
  belongs_to :sheet
  has_many :notifications

  # Methods
  delegate :project_editors, to: :sheet

  def send_unlock_request_emails_in_background
    fork_process(:send_unlock_request_emails)
  end

  def send_unlock_request_emails
    return unless EMAILS_ENABLED
    project_editors.each do |editor|
      next unless sheet.project.emails_enabled?(editor)
      UserMailer.sheet_unlock_request(self, editor).deliver_now
    end
  end

  def destroy
    super
    notifications.destroy_all
  end

  private

  def create_notifications
    project_editors.each do |u|
      u.notifications.create(
        project_id: sheet.project_id, sheet_unlock_request_id: id
      )
    end
    true
  end
end
