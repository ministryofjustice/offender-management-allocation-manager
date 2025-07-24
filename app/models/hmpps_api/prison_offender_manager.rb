# frozen_string_literal: true

module HmppsApi
  class PrisonOffenderManager
    attr_reader :staff_id, :first_name, :last_name, :position,
                :agency_id, :position_description,
                :from_date, :to_date, :schedule_type, :hours_per_week

    attr_accessor :status, :working_pattern

    def initialize(payload)
      @staff_id = payload['staffId'].to_i
      @first_name = payload['firstName']
      @last_name = payload['lastName']
      @agency_id = payload['agencyId']
      @position = payload['position']
      @position_description = payload['positionDescription']
      @from_date = payload['fromDate']
      @to_date = payload['toDate']
      @schedule_type = payload['scheduleType']
      @hours_per_week = payload['hoursPerWeek']
    end

    def prison_officer?
      position == RecommendationService::PRISON_POM
    end

    def probation_officer?
      position == RecommendationService::PROBATION_POM
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end

    def email_address
      @email_address ||= HmppsApi::NomisUserRolesApi.email_address(@staff_id)
    end

    def self.from_json(payload)
      PrisonOffenderManager.new(payload)
    end
  end
end
