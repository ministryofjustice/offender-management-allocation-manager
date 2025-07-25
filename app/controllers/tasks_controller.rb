# frozen_string_literal: true

class TasksController < PrisonsApplicationController
  before_action :ensure_pom
  before_action :load_pom

  def index
    offenders = @current_user.allocations
    sorted_tasks = sort_tasks(offenders.map(&:pom_tasks).flatten)
    @pomtasks = paginate_array(sorted_tasks)
  end

private

  def sort_tasks(tasks)
    if params['sort'].present?
      sort_field, sort_direction = params['sort'].split.map(&:to_sym)
    else
      sort_field = :offender_name
      sort_direction = :asc
    end

    # cope with nil values by sorting using to_s - only dates and strings in these fields
    sorted_tasks = tasks.sort_by { |task| task.public_send(sort_field).to_s }
    sorted_tasks.reverse! if sort_direction == :desc

    sorted_tasks
  end

  def load_pom
    poms_list = @prison.get_list_of_poms

    @pom = poms_list.find { |p| p.staff_id.to_i == current_staff_id }
  end
end
