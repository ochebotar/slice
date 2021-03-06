# frozen_string_literal: true

# Tracks a list of randomizations.
class List < ApplicationRecord
  # Serialized
  serialize :extra_options, Array

  # Concerns
  include Deletable

  attr_accessor :items

  # Scopes

  # Validations
  validates :project_id, :randomization_scheme_id, :user_id, presence: true

  # Relationships
  belongs_to :project
  belongs_to :randomization_scheme
  belongs_to :user
  has_many :list_options
  has_many :options, through: :list_options
  has_many :randomizations, -> { current }

  # Methods

  def name
    names = extra_option_names + option_names
    names.present? ? names.join(", ") : "List"
  end

  def option_names
    list_options.includes(:option).order("stratification_factor_options.stratification_factor_id").collect(&:name)
  end

  def extra_option_names
    project.sites.where(id: extra_options.collect { |h| h[:site_id] }).order(:name).collect(&:short_name)
  end

  def subject_randomizations
    randomizations.where.not(subject_id: nil)
  end

  def generate_all_block_groups_up_to!(current_user, max_block_group, multipliers, arms)
    current_block_group = next_block_group
    (current_block_group..max_block_group).each do |block_group|
      generate_block_group!(current_user, block_group, multipliers, arms)
    end
  end

  def generate_block_group!(current_user, block_group, multipliers, arms)
    list_position = next_list_position
    multipliers.shuffle.each do |multiplier|
      (arms * multiplier).shuffle.each do |treatment_arm_id|
        randomizations.create(
          project_id: project_id,
          randomization_scheme_id: randomization_scheme_id,
          user_id: current_user.id,
          position: list_position,
          treatment_arm_id: treatment_arm_id,
          block_group: block_group,
          multiplier: multiplier
        )
        list_position += 1
      end
    end
  end

  def next_list_position
    (randomizations.pluck(:position).max || 0) + 1
  end

  def next_block_group
    (randomizations.pluck(:block_group).max || 0) + 1
  end

  def criteria_match?(selected_criteria)
    selected_criteria.collect! { |sfid, oid| [sfid.to_i, oid.to_i] }.sort!
    criteria == selected_criteria
  end

  # Returns sorted list of criteria in key value pairs [stratification_factor_id and stratification_factor_value]
  # Stratification value can either be a stratification_factor_option_id or a site_id
  def criteria
    (option_pairs + extra_option_pairs).sort
  end

  def option_pairs
    options.pluck(:stratification_factor_id, :id)
  end

  def extra_option_pairs
    extra_options.collect { |h| [h[:stratification_factor_id].to_i, h[:site_id].to_i] }
  end

  def append_items!(items, current_user)
    return unless randomization_scheme.custom_list?
    items.to_s.split(/[\n\r]/).collect(&:squish).reject(&:blank?).each do |item|
      randomizations.create(
        project: randomization_scheme.project,
        randomization_scheme: randomization_scheme,
        user: current_user,
        custom_treatment_name: item
      )
    end
  end
end
