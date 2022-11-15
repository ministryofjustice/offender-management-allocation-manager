module HandoverHelper
  def handover_record_progress_link(prison_code, nomis_offender_id)
    link_to('Record progress',
            prison_update_handover_progress_checklist_path(prison_code, nomis_offender_id),
            class: 'govuk-link govuk-link--no-visited-state')
  end

  def handover_progress_checklist_completion_tag(value)
    css_classes = %w[govuk-tag app-task-list__tag]
    if value
      text = 'Complete'
    else
      text = 'To do'
      css_classes.push 'govuk-tag govuk-tag--grey'
    end
    tag.strong text, class: css_classes
  end

  def last_handovers_url
    flash[:current_handovers_url] || upcoming_prison_handovers_url(@prison) # rubocop:disable Rails/HelperInstanceVariable
  end
end
