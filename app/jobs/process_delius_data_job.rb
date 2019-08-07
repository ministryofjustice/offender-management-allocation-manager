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
      else
        delius_import(delius_data.first)
      end
    end
  end

private

  def delius_import(delius_record)
    offender = OffenderService.get_offender(delius_record.noms_no)

    if auto_delius_import_enabled?(offender.latest_location_id)
      if offender.date_of_birth == Date.parse(delius_record.date_of_birth)
        process_record(delius_record)
      else
        DeliusImportError.create! nomis_offender_id: nomis_offender_id,
                                  error_type: DeliusImportError::MISMATCHED_DOB
      end
    end
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
    ldu_record = make_ldu_record(delius_record)
    team_record = make_team_record(delius_record)

    find_case_info(delius_record).tap do |case_info|
      case_info.assign_attributes(
        crn: delius_record.crn,
        tier: map_tier(delius_record.tier),
        local_divisional_unit: ldu_record.persisted? ? ldu_record : nil,
        team: team_record.persisted? ? team_record : nil,
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
    LocalDivisionalUnit.find_or_initialize_by(
      code: delius_record.ldu_code
    ) { |item|
      item.name = delius_record.ldu
      item.save
    }
  end

  def make_team_record(delius_record)
    Team.find_or_initialize_by(code: delius_record.team_code) { |team|
      team.name = delius_record.team
      team.save
    }
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
