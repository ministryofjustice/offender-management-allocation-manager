# frozen_string_literal: true

require_relative '../application_service'

module POMService
  class UpdatePom < ApplicationService
    attr_reader :staff_id, :working_pattern, :status

    def initialize(staff_id, pattern, status)
      @staff_id = staff_id
      @working_pattern = pattern
      @status = status
    end

    def call
      pom = PomDetail.by_nomis_staff_id(@staff_id)
      pom.working_pattern = @working_pattern
      pom.status = @status || pom.status
      pom.save

      if pom.valid? && pom.status == 'inactive'
        AllocationVersion.deallocate_primary_pom(@staff_id)
      end

      pom
    end
  end
end
