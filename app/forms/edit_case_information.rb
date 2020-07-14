# frozen_string_literal: true

class EditCaseInformation
  include ActiveModel::Model

  attr_accessor :last_known_location, :last_known_address, :tier, :case_allocation, :team_id

  validates :last_known_address, inclusion: {
    in: ['Scotland', 'Northern Ireland', 'Wales'],
    allow_nil: false,
    message: "You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales"
  }, if: -> { last_known_location == 'Yes' }

  validates :tier, inclusion: { in: %w[A B C D], message: "Select the prisoner's tier" }

  validates :case_allocation, inclusion: {
    in: %w[NPS CRC],
    allow_nil: false,
    message: 'Select the service provider for this case'
  }

  validates :team_id,
            presence: { message: "You must select the prisoner's team" },
            if: -> {
                  last_known_location == 'No' ||
                      last_known_address == 'Wales'
                }

  def probation_service
    last_known_location == 'No' ? 'England' : last_known_address
  end

  def self.from_case_info case_info
    new(
      last_known_location: case_info.probation_service == 'England' ? 'No' : 'Yes',
      last_known_address: case_info.probation_service,
      tier: case_info.tier,
      case_allocation: case_info.case_allocation,
      team_id: case_info.team_id
    )
  end
end
