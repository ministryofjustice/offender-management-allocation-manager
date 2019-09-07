# frozen_string_literal: true

require_relative '../application_service'

module OffenderService
  class Get < ApplicationService
    attr_reader :offender_id

    def initialize(offender_id)
      @offender_id = offender_id
    end

    def call
      Nomis::Elite2::OffenderApi.get_offender(@offender_id).tap { |o|
        next false if o.nil?

        record = CaseInformation.find_by(nomis_offender_id: @offender_id)

        if record.present?
          o.tier = record.tier
          o.case_allocation = record.case_allocation
          o.omicable = record.omicable == 'Yes'
          o.crn = record.crn
          o.mappa_level = record.mappa_level
        end

        sentence_detail = SentenceDetails.call([o.latest_booking_id])
        if sentence_detail.present? && sentence_detail.key?(o.latest_booking_id)
          o.sentence = sentence_detail[o.latest_booking_id]
        end

        o.category_code = Nomis::Elite2::OffenderApi.get_category_code(o.offender_no)
        o.main_offence = Nomis::Elite2::OffenderApi.get_offence(o.latest_booking_id)
      }
    end
  end
end
