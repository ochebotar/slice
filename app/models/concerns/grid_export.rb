# frozen_string_literal: true

module GridExport
  extend ActiveSupport::Concern

  def generate_csv_grids(sheet_scope, filename, raw_data, folder)
    sheet_scope = sheet_scope.order(id: :desc)
    tmp_export_file = File.join('tmp', 'files', 'exports', "#{filename}_grids__#{raw_data ? 'raw' : 'labeled'}_tmp.csv")
    export_file = File.join('tmp', 'files', 'exports', "#{filename}_grids__#{raw_data ? 'raw' : 'labeled'}.csv")

    t = Time.zone.now
    design_ids = sheet_scope.select(:design_id)
    grid_group_variables = all_design_variables_using_design_ids(design_ids).where(variable_type: 'grid')

    sheet_ids = compute_sheet_ids_with_max_position(sheet_scope)

    CSV.open(tmp_export_file, 'wb') do |csv|
      csv << ['', 'Sheet ID'] + sheet_ids
      csv << ['', 'Name'] + grid_get_corresponding_names(sheet_ids, sheet_scope.joins(:design).pluck(:id, :name))
      csv << ['', 'Description'] + grid_get_corresponding_names(sheet_ids, sheet_scope.joins(:design).pluck(:id, :description))
      csv << ['', 'Sheet Creation Date'] + grid_get_corresponding_names(sheet_ids, sheet_scope.pluck(:id, :created_at).collect{ |id, s| [id, s.strftime('%Y-%m-%d')]})
      csv << ['', 'Project'] + grid_get_corresponding_names(sheet_ids, sheet_scope.joins(:project).pluck(:id, :name))
      csv << ['', 'Site'] + grid_get_corresponding_names(sheet_ids, sheet_scope.includes(subject: :site).collect { |s| [s.id, s.subject && s.subject.site ? s.subject.site.name : nil] })
      csv << ['', 'Subject'] + grid_get_corresponding_names(sheet_ids, sheet_scope.joins(:subject).pluck(:id, :subject_code))
      csv << ['', 'Acrostic'] + grid_get_corresponding_names(sheet_ids, sheet_scope.joins(:subject).pluck(:id, :acrostic))
      csv << ['', 'Status'] + grid_get_corresponding_names(sheet_ids, sheet_scope.joins(:subject).pluck(:id, :status))
      csv << ['', 'Creator'] + grid_get_corresponding_names(sheet_ids, sheet_scope.includes(:user).collect { |s| [s.id, s.user ? "#{s.user.first_name} #{s.user.last_name}" : nil] })
      csv << ['', 'Event Name'] + grid_get_corresponding_names(sheet_ids, sheet_scope.includes(subject_event: :event).collect { |s| [s.id, s.subject_event && s.subject_event.event ? s.subject_event.event.name : nil] })

      grid_group_variables.each do |grid_group_variable|
        grid_variables = grid_group_variable.project.variables.where(id: grid_group_variable.grid_variables.collect { |gv| gv[:variable_id] }).to_a
        grid_group_variable.grid_variables.each do |grid_variable_hash|
          v = grid_variables.find { |gv| gv.id == grid_variable_hash[:variable_id].to_i }
          next unless v
          if v.variable_type == 'checkbox'
            v.shared_options.each do |option|
              value = option[:value]
              sorted_responses = grid_sort_responses_by_sheet_id_for_checkbox(grid_group_variable, v, sheet_scope, sheet_ids, value)
              formatted_responses = format_responses(v, raw_data, sorted_responses)
              csv << [grid_group_variable.name, "#{v.name}__#{value}"] + formatted_responses
            end
          else
            sorted_responses = grid_sort_responses_by_sheet_id_generic(grid_group_variable, v, sheet_scope, sheet_ids)
            formatted_responses = format_responses(v, raw_data, sorted_responses)
            csv << [grid_group_variable.name, v.name] + formatted_responses
          end
        end
        update_steps(1) unless new_record? # TODO: Remove unless conditional
      end
    end
    transpose_tmp_csv(tmp_export_file, export_file)
    Rails.logger.debug "Total Time: #{Time.zone.now - t} seconds"
    ["#{folder.upcase}/#{export_file.split('/').last}", export_file]
  end

  def grid_get_corresponding_names(sheet_ids, ids_and_names)
    sheet_ids.collect do |sheet_id|
      ids_and_names.find { |v| v.first == sheet_id }.last
    end
  end

  def grid_sort_responses_by_sheet_id_for_checkbox(grid_group_variable, variable, sheet_scope, sheet_ids, value)
    responses = Response.joins(:grid)
                        .where(sheet_id: sheet_scope.select(:id), variable_id: variable.id, value: value)
                        .where.not(grid_id: nil)
                        .order(sheet_id: :desc).pluck(:value, :position, :sheet_id).uniq
    grid_sort_responses_by_sheet_id(grid_group_variable, responses, sheet_scope, sheet_ids)
  end

  def grid_sort_responses_by_sheet_id_generic(grid_group_variable, variable, sheet_scope, sheet_ids)
    responses = Grid.joins(:sheet_variable).merge(SheetVariable.where(sheet_id: sheet_scope.select(:id)))
                    .where(variable_id: variable.id)
                    .order('sheet_id desc', :position)
                    .pluck(:response, :position, :sheet_id).uniq
    grid_sort_responses_by_sheet_id(grid_group_variable, responses, sheet_scope, sheet_ids)
  end

  def grid_sort_responses_by_sheet_id(grid_group_variable, responses, sheet_scope, sheet_ids)
    sorted_responses = Array.new(sheet_ids.count)
    response_counter = 0
    current_sheet_position = nil
    last_sheet_id = nil
    sheet_ids.each_with_index do |sheet_id, index|
      if sheet_id == last_sheet_id
        current_sheet_position += 1
      else
        current_sheet_position = 0
      end
      response = responses[response_counter]
      if response && response[1] == current_sheet_position && response.last == sheet_id
        sorted_responses[index] = response.first
        response_counter += 1
      end
      last_sheet_id = sheet_id
    end
    sorted_responses
  end

  # Computes how many maximum grid rows per sheet need to be exported and
  # returns the sheet_ids in descending order
  def compute_sheet_ids_with_max_position(sheet_scope)
    highest_hash = {}
    all_positions = Grid.joins(:sheet_variable).merge(SheetVariable.where(sheet_id: sheet_scope.select(:id))).pluck(:sheet_id, :position)
    all_positions.each do |sheet_id, position|
      highest_hash[sheet_id.to_s] ||= 0
      highest_hash[sheet_id.to_s] = position if position > highest_hash[sheet_id.to_s]
    end
    highest_hash.collect { |sheet_id, position| [sheet_id.to_i] * (position + 1) }.flatten.sort.reverse
  end
end
