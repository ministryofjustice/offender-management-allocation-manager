# frozen_string_literal: true

class PomCaseload
  include Rails.application.routes.url_helpers

  def initialize(pom_staff_id, prison_id)
    @staff_id = pom_staff_id
    @prison_id = prison_id
    @tasks = PomTasks.new
  end

  def allocations
    @allocations ||= load_allocations
  end

  def tasks_for_offenders
    @tasks.for_offenders(allocations.map(&:offender))
  end

  def tasks_for_offender(offender)
    @tasks.for_offender(offender)
  end

private

  # rubocop:disable Metrics/MethodLength
  def load_allocations
    allocation_list = AllocationVersion.active_pom_allocations(
      @staff_id, @prison_id
    )

    offender_ids = allocation_list.map(&:nomis_offender_id)
    offenders = OffenderService.get_multiple_offenders(offender_ids)

    # Lookup responsibility overrides and store them in a hash for this
    # caseload
    responsibilities = Responsibility.where(nomis_offender_id: offender_ids)
    responsibility_overrides = responsibilities.map { |r|
      [r.nomis_offender_id, r]
    }.to_h

    offenders.map { |offender|
      # This is potentially slow, possibly of the order O(NM)
      allocation = allocation_list.detect { |alloc|
        alloc.nomis_offender_id == offender.offender_no
      }

      # Do a lookup to find out if this offender has had
      # their responsibility manually overridden. If so then
      # use that, otherwise we need to calculate it.
      overridden_responsibility = responsibility_overrides.fetch(offender.offender_no, nil)
      responsibility_string = if overridden_responsibility.present?
                                if overridden_responsibility.value == Responsibility::PRISON
                                  ResponsibilityService::RESPONSIBLE
                                else
                                  ResponsibilityService::SUPPORTING
                                end
                              elsif allocation.primary_pom_nomis_id == @staff_id
                                ResponsibilityService.calculate_pom_responsibility(offender)
                              else
                                ResponsibilityService::COWORKING
                              end

      AllocatedOffender.new(
        @staff_id,
        allocation,
        offender,
        responsibility_string.to_s
      )
    }
  end
  # rubocop:enable Metrics/MethodLength
end
