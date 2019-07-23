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
    case_information = CaseInformation.find_or_initialize_by(
      nomis_offender_id: delius_record.noms_no
    ) { |item|
      item.manual_entry = false
    }.tap { |ci|
      ci.assign_attributes(
        crn: delius_record.crn,
        tier: map_tier(delius_record.tier),
        ldu: delius_record.ldu,
        team: delius_record.team,
        case_allocation: delius_record.service_provider,
        omicable: map_omicable(delius_record.omicable?)
      )
    }

    unless case_information.save
      case_information.errors.each do |field, _errors|
        DeliusImportError.create! nomis_offender_id: delius_record.noms_no,
                                  error_type: error_type(field)
      end
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
      ldu: DeliusImportError::MISSING_LDU,
      team: DeliusImportError::MISSING_TEAM
    }.fetch(field)
  end
end
