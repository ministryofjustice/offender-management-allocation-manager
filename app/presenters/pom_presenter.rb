# frozen_string_literal: true

class PomPresenter
  delegate :working_pattern, :status, :probation_officer?, :prison_officer?, :staff_id,
           :first_name, :last_name, :position_description, to: :@pom

  def initialize(pom)
    @pom = pom
    @pom_allocated_offenders = pom_allocated_offenders
  end

  def tier_a
    @pom_allocated_offenders.count { |o| o.tier == 'A' }
  end

  def tier_b
    @pom_allocated_offenders.count { |o| o.tier == 'B' }
  end

  def tier_c
    @pom_allocated_offenders.count { |o| o.tier == 'C' }
  end

  def tier_d
    @pom_allocated_offenders.count { |o| o.tier == 'D' }
  end

  def no_tier
    @pom_allocated_offenders.count { |o| o.tier == 'N/A' }
  end

  def total_cases
    @pom_allocated_offenders.count
  end

  def high_complexity_count
    @pom_allocated_offenders.count { |o| o.complexity_level == 'high' }
  end

private

  def pom_allocated_offenders
    offenders_in_prison = Prison.new(@pom.agency_id).offenders
    allocated_offender_ids = Allocation.active_pom_allocations(@pom.staff_id, @pom.agency_id).
    where(nomis_offender_id: offenders_in_prison.map(&:offender_no)).pluck(:nomis_offender_id)

    offenders_in_prison.select { |o| allocated_offender_ids.include?(o.offender_no) }
  end
end
