module HandoverHelper
  def handover_record_progress_link(prison_code, nomis_offender_id)
    link_to('Record progress',
            prison_update_handover_progress_checklist_path(prison_code, nomis_offender_id),
            class: 'govuk-link govuk-link--no-visited-state')
  end
end
