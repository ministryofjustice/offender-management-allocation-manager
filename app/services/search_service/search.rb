# frozen_string_literal: true

require_relative '../application_service'

module SearchService
  class Search < ApplicationService
    attr_reader :text, :prison

    def initialize(text, prison)
      @text = text
      @prison = prison
    end

    def call
      return [] if @text.nil?

      search_term = @text.upcase

      OffenderService::List.call(@prison).select do |offender|
        offender.last_name.start_with?(search_term) ||
          offender.first_name.start_with?(search_term) ||
          offender.offender_no.include?(search_term)
      end
    end
  end
end
