# frozen_string_literal: true

require_relative '../application_service'

module POMService
  class GetPomName < ApplicationService
    attr_reader :staff_id

    def initialize(staff_id)
      @staff_id = staff_id
    end

    def call
      staff = Nomis::Elite2::PrisonOffenderManagerApi.staff_detail(@staff_id)
      [staff.first_name, staff.last_name]
    end
  end
end
