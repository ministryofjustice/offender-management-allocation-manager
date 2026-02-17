# frozen_string_literal: true

class DeliusDataImportService
  attr_reader :logger, :identifier_type, :trigger_method, :event_type

  def initialize(identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil, logger: Rails.logger)
    @identifier_type = identifier_type
    @trigger_method = trigger_method
    @event_type = event_type
    @logger = logger
  end

  def process(identifier)
    prefix = "job=process_delius_data_job,#{identifier_type}=#{identifier},trigger_method=#{trigger_method}"

    logger.info("#{prefix},event=processing")
    import_data(identifier)
    logger.info("#{prefix},event=processed")
  rescue Faraday::ResourceNotFound
    logger.warn("#{prefix},event=resource_not_found")
  rescue Faraday::ConflictError
    logger.warn("#{prefix},event=conflict_error")
  rescue StandardError => e
    logger.warn("#{prefix},event=exception,message=#{e.message}")
  end

private

  def import_data(identifier)
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

    # Only when processing delius data as a consequence of an event received, we need
    # to check if the offender we've received exists, and falls inside OMiC rules.
    #
    # When using a batch/nightly job we don't need to do this as we are already processing
    # offenders we know are inside OMiC, so this is redundant and costly/slow.
    #
    if trigger_method == :event
      offender = OffenderService.get_offender(
        nomis_offender_id,
        ignore_legal_status: true, fetch_complexities: false, fetch_categories: false, fetch_movements: false
      )

      if offender.nil?
        logger.error(
          "nomis_offender_id=#{nomis_offender_id},job=process_delius_data_job,event=missing_offender_record|" \
          'Failed to retrieve NOMIS offender record'
        )

        return
      end

      unless offender.inside_omic_policy?
        logger.info(
          "nomis_offender_id=#{nomis_offender_id},job=process_delius_data_job,event=outside_omic_policy|" \
          'NOMIS offender outside OMIC policy'
        )

        return
      end
    end

    process_record(probation_record, nomis_offender_id)
  end

  def process_record(probation_record, nomis_offender_id)
    DeliusImportError.where(nomis_offender_id: nomis_offender_id).destroy_all

    prisoner = Offender.find_or_create_by!(nomis_offender_id: nomis_offender_id)
    case_info = prisoner.case_information || prisoner.build_case_information

    map_delius_to_case_info!(probation_record, case_info)

    # this is the most common scenario so we don't log anything, otherwise we will be
    # producing thousands of log traces daily saying "no change" which is pointless
    return unless case_info.changed?

    case_info_attrs_before = case_info.changed_attributes

    if case_info.save
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

      logger.info(
        "nomis_offender_id=#{nomis_offender_id},trigger_method=#{trigger_method},job=process_delius_data_job,event=case_information_changed"
      )
    else
      import_errors = []
      case_info.errors.each do |error|
        DeliusImportError.create!(nomis_offender_id:, error_type: error_type(error.attribute))
        import_errors << error.attribute
      end

      logger.error(
        "nomis_offender_id=#{nomis_offender_id},trigger_method=#{trigger_method},job=process_delius_data_job,event=case_information_error," \
        "errors=#{import_errors.join(',')}"
      )
    end
  end

  def map_delius_to_case_info!(probation_record, case_info)
    ldu_code = probation_record.dig(:manager, :team, :local_delivery_unit, :code)
    ldu_record = LocalDeliveryUnit.find_by(code: ldu_code)

    # We only populate tier if it's a new record because this is subsequently
    # updated by `TierChangeHandler` (leaving both updates causes a race condition)
    tier = case_info.persisted? ? case_info.tier : map_tier(probation_record.fetch(:tier))

    case_info.tap do |ci|
      ci.assign_attributes(
        manual_entry: false,
        com_name: com_name(probation_record),
        com_email: probation_record.dig(:manager, :email),
        crn: probation_record.fetch(:crn),
        tier: tier,
        local_delivery_unit: ldu_record,
        ldu_code: ldu_code,
        team_name: probation_record.dig(:manager, :team, :description),
        enhanced_resourcing: enhanced_resourcing(probation_record.fetch(:resourcing)),
        probation_service: ldu_record&.country || 'England',
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

  def map_tier(tier)
    tier[0] if tier.present?
  end

  def error_type(field)
    {
      tier: DeliusImportError::INVALID_TIER,
      case_allocation: DeliusImportError::INVALID_CASE_ALLOCATION,
      local_delivery_unit: DeliusImportError::MISSING_LDU,
      team: DeliusImportError::MISSING_TEAM,
    }.fetch(field)
  end

  def enhanced_resourcing(value)
    return nil if value.blank?

    value.upcase == 'ENHANCED'
  end
end
