# frozen_string_literal: true

# reports/designs/:design_id/          <= Basic Quick-Glance Report Statistics
# reports/designs/:design_id/overview  <= Overview Report
# reports/designs/:design_id/advanced  <= Advanced Configurable Report

# Displays basic, overview, and advanced reports for designs, as well as
# providing PDFs of the reports.
class Reports::DesignsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_viewable_project_or_redirect
  before_action :find_viewable_design

  # Concerns
  include Buildable

  # def basic
  # end

  # GET /reports/designs/1/overview
  def overview
    @sheets = current_user.all_viewable_sheets
                          .where(project_id: @project.id, design_id: @design.id)
                          .where(missing: false)
  end

  def advanced
    setup_report_new
    generate_table_csv_new if params[:format] == 'csv'
    generate_advanced_pdf if params[:format] == 'pdf'
  end

  protected

  def find_viewable_design
    @design = current_user.all_viewable_designs.find_by_param params[:id]
    redirect_without_design
  end

  def redirect_without_design
    empty_response_or_root_path(project_designs_path(@project)) unless @design
  end

  def generate_advanced_pdf
    pdf_location = generate_pdf_location
    if File.exist?(pdf_location)
      file_name = @report_title.gsub(' vs. ', ' versus ').gsub(/[^\da-zA-Z ]/, '')
      send_file pdf_location,
                filename: "#{file_name} #{Time.zone.now.strftime('%Y.%m.%d %Ih%M %p')}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
    else
      redirect_to project_reports_design_advanced_path(@project, @design), alert: 'Unable to generate PDF.'
    end
  end

  def generate_pdf_location
    orientation = %w(portrait landscape).include?(params[:orientation].to_s) ? params[:orientation].to_s : 'portrait'
    @design.latex_report_new_file_location(
      current_user, orientation, @report_title, @report_subtitle,
      @report_caption, @percent, @table_header, @table_body, @table_footer
    )
  end
end