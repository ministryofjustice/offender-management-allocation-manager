class ProcessDeliusDataJob < ApplicationJob
  queue_as :default

  include ApplicationHelper

  def perform(nomis_offender_id)
    DeliusData.transaction do
      DeliusImportError.where(nomis_offender_id: nomis_offender_id).destroy_all
      delius_data = DeliusData.where(noms_no: nomis_offender_id)
      if delius_data.count > 1
        DeliusImportError.create! nomis_offender_id: nomis_offender_id,
                                  error_type: DeliusImportError::DUPLICATE_NOMIS_ID
      elsif delius_data.count == 1
        import(delius_data.first)
      end
    end
  end

private

  def import(delius_record)
    offender = OffenderService.get_offender(delius_record.noms_no)

    return unless offender.present? && offender.convicted?

    if auto_delius_import_enabled?(offender.latest_location_id)
      if dob_matches?(offender, delius_record)
        process_record(delius_record)
      else
        DeliusImportError.create! nomis_offender_id: delius_record.noms_no,
                                  error_type: DeliusImportError::MISMATCHED_DOB
      end
    end
  rescue Nomis::Client::APIError
    logger.error("Failed to retrieve NOMIS record #{delius_record.noms_no}")
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
  end

  def map_delius_to_case_info(delius_record)
    find_case_info(delius_record).tap do |case_info|
      case_info.assign_attributes(
        crn: delius_record.crn,
        tier: map_tier(delius_record.tier),
        local_divisional_unit: make_ldu_record(delius_record),
        team: make_team_record(delius_record),
        case_allocation: delius_record.service_provider,
        omicable: map_omicable(delius_record.omicable?),
        mappa_level: map_mappa_level(delius_record.mappa, delius_record.mappa_levels)
      )
    end
  end

  def find_case_info(delius_record)
    CaseInformation.find_or_initialize_by(
      nomis_offender_id: delius_record.noms_no
    ) { |item|
      item.manual_entry = false
    }
  end

  def make_ldu_record(delius_record)
    ldu = LocalDivisionalUnit.find_or_initialize_by(
      code: delius_record.ldu_code
    ) { |item|
      item.name = delius_record.ldu
      item.save
    }
    ldu if ldu.persisted?
  end

  def make_team_record(delius_record)
    team = Team.find_or_initialize_by(code: delius_record.team_code) { |new_team|
      new_team.name = delius_record.team
      new_team.save
    }
    team if team.persisted?
  end

  def map_mappa_level(delius_mappa, delius_mappa_levels)
    if delius_mappa == 'N'
      0
    elsif delius_mappa == 'Y'
      delius_mappa_levels.split(',').reject { |ml| ml == 'Nominal' }.map(&:to_i).max
    end
  end

  def map_omicable(omicable)
    omicable ? 'Yes' : 'No'
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
