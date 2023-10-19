# frozen_string_literal: true

module Api
  class AllocationApiController < Api::ApiController
    def show
      render_404('Not ready for allocation') && return if allocation.nil?
      render_404('Not allocated') && return unless offender_allocated?

      render json: both_poms
    end

    def primary_pom
      render_404('Not ready for allocation') && return if allocation.nil?
      render_404('Not allocated') && return unless offender_allocated?

      staff = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(allocation.primary_pom_nomis_id)

      render json: {
        manager: {
          code: staff.staff_id,
          forename: staff.first_name,
          surname: staff.last_name
        },
        prison: {
          code: allocation.prison
        }
      }
    end

  private

    def both_poms
      {
        primary_pom: primary_pom_details,
        secondary_pom: secondary_pom_details
      }
    end

    def primary_pom_details
      {
        staff_id: @allocation.primary_pom_nomis_id,
        name: PrisonOffenderManagerService.fetch_pom_name(@allocation.primary_pom_nomis_id)
      }
    end

    def secondary_pom_details
      return {} if @allocation.secondary_pom_nomis_id.blank?

      {
        staff_id: @allocation.secondary_pom_nomis_id,
        name: PrisonOffenderManagerService.fetch_pom_name(@allocation.secondary_pom_nomis_id)
      }
    end

    def offender_allocated?
      offender.present? && offender.inside_omic_policy? && allocation.active?
    end

    def allocation
      @allocation ||= AllocationHistory.find_by(nomis_offender_id: offender_number)
    end

    def offender
      @offender ||= OffenderService.get_offender(offender_number)
    end

    def offender_number
      params[:offender_no]
    end
  end
end
