# frozen_string_literal: true

class PomTasks
  # Just for auto_delius_import_enabled
  include ApplicationHelper

  def for_offenders(offenders)
    # For each AllocatedOffender we want to find out if the offender
    # requires any changes to it. This may return multiple tasks for the
    # same offender.
    early_allocs = get_early_allocations(offenders.map(&:offender_no))

    offenders.map { |offender|
      for_offender(offender, early_allocations: early_allocs)
    }.flatten
  end

  def for_offender(offender, early_allocations: nil)
    if early_allocations.nil?
      early_allocations = get_early_allocations([offender.offender_no])
    end

    tasks = [
      parole_review_date_task(offender),
      missing_info_task(offender)
    ].compact

    if early_allocations.include?(offender.offender_no)
      tasks << early_allocation_update_task(offender)
    end

    tasks
  end

  def parole_review_date_task(offender)
    # Offender is indeterminate and their parole review date is old or missing
    return unless offender.indeterminate_sentence?

    if offender.parole_review_date.blank? || offender.parole_review_date < Time.zone.today
      PomTaskPresenter.new.tap { |presenter|
        presenter.offender_name = offender.full_name
        presenter.offender_number = offender.offender_no
        presenter.action_label = 'Parole review date'
        presenter.long_label = 'Parole review date must be updated so handover dates can be calculated.'
      }
    end
  end

  def missing_info_task(offender)
    return unless auto_delius_import_enabled?(offender.prison_id)

    # Offender had their delius data manually added and as a result are missing
    # new key fields.
    unless offender.delius_matched?
      PomTaskPresenter.new.tap { |presenter|
        presenter.offender_name = offender.full_name
        presenter.offender_number = offender.offender_no
        presenter.action_label = 'nDelius case matching'
        presenter.long_label = 'This prisoner must be linked to an nDelius record so '\
          'community probation details are available. '\
          'See <a href="/update_case_information">how to update case information</a>'
      }
    end
  end

  def early_allocation_update_task(offender)
    # An early allocation request has been made but is pending a response from
    # the community, and therefore needs updating.
    PomTaskPresenter.new.tap { |presenter|
      presenter.offender_name = offender.full_name
      presenter.offender_number = offender.offender_no
      presenter.action_label = 'Early allocation decision'
      presenter.long_label = 'The community probation team’s decision about early allocation must be recorded.'
    }
  end

  def get_early_allocations(offender_nos)
    # For the provided offender numbers, determines whether they have an outstanding
    # early allocation and then adds them to a set for quick lookup.
    eas = EarlyAllocation.where(nomis_offender_id: offender_nos).select { |early_allocation|
      early_allocation.discretionary? && early_allocation.community_decision.nil?
    }.map(&:nomis_offender_id)
    Set.new(eas)
  end
end
