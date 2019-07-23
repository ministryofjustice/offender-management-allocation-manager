# frozen_string_literal: true

class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'

  validates :manual_entry, inclusion: { in: [true, false], allow_nil: false }
  validates :nomis_offender_id, presence: true, uniqueness: true

  validates :ldu, :team, presence: true, unless: ->{ manual_entry }

  validates :omicable, inclusion: {
    in: %w[Yes No],
    allow_nil: false,
    message: 'Select yes if the prisoner’s last known address was in Wales'
  }
  validates :tier, inclusion: { in: %w[A B C D], message: 'Select the prisoner’s tier' }

  validates :case_allocation, inclusion: {
    in: %w[NPS CRC],
    allow_nil: false,
    message: 'Select the service provider for this case'
  }

  validates :mappa_level, inclusion: { in: [1, 2, 3], allow_nil: true }
end
