# frozen_string_literal: true

class CaseloadController < PrisonStaffApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_and_validate_pom, :pom_allocations_summary

  def index; end

  def cases; end

  def parole_cases; end

  def updates_required
    tasks = @pom.pom_tasks.map { PomTaskPresenter.for(it) }
    @pom_tasks = paginate_array(tasks)
  end
end
