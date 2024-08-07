# frozen_string_literal: true

class ProcessDeliusDataJob < ApplicationJob
  queue_as :default

  # HTTP 404 Not Found: Not much point retrying a missing offender
  discard_on Faraday::ResourceNotFound

  # HTTP 409 Conflict: nDelius API fails like this when trying to read a duplicate offender - so don't retry here either
  discard_on Faraday::ConflictError

  include ApplicationHelper

  # identifier_type can be :nomis_offender_id (default), or :crn
  # trigger_method can be :batch (default), or :event
  def perform(identifier, identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil)
    ApplicationRecord.transaction do
      logger.info("#{identifier_type}=#{identifier},trigger_method=#{trigger_method},job=process_delius_data_job,event=started")
      import_data(identifier, identifier_type, trigger_method, event_type)
      logger.info("#{identifier_type}=#{identifier},trigger_method=#{trigger_method},job=process_delius_data_job,event=finished")
    end
  end

private

  def import_data(identifier, identifier_type, trigger_method, event_type)
    probation_record = OffenderService.get_probation_record(identifier)

    if probation_record.nil?
      logger.error(
        "#{identifier_type}=#{identifier},job=process_delius_data_job,event=missing_probation_record|" \
        'Failed to retrieve probation record'
      )

      return
    end

    if identifier_type == :crn
      nomis_offender_id = probation_record.fetch(:noms_id)

      if nomis_offender_id.blank?
        logger.error(
          "crn=#{identifier},job=process_delius_data_job,event=missing_offender_id|" \
          'Probation record does not have a NOMIS ID'
        )

        return
      end
    else
      nomis_offender_id = identifier
    end

    offender = OffenderService.get_offender(nomis_offender_id)

    if offender.nil?
      logger.error(
        "nomis_offender_id=#{nomis_offender_id},job=process_delius_data_job,event=missing_offender_record|" \
        'Failed to retrieve NOMIS offender record'
      )

      return
    end

    process_record(probation_record, nomis_offender_id, trigger_method, event_type) if offender.inside_omic_policy?
  end

  def process_record(probation_record, nomis_offender_id, trigger_method, event_type)
    DeliusImportError.where(nomis_offender_id: nomis_offender_id).destroy_all

    prisoner = Offender.find_by!(nomis_offender_id: nomis_offender_id)
    case_info = prisoner.case_information || prisoner.build_case_information

    map_delius_to_case_info!(probation_record, case_info)

    if case_info.changed?
      case_info_attrs_before = case_info.changed_attributes

      if case_info.save
        # Recalculate the offender's handover dates
        RecalculateHandoverDateJob.perform_later(nomis_offender_id)

        tags = %w[job process_delius_data_job case_information changed]
        tags << trigger_method.to_s
        tags << event_type.downcase if event_type.present?

        AuditEvent.publish(
          nomis_offender_id: nomis_offender_id,
          tags: tags,
          system_event: true,
          data: {
            'before' => case_info_attrs_before,
            'after' => case_info.slice(case_info_attrs_before.keys)
          }
        )
      else
        case_info.errors.each do |error|
          DeliusImportError.create! nomis_offender_id: nomis_offender_id,
                                    error_type: error_type(error.attribute)
        end
      end
    else
      logger.info(
        "nomis_offender_id=#{nomis_offender_id},trigger_method=#{trigger_method},job=process_delius_data_job,event=case_information_unchanged"
      )
    end
  end

  def map_delius_to_case_info!(probation_record, case_info)
    ldu_code = probation_record.dig(:manager, :team, :local_delivery_unit, :code)

    # We only populate tier if it's a new record because this is subsequently
    # updated by TierChangeHandler
    tier = case_info.persisted? ? case_info.tier : map_tier(probation_record.fetch(:tier))

    case_info.tap do |ci|
      ci.assign_attributes(
        manual_entry: false,
        com_name: com_name(probation_record),
        com_email: probation_record.dig(:manager, :email),
        crn: probation_record.fetch(:crn),
        tier: tier,
        local_delivery_unit: map_ldu(ldu_code),
        ldu_code: ldu_code,
        team_name: probation_record.dig(:manager, :team, :description),
        enhanced_resourcing: enhanced_resourcing(probation_record.fetch(:resourcing)),
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

    return nil if surname.blank? && forename.blank?

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

  def enhanced_resourcing(value)
    return nil if value.blank?

    value.upcase == 'ENHANCED'
  end
end
