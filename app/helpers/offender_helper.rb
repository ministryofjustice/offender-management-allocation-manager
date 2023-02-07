module OffenderHelper
  def digital_prison_service_profile_path(offender_id)
    URI.join(
      Rails.configuration.digital_prison_service_host,
      "/offenders/#{offender_id}/quick-look"
    ).to_s
  end

  def pom_responsibility_label(offender)
    if offender.pom_responsible?
      'Responsible'
    elsif offender.pom_supporting?
      'Supporting'
    elsif offender.coworking?
      'Co-working'
    end
  end

  def pom_role_needed(offender)
    if offender.pom_responsible?
      'Responsible'
    elsif offender.com_responsible?
      'Supporting'
    end
  end

  def case_owner_label(offender)
    if offender.pom_responsible?
      'Custody'
    elsif offender.com_responsible?
      'Community'
    end
  end

  def last_event(allocation)
    event = event_type(allocation.event)
    "#{event} - #{allocation.created_at.strftime('%d/%m/%Y')}"
  end

  def event_type(event)
    type = (event.include? 'primary_pom') ? 'POM ' : 'Co-working POM '

    if event.include? 'reallocate'
      "#{type}re-allocated"
    elsif event.include? 'deallocate'
      "#{type}removed"
    elsif event.include? 'allocate'
      "#{type}allocated"
    end
  end

  def recommended_pom_type_label(offender)
    if RecommendationService.recommended_pom_type(offender) == RecommendationService::PRISON_POM
      'Prison officer'
    else
      'Probation officer'
    end
  end

  def non_recommended_pom_type_label(offender)
    if RecommendationService.recommended_pom_type(offender) == RecommendationService::PRISON_POM
      'Probation officer'
    else
      'Prison officer'
    end
  end

  def complex_reason_label(offender)
    if RecommendationService.recommended_pom_type(offender) == RecommendationService::PRISON_POM
      'Prisoner assessed as not suitable for a prison officer POM'
    else
      'Prisoner assessed as suitable for a prison officer POM despite tiering calculation'
    end
  end

  def tier_a_case_count(offenders)
    offenders.count { |a| a.tier == 'A' }
  end

  def tier_b_case_count(offenders)
    offenders.count { |a| a.tier == 'B' }
  end

  def tier_c_case_count(offenders)
    offenders.count { |a| a.tier == 'C' }
  end

  def tier_d_case_count(offenders)
    offenders.count { |a| a.tier == 'D' }
  end

  # :nocov: new case mix bar doesn't include tier N/A cases :-(
  def no_tier_case_count(offenders)
    offenders.count { |a| a.tier == 'N/A' }
  end
  # :nocov:

  def probation_field(offender, field)
    offender.public_send field if offender.probation_record.present?
  end

  def format_allocation(offender:, pom:, view_context:, co_working_pom: nil, prev_pom_name: nil)
    {
      offender_name: offender.full_name_ordered,
      prisoner_number: offender.offender_no,
      pom_name: view_context.full_name_ordered(pom),
      prev_pom_name: prev_pom_name,
      co_working_pom_name: co_working_pom.blank? ? nil : view_context.full_name_ordered(co_working_pom),
      pom_role: if offender.pom_responsible?
                  'Responsible'
                else
                  (offender.com_responsible? ? 'Supporting' : '')
                end,
      mappa_level: offender.mappa_level,
      ldu_name: (offender.ldu_name.presence || 'Unknown'),
      ldu_email: (offender.ldu_email_address.presence || 'Unknown'),
      com_name: (view_context.unreverse_name(offender.allocated_com_name).presence || 'Unknown'),
      com_email: (offender.allocated_com_email.presence || 'Unknown'),
      handover_start_date: (view_context.format_date(offender.handover_start_date).presence || 'Unknown'),
      handover_completion_date: (view_context.format_date(offender.responsibility_handover_date).presence || 'Unknown'),
      last_oasys_completed: (view_context.format_date(last_oasys_completed(offender.offender_no)).presence || 'No OASys information'),
      active_alerts: offender.active_alert_labels.join(', '),
      additional_notes: nil
    }.merge(offender.rosh_summary)
  end

  def last_oasys_completed(offender_no)
    details = HmppsApi::AssessmentApi.get_latest_oasys_date(offender_no)

    return nil if details.nil? ||
      details.fetch(:assessment_type) == Faraday::ConflictError ||
      details.fetch(:assessment_type) == Faraday::ServerError

    details.fetch(:completed)
  end
end
