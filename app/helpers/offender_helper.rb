module OffenderHelper
  def digital_prison_service_profile_path(offender_id)
    URI.join(
      Rails.configuration.digital_prison_service_host,
      "/offenders/#{offender_id}/quick-look"
    ).to_s
  end

  def pom_responsibility_label(offender)
    offender.pom_responsibility.to_s
  end

  def case_owner_label(offender)
    offender.pom_responsibility.case_owner
  end

  def last_event(allocation)
    event = event_type(allocation.event)
    event + ' - ' + allocation.created_at.strftime('%d/%m/%Y')
  end

  def event_type(event)
    type = (event.include? 'primary_pom') ? 'POM ' : 'Co-working POM '

    if event.include? 'reallocate'
      type + 're-allocated'
    elsif event.include? 'deallocate'
      type + 'removed'
    elsif event.include? 'allocate'
      type + 'allocated'
    end
  end

  def approaching_handover_without_com?(offender)
    return false unless offender.sentenced?

    return false if offender.handover_start_date.nil?

    return false if offender.handover_start_date > Time.zone.today + 45.days

    return false if offender.allocated_com_name.present?

    return true if offender.ldu.try(:email_address).nil?

    false
  end
end
