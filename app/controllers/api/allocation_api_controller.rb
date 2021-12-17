# frozen_string_literal: true

module Api
  class AllocationApiController < Api::ApiController
    def show
      render_404('Not ready for allocation') && return if allocation.nil?

      offender = OffenderService.get_offender(offender_number)

      if offender.nil? || !allocation.active? || !offender.inside_omic_policy?
        return render_404('Not allocated')
       end

      render json: allocation_as_json
    end

  private

    def allocation_as_json
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

    def allocation
      @allocation ||= AllocationHistory.find_by(nomis_offender_id: offender_number)
    end

    def offender_number
      params[:offender_no]
    end
  end
end
