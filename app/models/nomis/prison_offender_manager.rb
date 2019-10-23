# frozen_string_literal: true

module Nomis
  class PrisonOffenderManager
    include Deserialisable

    attr_accessor :staff_id, :first_name, :last_name,
                  :agency_id, :agency_description,
                  :from_date, :position, :position_description,
                  :role, :role_description,
                  :schedule_type, :schedule_type_description,
                  :hours_per_week, :thumbnail_id, :emails,
                  :tier_a, :tier_b, :tier_c, :tier_d,
                  :total_cases, :status, :working_pattern

    def email_address
      emails.first
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

    def add_detail(pom_detail, prison)
      allocation_counts = AllocationVersion.active_primary_pom_allocations(
        pom_detail.nomis_staff_id, prison).group(:allocated_at_tier).count

      self.tier_a = allocation_counts.fetch('A', 0)
      self.tier_b = allocation_counts.fetch('B', 0)
      self.tier_c = allocation_counts.fetch('C', 0)
      self.tier_d = allocation_counts.fetch('D', 0)
      self.total_cases = [tier_a, tier_b, tier_c, tier_d].sum
      self.status = pom_detail.status
      self.working_pattern = pom_detail.working_pattern
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
