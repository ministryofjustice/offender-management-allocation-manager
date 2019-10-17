# frozen_string_literal: true

class TasksController < PrisonsApplicationController
  breadcrumb 'Case updates needed', ''

  before_action :ensure_pom

  def index
    @pomtasks = tasks_for_offenders(caseload)
  end

private

  def tasks_for_offenders(allocations)
    # For each passed AllocationWithSentence we want to find out if the offender
    # requires any changes to it.  If so we will construct a PomTaskPresenter and
    # return it. Otherwise nil.

    allocations.map { |allocation|
      # TODO: Replace this with a call to OffenderService.get_multiple_offenders_as_hash
      # earlier in the method so that we can look up the offender from a local
      # hash so that we are not doing N+1 API calls.
      offender = OffenderService.get_offender(allocation.nomis_offender_id)

      prd_task = parole_review_date_task(offender)
      next prd_task if prd_task.present?

      delius_task = missing_info_task(offender)
      next delius_task if delius_task.present?

      early_task = early_allocation_update_task(offender)
      next early_task if early_task.present?
    }.compact
  end

  def parole_review_date_task(offender)
    # Offender is indeterminate and their parole review date is old or missing
    return unless offender.indeterminate_sentence?

    if offender.parole_review_date.blank? || offender.parole_review_date < Time.zone.today
      PomTaskPresenter.new.tap { |presenter|
        presenter.offender = offender
        presenter.action_label = 'Parole review date'
        presenter.action_url = prison_edit_prd_path(active_prison, offender.offender_no)
      }
    end
  end

  def missing_info_task(offender)
    # Offender had their delius data manually added and as a result are missing
    # new key fields.
    if offender.mappa_level.blank? || offender.ldu.blank?
      PomTaskPresenter.new.tap { |presenter|
        presenter.offender = offender
        presenter.action_label = 'nDelius case matching'
        presenter.action_url = 'No idea where to go....'
      }
    end
  end

  def early_allocation_update_task(offender)
    # An early allocation request has been made but is pending a response from
    # the community, and therefore needs updating.
  end

  def caseload
    @caseload ||= PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    )
  end

  def ensure_pom
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user,
      active_prison
    )

    if @pom.blank?
      redirect_to '/'
    end
  end
end
