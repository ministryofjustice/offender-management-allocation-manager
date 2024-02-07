module Api
  class SarController < Api::ApiController
    SAR_ROLE = 'ROLE_SAR_DATA_ACCESS'.freeze
    MPC_ADMIN_ROLE = 'ROLE_MPC_ADMIN'.freeze

    def show
      return render_error('PRN and CRN parameters passed', 2, 400) if parameter_conflict?
      return render_error('CRN parameter not allowed', 3, 209) if only_crn?
      return not_found if offender.nil?

      render json: offender_data
    end

  private

    # Overrides parent due to endpoint-specific roles
    def verify_token
      unless token.valid_token_with_scope?('read', role: SAR_ROLE) ||
             token.valid_token_with_scope?('read', role: MPC_ADMIN_ROLE)
        render_error('Valid authorisation token required', 1, 401)
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

    def offender
      @offender ||= Offender.find_by(nomis_offender_id: offender_number)
    end

    def offender_data
      {
        content: {
          nomsNumber: offender_number,
          allocationHistory: allocation_with_history,
          auditEvents: jsonify_keys(AuditEvent.where(nomis_offender_id: offender_number)),
          calculatedEarlyAllocationStatus: jsonify_keys(CalculatedEarlyAllocationStatus.where(nomis_offender_id: offender_number)).first,
          calculatedHandoverDate: jsonify_keys(CalculatedHandoverDate.where(nomis_offender_id: offender_number)).first,
          caseInformation: jsonify_keys(CaseInformation.where(nomis_offender_id: offender_number)).first,
          earlyAllocations: jsonify_keys(EarlyAllocation.where(nomis_offender_id: offender_number)),
          emailHistories: jsonify_keys(EmailHistory.where(nomis_offender_id: offender_number)),
          handoverProgressChecklist: jsonify_keys(HandoverProgressChecklist.where(nomis_offender_id: offender_number)).first,
          offenderEmailSent: jsonify_keys(OffenderEmailSent.where(nomis_offender_id: offender_number)),
          paroleRecord: jsonify_keys(ParoleRecord.where(nomis_offender_id: offender_number)).first,
          paroleReviewImports: jsonify_keys(ParoleReviewImport.where(nomis_id: offender_number)),
          responsibility: jsonify_keys(Responsibility.where(nomis_offender_id: offender_number)).first,
          victimLiaisonOfficers: jsonify_keys(VictimLiaisonOfficer.where(nomis_offender_id: offender_number)),
        }
      }
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

    def jsonify_keys(collection)
      return [] if collection.none?

      exclude_attributes = %w[id nomis_offender_id nomis_id]

      collection.map do |item|
        item.attributes
            .reject { |key, _val| exclude_attributes.include?(key) }
            .deep_transform_keys { |key| key.camelcase(:lower) }
      end
    end

    def allocation_with_history
      allocation = AllocationHistory.find_by(nomis_offender_id: offender_number)
      return [] if allocation.nil?

      jsonify_keys([allocation] + allocation.get_old_versions)
    end
  end
end
