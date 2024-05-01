class ParoleOutcomeDatePomTaskPresenter < PomTaskPresenter
  def action_label
    'Date parole hearing outcome confirmed'
  end

  def long_label
    "Enter the date that the outcome of #{first_name_with_ownership} parole hearing was confirmed. This allows us to work out who should take responsibility for this case."
  end

  def long_label_link
    edit_prison_prisoner_parole_review_path(prison_id, offender_number, parole_review_id)
  end

  def link_text
    'Enter date'
  end

  def link_path
    edit_prison_prisoner_parole_review_path(prison_id, offender_number, parole_review_id)
  end
end
