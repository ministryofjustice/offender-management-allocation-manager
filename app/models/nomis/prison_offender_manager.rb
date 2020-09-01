# frozen_string_literal: true

module Nomis
  class PrisonOffenderManager
    include Deserialisable

    attr_accessor :staff_id, :first_name, :last_name,
                  :agency_id, :agency_description,
                  :from_date, :position_description,
                  :role, :role_description,
                  :schedule_type, :schedule_type_description,
                  :hours_per_week, :thumbnail_id,
                  :tier_a, :tier_b, :tier_c, :tier_d, :no_tier,
                  :status, :working_pattern

    attr_writer :position, :emails

    def prison_officer?
      @position == RecommendationService::PRISON_POM
    end

    def probation_officer?
      @position == RecommendationService::PROBATION_POM
    end

    def email_address
      @emails.first
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end

    def grade
      "#{position_description.split(' ').first} POM"
    end

    def total_cases
      [tier_a, tier_b, tier_c, tier_d, no_tier].sum
    end

    def self.from_json(payload)
      PrisonOffenderManager.new.tap { |obj|
        obj.staff_id = payload['staffId'].to_i
        obj.first_name = payload['firstName']
        obj.last_name = payload['lastName']
        obj.agency_id = payload['agencyId']
        obj.agency_description = payload['agencyDescription']
        obj.from_date = deserialise_date(payload, 'fromDate')
        obj.position = payload['position']
        obj.position_description = payload['positionDescription']
        obj.role = payload['role']
        obj.role_description = payload['roleDescription']
        obj.schedule_type = payload['scheduleType']
        obj.schedule_type_description = payload['scheduleTypeDescription']
        obj.hours_per_week = payload['hoursPerWeek']&.to_i
        obj.thumbnail_id = payload['thumbnailId']
        obj.emails = payload['emails']
      }
    end
  end
end
