module Api
  class SarController < Api::ApiController
    SAR_ROLE = 'ROLE_SAR_DATA_ACCESS'.freeze
    MPC_ADMIN_ROLE = 'ROLE_MPC_ADMIN'.freeze

    def show
      return render_error('PRN and CRN parameters passed', 2, 400) if parameter_conflict?
      return render_error('CRN parameter not allowed', 3, 209) if only_crn?
      return render_error('Invalid date format', 4, 210) unless parse_dates

      result = SarOffenderDataService.new(offender_number, @from_date, @to_date).find
      return not_found if result.nil?

      render json: { content: result }
    end

  private

    # Overrides parent due to endpoint-specific roles
    def verify_token
      unless token.valid?
        return render_error('Valid authorisation token required', 1, 401)
      end

      unless token.valid_token_with_scope?('read', role: SAR_ROLE) ||
             token.valid_token_with_scope?('read', role: MPC_ADMIN_ROLE)
        render_error('Invalid token role', 5, 403)
      end
    end

    # Overrides parent due to endpoint-specific error schema
    def render_error(msg, error_code, status)
      render json: {
        developerMessage: msg,
        errorCode: error_code,
        status: status,
        userMessage: msg }, status: status.to_s
    end

    def not_found
      head :no_content
    end

    def offender_number
      params[:prn]
    end

    def crn
      params[:crn]
    end

    def parameter_conflict?
      crn.present? && offender_number.present?
    end

    def only_crn?
      crn.present? && offender_number.blank?
    end

    def parse_dates
      if params[:fromDate].blank? || params[:toDate].blank?
        @from_date = nil
        @to_date = nil
      else
        @from_date = Date.parse(params[:fromDate])
        @to_date = Date.parse(params[:toDate])
      end

      true
    rescue Date::Error
      false
    end
  end
end
