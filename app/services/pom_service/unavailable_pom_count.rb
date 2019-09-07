# frozen_string_literal: true

require_relative '../application_service'

module POMService
  class UnavailablePomCount < ApplicationService
    attr_reader :prison

    def initialize(prison)
      @prison = prison
    end

    def call
      poms = POMService::GetPomsForPrison.call(prison).reject { |pom|
        pom.status == 'active'
      }
      poms.count
    end
  end
end
