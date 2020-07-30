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
  }

  def welsh?
    probation_service == 'Wales'
  end

  def ldu_changed?
    return false unless team_id_changed?

    team_ids = team_id_change.reject(&:nil?)
    return true unless team_ids.count == 2

    teams = Team.where(id: team_ids)
    ldu_ids = teams.map(&:local_divisional_unit_id)
    ldu_ids.uniq.count == 2
  end

private

  def save_scottish_or_ni
    assign_attributes(tier: 'N/A',
                      case_allocation: 'N/A',
                      team: nil)
  end
end
