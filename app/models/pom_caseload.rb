# frozen_string_literal: true

class PomCaseload
  include Rails.application.routes.url_helpers

  def initialize(pom_staff_id, prison_id)
    @staff_id = pom_staff_id
    @prison_id = prison_id
  end

  def allocations
    @allocations ||= load_allocations
  end

  def tasks_for_offenders
    # For each AllocationWithSentence we want to find out if the offender
    # requires any changes to it. This may return multiple tasks for the
    # same offender.
    offender_nos = allocations.map(&:nomis_offender_id)
    @early_allocations = preload_early_allocations(offender_nos)

    allocations.map { |allocation|
      tasks_for_offender(allocation.offender)
    }.flatten
  end

  def tasks_for_offender(offender)
    offender_nos = allocations.map(&:nomis_offender_id)
    @early_allocations = preload_early_allocations(offender_nos)

    tasks = []
    prd_task = parole_review_date_task(offender)
    tasks << prd_task if prd_task.present?

    delius_task = missing_info_task(offender)
    tasks << delius_task if delius_task.present?

    early_task = early_allocation_update_task(offender)
    tasks << early_task if early_task.present?

    tasks
  end

private

  def parole_review_date_task(offender)
    # Offender is indeterminate and their parole review date is old or missing
    return unless offender.indeterminate_sentence?

    if offender.parole_review_date.blank? || offender.parole_review_date < Time.zone.today
      PomTaskPresenter.new.tap { |presenter|
        presenter.offender_name = offender.full_name
        presenter.offender_number = offender.offender_no
        presenter.action_label = 'Parole review date'
        presenter.long_label = 'Parole review date must be updated so handover dates can be calculated.'
        presenter.action_url = prison_edit_prd_path(@prison_id, offender.offender_no)
      }
    end
  end

  def missing_info_task(offender)
    # Offender had their delius data manually added and as a result are missing
    # new key fields.
    if offender.mappa_level.blank? || offender.ldu.blank?
      PomTaskPresenter.new.tap { |presenter|
        presenter.offender_name = offender.full_name
        presenter.offender_number = offender.offender_no
        presenter.action_label = 'nDelius case matching'
        presenter.long_label = 'This prisoner must be linked to an nDelius record so '\
          'community probation details are available. '\
          'See <a href="/update_case_information">how to update case information</a>'
        presenter.action_url = prison_case_information_path(@prison_id, offender.offender_no)
      }
    end
  end

  def early_allocation_update_task(offender)
    # An early allocation request has been made but is pending a response from
    # the community, and therefore needs updating.
    if @early_allocations.key?(offender.offender_no)
      PomTaskPresenter.new.tap { |presenter|
        presenter.offender_name = offender.full_name
        presenter.offender_number = offender.offender_no
        presenter.action_label = 'Early allocation decision'
        presenter.long_label = 'The community probation team’s decision about early allocation must be recorded.'
        presenter.action_url = community_decision_prison_prisoner_early_allocation_path(
          @prison_id, offender.offender_no)
      }
    end
  end

  def preload_early_allocations(offender_nos)
    # For the provided offender numbers, determines whether they have an outstanding
    # early allocation and then adds them to a hash for quick lookup.  If a specific
    # offender does have an outstanding early allocation their offender number will
    # appear as a key (with a boolean value). We do this because hash lookup is
    # significantly faster than array/list lookup.
    EarlyAllocation.where(nomis_offender_id: offender_nos).map { |early_allocation|
      if early_allocation.discretionary? && early_allocation.community_decision.nil?
        [early_allocation.nomis_offender_id, true]
      end
    }.compact.to_h
  end

  # rubocop:disable Metrics/MethodLength
  def load_allocations
    allocation_list = AllocationVersion.active_pom_allocations(
      @staff_id, @prison_id
    )

    offender_ids = allocation_list.map(&:nomis_offender_id)
    offenders = OffenderService.get_multiple_offenders(offender_ids)

    offenders.map { |offender|
      # This is potentially slow, possibly of the order O(NM)
      allocation = allocation_list.detect { |alloc|
        alloc.nomis_offender_id == offender.offender_no
      }

      # If this is the primary POM, work out responsibility
      if allocation.primary_pom_nomis_id == @staff_id
        responsibility =
          ResponsibilityService.calculate_pom_responsibility(offender).to_s
      else
        responsibility = ResponsibilityService::COWORKING
      end

      AllocationWithSentence.new(
        @staff_id,
        allocation,
        offender,
        responsibility
      )
    }
  end
  # rubocop:enable Metrics/MethodLength
end
