class Offenders::AdditionalIsps
  def initialize(booking_id)
    @booking_id = booking_id
  end

  def any?
    isp_terms_by_case.values
      .map  { |terms| terms.first.sentence_start_date }.sort
      .then { |dates| dates.count > 1 && dates.last > dates.first }
  end

private

  def isp_terms_by_case
    @isp_terms_by_case ||= OffenderService
      .get_offender_sentences_and_offences(@booking_id)
      .select(&:indeterminate?)
      .group_by(&:case_id)
  end
end
