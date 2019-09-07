# frozen_string_literal: true

require_relative '../application_service'

module OffenderService
  class SentenceDetails < ApplicationService
    attr_reader :booking_ids

    def initialize(booking_ids)
      @booking_ids = booking_ids
    end

    def call
      Nomis::Elite2::OffenderApi.get_bulk_sentence_details(@booking_ids)
    end
  end
end
