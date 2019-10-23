# frozen_string_literal: true

class PomCaseload
  include Rails.application.routes.url_helpers

  def initialize(pom_staff_id, prison_id)
    @staff_id = pom_staff_id
    @prison_id = prison_id
    @tasks = PomTasks.new(@prison_id)
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

      AllocatedOffenderWithSentence.new(
        @staff_id,
        allocation,
        offender,
        responsibility
      )
    }
  end
  # rubocop:enable Metrics/MethodLength
end
