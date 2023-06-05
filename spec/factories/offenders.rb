# frozen_string_literal: true

FactoryBot.define do
  factory :nomis_offender, class: Hash do
    initialize_with {
      # convert values to JSON primitives (e.g. Date to String)
      attrs = JSON.parse(attributes.to_json).deep_symbolize_keys
      attrs.except(:sentence).merge(attrs.fetch(:sentence, {}))
    }

    inOutStatus { 'IN' }
    imprisonmentStatus { 'SENT03' }
    prisonId { 'LEI' }
    supportingPrisonId { 'LEI' }
    restrictedPatient { false }

    # cell location is the format <1 letter>-<1 number>-<3 numbers> e.g 'E-4-014'
    cellLocation {
      block = Faker::Alphanumeric.alpha(number: 1).upcase
      num = Faker::Number.non_zero_digit
      numbers = Faker::Number.leading_zero_number(digits: 3)
      "#{block}-#{num}-#{numbers}"
    }

    prisonerNumber { generate :nomis_offender_id }
    legalStatus { 'SENTENCED' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    category { attributes_for(:offender_category, :cat_c) }

    sentence do
      attributes_for :sentence_detail
    end

    complexityLevel { 'medium' }

    sequence(:bookingId) { |c| c + 100_000 }

    # Use in conjunction with the :rotl trait on :movement
    trait :rotl do
      inOutStatus { 'OUT' }
      lastMovementTypeCode { 'TAP' }
    end

    created {Date.new }
  end

  factory :offender do
    nomis_offender_id

    trait :enhanced_handover do
      case_information { create(:case_information, enhanced_handover: true) }
    end

    trait :normal_handover do
      case_information { create(:case_information, enhanced_handover: false) }
    end
  end

  factory :mpc_offender do
    initialize_with { MpcOffender.new(prison: attributes.fetch(:prison),
                                      offender: attributes.fetch(:offender),
                                      prison_record: attributes.fetch(:prison_record)) }

  end
end
