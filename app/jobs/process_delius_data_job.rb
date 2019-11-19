class ProcessDeliusDataJob < ApplicationJob
  queue_as :default

  include ApplicationHelper

  def perform(nomis_offender_id)
    DeliusData.transaction do
      logger.info("[DELIUS] Processing delius data for #{nomis_offender_id}")

      DeliusImportError.where(nomis_offender_id: nomis_offender_id).destroy_all
      delius_data = DeliusData.where(noms_no: nomis_offender_id)
      if delius_data.count > 1
        DeliusImportError.create! nomis_offender_id: nomis_offender_id,
                                  error_type: DeliusImportError::DUPLICATE_NOMIS_ID
      elsif delius_data.count == 1
        import_data(delius_data.first)
      end
    end
  end

private

  def import_data(delius_record)
    offender = OffenderService.get_offender(delius_record.noms_no)

    if offender.nil?
      return logger.error("[DELIUS] Failed to retrieve NOMIS record #{delius_record.noms_no}")
    end

    return unless offender.convicted?

    # as a compromise, we always import the DeliusData into the case_information record now,
    # but only disable manual editing for prisons that are actually enabled.
    if dob_matches?(offender, delius_record)
      process_record(delius_record)
    else
      DeliusImportError.create! nomis_offender_id: delius_record.noms_no,
                                error_type: DeliusImportError::MISMATCHED_DOB
    end
  end

  def dob_matches?(offender, delius_record)
    delius_record.date_of_birth.present? &&
      (delius_record.date_of_birth == ('*' * 8) ||
      offender.date_of_birth == safe_date_parse(delius_record.date_of_birth))
  end

  def safe_date_parse(dob)
    Date.parse(dob)
  rescue ArgumentError
    nil
  end

  def process_record(delius_record)
    case_information = map_delius_to_case_info(delius_record)

    unless case_information.save
      case_information.errors.each do |field, _errors|
        DeliusImportError.create! nomis_offender_id: delius_record.noms_no,
                                  error_type: error_type(field)
      end
    end

    update_com_name(delius_record)
  end

  def update_com_name(delius_record)
    allocation = Allocation.find_by(nomis_offender_id: delius_record.noms_no)
    return if allocation.blank?

    allocation.update(com_name: delius_record.offender_manager)
  end

  def map_delius_to_case_info(delius_record)
    find_case_info(delius_record).tap do |case_info|
      team = map_team(delius_record.team_code)
      ldu = team.local_divisional_unit if team
      case_info.assign_attributes(
        crn: delius_record.crn,
        tier: map_tier(delius_record.tier),
        team: team,
        local_divisional_unit: ldu,
        case_allocation: delius_record.service_provider,
        welsh_offender: map_welsh_offender(delius_record.welsh_offender?),
        mappa_level: map_mappa_level(delius_record.mappa, delius_record.mappa_levels)
      )
    end
  end

  def map_team(team_code)
    Team.find_by(shadow_code: team_code) || Team.find_by(code: team_code)
  end

  def find_case_info(delius_record)
    CaseInformation.find_or_initialize_by(
      nomis_offender_id: delius_record.noms_no
    ) { |item|
      item.manual_entry = false
    }
  end

  def map_mappa_level(delius_mappa, delius_mappa_levels)
    if delius_mappa == 'N'
      0
    elsif delius_mappa == 'Y'
      delius_mappa_levels.split(',').reject { |ml| ml == 'Nominal' }.map(&:to_i).max
    end
  end

  def map_welsh_offender(welsh_offender)
    welsh_offender ? 'Yes' : 'No'
  end

  def map_tier(tier)
    tier[0] if tier.present?
  end

  def error_type(field)
    {
      tier: DeliusImportError::INVALID_TIER,
      case_allocation: DeliusImportError::INVALID_CASE_ALLOCATION,
      local_divisional_unit: DeliusImportError::MISSING_LDU,
      team: DeliusImportError::MISSING_TEAM
    }.fetch(field)
  end
end
