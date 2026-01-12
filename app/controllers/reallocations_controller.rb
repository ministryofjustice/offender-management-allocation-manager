# frozen_string_literal: true

class ReallocationsController < AllocationStaffController
  skip_before_action :load_prisoner_via_prisoner_id

  before_action :load_pom
  before_action :load_new_pom, only: [:caseload]

  # rescue_from StandardError do |e|
  #   Rails.logger.error(e)
  #   Sentry.capture_exception(e)
  #   render :error
  # end

  # NOTE: below actions override slightly (main changes being the views)
  # the parent class controller `AllocationStaffController` to accommodate
  # the specific needs of the "bulk allocation" feature.
  # But many methods from the parent are still valid and used here.

  def index
    @available_poms = sort_collection(active_poms, default_sort: :last_name, default_direction: :asc)
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

  def error; end

private

  def load_pom
    @pom = StaffMember.new(@prison, params[:nomis_staff_id])

    if @pom.active? || @pom.unavailable?
      raise "not a valid POM! Prison #{@prison.code} - #{@pom.staff_id}"
    end
  end

  def load_new_pom
    @new_pom = StaffMember.new(@prison, params.fetch(:new_pom))

    unless @new_pom.active? && @new_pom.email_address.present?
      raise "not a valid POM! Prison #{@prison.code} - #{@new_pom.staff_id}"
    end
  end

  def check_compare_success_route
    compare_poms_prison_reallocation_path(pom_ids: params[:pom_ids])
  end

  def check_compare_error_route
    prison_reallocation_path
  end
end
