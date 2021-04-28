# frozen_string_literal: true

class PomDetail < ApplicationRecord
  validates :nomis_staff_id, presence: true, uniqueness: { scope: :prison_code }
  validates :status, presence: true
  validates :working_pattern, presence: {
    message: 'Select number of days worked'
  }
  validates_presence_of :prison_code

  def allocations
    @allocations ||= begin
      allocations = Allocation.active_pom_allocations(nomis_staff_id, prison_code).pluck(:nomis_offender_id)
      Prison.find(prison_code).offenders.select { |o| allocations.include? o.offender_no }
    end
  end
end
