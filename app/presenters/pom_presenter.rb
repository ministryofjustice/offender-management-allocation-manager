# frozen_string_literal: true

class PomPresenter
  delegate :working_pattern, :status, :probation_officer?, :prison_officer?, :staff_id, :first_name, :last_name, to: :@pom

  def initialize(pom)
    @pom = pom
    offender_numbers = Prison.new(pom.agency_id).offenders.map(&:offender_no)
    allocations = Allocation.active_pom_allocations(pom.staff_id, pom.agency_id).
      where(nomis_offender_id: offender_numbers).
      map(&:nomis_offender_id)
    @allocation_counts = CaseInformation.where(nomis_offender_id: allocations).
        group_by(&:tier)
  end

  def tier_a
    @allocation_counts.fetch('A', []).size
  end

  def tier_b
    @allocation_counts.fetch('B', []).size
  end

  def tier_c
    @allocation_counts.fetch('C', []).size
  end

  def tier_d
    @allocation_counts.fetch('D', []).size
  end

  def no_tier
    @allocation_counts.fetch('N/A', []).size
  end

  def total_cases
    [tier_a, tier_b, tier_c, tier_d, no_tier].sum
  end
end
