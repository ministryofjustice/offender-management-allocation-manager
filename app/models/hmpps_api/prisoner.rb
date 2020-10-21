# frozen_string_literal: true

module HmppsApi
  class Prisoner
    include Deserialisable

    include SentenceHolder
    include CaseInformationHolder
    include HandoverHolder
    include NameFormatter

    attr_reader :offender_no, :prison_id, :booking_id, :category_code, :date_of_birth
    attr_reader :first_name, :last_name

    attr_accessor :prison_arrival_date, :main_offence

    def immigration_case?
      false
    end

    def convicted?
      true
    end

    def recalled?
      @recall
    end

    def indeterminate_sentence?
      @indeterminate_sentence
    end

    def self.from_json(payload)
      Prisoner.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    def load_from_json(payload)
      @offender_no = payload.fetch('prisonerNumber')
      @booking_id = payload.fetch('bookingId').to_i
      @recall = payload.fetch('recall')
      @first_name = payload.fetch('firstName')
      @last_name = payload.fetch('lastName')
      @date_of_birth = deserialise_date(payload, 'dateOfBirth')
      @prison_id = payload.fetch('prisonId')
      @category_code = payload.fetch('category')
      @indeterminate_sentence = payload.fetch('indeterminateSentence')
    end
  end
end
