# frozen_string_literal: true

class ProcessDeliusDataJob < ApplicationJob
  queue_as :default

  # HTTP 404 Not Found: Not much point retrying a missing offender
  discard_on Faraday::ResourceNotFound

  # HTTP 409 Conflict: nDelius API fails like this when trying to read a duplicate offender - so don't retry here either
  discard_on Faraday::ConflictError

  include ApplicationHelper

  def perform(nomis_offender_id)
    ApplicationRecord.transaction do
      logger.info("[DELIUS] Processing delius data for #{nomis_offender_id}")

      DeliusImportError.where(nomis_offender_id: nomis_offender_id).destroy_all

      import_data(nomis_offender_id)
    end
  end

private

  def import_data(nomis_offender_id)
    probation_record = OffenderService.get_probation_record(nomis_offender_id)

    return logger.error("[DELIUS] Failed to retrieve probation record for #{nomis_offender_id}") if probation_record.nil?

    offender = OffenderService.get_offender(nomis_offender_id)

    return logger.error("[DELIUS] Failed to retrieve NOMIS record #{nomis_offender_id}") if offender.nil?

    process_record(probation_record, nomis_offender_id) if offender.inside_omic_policy?
  end

  def process_record(probation_record, nomis_offender_id)
    prisoner = Offender.find_by!(nomis_offender_id: nomis_offender_id)
    case_information_before = prisoner.case_information || prisoner.build_case_information
    case_information_after = map_delius_to_case_info(probation_record, case_information_before)

    if case_information_after.changed?
      if case_information_after.save
        # Recalculate the offender's handover dates
        RecalculateHandoverDateJob.perform_later(nomis_offender_id)

        AuditEvent.publish(
          nomis_offender_id: nomis_offender_id,
          tags: %w[job process_delius_data_job case_information changed],
          system_event: true,
          data: {
            'before' => case_information_before.attributes.except('id', 'created_at', 'updated_at'),
            'after' => case_information_after.attributes.except('id', 'created_at', 'updated_at')
          }
        )
      else
        case_information_after.errors.each do |error|
          DeliusImportError.create! nomis_offender_id: nomis_offender_id,
                                    error_type: error_type(error.attribute)
        end
      end
    end
  end

  def map_delius_to_case_info(probation_record, orig_case_information)
    ldu_code = probation_record.dig(:manager, :team, :local_delivery_unit, :code)

    orig_case_information.tap do |case_info|
      case_info.assign_attributes(
        manual_entry: false,
        com_name: com_name(probation_record),
        com_email: probation_record.dig(:manager, :email),
        crn: probation_record.fetch(:crn),
        tier: map_tier(probation_record.fetch(:tier)),
        local_delivery_unit: map_ldu(ldu_code),
        ldu_code: ldu_code,
        team_name: probation_record.dig(:manager, :team, :description),
        enhanced_resourcing: probation_record.fetch(:resourcing).upcase == 'ENHANCED',
        probation_service: map_probation_service(ldu_code),
        mappa_level: probation_record.fetch(:mappa_level),
        active_vlo: probation_record.fetch(:vlo_assigned)
      )
    end
  end

  def com_name(probation_record)
    return nil unless probation_record.dig(:manager, :name)

    forename = probation_record.dig(:manager, :name, :forename)
    surname = probation_record.dig(:manager, :name, :surname)

    "#{surname}, #{forename}"
  end

  # map the LDU regardless of enabled switch, but only expose it from offender when enabled
  def map_ldu(ldu_code)
    LocalDeliveryUnit.find_by(code: ldu_code)
  end

  def map_probation_service(ldu_code)
    LocalDeliveryUnit.find_by(code: ldu_code)&.country || 'England'
  end

  def map_tier(tier)
    tier[0] if tier.present?
  end

  def error_type(field)
    {
      tier: DeliusImportError::INVALID_TIER,
      case_allocation: DeliusImportError::INVALID_CASE_ALLOCATION,
      local_delivery_unit: DeliusImportError::MISSING_LDU,
      team: DeliusImportError::MISSING_TEAM
    }.fetch(field)
  end
end
