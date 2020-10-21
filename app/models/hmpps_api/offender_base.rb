# frozen_string_literal: true

module HmppsApi
  class OffenderBase
    include SentenceHolder
    include CaseInformationHolder
    include HandoverHolder
    include NameFormatter

    delegate :indeterminate_sentence?, :immigration_case?, to: :@sentence_type

    attr_accessor :category_code, :prison_arrival_date

    attr_reader :first_name, :last_name, :booking_id,
                :offender_no, :date_of_birth

    attr_accessor :allocated_pom_name, :allocated_com_name

    attr_reader :sentence_type

    def convicted?
      @convicted_status == 'Convicted'
    end

    def recalled?
      @recall_flag
    end

    def criminal_sentence?
      @sentence_type.civil? == false
    end

    def civil_sentence?
      @sentence_type.civil?
    end

    def describe_sentence
      "#{@sentence_type.code} - #{@sentence_type.description}"
    end

    def load_from_json(payload)
      # It is expected that this method will be called by the subclass which
      # will have been given a payload at the class level, and will call this
      # method from it's own internal from_json
      @first_name = payload.fetch('firstName')
      @last_name = payload.fetch('lastName')
      @offender_no = payload.fetch('offenderNo')
      @convicted_status = payload['convictedStatus']
      @recall_flag = payload.fetch('recall')
      @sentence_type = SentenceType.new(payload['imprisonmentStatus'])
      @category_code = payload['categoryCode']
      @date_of_birth = deserialise_date(payload, 'dateOfBirth')
      @early_allocation = false
    end
  end
end
