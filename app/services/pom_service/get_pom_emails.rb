# frozen_string_literal: true

require_relative '../application_service'

module POMService
  class GetPomEmails < ApplicationService
    attr_reader :staff_id

    def initialize(staff_id)
      @staff_id = staff_id
    end

    def call
      Nomis::Elite2::PrisonOffenderManagerApi.fetch_email_addresses(@staff_id)
    end
  end
end
