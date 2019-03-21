class CaseloadController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Your caseload', :caseload_index_path, only: [:new]
  breadcrumb -> { 'Your caseload' },
    -> { caseload_index_path }, only: [:index]
  breadcrumb -> { 'New cases' },
    -> { new_caseload_path }, only: [:new]

  def index
    @pom = PrisonOffenderManagerService.
        get_signed_in_pom_details(current_user, active_caseload)
    if @pom.present?
      @allocations = PrisonOffenderManagerService.get_allocated_offenders(
        @pom.staff_id, active_caseload
      )
      @new_cases = PrisonOffenderManagerService.get_new_cases(
        @pom.staff_id, active_caseload
      )
    end
  end

  def new
    @pom = PrisonOffenderManagerService.
        get_signed_in_pom_details(current_user, active_caseload)
    if @pom.present?
      @new_cases = PrisonOffenderManagerService.get_new_cases(
        @pom.staff_id, active_caseload
      )
    end
  end
end
