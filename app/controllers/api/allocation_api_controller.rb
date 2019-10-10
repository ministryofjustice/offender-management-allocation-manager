# frozen_string_literal: true

module Api
  class AllocationApiController < Api::ApiController

    def show
      render_404('Not ready for allocation') and return if allocation.nil?
      render_404('Not allocated') and return if allocation.primary_pom_nomis_id.nil?

      render json: allocation_as_json
    end

  private

    def allocation_as_json
      {
        primary_pom: primary_pom_details,
        secondary_pom: secondary_pom_details,
      }
    end

    def primary_pom_details
      {
        staff_id: @allocation.primary_pom_nomis_id,
        name: @allocation.primary_pom_name
      }
    end

    def secondary_pom_details
      return {} unless @allocation.secondary_pom_nomis_id.present?

      {
        staff_id: @allocation.secondary_pom_nomis_id,
        name: @allocation.secondary_pom_name
      }
    end

    def allocation
      @allocation = AllocationVersion.find_by(nomis_offender_id: offender_number)
    end

    def offender_number
      params[:offender_no]
    end
  end
end
