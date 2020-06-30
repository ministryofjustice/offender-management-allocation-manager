# frozen_string_literal: true

class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'

  belongs_to :team, optional: true, counter_cache: :case_information_count

  has_many :early_allocations,
           foreign_key: :nomis_offender_id,
           primary_key: :nomis_offender_id,
           inverse_of: :case_information,
           dependent: :destroy

  scope :nps, -> { where(case_allocation: 'NPS') }

  before_validation :save_scottish_or_ni, if: -> { manual_entry && (probation_service == 'Scotland' || probation_service == 'Northern Ireland') }
  before_validation :set_welsh_offender

  def local_divisional_unit
    team.try(:local_divisional_unit)
  end

  # We only normally show/edit the most recent early allocation
  def latest_early_allocation
    early_allocations.last
  end

  validates :manual_entry, inclusion: { in: [true, false], allow_nil: false }
  validates :nomis_offender_id, presence: true, uniqueness: true

  validates :team,
            presence: { message: "You must select the prisoner's team" },
            unless:
            proc { |c|
              c.manual_entry &&
              (c.probation_service == 'Scotland' ||
              c.probation_service == 'Northern Ireland')
            }

  validates :tier, inclusion: { in: %w[A B C D N/A], message: "Select the prisoner's tier" }

  validates :welsh_offender, inclusion: { in: %w[Yes No] }

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

private

  def save_scottish_or_ni
    assign_attributes(tier: 'N/A',
                      case_allocation: 'N/A',
                      team: nil)
  end

  def set_welsh_offender
    assign_attributes(
      welsh_offender: if probation_service == 'Wales'
                        'Yes'
                      else
                        'No'
                      end
    )
  end
end
