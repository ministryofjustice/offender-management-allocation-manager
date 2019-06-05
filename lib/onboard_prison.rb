class OnboardPrison
  attr_reader :offender_ids

  def initialize(offender_ids, delius_records)
    @offender_ids = filter_existing_records(offender_ids)
    @delius_records = delius_records
  end

private

  # rubocop:disable Metrics/LineLength
  def filter_existing_records(offender_ids)
    existing = CaseInformation.where(nomis_offender_id: offender_ids).pluck(:nomis_offender_id)
    offender_ids - existing
  end
  # rubocop:enable Metrics/LineLength
end
