module Api
  class SarController < Api::ApiController
    SAR_ROLE = 'ROLE_SAR_DATA_ACCESS'.freeze

    after_action :log_successful_request, only: :show

    def template
      render plain: SubjectAccessRequestTemplateService.content, content_type: 'text/plain'
    end

    def show
      return render_error('PRN and CRN parameters must be strings', 10, 400) unless valid_identifier_types?
      return render_error('PRN and CRN parameters passed', 11, 400) if parameter_conflict?
      return render_error('PRN or CRN parameter required', 12, 400) if offender_number.blank? && crn.blank?
      return render_error('Invalid date format', 20, 400) unless parse_dates
      return render_error('fromDate must be on or before toDate', 22, 400) if @from_date && @from_date > @to_date
      return head 209 if only_crn?

      result = SarOffenderDataService.new(offender_number, @from_date, @to_date).find
      return head :no_content if result.nil?

      render json: { content: result }
    end

  private

    # Overrides parent due to endpoint-specific roles
    def verify_token
      unless token.valid?
        return render_error('Valid authorisation token required', 1, 401)
      end

      unless token.valid_token_with_scope?('read', role: SAR_ROLE)
        render_error('Invalid token role', 5, 403)
      end
    end

    # Overrides parent due to endpoint-specific error schema
    def render_error(msg, error_code, status)
      Rails.logger.warn(
        "event=subject_access_request_error,status=#{status},error_code=#{error_code},message=#{msg}"
      )

      render json: {
        developerMessage: msg,
        errorCode: error_code,
        status: status,
        userMessage: msg }, status: status.to_s
    end

    def log_successful_request
      return unless response.successful?

      Rails.logger.info(
        "event=subject_access_request_success,status=#{response.status},prn=#{offender_number}," \
          "from_date=#{@from_date},to_date=#{@to_date}"
      )
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

    def valid_identifier_types?
      [offender_number, crn].all? { |identifier| identifier.nil? || identifier.is_a?(String) }
    end

    def only_crn?
      crn.present? && offender_number.blank?
    end

    def parse_dates
      @from_date = parse_date(params[:fromDate])
      @to_date = parse_date(params[:toDate]) || Time.zone.today

      true
    rescue Date::Error
      false
    end

    def parse_date(value)
      return nil if value.nil? || value == ''

      raise Date::Error unless value.is_a?(String) && value.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)

      Date.iso8601(value)
    end
  end
end
