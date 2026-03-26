# frozen_string_literal: true

class ReallocationsController < AllocationStaffController
  skip_before_action :load_prisoner_via_prisoner_id

  before_action :load_pom
  before_action :load_new_pom, only: %i[caseload selected_cases]

  rescue_from StandardError do |e|
    Rails.logger.error(e)
    Sentry.capture_exception(e)
    render :error
  end

  # NOTE: below actions override slightly (main changes being the views)
  # the parent class controller `AllocationStaffController` to accommodate
  # the specific needs of the "bulk allocation" feature.
  # But many methods from the parent are still valid and used here.

  def index
    @available_poms = active_poms.sort_by(&:full_name_ordered)
  end

  def check_compare_list
    super
  end

  def compare_poms
    @poms = params[:pom_ids].map { |staff_id| StaffMember.new(@prison, staff_id) }
  end

  def caseload
    @allocations = @pom.allocations.select(&:primary_pom?)
  end

  # TODO: this is just a placeholder, yet to be implemented, action name is TBD
  def selected_cases
    nomis_offender_ids = Array(params[:nomis_offender_ids]).compact_blank

    if nomis_offender_ids.empty?
      head :unprocessable_entity and return
    end

    redirect_to(
      caseload_prison_reallocation_path(new_pom: @new_pom.staff_id),
      notice: 'Selected cases received. Bulk reallocation is not implemented yet.'
    )
  end

  def error; end

private

  def load_pom
    @pom = StaffMember.new(@prison, params[:nomis_staff_id])

    unless @pom.inactive? || @pom.in_limbo?
      raise "error: not an inactive POM! Prison #{@prison.code} - #{@pom.staff_id}"
    end
  end

  def load_new_pom
    @new_pom = StaffMember.new(@prison, params.fetch(:new_pom))

    unless @new_pom.active? && @new_pom.has_pom_role?
      raise "error: not an active POM! Prison #{@prison.code} - #{@new_pom.staff_id}"
    end
  end

  def check_compare_success_route
    compare_poms_prison_reallocation_path(pom_ids: params[:pom_ids])
  end

  def check_compare_error_route
    prison_reallocation_path
  end
end
