# frozen_string_literal: true

class TasksController < PrisonsApplicationController
  breadcrumb 'Case updates needed', ''

  before_action :ensure_pom

  def index
    @pomtasks = PomTasks.new(active_prison).tasks_for_offenders(caseload)
  end

private

  def caseload
    @caseload ||= PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    )
  end

  def ensure_pom
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user,
      active_prison
    )

    if @pom.blank?
      redirect_to '/'
    end
  end
end
