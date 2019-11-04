# frozen_string_literal: true

class PomDetail < ApplicationRecord
  validates :nomis_staff_id, presence: true, uniqueness: true
  validates :status, presence: true
  validates :working_pattern, presence: {
    message: 'Select number of days worked'
  }
end
