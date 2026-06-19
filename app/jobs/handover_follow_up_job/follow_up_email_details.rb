class HandoverFollowUpJob::FollowUpEmailDetails
  def self.for(offender:)
    new(offender:).details
  end

  attr_reader :offender, :prison, :allocation

  def initialize(offender:)
    @offender   = offender
    @prison     = Prison.find(offender.prison_id)
    @allocation = AllocationHistory.find_by(nomis_offender_id: offender.offender_no)
  end

  def details
    {
      nomis_offender_id: offender.offender_no,
      offender_name: offender.full_name,
      offender_crn: offender.crn,
      sentence_type: offender.indeterminate_sentence? ? 'Indeterminate' : 'Determinate',
      ldu_email: offender.ldu_email_address,
      prison: prison.name,
      start_date: offender.handover_start_date,
      responsibility_handover_date: offender.handover_date,
    }.merge(pom_details)
  end

private

  def pom_details
    # If the offender has transferred but the allocation still references the old prison,
    # treat as if there's no active POM to avoid sending stale contact info.
    if allocation.try(:active?) && allocation.prison == prison.code
      active_pom_details
    else
      no_active_pom_details
    end
  end

  def active_pom_details
    pom = prison.get_single_pom(allocation.primary_pom_nomis_id)

    { pom_name: pom.full_name, pom_email: pom.email_address || 'unknown' }
  rescue StandardError => e
    # `get_single_pom` can raise an exception if the `primary_pom_nomis_id`
    # is not found in the list of all poms for this prison
    Rails.logger.error(e.message)

    { pom_name: 'unknown', pom_email: 'unknown' }
  end

  def no_active_pom_details
    { pom_name: 'This offender does not have an allocated POM', pom_email: 'n/a' }
  end
end
