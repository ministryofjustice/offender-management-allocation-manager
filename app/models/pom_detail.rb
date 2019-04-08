# frozen_string_literal: true

class PomDetail < ApplicationRecord
  # rubocop:disable HasManyOrHasOneDependent
  has_many :allocations
  # rubocop:enable HasManyOrHasOneDependent

  validates :nomis_staff_id, presence: true
  validates :status, presence: true
  validates :working_pattern, presence: {
    message: 'Select number of days worked'
  }
end
