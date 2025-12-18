# frozen_string_literal: true

class PomDetail < ApplicationRecord
  has_paper_trail

  FULL_TIME_HOURS_PER_WEEK = 37.5

  enum :status, { active: 'active', unavailable: 'unavailable', inactive: 'inactive' }, validate: true

  validates :nomis_staff_id, presence: true, uniqueness: { scope: :prison_code }
  validates :working_pattern, presence: {
    message: 'Select full time or part time'
  }

  belongs_to :prison, foreign_key: :prison_code, inverse_of: :pom_details

  # @return [Array<MpcOffender>] Allocated offenders for this POM
  def allocations
    @allocations ||= begin
      allocations = AllocationHistory.active_pom_allocations(nomis_staff_id, prison_code).pluck(:nomis_offender_id)
      allocations.any? ? prison.allocated.select { |o| allocations.include?(o.offender_no) } : []
    end
  end

  def has_primary_allocations?
    allocations.filter_map(&:active_allocation).any? do |alloc|
      alloc.primary_pom_nomis_id == nomis_staff_id
    end
  end

  # 37.5 -> 1.0, 33.75 -> 0.9, etc.
  # If for any reason hours are greater than 37.5 we convert to 1.0 (full-time)
  def hours_per_week=(hours)
    self.working_pattern = [(hours / FULL_TIME_HOURS_PER_WEEK).floor(1), 1.0].min
  end

  def hours_per_week
    working_pattern * FULL_TIME_HOURS_PER_WEEK
  end
end
