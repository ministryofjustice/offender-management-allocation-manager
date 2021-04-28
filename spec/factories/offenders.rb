# frozen_string_literal: true

FactoryBot.define do
  factory :nomis_offender, class: Hash do
    initialize_with { attributes }

    currentlyInPrison { 'Y' }
    imprisonmentStatus { 'SENT03' }
    agencyId { 'LEI' }

    # cell location is the format <1 letter>-<1 number>-<3 numbers> e.g 'E-4-014'
    internalLocation {
      block = Faker::Alphanumeric.alpha(number: 1).upcase
      num = Faker::Number.non_zero_digit
      numbers = Faker::Number.leading_zero_number(digits: 3)
      "#{block}-#{num}-#{numbers}"
    }

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:offenderNo) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and case_information should produce different values to avoid clashes
      "T#{number}O#{letter}"
    end
    convictedStatus { 'Convicted' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    category { attributes_for(:offender_category, :cat_c) }
    recall { false }

    sentence do
      attributes_for :sentence_detail
    end

    complexityLevel { 'medium' }

    sequence(:bookingId) { |c| c + 100_000 }
  end

  factory :offender do
    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:nomis_offender_id) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and the offender should produce different values to avoid clashes
      "P#{number}P#{letter}"
    end
  end
end
