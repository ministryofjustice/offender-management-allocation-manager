# frozen_string_literal: true

require_relative '../application_service'

module POMService
  class GetUsername < ApplicationService
    attr_reader :username

    def initialize(username)
      @username = username
    end

    def call
      user = Nomis::Elite2::UserApi.user_details(@username)
      [user.first_name, user.last_name]
    end
  end
end
