# frozen_string_literal: true

require_relative '../application_service'

module OffenderService
  class List < ApplicationService
    attr_reader :prison

    def initialize(prison)
      @prison = prison
    end

    def call
      OffenderEnumerator.new(@prison)
    end
  end
end
