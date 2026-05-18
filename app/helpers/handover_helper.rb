module HandoverHelper
  def handover_record_progress_link(prison_code, nomis_offender_id)
    link_to('Record progress',
            prison_update_handover_progress_checklist_path(prison_code, nomis_offender_id),
            class: 'govuk-link govuk-link--no-visited-state')
  end

  def handover_progress_checklist_completion_tag(value)
    css_classes = %w[govuk-tag]
    if value
      text = 'Complete'
    else
      text = 'To do'
      css_classes.push 'govuk-tag--grey'
    end

    tag.span(class: 'app-handover-task-status-tag-wrapper') do
      tag.strong(text, class: css_classes)
    end
  end

  def last_handovers_url
    flash[:current_handovers_url] || upcoming_prison_handovers_url(@prison) # rubocop:disable Rails/HelperInstanceVariable
  end

  def handover_tab_navigation_link(action, title, pom_view)
    link_params = {}
    link_params[:pom] = 'user' if pom_view
    url = send("#{action}_prison_handovers_path", link_params)
    aria = (controller.action_name == action) ? { current: 'page' } : nil
    link_to title, url, class: %w[moj-sub-navigation__link], aria: aria
  end

  def handover_progress_task_label(task_field)
    I18n.t("handovers.progress_checklist.tasks.#{task_field}.label")
  end

  def handover_progress_task_hint_id(task_field)
    "#{task_field.to_s.tr('_', '-')}-hint"
  end

  def handover_progress_task_hint(task_field)
    task_field = task_field.to_sym
    return t("handovers.progress_checklist.tasks.#{task_field}.hint") unless task_field == :sent_handover_report

    t(
      'handovers.progress_checklist.tasks.sent_handover_report.hint_html',
      equip_link: link_to(
        t('handovers.progress_checklist.tasks.sent_handover_report.equip_link_text'),
        t(:equip_url), target: '_blank', rel: 'noopener'
      )
    )
  end
end
