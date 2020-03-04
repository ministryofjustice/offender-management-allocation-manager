# frozen_string_literal: true

class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'

  belongs_to :team, optional: true

  has_many :early_allocations,
           foreign_key: :nomis_offender_id,
           primary_key: :nomis_offender_id,
           inverse_of: :case_information,
           dependent: :destroy

  def local_divisional_unit
    team.try(:local_divisional_unit)
  end

  # We only normally show/edit the most recent early allocation
  def latest_early_allocation
    early_allocations.last
  end

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

  validates :probation_service, inclusion: {
    in: ['Scotland', 'Northern Ireland', 'Wales', 'England'],
    allow_nil: false,
    message: "You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales"
  }, if: -> { manual_entry }

end
