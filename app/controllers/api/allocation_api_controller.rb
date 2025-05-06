# frozen_string_literal: true

module Api
  class AllocationApiController < Api::ApiController
    rescue_from HmppsApi::Error::Unauthorized, with: :unauthorized_error

    before_action :check_allocation_status

    def show
      render json: {
        primary_pom: primary_pom_details,
        secondary_pom: secondary_pom_details
      }
    end

    def primary_pom
      staff = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(allocation.primary_pom_nomis_id)

      render json: {
        manager: {
          code: staff.staff_id,
          forename: staff.first_name,
          surname: staff.last_name,
          email: staff.email_address
        },
        prison: {
          code: allocation.prison
        }
      }
    end

  private

    def check_allocation_status
      if allocation.nil?
        render_404('Not ready for allocation')
      elsif !allocation.active?
        render_404('Not allocated')
      end
    end

    def primary_pom_details
      {
        staff_id: @allocation.primary_pom_nomis_id,
        name: @allocation.primary_pom_name
      }
    end

    def secondary_pom_details
      return {} if @allocation.secondary_pom_nomis_id.blank?

      {
        staff_id: @allocation.secondary_pom_nomis_id,
        name: @allocation.secondary_pom_name
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
