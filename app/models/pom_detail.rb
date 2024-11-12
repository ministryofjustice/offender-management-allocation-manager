# frozen_string_literal: true

class PomDetail < ApplicationRecord
  has_paper_trail

  validates :nomis_staff_id, presence: true, uniqueness: { scope: :prison_code }
  validates :status, presence: true
  validates :working_pattern, presence: {
    message: 'Select number of days worked'
  }

  belongs_to :prison, foreign_key: :prison_code, inverse_of: :pom_details

  def self.find_or_create_new_active_by!(prison:, nomis_staff_id:)
    find_or_create_by!(prison:, nomis_staff_id:) do |pom|
      pom.working_pattern = 0.0
      pom.status = 'active'
    end
  end

  def allocations
    @allocations ||= begin
      allocations = AllocationHistory.active_pom_allocations(nomis_staff_id, prison_code).pluck(:nomis_offender_id)
      prison.offenders.select { |o| allocations.include? o.offender_no }
    end
  end
end
