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
    if offender.pom_responsibility.custody?
      'Custody'
    else
      'Community'
    end
  end

  def last_event(allocation)
    event = event_type(allocation.event)
    event + ' - ' + allocation.updated_at.strftime('%d/%m/%Y')
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
end
