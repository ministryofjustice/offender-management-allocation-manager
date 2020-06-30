# frozen_string_literal: true

class LastLocationForm
  include ActiveModel::Model

  attr_accessor :nomis_offender_id, :last_known_location, :last_known_address

  validates :last_known_location,
            inclusion: {
              in: %w[Yes No],
              allow_nil: false,
              message: "Select yes if the prisoner's last known address was in Northern Ireland, Scotland or Wales"
            }

  validates :last_known_address, inclusion: {
    in: ['Scotland', 'Northern Ireland', 'Wales'],
    allow_nil: false,
    message: "You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales"
  }, if: -> { last_known_location == 'Yes' }

  def probation_service
    last_known_location == 'No' ? 'England' : last_known_address
  end
end
