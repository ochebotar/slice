# frozen_string_literal: true

# Allows designs to be create via imports. Imports can also include the data
# associated to the designs to create and update existing sheets.
class ImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_editable_project_or_redirect
  before_action :find_design_or_redirect, only: [:progress, :edit, :update]

  # GET /designs/imports/new
  def new
    @design = @project.designs.new
    @variables = []
  end

  # POST /designs/1/imports/progress.js
  # def progress
  # end

  # GET /designs/1/imports/edit
  def edit
    @design.remove_csv_file!
    @design.update csv_file: nil
  end

  # POST /designs/1/imports
  def create
    @design = current_user.designs.where(project_id: @project.id).new(design_params)
    if params[:variables].blank?
      @design.errors.add(:csv_file, "must be selected") if @design.csv_file.blank?
    elsif @design.save
      @design.create_variables!(params[:variables])
      @design.generate_import_in_background(params[:site_id], current_user, request.remote_ip)
      redirect_to [@design.project, @design]
      return
    end
    @variables = @design.load_variables
    @design.name_from_csv!
    render :new
  end

  # PATCH /designs/1/imports
  def update
    @design.update(design_params)
    if params[:variables].blank?
      render :edit
    else
      @design.generate_import_in_background(params[:site_id], current_user, request.remote_ip)
      redirect_to [@design.project, @design]
    end
  end

  private

  def find_design_or_redirect
    @design = current_user.all_designs.where(project_id: @project.id).find_by_param(params[:id])
    redirect_without_design
  end

  def redirect_without_design
    empty_response_or_root_path(project_designs_path(@project)) unless @design
  end

  def design_params
    params[:design] ||= { blank: "1" }
    params.require(:design).permit(:name, :csv_file, :csv_file_cache, :reimport)
  end
end
