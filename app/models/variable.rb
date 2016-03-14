# frozen_string_literal: true

class Variable < ApplicationRecord
  TYPE = %w(dropdown checkbox radio string text integer numeric date time time_duration file calculated grid signature).sort.collect { |i| [i, i] }
  TYPE_IMPORTABLE = %w(string text integer numeric date time).sort.collect { |i| [i, i] }
  TYPE_DOMAIN = %w(dropdown checkbox radio integer numeric)
  DISPLAY_NAME_VISIBILITY = [['Inline', 'visible'], ['Above - Indented', 'invisible'], ['Above - Full', 'gone']]
  ALIGNMENT = [['Horizontal', 'horizontal'], ['Vertical', 'vertical'], ['Scale', 'scale']]

  serialize :grid_variables, Array

  # Triggers
  before_save :check_for_duplicate_variables, :check_for_valid_domain
  attr_accessor :questions
  after_save :create_variables_from_questions

  # Concerns
  include Searchable, Deletable, DateAndTimeParser

  # Named Scopes
  scope :with_user, -> (arg) { where user_id: arg }
  scope :with_project, -> (arg) { where project_id: arg }
  scope :with_variable_type, -> (arg) { where variable_type: arg }
  scope :without_variable_type, -> (arg) { where 'variables.variable_type NOT IN (?)', arg }

  # Model Validation
  validates :name, :display_name, :variable_type, :project_id, presence: true
  validates :name, format: { with: /\A[a-z]\w*\Z/i }, length: { maximum: 32 }
  validates :name, uniqueness: { scope: [:deleted, :project_id] }

  # Model Relationships
  belongs_to :user
  belongs_to :project
  belongs_to :domain
  has_many :sheet_variables
  has_many :grids
  has_many :responses
  belongs_to :updater, class_name: 'User', foreign_key: 'updater_id'
  has_many :design_options, -> { order :position }
  has_many :designs, through: :design_options

  # Model Methods

  def self.searchable_attributes
    %w(name description display_name)
  end

  def create_variables_from_questions
    return unless variable_type == 'grid' && questions.present?
    new_grid_variables = []
    questions.select { |hash| hash[:question_name].present? }.each do |question_hash|
      question_hash = question_hash.symbolize_keys
      name = question_hash[:question_name].to_s.downcase
                                          .gsub(/[^a-zA-Z0-9]/, '_')
                                          .gsub(/^[\d_]/, 'n')
                                          .gsub(/_{2,}/, '_')
                                          .gsub(/_$/, '')[0..31].strip
      name = "var_#{SecureRandom.hex(12)}" if project.variables.where(name: name).size != 0
      new_variable_type = if Design::QUESTION_TYPES.collect(&:second).include?(question_hash[:question_type])
                            question_hash[:question_type]
                          else
                            'string'
                          end
      params = {
        variable_type: new_variable_type,
        name: name,
        display_name: question_hash[:question_name]
      }
      variable = project.variables.create(params)
      new_grid_variables << { variable_id: variable.id } if variable && !variable.new_record?
    end

    self.questions = nil
    update grid_variables: new_grid_variables.uniq.compact
  end

  def shared_options
    domain ? domain.options : []
  end

  def shared_options_with_user(current_user)
    return shared_options unless current_user
    site_ids = current_user.all_editable_sites.where(project_id: project_id).pluck(:id)
    shared_options.select { |opt| opt[:site_id].blank? || site_ids.include?(opt[:site_id].to_i) }
  end

  def autocomplete_array
    autocomplete_values.to_s.split(/[\n\r]/).collect(&:strip).reject(&:blank?)
  end

  def uses_scale?
    %w(radio checkbox).include?(variable_type) && alignment == 'scale'
  end

  # Use inherited designs to include grid variables
  def inherited_designs
    variable_ids = Variable.current.where(project_id: project_id, variable_type: 'grid').select { |v| v.grid_variable_ids.include?(id) }.collect(&:id) + [id]
    Design.current.where(project_id: project_id).select { |d| (d.variables.pluck(:id) & variable_ids).size > 0 }.sort_by(&:name)
  end

  def editable_by?(current_user)
    current_user.all_variables.where(id: id).count == 1
  end

  def copyable_attributes
    self.attributes.reject { |key, val| %w(id user_id deleted created_at updated_at).include?(key.to_s) }
  end

  # Includes responses, grids, and sheet_variables
  def captured_values
    @captured_values ||= begin
      (sheet_variables.pluck(:response) + grids.pluck(:response) + responses.pluck(:value)).uniq.reject(&:blank?)
    end
  end

  def check_for_valid_domain
    result = true
    d = (domain ? domain : Domain.new)
    if has_domain? and (captured_values | d.values).size > d.values.size and not ['integer', 'numeric'].include?(self.variable_type)
      errors.add(:domain_id, 'must include all previously captured values')
      result = false
    end
    result
  end

  def check_for_duplicate_variables
    result = true
    variable_ids = grid_variables.collect { |grid_variable| grid_variable[:variable_id] }
    if variable_ids.uniq.size < variable_ids.size
      errors.add(:grid, 'variables must be unique')
      result = false
    end
    result
  end

  def range_tooltip
    result = ''
    minimum = hard_minimum || soft_minimum
    maximum = hard_maximum || soft_maximum
    with_units = (units.blank? ? '' : " #{units}")
    if !minimum.blank? && !maximum.blank?
      result = "[#{minimum}, #{maximum}]" + with_units
    elsif minimum.blank? && !maximum.blank?
      result = "<= #{maximum}" + with_units
    elsif maximum.blank? && !minimum.blank?
      result = ">= #{minimum}" + with_units
    end
    result
  end

  def grid_tokens=(tokens)
    self.grid_variables = []
    tokens.each do |grid_hash|
      self.grid_variables << { variable_id: grid_hash[:variable_id].strip.to_i } if grid_hash[:variable_id].strip.to_i > 0
    end
  end

  def grid_variable_ids
    grid_variables.collect { |gv| gv[:variable_id] }
  end

  def missing_codes
    shared_options.select { |opt| opt[:missing_code] == '1' }.collect { |opt| opt[:value] }
  end

  def first_scale_variable?(design)
    return true unless design

    position = design.design_options.pluck(:variable_id).index(id)
    if position && position > 0
      design_option = design.design_options[position - 1]
      previous_variable = design_option.variable
    end
    # While this could just compare the variable domains, comparing the shared options allows scales with different domains (that have the same options) to still stack nicely on a form
    if previous_variable && previous_variable.uses_scale? && previous_variable.shared_options == shared_options
      return false
    else
      return true
    end
  end

  def options_missing_at_end(current_user = nil)
    options_without_missing(current_user) + options_only_missing(current_user)
  end

  def options_without_missing(current_user = nil)
    shared_options_with_user(current_user).select { |opt| opt[:missing_code] != '1' }
  end

  def options_only_missing(current_user = nil)
    shared_options_with_user(current_user).select { |opt| opt[:missing_code] == '1' }
  end

  def grouped_by_missing(show_values, current_user = nil)
    [['', options_without_missing(current_user).collect { |opt| [[(show_values ? opt[:value] : nil), opt[:name]].compact.join(': '), opt[:value]] }], ['Missing', options_only_missing(current_user).collect { |opt| [[(show_values ? opt[:value] : nil), opt[:name]].compact.join(': '), opt[:value]] }]]
  end

  def options_or_autocomplete(include_missing)
    if variable_type == 'string'
      NaturalSort.sort(autocomplete_array.reject(&:blank?).collect { |val| { name: val, value: val } }) + NaturalSort.sort(user_submitted_sheet_variables.collect { |sv| { name: sv.response, value: sv.response, info: 'User Submitted' } }.uniq { |a| a[:value].downcase })
    else
      (include_missing ? shared_options : options_without_missing)
    end
  end

  # Responses that are user submitted and not on autocomplete list
  def user_submitted_sheet_variables
    sheet_variables.reject { |sv| autocomplete_array.include?(sv.response.to_s.strip) || sv.response.to_s.strip.blank? }
  end

  def formatted_calculation
    calculation.to_s.gsub(/\?|\:/, '<br/>&nbsp;\0<br/>').html_safe
  end

  def statistics?
    %w(integer numeric calculated).include?(variable_type)
  end

  def has_domain?
    %w(dropdown checkbox radio integer numeric).include?(variable_type)
  end

  def report_strata(include_missing, max_strata, hash, sheet_scope)
    strata = base_strata(sheet_scope, include_missing, hash)
    strata << unknown_filter if include_missing && !%w(site sheet_date).include?(variable_type)
    strata.collect! { |s| s.merge(calculator: self, variable_id: id ? id : name) }
    strata.last(max_strata)
  end

  def base_strata(sheet_scope, include_missing, hash)
    if statistics? && hash[:axis] == 'col'
      statistic_filters
    elsif %w(dropdown radio string checkbox).include?(variable_type)
      domain_filters(sheet_scope, include_missing)
    elsif variable_type == 'design'
      design_filters
    elsif variable_type == 'site'
      site_filters
    elsif %w(sheet_date date).include?(variable_type)
      date_filters(sheet_scope, hash)
    else # Create a Filter that shows if the variable is present.
      presence_filters(hash)
    end
  end

  def statistic_filters
    [
      { filters: [], name: 'N',      tooltip: 'N',      calculation: 'array_count'                            },
      { filters: [], name: 'Mean',   tooltip: 'Mean',   calculation: 'array_mean'                             },
      { filters: [], name: 'StdDev', tooltip: 'StdDev', calculation: 'array_standard_deviation', symbol: 'pm' },
      { filters: [], name: 'Median', tooltip: 'Median', calculation: 'array_median'                           },
      { filters: [], name: 'Min',    tooltip: 'Min',    calculation: 'array_min'                              },
      { filters: [], name: 'Max',    tooltip: 'Max',    calculation: 'array_max'                              }
    ]
  end

  def domain_filters(sheet_scope, include_missing)
    unique_responses = unique_responses_for_sheets(sheet_scope)
    options_or_autocomplete(include_missing)
      .select { |h| unique_responses.include?(h[:value]) }
      .collect { |h| h.merge(filters: [{ variable_id: id, value: h[:value] }], tooltip: h[:name]) }
  end

  def design_filters
    project.designs.order(:name).collect do |design|
      {
        filters: [{ variable_id: 'design', value: design.id.to_s }],
        name: design.name,
        tooltip: design.name,
        link: "projects/#{project_id}/reports/designs/#{design.id}/advanced",
        value: design.id.to_s,
        calculation: 'array_count'
      }
    end
  end

  def site_filters
    project.sites.order(:name).collect do |site|
      {
        filters: [{ variable_id: 'site', value: site.id.to_s }],
        name: site.name,
        tooltip: site.name,
        value: site.id.to_s,
        calculation: 'array_count'
      }
    end
  end

  def date_filters(sheet_scope, hash)
    date_buckets = generate_date_buckets(sheet_scope, hash[:by] || 'month')
    date_buckets.reverse! unless hash[:axis] == 'col'
    date_buckets.collect do |date_bucket|
      {
        filters: [{ variable_id: (id ? id : name),
                    start_date: date_bucket[:start_date],
                    end_date: date_bucket[:end_date] }],
        name: date_bucket[:name], tooltip: date_bucket[:tooltip],
        calculation: 'array_count',
        start_date: date_bucket[:start_date], end_date: date_bucket[:end_date]
      }
    end
  end

  def presence_filters(hash)
    display_name = "#{"#{hash[:variable].display_name} " if hash[:axis] == 'col'}Collected"
    [{ filters: [{ variable_id: id, value: ':any' }], name: display_name, tooltip: display_name }]
  end

  def unknown_filter
    { filters: [{ variable_id: id, value: ':missing' }], name: '', tooltip: 'Unknown', value: nil }
  end

  def unique_responses_for_sheets(sheet_scope)
    if variable_type == 'checkbox'
      sheet_scope.sheet_responses_for_checkboxes(self).uniq
    else
      sheet_scope.sheet_responses(self).uniq
    end
  end

  def edge_date(sheet_scope, method)
    if variable_type == 'sheet_date'
      sheet_scope.pluck(:created_at).send(method).to_date
    else
      Date.strptime(sheet_scope.sheet_responses(self).reject(&:blank?).send(method), '%Y-%m-%d')
    end
  rescue
    Time.zone.today
  end

  def min_date(sheet_scope)
    edge_date(sheet_scope, :min)
  end

  def max_date(sheet_scope)
    edge_date(sheet_scope, :max)
  end

  def generate_date_buckets(sheet_scope, by)
    max_length_of_time_in_years = 200
    min = min_date(sheet_scope)
    max = max_date(sheet_scope)
    date_buckets = []
    last_years = (min.year..max.year).last(max_length_of_time_in_years)
    case by
    when 'week'
      current_cweek = min.cweek
      last_years.each do |year|
        (current_cweek..Date.parse("#{year}-12-28").cweek).each do |cweek|
          start_date = Date.commercial(year, cweek) - 1.day
          end_date = Date.commercial(year, cweek) + 5.days
          date_buckets << { name: "Week #{cweek}", tooltip: "#{year} #{start_date.strftime('%m/%d')}-#{end_date.strftime('%m/%d')} Week #{cweek}", start_date: start_date, end_date: end_date }
          break if year == max.year && cweek == max.cweek
        end
        current_cweek = 1
      end
    when 'month'
      current_month = min.month
      last_years.each do |year|
        (current_month..12).each do |month|
          start_date = Date.parse("#{year}-#{month}-01")
          end_date = Date.parse("#{year}-#{month}-01").end_of_month
          date_buckets << { name: "#{Date::ABBR_MONTHNAMES[month]} #{year}", tooltip: "#{Date::MONTHNAMES[month]} #{year}", start_date: start_date, end_date: end_date }
          break if year == max.year && month == max.month
        end
        current_month = 1
      end
    when 'year'
      last_years.each do |year|
        start_date = Date.parse("#{year}-01-01")
        end_date = Date.parse("#{year}-12-31")
        date_buckets << { name: year.to_s, tooltip: year.to_s, start_date: start_date, end_date: end_date }
      end
    end
    date_buckets
  end

  def self.site(project_id)
    new project_id: project_id, name: 'site', display_name: 'Site', variable_type: 'site'
  end

  def self.sheet_date(project_id)
    new project_id: project_id, name: 'sheet_date', display_name: 'Sheet Date', variable_type: 'sheet_date'
  end

  def self.design(project_id)
    new project_id: project_id, name: 'design', display_name: 'Design', variable_type: 'design'
  end

  def sas_informat
    if %w(string file).include?(variable_type)
      '$500'
    elsif %w(date).include?(variable_type)
      'yymmdd10'
    elsif %w(time).include?(variable_type)
      'time8'
    elsif %w(time_duration).include?(variable_type)
      'time20'
    elsif %w(dropdown radio).include?(variable_type) && domain && !domain.all_numeric?
      '$500'
    elsif %w(numeric integer dropdown radio).include?(variable_type)
      'best32'
    else # elsif %w(text).include?(variable_type)
      '$5000'
    end
  end

  def sas_format
    sas_informat
  end

  def csv_column
    if variable_type == 'checkbox'
      shared_options.collect { |option| option_variable_name(option[:value]) }
    else
      name
    end
  end

  def sas_informat_definition
    if variable_type == 'checkbox'
      option_informat = (domain && !domain.all_numeric? ? '$500' : 'best32')
      shared_options.collect { |option| "  informat #{option_variable_name(option[:value])} #{option_informat}. ;" }
    else
      "  informat #{name} #{sas_informat}. ;"
    end
  end

  def sas_format_definition
    if variable_type == 'checkbox'
      option_format = (domain && !domain.all_numeric? ? '$500' : 'best32')
      shared_options.collect { |option| "  format #{option_variable_name(option[:value])} #{option_format}. ;" }
    else
      "  format #{name} #{sas_format}. ;"
    end
  end

  def sas_format_label
    if variable_type == 'checkbox'
      shared_options.collect { |option| "  label #{option_variable_name(option[:value])}='#{display_name.gsub("'", "''")} (#{option[:name].to_s.gsub("'", "''")})' ;" }
    else
      "  label #{name}='#{display_name.gsub("'", "''")}';"
    end
  end

  def sas_format_domain
    if domain
      case variable_type
      when 'checkbox'
        shared_options.collect { |option| "  format #{option_variable_name(option[:value])} #{domain.sas_domain_name}. ;" }
      else
        "  format #{name} #{domain.sas_domain_name}. ;"
      end
    else
      nil
    end
  end

  def option_variable_name(value)
    "#{name}__#{value.gsub(/[^a-zA-Z0-9_]/, '_')}".last(28)
  end

  def date_order
    case format
    when '%Y-%m-%d'
      %w(year month day)
    when '%d/%m/%Y'
      %w(day month year)
    else
      %w(month day year)
    end
  end

  def date_formatting(component)
    case component
    when 'month'
      ['mm', '%m']
    when 'day'
      ['dd', '%d']
    when 'year'
      ['yyyy', '%Y']
    end
  end

  def date_separator
    case format
    when '%Y-%m-%d'
      '-'
    else
      '/'
    end
  end

  # Validation Module

  def validator
    @validator ||= Validation.for(self)
  end

  def value_in_range?(value)
    validator.value_in_range?(value)
  end

  def response_to_value(response)
    validator.response_to_value(response)
  end

  def requirement_on_design(design)
    design_option = design_options.where(design_id: design.id).first
    if design_option
      design_option.required.blank? ? 'optional' : design_option.required
    else
      'optional'
    end
  end

  def validate_value(design, value)
    validation_hash = value_in_range?(value)
    requirement = requirement_on_design(design)

    if validation_hash[:status].in?(%w(invalid out_of_range)) || (validation_hash[:status] == 'blank' && requirement == 'required')
      'error'
    elsif (validation_hash[:status] == 'blank' && requirement == 'recommended') || (validation_hash[:status] == 'in_hard_range')
      'warning'
    else
      'valid'
    end
  end
end
