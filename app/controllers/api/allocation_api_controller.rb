# frozen_string_literal: true

module Api
  class AllocationApiController < Api::ApiController
    def show
      render_404('Not ready for allocation') && return if allocation.nil?
      render_404('Not allocated') && return if allocation.primary_pom_nomis_id.nil?

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
        name: helpers.fetch_pom_name(@allocation.primary_pom_nomis_id)
      }
    end

    def secondary_pom_details
      return {} if @allocation.secondary_pom_nomis_id.blank?

      {
        staff_id: @allocation.secondary_pom_nomis_id,
        name: helpers.fetch_pom_name(@allocation.primary_pom_nomis_id)
      }
    end

    def allocation
      @allocation ||= Allocation.find_by(nomis_offender_id: offender_number)
    end

    def offender_number
      params[:offender_no]
    end

    def fetch_pom_name(staff_id)
      pom_firstname, pom_secondname =
        PrisonOffenderManagerService.get_pom_name(staff_id)
      "#{pom_secondname}, #{pom_firstname}"
    end
  end
end
