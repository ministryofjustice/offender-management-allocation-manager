# frozen_string_literal: true

module Reallocations
  class SelectionController < BaseController
    before_action :load_pom, except: %i[error]
    before_action :load_new_pom, only: %i[caseload create]

    # NOTE: some of these actions override slightly (mostly view changes)
    # the parent class controller `AllocationStaffController` to accommodate
    # the specific needs of the "bulk reallocation" feature.
    # But many methods from the parent are still valid and used here.

    def index
      @available_poms = active_poms.sort_by(&:full_name_ordered)
    end

    # NOTE: do not remove this override, it is here for explicitness
    def check_compare_list
      super
    end

    # NOTE: do not remove this override, it is here for explicitness
    def compare_poms
      super
    end

    def caseload
      @allocations = primary_allocations
    end

    def create
      selected_cases = selected_cases_from_params

      if selected_cases.empty?
        redirect_to caseload_prison_reallocation_path(**reallocation_route_params),
                    alert: 'Choose at least one case to reallocate.' and return
      end

      clear_bulk_reallocation_confirmation!

      journey = BulkReallocationJourney.new(
        source_pom_id: @pom.staff_id,
        target_pom_id: @new_pom.staff_id,
        selected_offender_ids: selected_cases.map(&:nomis_offender_id),
        override_offender_ids: selected_cases.reject { it.recommended_pom_type == @new_pom.position }.map(&:nomis_offender_id),
        overrides: {},
      )
      store_bulk_reallocation_journey!(journey)

      redirect_to next_reallocation_step_path(journey)
    end

    def error; end

  private

    def available_poms
      active_poms
    end

    def check_compare_success_route
      compare_poms_prison_reallocation_path(pom_ids: params[:pom_ids])
    end

    def check_compare_error_route
      prison_reallocation_path
    end

    def selected_cases_from_params
      offender_ids = Array(params[:nomis_offender_ids]).compact_blank
      primary_allocations.select { offender_ids.include?(it.nomis_offender_id) }
    end
  end
end
