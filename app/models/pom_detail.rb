# frozen_string_literal: true

class PomDetail < ApplicationRecord
  scope :by_nomis_staff_id, lambda { |nomis_staff_id|
    find_by(nomis_staff_id: nomis_staff_id)
  }
  validates :nomis_staff_id, presence: true
  validates :status, presence: true
  validates :working_pattern, presence: {
    message: 'Select number of days worked'
  }
end
