class EarlyAllocationDecisionPomTaskPresenter < PomTaskPresenter
  def action_label
    'Early allocation decision'
  end

  def long_label
    'The community probation team’s decision about early allocation must be recorded.'
  end

  def long_label_link
    nil
  end

  def link_text
    'Record decision'
  end

  def link_path
    edit_prison_prisoner_latest_early_allocation_path(prison_id, offender_number)
  end
end
