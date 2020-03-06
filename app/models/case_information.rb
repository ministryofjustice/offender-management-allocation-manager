# frozen_string_literal: true

class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'

  belongs_to :team, optional: true

  has_many :early_allocations,
           foreign_key: :nomis_offender_id,
           primary_key: :nomis_offender_id,
           inverse_of: :case_information,
           dependent: :destroy

  attr_accessor :last_known_location

  def local_divisional_unit
    team.try(:local_divisional_unit)
  end

  # We only normally show/edit the most recent early allocation
  def latest_early_allocation
    early_allocations.last
  end

  validates :manual_entry, inclusion: { in: [true, false], allow_nil: false }
  validates :nomis_offender_id, presence: true, uniqueness: true

  validates :local_divisional_unit, :team,
            presence: { message: "You must select the prisoner's team" },
            unless:
            proc { |c|
              c.manual_entry &&
              (c.probation_service == 'Scotland' ||
              c.probation_service == 'Northern Ireland')
            }

  validates :tier, inclusion: { in: %w[A B C D N/A], message: "Select the prisoner's tier" }

  validates :case_allocation, inclusion: {
    in: %w[NPS CRC N/A],
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

  # We only want to validate last known location in forms
  validates :last_known_location,
            inclusion: {
              in: %w[Yes No],
              allow_nil: true,
              message: "Select yes if the prisoner's last known address was in Northern Ireland, Scotland or Wales"
            }, if: -> { manual_entry }

  def scottish_or_ni?
    return true if probation_service == 'Scotland' || probation_service == 'Northern Ireland'

    false
  end

  def save_scottish_or_ni
    self.tier = 'N/A'
    self.case_allocation = 'N/A'
    self.team = nil
  end

  def english_or_welsh?
    return true if last_known_location == 'No' || probation_service == 'Wales' || probation_service == 'England'

    false
  end

  def english?
    last_known_location == 'No'
  end

  def stage2_filled?
    return false if tier.nil? || team.nil? || case_allocation.nil?

    true
  end
end
