# frozen_string_literal: true

# Represents a request for more information made by an Adverse Event Admin to
# the Adverse Event Reporter(s).
class AeInfoRequest < ApplicationRecord
  # Validations
  validates :comment, presence: true

  # Relationships
  belongs_to :project
  belongs_to :ae_adverse_event
  belongs_to :user
  belongs_to :resolver, class_name: "User", foreign_key: "resolver_id", optional: true
  belongs_to :ae_team, optional: true

  # Methods
  def destroy
    AeLogEntryAttachment.where(
      attachment_type: self.class.to_s,
      attachment_id: id
    ).destroy_all
    super
  end

  def open!(current_user)
    ae_adverse_event.update sent_for_review_at: nil unless ae_team
    ae_adverse_event.ae_log_entries.create(
      project: project,
      ae_team: ae_team,
      user: current_user,
      entry_type: "ae_info_request_created",
      info_requests: [self]
    )
    # TODO: Generate in app notifications and LOG notifications to AENotificationsLog for Info Request (to "reporters of AE")
    # @info_request.log_info # TODO: Generate notifications and log entries
  end

  def resolved?
    !resolved_at.nil?
  end

  def resolve!(current_user)
    update(resolved_at: Time.zone.now, resolver: current_user)
    ae_adverse_event.ae_log_entries.create(
      project: project,
      ae_team: ae_team,
      user: current_user,
      entry_type: "ae_info_request_resolved",
      info_requests: [self]
    )
    # TODO: Generate in app notifications and LOG notifications to AENotificationsLog for Info Request (to "admins of AE, or info_request creator")
  end
end
