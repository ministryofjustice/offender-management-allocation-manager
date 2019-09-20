# frozen_string_literal: true

class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'

  belongs_to :local_divisional_unit, optional: true
  belongs_to :team, optional: true

  validates :manual_entry, inclusion: { in: [true, false], allow_nil: false }
  validates :nomis_offender_id, presence: true, uniqueness: true

  validates :local_divisional_unit, :team, presence: true, unless: ->{ manual_entry }

  validates :welsh_offender, inclusion: {
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

  # nil means MAPPA level is completely unknown.
  # 0 means MAPPA level is known to be not relevant for offender
  validates :mappa_level, inclusion: { in: [0, 1, 2, 3], allow_nil: true }
end
