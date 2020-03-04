# frozen_string_literal: true

class OnboardPrison
  attr_reader :offender_ids, :delius_records
  attr_accessor :delius_missing, :additions

  def initialize(prison, offender_ids, delius_records)
    @prison = prison
    @offender_ids = filter_existing_records(offender_ids)
    @delius_records = list_to_lookup(delius_records)

    @additions = 0
    @delius_missing = 0
  end

  def complete_missing_info
    @offender_ids.each { |offender_id|
      record = @delius_records[offender_id]
      if record.nil?
        @delius_missing += 1
        next
      end

      # Create a CaseInformation .....
      CaseInformation.find_or_create_by(
        nomis_offender_id: offender_id,
        welsh_offender: record[:welsh_offender] ? 'Yes' : 'No',
        tier: record[:tier],
        case_allocation: record[:provider_cd],
        crn: record[:crn],
        # probation_service will not exist, default to Scotland
        # or Northern Ireland. This is currently the only way the record will
        # be saved without a team.
        probation_service: record[:probation_service].presence || 'Scotland',
        manual_entry: true
      )

      @additions += 1
    }
  end

private

  def filter_existing_records(offender_ids)
    existing = CaseInformation.where(nomis_offender_id: offender_ids).pluck(:nomis_offender_id)
    offender_ids - existing
  end

  def list_to_lookup(delius_records)
    return {} if delius_records.blank?

    Hash[delius_records.collect { |record| [record[:noms_no], record] }]
  end
end
