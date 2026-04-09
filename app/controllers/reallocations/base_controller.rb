# frozen_string_literal: true

module Reallocations
  class BaseController < AllocationStaffController
    BULK_REALLOCATION_SESSION_KEY = :bulk_reallocation
    BULK_REALLOCATION_CONFIRMATION_SESSION_KEY = :bulk_reallocation_confirmation

    skip_before_action :load_prisoner_via_prisoner_id

    unless Rails.env.development? || Rails.env.test?
      rescue_from StandardError, with: :handle_unexpected_error
    end

    def self.local_prefixes
      ['reallocations'] + super
    end

  private

    def reallocation_route_params
      {
        prison_id: @prison.code,
        nomis_staff_id: @pom.staff_id,
        new_pom: @new_pom.staff_id,
      }
    end

    def load_pom
      @pom = StaffMember.new(@prison, params[:nomis_staff_id])

      redirect_to error_prison_reallocation_path unless @pom.inactive? || @pom.in_limbo?
    end

    def load_new_pom
      @new_pom = StaffMember.new(@prison, params.fetch(:new_pom))

      redirect_to error_prison_reallocation_path unless @new_pom.active? && @new_pom.has_pom_role?
    end

    def next_reallocation_step_path(journey = @journey)
      if journey.pending_override_offender_ids.any?
        override_prison_reallocation_path(**reallocation_route_params, nomis_offender_id: journey.pending_override_offender_ids.first)
      else
        summary_prison_reallocation_path(**reallocation_route_params)
      end
    end

    def primary_allocations
      @primary_allocations ||= @pom.allocations.select(&:primary_pom?)
    end

    def primary_allocations_index
      @primary_allocations_index ||= primary_allocations.index_by(&:nomis_offender_id)
    end

    def bulk_reallocation_journey
      BulkReallocationJourney.new(session[BULK_REALLOCATION_SESSION_KEY])
    end

    def store_bulk_reallocation_journey!(journey)
      session[BULK_REALLOCATION_SESSION_KEY] = journey.to_h
    end

    def clear_bulk_reallocation_journey!
      session.delete(BULK_REALLOCATION_SESSION_KEY)
    end

    def store_bulk_reallocation_confirmation!(result)
      session[BULK_REALLOCATION_CONFIRMATION_SESSION_KEY] = result.to_confirmation
    end

    def clear_bulk_reallocation_confirmation!
      session.delete(BULK_REALLOCATION_CONFIRMATION_SESSION_KEY)
    end

    def clear_bulk_reallocation_state!
      clear_bulk_reallocation_journey!
      clear_bulk_reallocation_confirmation!
    end

    def handle_unexpected_error(error)
      Rails.logger.error(
        "event=bulk_reallocation_error,prison_id=#{@prison.code},source_pom_id=#{@pom&.staff_id}," \
        "target_pom_id=#{@new_pom&.staff_id},path=#{request.fullpath}|#{error.message}"
      )
      Sentry.capture_exception(error)
      render 'reallocations/error', status: :internal_server_error
    end
  end
end
