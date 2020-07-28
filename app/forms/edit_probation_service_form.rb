# frozen_string_literal: true

class EditProbationServiceForm
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

  def probation_service=(probation_service)
    if probation_service.nil?
      assign_attributes(
        last_known_location: nil,
        last_known_address: nil,
        )
    else
      assign_attributes(
        last_known_location: probation_service == 'England' ? 'No' : 'Yes',
        last_known_address: probation_service == 'England' ? nil : probation_service,
        )
    end
  end
end
