# frozen_string_literal: true

class PomTaskPresenter
  include Rails.application.routes.url_helpers

  # @offender may be either an AllocatedOffender or MpcOffender, depending on the source of the call.
  # However, all relevant methods can be found on MpcOffender.
  delegate :offender_name, :offender_first_name, :offender_number, :prison_id, :type, :parole_record_id, to: :@pom_task

  def initialize(pom_task)
    @pom_task = pom_task
  end

  def first_name_with_ownership
    "#{offender_first_name.capitalize}#{offender_first_name.downcase[-1] == 's' ? '\'' : '\'s'}"
  end

  def action_label
    case type
    when :parole_outcome_date
      'Date parole hearing outcome confirmed'
    when :early_allocation_decision
      'Early allocation decision'
    end
  end

  def long_label
    case type
    when :parole_outcome_date
      "Enter the date that the outcome of #{first_name_with_ownership} parole hearing was confirmed. This allows us to work out who should take responsibility for this case."
    when :early_allocation_decision
      'The community probation team’s decision about early allocation must be recorded.'
    end
  end

  def long_label_link
    case type
    when :parole_outcome_date
      edit_prison_prisoner_parole_record_path(prison_id, offender_number, parole_record_id)
    when :early_allocation_decision
      nil
    end
  end

  def link_text
    case type
    when :parole_outcome_date
      'Enter date'
    when :early_allocation_decision
      'Record decision'
    end
  end

  def link_path
    case type
    when :parole_outcome_date
      edit_prison_prisoner_parole_record_path(prison_id, offender_number, parole_record_id)
    when :early_allocation_decision
      edit_prison_prisoner_latest_early_allocation_path(prison_id, offender_number)
    end
  end
end
