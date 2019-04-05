# frozen_string_literal: true

class PomDetail < ApplicationRecord
  # rubocop:disable HasManyOrHasOneDependent
  has_many :allocations
  # rubocop:enable HasManyOrHasOneDependent

  validates :nomis_staff_id, :working_pattern, :status, presence: true
end
