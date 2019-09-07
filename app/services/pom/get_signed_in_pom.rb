# frozen_string_literal: true

require_relative '../application_service'

module POM
  class GetSignedInPom < ApplicationService
    attr_reader :prison, :username

    def initialize(prison, username)
      @username = username
      @prison = prison
    end

    def call
      user = Nomis::Elite2::UserApi.user_details(@username)

      poms_list = POM::GetPomsForPrison.call(@prison)
      poms_list.select { |p| p.staff_id.to_i == user.staff_id.to_i }.first
    end
  end
end
